function [trajectory,info] = map_route(scheme,requestedSpacing,channelModel,cfg)
%MAP_ROUTE Fixed-layout complete route at D; no initial-phase transformation.
% BCS/A and PCZ/D only. All physical control vertices and complete return are retained.
validateattributes(requestedSpacing,{'numeric'},{'scalar','finite','positive'});
scheme=upper(char(string(scheme)));if strcmp(scheme,'BCS'),scheme='A';elseif strcmp(scheme,'PCZ'),scheme='D';end
assert(ismember(scheme,{'A','D'}),'xldsurvey:Scheme','Use BCS/A or PCZ/D.');
geometry=validateChannelGeometry(channelModel);
options=struct('TrajectoryResolution',cfg.TrajectoryResolution_m);
    channelLength = geometry.station(end)-geometry.station(1);
    widthValues = hypot(geometry.leftBank(:,1)-geometry.rightBank(:,1), ...
        geometry.leftBank(:,2)-geometry.rightBank(:,2));
    validWidths = widthValues(isfinite(widthValues) & widthValues > 0);
    if isempty(validWidths)
        error('generateRealChannelSurveyPath:InvalidWidth', ...
            'The final banks do not define a positive channel width.');
    end
    referenceWidth = mean(validWidths);

    [~,rectangularInfo]=xldsurvey.template_route(channelLength,referenceWidth,scheme,requestedSpacing,'DoPlot',false);

    trajectoryResolution = options.TrajectoryResolution;
    mappingStep = trajectoryResolution/2;
    [outwardPhysical, outwardTemplate, outwardVertexIndices, ...
        outwardLegResolution] = mapAndResampleControlPolyline( ...
        rectangularInfo.outwardPath, trajectoryResolution, mappingStep, ...
        referenceWidth, geometry);
    [returnPhysical, returnTemplate, returnVertexIndices, ...
        returnLegResolution] = mapAndResampleControlPolyline( ...
        rectangularInfo.returnPath, trajectoryResolution, mappingStep, ...
        referenceWidth, geometry);
    trajectory = [outwardPhysical; returnPhysical(2:end,:)];
    templateTrajectory = [outwardTemplate; returnTemplate(2:end,:)];
    phase = [ones(size(outwardPhysical,1),1); ...
        2*ones(max(0,size(returnPhysical,1)-1),1)];

    controlOutwardPhysical = outwardPhysical(outwardVertexIndices,:);
    controlReturnPhysical = returnPhysical(returnVertexIndices,:);
    controlPointsPhysical = [controlOutwardPhysical; ...
        controlReturnPhysical(2:end,:)];
    controlVertexIndices = [outwardVertexIndices; ...
        size(outwardPhysical,1)-1+returnVertexIndices(2:end)];

    boundary = geometry.boundary;
    maximumBoundaryCheckPoints = 20000;
    checkStride = max(1, ceil(size(trajectory,1)/ ...
        maximumBoundaryCheckPoints));
    boundaryCheckIndices = unique([(1:checkStride:size(trajectory,1)).'; ...
        controlVertexIndices; size(trajectory,1)]);
    checkedPoints = trajectory(boundaryCheckIndices,:);
    [inside, onBoundary] = inpolygon(checkedPoints(:,1), checkedPoints(:,2), ...
        boundary(:,1), boundary(:,2));
    checkedEta = templateTrajectory(boundaryCheckIndices,2)/referenceWidth;
    exactBankPoint = abs(checkedEta) <= 1e-12 | ...
        abs(checkedEta-1) <= 1e-12;
    % eta=0 and eta=1 are mapped directly from the final right/left bank.
    % Treat them as boundary points even if inpolygon loses collinearity at
    % the large UTM coordinate magnitude through floating-point roundoff.
    insideMask = inside | onBoundary | exactBankPoint;
    consecutiveDistance = hypot(diff(trajectory(:,1)), ...
        diff(trajectory(:,2)));

    info = struct();
    info.scheme = rectangularInfo.scheme;
    info.schemeName = rectangularInfo.schemeName;
    info.requestedSpacing = requestedSpacing;
    info.actualSpacing = rectangularInfo.actualSpacing;
    info.spacingAdjustment = rectangularInfo.spacingAdjustment;
    info.gridSpacing = rectangularInfo.gridSpacing;
    info.nIntervals = rectangularInfo.nIntervals;
    info.constructionFactor = rectangularInfo.constructionFactor;
    info.spacingDefinition = rectangularInfo.spacingDefinition;
    info.channelSource = "explicit channelModel input";
    info.channelLength = channelLength;
    info.referenceWidth = referenceWidth;
    info.averageWidth = referenceWidth;
    info.minimumWidth = min(validWidths);
    info.maximumWidth = max(validWidths);
    info.trajectoryResolution = trajectoryResolution;
    info.mappingStep = mappingStep;
    info.sampleStep = trajectoryResolution;
    info.outwardLegResolution = outwardLegResolution;
    info.returnLegResolution = returnLegResolution;
    info.minimumPointSpacing = min(consecutiveDistance);
    info.meanPointSpacing = mean(consecutiveDistance);
    info.maximumPointSpacing = max(consecutiveDistance);
    info.modelStation = geometry.station;
    info.thalweg = geometry.thalweg;
    info.leftBank = geometry.leftBank;
    info.rightBank = geometry.rightBank;
    info.channelBoundaryClosed = boundary;
    info.rectangularInfo = rectangularInfo;
    info.effectiveIntervalCount=info.constructionFactor*info.nIntervals;
    info.constructionParity=parity_name(info.nIntervals);
    info.effectiveParity=parity_name(info.effectiveIntervalCount);
    info.returnType=return_type(info);
    info.controlPointsRectangular = [rectangularInfo.outwardPath; ...
        rectangularInfo.returnPath(2:end,:)];
    info.controlOutwardRectangular = rectangularInfo.outwardPath;
    info.controlReturnRectangular = rectangularInfo.returnPath;
    info.controlPointsPhysical = controlPointsPhysical;
    info.controlOutwardPhysical = controlOutwardPhysical;
    info.controlReturnPhysical = controlReturnPhysical;
    info.controlVertexIndices = controlVertexIndices;
    info.outwardVertexIndices = outwardVertexIndices;
    info.returnVertexIndices = returnVertexIndices;
    info.turnPointsIncluded = isequal(trajectory(controlVertexIndices,:), ...
        controlPointsPhysical);
    info.outwardTemplate = outwardTemplate;
    info.returnTemplate = returnTemplate;
    info.templateTrajectory = templateTrajectory;
    info.lateralFraction = templateTrajectory(:,2)/referenceWidth;
    info.voyageStage = phase;
    info.outwardPath = outwardPhysical;
    info.returnPath = returnPhysical;
    info.trajectory = trajectory;
    info.outwardLength = polylineLength(outwardPhysical);
    info.returnLength = polylineLength(returnPhysical);
    info.totalLength = info.outwardLength+info.returnLength;
    info.startPoint = trajectory(1,:);
    info.endPoint = trajectory(end,:);
    tolerance = 1e-8*max([1, channelLength, referenceWidth]);
    info.isClosed = norm(info.startPoint-info.endPoint) <= tolerance;
    info.allSegmentsMeasured = rectangularInfo.allSegmentsMeasured;
    info.boundaryCheckIndices = boundaryCheckIndices;
    info.exactBankPointMask = exactBankPoint;
    info.insideMask = insideMask;
    info.insideFraction = mean(insideMask);
    info.allPointsInside = all(insideMask);
    info.mapping = ['The A-E rectangular template is mapped by station ', ...
        'and lateral fraction. eta=0 maps to the final right bank, ', ...
        'eta=0.5 to the final thalweg, and eta=1 to the final left bank.'];

    if ~info.allPointsInside
        warning('generateRealChannelSurveyPath:OutsideBoundary', ...
            ['%.3f%% of the checked samples lie outside the closed boundary. ', ...
             'Inspect the final bank geometry.'], ...
            100*(1-info.insideFraction));
    end


