function auxiliary = make_auxiliary_lines(model,count,resolution)
%MAKE_AUXILIARY_LINES Fixed three-line mapping, from left bank through thalweg to right bank.
validateattributes(count,{'numeric'},{'scalar','integer','>=',3});
assert(mod(count,2)==1,'xldsurvey:AuxiliaryCount','Use an odd number including thalweg.');
fractions=linspace(1,0,count);parts=cell(count,1);
for k=1:count
    eta=fractions(k);
    if eta<=.5,control=model.rightBank+2*eta*(model.thalweg-model.rightBank);
    else,control=model.thalweg+(2*eta-1)*(model.leftBank-model.thalweg);end
    xy=densifyPolyline(control,resolution);s=cumulativeStation(xy);
    parts{k}=table(repmat(k,size(xy,1),1),s,xy(:,1),xy(:,2), ...
       repmat(eta,size(xy,1),1),'VariableNames',{'ID','S','X','Y','LateralFraction'});
end
auxiliary=vertcat(parts{:});
end
