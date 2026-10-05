function [xyz,qc] = sample_dem(xy,ctx,cfg)
%SAMPLE_DEM Bilinear bed-elevation sampling at every complete route point.
% Full DEM values are used; no underwater-channel clipping. Missing samples are explicit.
validateattributes(xy,{'numeric'},{'2d','ncols',2,'finite'});
[c,r]=worldToIntrinsic(ctx.R,xy(:,1),xy(:,2));
z=interp2(ctx.Z,c,r,char(cfg.SampleMethod),NaN);missing=~isfinite(z);originalMissing=nnz(missing);
fallbackDistance=zeros(originalMissing,1);
if any(missing)
    indices=find(missing);radius=ceil(cfg.MaximumSampleFallbackDistance_m/ ...
        min(ctx.R.CellExtentInWorldX,ctx.R.CellExtentInWorldY));
    for j=1:numel(indices)
        i=indices(j);rr=max(1,floor(r(i))-radius):min(size(ctx.Z,1),ceil(r(i))+radius);
        cc=max(1,floor(c(i))-radius):min(size(ctx.Z,2),ceil(c(i))+radius);
        [dy,dx]=find(isfinite(ctx.Z(rr,cc)));assert(~isempty(dy),'No finite DEM sample near route point.');
        ar=rr(dy);ac=cc(dx);[xx,yy]=intrinsicToWorld(ctx.R,ac(:),ar(:));
        [dist,pick]=min(hypot(xx-xy(i,1),yy-xy(i,2)));
        assert(dist<=cfg.MaximumSampleFallbackDistance_m,'Route point farther than allowed DEM fallback.');
        z(i)=ctx.Z(ar(pick),ac(pick));fallbackDistance(j)=dist;
    end
end
assert(all(isfinite(z)),'xldsurvey:Sampling','Incomplete real-DEM sampling.');
xyz=[xy,double(z(:))];qc=struct('PointCount',size(xy,1),'BilinearFiniteCount',size(xy,1)-originalMissing, ...
    'NearestFallbackCount',originalMissing,'MaximumFallbackDistance_m',max([0;fallbackDistance]), ...
    'MinimumZ_m',min(z),'MaximumZ_m',max(z));
end
