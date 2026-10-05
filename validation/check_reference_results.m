function checks=check_reference_results
% Independently recompute response fits, decisions and crossings from numeric rows.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_project;
ref=fullfile(root,'reference');d=readtable(fullfile(ref,'layouts.csv'),'TextType','string');
stored=load(fullfile(ref,'rmse_only_results.mat'),'output');o=stored.output;
models=cell(2,2);fields=strings(0,1);errors=zeros(0,1);tolerances=zeros(0,1);
paths=["BCS","PCZ"];
for p=1:2
 for j=1:2
  pl=string(char('A'+p-1));q=sortrows(d(d.Platform==pl&d.Path==paths(j),:),'TotalTime_h');
  time=(q.PathLength_m+q.Coefficient_m_per_rad.*q.AbsoluteTurnAngle_rad)./q.BaselineSpeed_mps/3600;
  record(pl+' '+paths(j)+' time closure',max(abs(time-q.TotalTime_h)),1e-9);
  f=fit_monotone_rmse(time,q.RMSE_m,o.Config.Lambda);f.Path=paths(j);f.D_m=q.ActualD_m;f.Width_m=mean(q.ActualD_m./q.ActualDstar);models{p,j}=f;
  tt=logspace(log10(f.Time_h(1)),log10(f.Time_h(end)),1000);
  old=o.Fits{p,j};record(pl+' '+paths(j)+' fitted curve',max(abs(exp(ppval(f.PP,log(tt)))-exp(ppval(old.PP,log(tt))))),1e-8);
 end
 map=select_rmse(models(p,:),o.Config.Hours,o.Config.TargetRstar*o.Dmax_m,o.Dmax_m);original=o.Maps{p};
 for name=["N","PathCode","D_m","PredictedRMSE_m","PredictedTime_h"]
  a=map.(name);b=original.(name);assert(isequal(isnan(a),isnan(b))&&isequal(isinf(a),isinf(b)));
  finite=isfinite(a)&isfinite(b);record(string(p)+' decision '+name,max(abs(a(finite)-b(finite))),1e-7);
 end
end
s=load(fullfile(ref,'reconstruction_and_rmse_time.mat'),'data');data=s.data;
cfg=draft_plot_config(root);cfg.ProcessedDir=fullfile(root,'validation','recalculated');if ~isfolder(cfg.ProcessedDir),mkdir(cfg.ProcessedDir);end
cfg.TargetRMSELimits=[.01 .03]*o.Dmax_m;data.RMSEFits=models;
data=attach_turning_response_fits(data,cfg);
record('RMSE-time crossings',max(abs(data.TurningPrincipalCrossings.Time_h-s.data.TurningPrincipalCrossings.Time_h)),1e-7);
source=struct('Layouts',d(d.Platform=="A",:),'Platforms',data.Models,'ReferenceLength_m',data.Domain.MappingLength_m, ...
 'PrincipalErrorLimits_m',[.01 .03]*o.Dmax_m,'PreviousCrossings',data.TurningPrincipalCrossings);
cfg=struct('CoefficientGrid_m_per_rad',unique([0:300 310:10:500]),'Lambda',1e-4,'Paths',paths,'RootGridPoints',6000,'ResultDir',cfg.ProcessedDir);
actual=calculate_normalized_crossings(source,cfg);s=load(fullfile(ref,'normalized_crossover_data.mat'),'output');
[present,ids]=ismember(actual.Sweep.Coefficient_m_per_rad,s.output.Sweep.Coefficient_m_per_rad);assert(all(present));
record('0–500 m/rad crossing sweep',max(abs(actual.Sweep.CrossoverTimeStar-s.output.Sweep.CrossoverTimeStar(ids))),1e-7);
checks=table(fields,errors,tolerances,isfinite(errors)&errors<=tolerances,'VariableNames',{'Check','AbsoluteDifference','Tolerance','Pass'});
writetable(checks,fullfile(root,'validation','reference_recalculation.csv'));assert(all(checks.Pass));disp(checks);
 function record(name,value,tol)
  fields(end+1,1)=name;errors(end+1,1)=value;tolerances(end+1,1)=tol;
 end
end
