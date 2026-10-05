function output=calculate_normalized_crossings(source,cfg)
%CALCULATE_NORMALIZED_CROSSINGS Vary turning cost, retaining numerical RMSE.
% Tstar=(S+C*Theta)/Lc; Cstar=C/Lc. Reference speed cancels exactly.
Lc=source.ReferenceLength_m;
coefficients=unique([cfg.CoefficientGrid_m_per_rad(:); ...
 source.Platforms.Coefficient_m_per_rad]);
nc=numel(coefficients);allRoots=table;
mainTime=nan(nc,1);mainError=nan(nc,1);counts=zeros(nc,1);
maxResidual=nan(nc,1);localSignCheck=false(nc,1);fits=cell(nc,2);
focusCounts=zeros(nc,1);
previousBranchError=source.PreviousCrossings.RMSE_m( ...
 find(source.PreviousCrossings.Scenario=="WithoutTurning",1));
for j=1:nc
 for p=1:2
  q=source.Layouts(source.Layouts.Path==cfg.Paths(p),:);
  tstar=(q.PathLength_m+coefficients(j)*q.AbsoluteTurnAngle_rad)/Lc;
  f=fit_monotone_rmse(tstar,q.RMSE_m,cfg.Lambda);
  f.TimeStar=f.Time_h;f=rmfield(f,'Time_h');
  f.Path=cfg.Paths(p);f.Coefficient_m_per_rad=coefficients(j);
  fits{j,p}=f;
 end
 a=fits{j,1};b=fits{j,2};
 lo=max(a.TimeStar(1),b.TimeStar(1));hi=min(a.TimeStar(end),b.TimeStar(end));
 grid=unique([logspace(log10(lo),log10(hi),cfg.RootGridPoints)'; ...
  a.TimeStar(a.TimeStar>lo&a.TimeStar<hi); ...
  b.TimeStar(b.TimeStar>lo&b.TimeStar<hi)]);
 delta=@(t)exp(ppval(a.PP,log(t)))-exp(ppval(b.PP,log(t)));
 d=delta(grid);brackets=find(d(1:end-1).*d(2:end)<0);
 roots=zeros(numel(brackets),1);
 for k=1:numel(brackets),roots(k)=fzero(delta,grid(brackets(k):brackets(k)+1));end
 error=exp(ppval(a.PP,log(roots)));residual=abs(delta(roots));
 down=delta(roots.*exp(-1e-5))>0&delta(roots.*exp(1e-5))<0;
 up=delta(roots.*exp(-1e-5))<0&delta(roots.*exp(1e-5))>0;
 assert(all(down|up),'Intersection direction could not be resolved.');
 focus=error>=source.PrincipalErrorLimits_m(1)& ...
  error<=source.PrincipalErrorLimits_m(2);
 eligible=focus&down;
 count=sum(eligible);counts(j)=count;
 focusCounts(j)=sum(focus);
 originalBranch=false(size(roots));
 if count>=1
  candidates=find(eligible);
  [~,nearest]=min(abs(error(candidates)-previousBranchError));
  selected=candidates(nearest);originalBranch(selected)=true;
  mainTime(j)=roots(selected);mainError(j)=error(selected);
  previousBranchError=mainError(j);
  maxResidual(j)=residual(selected);
  % Verify advantage directions within 5 percent of the main crossing.
  nearby=mainTime(j)*[.95 1.05];
  localSignCheck(j)=all(nearby>=lo&nearby<=hi)& ...
   delta(nearby(1))>0&delta(nearby(2))<0;
 end
 rows=table(repmat(coefficients(j),numel(roots),1), ...
  repmat(coefficients(j)/Lc,numel(roots),1),roots,error,residual,down,up,focus,eligible, ...
  originalBranch, ...
  'VariableNames',{'Coefficient_m_per_rad','CoefficientStar','TimeStar', ...
  'RMSE_m','AbsoluteDifference_m','PCZtoBCS','BCStoPCZ','WithinFocusErrorRange', ...
  'PrincipalCrossingCandidate','OriginalBranch'});
 allRoots=[allRoots;rows]; %#ok<AGROW>
