function checks = verify_turning_delivery(output)
%VERIFY_TURNING_DELIVERY Numerical acceptance: references and public route interface.
rows={};cfg=output.Config;
for p=1:numel(output.Models)
    m=output.Models{p};b=output.Blocks{p};name=m.Platform;
    baseline=b.Length_m./b.LocalBaselineSpeed_mps;
    rows{end+1}=row(name+": block time closure",max(abs(b.Time_s-baseline-b.ObservedExtraTime_s)),1e-8);
    straight=[0 0;1000 0];turn=[0 0;500 0;500 500;1000 500];
    a=xldturn.predict_route(straight,m);t=xldturn.predict_route(turn,m);
    translated=xldturn.predict_route(turn+[600000 3900000],m);
    mirrored=xldturn.predict_route(turn.*[1 -1],m);
    reversed=xldturn.predict_route(flipud(turn),m);
    rows{end+1}=row(name+": straight-route turning",a.TurningExtraTime_s,1e-6);
    rows{end+1}=row(name+": route time closure",abs(t.TotalTime_s-t.BaselineTime_s-t.TurningExtraTime_s),1e-9);
    rows{end+1}=row(name+": coordinate translation",abs(t.TotalTime_s-translated.TotalTime_s),1e-4);
    rows{end+1}=row(name+": mirror symmetry",abs(t.TotalTime_s-mirrored.TotalTime_s),1e-7);
    rows{end+1}=row(name+": route reversal",abs(t.TotalTime_s-reversed.TotalTime_s),1e-7);
    rows{end+1}=row(name+": positive turning duration",double(t.TurningExtraTime_s<=0),0);
    doubled=xldturn.predict_route(turn,m,2*m.BaselineSpeed_mps);
    rows{end+1}=row(name+": speed scaling",abs(doubled.TotalTime_s-0.5*t.TotalTime_s),1e-9);
end
checks=vertcat(rows{:});
end
function r=row(name,error,tolerance)
r=table(string(name),error,tolerance,isfinite(error)&&error<=tolerance, ...
 'VariableNames',{'Check','AbsoluteDifference','Tolerance','Pass'});
end
