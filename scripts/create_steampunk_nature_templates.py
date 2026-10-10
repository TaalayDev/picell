"""Create botanical steampunk nature tiles, without sci-fi technology."""
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
  f='steampunk_nature_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
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


LEAF='62896c';MOSS='91af70';DEEP='354f4e';EARTH='705448';BARK='634d43';WATER='507b80';WATERHI='8cb7ae'
for kind,label in [('moss','Velvet Moss'),('copper_soil','Copper Root Soil'),('leaf_litter','Amber Leaf Litter'),('stone','Garden Limestone')]:
 base={'moss':DEEP,'copper_soil':EARTH,'leaf_litter':BARK,'stone':IRON}[kind];t=Tile(base)
 for y in range(1,16,4):
  for x in range((y//4%2)*2,16,5):
   t.rect(x,y,3,2,MOSS if kind=='moss' else BRASS if kind=='copper_soil' else RUST if kind=='leaf_litter' else SHINE)
 if kind=='copper_soil':
  t.rect(3,0,1,16,RUST);t.rect(3,7,7,1,RUST);t.rect(9,7,1,9,RUST)
 t.save(kind,label)
for side in ['top','left','right','bottom','nw','ne','sw','se']:
 t=Tile(EARTH)
 for x,y in [(2,5),(8,9),(12,3),(4,13)]:t.rect(x,y,2,1,RUST)
 if side in ['top','nw','ne']:t.rect(0,0,16,4,LEAF);t.rect(0,0,16,1,MOSS);t.rect(2,4,2,2,DEEP);t.rect(10,4,3,1,DEEP)
 if side in ['bottom','sw','se']:t.rect(0,12,16,4,LEAF);t.rect(0,12,16,1,MOSS)
 if side in ['left','nw','sw']:t.rect(0,0,4,16,LEAF);t.rect(0,0,1,16,MOSS)
 if side in ['right','ne','se']:t.rect(12,0,4,16,LEAF);t.rect(15,0,1,16,MOSS)
 t.save('moss_bank_'+side,'Moss Bank '+side.upper())
t=Tile(WATER)
for x,y in [(1,2),(9,5),(3,10),(11,14)]:t.rect(x,y,4,1,WATERHI)
t.save('pond','Botanical Pond')
for side in ['left','right']:
 t=Tile(WATER);x=0 if side=='left' else 11;t.rect(x,0,5,16,EARTH);t.rect(x,0,3,16,LEAF);t.rect(x+4 if side=='left' else x,0,1,16,WATERHI);t.save('pond_bank_'+side,'Pond Bank '+side.title())
t=Tile(BARK)
for y in range(0,16,4):t.rect(0,y,16,1,D);t.rect(0,y+1,16,1,BRASS)
t.rect(1,0,1,16,IRON);t.rect(14,0,1,16,IRON);t.save('garden_bridge','Copper Bound Garden Bridge')
prop('copper_tree','Copper Root Tree',[(4,1,8,2,DEEP),(2,3,12,5,DEEP),(3,3,10,4,LEAF),(4,2,6,2,MOSS),(1,6,14,3,DEEP),(2,6,12,2,LEAF),(7,8,3,7,BARK),(7,9,1,5,RUST),(4,14,8,2,BARK),(3,15,3,1,BRASS),(11,15,3,1,BRASS)])
prop('spiral_tree','Spiral Willow',[(3,1,10,2,DEEP),(1,3,14,4,LEAF),(2,3,11,1,MOSS),(1,7,2,4,LEAF),(5,7,1,3,LEAF),(12,7,2,5,LEAF),(7,5,2,10,BARK),(7,7,4,1,RUST),(10,7,1,3,RUST),(6,14,5,2,BARK)])
prop('brass_bloom','Brass Petal Bloom',[(7,7,2,8,LEAF),(4,10,3,2,LEAF),(9,12,3,2,LEAF),(6,1,4,2,BRASS),(3,3,3,4,BRASS),(10,3,3,4,BRASS),(6,7,4,2,BRASS),(6,3,4,4,GOLD),(7,4,2,2,BARK)])
prop('amber_fern','Amber Tipped Fern',[(7,3,2,12,DEEP),(3,5,4,2,LEAF),(9,5,4,2,LEAF),(2,8,5,2,LEAF),(9,8,5,2,LEAF),(3,11,4,2,MOSS),(9,11,4,2,MOSS),(3,5,2,1,BRASS),(11,5,2,1,BRASS),(2,8,2,1,BRASS),(12,8,2,1,BRASS)])
prop('copper_mushrooms','Copper Cap Mushrooms',[(3,9,2,6,GOLD),(10,7,2,8,GOLD),(1,6,6,4,RUST),(2,5,4,2,BRASS),(8,4,7,4,RUST),(9,3,5,2,BRASS),(3,6,2,1,GOLD),(11,4,2,1,GOLD)])
prop('seed_pod','Clockwork Seed Pod',[(6,1,4,2,LEAF),(7,3,2,2,DEEP),(4,5,8,8,D),(5,6,6,6,BRASS),(7,6,2,6,RUST),(6,8,1,2,GOLD),(9,8,1,2,GOLD),(7,13,2,2,LEAF)])
prop('vine','Copper Trained Vine',[(7,0,1,16,RUST),(4,1,3,2,LEAF),(8,4,4,2,MOSS),(3,7,4,2,LEAF),(8,10,4,2,MOSS),(4,13,3,2,LEAF),(7,5,2,1,BRASS),(6,11,2,1,BRASS)])
prop('moss_rock','Root Wrapped Boulder',[(4,6,8,2,D),(2,8,12,6,D),(3,8,10,5,IRON),(4,7,7,2,SHINE),(4,7,6,2,LEAF),(2,9,3,3,MOSS),(8,10,4,1,RUST),(10,11,1,3,RUST)])
prop('fallen_log','Copper Root Fallen Log',[(1,7,14,7,D),(2,8,12,5,BARK),(2,8,2,5,BRASS),(3,9,2,3,EARTH),(5,8,8,1,RUST),(7,10,5,1,RUST),(8,5,4,3,LEAF),(9,5,2,1,MOSS)])
prop('terrarium','Victorian Terrarium',[(6,1,4,2,BRASS),(3,3,10,10,D),(4,4,8,8,WATER),(4,4,1,6,WATERHI),(7,6,2,6,LEAF),(5,7,2,2,MOSS),(9,8,2,2,MOSS),(3,12,10,2,BRASS),(5,14,6,1,BARK)])
prop('water_wheel','Garden Water Wheel',[(4,2,8,12,BARK),(2,4,12,8,BARK),(5,3,6,10,BRASS),(3,5,10,6,BRASS),(5,5,6,6,D),(7,3,2,10,BARK),(3,7,10,2,BARK),(7,7,2,2,GOLD)])
prop('watering_pump','Hand Powered Garden Pump',[(7,3,3,10,IRON),(7,3,2,2,BRASS),(9,3,5,1,BARK),(12,3,1,4,BARK),(4,6,4,2,BRASS),(3,7,2,3,BRASS),(4,13,9,2,D),(5,13,7,1,BRASS)])
prop('planter','Brass Botanical Planter',[(2,9,12,2,D),(3,10,10,4,BRASS),(4,14,8,1,RUST),(7,3,2,6,LEAF),(4,4,3,2,MOSS),(9,2,3,2,LEAF),(4,7,3,2,LEAF),(9,6,4,2,MOSS),(5,11,1,2,GOLD),(10,11,1,2,GOLD)])
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 t=json.loads(ROOT.joinpath(f).read_text());assert t['width']==t['height']==16 and len(p)==256 and all(0<=c<=0xffffffff for c in p)
ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n');assert len(index)==len(set(index))
cols=6;rows=(len(items)+cols-1)//cols;w=cols*96;h=rows*96;raw=bytearray()
for y in range(h):
 raw.append(0)
 for x in range(w):
  n=y//96*cols+x//96;c=items[n][1][(y%96//6)*16+x%96//6] if n<len(items) else 0
  c=c or (0xffe5e6ee if (x//12+y//12)%2 else 0xffd7dae5)
  raw.extend([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
Path('/private/tmp/picell-steampunk-nature.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 steampunk nature templates')
