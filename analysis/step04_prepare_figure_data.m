function step04_prepare_figure_data(root)
% Full-resolution results -> small figure tables and display-only rasters.
if nargin<1,root=setup_project;end
cfg=draft_plot_config(root);cfg.ProcessedDir=fullfile(root,'results','figure_data');
cfg.ResponseRoot=fullfile(root,'results','responses');cfg.InputDir=cfg.ProcessedDir;
cfg.TargetRMSELimits=[.01 .03]*40.9059448242188;cfg.RouteDisplayStep_m=5;
if ~isfolder(cfg.ProcessedDir),mkdir(cfg.ProcessedDir);end
base=fullfile(root,'results','survey');
source.Layouts=readtable(fullfile(base,'RMSE_TIME.csv'),'TextType','string');
source.Models=readtable(fullfile(root,'results','turning','Summary.csv'),'TextType','string');
source.Domain=readtable(fullfile(base,'common','domain_summary.csv'));cfg.TargetRMSELimits=[.01 .03]*source.Domain.ReferenceElevationRange_m;
source.Preview=load(fullfile(base,'common','plot_reference.mat'));
source.Reference=load(fullfile(base,'common','evaluation_reference.mat'),'EvaluationIndices','ReferenceElevation_m','RasterSize','EvaluationBoundaryXY','Dmax_m');
first=source.Layouts(source.Layouts.Platform=="A",:);rows=cell(4,1);
for j=1:2
 q=first(first.Path==cfg.Paths(j),:);[~,lo]=max(q.ActualD_m);[~,hi]=min(q.ActualD_m);rows{j}=q(lo,:);rows{j+2}=q(hi,:);
end
source.Selected=vertcat(rows{:});source.Selected.Density=["coarse";"coarse";"dense";"dense"];
source.SurfaceFiles=strings(4,1);source.RouteFiles=strings(4,1);
for j=1:4
 folder=fullfile(base,'cases',source.Selected.CaseID(j));source.SurfaceFiles(j)=fullfile(folder,'surface.mat');source.RouteFiles(j)=fullfile(folder,'route_and_observations.mat');
end
data=prepare_draft_data(source,cfg);
save(fullfile(cfg.ProcessedDir,'reconstruction_and_rmse_time.mat'),'data','-v7.3');
end
