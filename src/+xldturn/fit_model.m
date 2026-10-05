function [Model, Blocks, Statistics] = fit_model(Blocks, cfg)
%CALIBRATE_ANGLE_MODEL Estimate local cruise speed and zero-intercept c.
Blocks = retain_long_operations(Blocks, cfg.MinimumOperationLength_m, cfg.MinimumOperationBlocks);
assert(~isempty(Blocks),'xldturn:NoOperations','No eligible operations remain.');
n = height(Blocks); isCandidate = false(n,1); isSupport = false(n,1); baselineSpeed = nan(n,1);
[group,~,~] = findgroups(Blocks.DateKey,Blocks.OperationID);
for g = 1:max(group)
    index = find(group==g); [~,order] = sort(Blocks.ArcCenter_m(index)); index=index(order);
    s = Blocks.ArcCenter_m(index); density = Blocks.AngleDensity_radpm(index);
    unitTime = Blocks.Time_s(index)./Blocks.Length_m(index);
    candidateLocal = density <= prctile(density,100*cfg.LowAngleFraction);
    candidateIndex = find(candidateLocal); isCandidate(index(candidateIndex)) = true;
    preliminarySpeed = estimate_local_speed(s,unitTime,candidateIndex,cfg.BaselineHalfWindow_m);
    residual = log(preliminarySpeed(candidateIndex)./Blocks.ObservedSpeed_mps(index(candidateIndex)));
    center = median(residual,'omitnan'); scale = 1.4826*median(abs(residual-center),'omitnan');
    supportIndex = candidateIndex;
    if isfinite(scale) && scale>0
        supportIndex = candidateIndex(abs(residual-center)<=cfg.BaselineSpeedMADMultiplier*scale);
        minimumCount = min(numel(candidateIndex),max(8,ceil(cfg.MinimumSupportFraction*numel(candidateIndex))));
        if numel(supportIndex)<minimumCount
            [~,rank] = sort(abs(residual-center)); supportIndex = candidateIndex(rank(1:minimumCount));
        end
    end
    isSupport(index(supportIndex)) = true;
    baselineSpeed(index) = estimate_local_speed(s,unitTime,supportIndex,cfg.BaselineHalfWindow_m);
end
Blocks.LocalBaselineSpeed_mps = baselineSpeed;
Blocks.IsLowAngleCandidate = isCandidate;
Blocks.IsBaselineSupport = isSupport;
Blocks.UseForCalibration = ~isCandidate & isfinite(baselineSpeed) & baselineSpeed>0;
Blocks.ObservedExtraTime_s = Blocks.Time_s-Blocks.Length_m./baselineSpeed;
Blocks.SpeedAdjustedAngle_s_radpm = Blocks.AbsoluteTurnAngle_rad./baselineSpeed;
use = Blocks.UseForCalibration; x = Blocks.SpeedAdjustedAngle_s_radpm(use); y = Blocks.ObservedExtraTime_s(use);
assert(numel(x)>=2 && sum(x.^2)>0,'xldturn:NoCalibration','Insufficient turning predictors.');
c = sum(x.*y)/sum(x.^2);
assert(isfinite(c)&&c>0,'xldturn:InvalidCoefficient','The fitted coefficient is not positive.'); predicted = c*x;
sse = sum((y-predicted).^2); r2zero = 1-sse/sum(y.^2); rmse = sqrt(mean((y-predicted).^2));
Blocks.PredictedExtraTime_s = c*Blocks.SpeedAdjustedAngle_s_radpm;
Model = struct('Version',cfg.Version,'Coefficient_m_per_rad',c, ...
    'Coefficient_m_per_degree',c*pi/180,'R2Zero',r2zero, ...
    'RMSE_s',rmse,'NCalibrationBlocks',nnz(use));
Model.BaselineSpeed_mps=median(baselineSpeed,'omitnan');
Model.Processing=cfg;
Statistics = table(c,c*pi/180,r2zero,rmse,nnz(use),height(Blocks),nnz(isCandidate),nnz(isSupport), ...
    'VariableNames',{'Coefficient_m_per_rad','Coefficient_m_per_degree', ...
    'R2Zero','RMSE_s','NCalibrationBlocks','NRetainedBlocks', ...
    'NLowAngleCandidates','NBaselineSupports'});
end

function B = retain_long_operations(B, minimumLength_m, minimumBlocks)
[group,~,~] = findgroups(B.DateKey,B.OperationID);
operationLength = splitapply(@sum,B.Length_m,group); blockCount = splitapply(@numel,B.BlockID,group);
B = B(operationLength(group)>=minimumLength_m & blockCount(group)>=minimumBlocks,:);
end

function speed = estimate_local_speed(s, unitTime, supportIndex, halfWindow_m)
speed = nan(size(unitTime)); supportS=s(supportIndex); supportTime=unitTime(supportIndex);
for i = 1:numel(s)
    nearby = find(abs(supportS-s(i))<=halfWindow_m);
    if numel(nearby)<5
        [~,rank]=sort(abs(supportS-s(i))); nearby=rank(1:min(5,numel(rank)));
    end
    values=supportTime(nearby); center=median(values,'omitnan'); spread=median(abs(values-center),'omitnan');
    if spread>0, values=values(abs(values-center)<=3*1.4826*spread); end
    speed(i)=1/median(values,'omitnan');
end
end
