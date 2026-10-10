"""Create a 16px steampunk detective street, office and clue tileset."""
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
  f='steampunk_detective_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 16×16',category=category,is_pro=False,width=16,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
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

WOOD='694d43';WHI='d8cbb0';GLASS='416676';BLUE='668d99'
for id,name,base,accent in [('cobblestone','Detective Cobblestone',IRON,SHINE),('wet_cobblestone','Rainy Cobblestone','3a4b5c',BLUE),('brick_wall','Soot Brick Wall','624b49',RUST)]:
 t=Tile(D)
 for y in range(0,16,4):
  for x in range(-4 if y%8 else 0,16,8):
   t.rect(x,y,7,3,base);t.rect(x,y,7,1,accent)
 if id=='wet_cobblestone':t.rect(2,10,5,1,BLUE);t.rect(10,3,4,1,BLUE)
 t.save(id,name)
t=Tile(WOOD)
for x in range(0,16,4):t.rect(x,0,1,16,D);t.rect(x+1,0,1,16,'986b4d')
for x,y in [(3,4),(7,11),(11,6),(15,13)]:t.rect(x-2,y,3,1,D)
t.save('office_floor','Detective Office Floor')
t=Tile('3d454e');t.rect(0,0,16,2,BRASS);t.rect(0,13,16,3,WOOD)
for x in range(2,16,5):t.rect(x,2,1,11,'59616b')
t.save('wallpaper','Victorian Office Wallpaper')
t=Tile(D);t.rect(0,1,16,14,IRON);t.rect(0,2,16,2,SHINE);t.rect(0,11,16,1,BLUE);t.save('street_curb','Rainy Street Curb')
prop('arched_window','Gaslit Arched Window',[(4,1,8,2,D),(2,3,12,12,D),(3,4,10,10,BRASS),(4,5,8,8,GLASS),(5,5,2,5,BLUE),(7,4,2,10,BRASS),(3,9,10,1,BRASS),(1,14,14,1,IRON)])
prop('office_door','Detective Office Door',[(3,0,10,16,D),(4,1,8,15,WOOD),(5,2,6,5,BRASS),(6,3,4,3,GLASS),(5,9,6,5,'453a39'),(10,8,1,1,GOLD)])
prop('gas_lamp','Detective Street Gas Lamp',[(6,1,4,1,D),(4,2,8,7,D),(5,3,6,5,BRASS),(6,4,4,3,GOLD),(7,3,2,3,'fff1ae'),(7,9,2,5,IRON),(5,14,6,2,D)])
prop('street_sign','Brass Street Sign',[(7,2,2,14,IRON),(1,3,14,5,D),(2,4,12,3,BRASS),(3,5,3,1,WHI),(8,5,4,1,WHI)])
prop('drain','Victorian Street Drain',[(1,5,14,8,D),(2,6,12,6,IRON),(3,7,1,4,D),(6,7,1,4,D),(9,7,1,4,D),(12,7,1,4,D),(2,6,12,1,SHINE)])
prop('steam_manhole','Steaming Manhole',[(2,10,12,4,D),(3,11,10,2,IRON),(5,11,1,2,SHINE),(8,11,1,2,SHINE),(6,6,2,3,SHINE),(8,3,3,3,'b7c7c7'),(5,1,3,2,SHINE)])
prop('desk','Detective Writing Desk',[(1,6,14,3,D),(2,6,12,2,WOOD),(2,9,5,5,WOOD),(9,9,4,2,WOOD),(12,10,2,5,D),(3,10,3,1,BRASS),(3,12,3,1,BRASS),(8,4,4,2,WHI)])
prop('chair','Detective Leather Chair',[(4,1,8,8,D),(5,2,6,6,RUST),(6,3,4,4,'794e43'),(3,9,10,3,D),(4,9,8,2,RUST),(4,12,2,3,WOOD),(10,12,2,3,WOOD)])
prop('filing_cabinet','Brass Filing Cabinet',[(3,1,10,14,D),(4,2,8,12,IRON),(4,2,8,1,SHINE),(5,4,6,1,D),(5,8,6,1,D),(5,12,6,1,D),(7,3,2,1,BRASS),(7,7,2,1,BRASS),(7,11,2,1,BRASS)])
prop('bookshelf','Case Archive Bookshelf',[(2,1,12,14,D),(3,2,10,12,WOOD),(3,7,10,1,BRASS),(3,13,10,1,BRASS),(4,3,2,4,RUST),(7,2,2,5,BLUE),(10,3,2,4,GOLD),(4,9,2,4,BLUE),(7,9,2,4,RUST),(10,10,2,3,WHI)])
prop('evidence_board','Detective Evidence Board',[(1,2,14,12,D),(2,3,12,10,WOOD),(3,4,4,3,WHI),(9,4,3,4,WHI),(5,9,5,3,WHI),(6,6,5,1,RUST),(7,7,1,3,RUST),(4,4,1,1,GOLD),(10,4,1,1,GOLD),(7,9,1,1,GOLD)])
prop('typewriter','Brass Typewriter',[(5,1,7,5,WHI),(6,2,5,1,IRON),(6,4,4,1,IRON),(3,6,10,5,D),(4,7,8,3,IRON),(1,11,14,3,D),(2,12,12,1,BRASS),(3,12,1,1,WHI),(6,12,1,1,WHI),(9,12,1,1,WHI),(12,12,1,1,WHI)])
prop('telephone','Clockwork Telephone',[(3,2,10,3,D),(4,2,8,1,BRASS),(2,3,3,3,D),(11,3,3,3,D),(7,5,2,5,BRASS),(4,9,8,5,D),(5,10,6,3,IRON),(6,10,4,3,BRASS),(7,11,2,1,D)])
prop('safe','Detective Evidence Safe',[(2,2,12,13,D),(3,3,10,11,IRON),(4,4,8,9,D),(5,5,6,7,IRON),(7,7,3,3,BRASS),(8,8,1,1,D),(4,5,1,2,SHINE),(4,10,1,2,SHINE)])
prop('magnifying_glass','Brass Magnifying Glass',[(3,2,7,2,BRASS),(1,4,2,5,BRASS),(3,9,7,2,BRASS),(10,4,2,5,BRASS),(3,4,7,5,GLASS),(4,4,2,2,BLUE),(10,10,2,2,WOOD),(12,12,2,3,WOOD)])
prop('pocket_watch','Detective Pocket Watch',[(7,1,2,2,BRASS),(4,3,8,10,D),(3,5,10,6,BRASS),(5,4,6,8,BRASS),(5,5,6,6,WHI),(7,6,1,3,D),(7,8,3,1,D),(12,3,2,1,GOLD),(14,4,1,4,GOLD)])
prop('case_file','Confidential Case File',[(2,4,12,9,D),(3,5,10,7,BRASS),(3,2,6,3,BRASS),(5,6,6,1,WHI),(5,8,4,1,WHI),(9,10,2,1,RUST)])
prop('newspaper','Detective Newspaper',[(2,2,12,12,D),(3,3,10,10,WHI),(4,4,8,2,IRON),(4,7,3,3,BLUE),(8,7,4,1,IRON),(8,9,4,1,IRON),(4,11,8,1,IRON)])
prop('footprints','Suspicious Boot Prints',[(3,2,3,5,D),(3,8,3,2,D),(9,6,3,5,D),(9,12,3,2,D),(4,3,1,3,IRON),(10,7,1,3,IRON)])
prop('evidence_vial','Evidence Sample Vial',[(6,1,4,3,BRASS),(5,4,6,10,D),(6,5,4,8,GLASS),(6,9,4,4,'83b6ad'),(6,5,1,5,'c2dbd1'),(7,7,2,2,WHI)])
prop('detective_hat','Detective Fedora',[(4,4,8,6,D),(5,5,6,4,WOOD),(4,8,8,2,BRASS),(1,10,14,2,D),(2,10,12,1,WOOD)])
prop('umbrella','Rainy Street Umbrella',[(5,1,6,2,D),(3,3,10,2,D),(1,5,14,3,D),(2,5,12,2,BLUE),(7,2,2,5,GLASS),(7,8,1,6,BRASS),(8,14,3,1,BRASS),(10,12,1,2,BRASS)])
prop('briefcase','Detective Briefcase',[(5,3,6,3,D),(6,4,4,1,BRASS),(2,6,12,8,D),(3,7,10,6,WOOD),(3,9,10,1,BRASS),(7,9,2,2,GOLD)])
prop('camera','Clockwork Evidence Camera',[(4,3,5,3,D),(5,4,3,1,BRASS),(2,6,12,7,D),(3,7,10,5,IRON),(6,7,5,5,BRASS),(7,8,3,3,GLASS),(8,8,1,1,SHINE),(3,7,2,1,WHI)])
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
Path('/private/tmp/picell-steampunk-detective.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 steampunk detective templates')
