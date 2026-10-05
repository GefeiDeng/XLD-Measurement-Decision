function stats=plot_turning_model_discussion(inputFolder,outputFolder,cfg)
% Reproduce the approved figure from the packaged calculation-result snapshots.
% The style follows Fig3_MSE_validation: Times New Roman, blue/red, inward ticks.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1 || isempty(inputFolder), inputFolder=fullfile(root,'inputs'); end
if nargin<2 || isempty(outputFolder), outputFolder=fullfile(root,'outputs'); end
if nargin<3 || isempty(cfg), cfg=turning_parameter_figure_config; end
if ~isfolder(outputFolder), mkdir(outputFolder); end
platforms=cfg.platforms; years=cfg.years;
windows=readtable(fullfile(inputFolder,'Windows.csv'),'TextType','string');
bootstrap=readtable(fullfile(inputFolder,'BootstrapDraws.csv'),'TextType','string');
processing=readtable(fullfile(inputFolder,'Preprocessing.csv'),'TextType','string');
models=readtable(fullfile(inputFolder,'Summary.csv'),'TextType','string');
windows.APE_pct=100*abs(windows.PredictedTotalTime_s-windows.ObservedTotalTime_s)./windows.ObservedTotalTime_s;
assert(max(abs(windows.APE_pct-abs(windows.TotalTimeError_pct)))<1e-8);
windows.OperationKey=string(windows.DateKey)+"_"+string(windows.OperationID);
[g,p,s,k]=findgroups(windows.Platform,windows.Scale_km,windows.OperationKey);
med=splitapply(@median,windows.APE_pct,g);
counts=splitapply(@numel,windows.APE_pct,g);
representatives=table(p,s,k,med,counts,'VariableNames', ...
    {'Platform','Scale_km','OperationKey','APE_pct','WindowSamples'});
representatives=representatives(representatives.Scale_km<=5,:);
fig=figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 cfg.size_cm],'PaperUnits','centimeters', ...
    'PaperSize',cfg.size_cm,'PaperPosition',[0 0 cfg.size_cm], ...
    'PaperPositionMode','manual');
set(fig,'DefaultAxesFontName',cfg.font,'DefaultTextFontName',cfg.font);
stats=table;
for ip=1:2
    ax=axes(fig,'Units','centimeters','Position',cfg.left_axes_cm(ip,:)); hold(ax,'on');
    col=cfg.colors(ip,:); pale=.44+.56*col; fill=.88+.12*col;
    for scale=1:5
        r=representatives(representatives.Platform==platforms(ip)&representatives.Scale_km==scale,:);
        v=r.APE_pct; q=prctile(v,[25 50 75]); iqr=q(3)-q(1);
        whLo=min(v(v>=q(1)-1.5*iqr)); whHi=max(v(v<=q(3)+1.5*iqr));
        half=cfg.box_width/2;
        plot(ax,[scale scale],[whLo whHi],'-','Color',pale,'LineWidth',.7);
        patch(ax,scale+half*[-1 1 1 -1],q([1 1 3 3]),fill, ...
            'EdgeColor',pale,'LineWidth',.8);
        plot(ax,scale+half*[-1 1],[q(2) q(2)],'-','Color',col,'LineWidth',1);
        for y=[whLo whHi]
            plot(ax,scale+.12*[-1 1],[y y],'-','Color',pale,'LineWidth',.7);
        end
        total=sum(r.WindowSamples);
        assert(total==sum(windows.Platform==platforms(ip)&windows.Scale_km==scale));
        % Keep each count close to its own whisker, inside the plot frame.
        labelY=whHi+cfg.count_gap_cm/cfg.left_axes_cm(ip,4)*cfg.y_limits(ip);
        labelHeight=.36/cfg.left_axes_cm(ip,4)*cfg.y_limits(ip);
        if labelY+labelHeight<cfg.y_limits(ip)
            labelX=scale;align='center';valign='bottom';
        else
            labelX=scale+.20;labelY=cfg.y_limits(ip)*.94;
            align='left';valign='top';
        end
        text(ax,labelX,labelY,sprintf('\\itn\\rm=%d',total),'FontSize',cfg.count_font, ...
            'Color',[.20 .20 .20],'VerticalAlignment',valign, ...
            'HorizontalAlignment',align,'Clipping','off','Tag','sample_count');
        row=table(years(ip),scale,height(r),total,q(1),q(2),q(3),iqr, ...
            min(v),max(v),cfg.y_limits(ip),sum(v>cfg.y_limits(ip)),whLo,whHi, ...
            'VariableNames',{'PlatformYear','Scale_km','OperationRepresentatives', ...
            'UnderlyingWindowCount','Q1_pct','Median_pct','Q3_pct','IQR_pct', ...
            'Min_pct','Max_pct','AxisMaximum_pct','RepresentativesAboveAxisMaximum', ...
            'WhiskerLow_pct','WhiskerHigh_pct'});
        stats=[stats;row]; %#ok<AGROW>
    end
    style_axes(ax,cfg); xlim(ax,[.5 5.5]); ylim(ax,[0 cfg.y_limits(ip)]);
    ax.XTick=1:5;
    ax.YTick=unique([0:5:cfg.y_limits(ip),cfg.y_limits(ip)]);
    ylabel(ax,'Error (%)','FontSize',cfg.label_font);
    if ip==2, xlabel(ax,'Length (km)','FontSize',cfg.label_font); end
    text(ax,0,1+cfg.title_gap_cm/cfg.left_axes_cm(ip,4),sprintf('Platform %d',years(ip)), ...
        'Units','normalized','FontSize',cfg.panel_font,'FontWeight','normal','Color','k', ...
        'HorizontalAlignment','left','VerticalAlignment','bottom','Clipping','off');
    aligned_panel_letter(fig,ax,sprintf('(%c)','a'+ip-1),cfg);
