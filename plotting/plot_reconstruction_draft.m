function fig=plot_reconstruction_draft(data,cfg)
%PLOT_RECONSTRUCTION_DRAFT Cached surfaces/routes; finer error scale for dense rows.
fig=new_draft_figure(cfg.MapFigureSize_cm,cfg);
mapAxes=gobjects(8,1);colourbars=gobjects(8,1);
panelLabels=gobjects(8,1);titleLabels=gobjects(8,1);
for row=1:4
 s=data.Surfaces(row);
 for col=1:2
  pos=cfg.MapAxes_cm+[cfg.MapColumnStep_cm*(col-1), ...
   -cfg.MapRowStep_cm*(row-1),0,0];
  ax=axes(fig,'Units','centimeters','Position',pos);hold(ax,'on');
  if col==1,z=s.Prediction;cmap=cfg.ElevationMap;limits=data.Map.ElevationLimits;
   titleText=sprintf('%s | \\itn\\rm = %d',s.Path,s.N);
   label='Bed elevation (m)';
  else,z=s.Error;cmap=cfg.ErrorMap;limits=data.Map.ErrorLimits;
   if row>=3,limits=cfg.DenseErrorLimits;end
   titleText=sprintf('RMSE = %.3f m',s.RMSE_m);label='Elevation error (m)';
  end
  h=imagesc(ax,data.Map.X_km,data.Map.Y_km,z);h.AlphaData=isfinite(z);
  plot(ax,data.Map.Boundary_km(:,1),data.Map.Boundary_km(:,2), ...
   '-','Color',[.35 .35 .35],'LineWidth',.45);
  if row<=2 && col==1
   route=plot(ax,s.RouteXY_km(:,1),s.RouteXY_km(:,2), ...
    '-','Color',cfg.RouteColour,'LineWidth',cfg.RouteLineWidth, ...
    'HandleVisibility','off','Tag','SparseSurveyRoute');
   uistack(route,'top');
  end
  ax.SortMethod='childorder';
  set(ax,'YDir','normal','Color','w');axis(ax,'equal');axis(ax,data.Map.Limits);
  colormap(ax,cmap);clim(ax,limits);
  xlabel(ax,'Easting (km)','FontSize',cfg.LabelFont);
  ylabel(ax,'Northing (km)','FontSize',cfg.LabelFont);
  index=(row-1)*2+col;
  [panelLabels(index),titleLabels(index)]=style_draft_axes(ax,cfg, ...
   char('a'+index-1),titleText);
  cb=colorbar(ax);cb.Units='centimeters';cb.Position=[pos(1)+pos(3)+ ...
   cfg.ColourbarGap_cm,pos(2),cfg.ColourbarWidth_cm,pos(4)];
  cb.FontName=cfg.FontName;cb.FontSize=cfg.TickFont;cb.LineWidth=.6;
  cb.Label.String=label;cb.Label.FontSize=cfg.LabelFont;cb.Label.FontName=cfg.FontName;
  if col==2
   if row>=3,cb.Ticks=linspace(limits(1),limits(2),5);
   else,cb.Ticks=linspace(limits(1),limits(2),7);end
  end
  ax.Position=pos;
  index=(row-1)*2+col;mapAxes(index)=ax;colourbars(index)=cb;
 end
end
drawnow;
boxPositions=zeros(8,4);barPositions=zeros(8,4);
for index=1:8
 boxPositions(index,:)=actual_plot_box(mapAxes(index));
 box=boxPositions(index,:);
 colourbars(index).Position=[box(1)+box(3)+cfg.ColourbarGap_cm, ...
  box(2),cfg.ColourbarWidth_cm,box(4)];
 barPositions(index,:)=colourbars(index).Position;
end
drawnow;
headerPositions=zeros(8,4);
for index=1:8
 ax=mapAxes(index);box=actual_plot_box(ax);
 ax.YLabel.Units='centimeters';labelExtent=ax.YLabel.Extent;
 % The rotated 9 pt Times New Roman label has 1.15 mm of extent padding
 % before its exported glyph edge; compensate for visual left alignment.
 labelLeft=labelExtent(1)+.115;
 % Text in physical units is measured from the actual plot-box origin.
 headerY=box(4)+cfg.PanelLabelGap_cm;
 panelLabels(index).Units='centimeters';
 panelLabels(index).Position=[labelLeft,headerY,0];
 titleLabels(index).Units='centimeters';
 titleLabels(index).Position=[box(1)-ax.Position(1),headerY,0];
 headerPositions(index,:)=[ax.Position(1)+panelLabels(index).Position(1), ...
  ax.Position(1)+labelLeft,ax.Position(1)+titleLabels(index).Position(1),box(1)];
end
drawnow;
headers=table(string(('a':'h')'),headerPositions(:,1),headerPositions(:,2), ...
 headerPositions(:,3),headerPositions(:,4),'VariableNames', ...
 {'Panel','PanelLabelLeft_cm','YLabelLeft_cm','TitleLeft_cm','BoxLeft_cm'});
writetable(headers,fullfile(cfg.ProcessedDir,'map_header_alignment.csv'));
assert(max(abs(headerPositions(:,[1 3])-headerPositions(:,[2 4])),[],'all')<1e-8, ...
 'Map headers must align with their ylabel and plot box.');
alignment=table(string(('a':'h')'),boxPositions(:,2),boxPositions(:,4), ...
 barPositions(:,2),barPositions(:,4),'VariableNames', ...
 {'Panel','BoxBottom_cm','BoxHeight_cm','ColorbarBottom_cm','ColorbarHeight_cm'});
writetable(alignment,fullfile(cfg.ProcessedDir,'colorbar_alignment.csv'));
assert(max(abs(boxPositions(:,[2 4])-barPositions(:,[2 4])),[],'all')<1e-8, ...
 'Colorbar and rendered plot box do not align.');
end

function box=actual_plot_box(ax)
% Actual 2-D plot box, including the letterboxing imposed by axis equal.
if exist('tightPosition','file')||exist('tightPosition','builtin')
 box=tightPosition(ax);return
end
box=ax.Position;
if strcmp(ax.DataAspectRatioMode,'manual')
 ratio=diff(ax.XLim)*ax.DataAspectRatio(2)/(diff(ax.YLim)*ax.DataAspectRatio(1));
elseif strcmp(ax.PlotBoxAspectRatioMode,'manual')
 ratio=ax.PlotBoxAspectRatio(1)/ax.PlotBoxAspectRatio(2);
else
 return
end
if box(3)/box(4)>ratio
 width=box(4)*ratio;box(1)=box(1)+(box(3)-width)/2;box(3)=width;
else
 height=box(3)/ratio;box(2)=box(2)+(box(4)-height)/2;box(4)=height;
end
end
