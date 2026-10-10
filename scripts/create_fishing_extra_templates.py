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

for id,name,c,accent in [('pike','Northern Pike',LEAF,HI),('bluegill','Bluegill','668d99',PAPER),('catfish','River Catfish',IRON,SHINE),('eel','River Eel',WOOD,PLANK),('koi','Pond Koi',PAPER,RUST),('bass','Lake Bass','496259',HI)]:
 t=Tile();t.rect(4,5,9,6,D);t.rect(5,6,7,4,c);t.rect(5,6,6,1,accent);t.rect(1,5,3,7,c);t.dot(11,7,D);t.rect(7,10,3,2,c)
 if id=='koi':t.rect(6,7,2,3,RUST);t.rect(10,6,2,2,RUST)
 if id=='eel':t.rect(2,9,10,2,c);t.rect(1,10,3,2,c);t.rect(5,5,8,1,accent)
 if id=='catfish':t.rect(12,8,3,1,SHINE);t.rect(13,9,1,2,SHINE)
 t.save(id,name,'Object')
prop('crab','Shore Crab',[(4,6,8,6,D),(5,7,6,4,RUST),(6,5,1,2,D),(9,5,1,2,D),(1,4,3,4,RUST),(12,4,3,4,RUST),(2,9,3,1,RUST),(11,9,3,1,RUST),(2,12,3,1,RUST),(11,12,3,1,RUST)])
prop('shrimp','River Shrimp',[(5,4,7,2,RUST),(3,6,9,4,RUST),(4,6,7,1,'e4ae8e'),(2,10,6,2,RUST),(1,11,3,2,RUST),(10,5,1,1,D),(12,4,3,1,PAPER),(6,10,1,3,PAPER),(9,10,1,2,PAPER)])
prop('shell','Shore Shell',[(5,4,6,2,D),(3,6,10,6,D),(4,6,8,5,PAPER),(5,6,1,4,BRASS),(8,5,1,6,BRASS),(11,6,1,4,BRASS),(6,12,4,1,BRASS)])
prop('starfish','Shore Starfish',[(7,2,2,10,RUST),(2,6,12,2,RUST),(5,8,6,3,RUST),(3,11,3,3,RUST),(10,11,3,3,RUST),(7,6,2,3,'e4ae8e')])
for side in ['top','bottom','cross','corner']:
 t=Tile();t.rect(3,0,10,16,D)
 for y in range(0,16,3):t.rect(4,y,8,2,PLANK);t.rect(4,y,8,1,'c19869')
 if side in ['cross','corner']:
  t.rect(0 if side=='cross' else 8,4,16 if side=='cross' else 8,8,PLANK)
  for y in [4,7,10]:t.rect(0 if side=='cross' else 8,y,16 if side=='cross' else 8,1,'c19869')
 if side=='top':t.rect(3,0,10,1,D);t.rect(2,1,2,4,WOOD);t.rect(12,1,2,4,WOOD)
 if side=='bottom':t.rect(3,15,10,1,D);t.rect(2,11,2,4,WOOD);t.rect(12,11,2,4,WOOD)
 t.save('dock_'+side,'Fishing Dock '+side.title())
prop('mooring_post','Dock Mooring Post',[(6,2,4,13,D),(7,3,2,11,PLANK),(4,7,8,2,PAPER),(5,9,6,1,PAPER),(5,2,6,1,WOOD)])
prop('rope_coil','Dock Rope Coil',[(4,3,8,2,BRASS),(2,5,2,6,BRASS),(12,5,2,6,BRASS),(4,11,8,2,BRASS),(5,5,6,2,BRASS),(5,7,2,3,BRASS),(9,7,2,3,BRASS),(7,9,2,1,BRASS),(11,12,3,2,BRASS)])
prop('fish_trap','Wicker Fish Trap',[(3,4,10,2,WOOD),(1,6,14,5,WOOD),(3,11,10,2,WOOD),(3,6,10,4,PLANK),(4,6,1,4,PAPER),(7,6,1,4,PAPER),(10,6,1,4,PAPER),(2,8,12,1,WOOD),(6,4,4,2,D)])
prop('hanging_net','Hanging Fishing Net',[(1,1,14,1,WOOD),(2,2,1,9,PAPER),(5,2,1,11,PAPER),(8,2,1,12,PAPER),(11,2,1,11,PAPER),(14,2,1,9,PAPER),(2,4,13,1,PAPER),(2,7,13,1,PAPER),(3,10,11,1,PAPER),(5,13,7,1,PAPER)])
prop('fish_crate','Fresh Fish Crate',[(2,6,12,8,D),(3,7,10,6,PLANK),(3,9,10,1,WOOD),(3,12,10,1,WOOD),(4,4,8,3,SHINE),(3,4,2,3,SHINE),(10,5,1,1,D)])
prop('cooler','Fishing Cooler',[(2,5,12,9,D),(3,6,10,7,'668d99'),(2,4,12,3,PAPER),(3,4,10,1,'f1e4c9'),(6,8,4,2,PAPER),(1,7,2,3,IRON),(13,7,2,3,IRON)])
prop('stool','Fishing Folding Stool',[(2,5,12,3,D),(3,5,10,2,LEAF),(4,8,2,3,WOOD),(10,8,2,3,WOOD),(6,11,4,2,WOOD),(3,13,3,2,WOOD),(10,13,3,2,WOOD)])
prop('camp_lantern','Fishing Camp Lantern',[(6,1,4,1,IRON),(5,2,1,3,IRON),(10,2,1,3,IRON),(4,5,8,2,D),(5,7,6,6,BRASS),(6,8,4,4,GOLD),(7,8,2,3,'fff1ae'),(4,13,8,2,D)])
prop('campfire','Fishing Campfire',[(3,12,10,2,WOOD),(5,10,2,5,PLANK),(9,10,2,5,PLANK),(5,6,6,5,RUST),(7,3,2,8,'efa14f'),(8,7,2,3,GOLD),(3,14,2,1,IRON),(11,14,2,1,IRON)])
prop('tent','Lakeside Fishing Tent',[(7,2,2,2,LEAF),(5,4,6,3,LEAF),(3,7,10,3,LEAF),(1,10,14,4,D),(2,10,12,3,LEAF),(7,6,2,7,HI),(6,10,4,3,D)])
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
Path('/private/tmp/picell-fishing-extra.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 fishing templates')
