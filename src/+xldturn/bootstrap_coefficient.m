function [draws,interval] = bootstrap_coefficient(blocks,cfg,platform)
%BOOTSTRAP_COEFFICIENT Operations + circular moving blocks, coefficient only.
% Caller seeds RNG once; local baseline estimates and calibration masks stay fixed.
draws=hierarchical_bootstrap(blocks,cfg.BootstrapReplicates,cfg.MovingBlockCount,string(platform));
draws=addvars(draws,(1:height(draws)).','After','Platform','NewVariableNames','Replicate');
interval=prctile(draws.Coefficient_m_per_rad,[2.5 97.5]);
end
function draws=hierarchical_bootstrap(blocks,replicates,movingBlockCount,platform)
group=findgroups(blocks.DateKey,blocks.OperationID);
groupCount=max(group);indices=cell(groupCount,1);
for g=1:groupCount,indices{g}=find(group==g);end
coefficient=nan(replicates,1);calibrationBlocks=zeros(replicates,1);
for b=1:replicates
    selectedGroups=randi(groupCount,groupCount,1);
    sampledRows=cell(groupCount,1);
    for j=1:groupCount
        source=indices{selectedGroups(j)};
        local=circular_moving_block_indices(numel(source),movingBlockCount);
        sampledRows{j}=source(local);
    end
    sampled=blocks(vertcat(sampledRows{:}),:);
    use=logical(sampled.UseForCalibration);
    x=sampled.SpeedAdjustedAngle_s_radpm(use);
    y=sampled.ObservedExtraTime_s(use);
    denominator=sum(x.^2);
    if denominator>0,coefficient(b)=sum(x.*y)/denominator;end
    calibrationBlocks(b)=nnz(use);
end
valid=isfinite(coefficient)&coefficient>0;
draws=table(repmat(platform,nnz(valid),1),coefficient(valid), ...
    calibrationBlocks(valid),'VariableNames',{'Platform', ...
    'Coefficient_m_per_rad','CalibrationBlocks'});
end

function index=circular_moving_block_indices(n,blockLength)
blockLength=min(blockLength,n);blockCount=ceil(n/blockLength);
index=zeros(blockCount*blockLength,1);cursor=0;
for b=1:blockCount
    start=randi(n);local=mod((start-1)+(0:blockLength-1),n)+1;
    index(cursor+(1:blockLength))=local;cursor=cursor+blockLength;
end
index=index(1:n);
end
