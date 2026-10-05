function fig=plot_crossover_semilog(output,cfg)
%PLOT_CROSSOVER_SEMILOG One original branch, Cv<=500, log x and linear y.
fig=new_draft_figure(cfg.CrossoverFigureSize_cm,cfg);
ax=axes(fig,'Units','centimeters','Position',cfg.CrossoverAxes_cm);hold(ax,'on');
s=output.Sweep;
keep=s.Coefficient_m_per_rad>0 & s.Coefficient_m_per_rad<=cfg.CoefficientLimits_m_per_rad(2);
assert(any(keep));x=s.Coefficient_m_per_rad(keep);y=s.CrossoverTimeStar(keep);
handles=gobjects(3,1);
zero=s(s.Coefficient_m_per_rad==0,:);assert(height(zero)==1);
yline(ax,zero.CrossoverTimeStar,'--','Color',[.45 .45 .45], ...
 'LineWidth',.8,'HandleVisibility','off','Tag','ZeroTurningReference');
handles(1)=plot(ax,x,y,'-','Color',[.08 .08 .08],'LineWidth',1.05);
for p=1:2
 row=output.PlatformPoints(output.PlatformPoints.Platform==cfg.PlatformCodes(p),:);
 assert(height(row)==1);
 handles(p+1)=plot(ax,row.Coefficient_m_per_rad,row.CrossoverTimeStar, ...
  'LineStyle','none','Marker',cfg.CrossingMarkers{p},'MarkerSize',cfg.CrossingMarkerSize, ...
  'MarkerEdgeColor',cfg.CrossingColours(p,:),'MarkerFaceColor',cfg.CrossingColours(p,:), ...
  'LineWidth',.8,'Tag','PlatformCrossover');
end
set(ax,'XScale','log','YScale','linear','FontName',cfg.FontName, ...
 'FontSize',cfg.TickFont,'TickDir','in','TickLength',[.015 .015], ...
 'LineWidth',.8,'XMinorTick','off','YMinorTick','off','Layer','top', ...
 'XColor','k','YColor','k');
box(ax,'on');grid(ax,'off');
xlim(ax,[min(x),cfg.CoefficientLimits_m_per_rad(2)]);ylim(ax,[8 40]);
xticks(ax,[1 5 20 100 500]);xticklabels(ax,compose('%g',xticks(ax)));
yticks(ax,10:5:40);
xlabel(ax,'Turning coefficient, \itc_{v}\rm (m/rad)','FontSize',cfg.LabelFont);
ylabel(ax,'Normalized crossover time, \itT\rm_{cross}^*    (-)','FontSize',cfg.LabelFont);
lg=legend(ax,handles,["Tracked crossover",cfg.PlatformTitles], ...
 'Location','northwest','Box','off','FontSize',cfg.LegendFont,'AutoUpdate','off');
lg.ItemTokenSize=cfg.CombinedLegendItemTokenSize;
zeroLabel=text(ax,.04,.14, ...
 sprintf('\\itc_{v}\\rm = 0: \\itT\\rm_{cross}^* = %.2f',zero.CrossoverTimeStar), ...
 'Units','normalized','FontName',cfg.FontName,'FontSize',9,'Interpreter','tex', ...
 'Color',[.28 .28 .28],'HorizontalAlignment','left','VerticalAlignment','bottom', ...
 'Clipping','on','Tag','ZeroTurningLabel');
drawnow;
e=zeroLabel.Extent;
assert(e(1)>=0 && e(2)>=0 && e(1)+e(3)<=1 && e(2)+e(4)<=1, ...
 'Zero-turning annotation must fit inside the plot box.');
% Point explicitly to the zero-turning horizontal dashed reference.
arrowX=[.36 .42];
arrowY=[.135 (zero.CrossoverTimeStar-ax.YLim(1))/diff(ax.YLim)];
pos=cfg.CrossoverAxes_cm;
annotation(fig,'arrow',(pos(1)+pos(3)*arrowX)/cfg.CrossoverFigureSize_cm(1), ...
 (pos(2)+pos(4)*arrowY)/cfg.CrossoverFigureSize_cm(2), ...
 'Color',[.28 .28 .28],'LineWidth',.7,'HeadLength',4,'HeadWidth',4);

end
