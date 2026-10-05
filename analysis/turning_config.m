function cfg = turning_config(root)
%TURNING_CONFIG Case paths and all processing/assessment settings.
% Edit Platforms for another case. Algorithms contain no Xiaolangdi paths or dates.
if nargin<1,root=fileparts(fileparts(mfilename('fullpath')));end
cfg.Root=string(root); cfg.Version="xld-turning-engineering-v1.0";
cfg.TrackDir=fullfile(cfg.Root,'results','turning','rebuilt_gps');
cfg.ResultDir=fullfile(cfg.Root,'results','turning');cfg.FigureDir=fullfile(cfg.Root,'figures');
cfg.VerifyReference=false;cfg.RunPreprocessingSensitivity=true;
cfg.Platforms=struct('Name',{"A","B"},'SourceName',{"Medium","Large"}, ...
    'Year',{2023,2020},'FilePattern',{'medium_2023*_track.csv','large_2020*_track.csv'});
cfg.SpatialStep_m=1;cfg.PositionSmooth_m=15;cfg.HeadingBaseline_m=20;
cfg.HeadingSmooth_m=9;cfg.HeadingRateSmooth_m=5;cfg.BlockLength_m=20;
cfg.MinimumSegmentSpeed_mps=0.05;cfg.MaximumSegmentSpeed_mps=6;
cfg.MinimumOperationLength_m=1000;cfg.MinimumOperationBlocks=50;
cfg.LowAngleFraction=0.40;cfg.BaselineHalfWindow_m=1000;
cfg.BaselineSpeedMADMultiplier=3;cfg.MinimumSupportFraction=0.50;
cfg.RandomSeed=20260814;cfg.BootstrapReplicates=5000;cfg.MovingBlockCount=25;
cfg.BaseWindowLength_m=1000;cfg.MinimumWindowCoverage=0.90;cfg.MaximumScale_km=10;
cfg.TimeStep_s=0.5;cfg.MinGap_s=5;cfg.GapFactor=5;cfg.MaxLinkSpeed_mps=6;
cfg.TimeSmooth_s=4;cfg.SpeedSmooth_s=2;cfg.StopSpeed_mps=0.15;
cfg.StopMinimum_s=60;cfg.OperationMinimum_s=60;
% Case coordinate filter; replace with the bounds of a new metric coordinate system.
cfg.ValidXRange_m=[5e5 7e5];cfg.ValidYRange_m=[3.8e6 4.0e6];
cfg.CaseDatesA=[20230706 20230707 20230708 20230709 20230710];
cfg.CaseDatesB=[20200817 20200823];
cfg.PreprocessingVariants=table( ...
 ["Baseline";"HeadingBaseline10m";"HeadingBaseline40m";"BlockLength10m"; ...
 "BlockLength40m";"LowAngle30pct";"LowAngle50pct";"BaselineWindow500m";"BaselineWindow1500m"], ...
 [20;10;40;20;20;20;20;20;20],[20;20;20;10;40;20;20;20;20], ...
 [0.4;0.4;0.4;0.4;0.4;0.3;0.5;0.4;0.4], ...
 [1000;1000;1000;1000;1000;1000;1000;500;1500], ...
 'VariableNames',{'Variant','HeadingBaseline_m','BlockLength_m', ...
 'LowAngleFraction','BaselineHalfWindow_m'});
end
