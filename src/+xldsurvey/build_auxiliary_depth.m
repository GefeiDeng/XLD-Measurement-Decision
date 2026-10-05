function [auxiliaryXYZ, intersections, qc] = ...
        build_auxiliary_depth(trajectoryXYZ, auxiliaryXY, varargin)
%INTERPOLATEAUXILIARYDEPTH Interpolate Z independently along auxiliary lines.
%
% Only the measured complete route supplies depth constraints; end cross-sections
% are already timed and sampled. No unmeasured endpoint elevations are added. auxiliaryXY is a table with ID, X and Y. No interpolation between
% different auxiliary-line IDs is performed.

parser = inputParser;
addParameter(parser,'Method','linear',@isTextScalar);
addParameter(parser,'MergeTolerance',1e-4,@isPositiveScalar);
addParameter(parser,'AnchorTolerance',1e-3,@isPositiveScalar);
parse(parser,varargin{:});
options = parser.Results;
method = lower(char(options.Method));
if ~ismember(method,{'linear','pchip','makima'})
    error('riverdepth:Auxiliary:InvalidMethod', ...
        'Method must be linear, pchip, or makima.');
end

trajectoryXYZ = validateXYZ(trajectoryXYZ,'trajectoryXYZ');

auxiliaryXY = validateAuxiliaryTable(auxiliaryXY);

parts = struct('Name',{'trajectory'},'XYZ',{trajectoryXYZ});

lineIds = unique(auxiliaryXY.ID,'stable');
auxiliaryRows = cell(numel(lineIds),1);
intersectionRows = cell(numel(lineIds),1);
qcRows = cell(numel(lineIds),1);
for lineIndex = 1:numel(lineIds)
    lineId = lineIds(lineIndex);
    rows = auxiliaryXY.ID == lineId;
    lineXY = [auxiliaryXY.X(rows),auxiliaryXY.Y(rows)];
    if size(lineXY,1) < 2
        error('riverdepth:Auxiliary:ShortLine', ...
            'Auxiliary line ID %g has fewer than two points.',lineId);
    end
    lineStation = cumulativeStation(lineXY);
    rawRows = cell(numel(parts),1);
    for partIndex = 1:numel(parts)
        rawRows{partIndex} = intersectDensePolylines( ...
            parts(partIndex).XYZ,lineXY,lineStation,lineId, ...
            parts(partIndex).Name);
    end
    raw = vertcat(rawRows{:});
    if isempty(raw)
        error('riverdepth:Auxiliary:NoIntersections', ...
            'No intersections found for auxiliary line ID %g.',lineId);
    end
    constraints = mergeCoincidentIntersections(raw, ...
        options.MergeTolerance);
    if abs(constraints.S(1)) <= options.AnchorTolerance
        constraints.S(1) = 0;
    end
    if abs(constraints.S(end)-lineStation(end)) <= options.AnchorTolerance
        constraints.S(end) = lineStation(end);
    end
    if constraints.S(1) ~= 0 || constraints.S(end) ~= lineStation(end)
        error('riverdepth:Auxiliary:MissingAnchor', ...
            ['Auxiliary line ID %g lacks an upstream or downstream mask ', ...
             'anchor (%.6f to %.6f; expected 0 to %.6f m).'], ...
            lineId,constraints.S(1),constraints.S(end),lineStation(end));
    end

    lineZ = interp1(constraints.S,constraints.Z,lineStation,method,NaN);
    gap = diff(constraints.S);
    auxiliaryRows{lineIndex} = table( ...
        repmat(lineId,size(lineXY,1),1),lineStation, ...
        lineXY(:,1),lineXY(:,2),lineZ, ...
        'VariableNames',{'ID','S','X','Y','Z'});
    intersectionRows{lineIndex} = constraints;
    qcRows{lineIndex} = table(lineId,size(raw,1),height(constraints), ...
        nnz(contains(constraints.SourcePart,'trajectory')), ...
        nnz(contains(constraints.SourcePart,'upstream_mask_side')), ...
        nnz(contains(constraints.SourcePart,'downstream_mask_side')), ...
        lineStation(end),mean(gap),median(gap),max(gap), ...
        nnz(~isfinite(lineZ)),min(lineZ),max(lineZ), ...
        'VariableNames',{'ID','RawIntersections','UniqueIntersections', ...
        'TrajectoryConstraints','UpstreamAnchorCount', ...
        'DownstreamAnchorCount','LineLength_m','MeanConstraintGap_m', ...
        'MedianConstraintGap_m','MaximumConstraintGap_m','NaNCount', ...
        'MinimumZ','MaximumZ'});
end

auxiliaryXYZ = vertcat(auxiliaryRows{:});
intersections = vertcat(intersectionRows{:});
qc = vertcat(qcRows{:});
end

function xyz = validateXYZ(xyz,name)
xyz = double(xyz);
if ~ismatrix(xyz) || size(xyz,2) ~= 3 || size(xyz,1) < 2 || ...
        any(~isfinite(xyz),'all')
    error('riverdepth:Auxiliary:InvalidXYZ', ...
        '%s must be a finite N-by-3 numeric array.',name);
end
end

function auxiliary = validateAuxiliaryTable(auxiliary)
if ~istable(auxiliary) || ...
        ~all(ismember({'ID','X','Y'},auxiliary.Properties.VariableNames))
    error('riverdepth:Auxiliary:InvalidTable', ...
        'auxiliaryXY must be a table containing ID, X, and Y.');
end
auxiliary = auxiliary(:,{'ID','X','Y'});
if any(~isfinite([auxiliary.ID auxiliary.X auxiliary.Y]),'all')
    error('riverdepth:Auxiliary:NonfiniteTable', ...
        'Auxiliary ID, X, and Y must be finite.');
end
end

function tf = isTextScalar(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
