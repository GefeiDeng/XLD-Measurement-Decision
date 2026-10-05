function f=fit_monotone_rmse(t,e,lambda)
% Fit positive monotone RMSE trend in log coordinates, then PCHIP it.
% Equal layout weights; no endpoint truth or target crossing enters the fit.
[t,idx]=sort(t(:));e=e(idx);assert(all(diff(t)>0)&&all(e>0));
x=log(t);y=log(e);n=numel(x);h=diff(x);
A=diff(eye(n));B=zeros(n-2,n);
for k=1:n-2
 B(k,k:k+2)=[1/h(k),-1/h(k)-1/h(k+1),1/h(k+1)]/sqrt((h(k)+h(k+1))/2);
end
opts=optimoptions('lsqlin','Display','off','OptimalityTolerance',1e-10,'ConstraintTolerance',1e-10);
[z,~,~,flag]=lsqlin([eye(n);sqrt(lambda)*B],[y;zeros(n-2,1)],A,zeros(n-1,1),[],[],[],[],[],opts);
assert(flag>0&&all(diff(z)<=1e-7));
f=struct('Time_h',t,'Observed_m',e,'LogKnots',x,'LogValues',z,'PP',pchip(x,z),'Lambda',lambda,'ExitFlag',flag);
f.Prediction_m=exp(ppval(f.PP,x));
end
