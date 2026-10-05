function fig=plot_combined_rmse_time(data,cfg)
%PLOT_COMBINED_RMSE_TIME Continuous responses, fitted crossings and internal insets.
fig=new_draft_figure(cfg.CombinedFigureSize_cm,cfg);
mainAxes=gobjects(2,1);legendHandles=[];legendLabels=[];
headerChecks=zeros(2,5);
for platform=1:2
 pos=cfg.CombinedAxes_cm+[cfg.CurveColumnStep_cm*(platform-1),0,0,0];
 ax=axes(fig,'Units','centimeters','Position',pos);hold(ax,'on');mainAxes(platform)=ax;
 [hh,labels]=draw_responses(ax,data,cfg,platform,true);
 set_time_axes(ax,cfg,1);
 xlabel(ax,'Time (h)','FontSize',cfg.LabelFont);
 ylabel(ax,'RMSE (m)','FontSize',cfg.LabelFont);
 headerChecks(platform,:)=style_combined_axes(ax,cfg,char('a'+platform-1),cfg.PlatformTitles(platform));
 if platform==1,legendHandles=hh;legendLabels=labels;end
 roots=data.TurningPrincipalCrossings(data.TurningPrincipalCrossings.Platform== ...
  cfg.PlatformCodes(platform),:);
 span=range(roots.Time_h);padding=max(.75,.60*span);
 xrange=[floor((min(roots.Time_h)-padding)*2)/2, ...
  ceil((max(roots.Time_h)+padding)*2)/2];
 values=[];
 for path=1:2
  for scenario=1:2
   if scenario==1,f=data.RMSEFits{platform,path};
   else,f=data.NoTurningFits{platform,path};end
   tt=linspace(max(xrange(1),f.Time_h(1)),min(xrange(2),f.Time_h(end)),301);
   values=[values;exp(ppval(f.PP,log(tt(:))))]; %#ok<AGROW>
  end
 end
 yrange=[floor((min(values)-.02)*10)/10,ceil((max(values)+.02)*10)/10];
 rectangle(ax,'Position',[xrange(1),yrange(1),diff(xrange),diff(yrange)], ...
  'EdgeColor',[.5 .5 .5],'LineStyle',':','LineWidth',.5,'HandleVisibility','off');
 mark_crossings(ax,roots,cfg,platform,true);
 insetPos=[pos(1:2)+cfg.InsetOffsetSize_cm(1:2),cfg.InsetOffsetSize_cm(3:4)];
 if ~cfg.LoglogPreview
  insetPos(1)=pos(1)+pos(3)-cfg.InsetOffsetSize_cm(3)-.45;
 end
 iax=axes(fig,'Units','centimeters','Position',insetPos,'Color','w');hold(iax,'on');
 draw_responses(iax,data,cfg,platform,false);
 set(iax,'FontName',cfg.FontName,'FontSize',cfg.InsetTickFont,'TickDir','in', ...
  'LineWidth',.6,'TickLength',[.02 .02],'XMinorTick','off','YMinorTick','off', ...
  'Layer','top','XColor','k','YColor','k');
 box(iax,'on');grid(iax,'off');xlim(iax,xrange);ylim(iax,yrange);
 xticks(iax,linspace(xrange(1),xrange(2),3));xtickformat(iax,'%.1f');
 yticks(iax,linspace(yrange(1),yrange(2),3));ytickformat(iax,'%.2f');
 xlabel(iax,'');ylabel(iax,'');
 mark_crossings(iax,roots,cfg,platform,false);
 add_zoom_connectors(fig,ax,xrange,yrange,insetPos,cfg);
end
lg=legend(mainAxes(1),legendHandles,legendLabels,'NumColumns',4,'Orientation','horizontal','Box','off', ...
 'FontName',cfg.FontName,'FontSize',cfg.LegendFont,'AutoUpdate','off');
