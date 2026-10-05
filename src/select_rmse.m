function o=select_rmse(fits,hours,target_m,dmax)
% Fit only RMSE(T). Spacing comes from linear lookup of numerical (T,D).
[H,E]=meshgrid(hours(:)',target_m(:));sz=size(H);fleet=inf([sz 2]);req=fleet;times=nan([sz 2]);errors=inf([sz 2]);spacings=times;
for j=1:2
 f=fits{j};lo=repmat(f.Time_h(1),numel(target_m),1);hi=repmat(f.Time_h(end),numel(target_m),1);target=target_m(:);
 emin=exp(ppval(f.PP,log(f.Time_h(end))));emax=exp(ppval(f.PP,log(f.Time_h(1))));
 for k=1:50
  mid=(lo+hi)/2;e=exp(ppval(f.PP,log(mid)));pick=e>target;lo(pick)=mid(pick);hi(~pick)=mid(~pick);
 end
 t=hi;t(target>=emax)=f.Time_h(1);t(target<emin)=inf;req(:,:,j)=repmat(t,1,numel(hours));fleet(:,:,j)=ceil(req(:,:,j)./H);
end
N=min(fleet,[],3);
for j=1:2
 f=fits{j};t=min(N.*H,f.Time_h(end));ok=isfinite(N)&fleet(:,:,j)==N&t>=f.Time_h(1);
 e=exp(ppval(f.PP,log(t)));dd=interp1(f.Time_h,f.D_m,t,'linear');e(~ok)=inf;t(~ok)=NaN;dd(~ok)=NaN;times(:,:,j)=t;errors(:,:,j)=e;spacings(:,:,j)=dd;
end
[err,path]=min(errors,[],3);valid=isfinite(err);path(~valid)=0;time=nan(sz);D=time;G=time;
for j=1:2
 pick=path==j;t=times(:,:,j);dd=spacings(:,:,j);time(pick)=t(pick);D(pick)=dd(pick);G(pick)=dd(pick)/fits{j}.Width_m;
end
err(~valid)=NaN;
o=struct('H',H,'TargetRstar',E/dmax,'N',N,'N_BCS',fleet(:,:,1),'N_PCZ',fleet(:,:,2),'RequiredTime_BCS_h',req(:,:,1),'RequiredTime_PCZ_h',req(:,:,2),'PathCode',uint8(path),'Gstar',G,'D_m',D,'PredictedRstar',err/dmax,'PredictedRMSE_m',err,'PredictedTime_h',time,'IdealCompletion_h',time./N,'UnusedVesselHours',N.*H-time,'Valid',valid);
end
