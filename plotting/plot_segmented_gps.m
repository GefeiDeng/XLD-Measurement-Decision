function [fig,audit] = plot_segmented_gps(data,cfg)
%PLOT_SEGMENTED_GPS Metric GPS trajectories in a physical 4 + 1 + 3 layout.
% Each operation is a separate line. Every 2023 panel has identical bounds.
% The last panel spans three columns and combines both 2020 days.
assert(numel(cfg.Dates2023)==5 && numel(cfg.Dates2020)==2);
sz=cfg.FigureSize_cm;
width=(sz(1)-cfg.Left_cm-cfg.Right_cm-3*cfg.ColumnGap_cm)/4;
fig=figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 sz],'PaperUnits','centimeters','PaperSize',sz, ...
    'PaperPosition',[0 0 sz],'PaperPositionMode','manual','InvertHardcopy','off');
set(fig,'DefaultAxesFontName',cfg.FontName,'DefaultTextFontName',cfg.FontName);
data2023=data.Days(ismember([data.Days.DateKey],cfg.Dates2023));
commonBounds=fit_bounds(data2023,width/cfg.PanelHeight_cm,cfg.BoundsPadding);
auditRows=cell(6,1);northReferenceX_cm=nan;
for i=1:6
    if i<=4
        key=cfg.Dates2023(i); days=data.Days([data.Days.DateKey]==key);
        pos=[cfg.Left_cm+(i-1)*(width+cfg.ColumnGap_cm), ...
            cfg.TopRowBottom_cm,width,cfg.PanelHeight_cm];
        bounds=commonBounds; color=cfg.PlatformColors(1,:);
        titleText=short_panel_date(key);
    elseif i==5
        key=cfg.Dates2023(5); days=data.Days([data.Days.DateKey]==key);
        pos=[cfg.Left_cm,cfg.BottomRowBottom_cm,width,cfg.PanelHeight_cm];
        bounds=commonBounds; color=cfg.PlatformColors(1,:);
        titleText=short_panel_date(key);
    else
        days=data.Days(ismember([data.Days.DateKey],cfg.Dates2020));
        pos=[cfg.Left_cm+width+cfg.ColumnGap_cm,cfg.BottomRowBottom_cm, ...
            3*width+2*cfg.ColumnGap_cm,cfg.PanelHeight_cm];
        bounds=fit_bounds(days,pos(3)/pos(4),cfg.BoundsPadding);
        color=cfg.PlatformColors(2,:);
        titleText='17 & 23 Aug 2020';
    end
    ax=axes(fig,'Units','centimeters','Position',pos,'FontName',cfg.FontName, ...
        'FontSize',cfg.MapFont,'Box','on','Layer','top','LineWidth',cfg.FrameWidth, ...
        'XTick',[],'YTick',[],'XColor','k','YColor','k','Color','w', ...
        'XLim',bounds(1:2),'YLim',bounds(3:4),'DataAspectRatio',[1 1 1], ...
        'XLimMode','manual','YLimMode','manual');
    hold(ax,'on'); grid(ax,'off');
    points=0; nOperations=0; allInside=true;
    dayHandles=gobjects(numel(days),1); dayLabels=cell(numel(days),1); dayIndex=0;
    for day=reshape(days,1,[])
        dayIndex=dayIndex+1;
        style='-'; dayColor=color;
        if i==6
            styleIndex=find(cfg.Dates2020==day.DateKey,1);
            dayColor=cfg.Colors2020(styleIndex,:); style=cfg.LineStyles2020{styleIndex};
        end
        runIndex=0;
        for run=reshape(day.Runs,1,[])
            runIndex=runIndex+1;
            lineHandle=plot(ax,run.X_m,run.Y_m,'LineStyle',style, ...
                'Color',dayColor,'LineWidth',cfg.TrackWidth,'Tag','gps_trajectory');
            lineHandle.UserData=struct('DateKey',day.DateKey,'OperationID',run.OperationID);
            if runIndex==1, dayHandles(dayIndex)=lineHandle; end
            points=points+numel(run.X_m); nOperations=nOperations+1;
            allInside=allInside && all(run.X_m>=bounds(1) & run.X_m<=bounds(2) ...
                & run.Y_m>=bounds(3) & run.Y_m<=bounds(4));
        end
        dayLabels{dayIndex}=format_date(day.DateKey);
    end
    assert(allInside,'A plotted trajectory is clipped.');
    alignNorthX=[];if i==6,alignNorthX=northReferenceX_cm;end
    [bearing,north]=add_north_arrow(ax,bounds,pos,cfg,alignNorthX);
    if i==4,northReferenceX_cm=north.LabelX_cm;end
    add_distance_bar(ax,bounds,pos,cfg);
    labelRight=pos(1); % The label right edge meets its own frame left edge.
    labelWidth=.46;labelLeft=labelRight-labelWidth;
    labelBottom=pos(2)+pos(4)+cfg.PanelLabelGap_cm;
    annotation(fig,'textbox',[labelLeft/sz(1),labelBottom/sz(2), ...
        labelWidth/sz(1),.34/sz(2)],'String',sprintf('(%c)','a'+i-1), ...
        'FontName',cfg.FontName,'FontSize',cfg.PanelFont,'FontWeight','normal', ...
        'EdgeColor','none','Margin',0,'VerticalAlignment','bottom', ...
        'HorizontalAlignment','right');
    text(ax,cfg.DateInset_cm(1)/pos(3),1-cfg.DateInset_cm(2)/pos(4), ...
        titleText,'Units','normalized','Tag','panel_date', ...
        'FontName',cfg.FontName,'FontSize',cfg.TitleFont,'Interpreter','none', ...
        'Color','k','HorizontalAlignment','left','VerticalAlignment','top');
    if i==6
        lg=legend(ax,dayHandles,dayLabels,'FontName',cfg.FontName, ...
            'FontSize',cfg.MapFont,'Box','off','NumColumns',1,'AutoUpdate','off');
        lg.ItemTokenSize=[16 8]; lg.Units='centimeters'; drawnow;
        lp=lg.Position;
        lg.Position=[north.LabelX_cm-cfg.LegendNorthGap_cm-lp(3), ...
            pos(2)+pos(4)-cfg.LegendTopInset_cm-lp(4),lp(3),lp(4)];
        assert(lg.Position(1)+lg.Position(3)<north.LabelX_cm-.15, ...
            'The 2020 legend must lie to the left of the north arrow.');
        assert(lg.Position(1)>=pos(1) && lg.Position(2)>=pos(2) ...
            && lg.Position(1)+lg.Position(3)<=pos(1)+pos(3) ...
            && lg.Position(2)+lg.Position(4)<=pos(2)+pos(4), ...
            'The 2020 legend must remain inside its panel.');
    end
    auditRows{i}=table(string(sprintf('%c','a'+i-1)),string(titleText), ...
        nOperations,points,pos(1),pos(2),pos(3),pos(4), ...
        bounds(1),bounds(2),bounds(3),bounds(4), ...
        cfg.ScaleLength_m,bearing,true, ...
        'VariableNames',{'Panel','Title','Operations','PlottedPoints','Left_cm', ...
        'Bottom_cm','Width_cm','Height_cm','XMinimum_m','XMaximum_m', ...
        'YMinimum_m','YMaximum_m','DistanceBar_m','NorthBearing_deg','AllPointsInside'});
    auditRows{i}.LabelLeft_cm=labelLeft;
    auditRows{i}.LabelRight_cm=labelRight;
    auditRows{i}.LabelBottom_cm=labelBottom;
    auditRows{i}.LabelReference="label right edge to frame left edge";
    auditRows{i}.BoxLayer=string(ax.Layer);
    auditRows{i}.NorthLabelX_cm=north.LabelX_cm;
    auditRows{i}.NorthTipX_cm=north.TipX_cm;
    auditRows{i}.NorthBaseX_cm=north.BaseX_cm;
    if i==6
        auditRows{i}.LegendRight_cm=lg.Position(1)+lg.Position(3);
        auditRows{i}.LegendTop_cm=lg.Position(2)+lg.Position(4);
    else
        auditRows{i}.LegendRight_cm=nan;auditRows{i}.LegendTop_cm=nan;
    end
