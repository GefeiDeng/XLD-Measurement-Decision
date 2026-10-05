function densePoints = densifyPolyline(controlPoints,resolution)
%DENSIFYPOLYLINE Densify every segment while retaining all control points.
pieces = cell(size(controlPoints,1)-1,1);
for segmentIndex = 1:size(controlPoints,1)-1
    startPoint = controlPoints(segmentIndex,:);
    endPoint = controlPoints(segmentIndex+1,:);
    segmentLength = hypot(endPoint(1)-startPoint(1), ...
        endPoint(2)-startPoint(2));
    nIntervals = max(1,round(segmentLength/resolution));
    fraction = (0:nIntervals)'/nIntervals;
    sampled = startPoint+fraction.*(endPoint-startPoint);
    if segmentIndex > 1
        sampled = sampled(2:end,:);
    end
    pieces{segmentIndex} = sampled;
end
densePoints = vertcat(pieces{:});
end
