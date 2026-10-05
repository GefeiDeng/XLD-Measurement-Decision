function data=attach_turning_response_fits(data,cfg)
%ATTACH_TURNING_RESPONSE_FITS Same RMSE data; zero-turn time uses the existing fitter.
data.NoTurningFits=cell(2,2);curves=table;residuals=table;
for row=1:2
 for path=1:2
  q=data.Time(data.Time.Platform==cfg.PlatformCodes(row)&data.Time.Path==cfg.Paths(path),:);
  f=data.RMSEFits{row,path};
  % The existing with-turning decision fit is reused without alteration.
  zero=fit_monotone_rmse(q.WithoutTurning_h,q.RMSE_m,f.Lambda);
  zero.Path=cfg.Paths(path);data.NoTurningFits{row,path}=zero;
  for scenario=1:2
   if scenario==1
    model=f;name="WithTurning";times=q.WithTurning_h;
   else
    model=zero;name="WithoutTurning";times=q.WithoutTurning_h;
   end
   tt=unique([logspace(log10(model.Time_h(1)),log10(model.Time_h(end)),1200)'; ...
    model.Time_h(:)]);
   ee=exp(ppval(model.PP,log(tt)));
   assert(all(isfinite(ee)&ee>0));
   rows=table(repmat(cfg.PlatformCodes(row),numel(tt),1), ...
    repmat(cfg.Paths(path),numel(tt),1),repmat(name,numel(tt),1),tt,ee, ...
    'VariableNames',{'Platform','Path','Scenario','Time_h','FittedRMSE_m'});
   curves=[curves;rows]; %#ok<AGROW>
   fitted=exp(ppval(model.PP,log(times)));
   rows=table(q.Platform,q.Path,repmat(name,height(q),1),q.CaseID,times, ...
    q.RMSE_m,fitted,q.RMSE_m-fitted,'VariableNames',{'Platform','Path', ...
    'Scenario','CaseID','Time_h','NumericalRMSE_m','FittedRMSE_m','Residual_m'});
   residuals=[residuals;rows]; %#ok<AGROW>
  end
 end
end
data.TurningResponseCurves=curves;data.TurningResponseResiduals=residuals;
writetable(curves,fullfile(cfg.ProcessedDir,'combined_continuous_rmse_time.csv'));
writetable(residuals,fullfile(cfg.ProcessedDir,'combined_fitted_vs_numerical.csv'));
[data.TurningFitCrossings,data.TurningPrincipalCrossings]=turning_fit_crossings(data,cfg);
fprintf('Prepared combined continuous responses using unchanged numerical RMSE and existing fit settings.\n');
end
