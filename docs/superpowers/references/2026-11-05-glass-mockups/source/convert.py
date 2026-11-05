"""One-off seed: turn the first-generation light boards into colour-token templates (S/ds/screens/*.html).
Usage: python3 convert.py   (reads ../allscreens/project/<Name>.dc.html, writes screens/<Name>.html)"""
import re,os,glob
D=os.path.dirname(os.path.abspath(__file__)); SRC=os.path.join(D,'..','allscreens','project'); OUT=os.path.join(D,'screens')
os.makedirs(OUT,exist_ok=True)
HEX={'#1B2236':'--text','#38425E':'--text2','#39425E':'--text2','#2A3350':'--text2','#2B3556':'--text2','#3B4468':'--text2','#2C3550':'--text2b',
 '#5A6482':'--text3','#8A93B2':'--text3','#8F97B5':'--text3','#6F7896':'--chk-b','#1F5FD0':'--link','#1F4FA8':'--link-h','#2F6FDB':'--accent',
 '#0B857A':'--teal','#0A7A70':'--teal','#0B6F65':'--teal','#07665D':'--success',
 '#A86400':'--warn','#8F5400':'--warn','#7A4A00':'--warn','#8A5200':'--warn','#6B3F00':'--warn','#B35900':'--warn',
 '#B02440':'--danger','#A8212F':'--danger','#8E1B33':'--danger','#8F1C33':'--danger','#6B4BC0':'--purple'}
def conv(t,habits=False):
    k=t.index('/* ===== Liquid Glass kit'); j=t.index('</style>',k)
    t=t[:k]+t[j:]
    t=re.sub(r'<svg width="0".*?</svg>','<!--@SVG-->\n<!--@BGFX-->',t,flags=re.S)
    t=re.sub(r'<!-- BG:START -->.*?<!-- BG:END -->\n?','',t,flags=re.S)
    title=re.search(r'<title>(.*?)</title>',t).group(1)
    sty=re.search(r'<style>(.*?)</style>',t,flags=re.S).group(1)
    body=t.split('</helmet>',1)[1].split('</x-dc>')[0]
    # style cleanup: root backgrounds, orbs/bands are build-owned
    sty=re.sub(r'\.(bg-root|desk)\{background:[^}]*\}\n?','',sty)
    sty=re.sub(r'\.band\{[^}]*\}\n?','',sty)
    sty=re.sub(r'\.orb\{[^}]*\}\n?','',sty)
    sty=re.sub(r'(?m)^body\{margin:0\}\n?','',sty)
    sty=sty.replace('background:rgba(255,255,255,.4);margin:0','background:var(--chk-bg);margin:0')
    sty=sty.replace('.row:hover{background:rgba(255,255,255,.28)}','.row:hover{background:var(--hover)}').replace('.navi:hover{background:rgba(255,255,255,.35)}','.navi:hover{background:var(--hover2)}')
    sty=sty.replace('.chk:checked{background:#2F6FDB;border-color:#2F6FDB}','.chk:checked{background:var(--accent);border-color:var(--accent)}')
    sty=sty.replace('a:hover{color:#1F4FA8}','a:hover{color:var(--link-h)}')
    # root bg inline
    body=re.sub(r'background: #FFFFFF; font-family: Vazirmatn','background: var(--bg); font-family: Vazirmatn',body)
    body=re.sub(r'(background: )#FFFFFF(; box-shadow: 0 0 0 \.5px rgba\(255,255,255,\.28\))',r'\1var(--win)\2',body)
    if habits:
        body=body.replace(' lg-dark','')
    both=sty+'\n@@BODY@@\n'+body
    both=re.sub(r'rgba\(27,34,54,(\.\d+)\)',lambda m:'var(--ink-%s)'%m.group(1)[1:],both)
    both=both.replace('--ink-3)','--ink-3)')
    for h,v in HEX.items():
        both=re.sub(re.escape(h)+r'\b','var(%s)'%v,both,flags=re.I)
    sty,body=both.split('\n@@BODY@@\n')
    return title,sty.strip(),body.strip('\n')
def kind(n): return 'mac' if n.startswith('Mac') else 'phone'
if __name__=='__main__':
    for f in sorted(glob.glob(SRC+'/*.dc.html')):
        n=os.path.basename(f)[:-8]
        if n.startswith('Bg') or n.endswith('Dark'): continue
        t=open(f,encoding='utf-8').read()
        title,sty,body=conv(t,habits=(n=='PhoneHabits'))
        open(os.path.join(OUT,n+'.html'),'w',encoding='utf-8').write('<!--@title %s-->\n<!--@kind %s-->\n<style>\n%s\n</style>\n%s\n'%(title,kind(n),sty,body))
        print(n,len(body))
