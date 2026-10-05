function audit=add_turning_analysis_panels(fig,data,cfg)
%ADD_TURNING_ANALYSIS_PANELS Two calibration panels and daily observed hours.
% Dark fills show observed extra time relative to the local straight baseline.
rows=cell(3,1);
labelLeft=zeros(3,1);labelBottom=zeros(3,1);yLabelLeft=zeros(3,1);
legendRight=zeros(3,1);
tickLength_cm=zeros(3,1);
for p=1:2
    pos=cfg.FitPositions_cm(p,:);ax=analysis_axes(fig,pos,cfg);
    b=data.Blocks{p};m=data.Summary(data.Summary.Platform==data.Platforms(p),:);
    use=logical(b.UseForCalibration);
    x=b.SpeedAdjustedAngle_s_radpm(use);y=b.ObservedExtraTime_s(use);
    s=scatter(ax,x,y,cfg.ScatterSize,cfg.ScatterColors(p,:),'filled', ...
        'MarkerEdgeColor','none','Tag','calibration_scatter');
    s.UserData=struct('Year',data.Years(p),'CalibrationBlocks',nnz(use));
    xmax=max(x); % Both calibration axes end at the fitted-line domain.
    xx=linspace(0,max(x),150);
    f=plot(ax,xx,m.Coefficient_m_per_rad*xx,'Color',cfg.FitColors(p,:), ...
        'LineWidth',1.2,'Tag','calibration_fit');
    annotationHeights=cfg.StatisticTopNormalized-(0:2)*cfg.StatisticLineStep_cm/pos(4);
    ylimits=[floor(min(y)/5)*5-5,ceil(max(y)/10)*10+5];
    % Keep the fit below the final annotation after increasing the line spacing.
    textHeight_cm=cfg.AnalysisFont*2.54/72;
    lowestText=annotationHeights(end)-(textHeight_cm+cfg.StatisticFitClearance_cm)/pos(4);
    neededUpper=ylimits(1)+(max(f.YData)-ylimits(1))/lowestText;
    ylimits(2)=max(ylimits(2),ceil(neededUpper/5)*5);
    xlim(ax,[0 xmax]);ylim(ax,ylimits);
    yline(ax,0,'--','Color',cfg.ZeroLineColor,'LineWidth',cfg.ZeroLineWidth_pt, ...
        'HandleVisibility','off','Tag','zero_duration_reference');
    xlabel(ax,'\Delta\it\theta\rm/\itv\rm (s·rad/m)','Interpreter','tex');
    ylabel(ax,'Additional duration, \Delta\itt\rm (s)','Interpreter','tex');
    text(ax,.04,.96,sprintf('Platform %d',data.Years(p)),'Units','normalized', ...
        'FontName',cfg.FontName,'FontSize',cfg.AnalysisDateFont,'FontWeight','normal', ...
        'Color',cfg.TurningColors(p,:),'VerticalAlignment','top');
    % Lowercase italic v in c_v; retain zero-intercept R_0^2.
    lines={sprintf('\\itc_{\\itv}\\rm = %.2f (m/rad)',m.Coefficient_m_per_rad), ...
        sprintf('\\itR\\rm_0^2 = %.3f',m.R2Zero),sprintf('\\itn\\rm = %d',nnz(use))};
    for k=1:numel(lines)
        text(ax,.96,annotationHeights(k),lines{k},'Units','normalized', ...
            'FontName',cfg.FontName,'FontSize',9, ...
            'Interpreter','tex','VerticalAlignment','top', ...
            'HorizontalAlignment','right','BackgroundColor','none','Margin',1);
    end
    pointToken=plot(ax,nan,nan,'o','MarkerSize',cfg.LegendMarkerSize_pt, ...
        'MarkerFaceColor',cfg.ScatterColors(p,:),'MarkerEdgeColor','none','LineStyle','none');
    lineToken=plot(ax,nan,nan,'-','Color',cfg.FitColors(p,:),'LineWidth',0.9);
    lg=legend(ax,[pointToken lineToken],{'Calibration blocks','Fitted relation'}, ...
        'NumColumns',2,'Box','off','FontName',cfg.FontName, ...
        'FontSize',cfg.AnalysisFont,'AutoUpdate','off');
    lg.ItemTokenSize=cfg.LegendTokenSize_pt;lg.Units='centimeters';drawnow;
    lp=lg.Position;
    lg.Position=[pos(1)+pos(3)-lp(3),pos(2)+pos(4)+.11,lp(3),lp(4)];
    ax.Position=pos;
    tickLength_cm(p)=ax.TickLength(1)*max(ax.Position(3:4));
    legendRight(p)=lg.Position(1)+lg.Position(3);
    [labelLeft(p),labelBottom(p),yLabelLeft(p)]=panel_label(fig,ax,sprintf('(%c)','g'+p-1),cfg);
    rows{p}=table(string(sprintf('%c','g'+p-1)),string(sprintf('%d calibration',data.Years(p))), ...
        nnz(use),m.Coefficient_m_per_rad,m.R2Zero, ...
        'VariableNames',{'Panel','Description','DataCount','Coefficient_m_per_rad','R2Zero'});
    rows{p}.FitLineEnd_x=max(x);rows{p}.AxisMaximum_x=xmax;
    rows{p}.StatisticLineStep_cm=cfg.StatisticLineStep_cm;
    rows{p}.StatisticTop=annotationHeights(1);rows{p}.StatisticBottom=annotationHeights(end);
    rows{p}.YMinimum=ylimits(1);rows{p}.YMaximum=ylimits(2);
