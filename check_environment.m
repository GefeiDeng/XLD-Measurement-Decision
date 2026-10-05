function report=check_environment
root=setup_project;
names=["MATLAB";"Mapping Toolbox";"Image Processing Toolbox";"Statistics and Machine Learning Toolbox";"Optimization Toolbox"];
products=ver;installed=string({products.Name});ok=ismember(names,installed);
report=table(names,ok,'VariableNames',{'Dependency','Available'});disp(report);
assert(all(ok),'Install the missing MATLAB products before a full run.');
python=getenv('IJSR_PYTHON');if isempty(python),python='python';end
[status,result]=system(sprintf('"%s" -c "import pypdf; print(pypdf.__version__)"',python));
assert(status==0,'Python/pypdf unavailable. Install requirements.txt or set IJSR_PYTHON.');
fprintf('Python pypdf: %s',result);
assert(any(strcmpi(listfonts,'Times New Roman')),'Times New Roman is required for the approved figure typography.');
assert(isfile(fullfile(root,'data','raw','dem_cropped.tif')),'Missing cropped DEM.');
fprintf('Required environment and principal input found.\n');
end