lg.ItemTokenSize=cfg.CombinedLegendItemTokenSize;lg.Units='centimeters';drawnow;
lp=lg.Position;
panelSpan=cfg.CurveColumnStep_cm+cfg.CombinedAxes_cm(3);
legendLeft=cfg.CombinedAxes_cm(1)+(panelSpan-lp(3))/2;
assert(legendLeft>=.10 && legendLeft+lp(3)<=cfg.CombinedFigureSize_cm(1)-.10, ...
 'The single-row legend must fit the 16 cm canvas at 9 pt.');
lg.Position=[legendLeft,.35,lp(3),lp(4)];
for platform=1:2
 mainAxes(platform).Position=cfg.CombinedAxes_cm+[cfg.CurveColumnStep_cm*(platform-1),0,0,0];
end
drawnow;
texts=findall(fig,'Type','text','Tag','InsetCrossingLabel');
bounds=zeros(numel(texts),4);labels=strings(numel(texts),1);
for k=1:numel(texts)
 bounds(k,:)=texts(k).Extent;labels(k)=string(texts(k).String);
 e=bounds(k,:);
 assert(e(1)>=0 && e(2)>=0 && e(1)+e(3)<=1 && e(2)+e(4)<=1, ...
  'Inset time label must lie completely inside its axes frame.');
end
report=table(labels,bounds(:,1),bounds(:,2),bounds(:,3),bounds(:,4), ...
 'VariableNames',{'Label','Left','Bottom','Width','Height'});
writetable(report,fullfile(cfg.ProcessedDir,'inset_text_bounds.csv'));
layoutReport=array2table(headerChecks,'VariableNames', ...
 {'FrameLeft_cm','TitleInitial_cm','PanelCentre_cm','YLabelCentre_cm','HeaderGap_cm'});
layoutReport.Platform=cfg.PlatformTitles';
layoutReport.LegendColumns=repmat(lg.NumColumns,2,1);
layoutReport.LegendLeft_cm=repmat(lg.Position(1),2,1);
layoutReport.LegendWidth_cm=repmat(lg.Position(3),2,1);
writetable(layoutReport,fullfile(cfg.ProcessedDir,'figure5_layout_checks.csv'));
end

function check=style_combined_axes(ax,cfg,letter,titleText)
% Align the title with the frame and centre the panel letter over the ylabel.
set(ax,'FontName',cfg.FontName,'FontSize',cfg.TickFont,'TickDir','in', ...
 'TickLength',[.012 .012],'LineWidth',cfg.LineWidth,'XColor','k','YColor','k', ...
 'XMinorTick','off','YMinorTick','off','Layer','top');
box(ax,'on');grid(ax,'off');drawnow;
ax.YLabel.Units='centimeters';
labelExtent=ax.YLabel.Extent;
labelCentre=labelExtent(1)+labelExtent(3)/2;
headerY=ax.Position(4)+cfg.PanelLabelGap_cm;
text(ax,labelCentre,headerY,sprintf('(%c)',letter),'Units','centimeters', ...
 'FontName',cfg.FontName,'FontSize',cfg.PanelFont,'FontWeight','normal', ...
 'HorizontalAlignment','center','VerticalAlignment','bottom', ...
 'Clipping','off','Interpreter','none','Tag','AlignedPanelLabel');
text(ax,0,headerY,titleText,'Units','centimeters','FontName',cfg.FontName, ...
 'FontSize',cfg.PanelFont,'FontWeight','normal','HorizontalAlignment','left', ...
 'VerticalAlignment','bottom','Clipping','off','Interpreter','none', ...
 'Tag','AlignedPlatformTitle');
check=[ax.Position(1),ax.Position(1),ax.Position(1)+labelCentre, ...
 ax.Position(1)+labelCentre,cfg.PanelLabelGap_cm];
end

