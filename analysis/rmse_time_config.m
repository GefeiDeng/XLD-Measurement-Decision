function cfg = rmse_time_config(root)
%RMSE_TIME_CONFIG Explicit data/domain/layout settings; no phase ensemble.
if nargin<1,root=fileparts(fileparts(mfilename('fullpath')));end
cfg.Root=string(root);cfg.Version="xld-rmse-time-riverpolygon-v2.0";
cfg.DEMFile=fullfile(root,'data','raw','dem_cropped.tif');
cfg.ChannelFile=fullfile(root,'results','survey','channel_model.mat');
cfg.ModelFile=fullfile(root,'results','turning','models.mat');
cfg.ResultDir=fullfile(root,'results','survey');cfg.FigureDir=fullfile(root,'figures');
cfg.EvaluationDomain="polygon"; % user-confirmed River_Polygon, original end closures
cfg.EvaluationBoundaryXY=readmatrix(fullfile(root,'data','raw','geometry','evaluation_boundary.csv')); % exact accepted boundary
cfg.NoDataValue=[]; % default uses channelModel.noDataValue; no guessing from finite() alone
cfg.RequestedSpacingStar=[.10 .15 .20 .40 .60 .80 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7 7.5 8]';
cfg.RequestedSpacing_m=[]; % if supplied, replaces width multiples
cfg.Schemes=["BCS" "PCZ"];
cfg.TrajectoryResolution_m=0.5;cfg.AuxiliaryResolution_m=0.5;cfg.AuxiliaryLineCount=11;
cfg.SampleMethod="linear";cfg.MaximumSampleFallbackDistance_m=5;
cfg.AuxiliaryDepthMethod="linear";cfg.IntersectionMergeTolerance_m=1e-4;
cfg.AnchorTolerance_m=1e-3;
cfg.ExtrapolationMethod="nearest"; % recorded exterior fill; natural neighbour is used inside hull
cfg.QueryChunkSize=250000;cfg.ResumeCompletedCases=true;
cfg.WritePointCSV=false;cfg.WriteSurface=true;cfg.PlotRasterStride=12;
cfg.CaseIndices=[]; % empty=all; a subset can be used for pilot calculations
cfg.VerifyGeometryReference=false; % previous narrow-route geometry is not a reference for this domain
end

