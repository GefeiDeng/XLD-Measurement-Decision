function data=load_turning_plot_data(inputFolder)
%LOAD_TURNING_PLOT_DATA Use saved fit quantities without refitting.
data.Years=[2023 2020];data.Platforms=["A" "B"];
data.Summary=readtable(fullfile(inputFolder,'Summary.csv'),'TextType','string');
daily=readtable(fullfile(inputFolder,'Daily.csv'),'TextType','string');
parts=cell(2,1);
for p=1:2
    platform=data.Platforms(p);
    b=readtable(fullfile(inputFolder,sprintf('blocks_%s.csv',platform)));
    data.Blocks{p}=b;
    m=data.Summary(data.Summary.Platform==platform,:);
    assert(height(m)==1 && m.Year==data.Years(p));
    use=logical(b.UseForCalibration);
    x=b.SpeedAdjustedAngle_s_radpm(use);y=b.ObservedExtraTime_s(use);
    assert(all(isfinite(x)) && all(isfinite(y)));
    checkC=sum(x.*y)/sum(x.^2);
    assert(abs(checkC-m.Coefficient_m_per_rad)<1e-9,'Stored fit and points differ.');
    assert(nnz(use)==m.CalibrationBlocks);
    d=sortrows(daily(daily.Platform==platform,:),'DateKey');
    assert(all(abs(d.ObservedTime_h-d.BaselineTime_h-d.ExtraTime_h)<1e-10));
    for k=1:height(d)
        day=b.DateKey==d.DateKey(k);
        observed=sum(b.Time_s(day))/3600;
        baseline=sum(b.Length_m(day)./b.LocalBaselineSpeed_mps(day))/3600;
        assert(abs(observed-d.ObservedTime_h(k))<1e-9);
        assert(abs(baseline-d.BaselineTime_h(k))<1e-9);
    end
    d.Year=repmat(data.Years(p),height(d),1);
    d.StraightShare_pct=100*d.BaselineTime_h./d.ObservedTime_h;
    d.TurningShare_pct=100*d.ExtraTime_h./d.ObservedTime_h;
    assert(all(abs(d.StraightShare_pct+d.TurningShare_pct-100)<1e-10));
    parts{p}=d;
end
data.DailyPlot=vertcat(parts{:});
end
