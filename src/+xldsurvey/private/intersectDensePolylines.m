function rows = intersectDensePolylines(partXYZ,lineXY,lineStation,lineId,sourceName)
%INTERSECTDENSEPOLYLINES Intersect dense lines without an all-pairs matrix.
pathXY = partXYZ(:,1:2);
pathStartAll = pathXY(1:end-1,:);
pathVectorAll = diff(pathXY,1,1);
pathLengthAll = hypot(pathVectorAll(:,1),pathVectorAll(:,2));
lineStartAll = lineXY(1:end-1,:);
lineVectorAll = diff(lineXY,1,1);
lineLengthAll = hypot(lineVectorAll(:,1),lineVectorAll(:,2));
pathSegmentIndex = find(pathLengthAll > eps);
lineSegmentIndex = find(lineLengthAll > eps);
pathStart = pathStartAll(pathSegmentIndex,:);
pathVector = pathVectorAll(pathSegmentIndex,:);
pathLength = pathLengthAll(pathSegmentIndex);
lineStart = lineStartAll(lineSegmentIndex,:);
lineVector = lineVectorAll(lineSegmentIndex,:);
lineLength = lineLengthAll(lineSegmentIndex);
pathMidpoint = pathStart+0.5*pathVector;
lineMidpoint = lineStart+0.5*lineVector;
searchRadius = 0.5*max(pathLength)+0.5*max(lineLength)+1e-3;
candidateCells = rangesearch(lineMidpoint,pathMidpoint,searchRadius);
candidateCount = cellfun(@numel,candidateCells);
if ~any(candidateCount)
    rows = emptyTable();
    return;
end
pathCandidate = repelem((1:numel(candidateCells))',candidateCount);
candidateColumnCells = cellfun(@(x) x(:),candidateCells, ...
    'UniformOutput',false);
lineCandidate = vertcat(candidateColumnCells{:});
p = pathStart(pathCandidate,:);
r = pathVector(pathCandidate,:);
q = lineStart(lineCandidate,:);
s = lineVector(lineCandidate,:);
qMinusP = q-p;
denominator = cross2d(r,s);
lengthProduct = pathLength(pathCandidate).*lineLength(lineCandidate);
nonparallel = abs(denominator) > 1e-12*lengthProduct;
t = nan(size(denominator));
u = nan(size(denominator));
t(nonparallel) = cross2d(qMinusP(nonparallel,:),s(nonparallel,:))./ ...
    denominator(nonparallel);
u(nonparallel) = cross2d(qMinusP(nonparallel,:),r(nonparallel,:))./ ...
    denominator(nonparallel);
parameterTolerance = 1e-8;
valid = nonparallel & t >= -parameterTolerance & ...
    t <= 1+parameterTolerance & u >= -parameterTolerance & ...
    u <= 1+parameterTolerance;

parallelCandidate = find(~nonparallel);
for index = parallelCandidate(:)'
    distanceToPath = abs(cross2d(qMinusP(index,:),r(index,:)))/ ...
        pathLength(pathCandidate(index));
    if distanceToPath > 1e-6
        continue;
    end
    rr = sum(r(index,:).^2);
    projection0 = dot(qMinusP(index,:),r(index,:))/rr;
    projection1 = dot(qMinusP(index,:)+s(index,:),r(index,:))/rr;
    overlapStart = max(0,min(projection0,projection1));
    overlapEnd = min(1,max(projection0,projection1));
    if overlapEnd < overlapStart-parameterTolerance
        continue;
    end
    t(index) = 0.5*(overlapStart+overlapEnd);
    point = p(index,:)+t(index)*r(index,:);
    ss = sum(s(index,:).^2);
    u(index) = dot(point-q(index,:),s(index,:))/ss;
    valid(index) = u(index) >= -parameterTolerance && ...
        u(index) <= 1+parameterTolerance;
end
if ~any(valid)
    rows = emptyTable();
    return;
end

pathCandidate = pathCandidate(valid);
lineCandidate = lineCandidate(valid);
t = min(1,max(0,t(valid)));
u = min(1,max(0,u(valid)));
pathSegment = pathSegmentIndex(pathCandidate);
lineSegment = lineSegmentIndex(lineCandidate);
pathPoint = pathStartAll(pathSegment,:)+t.*pathVectorAll(pathSegment,:);
linePoint = lineStartAll(lineSegment,:)+u.*lineVectorAll(lineSegment,:);
intersectionXY = 0.5*(pathPoint+linePoint);
z = partXYZ(pathSegment,3).*(1-t)+partXYZ(pathSegment+1,3).*t;
station = lineStation(lineSegment).*(1-u)+lineStation(lineSegment+1).*u;
rows = table(repmat(lineId,numel(station),1),station, ...
    intersectionXY(:,1),intersectionXY(:,2),z, ...
    repmat(string(sourceName),numel(station),1), ...
    'VariableNames',{'ID','S','X','Y','Z','SourcePart'});
end

function value = cross2d(first,second)
value = first(:,1).*second(:,2)-first(:,2).*second(:,1);
end

function rows = emptyTable
rows = table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
    zeros(0,1),strings(0,1),'VariableNames', ...
    {'ID','S','X','Y','Z','SourcePart'});
end
