"""Generate native 36×36 steampunk platformer tiles and objects."""
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
  f='steampunk_platformer_'+id+'_36.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 36×36',category=cat,is_pro=False,width=36,height=36,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
def rivet(t,x,y):
 t.circle(x,y,2,D);t.circle(x,y,1,B);t.rect(x,y-1,1,1,G)
def panel():
 t=Tile(D);t.rect(1,1,34,34,I);t.rect(1,1,34,1,S);t.rect(1,2,1,32,S);t.rect(3,32,29,2,'3c4a5f')
 for x,y in [(4,4),(31,4),(4,31),(31,31)]:rivet(t,x,y)
 return t

# Consistent six-pixel brass terrain edges across all adjoining tiles.
for side in ['fill','top','bottom','left','right','nw','ne','sw','se']:
 t=Tile(D);t.rect(1,1,34,34,I)
 for y in [5,17,29]:
  t.rect(1,y,34,1,'3c4a5f')
  for x in [5,17,29]:rivet(t,x,y+2)
 if side in ['top','nw','ne']:t.rect(0,0,36,6,B);t.rect(0,0,36,1,G);t.rect(0,5,36,1,D)
 if side in ['bottom','sw','se']:t.rect(0,30,36,6,B);t.rect(0,30,36,1,G);t.rect(0,35,36,1,D)
 if side in ['left','nw','sw']:t.rect(0,0,6,36,B);t.rect(0,0,1,36,G)
 if side in ['right','ne','se']:t.rect(30,0,6,36,B);t.rect(35,0,1,36,D)
 t.save('ground_'+side,'Foundry Ground '+side.upper())
for side in ['left','right']:
 t=Tile()
 for x in range(36):
  y=35-x if side=='right' else x;t.rect(x,y,1,36-y,I);t.rect(x,y,1,1,G);t.rect(x,y+1,1,3,B)
 for x,y in [(7,30),(18,30),(29,30)]:
  if t.p[y*36+x]:rivet(t,x,y)
 t.save('slope_'+side,'Brass Slope '+side.title())
for side in ['left','middle','right']:
 t=Tile();t.rect(0,8,36,14,D);t.rect(0,8,36,2,G);t.rect(0,10,36,6,B);t.rect(0,17,36,3,I)
 for x in [6,18,30]:rivet(t,x,13)
 if side=='left':t.rect(0,8,2,14,D);t.rect(2,10,2,10,R)
 if side=='right':t.rect(34,8,2,14,D);t.rect(32,10,2,10,R)
 t.save('platform_'+side,'Riveted Platform '+side.title())
t=Tile();t.rect(0,8,36,17,D);t.rect(0,9,36,7,I);t.rect(0,9,36,1,S)
for x in range(-8,36,12):
 for y in range(5):t.rect(x+y,11+y,5,1,B)
for x in [6,18,30]:t.circle(x,20,3,B);t.circle(x,20,1,D)
t.save('conveyor','Brass Foundry Conveyor')
t=Tile();t.rect(3,5,30,6,D);t.rect(4,6,28,3,B);t.rect(4,6,28,1,G);t.rect(6,29,24,6,D);t.rect(7,30,22,2,I)
for y in range(13,28,5):t.rect(11,y,14,2,G);t.rect(10 if y%2 else 24,y+2,2,3,B)
t.save('spring','Mechanical Spring Pad','Object')
t=Tile();t.rect(2,19,32,8,D);t.rect(3,20,30,3,B);t.rect(3,20,30,1,G)
for x in [6,27]:t.rect(x,0,3,19,I);t.rect(x,0,1,19,S);rivet(t,x+1,23)
t.rect(7,27,4,6,I);t.rect(25,27,4,6,I);t.save('lift','Chain Driven Lift','Object')
t=Tile();t.rect(0,29,36,7,D);t.rect(0,29,36,2,B)
for x in [1,13,25]:
 for y in range(9,29):
  w=1+(y-9)//2;t.rect(x+5-w//2,y,w,1,I);t.rect(x+5-w//2,y,1,1,S)
t.save('spikes','Retractable Foundry Spikes')
t=Tile()
for a in range(12):
 x=round(18+14*math.cos(a*math.pi/6));y=round(18+14*math.sin(a*math.pi/6));t.rect(x-2,y-2,5,5,S)
t.circle(18,18,13,D);t.circle(18,18,12,S);t.circle(18,18,9,I);t.circle(18,18,4,B);t.circle(18,18,2,D)
for x,y in [(12,12),(24,12),(12,24),(24,24)]:t.rect(x,y,2,2,S)
t.save('saw','Clockwork Saw','Object')
t=Tile();t.rect(5,24,26,12,D);t.rect(6,25,24,10,I);t.rect(9,22,18,4,B);t.rect(11,24,14,1,G)
for x,y,w,h in [(15,15,7,6),(11,9,11,5),(17,3,12,5),(10,0,9,2)]:t.rect(x,y,w,h,S);t.rect(x+1,y,w-2,1,'c3d2cb')
t.save('steam_vent','Steam Jet Hazard','Object')
t=Tile('ab5340')
for x,y in [(0,2),(13,5),(25,1),(4,14),(21,19),(2,28),(28,31)]:t.rect(x,y,9,2,'eea15b');t.rect(x+2,y,4,1,'ffe0a0')
t.save('molten_copper','Molten Copper Pool')
t=panel();t.rect(8,8,20,20,D);t.circle(18,18,8,B);t.circle(18,18,6,G);t.rect(17,12,2,8,D);t.rect(17,23,2,2,D);t.save('bonus_block','Clockwork Bonus Block')
t=Tile();t.rect(3,3,30,30,D);t.rect(4,4,28,28,W)
for x in [5,27]:t.rect(x,5,4,26,B);t.rect(x,5,1,26,G)
for y in [5,27]:t.rect(5,y,26,4,B)
for i in range(18):t.rect(9+i,9+i,2,2,R)
for x,y in [(7,7),(28,7),(7,28),(28,28)]:rivet(t,x,y)
t.save('crate','Brass Bound Cargo Crate','Object')
t=Tile();t.circle(18,18,12,D);t.circle(18,18,11,B);t.circle(18,18,8,G);t.circle(18,18,6,B);t.rect(16,12,4,12,G);t.rect(13,15,10,2,G);t.save('coin','Brass Gear Token','Object')
t=Tile();t.rect(6,2,3,32,I);t.rect(6,2,1,32,S);t.circle(7,3,2,B);t.rect(9,6,20,13,R);t.rect(10,7,17,1,'d69a6c');t.circle(18,12,4,B);t.circle(18,12,2,D);t.rect(3,33,12,3,D);t.save('checkpoint','Foundry Checkpoint Flag','Object')
t=Tile();t.rect(12,0,3,36,B);t.rect(12,0,1,36,G);t.rect(22,0,3,36,B);t.rect(22,0,1,36,G)
for y in range(2,36,8):t.rect(14,y,9,3,I);t.rect(14,y,9,1,S)
t.save('ladder','Foundry Ladder')
t=Tile();t.rect(4,4,28,29,D);t.rect(5,5,26,27,I);t.rect(8,7,20,24,W);t.rect(9,8,18,1,R);t.rect(9,20,18,2,B);t.circle(23,18,2,G);t.rect(12,10,12,7,D);t.rect(13,11,10,5,'8cb7ae');t.save('exit_door','Boiler Room Exit Door','Object')
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
Path('/private/tmp/picell-steampunk-platformer36.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'36×36 steampunk platformer templates')
