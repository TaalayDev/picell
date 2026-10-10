"""Generate detailed, native-resolution 36×36 botanical steampunk tiles."""
import json, struct, zlib, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
D='293044'; I='596a78'; S='96a6ad'; B='be955b'; G='e8c88c'; R='a7674e'; W='634d43'; L='62896c'; H='91af70'
items=[]
class Tile:
 def __init__(self,c=None):self.p=[0 if c is None else 0xff000000|int(c,16)]*1296
 def rect(self,x,y,w,h,c):
  for yy in range(max(0,y),min(36,y+h)):
   for xx in range(max(0,x),min(36,x+w)):self.p[yy*36+xx]=0xff000000|int(c,16)
 def circle(self,x,y,r,c):
  for yy in range(y-r,y+r+1):
   for xx in range(x-r,x+r+1):
    if (xx-x)**2+(yy-y)**2<=r*r:self.rect(xx,yy,1,1,c)
 def save(self,id,name,cat='Background'):
  f='steampunk_'+id+'_36.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 36×36',category=cat,is_pro=False,width=36,height=36,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
def rivet(t,x,y):
 t.circle(x,y,2,D);t.circle(x,y,1,B);t.rect(x,y-1,1,1,G)
def panel():
 t=Tile(D);t.rect(1,1,34,34,I);t.rect(1,1,34,1,S);t.rect(1,2,1,32,S);t.rect(3,32,29,2,'3c4a5f')
 for x,y in [(4,4),(31,4),(4,31),(31,31)]:rivet(t,x,y)
 return t
for id,name in [('iron_panel','Forged Iron Panel'),('brass_panel','Engraved Brass Panel'),('vent_panel','Ornate Vent Panel'),('root_panel','Root Wrapped Panel')]:
 t=panel()
 if id=='brass_panel':
  t.rect(7,7,22,22,B);t.rect(8,8,20,1,G);t.rect(10,11,16,1,R);t.rect(10,24,16,1,R);t.circle(18,18,5,R);t.circle(18,18,3,G)
 if id=='vent_panel':
  t.rect(8,7,20,22,D)
  for x in range(10,28,4):t.rect(x,9,2,18,S);t.rect(x+1,9,1,18,I)
 if id=='root_panel':
  t.rect(9,0,3,36,R);t.rect(11,15,16,2,R);t.rect(25,15,2,21,R)
  for x,y in [(5,6),(12,10),(20,16),(27,24)]:t.rect(x,y,6,3,L);t.rect(x,y,4,1,H)
 t.save(id,name)
for side in ['top','bottom','left','right','nw','ne','sw','se']:
 t=panel()
 if side in ['top','nw','ne']:t.rect(0,0,36,6,B);t.rect(0,0,36,1,G);t.rect(0,5,36,1,D)
 if side in ['bottom','sw','se']:t.rect(0,30,36,6,B);t.rect(0,30,36,1,G);t.rect(0,35,36,1,D)
 if side in ['left','nw','sw']:t.rect(0,0,6,36,B);t.rect(0,0,1,36,G)
 if side in ['right','ne','se']:t.rect(30,0,6,36,B);t.rect(35,0,1,36,D)
 t.save('terrain_'+side,'Ornate Industrial Terrain '+side.upper())
for id,dirs in [('pipe_h','ew'),('pipe_v','ns'),('pipe_elbow','ne'),('pipe_cross','nesw')]:
 t=Tile()
 for d in dirs:
  x,y,w,h={'n':(12,0,12,24),'s':(12,12,12,24),'e':(12,12,24,12),'w':(0,12,24,12)}[d]
  t.rect(x,y,w,h,D);t.rect(x+1,y+1,w-2,h-2,R)
  if d in 'ns':t.rect(x+2,y,2,h,G);t.rect(x+8,y,2,h,'794e42');t.rect(x-2,3 if d=='n' else 28,16,4,B)
  else:t.rect(x,y+2,w,2,G);t.rect(x,y+8,w,2,'794e42');t.rect(3 if d=='w' else 28,y-2,4,16,B)
 t.circle(18,18,7,D);t.circle(18,18,6,B);t.circle(18,18,4,R);t.save(id,'Flanged Copper '+id.replace('pipe_','Pipe ').title())
t=Tile();t.circle(18,18,12,B)
for a in range(12):
 x=round(18+14*math.cos(a*math.pi/6));y=round(18+14*math.sin(a*math.pi/6));t.rect(x-2,y-2,5,5,B)
