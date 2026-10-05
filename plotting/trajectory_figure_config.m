function cfg = trajectory_figure_config(root)
%TRAJECTORY_FIGURE_CONFIG Case adapter, physical layout, and editable style.
if nargin<1, root=fileparts(fileparts(mfilename('fullpath'))); end
cfg.InputFolder=fullfile(root,'inputs');
cfg.Dates2023=[20230706 20230707 20230708 20230709 20230710];
cfg.Dates2020=[20200817 20200823];
cfg.FilePrefixes={'medium','large'};
cfg.PlatformNames={'2023','2020'};
cfg.ProjectedCRS=32649;
cfg.FigureSize_cm=[16 18.2];
cfg.OutputStem='Turning_model_calibration';
cfg.Left_cm=1.20; cfg.Right_cm=0.55; cfg.ColumnGap_cm=0.36;
cfg.PanelHeight_cm=3.0; cfg.TopRowBottom_cm=14.7; cfg.BottomRowBottom_cm=11.05;
cfg.BoundsPadding=0.065;
cfg.FontName='Times New Roman'; cfg.TitleFont=9; cfg.PanelFont=9;
cfg.MapFont=9; cfg.FrameWidth=0.8; cfg.TrackWidth=0.7;
cfg.DateInset_cm=[0.16 0.12];
cfg.LegendNorthGap_cm=.40; cfg.LegendTopInset_cm=.12;
cfg.PlatformColors=[0.12 0.39 0.64;0.80 0.16 0.16];
cfg.Colors2020=[0.55 0.55 0.55;0.80 0.16 0.16];
cfg.LineStyles2020={'-','-'};
cfg.ScaleLength_m=2000;
cfg.ExportDPI=600;
cfg.AnalysisFont=9; cfg.AnalysisDateFont=9; cfg.ScatterSize=7;
cfg.ScatterColors=[0.48 0.66 0.82;0.90 0.49 0.47];
cfg.FitColors=[0.06 0.23 0.41;0.53 0.06 0.06];
cfg.StraightColors=[0.73 0.84 0.93;0.96 0.76 0.74];
cfg.TurningColors=[0.12 0.39 0.64;0.80 0.16 0.16];
cfg.FitPositions_cm=[1.20 5.9 6.35 3.85;9.10 5.9 6.35 3.85];
cfg.BarPosition_cm=[1.20 0.95 10.45 3.6];
cfg.BarLegendGap_cm=.25;cfg.DailyBarWidth=.74;
cfg.StatisticTopNormalized=.98;cfg.StatisticLineStep_cm=.58;
cfg.StatisticFitClearance_cm=.08;
cfg.LegendTokenSize_pt=[9 6];
cfg.LegendMarkerSize_pt=2.8;
cfg.OverallRight_cm=15.45;
cfg.TickLength_cm=0.09;
cfg.PanelLabelGap_cm=.10; % Common vertical gap; horizontal anchors are local.
cfg.ZeroLineColor=[0.35 0.35 0.35];
cfg.ZeroLineWidth_pt=0.8;
end
