function segments = segment_table(info)
%SEGMENT_TABLE Complete route legs with travel/observation role; all are measured.
control=info.controlPointsRectangular;idx=info.controlVertexIndices;
n=size(control,1)-1;roles=strings(n,1);voyage=strings(n,1);lengths=zeros(n,1);
outwardLegs=size(info.controlOutwardRectangular,1)-1;
for j=1:n
    a=control(j,:);b=control(j+1,:);isReturn=j>outwardLegs;
    if isReturn,voyage(j)="return";else,voyage(j)="outward";end
    if info.scheme=='A'
        if isReturn,roles(j)=info.returnType;
        elseif abs(a(1)-b(1))<1e-8,roles(j)="cross_section";
        else,roles(j)="boundary_connector";end
    else
        if abs(a(1)-b(1))<1e-8
            if a(1)<1e-8,roles(j)="upstream_closure";else,roles(j)="downstream_connection";end
        else,roles(j)="cross_zigzag";end
    end
    xy=info.trajectory(idx(j):idx(j+1),:);lengths(j)=sum(hypot(diff(xy(:,1)),diff(xy(:,2))));
end
segments=table((1:n)',idx(1:end-1),idx(2:end),roles,voyage,true(n,1),lengths, ...
    'VariableNames',{'SegmentID','FirstPoint','LastPoint','Role','VoyageStage','IsMeasured','Length_m'});
end