end
assert(all(allRoots.AbsoluteDifference_m<1e-8),'Intersection accuracy check failed.');
output.Sweep=table(coefficients,coefficients/Lc,mainTime,mainError,counts, ...
 maxResidual,localSignCheck,focusCounts,'VariableNames',{'Coefficient_m_per_rad', ...
 'CoefficientStar','CrossoverTimeStar','CrossoverRMSE_m','PrincipalRootCount', ...
 'AbsoluteDifference_m','LocalPreferenceVerified','FocusRootCount'});
output.AllCrossings=allRoots;
output.FocusCrossings=allRoots(allRoots.WithinFocusErrorRange,:);
output.Fits=fits;
output.Source=source;
output.ReferenceLength_m=Lc;
zero=find(coefficients==0,1);
output.ZeroTurningTimeStar=mainTime(zero);
output.ZeroTurningRMSE_m=mainError(zero);
output.PlatformPoints=table;
output.Validation=table;
for p=1:height(source.Platforms)
 platform=source.Platforms.Platform(p);
 speed=source.Platforms.BaselineSpeed_mps(p);
 c=source.Platforms.Coefficient_m_per_rad(p);
 idx=find(coefficients==c,1);
 predictedHour=mainTime(idx)*Lc/(3600*speed);
 rows=table(platform,source.Platforms.Year(p),speed,c,c/Lc, ...
  mainTime(idx),mainError(idx),predictedHour, ...
  (mainTime(idx)/mainTime(zero)-1)*100,'VariableNames',{'Platform','Year', ...
  'BaselineSpeed_mps','Coefficient_m_per_rad','CoefficientStar','CrossoverTimeStar', ...
  'CrossoverRMSE_m','RestoredCrossoverTime_h','NormalizedDelay_pct'});
 output.PlatformPoints=[output.PlatformPoints;rows]; %#ok<AGROW>
 for scenario=["WithTurning","WithoutTurning"]
  q=source.PreviousCrossings(source.PreviousCrossings.Platform==platform& ...
   source.PreviousCrossings.Scenario==scenario,:);
  assert(height(q)==1);
  if scenario=="WithTurning",currentTime=mainTime(idx);currentError=mainError(idx);
  else,currentTime=mainTime(zero);currentError=mainError(zero);end
  oldTimeStar=3600*speed*q.Time_h/Lc;
  relativeDifference=abs(currentTime-oldTimeStar)/oldTimeStar;
  assert(relativeDifference<1e-5,'Normalized crossing does not reproduce previous figure.');
  assert(abs(currentError-q.RMSE_m)<1e-5,'Crossing error differs from previous figure.');
  rows=table(platform,scenario,oldTimeStar,currentTime,relativeDifference, ...
   abs(currentError-q.RMSE_m),'VariableNames',{'Platform','Scenario', ...
   'PreviousTimeStar','RecalculatedTimeStar','RelativeTimeDifference', ...
   'RMSEDifference_m'});
  output.Validation=[output.Validation;rows]; %#ok<AGROW>
 end
end
if ~isfolder(cfg.ResultDir),mkdir(cfg.ResultDir);end
writetable(output.Sweep,fullfile(cfg.ResultDir,'normalized_crossover_sweep.csv'));
writetable(output.AllCrossings,fullfile(cfg.ResultDir,'all_supported_crossings.csv'));
writetable(output.FocusCrossings,fullfile(cfg.ResultDir,'engineering_range_crossings.csv'));
writetable(output.PlatformPoints,fullfile(cfg.ResultDir,'platform_normalized_points.csv'));
writetable(output.Validation,fullfile(cfg.ResultDir,'previous_figure_consistency.csv'));
fprintf('Normalized crossover: %d coefficients; %d to %d focus roots per coefficient.\n', ...
 nc,min(focusCounts),max(focusCounts));
disp(output.PlatformPoints);
end
