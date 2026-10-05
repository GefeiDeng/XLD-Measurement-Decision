function [path,info,fig]=template_route(L,W,scheme,requestedSpacing,varargin)
%TEMPLATE_ROUTE Computational BCS/PCZ templates; no Figure-2 artwork.
% A=BCS, D=PCZ. Keep physical vertices and the complete return.
validateattributes(L,{'numeric'},{'scalar','finite','positive'});
validateattributes(W,{'numeric'},{'scalar','finite','positive'});
validateattributes(requestedSpacing,{'numeric'},{'scalar','finite','positive'});
    schemeCode=upper(char(scheme));assert(ismember(schemeCode,{'A','D'}),'Use A (BCS) or D (PCZ).');
    if schemeCode == 'D'
        constructionFactor = 2;
    else
        constructionFactor = 1;
    end
    nIntervals = max(1, round(L / ...
        (constructionFactor * requestedSpacing)));
    gridSpacing = L / nIntervals;
    actualSpacing = gridSpacing / constructionFactor;
    xGrid = linspace(0, L, nIntervals + 1).';

    switch schemeCode
        case 'A'
            outward = transverseSerpentine(xGrid, W);
            returnPath = directReturn(outward(end,:), [0, 0]);
            schemeName = 'Shore-connected transverse sections';
        case 'D'
            [outward, returnPath] = doubleCrossedZigzag(xGrid, W);
            schemeName = 'Double crossed zigzag';
    end

    outward = removeConsecutiveDuplicates(outward);
    returnPath = removeConsecutiveDuplicates(returnPath);
    if norm(outward(end,:) - returnPath(1,:)) > routeTolerance(L, W)
        error('generateSurveyPath:InternalJoinError', ...
            'Outward and return phases do not join.');
    end
    if norm(returnPath(end,:) - [0, 0]) > routeTolerance(L, W)
        returnPath(end+1,:) = [0, 0]; %#ok<AGROW>
    end

    path = [outward; returnPath(2:end,:)];
    phase = [ones(size(outward,1),1); ...
        2 * ones(max(0,size(returnPath,1)-1),1)];

    info = struct();
    info.scheme = schemeCode;
    info.schemeName = schemeName;
    info.requestedSpacing = requestedSpacing;
    info.actualSpacing = actualSpacing;
    info.spacingAdjustment = actualSpacing - requestedSpacing;
    info.nIntervals = nIntervals;
    info.constructionFactor = constructionFactor;
    info.gridSpacing = gridSpacing;
    info.xGrid = xGrid;
    info.outwardPath = outward;
    info.returnPath = returnPath;
    info.phase = phase;
    info.phaseBreakIndex = size(outward,1);
    info.outwardLength = polylineLength(outward);
    info.returnLength = polylineLength(returnPath);
    info.totalLength = info.outwardLength + info.returnLength;
    info.turnCount = countTurns(path);
    info.startPoint = path(1,:);
    info.endPoint = path(end,:);
    info.isClosed = norm(path(end,:) - path(1,:)) <= routeTolerance(L, W);
    info.allSegmentsMeasured = true;
    info.centerlineCrossings = centerlineCrossings(path, W/2, L, W);
    info.spacingDefinition = [ ...
        'actualSpacing is the scheme-normalized final effective spacing ', ...
        'd_eff. D counts outward and return measurements separately. ', ...
        'gridSpacing is d_eff for A and 2*d_eff for D.'];

    fig=[];
end

function points = transverseSerpentine(xGrid, W)
    n = numel(xGrid) - 1;
    points = zeros(2*n + 2, 2);
    cursor = 1;
    points(cursor,:) = [xGrid(1), 0];
    for i = 0:n
        if mod(i,2) == 0
            yTarget = W;
        else
            yTarget = 0;
        end
        cursor = cursor + 1;
        points(cursor,:) = [xGrid(i+1), yTarget];
        if i < n
            cursor = cursor + 1;
            points(cursor,:) = [xGrid(i+2), yTarget];
        end
    end
    points = points(1:cursor,:);
end


function points = singleZigzag(xGrid, W)
    n = numel(xGrid) - 1;
    y = zeros(n+1,1);
    y(mod((0:n).',2) == 1) = W;
    points = [xGrid, y];
end


function [outward, returnPath] = doubleCrossedZigzag(xGrid, W)
    base = singleZigzag(xGrid, W);
    rightTransition = [xGrid(end), W - base(end,2)];
    outward = [base; rightTransition];

    complement = [xGrid, W - base(:,2)];
    returnPath = flipud(complement);
    if norm(returnPath(1,:) - rightTransition) > routeTolerance(xGrid(end), W)
        returnPath = [rightTransition; returnPath];
    end
    returnPath(end+1,:) = [0, 0];
end


function points = directReturn(fromPoint, startPoint)
    points = [fromPoint; startPoint];
end


function points = removeConsecutiveDuplicates(points)
    if size(points,1) < 2
        return;
    end
    scale = max(1, max(abs(points(:))));
    keep = [true; sqrt(sum(diff(points,1,1).^2,2)) > 100*eps(scale)];
    points = points(keep,:);
end


function value = polylineLength(points)
    if size(points,1) < 2
        value = 0;
        return;
    end
    delta = diff(points,1,1);
    value = sum(sqrt(sum(delta.^2,2)));
end


function nTurns = countTurns(points)
    if size(points,1) < 3
        nTurns = 0;
        return;
    end
    vectors = diff(points,1,1);
    scale = max(1, max(sqrt(sum(vectors.^2,2))));
    vectors = vectors(sqrt(sum(vectors.^2,2)) > 100*eps(scale),:);
    if size(vectors,1) < 2
        nTurns = 0;
        return;
    end
    crossValue = vectors(1:end-1,1).*vectors(2:end,2) - ...
        vectors(1:end-1,2).*vectors(2:end,1);
    dotValue = sum(vectors(1:end-1,:).*vectors(2:end,:),2);
    angle = abs(atan2(crossValue, dotValue));
    nTurns = sum(angle > 1e-10);
end


function value = routeTolerance(L, W)
    value = 1e-10 * max([1, abs(L), abs(W)]);
end


function crossings = centerlineCrossings(points, centreY, L, W)
    tolerance = routeTolerance(L, W);
    crossings = zeros(max(1,size(points,1)-1),1);
    cursor = 0;
    for i = 1:size(points,1)-1
        p1 = points(i,:);
        p2 = points(i+1,:);
        dy = p2(2) - p1(2);
        if abs(dy) <= tolerance
            continue;
        end
        t = (centreY - p1(2)) / dy;
        if t >= -tolerance && t <= 1+tolerance
            cursor = cursor + 1;
            crossings(cursor) = p1(1) + t*(p2(1)-p1(1));
        end
    end
    crossings = sort(crossings(1:cursor));
    if numel(crossings) > 1
        keep = [true; diff(crossings) > tolerance];
        crossings = crossings(keep);
    end
end

