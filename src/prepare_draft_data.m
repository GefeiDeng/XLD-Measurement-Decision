function data=prepare_draft_data(source,cfg)
%PREPARE_DRAFT_DATA Check full-domain cached RMSE and form display-only snapshots.
% Curve segments are straight connections of numerical points, never fitted.
d=source.Layouts;
assert(all(d.BaselineSpeed_mps>0)&all(d.RMSE_m>0));
t=(d.PathLength_m+d.Coefficient_m_per_rad.*d.AbsoluteTurnAngle_rad) ...
 ./d.BaselineSpeed_mps/3600;
t0=d.PathLength_m./d.BaselineSpeed_mps/3600;
assert(max(abs(t-d.TotalTime_h))<1e-8,'Stored and recalculated time differ.');
assert(all(t0<=t+1e-10),'Ignoring a nonnegative penalty increased time.');
timeTable=d(:,{'CaseID','Path','Platform','EffectiveIntervals','ActualD_m', ...
 'PathLength_m','AbsoluteTurnAngle_rad','BaselineSpeed_mps', ...
 'Coefficient_m_per_rad','RMSE_m'});
timeTable.WithTurning_h=t;
timeTable.WithoutTurning_h=t0;
timeTable.TurningExtra_h=t-t0;
timeTable.TurningShare_pct=100*(t-t0)./t;
writetable(timeTable,fullfile(cfg.ProcessedDir,'time_comparison.csv'));
data.Time=timeTable;data.Models=source.Models;data.Domain=source.Domain;
data.SourceManifest=table();

p=source.Preview;r=source.Reference;
boundary=double(r.EvaluationBoundaryXY);
origin=min(boundary,[],1);
[x,~]=intrinsicToWorld(p.R,p.PreviewColumns,ones(size(p.PreviewColumns)));
[~,y]=intrinsicToWorld(p.R,ones(size(p.PreviewRows)),p.PreviewRows);
[cc,rr]=meshgrid(p.PreviewColumns,p.PreviewRows);
ids=uint32(sub2ind(r.RasterSize,rr(:),cc(:)));
[present,location]=ismember(ids,r.EvaluationIndices);
present=present&logical(p.PreviewMask(:));
truth=single(r.ReferenceElevation_m);
displayTruth=nan(size(p.PreviewZ),'single');
displayTruth(present)=truth(location(present));
assert(all(displayTruth(present)==p.PreviewZ(present)), ...
 'Display reference and common evaluation reference differ.');
data.Map=struct('X_km',(x-origin(1))/1000,'Y_km',(y-origin(2))/1000, ...
 'Truth',displayTruth,'Boundary_km',(boundary-origin)/1000, ...
 'Origin_m',origin,'RasterStride',median(diff(p.PreviewRows)), ...
 'DisplayCellSize_m',p.R.CellExtentInWorldX*median(diff(p.PreviewRows)), ...
 'EvaluationCells',numel(truth));
data.Map.Limits=[min(data.Map.Boundary_km(:,1))-.15 ...
 max(data.Map.Boundary_km(:,1))+.15 min(data.Map.Boundary_km(:,2))-.10 ...
 max(data.Map.Boundary_km(:,2))+.10];
data.Map.ElevationLimits=[floor(double(min(truth))/5)*5 ceil(double(max(truth))/5)*5];
caseTable=source.Selected(:,{'CaseID','Path','Density','EffectiveIntervals', ...
 'ActualD_m','RMSE_m','MaximumAbsoluteError_m','EvaluationCells'});
audited=zeros(4,1);
for k=1:4
 s=load(source.SurfaceFiles(k),'Prediction_m','Metrics','CaseComplete');
 assert(s.CaseComplete&&numel(s.Prediction_m)==numel(truth), ...
  'Surface is incomplete or uses a different evaluation domain.');
 difference=double(s.Prediction_m)-double(truth);
 audited(k)=sqrt(mean(difference.^2));
 assert(abs(audited(k)-caseTable.RMSE_m(k))<1e-8, ...
  'Full-domain archived surface does not reproduce stored RMSE.');
 prediction=nan(size(displayTruth),'single');
 prediction(present)=s.Prediction_m(location(present));
 data.Surfaces(k)=struct('CaseID',caseTable.CaseID(k),'Path',caseTable.Path(k), ...
  'Density',caseTable.Density(k),'N',caseTable.EffectiveIntervals(k), ...
  'Spacing_m',caseTable.ActualD_m(k),'RMSE_m',caseTable.RMSE_m(k), ...
  'Prediction',prediction,'Error',prediction-displayTruth);
 fprintf('Verified %s: %.9f m on %d cells.\n',caseTable.CaseID(k),audited(k),numel(truth));