end

pos=cfg.BarPosition_cm;ax=analysis_axes(fig,pos,cfg);
d=data.DailyPlot;n2023=nnz(d.Year==2023);n2020=nnz(d.Year==2020);
positions=1:height(d);
values=[d.BaselineTime_h,d.ExtraTime_h];
bars=bar(ax,positions,values,'stacked','BarWidth',cfg.DailyBarWidth,'EdgeColor','none');
bars(1).FaceColor='flat';bars(2).FaceColor='flat';
light=[repmat(cfg.StraightColors(1,:),n2023,1);repmat(cfg.StraightColors(2,:),n2020,1)];
dark=[repmat(cfg.TurningColors(1,:),n2023,1);repmat(cfg.TurningColors(2,:),n2020,1)];
bars(1).CData=light;bars(2).CData=dark;
bars(1).Tag='daily_straight_share';bars(2).Tag='daily_turning_share';
xticks(ax,positions);xticklabels(ax,arrayfun(@short_date,d.DateKey,'UniformOutput',false));
xlim(ax,[.3 positions(end)+.7]);
maximum=ceil(max(d.ObservedTime_h));ylim(ax,[0 maximum]);yticks(ax,0:2:maximum);
ylabel(ax,'Survey duration (h)');
shareText=gobjects(height(d),1);
for k=1:height(d)
    shareText(k)=text(ax,positions(k),d.BaselineTime_h(k)+d.ExtraTime_h(k)/2,sprintf('%.1f %%',d.TurningShare_pct(k)), ...
        'FontName',cfg.FontName,'FontSize',cfg.AnalysisFont,'Color','w', ...
        'HorizontalAlignment','center','VerticalAlignment','middle');
end
handles=gobjects(4,1);
legendColors=[cfg.StraightColors(1,:);cfg.TurningColors(1,:); ...
    cfg.StraightColors(2,:);cfg.TurningColors(2,:)];
for k=1:4
    handles(k)=patch(ax,nan,nan,legendColors(k,:),'EdgeColor','none');
end
lg=legend(ax,handles,{'2023: baseline time','2023: turning extra time', ...
    '2020: baseline time','2020: turning extra time'},'NumColumns',1,'Box','off', ...
    'FontName',cfg.FontName,'FontSize',cfg.AnalysisFont,'AutoUpdate','off');
lg.ItemTokenSize=cfg.LegendTokenSize_pt;lg.Units='centimeters';drawnow;
lp=lg.Position;
lg.Position=[cfg.OverallRight_cm-lp(3),pos(2)+(pos(4)-lp(4))/2,lp(3),lp(4)];
pos(3)=lg.Position(1)-cfg.BarLegendGap_cm-pos(1);
assert(pos(3)>9.90,'Daily duration panel must be wider than the previous layout.');
ax.Position=pos;
ax.TickLength=cfg.TickLength_cm/max(pos(3:4))*[1 1];
drawnow;
percentageBounds=zeros(height(d),4);
for k=1:height(d)
    extent=shareText(k).Extent;percentageBounds(k,:)=extent;
    assert(extent(1)>=positions(k)-cfg.DailyBarWidth/2 && ...
        extent(1)+extent(3)<=positions(k)+cfg.DailyBarWidth/2, ...
        'A percentage label is wider than its bar.');
    assert(extent(2)>=d.BaselineTime_h(k) && ...
        extent(2)+extent(4)<=d.ObservedTime_h(k), ...
        'A percentage label does not fit inside its coloured segment: date %d, text height %.4f h, segment height %.4f h.', ...
        d.DateKey(k),extent(4),d.ExtraTime_h(k));