t.circle(18,18,10,G);t.circle(18,18,8,B);t.circle(18,18,5,D);t.circle(18,18,2,I);t.save('gear','Precision Brass Gear','Object')
t=Tile();t.rect(7,8,22,24,D);t.rect(8,9,20,22,B);t.rect(9,10,2,19,G);t.rect(11,2,14,7,D);t.rect(12,3,12,4,I);t.rect(13,3,10,1,S);t.circle(18,17,6,D);t.circle(18,17,5,'8cb7ae');t.circle(18,17,3,'d8cbb0');t.rect(18,14,1,4,R);t.rect(11,26,14,2,R)
for x in [10,25]:rivet(t,x,11);rivet(t,x,29)
t.rect(9,32,5,3,I);t.rect(22,32,5,3,I);t.save('boiler','Artisan Steam Boiler','Object')
t=Tile();t.circle(18,16,13,D);t.circle(18,16,12,B);t.circle(18,16,10,'d8cbb0')
for a in range(12):
 x=round(18+8*math.cos(a*math.pi/6));y=round(16+8*math.sin(a*math.pi/6));t.rect(x,y,1,2,D)
t.rect(18,9,1,8,D);t.rect(18,16,7,1,D);t.circle(18,16,1,R);t.rect(15,29,6,5,B);t.save('clock','Observatory Brass Clock','Object')
t=Tile();t.rect(4,25,28,7,D);t.rect(5,26,26,5,B);t.rect(8,32,4,3,W);t.rect(24,32,4,3,W);t.rect(17,4,3,21,L)
for x,y in [(7,10),(20,7),(6,18),(20,16)]:t.rect(x,y,10,4,L);t.rect(x+1,y,7,1,H)
t.circle(18,5,4,B);t.circle(18,5,2,G)
for x in [8,27]:rivet(t,x,28)
t.save('botanical_planter','Brass Conservatory Planter','Object')
t=Tile();t.rect(16,15,6,21,W);t.rect(17,16,2,18,R)
for x,y,r in [(10,12,8),(23,11,9),(17,6,6),(8,20,6),(27,20,6)]:t.circle(x,y,r,'354f4e');t.circle(x,y-1,r-1,L);t.rect(x-2,y-4,5,2,H)
t.rect(10,33,17,3,W);t.rect(8,35,5,1,B);t.rect(26,35,5,1,B);t.save('copper_tree','Copper Root Canopy','Object')
t=Tile();t.rect(5,30,26,5,D);t.rect(6,31,24,3,B);t.rect(7,10,22,20,'507b80');t.rect(7,10,2,19,'8cb7ae');t.rect(8,9,20,2,B)
for x in [5,28]:t.rect(x,9,3,22,B);t.rect(x,10,1,19,G)
for y in range(2,10):t.rect(18-(y-2)*2,y,(y-2)*4+1,1,B)
t.rect(17,15,2,15,L);t.rect(11,20,6,3,H);t.rect(19,17,5,3,L);t.rect(7,29,22,2,W);t.save('glasshouse','Victorian Botanical Glasshouse','Object')
t=Tile();t.rect(8,3,20,25,D);t.rect(9,4,18,23,I);t.rect(10,5,16,1,S);t.rect(12,8,12,13,D)
for x in range(13,24,3):t.rect(x,9,1,11,B)
t.rect(10,24,16,2,R);t.rect(6,28,24,4,B);t.rect(10,32,4,3,I);t.rect(22,32,4,3,I);t.circle(18,14,4,B);t.circle(18,14,2,D);t.save('garden_engine','Mechanical Garden Engine','Object')
t=Tile()
for x in [5,28]:t.rect(x,0,3,36,I);t.rect(x,0,1,36,S)
for y in range(3,36,8):t.rect(8,y,20,3,B);t.rect(8,y,20,1,G);rivet(t,10,y+1);rivet(t,25,y+1)
t.save('ladder','Riveted Conservatory Ladder')
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 data=json.loads(ROOT.joinpath(f).read_text());assert data['width']==data['height']==36 and len(p)==1296 and all(0<=c<=0xffffffff for c in p)
assert len(index)==len(set(index));ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n')
cols=6;cell=108;rows=(len(items)+cols-1)//cols;w=cols*cell;h=rows*cell;raw=bytearray()
for y in range(h):
 raw.append(0)
 for x in range(w):
  n=y//cell*cols+x//cell;c=items[n][1][(y%cell//3)*36+x%cell//3] if n<len(items) else 0
  c=c or (0xffe5e6ee if (x//12+y//12)%2 else 0xffd7dae5);raw.extend([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
Path('/private/tmp/picell-steampunk36.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'36×36 steampunk templates')
