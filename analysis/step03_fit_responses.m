function output=step03_fit_responses(root)
% Numerical RMSE/time -> monotone responses and minimum-fleet decisions.
if nargin<1,root=setup_project;end
d=readtable(fullfile(root,'results','survey','RMSE_TIME.csv'),'TextType','string');
assert(height(d)==66&&numel(unique(d.CaseID))==33,'Stage 3 requires all 33 layouts. Run stage 2 without a CaseID subset first.');
dm=readtable(fullfile(root,'results','survey','common','domain_summary.csv'));
cfg=struct('Hours',1:.05:24,'TargetRstar',.01:.0001:.03,'Lambda',1e-4);
fits=cell(2,2);maps=cell(2,1);paths=["BCS","PCZ"];
for p=1:2
 platform=string(char('A'+p-1));
 for j=1:2
  q=d(d.Platform==platform&d.Path==paths(j),:);q=sortrows(q,'TotalTime_h');
  f=fit_monotone_rmse(q.TotalTime_h,q.RMSE_m,cfg.Lambda);
  f.Path=paths(j);f.D_m=q.ActualD_m;f.Width_m=mean(q.ActualD_m./q.ActualDstar);fits{p,j}=f;
 end
 maps{p}=select_rmse(fits(p,:),cfg.Hours,cfg.TargetRstar*dm.ReferenceElevationRange_m,dm.ReferenceElevationRange_m);
end
output=struct('Config',cfg,'Layouts',d,'Dmax_m',dm.ReferenceElevationRange_m,'Fits',{fits},'Maps',{maps});
folder=fullfile(root,'results','responses');if ~isfolder(folder),mkdir(folder);end
save(fullfile(folder,'rmse_only_results.mat'),'output','-v7.3');
end
