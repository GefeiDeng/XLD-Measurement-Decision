function ctx = prepare_context(cfg)
%PREPARE_CONTEXT Read full reference DEM, fixed evaluation indices and geometry.
loaded=load(cfg.ChannelFile,'channelModel');model=loaded.channelModel;
info=georasterinfo(cfg.DEMFile);R=info.RasterReference;
Z=imread(cfg.DEMFile);if ndims(Z)>2,Z=Z(:,:,1);end;Z=single(Z);
if isempty(cfg.NoDataValue)
    assert(isfield(model,'noDataValue'),'xldsurvey:NoData','Supply an explicit DEM NoData value.');
    nodata=model.noDataValue;
else,nodata=cfg.NoDataValue;end
Z(Z==single(nodata))=NaN;
if ~isempty(info.MissingDataIndicator)
    for v=reshape(info.MissingDataIndicator,1,[]),Z(Z==single(v))=NaN;end
end
valid=isfinite(Z);fullCount=nnz(valid);
if cfg.EvaluationDomain=="banks"
    boundary=[double(model.leftBank);flipud(double(model.rightBank));double(model.leftBank(1,:))];
    [bc,br]=worldToIntrinsic(R,boundary(:,1),boundary(:,2));
    evaluationMask=poly2mask(bc,br,size(Z,1),size(Z,2));
    evaluationMask=evaluationMask & valid;
    evaluationIndices=uint32(find(evaluationMask));
elseif cfg.EvaluationDomain=="polygon"
    assert(size(cfg.EvaluationBoundaryXY,2)==2&&size(cfg.EvaluationBoundaryXY,1)>=4, ...
        'xldsurvey:Boundary','Supply the complete study boundary explicitly.');
    boundary=cfg.EvaluationBoundaryXY;
    [bc,br]=worldToIntrinsic(R,boundary(:,1),boundary(:,2));
    evaluationMask=poly2mask(bc,br,size(Z,1),size(Z,2)) & valid;
    evaluationIndices=uint32(find(evaluationMask));
elseif cfg.EvaluationDomain=="full_dem"
    evaluationIndices=uint32(find(valid));evaluationMask=valid;boundary=[];
else,error('xldsurvey:Domain','Use banks, full_dem or polygon with an explicit boundary.');end
assert(~isempty(evaluationIndices),'xldsurvey:NoEvaluation','No evaluation cells.');
truth=Z(evaluationIndices);dmax=double(max(truth))-double(min(truth));
assert(dmax>0,'xldsurvey:FlatReference','Reference elevation range must be positive.');
width=hypot(diff_pair(model.leftBank,model.rightBank,1),diff_pair(model.leftBank,model.rightBank,2));
ctx=struct('Z',Z,'R',R,'Model',model,'EvaluationIndices',evaluationIndices,'Truth',truth, ...
 'Dmax_m',dmax,'Width_m',mean(width),'Length_m',model.station(end)-model.station(1), ...
 'RasterSize',size(Z),'FullValidCount',fullCount,'NoDataValue',double(nodata), ...
 'CoordinateReferenceSystem',info.CoordinateReferenceSystem, ...
 'EvaluationMask',evaluationMask,'EvaluationBoundaryXY',boundary);
ctx.AuxiliaryXY=xldsurvey.make_auxiliary_lines(model,cfg.AuxiliaryLineCount,cfg.AuxiliaryResolution_m);
platforms=load(cfg.ModelFile,'Models');ctx.PlatformModels=platforms.Models;
ctx.SourceCellArea_m2=R.CellExtentInWorldX*R.CellExtentInWorldY;
end
function d=diff_pair(a,b,k),d=a(:,k)-b(:,k);end
