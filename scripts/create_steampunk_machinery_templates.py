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
def prop(id,name,rects):
 t=Tile()
 for x,y,w,h,c in rects:t.rect(x,y,w,h,c)
 t.save(id,name,'Object')
for side in ['left','middle','right']:
 t=Tile();t.rect(0,4,16,7,D);t.rect(0,4,16,1,SHINE);t.rect(0,5,16,4,IRON)
 for x in range(-2,16,6):
  for y in range(3):t.rect(x+y,6+y,3,1,GOLD)
 if side=='left':t.rect(0,4,1,7,D)
 if side=='right':t.rect(15,4,1,7,D)
 t.save('hazard_platform_'+side,'Hazard Platform '+side.title())
for side in ['left','right']:
 t=Tile()
 for x in range(16):
  y=x if side=='left' else 15-x;t.rect(x,y,1,16-y,IRON);t.dot(x,y,SHINE)
  if y+1<16:t.dot(x,y+1,BRASS)
 t.save('metal_slope_'+side,'Metal Slope '+side.title())
prop('lift','Mechanical Lift',[(1,8,14,5,D),(2,9,12,2,IRON),(2,9,12,1,SHINE),(3,4,2,4,BRASS),(11,4,2,4,BRASS),(3,13,2,2,D),(11,13,2,2,D)])
prop('spring','Brass Spring Pad',[(2,3,12,3,D),(3,3,10,2,BRASS),(3,12,10,3,D),(4,12,8,1,SHINE),(5,6,6,1,GOLD),(4,7,1,1,GOLD),(5,8,6,1,GOLD),(10,9,1,1,GOLD),(5,10,6,1,GOLD)])
prop('saw','Factory Saw Blade',[(5,2,6,12,D),(2,5,12,6,D),(4,4,8,8,SHINE),(6,5,4,6,IRON),(5,6,6,4,IRON),(7,7,2,2,BRASS),(7,0,2,3,SHINE),(7,13,2,3,SHINE),(0,7,3,2,SHINE),(13,7,3,2,SHINE)])
prop('electro_coil','Tesla Coil',[(3,13,10,3,D),(4,14,8,1,BRASS),(7,5,2,8,RUST),(5,7,6,1,GOLD),(5,10,6,1,GOLD),(5,3,6,3,IRON),(6,2,4,3,SHINE),(7,0,2,1,'a1dbdc')])
prop('steam_nozzle','Steam Jet Nozzle',[(3,11,10,5,D),(4,12,8,3,IRON),(6,9,4,3,BRASS),(7,5,2,4,'97bac0'),(5,2,5,3,'c1d5cd'),(8,0,3,2,'97bac0')])
prop('furnace','Factory Furnace',[(2,3,12,12,D),(3,4,10,10,IRON),(4,6,8,7,D),(5,8,6,4,'b74d3e'),(7,6,2,6,'efa14f'),(8,9,1,2,'ffe1a1'),(4,4,8,1,BRASS)])
prop('fan','Ventilation Fan',[(2,2,12,12,D),(3,3,10,10,IRON),(6,4,3,4,SHINE),(9,6,3,3,SHINE),(7,9,3,3,SHINE),(4,7,3,3,SHINE),(7,7,2,2,BRASS)])
prop('clock','Factory Clock',[(4,2,8,12,D),(2,4,12,8,D),(4,3,8,10,BRASS),(3,5,10,6,BRASS),(5,4,6,8,'e3d4ad'),(4,6,8,4,'e3d4ad'),(7,5,1,4,D),(7,8,4,1,D)])
prop('oil_drum','Oil Drum',[(4,2,8,12,D),(5,3,6,10,RUST),(3,5,10,2,IRON),(3,10,10,2,IRON),(5,3,2,1,GOLD),(7,7,2,2,D)])
prop('oil_can','Oil Can',[(4,7,8,7,D),(5,8,6,5,BRASS),(6,5,4,2,IRON),(2,6,3,5,IRON),(1,7,1,3,SHINE),(10,8,3,1,BRASS),(12,6,2,3,BRASS)])
prop('coal_pile','Coal Pile',[(2,10,12,5,D),(4,7,9,4,D),(6,5,5,3,D),(3,11,4,2,'485060'),(7,8,3,2,'5f6773'),(10,11,3,2,'485060')])
prop('copper_crate','Copper Cargo Crate',[(2,3,12,11,D),(3,4,10,9,RUST),(3,4,10,2,BRASS),(3,11,10,2,BRASS),(3,4,2,9,BRASS),(11,4,2,9,BRASS),(6,7,4,3,IRON),(7,8,2,1,SHINE)])
prop('steam_robot_head','Discarded Robot Head',[(3,4,10,9,D),(4,5,8,7,IRON),(5,6,6,3,D),(6,7,4,1,'81c7c6'),(7,2,2,3,BRASS),(2,7,2,3,BRASS),(12,7,2,3,BRASS)])
prop('copper_lamp','Copper Wall Lamp',[(2,6,4,2,IRON),(4,6,2,6,IRON),(6,3,8,10,D),(7,4,6,8,BRASS),(8,5,4,6,GOLD),(9,5,2,4,'fff1ae'),(7,3,6,1,SHINE)])
prop('wrench','Factory Wrench',[(3,2,2,5,SHINE),(7,2,2,5,SHINE),(4,6,4,2,SHINE),(6,7,2,4,IRON),(7,10,2,4,SHINE),(7,13,3,2,SHINE)])
prop('brass_key','Brass Maintenance Key',[(2,3,6,6,D),(3,4,4,4,BRASS),(4,5,2,2,D),(7,6,7,2,BRASS),(11,8,2,2,BRASS),(3,4,2,1,GOLD)])
prop('gauge_dial','Round Gauge Dial',[(4,2,8,12,D),(2,4,12,8,D),(4,3,8,10,BRASS),(3,5,10,6,BRASS),(5,4,6,8,'e3d4ad'),(4,6,8,4,'e3d4ad'),(7,7,2,2,D),(9,5,1,3,RUST)])
prop('gear_small','Small Gear',[(5,4,6,8,BRASS),(4,5,8,6,BRASS),(6,2,4,2,BRASS),(6,12,4,2,BRASS),(2,6,2,4,BRASS),(12,6,2,4,BRASS),(6,6,4,4,D),(7,7,2,2,IRON)])
prop('hanging_cable','Hanging Factory Cable',[(6,0,2,7,D),(7,1,1,5,IRON),(8,6,2,4,D),(9,7,1,2,IRON),(7,9,2,4,D),(6,12,4,3,RUST),(7,13,2,1,GOLD)])
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
Path('/private/tmp/picell-steampunk-machinery.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
