#!/usr/bin/env python3
"""python3 shoot.py outdir Name... : plain-HTML copies of boards + headless chrome PNGs"""
import re,os,sys,subprocess
D=os.path.dirname(os.path.abspath(__file__)); P=os.path.join(D,'..') if os.path.exists(os.path.join(D,'..','Main.dc.html')) else os.path.join(D,'..','allscreens','project')
out=os.path.abspath(sys.argv[1]); os.makedirs(out,exist_ok=True)
for n in sys.argv[2:]:
    h=open(os.path.join(P,n+'.dc.html'),encoding='utf-8').read()
    h=h.replace('<script src="./support.js"></script>','').replace('<x-dc>','').replace('</x-dc>','').replace('<helmet>','').replace('</helmet>','')
    h=re.sub(r'<script type="text/x-dc".*?</script>','',h,flags=re.S)
    f=os.path.join(out,n+'.html'); open(f,'w',encoding='utf-8').write(h)
    sz='1440,900' if n.startswith('Mac') else '390,844'
    subprocess.run(['google-chrome','--headless=new','--no-sandbox','--hide-scrollbars','--virtual-time-budget=4000','--window-size='+sz,'--screenshot='+os.path.join(out,n+'.png'),'file://'+f],capture_output=True)
