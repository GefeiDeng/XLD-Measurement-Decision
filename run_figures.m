function run_figures(mode)
% Fast: run_figures. Newly computed results: run_figures("computed").
if nargin<1,mode="reference";end
assert(ismember(string(mode),["reference","computed"]));root=setup_project;
if mode=="reference"
 base=fullfile(root,'reference');turn=fullfile(base,'turning');response=base;
else
 base=fullfile(root,'results','figure_data');turn=fullfile(root,'results','turning');response=fullfile(root,'results','responses');
end
out=fullfile(root,'figures',mode);audit=fullfile(out,'data');if ~isfolder(audit),mkdir(audit);end
s=load(fullfile(turn,'used_gps_trajectories.mat'),'data');cfg=trajectory_figure_config(root);cfg.AuditDir=audit;
[fig,~]=plot_segmented_gps(s.data,cfg);stats=load_turning_plot_data(turn);
add_turning_analysis_panels(fig,stats,cfg);export_ijsr_pdf(fig,fullfile(out,'Fig03_turning_calibration.pdf'));close(fig);
s=load(fullfile(base,'reconstruction_and_rmse_time.mat'),'data');data=s.data;
cfg=draft_plot_config(root);cfg.ProcessedDir=audit;
fig=plot_reconstruction_draft(data,cfg);export_ijsr_pdf(fig,fullfile(out,'Fig04_reconstruction.pdf'));close(fig);
fig=plot_combined_rmse_time(data,cfg);export_ijsr_pdf(fig,fullfile(out,'Fig05_rmse_time.pdf'));close(fig);
s=load(fullfile(response,'rmse_only_results.mat'),'output');source.Output=s.output;
source.Palette=readtable(fullfile(root,'reference','original_palette.csv'));
dcfg=decision_plot_config(root);dd=prepare_decision_plot_data(source,dcfg);
writetable(dd.GridTable,fullfile(audit,'Fig06_decision_grid.csv'));
writetable(dd.Examples,fullfile(audit,'Fig06_examples.csv'));
fig=plot_engineering_decisions(dd,dcfg);export_ijsr_pdf(fig,fullfile(out,'Fig06_decisions.pdf'));close(fig);
pcfg=turning_parameter_figure_config;plot_turning_model_discussion(turn,audit,pcfg);
files=dir(fullfile(audit,'*.pdf'));assert(numel(files)==1);movefile(fullfile(files.folder,files.name),fullfile(out,'Fig07_turning_sensitivity.pdf'));
s=load(fullfile(base,'normalized_crossover_data.mat'),'output');
fig=plot_crossover_semilog(s.output,cfg);export_ijsr_pdf(fig,fullfile(out,'Fig08_crossing.pdf'));close(fig);
writetable(data.Time,fullfile(audit,'Fig05_numerical_data.csv'));
writetable(data.TurningResponseCurves,fullfile(audit,'Fig05_fitted_curves.csv'));
writetable(data.TurningPrincipalCrossings,fullfile(audit,'Fig05_crossings.csv'));
writetable(s.output.Sweep,fullfile(audit,'Fig08_sweep.csv'));
writetable(s.output.PlatformPoints,fullfile(audit,'Fig08_platform_points.csv'));
fprintf('Figures 3–8 saved to %s\n',out);
end