end
drawnow;
audit=vertcat(auditRows{:});
assert(all(max(audit{1:5,9:12},[],1)-min(audit{1:5,9:12},[],1)==0), ...
    'The 2023 display ranges differ.');
assert(abs(fig.PaperSize(1)-16)<1e-9,'Figure width must be 16 cm.');
assert(abs(audit.NorthLabelX_cm(4)-audit.NorthLabelX_cm(6))<1e-9, ...
    'North labels in panels (d) and (f) must be horizontally aligned.');
assert(abs(audit.NorthTipX_cm(4)-audit.NorthTipX_cm(6))<1e-9, ...
    'North-arrow tips in panels (d) and (f) must be horizontally aligned.');
end

function bounds=fit_bounds(days,aspect,padding)
xs=[]; ys=[];
for day=reshape(days,1,[])
    for run=reshape(day.Runs,1,[])
        xs=[xs;run.X_m]; ys=[ys;run.Y_m]; %#ok<AGROW>
    end
end
assert(~isempty(xs));
centre=[(min(xs)+max(xs))/2,(min(ys)+max(ys))/2];
w=(max(xs)-min(xs))*(1+2*padding);
h=(max(ys)-min(ys))*(1+2*padding);
w=max(w,h*aspect); h=w/aspect;
bounds=[centre(1)-w/2,centre(1)+w/2,centre(2)-h/2,centre(2)+h/2];
end

