function output=step02_reconstruct_bathymetry(root,caseIDs)
% Three mapping lines and cropped native DEM -> 33 layouts and full-area RMSE.
if nargin<1,root=setup_project;end
if nargin<2,caseIDs=strings(0,1);end
g=fullfile(root,'data','raw','geometry');channelModel=struct();
for field=["leftBank","rightBank","thalweg"]
 t=readtable(fullfile(g,field+'.csv'));channelModel.(field)=[t.Easting_m t.Northing_m];
 if isfield(channelModel,'station'),assert(isequal(channelModel.station,t.Station_m));else,channelModel.station=t.Station_m;end
end
channelModel.channelBoundaryClosed=readmatrix(fullfile(g,'evaluation_boundary.csv'));
channelModel.width=vecnorm(channelModel.leftBank-channelModel.rightBank,2,2);
channelModel.normal=(channelModel.leftBank-channelModel.rightBank)./channelModel.width;
meta=jsondecode(fileread(fullfile(root,'data','raw','dem_metadata.json')));channelModel.noDataValue=meta.NoDataValue;
outdir=fullfile(root,'results','survey');if ~isfolder(outdir),mkdir(outdir);end
save(fullfile(outdir,'channel_model.mat'),'channelModel');
cfg=rmse_time_config(root);cfg.DEMFile=fullfile(root,'data','raw','dem_cropped.tif');
cfg.ChannelFile=fullfile(outdir,'channel_model.mat');cfg.ModelFile=fullfile(root,'results','turning','models.mat');
cfg.ResultDir=outdir;cfg.WritePointCSV=false;
if ~isempty(caseIDs)
 design=sortrows(readtable(fullfile(root,'config','layout_design.csv'),'TextType','string'),'EffectiveIntervals');
 [present,indices]=ismember(string(caseIDs),design.CaseID);assert(all(present),'Unknown CaseID.');cfg.CaseIndices=indices;
end
output=run_rmse_time_stage(cfg);
assert(output.Domain.EvaluationCells==meta.EvaluationCells);
assert(abs(output.Domain.ReferenceElevationRange_m-meta.Dmax_m)<1e-10);
ref=readtable(fullfile(root,'reference','layouts.csv'),'TextType','string');
if ~isempty(caseIDs),ref=ref(ismember(ref.CaseID,string(caseIDs)),:);end
a=sortrows(output.Paired,{'CaseID','Platform'});b=sortrows(ref,{'CaseID','Platform'});
assert(isequal(a.CaseID,b.CaseID)&&isequal(a.Platform,b.Platform));
fields=["RMSE_m","PathLength_m","AbsoluteTurnAngle_rad","TotalTime_h"];
tol=[1e-5,1e-5,1e-4,1e-5];err=zeros(4,1);
for k=1:4,err(k)=max(abs(a.(fields(k))-b.(fields(k))));end
audit=table(fields',err,tol',err<=tol','VariableNames',{'Metric','MaxAbsoluteDifference','Tolerance','Pass'});
writetable(audit,fullfile(outdir,'reference_comparison.csv'));assert(all(audit.Pass));
end
