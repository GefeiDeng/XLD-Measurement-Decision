function rangeLabel=set_time_axes(ax,cfg,col)
%SET_TIME_AXES Coordinate display only; all RMSE values remain in metres.
if cfg.LoglogPreview
 set(ax,'XScale','log','YScale','log');
 if col==1
  xlim(ax,cfg.LogFullTimeLimits);ylim(ax,cfg.LogFullRMSELimits);
  xticks(ax,[1 2 5 10 20 50 100]);yticks(ax,[.1 .2 .5 1 2]);
  rangeLabel='full range (log-log)';
 else
  xlim(ax,cfg.LogZoomTimeLimits);ylim(ax,cfg.LogZoomRMSELimits);
  xticks(ax,[1 2 5 10 20]);yticks(ax,[.3 .5 1 1.5]);
  rangeLabel='1-24 h (log-log)';
 end
 xticklabels(ax,compose('%g',xticks(ax)));yticklabels(ax,compose('%g',yticks(ax)));
else
 if col==1
  xlim(ax,cfg.FullTimeLimits);ylim(ax,cfg.FullRMSELimits);rangeLabel='full range';
 else
  xlim(ax,cfg.ZoomTimeLimits);ylim(ax,cfg.ZoomRMSELimits);
  xticks(ax,0:6:24);rangeLabel='0-24 h';
 end
end
end
