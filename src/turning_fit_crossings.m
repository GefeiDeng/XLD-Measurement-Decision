function [allCrossings,principal]=turning_fit_crossings(data,cfg)
%TURNING_FIT_CROSSINGS Roots of existing continuous responses, never point joins.
allCrossings=table;
for platform=1:2
 for scenario=1:2
  if scenario==1,models=data.RMSEFits(platform,:);name="WithTurning";
  else,models=data.NoTurningFits(platform,:);name="WithoutTurning";end
  a=models{1};b=models{2};
  lo=max(a.Time_h(1),b.Time_h(1));hi=min(a.Time_h(end),b.Time_h(end));
  tt=unique([logspace(log10(lo),log10(hi),12000)'; ...
   a.Time_h(a.Time_h>lo&a.Time_h<hi);b.Time_h(b.Time_h>lo&b.Time_h<hi)]);
  fun=@(t)exp(ppval(a.PP,log(t)))-exp(ppval(b.PP,log(t)));
  yy=fun(tt);ids=find(yy(1:end-1).*yy(2:end)<0);roots=zeros(numel(ids),1);
  for k=1:numel(ids),roots(k)=fzero(fun,tt(ids(k):ids(k)+1));end
  ee=exp(ppval(a.PP,log(roots)));
  assert(all(abs(fun(roots))<1e-8),'Fitted response intersection is inaccurate.');
  relevant=ee>=cfg.TargetRMSELimits(1)&ee<=cfg.TargetRMSELimits(2)& ...
   roots<=cfg.ZoomTimeLimits(2);
  rows=table(repmat(cfg.PlatformCodes(platform),numel(roots),1), ...
   repmat(name,numel(roots),1),roots,ee,relevant,'VariableNames', ...
   {'Platform','Scenario','Time_h','RMSE_m','PrincipalTransition'});
  allCrossings=[allCrossings;rows]; %#ok<AGROW>
 end
end
principal=allCrossings(allCrossings.PrincipalTransition,:);
for platform=cfg.PlatformCodes
 for scenario=["WithTurning","WithoutTurning"]
  assert(sum(principal.Platform==platform&principal.Scenario==scenario)==1, ...
   'Expected one supported engineering transition for each platform/scenario.');
 end
end
writetable(allCrossings,fullfile(cfg.ProcessedDir,'continuous_turning_crossings.csv'));
writetable(principal,fullfile(cfg.ProcessedDir,'principal_turning_crossings.csv'));
end