end


labels={'Heading length','Block length','Low-angle fraction','Baseline half-window'};
fields={'HeadingBaseline_m','BlockLength_m','LowAngleFraction','BaselineHalfWindow_m'};
lowNames=["HeadingBaseline10m","BlockLength10m","LowAngle30pct","BaselineWindow500m"];
highNames=["HeadingBaseline40m","BlockLength40m","LowAngle50pct","BaselineWindow1500m"];
xMin=floor(min([bootstrap.Coefficient_m_per_rad;processing.Coefficient_m_per_rad])/5)*5;
xMax=ceil(max([bootstrap.Coefficient_m_per_rad;processing.Coefficient_m_per_rad])/5)*5;
% Compute the histogram from all draws, then crop the displayed coefficient axis.
edges=xMin:cfg.bin_width:xMax; centers=(edges(1:end-1)+edges(2:end))/2;
freq=zeros(2,numel(centers));
for ip=1:2
    b=bootstrap.Coefficient_m_per_rad(bootstrap.Platform==platforms(ip));
    freq(ip,:)=100*histcounts(b,edges)/numel(b);
    assert(abs(sum(freq(ip,:))-100)<1e-8);
end
coeffAx=axes(fig,'Units','centimeters','Position',cfg.coefficient_axes_cm); hold(coeffAx,'on');
for ip=1:2
    model=models(models.Platform==platforms(ip),:);
    patch(coeffAx,[model.BootstrapP025 model.BootstrapP975 model.BootstrapP975 model.BootstrapP025], ...
        [0 0 cfg.frequency_ylim(2) cfg.frequency_ylim(2)],[.94 .94 .94],'EdgeColor','none');
end
for ip=1:2
    col=cfg.colors(ip,:);
    bar(coeffAx,centers,freq(ip,:),1,'FaceColor',.76+.24*col, ...
        'EdgeColor',col,'LineWidth',.45);