end
function name=parity_name(n)
if mod(n,2)==0,name="even";else,name="odd";end
end
function name=return_type(info)
if info.scheme=='D',name="complementary_zigzag";
elseif mod(info.nIntervals,2)==1,name="boundary_return";
else,name="interior_diagonal_return";end
end
function geometry = validateChannelGeometry(channelModel)
    required = {'station','thalweg','leftBank','rightBank'};
    for i = 1:numel(required)
        if ~isfield(channelModel, required{i})
            error('generateRealChannelSurveyPath:MissingChannelField', ...
                'channelModel is missing field: %s', required{i});
        end
    end

    station = double(channelModel.station(:));
    thalweg = double(channelModel.thalweg);
    leftBank = double(channelModel.leftBank);
    rightBank = double(channelModel.rightBank);
    n = numel(station);
    arrays = {thalweg, leftBank, rightBank};
    names = {'thalweg','leftBank','rightBank'};
    for i = 1:numel(arrays)
        if ~ismatrix(arrays{i}) || size(arrays{i},1) ~= n || ...
                size(arrays{i},2) ~= 2
            error('generateRealChannelSurveyPath:InvalidChannelField', ...
                'channelModel.%s must be N-by-2 and match station.', ...
                names{i});
        end
    end
    if n < 2 || any(~isfinite(station)) || ...
            any(~isfinite(thalweg(:))) || any(~isfinite(leftBank(:))) || ...
            any(~isfinite(rightBank(:)))
        error('generateRealChannelSurveyPath:InvalidChannelGeometry', ...
            'Final station, thalweg and bank arrays must be finite.');
    end
    if any(diff(station) <= 0)
        error('generateRealChannelSurveyPath:InvalidStation', ...
            'channelModel.station must be strictly increasing.');
    end

    if isfield(channelModel, 'channelBoundaryClosed')
        boundary = double(channelModel.channelBoundaryClosed);
    else
        boundary = [leftBank; flipud(rightBank); leftBank(1,:)];
    end
    if ~ismatrix(boundary) || size(boundary,2) ~= 2 || ...
            size(boundary,1) < 4 || any(~isfinite(boundary(:)))
        error('generateRealChannelSurveyPath:InvalidBoundary', ...
            'The final closed channel boundary must be a finite N-by-2 array.');
    end
    scale = max(1, max(abs(boundary(:))));
    if norm(boundary(end,:)-boundary(1,:)) > 100*eps(scale)
        boundary(end+1,:) = boundary(1,:);
    end

    geometry = struct('station',station,'thalweg',thalweg, ...
        'leftBank',leftBank,'rightBank',rightBank,'boundary',boundary);
