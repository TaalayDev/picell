"""Original 16px mushroom biome: terrain, connecting trails and overlay props."""
import json, random, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
OUTLINE='28273d';SOIL='594356';MOSS='496c64';LIGHT='83a586';PATH='927485'
items=[]
class Tile:
 def __init__(self,c=None):self.p=[0 if c is None else 0xff000000|int(c,16)]*256
 def rect(self,x,y,w,h,c):
  for yy in range(y,y+h):
   for xx in range(x,x+w):
    if 0<=xx<16 and 0<=yy<16:self.p[yy*16+xx]=0xff000000|int(c,16)
 def dot(self,x,y,c):self.rect(x,y,1,1,c)
 def save(self,id,name,category='Background'):
  file='mushroom_biome_'+id+'_16.json'
  ROOT.joinpath(file).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n')
  items.append((file,self.p))
def ground(seed=3,base=MOSS):
 t=Tile(base);r=random.Random(seed)
 for i in range(22):
  x,y=r.randrange(1,15),r.randrange(1,15)
  t.rect(x,y,2 if i%4==0 else 1,1,LIGHT if i%3==0 else '39544f')
 return t
ground().save('moss','Fungal Moss Ground');ground(9).save('moss_dark','Deep Moss Ground')
t=Tile(SOIL)
for x,y in [(2,3),(9,2),(5,7),(12,9),(2,12),(9,13)]:t.rect(x,y,2,1,'805b70');t.dot(x+1,y+1,'3f3547')
t.save('soil','Mushroom Soil')
t=ground();
for x,y in [(2,4),(10,9),(6,12)]:t.rect(x,y,3,1,'bed8b2');t.dot(x+1,y-1,'7cbeb1');t.dot(x+1,y+1,'7cbeb1')
t.save('spores','Glowing Spore Ground')
# Trail entrances are six pixels wide and identical across all variants.
for id,name,dirs in [('path_h','Fungal Trail Horizontal','ew'),('path_v','Fungal Trail Vertical','ns'),('path_ne','Fungal Trail Northeast','ne'),('path_nw','Fungal Trail Northwest','nw'),('path_se','Fungal Trail Southeast','se'),('path_sw','Fungal Trail Southwest','sw'),('path_cross','Fungal Trail Crossing','nesw'),('path_t','Fungal Trail Junction','new')]:
 t=ground();t.rect(5,5,6,6,PATH)
 for d in dirs:
  if d=='n':t.rect(5,0,6,6,PATH)
  if d=='s':t.rect(5,10,6,6,PATH)
  if d=='e':t.rect(10,5,6,6,PATH)
  if d=='w':t.rect(0,5,6,6,PATH)
 t.dot(7,7,'b49a9b');t.dot(9,9,'73586d');t.save(id,name)
# Moss borders surround the exposed soil; outer corner variants join both edges.
for id,name,edges in [('edge_n','Moss Bank North','n'),('edge_s','Moss Bank South','s'),('edge_w','Moss Bank West','w'),('edge_e','Moss Bank East','e'),('corner_nw','Moss Bank Northwest','nw'),('corner_ne','Moss Bank Northeast','ne'),('corner_sw','Moss Bank Southwest','sw'),('corner_se','Moss Bank Southeast','se')]:
 t=Tile(SOIL)
 for d in edges:
  if d=='n':t.rect(0,0,16,5,MOSS);t.rect(0,4,16,1,LIGHT)
  if d=='s':t.rect(0,11,16,5,MOSS);t.rect(0,11,16,1,LIGHT)
  if d=='w':t.rect(0,0,5,16,MOSS);t.rect(4,0,1,16,LIGHT)
  if d=='e':t.rect(11,0,5,16,MOSS);t.rect(11,0,1,16,LIGHT)
 t.save(id,name)
# Transparent objects can be placed over any of the ground tiles.
for id,name,cap,shade,spots in [('rose_cap','Rosecap Mushroom','bb6388','7d486d','f4d6b5'),('blue_cap','Mooncap Mushroom','66aeb6','426c86','c9eee0'),('violet_cap','Violet Mushroom','9579ba','615580','e7c6df')]:
 t=Tile();t.rect(6,8,4,7,OUTLINE);t.rect(7,8,2,6,'d6c8b0');t.dot(8,12,'b28d9d');t.rect(2,5,12,4,OUTLINE);t.rect(4,3,8,2,OUTLINE);t.rect(6,2,4,1,OUTLINE);t.rect(3,5,10,2,cap);t.rect(5,4,6,2,cap);t.rect(6,3,4,1,cap);t.rect(3,7,10,1,shade);t.rect(5,5,2,1,spots);t.dot(9,4,spots);t.dot(11,6,spots);t.save(id,name,'Object')
t=Tile();t.rect(4,10,8,5,OUTLINE);t.rect(5,11,6,3,'d6c8b0')
for x,y in [(2,7),(7,4),(10,8)]:t.rect(x,y,4,2,'84b9ae');t.rect(x+1,y-1,2,1,'bed8b2');t.rect(x+1,y+2,1,4,'66877d')
t.save('glow_cluster','Glowshroom Cluster','Object')
t=Tile();t.rect(3,11,10,4,'394c4b');t.rect(7,5,2,8,MOSS)
for x,y in [(4,6),(9,4),(3,9),(10,8)]:t.rect(x,y,3,2,'78a78c');t.dot(x+1,y-1,'b0c99d')
t.save('fern','Spore Fern','Object')
t=Tile();t.rect(2,6,12,7,OUTLINE);t.rect(3,7,10,5,'725367');t.rect(4,8,2,3,'b28b87');t.rect(7,7,6,1,'967784');t.rect(4,5,7,2,MOSS);t.rect(5,5,4,1,LIGHT);t.dot(12,9,'bb6388');t.dot(13,8,'f4d6b5');t.save('fungal_log','Fungal Fallen Log','Object')
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 assert len(p)==256 and all(0<=c<=0xffffffff for c in p)
ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n');assert len(index)==len(set(index))
# Contact sheet, with transparency shown as checkerboard.
cols=7;rows=(len(items)+cols-1)//cols;w=cols*96;h=rows*96;raw=bytearray()
for y in range(h):
 raw.append(0)
 for x in range(w):
  n=y//96*cols+x//96;c=items[n][1][(y%96//6)*16+x%96//6] if n<len(items) else 0
  c=c or (0xffe5e6ee if (x//12+y//12)%2 else 0xffd7dae5)
  raw.extend([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
Path('/private/tmp/picell-mushroom-biome.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 mushroom biome templates')