function [hh,labels]=draw_responses(ax,data,cfg,platform,makeLegend)
hh=gobjects(4,1);labels=strings(4,1);
for path=1:2
 q=data.Time(data.Time.Platform==cfg.PlatformCodes(platform)&data.Time.Path==cfg.Paths(path),:);
 for scenario=1:2
  if scenario==1
   name="WithTurning";ls='-';description="with turning";time=q.WithTurning_h;
  else
   name="WithoutTurning";ls='--';description="without turning";time=q.WithoutTurning_h;
  end
  curve=data.TurningResponseCurves(data.TurningResponseCurves.Platform== ...
   cfg.PlatformCodes(platform)&data.TurningResponseCurves.Path==cfg.Paths(path)& ...
   data.TurningResponseCurves.Scenario==name,:);
  plot(ax,curve.Time_h,curve.FittedRMSE_m,ls,'Color',cfg.PathColours(path,:), ...
   'LineWidth',cfg.LineWidth,'HandleVisibility','off');
  plot(ax,time,q.RMSE_m,'LineStyle','none','Marker',cfg.Markers{path}, ...
   'MarkerSize',cfg.CombinedMarkerSize,'MarkerEdgeColor',cfg.PathColours(path,:), ...
   'MarkerFaceColor','none','LineWidth',cfg.LineWidth,'HandleVisibility','off');
  k=(path-1)*2+scenario;labels(k)=cfg.Paths(path)+" | "+description;
  if makeLegend
   % A proxy combines the fitted line style and the numerical path symbol.
   hh(k)=plot(ax,NaN,NaN,ls,'Color',cfg.PathColours(path,:), ...
    'LineWidth',cfg.LineWidth,'Marker',cfg.Markers{path}, ...
    'MarkerSize',cfg.LegendMarkerSize,'MarkerFaceColor','none', ...
    'MarkerEdgeColor',cfg.PathColours(path,:));
  end
 end
end
end

function mark_crossings(ax,roots,cfg,platform,isMain)
colour=cfg.CrossingColours(platform,:);marker=cfg.CrossingMarkers{platform};
for k=1:height(roots)
 with=roots.Scenario(k)=="WithTurning";
 if with,face=colour;else,face='w';end
 plot(ax,roots.Time_h(k),roots.RMSE_m(k),'LineStyle','none', ...
  'Marker',marker,'MarkerSize',cfg.CrossingMarkerSize, ...
  'MarkerEdgeColor',colour,'MarkerFaceColor',face,'LineWidth',.8, ...
  'HandleVisibility','off','Tag','PlatformCrossover');
 if isMain,continue;end
 if with,x=.96;y=.94;align='right';vertical='top';
 else,x=.04;y=.06;align='left';vertical='bottom';end
 label=sprintf('%.2f h',roots.Time_h(k));font=cfg.InsetTickFont;
 text(ax,x,y,label,'Units','normalized','FontName',cfg.FontName,'FontSize',font, ...
  'HorizontalAlignment',align,'VerticalAlignment',vertical, ...
  'Color',colour,'Interpreter','none','Clipping','on','Tag','InsetCrossingLabel');
end
end


function add_zoom_connectors(fig,ax,xrange,yrange,insetPos,cfg)
% Connect the lower corners of the highlighted region to the inset top edge.
pos=ax.Position;
for k=1:2
    xx=xrange(k);yy=yrange(1);
    if strcmp(ax.XScale,'log'),u=log(xx/ax.XLim(1))/log(ax.XLim(2)/ax.XLim(1));
    else,u=(xx-ax.XLim(1))/diff(ax.XLim);end
    if strcmp(ax.YScale,'log'),v=log(yy/ax.YLim(1))/log(ax.YLim(2)/ax.YLim(1));
    else,v=(yy-ax.YLim(1))/diff(ax.YLim);end
    from=pos(1:2)+[u*pos(3),v*pos(4)];
    to=[insetPos(1)+(k-1)*insetPos(3),insetPos(2)+insetPos(4)];
    annotation(fig,'line',[from(1),to(1)]/cfg.CombinedFigureSize_cm(1), ...
        [from(2),to(2)]/cfg.CombinedFigureSize_cm(2), ...
        'Color',[.5 .5 .5],'LineWidth',.6,'Tag','ZoomConnector');
end
end
