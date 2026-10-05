function run_all
% Recompute every reported analysis from the packaged RAW inputs.
root=setup_project;
step01_calibrate_turning(root);
step02_reconstruct_bathymetry(root);
step03_fit_responses(root);
step04_prepare_figure_data(root);
step05_calculate_crossings(root);
run_figures("computed");
fprintf('Full raw-data reproduction completed. See results/ and figures/computed/.\n');
end
