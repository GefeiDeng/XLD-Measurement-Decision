function data=prepare_decision_plot_data(source,cfg)
%PREPARE_DECISION_PLOT_DATA Evaluate frozen responses on the display grid.
% No DEM reconstruction, coefficient calibration or response refitting.
o=source.Output;allH=o.Config.Hours(:)';allE=o.Config.TargetRstar(:)*o.Dmax_m;
assert(cfg.TimeLimits_h(1)>=min(allH)&&cfg.TimeLimits_h(2)<=max(allH), ...
    'Requested time window exceeds the stored decision-map grid.');
assert(cfg.TargetLimits_m(1)>=min(allE)-1e-8&&cfg.TargetLimits_m(2)<=max(allE)+1e-8, ...
    'Requested error limits exceed the original display range.');
takeH=allH>=cfg.TimeLimits_h(1)-1e-10&allH<=cfg.TimeLimits_h(2)+1e-10;
takeE=allE>=cfg.TargetLimits_m(1)-1e-10&allE<=cfg.TargetLimits_m(2)+1e-10;
data.Hours_h=allH(takeH);
data.TargetRMSE_m=linspace(cfg.TargetLimits_m(1),cfg.TargetLimits_m(2),cfg.TargetGridCount)';
data.PlatformYears=cfg.PlatformYears;data.Maps=cell(1,2);data.Palette=source.Palette;
checks=strings(0,1);passed=false(0,1);difference=zeros(0,1);
fields={'N','N_BCS','N_PCZ','PathCode','D_m','PredictedRMSE_m','PredictedTime_h'};
for i=1:2
    data.Maps{i}=select_rmse(o.Fits(i,:),data.Hours_h,data.TargetRMSE_m,o.Dmax_m);
    % On the original grid, verify the copied decision function against archived maps.
    reference=select_rmse(o.Fits(i,:),data.Hours_h,allE(takeE),o.Dmax_m);
    original=o.Maps{i};
    for j=1:numel(fields)
        name=fields{j};expected=double(original.(name)(takeE,takeH));actual=double(reference.(name));
        good=isequal(isnan(expected),isnan(actual))&&isequal(isinf(expected),isinf(actual));
        finite=isfinite(expected)&isfinite(actual);
        maxDiff=max(abs(expected(finite)-actual(finite)),[],'all');
        if isempty(maxDiff),maxDiff=0;end
        checks(end+1)=string(cfg.PlatformYears(i))+" "+name+" unchanged on original grid";
        passed(end+1)=good&&maxDiff<=1e-8;difference(end+1)=maxDiff;
    end
    current=data.Maps{i};supported=current.Valid;
    good=all(current.PredictedTime_h(supported)<=current.N(supported).*current.H(supported)+1e-8) ...
        &&all(current.PredictedRMSE_m(supported)<=current.TargetRstar(supported)*o.Dmax_m+1e-8);
    checks(end+1)=string(cfg.PlatformYears(i))+" display-grid time/error constraints";
    passed(end+1)=good;difference(end+1)=0;
end
data.Audit=table(checks(:),passed(:),difference(:), ...
    'VariableNames',{'Check','Pass','MaximumAbsoluteDifference'});
assert(all(data.Audit.Pass),'Decision reproduction failed.');
fleet=[data.Maps{1}.N(:);data.Maps{2}.N(:)];spacing=[data.Maps{1}.D_m(:);data.Maps{2}.D_m(:)];
data.FleetMax=max(fleet(isfinite(fleet)));
data.SpacingLimits_m=[min(spacing(isfinite(spacing))),max(spacing(isfinite(spacing)))];
data.RangeSummary=table;data.GridTable=table;data.Examples=table;
for i=1:2
    map=data.Maps{i};path=strings(numel(map.N),1);
    path(map.PathCode(:)==1)="BCS";path(map.PathCode(:)==2)="PCZ";
    grid=table(repmat(cfg.PlatformYears(i),numel(map.N),1),map.H(:),map.TargetRstar(:)*o.Dmax_m, ...
        map.N(:),map.N_BCS(:),map.N_PCZ(:),path,map.D_m(:),map.PredictedRMSE_m(:), ...
        map.PredictedTime_h(:),map.Valid(:),'VariableNames', ...
        {'PlatformYear','H_h','TargetRMSE_m','MinimumFleet','BCSFleet','PCZFleet', ...
        'SelectedPath','PlanningSpacing_m','PredictedRMSE_m','TotalVesselHours','WithinSupport'});
    data.GridTable=[data.GridTable;grid];
    row=table(cfg.PlatformYears(i),min(map.N(map.Valid)),max(map.N(map.Valid)), ...
        min(map.D_m(map.Valid)),max(map.D_m(map.Valid)),100*mean(map.PathCode(map.Valid)==1), ...
        'VariableNames',{'PlatformYear','MinimumFleet','MaximumFleet','MinimumSpacing_m', ...
        'MaximumSpacing_m','BCSShare_pct'});
    data.RangeSummary=[data.RangeSummary;row];
    targets=[cfg.ExampleTarget_m,.613589172363282];
    example=select_rmse(o.Fits(i,:),cfg.ExampleTime_h,targets,o.Dmax_m);
    examplePath=strings(2,1);examplePath(example.PathCode(:)==1)="BCS";examplePath(example.PathCode(:)==2)="PCZ";
    rows=table(repmat(cfg.PlatformYears(i),2,1),example.H(:),targets(:),example.N(:), ...
        example.N_BCS(:),example.N_PCZ(:),examplePath,example.D_m(:), ...
        example.PredictedRMSE_m(:),example.PredictedTime_h(:),'VariableNames', ...
        {'PlatformYear','H_h','TargetRMSE_m','MinimumFleet','BCSFleet','PCZFleet', ...
        'SelectedPath','PlanningSpacing_m','PredictedRMSE_m','TotalVesselHours'});
    data.Examples=[data.Examples;rows];
end
end
