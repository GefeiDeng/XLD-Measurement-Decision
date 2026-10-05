function output=step01_calibrate_turning(root)
% Raw GPS -> prepared tracks -> turning coefficient and uncertainty.
if nargin<1,root=setup_project;end
cfg=turning_config(root);cfg.ResultDir=fullfile(root,'results','turning');
cfg.FigureDir=fullfile(root,'results','figures');cfg.VerifyReference=false;
output=run_turning_stage(cfg,"raw");
ref=readtable(fullfile(root,'reference','turning','Summary.csv'),'TextType','string');
assert(max(abs(output.Summary.Coefficient_m_per_rad-ref.Coefficient_m_per_rad))<1e-7,'Turning coefficient differs from reference.');
assert(max(abs(output.Summary.BaselineSpeed_mps-ref.BaselineSpeed_mps))<1e-8,'Baseline speed differs from reference.');
% Geometry for the trajectory panels is drawn from these newly prepared GPS.
prepare_gps_figure_data(cfg.ResultDir);
end
