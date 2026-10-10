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
  f='platformer_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
def dirt(seed=1):
 t=Tile(SOIL);r=random.Random(seed)
 for i in range(24):t.rect(r.randrange(1,15),r.randrange(1,15),2 if i%3==0 else 1,1,MID if i%2 else '674334')
 return t
# Three matching terrain families, each with top, fill and outer corners.
for biome,name,base,mid,shine,cap in [('snow','Snow','4a6275','708d9d','a6bdc5','e5efdf'),('sand','Desert','946748','b88956','dec088','f2d49a'),('volcanic','Volcanic','3a3444','5b4556','936270','c57356')]:
 for kind,label in [('top','Top'),('fill','Fill'),('left_corner','Left Corner'),('right_corner','Right Corner')]:
  t=Tile(base);r=random.Random(37)
  for i in range(25):t.rect(r.randrange(1,15),r.randrange(1,15),2 if i%3==0 else 1,1,mid if i%2 else shine)
  if kind!='fill':
   t.rect(0,0,16,3,cap);t.rect(0,3,16,1,shine);t.rect(3,3,2,2,cap);t.rect(11,3,2,1,cap)
  if kind=='left_corner':t.rect(0,0,1,16,D);t.rect(1,4,1,12,shine)
  if kind=='right_corner':t.rect(15,0,1,16,D);t.rect(14,4,1,12,base)
  t.save(biome+'_'+kind,name+' Ground '+label)
for id,name,cracked in [('ice_block','Ice Block',False),('ice_cracked','Cracked Ice Block',True)]:
 t=Tile('385f79');t.rect(1,1,14,14,'70a9bb');t.rect(1,1,14,2,'c2e2dd');t.rect(1,3,2,11,'9dcbd0');t.rect(4,4,3,1,'c2e2dd');t.rect(8,11,4,1,'9dcbd0')
 if cracked:
  for x,y in [(8,3),(7,4),(7,5),(8,6),(9,7),(9,8),(8,9),(7,10),(7,11),(6,12)]:t.dot(x,y,'385f79')
 t.save(id,name)
for side in ['left','middle','right']:
 t=Tile();t.rect(0,5,16,5,D);t.rect(0,5,16,1,'b8c9c6');t.rect(0,6,16,2,'738b99');t.rect(0,8,16,1,'46546b')
 for x in [3,11]:t.dot(x,7,'d1ded0')
 if side=='left':t.rect(0,5,1,5,D)
 if side=='right':t.rect(15,5,1,5,D)
 t.save('metal_platform_'+side,'Metal Platform '+side.title())
for side in ['left','right']:
 t=Tile()
 for x in range(16):
  y=x if side=='left' else 15-x
  t.rect(x,y,1,16-y,'b88956');t.dot(x,y,'f2d49a')
  if y+1<16:t.dot(x,y+1,'dec088')
 t.save('sand_slope_'+side,'Desert Slope '+side.title())
t=Tile();t.rect(2,3,12,3,D);t.rect(3,3,10,2,'d86780');t.rect(2,12,12,3,D);t.rect(3,12,10,2,'738b99')
for y in [6,8,10]:t.rect(5,y,6,1,'b8c9c6');t.dot(4,y+1,'738b99');t.dot(11,y+1,'738b99')
t.save('spring_pad','Spring Jump Pad')
t=Tile();t.rect(0,5,16,6,D);t.rect(0,6,16,3,'738b99')
for x in range(0,16,5):t.dot(x,6,'dfc178');t.dot(x+1,7,'dfc178');t.dot(x,8,'dfc178')
t.rect(0,10,16,1,'46546b');t.save('conveyor','Conveyor Platform')
t=Tile()
for y in range(0,16,4):t.rect(6,y,4,3,D);t.rect(7,y,2,1,'b8c9c6');t.rect(7,y+1,1,2,'738b99');t.dot(8,y+3,'738b99')
t.save('hanging_chain','Hanging Platform Chain')
t=Tile();t.rect(7,8,2,7,'456a46')
for x,y in [(3,9),(5,6),(9,6),(11,9)]:t.rect(x,y,2,5,'63aa68');t.dot(x,y,'a4d47a')
t.save('grass_tuft','Grass Tuft','Object')
t=Tile();t.rect(7,7,1,8,'456a46');t.rect(4,10,3,2,'63aa68');t.rect(8,12,3,2,'63aa68');t.rect(5,3,5,5,'d86780');t.rect(6,2,3,1,'f2a6a1');t.rect(4,4,1,3,'f2a6a1');t.rect(6,4,3,2,'ffe09b');t.save('flower','Meadow Flower','Object')
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
Path('/private/tmp/picell-platformer-extra.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
