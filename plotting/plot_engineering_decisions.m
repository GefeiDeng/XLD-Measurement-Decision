function fig=plot_engineering_decisions(data,cfg)
%PLOT_ENGINEERING_DECISIONS Four maps with manual centimetre layout.
fig=figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 cfg.FigureSize_cm],'PaperUnits','centimeters', ...
    'PaperSize',cfg.FigureSize_cm,'PaperPosition',[0 0 cfg.FigureSize_cm], ...
    'PaperPositionMode','manual');
set(fig,'DefaultAxesFontName',cfg.FontName,'DefaultTextFontName',cfg.FontName);
fleetDisplayMax=min(data.FleetMax,cfg.FleetDisplayCap);
fleetPalette=interp1(data.Palette.Fraction,table2array(data.Palette(:,2:4))/255, ...
    linspace(0,1,fleetDisplayMax),'linear');
spacingPalette=interp1(data.Palette.Fraction,table2array(data.Palette(:,5:7))/255,linspace(0,1,256),'linear');
for i=1:2
    map=data.Maps{i};
    for j=1:2
        pos=cfg.AxesBase_cm+[cfg.ColumnStep_cm*(j-1),-cfg.RowStep_cm*(i-1),0,0];
        ax=axes(fig,'Units','centimeters','Position',pos);
        if j==1,values=min(map.N,fleetDisplayMax);else,values=log10(map.D_m);end
        img=imagesc(ax,data.Hours_h,data.TargetRMSE_m,values);img.AlphaData=double(map.Valid);
        hold(ax,'on');
        if j==1
            colormap(ax,fleetPalette);clim(ax,[.5,fleetDisplayMax+.5]);
            contour(ax,data.Hours_h,data.TargetRMSE_m,values,1.5:1:fleetDisplayMax-.5, ...
                'LineColor',cfg.FleetBoundaryColour,'LineWidth',cfg.FleetBoundaryWidth);
        else
            colormap(ax,spacingPalette);clim(ax,log10(data.SpacingLimits_m));
        end
        contour(ax,data.Hours_h,data.TargetRMSE_m,double(map.PathCode),[1.5 1.5], ...
            'LineColor','k','LineStyle','--','LineWidth',cfg.PathBoundaryWidth);
        set(ax,'YDir','normal','FontSize',cfg.TickFont,'TickDir','in','TickLength',[.01 .01], ...
            'LineWidth',cfg.AxisLineWidth,'XMinorTick','off','YMinorTick','off', ...
            'XColor','k','YColor','k','Layer','top','SortMethod','childorder','Color','w', ...
            'XLim',cfg.TimeLimits_h,'YLim',cfg.TargetLimits_m,'XTick',cfg.XTicks,'YTick',cfg.YTicks);
        box(ax,'on');grid(ax,'off');
        xlabel(ax,'Survey window \itH\rm (h)','FontSize',cfg.LabelFont,'Interpreter','tex');
        yLabel=ylabel(ax,'Target RMSE (m)','FontSize',cfg.LabelFont,'Interpreter','none');
        cb=colorbar(ax,'eastoutside');cb.Units='centimeters';ax.Position=pos;
        cb.FontName=cfg.FontName;cb.FontSize=cfg.ColourbarTickFont;cb.TickDirection='out';cb.LineWidth=.6;
        if j==1
            cb.Ticks=1:fleetDisplayMax;fleetLabels=string(cb.Ticks);
            if data.FleetMax>fleetDisplayMax,fleetLabels(end)=sprintf('%d+',fleetDisplayMax);end
            cb.TickLabels=fleetLabels;
            barTitle='\itN\rm_{min}';
        else
            ticks=cfg.SpacingTicks_m;ticks=ticks(ticks>=data.SpacingLimits_m(1)&ticks<=data.SpacingLimits_m(2));
            cb.Ticks=log10(ticks);cb.TickLabels=string(ticks);barTitle='\itL/\itn\rm (m)';
        end
        barX=pos(1)+pos(3)+cfg.ColourbarGap_cm;
        header=text(ax,barX-pos(1),pos(4)+cfg.ColourbarTitleInkOffset_cm,barTitle,'Units','centimeters', ...
            'FontName',cfg.FontName,'FontSize',cfg.ColourbarHeaderFont, ...
            'Interpreter','tex','VerticalAlignment','top','Clipping','off');
        drawnow;
        % Fit the bar below its measured title; together they span the plot height.
        headerBounds=header.Extent;
        barHeight=headerBounds(2)-cfg.ColourbarTitleGap_cm;
        cb.Position=[barX,pos(2),cfg.ColourbarWidth_cm,barHeight];
        ax.Position=pos;
        % Outside headers: P aligns with the plot's left edge, and the panel
        % identifier aligns with the left edge of the vertical axis title.
        drawnow;
        yLabel.Units='centimeters';labelBounds=yLabel.Extent;
        headerY=pos(4)+.10;
        text(ax,0,headerY,cfg.PlatformTitles(i),'Units','centimeters','FontSize',cfg.PanelFont, ...
            'HorizontalAlignment','left','VerticalAlignment','bottom','Interpreter','none','Clipping','off');
        text(ax,labelBounds(1),headerY,sprintf('(%c)','a'+(i-1)*2+j-1),'Units','centimeters', ...
            'FontSize',cfg.PanelFont,'FontWeight','normal','HorizontalAlignment','left', ...
            'VerticalAlignment','bottom','Clipping','off');
        add_path_labels(ax,data.Hours_h,data.TargetRMSE_m,map.PathCode,cfg,i);
        if cfg.ShowExample&&cfg.ExampleTime_h>=cfg.TimeLimits_h(1)&&cfg.ExampleTime_h<=cfg.TimeLimits_h(2) ...
                &&cfg.ExampleTarget_m>=cfg.TargetLimits_m(1)&&cfg.ExampleTarget_m<=cfg.TargetLimits_m(2)
            plot(ax,cfg.ExampleTime_h,cfg.ExampleTarget_m,'kp','MarkerFaceColor',cfg.ExampleFill, ...
                'MarkerSize',cfg.ExampleMarkerSize,'LineWidth',.65,'Clipping','off');
            text(ax,cfg.ExampleTime_h+cfg.ExampleTextOffset(1),cfg.ExampleTarget_m+cfg.ExampleTextOffset(2), ...
                cfg.ExampleLabel,'FontSize',cfg.TickFont,'BackgroundColor','w','Margin',.5,'Interpreter','none');
        end
    end
end
drawnow;
end

function add_path_labels(ax,H,E,path,cfg,platformIndex)
labels={'BCS','PCZ'};
for code=1:2
    location=cfg.PathLabelPositions{platformIndex}(code,:);
    label=text(ax,location(1),location(2),labels{code},'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle','FontSize',cfg.PathFont,'Color','k','Interpreter','none');
    drawnow;
    % Keep the complete text box plus a margin within its path region.
    bounds=label.Extent+[-.015 -.02 .030 .04];
    hBox=H(1)+(H(end)-H(1))*[bounds(1),bounds(1)+bounds(3)];
    eBox=E(1)+(E(end)-E(1))*[bounds(2),bounds(2)+bounds(4)];
    inside=path(E>=eBox(1)&E<=eBox(2),H>=hBox(1)&H<=hBox(2));
    assert(~isempty(inside)&&all(inside==code,'all'), ...
        'Move the %s label: it is too close to the path-switching boundary.',labels{code});
end
end
