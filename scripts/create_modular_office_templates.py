"""Create modular 16px office floors, walls, furniture and props."""
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
  f='office_modular_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
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


WOOD='694d43';LIGHTWOOD='986b4d';PAPER='d8cbb0';GLASS='416676'
for id,name in [('wood_floor','Office Wood Floor'),('carpet','Office Green Carpet'),('checker_floor','Office Checker Floor')]:
 t=Tile(WOOD if id=='wood_floor' else '496259' if id=='carpet' else PAPER)
 if id=='wood_floor':
  for x in range(0,16,4):t.rect(x,0,1,16,D);t.rect(x+1,0,1,16,LIGHTWOOD)
  for x,y in [(1,4),(5,12),(9,4),(13,12)]:t.rect(x,y,3,1,D)
 if id=='carpet':
  for y in range(1,16,4):
   for x in range(1,16,4):t.dot(x,y,'62896c')
 if id=='checker_floor':
  for y in range(0,16,4):
   for x in range(0,16,4):
    if (x//4+y//4)%2:t.rect(x,y,4,4,IRON)
 t.save(id,name)
for side in ['middle','left','right']:
 t=Tile('c3b59a');t.rect(0,11,16,5,WOOD);t.rect(0,11,16,1,BRASS)
 for x in [3,11]:t.rect(x,0,1,11,'aa9b86')
 if side=='left':t.rect(0,0,2,16,D)
 if side=='right':t.rect(14,0,2,16,D)
 t.save('wall_'+side,'Office Wall '+side.title())
for side in ['left','middle','right']:
 t=Tile();t.rect(0,4,16,4,D);t.rect(0,4,16,1,LIGHTWOOD);t.rect(0,5,16,2,WOOD)
 if side=='left':t.rect(0,4,1,4,D);t.rect(2,8,2,7,D);t.rect(3,8,1,6,WOOD)
 if side=='right':t.rect(15,4,1,4,D);t.rect(12,8,2,7,D);t.rect(12,8,1,6,WOOD)
 t.save('desk_'+side,'Office Desk '+side.title(),'Object')
for side in ['left','right']:
 t=Tile();t.rect(0,4,16,4,D);t.rect(0,4,16,1,LIGHTWOOD);t.rect(0,5,16,2,WOOD)
 x=2 if side=='left' else 10;t.rect(x,4,4,12,D);t.rect(x+1,5,2,10,WOOD);t.rect(x+1,5,2,1,LIGHTWOOD)
 t.save('desk_corner_'+side,'Office Desk Corner '+side.title(),'Object')
prop('desk_drawers','Office Desk Drawer Module',[(0,4,16,4,D),(0,4,16,1,LIGHTWOOD),(0,5,16,2,WOOD),(3,8,10,7,D),(4,8,8,6,WOOD),(4,10,8,1,D),(4,13,8,1,D),(7,9,2,1,BRASS),(7,12,2,1,BRASS)])
for side in ['left','middle','right']:
 t=Tile();t.rect(0,1,16,14,D);t.rect(1 if side=='left' else 0,2,15 if side!='middle' else 16,12,WOOD)
 for y in [6,12]:t.rect(0,y,16,2,LIGHTWOOD)
 for x,c,h in [(2,RUST,3),(5,GLASS,4),(8,PAPER,3),(11,BRASS,4)]:t.rect(x,6-h,2,h,c);t.rect(x,12-h,2,h,c)
 if side=='right':t.rect(15,1,1,14,D)
 t.save('bookshelf_'+side,'Office Bookshelf '+side.title(),'Object')
for side in ['left','middle','right']:
 t=Tile();t.rect(0,2,16,13,D);t.rect(0,3,16,11,IRON);t.rect(0,3,16,1,SHINE)
 for y in [6,10,14]:t.rect(0,y,16,1,D)
 for y in [5,9,13]:t.rect(7,y,3,1,BRASS)
 if side=='left':t.rect(0,2,1,13,D)
 if side=='right':t.rect(15,2,1,13,D)
 t.save('filing_'+side,'Office Filing Cabinet '+side.title(),'Object')
prop('chair_front','Office Chair Front',[(4,2,8,7,D),(5,3,6,5,RUST),(3,10,10,3,D),(4,10,8,2,RUST),(7,13,2,2,IRON),(4,15,8,1,D)])
prop('chair_back','Office Chair Back',[(4,2,8,8,D),(5,3,6,6,WOOD),(6,4,4,1,LIGHTWOOD),(7,10,2,4,IRON),(3,14,10,1,D),(3,15,2,1,D),(11,15,2,1,D)])
prop('chair_side','Office Chair Side',[(3,2,4,8,D),(4,3,2,6,RUST),(3,10,10,3,D),(4,10,8,2,RUST),(7,13,2,2,IRON),(4,15,8,1,D)])
prop('door_closed','Office Closed Door',[(2,0,12,16,D),(3,1,10,15,WOOD),(4,2,8,6,'453a39'),(4,10,8,5,'453a39'),(11,8,1,1,GOLD)])
prop('door_open','Office Open Door',[(2,0,12,16,D),(3,1,10,15,'1d2635'),(10,1,3,15,WOOD),(10,2,1,13,LIGHTWOOD),(10,8,1,1,GOLD)])
prop('window','Office Window',[(1,1,14,13,D),(2,2,12,11,PAPER),(3,3,10,9,GLASS),(4,3,2,7,'668d99'),(7,2,2,11,WOOD),(2,7,12,1,WOOD),(0,14,16,2,LIGHTWOOD)])
prop('lamp','Office Desk Lamp',[(3,13,9,2,D),(4,13,7,1,BRASS),(7,6,2,7,IRON),(8,5,4,2,IRON),(9,2,5,3,D),(10,3,3,2,BRASS),(10,5,3,1,GOLD)])
prop('typewriter','Office Typewriter',[(5,1,7,5,PAPER),(6,2,5,1,IRON),(6,4,4,1,IRON),(3,6,10,5,D),(4,7,8,3,IRON),(1,11,14,3,D),(2,12,12,1,BRASS),(3,12,1,1,PAPER),(6,12,1,1,PAPER),(9,12,1,1,PAPER),(12,12,1,1,PAPER)])
prop('telephone','Office Telephone',[(3,2,10,3,D),(4,2,8,1,BRASS),(2,3,3,3,D),(11,3,3,3,D),(7,5,2,5,BRASS),(4,9,8,5,D),(5,10,6,3,IRON),(6,10,4,3,BRASS),(7,11,2,1,D)])
prop('papers','Office Paper Stack',[(3,4,10,9,D),(4,5,8,7,'aa9b86'),(2,2,10,9,PAPER),(3,4,7,1,IRON),(3,6,6,1,IRON),(3,8,4,1,IRON)])
prop('inkwell','Office Ink and Quill',[(3,10,7,5,D),(4,11,5,3,GLASS),(5,9,3,2,BRASS),(8,4,1,6,PAPER),(9,2,2,5,PAPER),(11,1,2,3,PAPER)])
prop('noticeboard','Office Noticeboard',[(1,2,14,12,D),(2,3,12,10,WOOD),(3,4,4,3,PAPER),(9,4,3,4,PAPER),(5,9,5,3,PAPER),(4,4,1,1,RUST),(10,4,1,1,RUST),(7,9,1,1,RUST)])
prop('plant','Office Potted Plant',[(4,10,8,5,D),(5,11,6,3,RUST),(7,3,2,7,'62896c'),(3,4,4,3,'91af70'),(9,2,4,3,'62896c'),(9,7,3,2,'91af70')])
prop('wastebasket','Office Wastebasket',[(3,5,10,10,D),(4,6,8,8,IRON),(5,6,1,7,SHINE),(8,6,1,7,SHINE),(11,6,1,7,SHINE),(5,3,5,3,PAPER)])
prop('wall_clock','Office Wall Clock',[(4,2,8,12,D),(2,4,12,8,D),(4,3,8,10,BRASS),(3,5,10,6,BRASS),(5,4,6,8,PAPER),(4,6,8,4,PAPER),(7,5,1,4,D),(7,8,4,1,D)])
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
Path('/private/tmp/picell-office-modular.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 modular office templates')
