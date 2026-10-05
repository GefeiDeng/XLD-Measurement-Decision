function [result,diagnostic] = predict_route(route,model,speed)
%PREDICT_ROUTE Complete ordered metric XY -> baseline, turning and total seconds.
% route: N-by-2 array, X_m/Y_m table, or CSV path with those named columns.
% model: output of xldturn.fit_model. Optional speed defaults to fitted V median.
% Include all connectors/return segments in route; no closure is added implicitly.
if nargin<3||isempty(speed),speed=model.BaselineSpeed_mps;end
validateattributes(speed,{'numeric'},{'scalar','finite','positive'});
if ischar(route)||(isstring(route)&&isscalar(route)),route=readtable(route);end
if istable(route)
    assert(all(ismember({'X_m','Y_m'},route.Properties.VariableNames)), ...
        'xldturn:RouteSchema','Route table must have X_m and Y_m columns.');
    route=[route.X_m route.Y_m];
end
validateattributes(route,{'numeric'},{'2d','ncols',2,'finite'});
route=double(route);keep=[true;hypot(diff(route(:,1)),diff(route(:,2)))>0];route=route(keep,:);
assert(size(route,1)>=2,'xldturn:RouteLength','At least two distinct points are required.');
arc0=[0;cumsum(hypot(diff(route(:,1)),diff(route(:,2))))];length_m=arc0(end);
cfg=model.Processing;
assert(length_m>=cfg.HeadingBaseline_m,'xldturn:RouteLength','Route shorter than heading scale.');
arc=unique([(0:cfg.SpatialStep_m:length_m)';length_m]);
x=interp1(arc0,route(:,1),arc,'linear');y=interp1(arc0,route(:,2),arc,'linear');
x=smoothdata(x,'sgolay',odd_window(cfg.PositionSmooth_m/cfg.SpatialStep_m,numel(arc)));
y=smoothdata(y,'sgolay',odd_window(cfg.PositionSmooth_m/cfg.SpatialStep_m,numel(arc)));
n=numel(arc);half=max(2,round(cfg.HeadingBaseline_m/(2*cfg.SpatialStep_m)));index=(1:n)';
left=max(1,index-half);right=min(n,index+half);
heading=unwrap(atan2(y(right)-y(left),x(right)-x(left)));
heading=smoothdata(heading,'sgolay',odd_window(cfg.HeadingSmooth_m/cfg.SpatialStep_m,n));
rate=smoothdata(gradient(heading,arc),'movmean',odd_window(cfg.HeadingRateSmooth_m/cfg.SpatialStep_m,n));
theta=trapz(arc,abs(rate));c=model.Coefficient_m_per_rad;
baseline=length_m/speed;extra=c*theta/speed;total=baseline+extra;
result=table(length_m,theta,c,speed,baseline,extra,total,total/3600, ...
 norm(route(1,:)-route(end,:))<1e-6,'VariableNames', ...
 {'PathLength_m','AbsoluteTurnAngle_rad','Coefficient_m_per_rad','BaselineSpeed_mps', ...
 'BaselineTime_s','TurningExtraTime_s','TotalTime_s','TotalTime_h','IsClosed'});
diagnostic=table(arc,x,y,heading,rate,'VariableNames', ...
 {'ArcLength_m','X_m','Y_m','Heading_rad','HeadingRate_radpm'});
end
function n=odd_window(w,count)
n=max(3,round(w));if mod(n,2)==0,n=n+1;end
if n>count,n=count-mod(count+1,2);end;n=max(3,n);
end
