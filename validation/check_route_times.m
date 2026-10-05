function audit=check_route_times
% Check every adopted route and both platform times without running DEM interpolation.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_project;
g=fullfile(root,'data','raw','geometry');model=struct;
for field=["leftBank","rightBank","thalweg"]
 t=readtable(fullfile(g,field+'.csv'));model.(field)=[t.Easting_m t.Northing_m];model.station=t.Station_m;
end
model.channelBoundaryClosed=readmatrix(fullfile(g,'evaluation_boundary.csv'));
cfg=rmse_time_config(root);cal=turning_config(root);
ref=readtable(fullfile(root,'reference','layouts.csv'),'TextType','string');
platforms=readtable(fullfile(root,'reference','turning','Summary.csv'),'TextType','string');
design=readtable(fullfile(root,'config','layout_design.csv'),'TextType','string');parts=cell(height(design),1);
for k=1:height(design)
 row=design(k,:);[xy,info]=xldsurvey.map_route(row.Path,row.CanonicalRequestedD_m,model,cfg);
 assert(info.isClosed&&info.nIntervals==row.ConstructionIntervals);
 records=cell(2,1);
 for p=1:2
  m=struct('BaselineSpeed_mps',platforms.BaselineSpeed_mps(p),'Coefficient_m_per_rad',platforms.Coefficient_m_per_rad(p));
  m.Processing=cal;
  result=xldturn.predict_route(xy,m);old=ref(ref.CaseID==row.CaseID&ref.Platform==platforms.Platform(p),:);
  e=[abs(result.PathLength_m-old.PathLength_m),abs(result.AbsoluteTurnAngle_rad-old.AbsoluteTurnAngle_rad),abs(result.TotalTime_h-old.TotalTime_h)];
  records{p}=table(row.CaseID,platforms.Platform(p),e(1),e(2),e(3),all(e<[1e-5 1e-4 1e-5]), ...
   'VariableNames',{'CaseID','Platform','LengthDifference_m','AngleDifference_rad','TimeDifference_h','Pass'});
 end
 parts{k}=vertcat(records{:});fprintf('Route verification %d/%d: %s\n',k,height(design),row.CaseID);
end
audit=vertcat(parts{:});writetable(audit,fullfile(root,'validation','route_time_comparison.csv'));assert(all(audit.Pass));
end