end
percentageAudit=table(d.DateKey,d.TurningShare_pct,percentageBounds(:,1), ...
    percentageBounds(:,2),percentageBounds(:,3),percentageBounds(:,4), ...
    'VariableNames',{'DateKey','TurningShare_pct','TextLeft','TextBottom','TextWidth','TextHeight'});
writetable(percentageAudit,fullfile(cfg.AuditDir,'percentage_label_bounds.csv'));
tickLength_cm(3)=ax.TickLength(1)*max(ax.Position(3:4));
assert(lg.Position(1)>pos(1)+pos(3),'Daily legend overlaps its axes.');
legendRight(3)=lg.Position(1)+lg.Position(3);
[labelLeft(3),labelBottom(3),yLabelLeft(3)]=panel_label(fig,ax,'(i)',cfg);
rows{3}=table("i","Daily observed-time decomposition",height(d),nan,nan, ...
    'VariableNames',{'Panel','Description','DataCount','Coefficient_m_per_rad','R2Zero'});
rows{3}.FitLineEnd_x=nan;rows{3}.AxisMaximum_x=nan;
rows{3}.StatisticLineStep_cm=nan;rows{3}.StatisticTop=nan;rows{3}.StatisticBottom=nan;
rows{3}.YMinimum=0;rows{3}.YMaximum=maximum;
audit=vertcat(rows{:});
positions_cm=[cfg.FitPositions_cm;pos];
audit.FrameLeft_cm=positions_cm(:,1);
audit.FrameRight_cm=positions_cm(:,1)+positions_cm(:,3);
audit.FrameTop_cm=positions_cm(:,2)+positions_cm(:,4);
audit.LabelLeft_cm=labelLeft;
audit.LabelBottom_cm=labelBottom;
audit.YAxisTitleLeft_cm=yLabelLeft;
audit.LabelReference=repmat("y-axis title",3,1);
audit.LegendRight_cm=legendRight;
audit.TickDirection=repmat("in",3,1);
audit.TickLength_cm=tickLength_cm;
audit.StatisticsBackground=["none";"none";"not applicable"];
audit.BoxLayer=repmat("top",3,1);
audit.ZeroLineWidth_pt=[cfg.ZeroLineWidth_pt;cfg.ZeroLineWidth_pt;nan];
end

function ax=analysis_axes(fig,pos,cfg)
tickFraction=cfg.TickLength_cm/max(pos(3:4));
ax=axes(fig,'Units','centimeters','Position',pos,'FontName',cfg.FontName, ...
    'FontSize',cfg.AnalysisFont,'Box','on','Layer','top','LineWidth',cfg.FrameWidth, ...
    'XColor','k','YColor','k','Color','w','TickDir','in', ...
    'TickLength',[tickFraction tickFraction],'LabelFontSizeMultiplier',1);
hold(ax,'on');grid(ax,'off');
end

function [left,bottom,yLabelLeft]=panel_label(fig,ax,label,cfg)
% Use the rendered local y-axis title, rather than a shared fixed offset.
drawnow;pos=ax.Position;
originalUnits=ax.YLabel.Units;
ax.YLabel.Units='centimeters';drawnow;
extent=ax.YLabel.Extent;
yLabelLeft=pos(1)+extent(1);
ax.YLabel.Units=originalUnits;
left=yLabelLeft;
bottom=pos(2)+pos(4)+cfg.PanelLabelGap_cm;
sz=cfg.FigureSize_cm;
annotation(fig,'textbox',[left/sz(1),bottom/sz(2), ...
    .5/sz(1),.34/sz(2)],'String',label,'FontName',cfg.FontName, ...
    'FontSize',cfg.PanelFont,'FontWeight','normal','EdgeColor','none', ...
    'Margin',0,'VerticalAlignment','bottom');
end

function label=short_date(key)
day=mod(key,100);month=floor(mod(key,10000)/100);
if month==7, mon='Jul';elseif month==8, mon='Aug';else,mon=string(month);end
label=sprintf('%d %s',day,mon);
end

