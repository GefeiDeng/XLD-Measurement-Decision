function detail = preprocessing_sensitivity(tracks,cfg,platform)
%PREPROCESSING_SENSITIVITY Frozen nine-setting, one-factor calibration check.
v=cfg.PreprocessingVariants;rows=cell(height(v),1);
for i=1:height(v)
    fprintf('  [%s] preprocessing %s\n',platform,v.Variant(i));
    c=cfg;c.HeadingBaseline_m=v.HeadingBaseline_m(i);c.BlockLength_m=v.BlockLength_m(i);
    c.MinimumOperationBlocks=max(5,ceil(c.MinimumOperationLength_m/c.BlockLength_m));
    c.LowAngleFraction=v.LowAngleFraction(i);c.BaselineHalfWindow_m=v.BaselineHalfWindow_m(i);
    [m,b]=xldturn.fit_model(xldturn.build_blocks(tracks,c),c);
    residual=b.ObservedExtraTime_s(b.UseForCalibration)-b.PredictedExtraTime_s(b.UseForCalibration);
    rows{i}=table(v.Variant(i),string(platform),c.HeadingBaseline_m,c.BlockLength_m, ...
    c.LowAngleFraction,c.BaselineHalfWindow_m,numel(unique(string(b.DateKey)+"_"+string(b.OperationID))), ...
    height(b),m.NCalibrationBlocks,m.BaselineSpeed_mps,m.Coefficient_m_per_rad,m.R2Zero, ...
    m.RMSE_s,mean(abs(residual)),'VariableNames', ...
    {'Variant','Platform','HeadingBaseline_m','BlockLength_m','LowAngleFraction','BaselineHalfWindow_m', ...
    'Operations','RetainedBlocks','CalibrationBlocks','MedianLocalBaselineSpeed_mps', ...
    'Coefficient_m_per_rad','R2Zero','BlockRMSE_s','BlockMAE_s'});
end
detail=vertcat(rows{:});baseline=detail.Coefficient_m_per_rad(detail.Variant=="Baseline");
detail.RelativeCoefficientChange_pct=100*(detail.Coefficient_m_per_rad/baseline-1);
end
