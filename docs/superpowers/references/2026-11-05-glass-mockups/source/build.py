#!/usr/bin/env python3
"""Single source of truth for the Liquid Glass design canvas.
   python3 build.py [outdir]   (default: ../allscreens/project)
Reads screens/<Name>.html (colour-token body templates) + kit2.css + kit2.svg.html and writes
<Name>.dc.html (light) and <Name>Dark.dc.html (dark) for every screen."""
import os,re,sys,glob
D=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.abspath(sys.argv[1]) if len(sys.argv)>1 else (os.path.join(D,'..','allscreens','project') if os.path.isdir(os.path.join(D,'..','allscreens','project')) else os.path.abspath(os.path.join(D,'..')))
rd=lambda p:open(os.path.join(D,p),encoding='utf-8').read()
KIT=rd('kit2.css'); SVG=rd('kit2.svg.html').strip()
WARM_PHONE='<div aria-hidden="true" style="position:absolute;inset:0;background:radial-gradient(85% 42% at 100% 0%,rgba(255,170,95,.34),rgba(255,170,95,0) 70%),linear-gradient(180deg,#232427,#18191C)"></div>'
WARM_DESK='<div aria-hidden="true" style="position:absolute;inset:0;background:radial-gradient(60% 55% at 100% 0%,rgba(255,170,95,.30),rgba(255,170,95,0) 70%),linear-gradient(180deg,#232427,#18191C)"></div>'
BARS=[('#2FB8A8','#17897C',.55),('#5A63C8','#3A43A3',.85),('#F6B26B','#E08E2B',.4),('#E8606E','#C8324B',.7),('#2F6FDB','#1F4FA8',.95),('#2FB8A8','#17897C',.6),('#8E6BD9','#6B4BC0',.8),('#F6B26B','#E08E2B',.5),('#5A63C8','#3A43A3',.65),('#E8606E','#C8324B',.9),('#2FB8A8','#17897C',.45),('#2F6FDB','#1F4FA8',.75)]
def under(kind,dark):
    """Real coloured content (chart bars + colour blobs) that sits UNDER the glass bars/sheets."""
    h=96 if kind=='phone' else 0
    n=7 if kind=='phone' else 0
    bars=''.join('<span style="flex:1;height:%dpx;border-radius:10px 10px 0 0;background:linear-gradient(180deg,%s,%s)"></span>'%(int(h*f*(1 if i%2 else .92)),a,b) for i,(a,b,f) in enumerate(BARS[:n]))
    blob=''
    if kind=='mac':
        blob='<span style="position:absolute;top:-40px;left:-40px;width:420px;height:200px;border-radius:50%%;background:radial-gradient(closest-side,rgba(47,184,168,%s),rgba(47,184,168,0))"></span><span style="position:absolute;top:-30px;left:34%%;width:380px;height:170px;border-radius:50%%;background:radial-gradient(closest-side,rgba(246,178,107,%s),rgba(246,178,107,0))"></span>'%(('.30' if dark else '.38'),('.22' if dark else '.34'))
        blob=blob.replace('%%','%')
    else:
        blob=''
    r='inherit'
    return ('<div aria-hidden="true" style="position:absolute;inset:0;overflow:hidden;border-radius:%s;pointer-events:none">%s'
            '<div style="position:absolute;left:0;right:0;bottom:0;display:flex;align-items:flex-end;gap:%dpx;padding:0 %dpx;height:%dpx">%s</div></div>')%(r,blob,8 if kind=='phone' else 14,14 if kind=='phone' else 24,h,bars)
SKEL='''<!doctype html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<title>@TITLE@</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300..900&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
@ROOTBG@
.orb{position:absolute;border-radius:50%}
@CSS@
@KIT@
</style>
</helmet>
@BODY@
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":@W@,"height":@H@}}'>
class Component extends DCLogic {
  renderVals() {
    return {};
  }
}
</script>
</body>
</html>
'''
def make(name,dark):
    t=rd('screens/%s.html'%name)
    title=re.search(r'<!--@title (.*?)-->',t).group(1); kind=re.search(r'<!--@kind (\w+)-->',t).group(1)
    css=re.search(r'<style>\n(.*?)\n</style>',t,flags=re.S).group(1)
    body=t.split('</style>\n',1)[1].strip('\n')
    title=re.sub(r' dark$','',title)+(' dark' if dark else '')
    body=body.replace('<!--@SVG-->',SVG)
    body=re.sub(r'--lg-tint: ?(rgba\([^)]*\))',lambda m:'background: linear-gradient(160deg,rgba(70,84,190,.9),%s)'%m.group(1),body)
    fx=(WARM_PHONE if (dark and kind=='phone') else WARM_DESK if kind=='mac' else '')
    # underlay: phone = first child of root; mac = first child of the window
    u=under(kind,dark)
    if kind=='phone':
        body=body.replace('<!--@BGFX-->',fx+'\n  '+u,1)
    else:
        body=body.replace('<!--@BGFX-->',fx)
        body,n=re.subn(r'(<div style="position: relative; width: 100%; max-width: 1320px[^>]*>)',lambda m:m.group(1)+'\n    '+u,body,count=1)
        assert n==1,name
    if dark:
        body,n=re.subn(r'^<div([ >])',r'<div data-theme="dark"\1',body.lstrip(),count=1); assert n==1,name
        body=body.replace('<div data-theme="dark" dir="rtl"','<div data-theme="dark" dir="rtl"',1)
    rootbg='.desk,.bg-root{background:#1B1C20}' if kind=='mac' else '.desk,.bg-root{background:var(--bg)}'
    w,h=(1440,900) if kind=='mac' else (390,844)
    out=SKEL.replace('@TITLE@',title).replace('@ROOTBG@',rootbg).replace('@CSS@',css).replace('@KIT@',KIT.strip()).replace('@BODY@',body).replace('@W@',str(w)).replace('@H@',str(h))
    assert 'style="{{' not in out and 'data:' not in out.replace('data-','')
    return out
if __name__=='__main__':
    names=sorted(os.path.basename(p)[:-5] for p in glob.glob(D+'/screens/*.html'))
    for n in names:
        for dark in (False,True):
            fn=n+('Dark' if dark else '')+'.dc.html'
            open(os.path.join(OUT,fn),'w',encoding='utf-8').write(make(n,dark)); print(fn)