end
style_axes(coeffAx,cfg);
xlim(coeffAx,cfg.coefficient_xlim); ylim(coeffAx,cfg.frequency_ylim);
coeffAx.XTick=cfg.coefficient_xticks; coeffAx.YTick=cfg.frequency_yticks;
ylabel(coeffAx,'Frequency (%)','FontSize',cfg.label_font);
xlabel(coeffAx,'Turning coefficient, \itc_{v}\rm (m/rad)','FontSize',cfg.label_font,'Interpreter','tex');
aligned_panel_letter(fig,coeffAx,'(c)',cfg);
rangeHeights=cfg.range_heights;
sensitivity=table;
for ip=1:2
    col=cfg.colors(ip,:);
    base=processing(processing.Platform==platforms(ip)&processing.Variant=="Baseline",:);
    model=models(models.Platform==platforms(ip),:);
    assert(height(base)==1 && height(model)==1);
    cv=model.Coefficient_m_per_rad;
    assert(abs(cv-base.Coefficient_m_per_rad)<1e-8);
    plot(coeffAx,[cv cv],cfg.frequency_ylim,'--','Color',.25+.75*col,'LineWidth',.65);
    % Preserve a visible final dash against the upper frame after clipping.
    plot(coeffAx,[cv cv],[cfg.frequency_ylim(2)-.40 cfg.frequency_ylim(2)], ...
        '-','Color',.25+.75*col,'LineWidth',.65);
    for j=1:4
        low=processing(processing.Platform==platforms(ip)&processing.Variant==lowNames(j),:);
        high=processing(processing.Platform==platforms(ip)&processing.Variant==highNames(j),:);
        assert(height(low)==1 && height(high)==1);
        lo=low.Coefficient_m_per_rad; hi=high.Coefficient_m_per_rad;
        yy=rangeHeights(j);
        plot(coeffAx,[lo hi],[yy yy],'-','Color',col,'LineWidth',.9);
        plot(coeffAx,lo,yy,'o','MarkerSize',3.2,'MarkerFaceColor',col, ...
            'MarkerEdgeColor',col,'LineWidth',.8);
        plot(coeffAx,[hi hi],yy+[-.85 .85],'-','Color',col,'LineWidth',1);
        multiplier=1; unit="m";
        if j==3, multiplier=100; unit="%"; end
        row=table(years(ip),string(labels{j}),multiplier*low.(fields{j}), ...
            multiplier*base.(fields{j}),multiplier*high.(fields{j}),unit,lo,cv,hi, ...
            low.RelativeCoefficientChange_pct,high.RelativeCoefficientChange_pct, ...
            'VariableNames',{'PlatformYear','Parameter','LowInput','DefaultInput', ...
            'HighInput','InputUnit','LowInputCoefficient','DefaultCoefficient', ...
            'HighInputCoefficient','LowInputCoefficientChange_pct','HighInputCoefficientChange_pct'});
        sensitivity=[sensitivity;row]; %#ok<AGROW>
        if ip==1
            text(coeffAx,cfg.parameter_label_x,yy,labels{j}, ...
                'FontSize',cfg.parameter_font,'HorizontalAlignment','center', ...
                'VerticalAlignment','middle','Clipping','off');
            parameter_key(coeffAx,cfg.parameter_label_x,yy-cfg.parameter_value_offset, ...
                [row.LowInput row.DefaultInput row.HighInput],row.InputUnit,cfg);
        end
    end
end
% One shared CI annotation in the whitespace between the shaded intervals.
leftModel=models(models.Platform==platforms(1),:);
rightModel=models(models.Platform==platforms(2),:);
labelX=(leftModel.BootstrapP975+rightModel.BootstrapP025)/2;
ciText=text(coeffAx,labelX,21,{'95% confidence','interval'}, ...
    'FontSize',cfg.parameter_font,'Color','k','HorizontalAlignment','center', ...
    'VerticalAlignment','middle','Interpreter','none');
drawnow;
ext=ciText.Extent;
assert(ext(1)>leftModel.BootstrapP975 && ext(1)+ext(3)<rightModel.BootstrapP025);
% Two short leaders identify the left and right shaded confidence intervals.
leaderStarts=[ext(1)-.4 21;ext(1)+ext(3)+.4 21];
leaderEnds=[leftModel.BootstrapP975-.7 17;rightModel.BootstrapP025+1.7 17];
for j=1:2
    xy=[leaderStarts(j,:);leaderEnds(j,:)];
    xx=(cfg.coefficient_axes_cm(1)+(xy(:,1)-cfg.coefficient_xlim(1))/diff(cfg.coefficient_xlim)*cfg.coefficient_axes_cm(3))/cfg.size_cm(1);
    yy=(cfg.coefficient_axes_cm(2)+(xy(:,2)-cfg.frequency_ylim(1))/diff(cfg.frequency_ylim)*cfg.coefficient_axes_cm(4))/cfg.size_cm(2);
    annotation(fig,'arrow',xx',yy','Color',[.25 .25 .25], ...
        'LineWidth',.65,'HeadLength',4,'HeadWidth',4);
