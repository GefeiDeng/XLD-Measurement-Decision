function root=setup_project
% Add only this project's code, regardless of the current working directory.
root=fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'src'),fullfile(root,'analysis'),fullfile(root,'plotting'),fullfile(root,'config'));
end
