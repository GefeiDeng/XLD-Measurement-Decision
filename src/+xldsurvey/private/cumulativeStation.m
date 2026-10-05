function station = cumulativeStation(xy)
%CUMULATIVESTATION Cumulative physical distance along a polyline.
station = [0;cumsum(hypot(diff(xy(:,1)),diff(xy(:,2))))];
end
