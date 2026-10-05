function output=step05_calculate_crossings(root)
% Track the reported PCZ-to-BCS crossing for turning costs from 0 to 500 m/rad.
if nargin<1,root=setup_project;end
folder=fullfile(root,'results','figure_data');s=load(fullfile(folder,'reconstruction_and_rmse_time.mat'),'data');d=s.data;
source.Layouts=d.Time(d.Time.Platform=="A",:);source.Platforms=d.Models;
source.ReferenceLength_m=d.Domain.MappingLength_m;
source.PrincipalErrorLimits_m=d.Domain.ReferenceElevationRange_m*[.01 .03];
source.PreviousCrossings=d.TurningPrincipalCrossings;
cfg=struct('CoefficientGrid_m_per_rad',unique([0:300 310:10:500]),'Lambda',1e-4,'Paths',["BCS","PCZ"],'RootGridPoints',6000,'ResultDir',folder);
output=calculate_normalized_crossings(source,cfg);
save(fullfile(folder,'normalized_crossover_data.mat'),'output','-v7.3');
end
