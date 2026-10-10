"""Create original 16px platformer tiles and transparent game objects."""
import json, random, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
D='293044';SOIL='83533f';MID='aa7147';LIGHT='d19a62';GRASS='63aa68';HI='a4d47a'
items=[]
class Tile:
 def __init__(self,c=None):self.p=[0 if c is None else 0xff000000|int(c,16)]*256
 def rect(self,x,y,w,h,c):
  for yy in range(y,y+h):
   for xx in range(x,x+w):
    if 0<=xx<16 and 0<=yy<16:self.p[yy*16+xx]=0xff000000|int(c,16)
 def dot(self,x,y,c):self.rect(x,y,1,1,c)
 def save(self,id,name,category='Background'):
  f='steampunk_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
def dirt(seed=1):
 t=Tile(SOIL);r=random.Random(seed)
 for i in range(24):t.rect(r.randrange(1,15),r.randrange(1,15),2 if i%3==0 else 1,1,MID if i%2 else '674334')
 return t
BRASS='be955b';GOLD='e8c88c';IRON='596a78';SHINE='96a6ad';RUST='a7674e'
def plate():
 t=Tile(D);t.rect(1,1,14,14,IRON);t.rect(1,1,14,1,SHINE);t.rect(1,2,1,12,'748895');t.rect(2,13,12,1,'3c4a5f')
 for x,y in [(3,3),(12,3),(3,12),(12,12)]:t.dot(x,y,GOLD)
 return t
plate().save('iron_plate','Riveted Iron Plate')
t=plate();t.rect(4,5,7,1,RUST);t.rect(6,6,4,2,RUST);t.rect(9,10,3,2,RUST);t.save('rust_plate','Rusty Iron Plate')
t=Tile(D);t.rect(1,1,14,14,'896d4e');t.rect(1,1,14,1,GOLD);t.rect(1,2,1,12,BRASS)
for x,y in [(3,3),(12,3),(3,12),(12,12)]:t.dot(x,y,GOLD)
t.save('brass_plate','Brass Panel')
t=plate();t.rect(4,4,8,8,D)
for x in [5,8,11]:t.rect(x,4,1,8,SHINE)
t.save('vent_plate','Vent Panel')
for side in ['top','left','right','nw','ne','bottom']:
 t=plate()
 if side in ['top','nw','ne']:t.rect(0,0,16,4,D);t.rect(0,0,16,1,GOLD);t.rect(0,1,16,2,BRASS)
 if side in ['left','nw']:t.rect(0,0,2,16,BRASS);t.rect(0,0,1,16,GOLD)
 if side in ['right','ne']:t.rect(14,0,2,16,BRASS);t.rect(15,0,1,16,'6d513c')
 if side=='bottom':t.rect(0,13,16,3,D);t.rect(0,13,16,1,BRASS)
 t.save('terrain_'+side,'Industrial Ground '+side.upper())
for side in ['left','middle','right']:
 t=Tile();t.rect(0,4,16,6,D);t.rect(0,4,16,1,GOLD);t.rect(0,5,16,3,BRASS);t.rect(0,8,16,1,'6d513c');t.dot(3,6,GOLD);t.dot(12,6,GOLD)
 if side=='left':t.rect(0,5,1,4,D)
 if side=='right':t.rect(15,5,1,4,D)
 t.save('platform_'+side,'Brass Platform '+side.title())
for id,name,dirs in [('pipe_h','Copper Pipe Horizontal','ew'),('pipe_v','Copper Pipe Vertical','ns'),('pipe_ne','Copper Pipe Elbow','ne'),('pipe_cross','Copper Pipe Junction','nesw')]:
 t=Tile();t.rect(5,5,6,6,D)
 for d in dirs:
  if d=='n':t.rect(5,0,6,8,D);t.rect(6,0,4,8,RUST);t.rect(6,0,1,8,GOLD)
  if d=='s':t.rect(5,8,6,8,D);t.rect(6,8,4,8,RUST);t.rect(6,8,1,8,GOLD)
  if d=='e':t.rect(8,5,8,6,D);t.rect(8,6,8,4,RUST);t.rect(8,6,8,1,GOLD)
  if d=='w':t.rect(0,5,8,6,D);t.rect(0,6,8,4,RUST);t.rect(0,6,8,1,GOLD)
 t.rect(6,6,4,4,RUST);t.dot(6,6,GOLD);t.save(id,name)
t=Tile();t.rect(3,0,2,16,IRON);t.rect(11,0,2,16,IRON);t.rect(3,0,1,16,SHINE)
for y in [2,7,12]:t.rect(5,y,6,2,BRASS);t.rect(5,y,6,1,GOLD)
t.save('ladder','Brass Ladder')
t=Tile();t.rect(4,4,8,8,D);t.rect(5,5,6,6,BRASS);t.rect(7,7,2,2,D)
for x,y,w,h in [(6,1,4,3),(6,12,4,3),(1,6,3,4),(12,6,3,4),(3,3,2,2),(11,11,2,2),(11,3,2,2),(3,11,2,2)]:t.rect(x,y,w,h,BRASS)
t.rect(5,5,5,1,GOLD);t.save('gear','Brass Gear','Object')
t=Tile();t.rect(3,5,10,9,D);t.rect(4,6,8,7,BRASS);t.rect(5,2,6,3,D);t.rect(6,3,4,2,SHINE);t.rect(6,8,4,3,'81c7c6');t.rect(7,8,1,2,'c5e6d9');t.dot(5,12,GOLD);t.dot(10,12,GOLD);t.save('boiler','Steam Boiler','Object')
t=Tile();t.rect(6,1,4,14,D);t.rect(7,2,2,12,BRASS);t.rect(2,3,12,2,IRON);t.rect(3,3,10,1,SHINE);t.rect(4,8,8,4,IRON);t.rect(5,8,6,1,SHINE);t.rect(3,14,10,2,D);t.save('piston','Steam Piston','Object')
t=Tile();t.rect(3,5,10,8,D);t.rect(4,6,8,6,IRON);t.rect(5,7,6,4,'8ab9bb');t.rect(6,8,4,2,'d1e2d0');t.rect(8,7,1,3,RUST);t.rect(6,2,4,3,BRASS);t.rect(7,2,2,1,GOLD);t.save('pressure_gauge','Pressure Gauge','Object')
t=Tile();t.rect(0,12,16,4,D);t.rect(1,12,14,1,BRASS)
for x in [1,6,11]:
 for y in range(5,12):t.rect(x+2-min(2,(y-5)//3),y,min(2,(y-5)//3)*2+1,1,SHINE)
t.save('spikes','Factory Spikes')
t=Tile();t.rect(0,6,16,6,D);t.rect(0,7,16,3,IRON)
for x in range(0,16,5):t.dot(x,7,GOLD);t.dot(x+1,8,GOLD);t.dot(x,9,GOLD)
t.save('conveyor','Factory Conveyor')
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 t=json.loads(ROOT.joinpath(f).read_text());assert t['width']==t['height']==16 and len(p)==256 and all(0<=c<=0xffffffff for c in p)
ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n');assert len(index)==len(set(index))
cols=7;rows=(len(items)+cols-1)//cols;w=cols*96;h=rows*96;raw=bytearray()
for y in range(h):
 raw.append(0)
 for x in range(w):
  n=y//96*cols+x//96;c=items[n][1][(y%96//6)*16+x%96//6] if n<len(items) else 0
  c=c or (0xffe5e6ee if (x//12+y//12)%2 else 0xffd7dae5)
  raw.extend([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
Path('/private/tmp/picell-steampunk.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