function titleText=short_panel_date(key)
month=floor(mod(key,10000)/100);
if month==7,mon='Jul';else,mon='Aug';end
titleText=sprintf('%d %s %d',mod(key,100),mon,floor(key/10000));
end

function titleText=format_date(key)
months={'January','February','March','April','May','June', ...
    'July','August','September','October','November','December'};
year=floor(key/10000); month=floor(mod(key,10000)/100); day=mod(key,100);
titleText=sprintf('%d %s %d',day,months{month},year);
end

function titleText=format_joined_dates(keys)
years=floor(keys/10000); months=floor(mod(keys,10000)/100);
if all(years==years(1)) && all(months==months(1))
    example=format_date(keys(1));
    suffix=extractAfter(string(example),strlength(string(mod(keys(1),100))));
    titleText=char(strjoin(string(mod(keys,100)),' & ')+suffix);
else
    labels=arrayfun(@format_date,keys,'UniformOutput',false);
    titleText=strjoin(labels,' & ');
end
end

function [bearing,glyph]=add_north_arrow(ax,bounds,pos,cfg,alignX_cm)
dx=diff(bounds(1:2)); dy=diff(bounds(3:4));
cx=mean(bounds(1:2)); cy=mean(bounds(3:4));
% True north is derived from the supplied projected CRS.
% Projection conversion is used only for this glyph, never to alter GPS.
crs=projcrs(cfg.ProjectedCRS);
[latitude,longitude]=projinv(crs,cx,cy);
[nx,ny]=projfwd(crs,latitude+0.005,longitude);
direction=[nx-cx,ny-cy]; direction=direction/norm(direction);
bearing=atan2d(direction(1),direction(2));
length_m=dy*.42/pos(4);
base=[bounds(1)+.89*dx,bounds(3)+(1-.97/pos(4))*dy];
if ~isempty(alignX_cm)
    targetTipX=bounds(1)+(alignX_cm-pos(1))/pos(3)*dx;
    base(1)=targetTipX-length_m*direction(1);
end
tip=base+length_m*direction;
glyph=struct('LabelX_cm',pos(1)+(tip(1)-bounds(1))/dx*pos(3), ...
    'TipX_cm',pos(1)+(tip(1)-bounds(1))/dx*pos(3), ...
    'BaseX_cm',pos(1)+(base(1)-bounds(1))/dx*pos(3));
headLength=dy*.13/pos(4); headHalfWidth=dx*.055/pos(3);
normal=[direction(2),-direction(1)];
neck=tip-headLength*direction;
line(ax,[base(1) neck(1)],[base(2) neck(2)],'Color','k','LineWidth',.7);
vertices=[tip;neck+headHalfWidth*normal;neck-headHalfWidth*normal];
patch(ax,vertices(:,1),vertices(:,2),'k','EdgeColor','k','LineWidth',.4);
text(ax,tip(1),tip(2)+dy*.10/pos(4),'N','FontName',cfg.FontName, ...
    'FontSize',cfg.MapFont,'HorizontalAlignment','center','VerticalAlignment','bottom');
end

function add_distance_bar(ax,bounds,pos,cfg)
dx=diff(bounds(1:2)); dy=diff(bounds(3:4));
x0=bounds(1)+.08*dx; y0=bounds(3)+.16*dy;
length_m=cfg.ScaleLength_m; half=length_m/2; bh=dy*.045/pos(4);
assert(x0+length_m<bounds(2),'Distance bar exceeds panel.');
patch(ax,x0+[0 half half 0],y0+[0 0 bh bh],'k','EdgeColor','k','LineWidth',.6);
patch(ax,x0+[half length_m length_m half],y0+[0 0 bh bh],'w','EdgeColor','k','LineWidth',.6);
text(ax,x0,y0-dy*.07/pos(4),'0','FontName',cfg.FontName, ...
    'FontSize',cfg.MapFont,'HorizontalAlignment','center','VerticalAlignment','top');
text(ax,x0+length_m,y0-dy*.07/pos(4),sprintf('%g km',length_m/1000), ...
    'FontName',cfg.FontName,'FontSize',cfg.MapFont, ...
    'HorizontalAlignment','center','VerticalAlignment','top');
end
