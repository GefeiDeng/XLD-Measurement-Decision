function result = run_case(designRow,ctx,cfg,fingerprint)
%RUN_CASE Complete fixed-layout geometry -> two-platform TIME -> auxiliary+NN -> RMSE.
name=designRow.CaseID;folder=fullfile(cfg.ResultDir,'cases',name);if ~isfolder(folder),mkdir(folder);end
complete=fullfile(folder,'result.mat');
if cfg.ResumeCompletedCases&&isfile(complete)
    old=load(complete,'result');
    if isfield(old.result,'Fingerprint')&&strcmp(old.result.Fingerprint,fingerprint)&&old.result.Completed
        fprintf('  Reusing verified complete case %s.\n',name);result=old.result;return
    end
end
[XY,info]=xldsurvey.map_route(designRow.Path,designRow.CanonicalRequestedD_m,ctx.Model,cfg);
assert(info.nIntervals==designRow.ConstructionIntervals,'Integer layout changed.');
segments=xldsurvey.segment_table(info);timeRows=cell(numel(ctx.PlatformModels),1);
for p=1:numel(ctx.PlatformModels)
    model=ctx.PlatformModels{p};timeRows{p}=xldturn.predict_route(XY,model);
    timeRows{p}=addvars(timeRows{p},model.Platform,'Before',1,'NewVariableNames','Platform');
end
time=vertcat(timeRows{:});[XYZ,samplingQC]=xldsurvey.sample_dem(XY,ctx,cfg);
[aux,intersections,auxQC]=xldsurvey.build_auxiliary_depth(XYZ,ctx.AuxiliaryXY, ...
    'Method',cfg.AuxiliaryDepthMethod,'MergeTolerance',cfg.IntersectionMergeTolerance_m, ...
    'AnchorTolerance',cfg.AnchorTolerance_m);
fprintf('  Full route %.3f km, theta %.3f rad; %d observed + %d auxiliary points.\n', ...
    time.PathLength_m(1)/1000,time.AbsoluteTurnAngle_rad(1),size(XYZ,1),height(aux));
metrics=xldsurvey.reconstruct_surface(XYZ,aux,ctx,cfg,fullfile(folder,'surface.mat'));
checks=xldsurvey.check_case(info,segments,time,XYZ,aux,intersections,metrics,ctx,cfg);
assert(all(checks.Pass),'xldsurvey:Acceptance','Case acceptance failed.');
trajectory=array2table(XYZ,'VariableNames',{'X_m','Y_m','BedElevation_m'});
save(fullfile(folder,'route_and_observations.mat'),'trajectory','info','segments','aux', ...
    'intersections','auxQC','samplingQC','time','-v7.3');
if cfg.WritePointCSV
    writetable(trajectory,fullfile(folder,'trajectory_xyz.csv'));writetable(aux,fullfile(folder,'auxiliary_xyz.csv'));
end
writetable(segments,fullfile(folder,'segments.csv'));writetable(time,fullfile(folder,'platform_times.csv'));
writetable(auxQC,fullfile(folder,'auxiliary_checks.csv'));writetable(intersections,fullfile(folder,'intersections.csv'));
writetable(checks,fullfile(folder,'verification.csv'));writetable(struct2table(metrics),fullfile(folder,'metrics.csv'));
result=struct('CaseID',name,'Design',designRow,'Time',time,'Metrics',metrics,'SamplingQC',samplingQC, ...
    'ReturnType',info.returnType,'IsClosed',info.isClosed,'CheckCount',height(checks), ...
    'Fingerprint',fingerprint,'Completed',true);save(complete,'result');
fprintf('  DONE %s: RMSE %.6f m; native NN coverage %.2f%%; fill %.2f%%.\n', ...
    name,metrics.RMSE_m,100*metrics.NativeNNCoverage,100*metrics.ExteriorFillFraction);
end
