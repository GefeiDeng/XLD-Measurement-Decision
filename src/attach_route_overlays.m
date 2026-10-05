function data=attach_route_overlays(data,routeFiles,cfg)
%ATTACH_ROUTE_OVERLAYS Display-only thinning of existing complete routes.
original=zeros(4,1);displayCount=zeros(4,1);closed=false(4,1);
for k=1:4
 r=load(routeFiles(k),'trajectory','info');
 xy=[double(r.trajectory.X_m),double(r.trajectory.Y_m)];
 step=median(hypot(diff(xy(:,1)),diff(xy(:,2))));
 stride=max(1,round(cfg.RouteDisplayStep_m/step));
 keep=unique([1:stride:size(xy,1),r.info.controlVertexIndices(:)',size(xy,1)]);
 data.Surfaces(k).RouteXY_km=(xy(keep,:)-data.Map.Origin_m)/1000;
 data.Surfaces(k).RouteSource=string(routeFiles(k));
 data.Surfaces(k).RouteDisplayStep_m=cfg.RouteDisplayStep_m;
 original(k)=size(xy,1);displayCount(k)=numel(keep);
 closed(k)=norm(xy(end,:)-xy(1,:))<1e-5;
 assert(closed(k),'Archived complete route is not closed.');
 fprintf('Attached %s route: %d display vertices from %d samples.\n', ...
  data.Surfaces(k).CaseID,displayCount(k),original(k));
end
data.RouteOverlaySummary=table(string({data.Surfaces.CaseID})',original, ...
 displayCount,closed,string(routeFiles(:)),'VariableNames', ...
 {'CaseID','ArchivedSamples','DisplayVertices','ClosedRoute','SourceFile'});
writetable(data.RouteOverlaySummary,fullfile(cfg.ProcessedDir,'route_overlay_summary.csv'));
end
