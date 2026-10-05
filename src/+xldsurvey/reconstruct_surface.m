function metrics = reconstruct_surface(routeXYZ,auxiliaryXYZ,ctx,cfg,filename)
%RECONSTRUCT_SURFACE Trajectory + interpolated auxiliaries -> NN surface -> all-cell RMSE.
% All fixed evaluation cells count. Outside-hull nearest fill is separately recorded.
points=[routeXYZ;auxiliaryXYZ{:,{'X','Y','Z'}}];
[~,uniqueIndex]=unique(round(points(:,1:2),6),'rows','stable');points=points(uniqueIndex,:);
F=scatteredInterpolant(points(:,1),points(:,2),points(:,3),'natural','none');
n=numel(ctx.EvaluationIndices);sumSquared=0;sumAbsolute=0;sumError=0;maxAbsolute=0;
nativeSquared=0;nativeCount=0;filledCount=0;started=tic;
if cfg.WriteSurface
    CaseComplete=false;save(filename,'CaseComplete','-v7.3');surface=matfile(filename,'Writable',true);
    surface.Prediction_m(n,1)=single(NaN);surface.NativeNN(n,1)=false;
end
for first=1:cfg.QueryChunkSize:n
    j=first:min(n,first+cfg.QueryChunkSize-1);ids=ctx.EvaluationIndices(j);
    [r,c]=ind2sub(ctx.RasterSize,double(ids));[x,y]=intrinsicToWorld(ctx.R,c,r);
    prediction=F(x,y);native=isfinite(prediction);missing=~native;
    if any(missing)
        assert(cfg.ExtrapolationMethod=="nearest",'xldsurvey:NoFullSurface', ...
            'Full-domain RMSE requires explicit exterior fill; none leaves uncovered cells.');
        F.ExtrapolationMethod='nearest';prediction(missing)=F(x(missing),y(missing));F.ExtrapolationMethod='none';
    end
    % Score the stored surface precision, so archived data reproduce reported RMSE exactly.
    prediction=single(prediction);assert(all(isfinite(prediction)),'Uncovered evaluation cells.');
    error=double(prediction)-double(ctx.Truth(j));sumSquared=sumSquared+sum(error.^2);
    sumAbsolute=sumAbsolute+sum(abs(error));sumError=sumError+sum(error);maxAbsolute=max(maxAbsolute,max(abs(error)));
    nativeSquared=nativeSquared+sum(error(native).^2);nativeCount=nativeCount+nnz(native);filledCount=filledCount+nnz(missing);
    if cfg.WriteSurface,surface.Prediction_m(j,1)=prediction;surface.NativeNN(j,1)=native;end
    if first==1||j(end)==n||mod(ceil(first/cfg.QueryChunkSize),40)==0
        fprintf('    NN query %d/%d (%.1f%%), elapsed %.1f s\n',j(end),n,100*j(end)/n,toc(started));
    end
end
metrics=struct('RMSE_m',sqrt(sumSquared/n),'Rstar',sqrt(sumSquared/n)/ctx.Dmax_m, ...
 'MAE_m',sumAbsolute/n,'BiasPredictedMinusReference_m',sumError/n,'MaximumAbsoluteError_m',maxAbsolute, ...
 'EvaluationCells',n,'NativeNNCells',nativeCount,'NativeNNCoverage',nativeCount/n, ...
 'ExteriorFillCells',filledCount,'ExteriorFillFraction',filledCount/n,'NativeNN_RMSE_m',sqrt(nativeSquared/nativeCount), ...
 'InputUniquePoints',size(points,1),'NNElapsed_s',toc(started));
if cfg.WriteSurface,surface.Metrics=metrics;surface.CaseComplete=true;end
end
