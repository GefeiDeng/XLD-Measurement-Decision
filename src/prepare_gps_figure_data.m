function data=prepare_gps_figure_data(folder)
files=dir(fullfile(folder,'rebuilt_gps','*.csv'));days=cell(numel(files),1);
for i=1:numel(files)
 t=readtable(fullfile(files(i).folder,files(i).name),'TextType','string');ids=unique(t.OperationID);runs=cell(numel(ids),1);
 for j=1:numel(ids)
  q=t(t.OperationID==ids(j),:);runs{j}=struct('OperationID',ids(j),'X_m',q.X_m,'Y_m',q.Y_m);
 end
 days{i}=struct('DateKey',t.DateKey(1),'Runs',vertcat(runs{:}));
end
data=struct('Days',vertcat(days{:}));save(fullfile(folder,'used_gps_trajectories.mat'),'data');
end