end
text(coeffAx,17.8,29.5,'2023','FontSize',cfg.panel_font,'FontWeight','normal', ...
    'Color','k','HorizontalAlignment','left','VerticalAlignment','middle');
text(coeffAx,56.2,11.5,'2020','FontSize',cfg.panel_font,'FontWeight','normal', ...
    'Color','k','HorizontalAlignment','left','VerticalAlignment','middle');

drawnow;
name=cfg.output_name;

export_ijsr_pdf(fig,fullfile(outputFolder,[name '.pdf']));
close(fig);
writetable(stats,fullfile(outputFolder,'duration_error_boxplot_summary.csv'));
writetable(representatives,fullfile(outputFolder,'operation_representatives.csv'));
writetable(sensitivity,fullfile(outputFolder,'parameter_sensitivity.csv'));
writetable(table(edges(1:end-1)',edges(2:end)',freq(1,:)',freq(2,:)', ...
    'VariableNames',{'BinLeft_m_per_rad','BinRight_m_per_rad','Frequency2023_pct','Frequency2020_pct'}), ...
    fullfile(outputFolder,'bootstrap_histogram.csv'));
fprintf('Approved turning-parameter figure and its statistics saved to %s\n',outputFolder);
end

function parameter_key(ax,center,y,values,unit,cfg)
% Each row carries its own symbol/value key; all units and values are archived.
strings={sprintf('%g',values(1)),sprintf('%g',values(2)),sprintf('%g %s',values(3),unit)};
handles=gobjects(1,3); widths=zeros(1,3);
for j=1:3
    handles(j)=text(ax,center,y,strings{j},'FontName',cfg.font,'FontSize',cfg.key_font, ...
        'Color',[.30 .30 .30],'HorizontalAlignment','left','VerticalAlignment','middle');
end
drawnow;
for j=1:3, extent=handles(j).Extent; widths(j)=extent(3); end
glyphWidth=1.3; innerGap=.35; groupGap=.8;
cursor=center-(sum(widths)+3*(glyphWidth+innerGap)+2*groupGap)/2;
for j=1:3
    x=cursor+glyphWidth/2;
    if j==1
        plot(ax,x,y,'ko','MarkerSize',2.9,'MarkerFaceColor','k','LineWidth',.6);
    elseif j==2
        plot(ax,x+[-.60 -.20],[y y],'k-','LineWidth',.7);
        plot(ax,x+[.20 .60],[y y],'k-','LineWidth',.7);
    else
        plot(ax,[x x],y+[-.92 .92],'k-','LineWidth',.8);
    end
    handles(j).Position=[cursor+glyphWidth+innerGap,y,0];
    cursor=cursor+glyphWidth+innerGap+widths(j)+groupGap;
end
end

function style_axes(ax,cfg)
set(ax,'FontName',cfg.font,'FontSize',cfg.tick_font,'LineWidth',cfg.line_width, ...
    'TickDir','in','TickLength',[.012 .012],'XColor','k','YColor','k', ...
    'XMinorTick','off','YMinorTick','off','XGrid','off','YGrid','off', ...
    'XMinorGrid','off','YMinorGrid','off','Layer','top');
box(ax,'on');
end

function aligned_panel_letter(fig,ax,letter,cfg)
% Align the panel-letter left edge with the vertical axis-label left edge.
drawnow;
pos=ax.Position;yl=ax.YLabel;oldUnits=yl.Units;yl.Units='centimeters';
extent=yl.Extent;x=pos(1)+extent(1);yl.Units=oldUnits;
y=pos(2)+pos(4)+cfg.title_gap_cm;
annotation(fig,'textbox',[x y .75 .42]./[cfg.size_cm cfg.size_cm], ...
    'String',letter,'FontName',cfg.font,'FontSize',cfg.panel_font,'FontWeight','normal', ...
    'LineStyle','none','Margin',0,'FitBoxToText','off','VerticalAlignment','bottom');
end
