function merged = mergeCoincidentIntersections(raw,tolerance)
%MERGECOINCIDENTINTERSECTIONS Merge duplicate constraints by line station.
raw = sortrows(raw,'S');
group = ones(height(raw),1);
for rowIndex = 2:height(raw)
    group(rowIndex) = group(rowIndex-1)+( ...
        raw.S(rowIndex)-raw.S(rowIndex-1) > tolerance);
end
nGroups = group(end);
merged = table(zeros(nGroups,1),zeros(nGroups,1),zeros(nGroups,1), ...
    zeros(nGroups,1),zeros(nGroups,1),strings(nGroups,1), ...
    'VariableNames',{'ID','S','X','Y','Z','SourcePart'});
for groupIndex = 1:nGroups
    rows = group == groupIndex;
    merged.ID(groupIndex) = raw.ID(find(rows,1));
    merged.S(groupIndex) = mean(raw.S(rows));
    merged.X(groupIndex) = mean(raw.X(rows));
    merged.Y(groupIndex) = mean(raw.Y(rows));
    merged.Z(groupIndex) = mean(raw.Z(rows));
    merged.SourcePart(groupIndex) = strjoin(unique( ...
        raw.SourcePart(rows),'stable'),'+');
end
end
