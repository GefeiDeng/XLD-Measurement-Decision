function [Track,Summary] = prepare_gps(RawDay,cfg)
%PREPROCESS_GPS_DAY Convert one raw day into valid, separated operations.
assert(nargin==2,'xldturn:Config','Pass explicit processing settings.');
t = RawDay.Time(:); x = RawDay.X_m(:); y = RawDay.Y_m(:);
valid = ~isnat(t) & isfinite(x) & isfinite(y) & ...
    x>=cfg.ValidXRange_m(1) & x<=cfg.ValidXRange_m(2) & ...
    y>=cfg.ValidYRange_m(1) & y<=cfg.ValidYRange_m(2);
t=t(valid); x=x(valid); y=y(valid);

% Aggregate exact duplicate timestamps only; do not average neighboring times.
[G,keyTime] = findgroups(t); x=splitapply(@median,x,G); y=splitapply(@median,y,G); t=keyTime;
[t,order] = sort(t); x=x(order); y=y(order);
dt = seconds(diff(t)); goodDt = dt(dt>0 & dt<60);
if isempty(goodDt), medianDt=cfg.TimeStep_s; else, medianDt=median(goodDt); end
gapThreshold = max(cfg.MinGap_s,cfg.GapFactor*medianDt);
linkSpeed = hypot(diff(x),diff(y))./max(dt,eps);
breakBefore = [true;dt<=0 | dt>gapThreshold | linkSpeed>cfg.MaxLinkSpeed_mps | ~isfinite(linkSpeed)];
starts=find(breakBefore); ends=[starts(2:end)-1;numel(t)];

outTime=datetime.empty(0,1); outX=[]; outY=[]; outSpeed=[]; outOperation=[]; operation=0;
for g=1:numel(starts)
    ii=starts(g):ends(g); if numel(ii)<3, continue; end
    tr=t(ii); xr=x(ii); yr=y(ii); elapsed=seconds(tr-tr(1));
    if elapsed(end)<cfg.OperationMinimum_s, continue; end
    uniformElapsed=(0:cfg.TimeStep_s:elapsed(end))'; uniformTime=tr(1)+seconds(uniformElapsed);
    xu=interp1(elapsed,xr,uniformElapsed,'linear'); yu=interp1(elapsed,yr,uniformElapsed,'linear');
    xs=smoothdata(xu,'sgolay',odd_window(cfg.TimeSmooth_s/cfg.TimeStep_s,numel(uniformElapsed)));
    ys=smoothdata(yu,'sgolay',odd_window(cfg.TimeSmooth_s/cfg.TimeStep_s,numel(uniformElapsed)));
    speed=smoothdata(hypot(gradient(xs,cfg.TimeStep_s),gradient(ys,cfg.TimeStep_s)), ...
        'movmedian',odd_window(cfg.SpeedSmooth_s/cfg.TimeStep_s,numel(uniformElapsed)));
    stopped=mark_long_runs(speed<cfg.StopSpeed_mps,round(cfg.StopMinimum_s/cfg.TimeStep_s));
    movingRuns=runs_from_mask(~stopped);
    for r=1:size(movingRuns,1)
        jj=movingRuns(r,1):movingRuns(r,2);
        if (numel(jj)-1)*cfg.TimeStep_s<cfg.OperationMinimum_s, continue; end
        operation=operation+1;
        outTime=[outTime;uniformTime(jj)]; outX=[outX;xs(jj)]; outY=[outY;ys(jj)]; %#ok<AGROW>
        outSpeed=[outSpeed;speed(jj)]; outOperation=[outOperation;repmat(operation,numel(jj),1)]; %#ok<AGROW>
    end
end

n=numel(outTime); Track=table(repmat(string(RawDay.Dataset),n,1),repmat(RawDay.DateKey,n,1), ...
    repmat(RawDay.IncludeInModel,n,1),outTime,outX,outY,outSpeed,outOperation, ...
    'VariableNames',{'Dataset','DateKey','IncludeInModel','Time','X_m','Y_m','SOG_mps','OperationID'});
if ~isempty(Track), Track.Time.Format='yyyy-MM-dd HH:mm:ss.SSS'; end
validDuration=0; for op=reshape(unique(outOperation),1,[]), tt=outTime(outOperation==op); validDuration=validDuration+seconds(tt(end)-tt(1)); end
Summary=struct('Dataset',string(RawDay.Dataset),'DateKey',RawDay.DateKey,'IncludeInModel',RawDay.IncludeInModel, ...
    'RawPointCount',RawDay.RawPointCount,'ValidUniquePoints',numel(t),'MedianSampleInterval_s',medianDt, ...
    'GapThreshold_s',gapThreshold,'OperationCount',operation,'ValidTrackPoints',height(Track),'ValidDuration_s',validDuration);
end

function out=mark_long_runs(mask,minN)
out=false(size(mask)); runs=runs_from_mask(mask);
for i=1:size(runs,1), if runs(i,2)-runs(i,1)+1>=minN, out(runs(i,1):runs(i,2))=true; end, end
end
function runs=runs_from_mask(mask), z=diff([false;mask(:);false]); runs=[find(z==1),find(z==-1)-1]; end
function w=odd_window(w,n)
w=max(3,round(w)); if mod(w,2)==0, w=w+1; end
if w>n, w=n-mod(n+1,2); end
w=max(3,w);
end
