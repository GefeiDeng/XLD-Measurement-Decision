function output = run_rmse_time_stage(cfg)
%RUN_RMSE_TIME_STAGE Reproducible full-area fixed-layout bathymetric RMSE--TIME.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,cfg=rmse_time_config(root);end
fprintf('Loading reference DEM and explicit %s evaluation domain.\n',cfg.EvaluationDomain);
ctx=xldsurvey.prepare_context(cfg);fingerprint=xldsurvey.source_fingerprint(cfg);
if ~isfolder(cfg.ResultDir),mkdir(cfg.ResultDir);end
common=fullfile(cfg.ResultDir,'common');if ~isfolder(common),mkdir(common);end
design=readtable(fullfile(cfg.Root,'config','layout_design.csv'),'TextType','string');aliases=table();
assert(max(abs(design.ActualD_m-ctx.Length_m./design.EffectiveIntervals))<1e-8);
design=sortrows(design,'EffectiveIntervals');
writetable(design,fullfile(cfg.ResultDir,'design.csv'));writetable(aliases,fullfile(cfg.ResultDir,'D_request_aliases.csv'));
writetable(ctx.AuxiliaryXY,fullfile(common,'auxiliary_xy.csv'));
EvaluationIndices=ctx.EvaluationIndices;ReferenceElevation_m=ctx.Truth;R=ctx.R;
RasterSize=ctx.RasterSize;EvaluationDomain=cfg.EvaluationDomain;Dmax_m=ctx.Dmax_m;
EvaluationMask=ctx.EvaluationMask;EvaluationBoundaryXY=ctx.EvaluationBoundaryXY;
save(fullfile(common,'evaluation_reference.mat'),'EvaluationIndices','ReferenceElevation_m','R', ...
    'RasterSize','EvaluationDomain','Dmax_m','EvaluationMask','EvaluationBoundaryXY','fingerprint','-v7.3');
writetable(array2table(EvaluationBoundaryXY,'VariableNames',{'X_m','Y_m'}), ...
    fullfile(common,'evaluation_boundary_xy.csv'));
summary=table(cfg.EvaluationDomain,ctx.FullValidCount,numel(ctx.EvaluationIndices), ...
    ctx.FullValidCount*ctx.SourceCellArea_m2,numel(ctx.EvaluationIndices)*ctx.SourceCellArea_m2, ...
    ctx.NoDataValue,ctx.Dmax_m,ctx.Width_m,ctx.Length_m,R.CellExtentInWorldX,R.CellExtentInWorldY, ...
    'VariableNames',{'EvaluationDomain','FullValidDEMCells','EvaluationCells','FullValidArea_m2', ...
    'EvaluationArea_m2','NoDataValue','ReferenceElevationRange_m','MappingMeanWidth_m', ...
    'MappingLength_m','EvaluationCellSizeX_m','EvaluationCellSizeY_m'});
writetable(summary,fullfile(common,'domain_summary.csv'));disp(summary);
stride=cfg.PlotRasterStride;PreviewZ=ctx.Z(1:stride:end,1:stride:end);PreviewRows=1:stride:size(ctx.Z,1);
PreviewMask=ctx.EvaluationMask(1:stride:end,1:stride:end);
PreviewColumns=1:stride:size(ctx.Z,2);channelModel=ctx.Model;
save(fullfile(common,'plot_reference.mat'),'PreviewZ','PreviewMask','PreviewRows','PreviewColumns','R','channelModel','summary');
selected=1:height(design);if ~isempty(cfg.CaseIndices),selected=cfg.CaseIndices;end
results=cell(numel(selected),1);timeRows=cell(numel(selected),1);metricRows=cell(numel(selected),1);pairedRows=cell(numel(selected),1);
for k=1:numel(selected)
    row=design(selected(k),:);fprintf('\n[%d/%d] %s: D=%.6f m, M=%d, effective N=%d.\n', ...
        k,numel(selected),row.CaseID,row.ActualD_m,row.ConstructionIntervals,row.EffectiveIntervals);
    results{k}=xldsurvey.run_case(row,ctx,cfg,fingerprint);r=results{k};time=r.Time;
    base=repmat(row,height(time),1);base.ReturnType=repmat(r.ReturnType,height(time),1);
    timeRows{k}=[base time];metrics=struct2table(r.Metrics);metrics.NNElapsed_s=[];
    metricRows{k}=[row metrics];
    writetable(vertcat(timeRows{1:k}),fullfile(cfg.ResultDir,'TIME_by_platform.csv'));
    writetable(vertcat(metricRows{1:k}),fullfile(cfg.ResultDir,'RMSE_by_layout.csv'));
    paired=repmat(metrics,height(time),1);pairedRows{k}=[timeRows{k} paired];
    writetable(vertcat(pairedRows{1:k}),fullfile(cfg.ResultDir,'RMSE_TIME.csv'));
end
output=struct('Config',cfg,'Design',design,'Aliases',aliases,'Domain',summary, ...
    'Results',{results},'Fingerprint',fingerprint,'Paired',vertcat(pairedRows{:}));
save(fullfile(cfg.ResultDir,'rmse_time_results.mat'),'output');


fprintf('\nCompleted %d independent layouts; %d platform--layout pairs.\n',numel(selected),height(output.Paired));
end