end
caseTable.AuditedRMSE_m=audited;
caseTable.SourceSurface=source.SurfaceFiles;
writetable(caseTable,fullfile(cfg.ProcessedDir,'selected_reconstruction_cases.csv'));
data.SelectedCases=caseTable;
errorMaximum=max(caseTable.MaximumAbsoluteError_m);
data.Map.ErrorLimits=ceil(errorMaximum/5)*5*[-1 1];
clear truth difference s
data=attach_route_overlays(data,source.RouteFiles,cfg);

intersections=table;summary=table;
range=cfg.TargetRMSELimits;
for ip=1:numel(cfg.PlatformCodes)
 platform=cfg.PlatformCodes(ip);
 for scenario=["WithTurning","WithoutTurning"]
  curves=cell(1,2);
  for j=1:2
   z=timeTable(timeTable.Platform==platform&timeTable.Path==cfg.Paths(j),:);
   if scenario=="WithTurning",tx=z.WithTurning_h;else,tx=z.WithoutTurning_h;end
   [tx,index]=sort(tx);assert(all(diff(tx)>0));
   curves{j}=[tx z.RMSE_m(index)];
  end
  [times,errors]=polyline_intersections(curves{1},curves{2});
  isRelevant=errors>=range(1)&errors<=range(2)&times<=cfg.ZoomTimeLimits(2);
  rows=table(repmat(platform,numel(times),1),repmat(scenario,numel(times),1), ...
   times,errors,isRelevant,'VariableNames', ...
   {'Platform','Scenario','Time_h','RMSE_m','WithinDecisionErrorAndTimeRange'});
  intersections=[intersections;rows]; %#ok<AGROW>
 end
 with=intersections(intersections.Platform==platform& ...
  intersections.Scenario=="WithTurning"&intersections.WithinDecisionErrorAndTimeRange,:);
 without=intersections(intersections.Platform==platform& ...
  intersections.Scenario=="WithoutTurning"&intersections.WithinDecisionErrorAndTimeRange,:);
 if height(with)==1&&height(without)==1
  row=table(platform,with.Time_h,without.Time_h,with.Time_h-without.Time_h, ...
   100*(with.Time_h-without.Time_h)/with.Time_h,with.RMSE_m,without.RMSE_m, ...
   'VariableNames',{'Platform','WithTurningCrossing_h','WithoutTurningCrossing_h', ...
   'CrossingDifference_h','DifferenceRelativeToWithTurning_pct', ...
   'WithTurningCrossingRMSE_m','WithoutTurningCrossingRMSE_m'});
  summary=[summary;row]; %#ok<AGROW>
 end
end
data.Intersections=intersections;data.CrossingComparison=summary;
writetable(intersections,fullfile(cfg.ProcessedDir,'polyline_intersections.csv'));
writetable(summary,fullfile(cfg.ProcessedDir,'crossing_comparison.csv'));
checks=table(["stored time formula";"no-turn time <= full time"; ...
 "full-domain RMSE reproduced for all four cached surfaces"; ...
 "display values come from the unchanged common evaluation domain"],true(4,1), ...
 'VariableNames',{'Check','Pass'});
writetable(checks,fullfile(cfg.ProcessedDir,'verification.csv'));
data.Checks=checks;
data=attach_existing_rmse_fits(data,cfg);
data=attach_turning_response_fits(data,cfg);
end

function [roots,errors]=polyline_intersections(a,b)
% Exact intersections of the drawn straight segments; no curve fitting.
lo=max(a(1,1),b(1,1));hi=min(a(end,1),b(end,1));
if lo>=hi,roots=zeros(0,1);errors=roots;return;end
knots=unique([lo;hi;a(a(:,1)>lo&a(:,1)<hi,1);b(b(:,1)>lo&b(:,1)<hi,1)]);
diff=interp1(a(:,1),a(:,2),knots,'linear')-interp1(b(:,1),b(:,2),knots,'linear');
roots=knots(abs(diff)<1e-12);
for k=1:numel(knots)-1
 if diff(k)*diff(k+1)<0
  roots(end+1,1)=knots(k)-diff(k)*(knots(k+1)-knots(k))/(diff(k+1)-diff(k)); %#ok<AGROW>
 end
end
roots=sort(roots);
if ~isempty(roots),roots=roots([true;abs(diff_values(roots))>1e-9]);end
errors=interp1(a(:,1),a(:,2),roots,'linear');
end
function dx=diff_values(x)
dx=x(2:end)-x(1:end-1);
end
