"""Create original modular 16px fishing terrain and props."""
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
  f='fishing_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
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



WATER='507b80';WAVE='8cb7ae';SAND='c5ae7c';WOOD='694d43';PLANK='986b4d';LEAF='62896c';HI='91af70';PAPER='d8cbb0'
for id,name,c in [('water','Fishing Calm Water',WATER),('deep_water','Fishing Deep Water','36596c')]:
 t=Tile(c)
 for x,y in [(1,2),(9,5),(3,10),(11,14)]:t.rect(x,y,4,1,WAVE)
 t.save(id,name)
t=Tile(SAND)
for x,y in [(2,3),(8,7),(12,2),(5,12),(13,13)]:t.dot(x,y,'aa8e60')
t.save('sand','Fishing Sandy Shore')
for side in ['top','bottom','left','right','nw','ne','sw','se']:
 t=Tile(WATER)
 if side in ['top','nw','ne']:t.rect(0,0,16,5,SAND);t.rect(0,5,16,1,PAPER)
 if side in ['bottom','sw','se']:t.rect(0,11,16,5,SAND);t.rect(0,10,16,1,PAPER)
 if side in ['left','nw','sw']:t.rect(0,0,5,16,SAND);t.rect(5,0,1,16,PAPER)
 if side in ['right','ne','se']:t.rect(11,0,5,16,SAND);t.rect(10,0,1,16,PAPER)
 t.save('shore_'+side,'Fishing Shore '+side.upper())
for side in ['left','middle','right']:
 t=Tile()
 t.rect(0,4,16,9,D)
 for y in [4,7,10]:t.rect(0,y,16,2,PLANK);t.rect(0,y,16,1,'c19869')
 if side=='left':t.rect(0,4,1,9,D);t.rect(2,2,2,13,WOOD)
 if side=='right':t.rect(15,4,1,9,D);t.rect(12,2,2,13,WOOD)
 t.save('dock_'+side,'Fishing Dock '+side.title())
t=Tile()
for x in [3,11]:t.rect(x,0,2,16,WOOD)
for y in [2,7,12]:t.rect(5,y,6,2,PLANK);t.rect(5,y,6,1,'c19869')
t.save('dock_ladder','Fishing Dock Ladder')
prop('rowboat','Fishing Rowboat',[(3,3,10,2,D),(1,5,14,7,D),(3,12,10,2,D),(2,5,12,6,PLANK),(4,4,8,1,PLANK),(4,6,8,4,WOOD),(3,7,10,1,'c19869'),(3,10,10,1,'c19869'),(4,12,8,1,PLANK)])
prop('oars','Crossed Fishing Oars',[(3,2,2,4,PLANK),(11,2,2,4,PLANK),(5,6,2,2,WOOD),(9,6,2,2,WOOD),(7,8,2,2,WOOD),(5,10,2,2,WOOD),(9,10,2,2,WOOD),(3,12,2,3,PLANK),(11,12,2,3,PLANK)])
prop('rod','Fishing Rod',[(3,9,2,6,WOOD),(4,5,1,5,PLANK),(5,2,1,4,PLANK),(6,1,6,1,PAPER),(11,2,1,9,PAPER),(10,11,2,2,IRON),(3,10,3,2,BRASS)])
prop('bobber','Fishing Bobber',[(7,1,1,4,PAPER),(5,5,6,6,D),(6,5,4,3,PAPER),(6,8,4,2,RUST),(7,11,2,2,WOOD),(3,14,10,1,WAVE)])
prop('net','Fishing Landing Net',[(3,2,9,2,WOOD),(2,4,2,6,WOOD),(11,4,2,6,WOOD),(4,10,7,2,WOOD),(5,4,1,6,PAPER),(8,4,1,6,PAPER),(4,5,7,1,PAPER),(4,8,7,1,PAPER),(7,12,2,4,WOOD)])
prop('bucket','Fishing Bucket',[(4,2,8,1,IRON),(3,3,1,5,IRON),(12,3,1,5,IRON),(2,7,12,2,D),(3,9,10,6,D),(4,9,8,5,IRON),(5,9,1,4,SHINE),(5,8,6,1,WATER)])
prop('tackle_box','Fishing Tackle Box',[(5,3,6,3,D),(6,4,4,1,BRASS),(2,6,12,8,D),(3,7,10,6,LEAF),(3,10,10,1,D),(7,9,2,3,BRASS),(4,7,7,1,HI)])
prop('bait_jar','Fishing Bait Jar',[(5,2,6,2,WOOD),(4,4,8,10,D),(5,5,6,8,'8cb7ae'),(5,5,1,6,PAPER),(7,8,3,1,RUST),(6,9,2,1,RUST),(7,10,3,1,RUST)])
prop('fish_basket','Fishing Wicker Basket',[(5,2,6,1,WOOD),(4,3,1,4,WOOD),(11,3,1,4,WOOD),(2,7,12,7,D),(3,8,10,5,PLANK),(3,10,10,1,WOOD),(5,8,1,5,WOOD),(9,8,1,5,WOOD)])
for id,name,c,accent in [('trout','River Trout','779b95',PAPER),('perch','Striped Perch',HI,LEAF),('salmon','River Salmon',RUST,'e4ae8e'),('carp','Golden Carp',BRASS,GOLD)]:
 t=Tile();t.rect(5,5,7,1,D);t.rect(3,6,10,5,D);t.rect(4,6,8,4,c);t.rect(5,6,6,1,accent);t.rect(1,5,3,7,c);t.dot(10,7,D);t.rect(6,10,3,2,c)
 if id=='perch':
  for x in [5,7,9]:t.rect(x,7,1,3,accent)
 t.save(id,name,'Object')
prop('reeds','Fishing Reeds',[(4,3,1,12,LEAF),(8,1,1,14,LEAF),(12,5,1,10,LEAF),(3,1,3,5,WOOD),(7,0,3,4,WOOD),(11,3,3,5,WOOD),(2,10,2,3,HI),(9,8,2,3,HI)])
prop('lily_pad','Fishing Lily Pad',[(3,5,10,7,LEAF),(2,7,12,3,LEAF),(4,6,7,1,HI),(8,8,6,1,WATER),(9,9,5,1,WATER),(6,4,3,3,PAPER),(7,5,1,1,GOLD)])
prop('shore_rock','Fishing Shore Rock',[(4,6,8,2,D),(2,8,12,6,D),(3,8,10,5,IRON),(4,7,7,2,SHINE),(3,8,3,3,LEAF)])
prop('fishing_sign','Fishing Spot Sign',[(7,8,2,8,WOOD),(1,2,14,7,D),(2,3,12,5,PLANK),(5,4,6,3,PAPER),(3,4,2,3,PAPER),(9,5,1,1,D)])
prop('lifebuoy','Fishing Lifebuoy',[(4,2,8,2,PAPER),(2,4,2,8,PAPER),(12,4,2,8,PAPER),(4,12,8,2,PAPER),(4,4,2,2,RUST),(10,4,2,2,RUST),(4,10,2,2,RUST),(10,10,2,2,RUST)])
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
Path('/private/tmp/picell-fishing.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 fishing templates')
