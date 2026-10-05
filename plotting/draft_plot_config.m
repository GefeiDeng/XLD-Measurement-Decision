function cfg=draft_plot_config(root)
%DRAFT_PLOT_CONFIG Package-local data paths and the approved figure styles.
if nargin<1,root=fileparts(fileparts(mfilename('fullpath')));end
cfg.Root=string(root);
cfg.InputDir=fullfile(root,'1 数据读取','inputs');
cfg.ProcessedDir=fullfile(root,'2 数据处理','处理结果');
cfg.OutputDir=fullfile(root,'4 图片保存','PDF交付');
cfg.ManifestFile=fullfile(root,'4 图片保存','figure_manifest.csv');
cfg.PlatformCodes=["A","B"];cfg.PlatformTitles=["Platform 2023","Platform 2020"];
cfg.CrossingColours=[.45 .20 .60;.05 .50 .35];cfg.CrossingMarkers={'o','s'};
cfg.CrossingMarkerSize=4.8;
cfg.Paths=["BCS","PCZ"];cfg.PathColours=[.12 .39 .64;.80 .16 .16];
cfg.Markers={'o','^'};cfg.FontName='Times New Roman';
cfg.TickFont=9;cfg.LabelFont=9;cfg.LegendFont=9;cfg.PanelFont=9;
cfg.LineWidth=.8;
cfg.CurveColumnStep_cm=7.70;
cfg.CombinedFigureSize_cm=[16 7.40];
cfg.CombinedAxes_cm=[1.35 2.00 6.10 4.70];
cfg.CombinedMarkerSize=3.0;
cfg.CombinedLegendItemTokenSize=[16 8];
cfg.LegendMarkerSize=3.5;
cfg.InsetOffsetSize_cm=[.90 .58 2.75 1.55];
cfg.InsetTickFont=9;
cfg.FullTimeLimits=[0 110];cfg.FullRMSELimits=[0 2.80];
cfg.ZoomTimeLimits=[0 24];cfg.ZoomRMSELimits=[0 1.50];
cfg.LoglogPreview=true;
cfg.LogFullTimeLimits=[1 110];cfg.LogFullRMSELimits=[.07 3];
cfg.LogZoomTimeLimits=[1 24];cfg.LogZoomRMSELimits=[.3 1.5];
cfg.MapFigureSize_cm=[16.0 16.10];
cfg.MapAxes_cm=[1.05 12.60 5.35 3.10];
cfg.MapColumnStep_cm=7.95;cfg.MapRowStep_cm=3.75;
cfg.ColourbarWidth_cm=.20;cfg.ColourbarGap_cm=.13;
cfg.RouteColour=[0 0 0];cfg.RouteLineWidth=.5;
cfg.DenseErrorLimits=[-.3 .3];
cfg.CoefficientLimits_m_per_rad=[0 500];
cfg.CrossoverFigureSize_cm=[8 7.2];
cfg.CrossoverAxes_cm=[1.55 1.55 5.90 5.10];
cfg.ElevationMap=parula(256);
cfg.ErrorMap=[linspace(.12,1,128)' linspace(.35,1,128)' ones(128,1); ...
 ones(128,1) linspace(1,.28,128)' linspace(1,.10,128)'];
cfg.PanelFont=9;cfg.PanelLabelGap_cm=.10;
end
