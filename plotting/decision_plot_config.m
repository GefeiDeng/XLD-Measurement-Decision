function cfg=decision_plot_config(root)
%DECISION_PLOT_CONFIG Central data and style interface for the draft.
if nargin<1,root=fileparts(fileparts(mfilename('fullpath')));end
cfg.Root=string(root);
cfg.InputDir=fullfile(root,'1 数据读取','inputs');
cfg.ProcessedDir=fullfile(root,'2 数据处理','处理结果');
cfg.AuditDir=fullfile(root,'2 数据处理','核对结果');
cfg.OutputDir=fullfile(root,'4 图片保存','输出');
cfg.TimeLimits_h=[4 18];
cfg.TargetLimits_m=[.5 1.227178344726564];
cfg.TargetGridCount=179;
cfg.PlatformCodes=["A","B"];
cfg.PlatformYears=[2023 2020];
cfg.PlatformTitles=["Platform 2023","Platform 2020"];
cfg.FigureSize_cm=[16 13.1];
cfg.AxesBase_cm=[1.30 7.65 5.25 4.50];
cfg.ColumnStep_cm=7.65;
cfg.RowStep_cm=6.05;
cfg.ColourbarGap_cm=.28;
cfg.ColourbarWidth_cm=.22;
cfg.ColourbarTitleGap_cm=.10;
cfg.ColourbarTitleInkOffset_cm=.11;
cfg.ColourbarAlignment='title-top and bar-bottom aligned to axes';
cfg.ColourbarHeaderFont=9;
cfg.FleetDisplayCap=5;
cfg.FontName='Times New Roman';
cfg.TickFont=9;cfg.LabelFont=9;cfg.ColourbarTickFont=9;
cfg.PanelFont=9;cfg.PathFont=9;
cfg.PathLabelPositions={ [.73 .50;.35 .70], [.73 .50;.15 .70] };
cfg.AxisLineWidth=.8;cfg.PathBoundaryWidth=.85;
cfg.FleetBoundaryWidth=.35;cfg.FleetBoundaryColour=[.48 .48 .48];
cfg.XTicks=4:2:18;cfg.YTicks=.5:.1:1.2;
cfg.SpacingTicks_m=[10 20 40 60 100 200 400];
cfg.ShowExample=false;
cfg.ExampleTime_h=4;cfg.ExampleTarget_m=.818118896484376;
cfg.ExampleMarkerSize=5.8;cfg.ExampleFill=[1 .85 .15];
cfg.ExampleTextOffset=[.45 .025];cfg.ExampleLabel='Example';
cfg.Resolution=400;
cfg.OutputStem='Engineering_survey_decisions_4to18h_RMSE0p5_draft';

end