end

function [physical, template, vertexIndices, legResolution] = ...
        mapAndResampleControlPolyline(controlPoints, resolution, ...
        mappingStep, referenceWidth, geometry)
%MAPANDRESAMPLECONTROLPOLYLINE Preserve turns and round each leg point count.
% Each control leg is first mapped with a finer internal sampling step. Its
% physical arc length is then divided into round(length/resolution) equal
% intervals. Therefore the spacing is approximately the requested value,
% while both endpoints (the required turn/bank-intersection points) are
% included exactly.
    nLegs = size(controlPoints,1)-1;
    if nLegs < 1
        physical = mapTemplateToChannel(controlPoints, ...
            referenceWidth, geometry);
        template = controlPoints;
        vertexIndices = 1;
        legResolution = zeros(0,1);
        return;
    end

    physicalLegs = cell(nLegs,1);
    templateLegs = cell(nLegs,1);
    vertexIndices = zeros(nLegs+1,1);
    legResolution = zeros(nLegs,1);
    vertexIndices(1) = 1;
    cursor = 1;

    for i = 1:nLegs
        delta = controlPoints(i+1,:)-controlPoints(i,:);
        templateLength = hypot(delta(1),delta(2));
        nMappingPieces = max(1, ceil(templateLength/mappingStep));
        mappingFraction = (0:nMappingPieces).'/nMappingPieces;
        mappedTemplate = bsxfun(@plus, controlPoints(i,:), ...
            bsxfun(@times, mappingFraction, delta));
        mappedPhysical = mapTemplateToChannel(mappedTemplate, ...
            referenceWidth, geometry);

        mappedDistance = hypot(diff(mappedPhysical(:,1)), ...
            diff(mappedPhysical(:,2)));
        keep = [true; mappedDistance > ...
            100*eps(max(1,max(abs(mappedPhysical(:)))))];
        mappedTemplate = mappedTemplate(keep,:);
        mappedPhysical = mappedPhysical(keep,:);
        mappedStation = [0; cumsum(hypot(diff(mappedPhysical(:,1)), ...
            diff(mappedPhysical(:,2))))];
        legLength = mappedStation(end);
        if legLength <= 0
            error('generateRealChannelSurveyPath:ZeroLengthControlLeg', ...
                'A mapped control leg has zero physical length.');
        end

        nPieces = max(1, round(legLength/resolution));
        query = linspace(0,legLength,nPieces+1).';
        legPhysical = [interp1(mappedStation,mappedPhysical(:,1), ...
            query,'linear'), interp1(mappedStation,mappedPhysical(:,2), ...
            query,'linear')];
        legTemplate = [interp1(mappedStation,mappedTemplate(:,1), ...
            query,'linear'), interp1(mappedStation,mappedTemplate(:,2), ...
            query,'linear')];

        % Restore both exact mapped vertices after interpolation.
        exactPhysical = mapTemplateToChannel(controlPoints([i i+1],:), ...
            referenceWidth, geometry);
        legPhysical([1 end],:) = exactPhysical;
        legTemplate([1 end],:) = controlPoints([i i+1],:);
        legResolution(i) = legLength/nPieces;

        if i > 1
            legPhysical = legPhysical(2:end,:);
            legTemplate = legTemplate(2:end,:);
        end
        physicalLegs{i} = legPhysical;
        templateLegs{i} = legTemplate;
        cursor = cursor+nPieces;
        vertexIndices(i+1) = cursor;
    end

    physical = vertcat(physicalLegs{:});
    template = vertcat(templateLegs{:});
