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
for id,name,edges in [('ground_top','Grass Ground Top','n'),('ground_left','Grass Ground Left','w'),('ground_right','Grass Ground Right','e'),('ground_bottom','Ground Bottom','s'),('ground_nw','Grass Ground Northwest','nw'),('ground_ne','Grass Ground Northeast','ne'),('ground_sw','Ground Southwest','sw'),('ground_se','Ground Southeast','se')]:
 t=dirt()
 for e in edges:
  if e=='n':t.rect(0,0,16,4,GRASS);t.rect(0,0,16,1,HI);t.rect(0,4,16,1,'456a46');t.rect(2,4,2,2,GRASS);t.rect(10,4,2,2,GRASS)
  if e=='w':t.rect(0,0,1,16,D);t.rect(1,0,2,16,LIGHT)
  if e=='e':t.rect(15,0,1,16,D);t.rect(13,0,2,16,'674334')
  if e=='s':t.rect(0,14,16,2,D);t.rect(0,13,16,1,'674334')
 t.save(id,name)
dirt().save('dirt_fill','Dirt Fill');dirt(7).save('dirt_fill_b','Dirt Fill Alternate')
# Pixel slopes contain transparency above the terrain.
for id,name,up in [('slope_right','Grass Slope Rising Right',True),('slope_left','Grass Slope Rising Left',False)]:
 t=Tile();base=dirt()
 for x in range(16):
  y=15-x if up else x
  for yy in range(y,16):t.p[yy*16+x]=base.p[yy*16+x]
  t.dot(x,y,HI)
  if y+1<16:t.dot(x,y+1,GRASS)
 t.save(id,name)
for id,name,side in [('platform_left','Wood Platform Left','left'),('platform_mid','Wood Platform Middle','middle'),('platform_right','Wood Platform Right','right')]:
 t=Tile();t.rect(0,4,16,5,D);t.rect(0,4,16,1,LIGHT);t.rect(0,5,16,2,MID);t.rect(0,7,16,1,SOIL);t.rect(3,5,1,2,'674334');t.rect(11,5,1,2,'674334')
 if side=='left':t.rect(0,4,1,5,D);t.rect(1,5,1,2,LIGHT)
 if side=='right':t.rect(15,4,1,5,D)
 t.save(id,name)
t=Tile();t.rect(3,0,2,16,MID);t.rect(11,0,2,16,MID);t.rect(3,0,1,16,LIGHT)
for y in [2,7,12]:t.rect(5,y,6,2,LIGHT);t.rect(5,y+2,6,1,SOIL)
t.save('ladder','Wood Ladder')
t=Tile(D)
for row in range(2):
 for x in range(-4 if row else 0,16,8):t.rect(x+1,row*8+1,7,7,SOIL);t.rect(x+1,row*8+1,7,1,LIGHT);t.rect(x+1,row*8+2,6,4,MID)
t.save('brick_block','Brick Block')
t=Tile(D);t.rect(1,1,14,14,'dea658');t.rect(2,2,12,1,'ffe09b');t.rect(5,4,6,2,D);t.rect(9,5,2,4,D);t.rect(7,8,3,2,D);t.rect(7,12,2,2,D);t.dot(2,13,'9b653f');t.save('mystery_block','Mystery Block')
t=Tile();t.rect(0,13,16,3,D)
for x in [0,5,10]:
 for y in range(5,13):
  half=min(2,(y-5)//3);t.rect(x+2-half,y,half*2+1,1,'a5bcc5');t.dot(x+2-half,y,'dfebde')
t.save('spikes','Floor Spikes')
t=Tile('9b3e3d')
for y in [2,7,12]:
 for x in range((y//5%2)*3,16,8):t.rect(x,y,5,2,'e27c45');t.rect(x+1,y,3,1,'ffd27a')
t.save('lava','Lava Pool')
t=Tile('347992')
for y in [1,6,11]:
 for x in range((y//5%2)*4,16,8):t.rect(x,y,5,1,'8ac7ca')
t.save('water','Water Pool')
t=Tile();t.rect(4,2,8,12,D);t.rect(2,4,12,8,D);t.rect(4,3,8,10,'e6b353');t.rect(3,5,10,6,'e6b353');t.rect(5,3,5,1,'fff1ae');t.rect(7,5,2,6,'ac713f');t.rect(6,5,2,5,'ffe09b');t.save('coin','Collectible Coin','Object')
t=Tile();t.rect(6,1,4,13,D);t.rect(2,5,12,6,D);t.rect(5,3,6,9,'8d78c4');t.rect(3,6,10,4,'8d78c4');t.rect(7,3,2,8,'d5bdf1');t.dot(6,5,'fff1ae');t.save('gem','Collectible Gem','Object')
t=Tile();t.rect(3,4,4,2,D);t.rect(9,4,4,2,D);t.rect(2,6,12,5,D);t.rect(4,11,8,2,D);t.rect(6,13,4,1,D);t.rect(3,6,10,4,'d86780');t.rect(5,10,6,2,'d86780');t.rect(4,5,2,2,'f2a6a1');t.save('heart','Health Pickup','Object')
t=Tile();t.rect(4,1,2,14,D);t.rect(5,2,1,12,'a6b9b9');t.rect(6,2,7,5,'e7b95c');t.rect(6,2,7,1,'fff1ae');t.rect(6,6,4,1,'ac713f');t.rect(2,14,6,2,D);t.save('checkpoint','Checkpoint Flag','Object')
t=Tile();t.rect(2,7,12,6,'c3d6cd');t.rect(4,4,8,8,'e2ede0');t.rect(6,2,5,3,'e2ede0');t.rect(3,12,10,1,'8eafb7');t.save('cloud','Cloud Platform')
t=Tile();t.rect(2,3,12,11,D);t.rect(3,4,10,9,MID);t.rect(3,4,10,2,LIGHT);t.rect(3,11,10,2,LIGHT);t.rect(3,4,2,9,LIGHT);t.rect(11,4,2,9,LIGHT)
for i in range(7):t.rect(4+i,5+i,2,1,LIGHT)
t.save('crate','Platform Crate','Object')
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
Path('/private/tmp/picell-platformer.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
