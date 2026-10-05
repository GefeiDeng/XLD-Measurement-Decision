function Blocks = build_blocks(track,cfg)
%BUILD_BLOCKS Prepared metric GPS table -> independent arc-length blocks.
% Never connects different DateKey/OperationID groups. IncludeInModel is optional.
required={'DateKey','Time','X_m','Y_m','OperationID'};
assert(istable(track)&&isempty(setdiff(required,track.Properties.VariableNames)), ...
    'xldturn:Schema','GPS input requires DateKey, Time, X_m, Y_m, OperationID.');
if ismember('IncludeInModel',track.Properties.VariableNames)
    value=track.IncludeInModel;
    if isnumeric(value)||islogical(value),keep=isfinite(double(value))&value~=0;
    else,keep=ismember(lower(strtrim(string(value))),["1","true","yes"]);end
    track=track(keep,:);
end
assert(~isempty(track),'xldturn:EmptyInput','No included GPS points.');
if ~isdatetime(track.Time)
    track.Time=datetime(track.Time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
end
track=sortrows(track,{'DateKey','OperationID','Time'});
group=findgroups(track.DateKey,track.OperationID); parts=cell(max(group),1);
for g=1:max(group)
    parts{g}=operation_to_blocks(track(group==g,:),cfg);
end
parts=parts(~cellfun(@isempty,parts));
assert(~isempty(parts),'xldturn:NoBlocks','No valid GPS blocks were generated.');
Blocks=sortrows(vertcat(parts{:}),{'DateKey','OperationID','ArcCenter_m'});
end
function B = operation_to_blocks(T, cfg)
x = T.X_m(:); y = T.Y_m(:); t = T.Time(:);
valid = isfinite(x) & isfinite(y) & ~isnat(t); x = x(valid); y = y(valid); t = t(valid);
if numel(x) < 3, B = table(); return; end
arcRaw = [0; cumsum(hypot(diff(x), diff(y)))];
[arcRaw, uniqueIndex] = unique(arcRaw, 'stable'); x = x(uniqueIndex); y = y(uniqueIndex); t = t(uniqueIndex);
if numel(arcRaw) < 3 || arcRaw(end) < cfg.BlockLength_m, B = table(); return; end
arc = (0:cfg.SpatialStep_m:arcRaw(end))';
x = interp1(arcRaw, x, arc, 'linear'); y = interp1(arcRaw, y, arc, 'linear');
elapsed_s = interp1(arcRaw, seconds(t - t(1)), arc, 'linear');
x = smoothdata(x, 'sgolay', odd_window(cfg.PositionSmooth_m/cfg.SpatialStep_m, numel(arc)));
y = smoothdata(y, 'sgolay', odd_window(cfg.PositionSmooth_m/cfg.SpatialStep_m, numel(arc)));
heading = local_heading(x, y, cfg.HeadingBaseline_m, cfg.SpatialStep_m);
heading = smoothdata(heading, 'sgolay', odd_window(cfg.HeadingSmooth_m/cfg.SpatialStep_m, numel(arc)));
headingRate = smoothdata(gradient(heading, cfg.SpatialStep_m), 'movmean', ...
    odd_window(cfg.HeadingRateSmooth_m/cfg.SpatialStep_m, numel(arc)));
ds = diff(arc); dt = diff(elapsed_s); arcMid = 0.5*(arc(1:end-1)+arc(2:end));
rateMid = 0.5*(headingRate(1:end-1)+headingRate(2:end)); speed = ds./dt;
good = isfinite(dt) & isfinite(rateMid) & dt > 0 & speed >= cfg.MinimumSegmentSpeed_mps & ...
    speed <= cfg.MaximumSegmentSpeed_mps;
if nnz(good) < 10, B = table(); return; end
ds = ds(good); dt = dt(good); arcMid = arcMid(good); rateMid = rateMid(good);
rawBlockID = floor((arcMid-min(arcMid))/cfg.BlockLength_m); [group, blockID] = findgroups(rawBlockID);
length_m = splitapply(@sum, ds, group); time_s = splitapply(@sum, dt, group);
absoluteAngle_rad = splitapply(@(v,w) sum(abs(v).*w), rateMid, ds, group);
signedAngle_rad = splitapply(@(v,w) sum(v.*w), rateMid, ds, group);
arcCenter_m = splitapply(@(v,w) sum(v.*w)/sum(w), arcMid, ds, group);
n = numel(length_m); dateKey = double(T.DateKey(1)); operationID = double(T.OperationID(1));
B = table(repmat(dateKey,n,1), repmat(operationID,n,1), blockID, arcCenter_m, ...
    length_m, time_s, length_m./time_s, absoluteAngle_rad, signedAngle_rad, ...
    absoluteAngle_rad./length_m, 'VariableNames', {'DateKey','OperationID','BlockID', ...
    'ArcCenter_m','Length_m','Time_s','ObservedSpeed_mps','AbsoluteTurnAngle_rad', ...
    'SignedTurnAngle_rad','AngleDensity_radpm'});
B = B(B.Length_m >= 0.5*cfg.BlockLength_m, :);
end

function heading = local_heading(x, y, baseline_m, step_m)
n = numel(x); halfWindow = max(2, round(baseline_m/(2*step_m))); index = (1:n)';
left = max(1,index-halfWindow); right = min(n,index+halfWindow);
heading = unwrap(atan2(y(right)-y(left), x(right)-x(left)));
end

function n = odd_window(window, sampleCount)
n = max(3,round(window)); if mod(n,2)==0, n=n+1; end
if n>sampleCount, n=sampleCount-mod(sampleCount+1,2); end; n=max(3,n);
end
