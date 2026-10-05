function export_ijsr_pdf(fig,file)
%EXPORT_IJSR_PDF Embedded vector fonts at the figure's exact physical size.
% A white canvas-edge anchor prevents exportgraphics from cropping the page.
% Python only normalizes round-off in the PDF box; it never rescales content.
fig.PaperUnits='centimeters'; sz=fig.PaperSize;
assert(any(abs(sz(1)-[8 16])<1e-8),'Select an 8 or 16 cm canvas.');
assert(sz(2)<24,'Figure height must be less than 24 cm.');
axesObjects=findall(fig,'Type','axes');
for k=1:numel(axesObjects)
    axesObjects(k).FontSize=9;
    axesObjects(k).LabelFontSizeMultiplier=1;
    axesObjects(k).TitleFontSizeMultiplier=1;
end
objects=findall(fig,'-property','FontName');
for k=1:numel(objects)
    objects(k).FontName='Times New Roman';
    if isprop(objects(k),'FontWeight'),objects(k).FontWeight='normal';end
    if isprop(objects(k),'FontSize') && ~isa(objects(k),'matlab.graphics.axis.Axes')
        objects(k).FontSize=9;
    end
end
anchor=annotation(fig,'rectangle',[0 0 1 1],'Color','white','LineWidth',.01);
cleanup=onCleanup(@()delete(anchor)); %#ok<NASGU>
drawnow;
exportgraphics(fig,file,'ContentType','vector','BackgroundColor','white');
python=getenv('IJSR_PYTHON');
if isempty(python)
    python='python';
end
helper=fullfile(fileparts(mfilename('fullpath')),'normalize_pdf_canvas.py');
cmd=sprintf('"%s" "%s" "%s" %.10f %.10f',python,helper,file,sz(1),sz(2));
[status,result]=system(cmd);
assert(status==0,'PDF canvas normalization failed: %s',result);
end