end

function physical = mapTemplateToChannel(template, referenceWidth, geometry)
    relativeStation = template(:,1);
    eta = template(:,2)/referenceWidth;
    tolerance = 1e-10;
    if any(relativeStation < -tolerance) || ...
            any(relativeStation > geometry.station(end)- ...
            geometry.station(1)+tolerance) || ...
            any(eta < -tolerance) || any(eta > 1+tolerance)
        error('generateRealChannelSurveyPath:TemplateOutsideRectangle', ...
            'The rectangular template must remain inside [0,L] x [0,W].');
    end
    relativeStation = max(0, min(geometry.station(end)- ...
        geometry.station(1), relativeStation));
    eta = max(0, min(1, eta));
    queryStation = geometry.station(1)+relativeStation;

    thalweg = interp1(geometry.station, geometry.thalweg, ...
        queryStation, 'linear');
    leftBank = interp1(geometry.station, geometry.leftBank, ...
        queryStation, 'linear');
    rightBank = interp1(geometry.station, geometry.rightBank, ...
        queryStation, 'linear');

    physical = zeros(size(template));
    lowerHalf = eta <= 0.5;
    lowerWeight = 2*eta(lowerHalf);
    physical(lowerHalf,:) = rightBank(lowerHalf,:)+ ...
        bsxfun(@times, lowerWeight, ...
        thalweg(lowerHalf,:)-rightBank(lowerHalf,:));
    upperHalf = ~lowerHalf;
    upperWeight = 2*eta(upperHalf)-1;
    physical(upperHalf,:) = thalweg(upperHalf,:)+ ...
        bsxfun(@times, upperWeight, ...
        leftBank(upperHalf,:)-thalweg(upperHalf,:));
end

function value = polylineLength(points)
    if size(points,1) < 2
        value = 0;
        return;
    end
    delta = diff(points,1,1);
    value = sum(hypot(delta(:,1), delta(:,2)));
end
