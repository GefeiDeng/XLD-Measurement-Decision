function output = run_turning_stage(cfg,mode)
%RUN_TURNING_STAGE Reproduce calibration, validation, sensitivity, plots and interfaces.
% The default rebuilds tracks from the packaged daily raw records.
% Explicit "prepared" mode reuses tracks from a previous stage-1 run.
% No original project is needed, and no RMSE/decision computation is called.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1||isempty(cfg),cfg=turning_config(root);end
if nargin<2,mode="raw";end
assert(ismember(string(mode),["prepared","raw"]),'mode must be prepared or raw.');
if ~isfolder(cfg.ResultDir),mkdir(cfg.ResultDir);end
if ~isfolder(cfg.FigureDir),mkdir(cfg.FigureDir);end
if mode=="raw"
    fprintf('Rebuilding seven selected GPS days from packaged MAT inputs.\n');
    xldturn.import_case_gps(cfg);cfg.TrackDir=fullfile(cfg.ResultDir,'rebuilt_gps');
end
rng(cfg.RandomSeed,'twister');n=numel(cfg.Platforms);Models=cell(n,1);Blocks=cell(n,1);
tracks=cell(n,1);summaries=cell(n,1);draws=cell(n,1);cumulative=cell(n,1);
cv=cell(n,1);cvsummary=cell(n,1);sensitivity=cell(n,1);daily=cell(n,1);
for p=1:n
    platform=cfg.Platforms(p);name=string(platform.Name);
    fprintf('[%d/%d] Building and fitting Platform %s.\n',p,n,name);
    files=dir(fullfile(cfg.TrackDir,platform.FilePattern));assert(~isempty(files),'Missing GPS input: %s',platform.FilePattern);
    parts=cell(numel(files),1);
    for j=1:numel(files),parts{j}=readtable(fullfile(files(j).folder,files(j).name),'TextType','string');end
    tracks{p}=vertcat(parts{:});[model,b]=xldturn.fit_model(xldturn.build_blocks(tracks{p},cfg),cfg);
    model.Platform=name;model.Year=platform.Year;model.SourceName=string(platform.SourceName);
    Models{p}=model;Blocks{p}=b;writetable(b,fullfile(cfg.ResultDir,"blocks_"+name+".csv"));
    fprintf('  c=%.12g m/rad, V=%.12g m/s, blocks=%d. Bootstrap...\n', ...
        model.Coefficient_m_per_rad,model.BaselineSpeed_mps,model.NCalibrationBlocks);
    [draws{p},ci]=xldturn.bootstrap_coefficient(b,cfg,name);Models{p}.CoefficientCI95=ci;
    fprintf('  Cumulative agreement and leave-one-operation-out coefficient check.\n');
    cumulative{p}=xldturn.cumulative_check(b,model,cfg,name);
    [cv{p},cvsummary{p}]=xldturn.crossvalidate_coefficient(b,name);
    group=findgroups(b.DateKey,b.OperationID);baseline=sum(b.Length_m./b.LocalBaselineSpeed_mps);
    observed=sum(b.Time_s);extra=observed-baseline;
    summaries{p}=table(name,platform.Year,numel(unique(b.DateKey)),max(group),height(b), ...
        model.NCalibrationBlocks,model.BaselineSpeed_mps,model.Coefficient_m_per_rad,ci(1),ci(2), ...
        model.R2Zero,model.RMSE_s,observed/3600,baseline/3600,extra/3600,100*extra/observed, ...
        'VariableNames',{'Platform','Year','Dates','Operations','RetainedBlocks','CalibrationBlocks', ...
        'BaselineSpeed_mps','Coefficient_m_per_rad','BootstrapP025','BootstrapP975','R2Zero', ...
        'BlockRMSE_s','ObservedTime_h','BaselineTime_h','ObservedExtraTime_h','ObservedExtraShare_pct'});
    dates=unique(b.DateKey);rows=cell(numel(dates),1);
    for j=1:numel(dates)
        d=b(b.DateKey==dates(j),:);obs=sum(d.Time_s);base=sum(d.Length_m./d.LocalBaselineSpeed_mps);
        rows{j}=table(name,dates(j),obs/3600,base/3600,(obs-base)/3600,100*(obs-base)/obs, ...
            'VariableNames',{'Platform','DateKey','ObservedTime_h','BaselineTime_h','ExtraTime_h','ExtraShare_pct'});
    end
    daily{p}=vertcat(rows{:});
    if cfg.RunPreprocessingSensitivity
        sensitivity{p}=xldturn.preprocessing_sensitivity(tracks{p},cfg,name);
    else,sensitivity{p}=table();end
end
output=struct('Config',cfg,'Models',{Models},'Blocks',{Blocks},'Summary',vertcat(summaries{:}), ...
    'Daily',vertcat(daily{:}),'BootstrapDraws',vertcat(draws{:}), ...
    'CVDetail',vertcat(cv{:}),'CVSummary',vertcat(cvsummary{:}), ...
    'Preprocessing',vertcat(sensitivity{:}),'Cumulative',{cumulative});
output.Windows=vertcat_cells(cumulative,'Windows');output.ScaleSummary=vertcat_cells(cumulative,'ScaleSummary');
output.CommonSupportSummary=vertcat_cells(cumulative,'CommonSupportSummary');
output.OperationSummary=vertcat_cells(cumulative,'OperationSummary');
items={'Summary','Daily','BootstrapDraws','CVDetail','CVSummary','Preprocessing', ...
    'Windows','ScaleSummary','CommonSupportSummary','OperationSummary'};
for j=1:numel(items),writetable(output.(items{j}),fullfile(cfg.ResultDir,items{j}+".csv"));end
save(fullfile(cfg.ResultDir,'models.mat'),'Models','cfg');save(fullfile(cfg.ResultDir,'turning_results.mat'),'output','-v7.3');
output.Checks=verify_turning_delivery(output);writetable(output.Checks,fullfile(cfg.ResultDir,'verification.csv'));

fprintf('Completed. Results: %s\n',cfg.ResultDir);disp(output.Summary);
assert(all(output.Checks.Pass),'xldturn:Verification','A delivery verification check failed.');
end
function tableOut=vertcat_cells(sets,field)
parts=cellfun(@(s)s.(field),sets,'UniformOutput',false);tableOut=vertcat(parts{:});
end
