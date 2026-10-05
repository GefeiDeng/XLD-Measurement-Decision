"""Normalize exportgraphics canvas round-off, preserving vectors and font sizes."""
from pathlib import Path
import sys
from pypdf import PdfReader, PdfWriter, Transformation
from pypdf.generic import RectangleObject, ContentStream, FloatObject

path=Path(sys.argv[1]); width,height=(float(s)*72/2.54 for s in sys.argv[2:4])
w=PdfWriter(clone_from=path); assert len(w.pages)==1
p=w.pages[0]; dx=(width-float(p.mediabox.width))/2;dy=(height-float(p.mediabox.height))/2
assert abs(dx)<1 and abs(dy)<1,(dx,dy,'Unexpected export cropping')
# MATLAB's TeX renderer reduces superscript/subscript fonts automatically.
# The current manuscript style explicitly uses 9 pt for every glyph.
# Replace those smaller Tf sizes while retaining symbol position and baseline.
def uniform_fonts(stream):
    scale=1.0;stack=[];font=None;tm_scale=1.0;operations=[]
    for operands,operator in stream.operations:
        if operator==b'q':stack.append((scale,font,tm_scale))
        elif operator==b'Q':scale,font,tm_scale=stack.pop()
        elif operator==b'cm':
            a,b,c,d=map(float,operands[:4]);scale*=abs(a*d-b*c)**.5
        elif operator==b'Tf':
            font=operands[0]
        elif operator==b'Tm':
            a,b,c,d=map(float,operands[:4]);tm_scale=abs(a*d-b*c)**.5
        elif operator==b'BT':tm_scale=1.0
        if operator in (b'Tj',b'TJ',b"'",b'"'):
            assert font is not None,'Text without a selected font'
            # Font selection often precedes a separate transformed q/cm block.
            # Apply the physical size at the glyph-drawing operation instead.
            operations.append(([font,FloatObject(9/(scale*tm_scale))],b'Tf'))
        operations.append((operands,operator))
    stream.operations=operations
    return stream
content=uniform_fonts(ContentStream(p.get_contents(),w));p.replace_contents(content)
def normalize_forms(resources):
    for ref in resources.get('/XObject',{}).values():
        obj=ref.get_object()
        if obj.get('/Subtype')=='/Form':
            obj.set_data(uniform_fonts(ContentStream(obj,w)).get_data())
            if '/Resources' in obj:normalize_forms(obj['/Resources'])
normalize_forms(p['/Resources'])
p.add_transformation(Transformation().translate(dx,dy))
for key in ('mediabox','cropbox','trimbox','bleedbox','artbox'):
    setattr(p,key,RectangleObject([0,0,width,height]))
w.add_metadata({'/Title':path.stem,'/Creator':'MATLAB vector export; exact IJSR canvas'})
temporary=path.with_suffix('.normalized.tmp'); w.write(temporary);temporary.replace(path)
