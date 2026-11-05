import sys,os
from PIL import Image
out=sys.argv[1]; names=sys.argv[2:]
ims=[Image.open(os.path.join(os.path.dirname(out),n+'.png')).convert('RGB') for n in names]
w=ims[0].width; h=ims[0].height
sc=0.62 if w==390 else 0.5
ims=[i.resize((int(i.width*sc),int(i.height*sc))) for i in ims]
cols=4 if w==390 else 2
rows=(len(ims)+cols-1)//cols
W=ims[0].width;H=ims[0].height
sheet=Image.new('RGB',(cols*W+ (cols+1)*6,rows*H+(rows+1)*6),(128,128,128))
for k,i in enumerate(ims): sheet.paste(i,(6+(k%cols)*(W+6),6+(k//cols)*(H+6)))
sheet.save(out)
