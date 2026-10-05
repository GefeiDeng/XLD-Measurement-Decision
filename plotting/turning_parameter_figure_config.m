function cfg=turning_parameter_figure_config
% All settings here reproduce the user-approved 16 x 7.6 cm layout.
cfg.size_cm=[16 7.6];
cfg.font='Times New Roman'; cfg.tick_font=9; cfg.label_font=9;
cfg.count_font=9; cfg.parameter_font=9; cfg.key_font=9; cfg.panel_font=9;
cfg.line_width=0.8; cfg.colors=[.12 .39 .64;.80 .16 .16];
cfg.left_axes_cm=[1.10 4.80 5.15 2.15;1.10 1.30 5.15 2.15];
cfg.coefficient_axes_cm=[7.50 1.30 7.95 5.65];
cfg.coefficient_xlim=[15 65]; cfg.frequency_ylim=[0 60];
cfg.coefficient_xticks=15:10:65; cfg.frequency_yticks=0:10:60;
cfg.y_limits=[13 20]; cfg.box_width=.36; cfg.bin_width=1;
cfg.platforms=["A","B"]; cfg.years=[2023 2020];
cfg.title_gap_cm=.10;cfg.count_gap_cm=.06;
cfg.range_heights=[56.7 49.0 41.3 33.6];
cfg.parameter_label_x=35; cfg.parameter_value_offset=3.8;
cfg.output_name='Turning_model_discussion_direct_labels';
end
