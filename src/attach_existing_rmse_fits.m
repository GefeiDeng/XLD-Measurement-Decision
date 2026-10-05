function data=attach_existing_rmse_fits(data,cfg)
%ATTACH_EXISTING_RMSE_FITS Reuse the four response curves used by decision maps.
file=fullfile(cfg.ResponseRoot,'rmse_only_results.mat');
archived=load(file,'output');
data.RMSEFits=archived.output.Fits;
data.RMSEFitSource=string(file);
curves=table;residuals=table;
for row=1:2
 for path=1:2
  f=data.RMSEFits{row,path};
  q=data.Time(data.Time.Platform==cfg.PlatformCodes(row)& ...
   data.Time.Path==cfg.Paths(path),:);
  q=sortrows(q,'WithTurning_h');
  assert(string(f.Path)==cfg.Paths(path)&&numel(f.Time_h)==height(q));
  assert(max(abs(f.Time_h(:)-q.WithTurning_h))<1e-9, ...
   'Archived continuous response uses different numerical times.');
  assert(max(abs(f.Observed_m(:)-q.RMSE_m))<1e-9, ...
   'Archived continuous response uses different numerical RMSE values.');
  tt=unique([logspace(log10(f.Time_h(1)),log10(f.Time_h(end)),1200)'; ...
   f.Time_h(:)]);
  ee=exp(ppval(f.PP,log(tt)));
  assert(all(isfinite(ee)&ee>0));
  rows=table(repmat(cfg.PlatformCodes(row),numel(tt),1), ...
   repmat(cfg.Paths(path),numel(tt),1),tt,ee,'VariableNames', ...
   {'Platform','Path','Time_h','FittedRMSE_m'});
  curves=[curves;rows]; %#ok<AGROW>
  ee=exp(ppval(f.PP,log(q.WithTurning_h)));
  rows=table(q.Platform,q.Path,q.CaseID,q.WithTurning_h,q.RMSE_m,ee, ...
   q.RMSE_m-ee,'VariableNames',{'Platform','Path','CaseID','Time_h', ...
   'NumericalRMSE_m','FittedRMSE_m','Residual_m'});
  residuals=[residuals;rows]; %#ok<AGROW>
 end
end
data.ContinuousRMSETime=curves;
data.FitResiduals=residuals;
writetable(curves,fullfile(cfg.ProcessedDir,'continuous_rmse_time.csv'));
writetable(residuals,fullfile(cfg.ProcessedDir,'fitted_vs_numerical.csv'));
end
