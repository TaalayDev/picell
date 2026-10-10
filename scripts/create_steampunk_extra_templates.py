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
# New pipe connections match the original six-pixel pipe ports.
for id,name,dirs in [('pipe_nw','Copper Elbow Northwest','nw'),('pipe_se','Copper Elbow Southeast','se'),('pipe_sw','Copper Elbow Southwest','sw'),('pipe_t_n','Copper T North','new'),('pipe_t_s','Copper T South','sew'),('pipe_t_e','Copper T East','nse'),('pipe_t_w','Copper T West','nsw')]:
 t=Tile();t.rect(5,5,6,6,D)
 for d in dirs:
  if d=='n':t.rect(5,0,6,8,D);t.rect(6,0,4,8,RUST);t.rect(6,0,1,8,GOLD)
  if d=='s':t.rect(5,8,6,8,D);t.rect(6,8,4,8,RUST);t.rect(6,8,1,8,GOLD)
  if d=='e':t.rect(8,5,8,6,D);t.rect(8,6,8,4,RUST);t.rect(8,6,8,1,GOLD)
  if d=='w':t.rect(0,5,8,6,D);t.rect(0,6,8,4,RUST);t.rect(0,6,8,1,GOLD)
 t.rect(6,6,4,4,RUST);t.dot(6,6,GOLD);t.save(id,name)
for id,name,cap in [('hazard_plate','Hazard Stripe Panel',True),('steel_grate','Steel Grate Floor',False)]:
 t=plate()
 if cap:
  for x in range(-2,16,6):
   for y in range(3):t.rect(x+y,y,3,1,GOLD)
 else:
  t.rect(3,3,10,10,D)
  for x in [4,7,10]:t.rect(x,3,1,10,SHINE)
  t.rect(3,6,10,1,IRON);t.rect(3,10,10,1,IRON)
 t.save(id,name)
t=plate();t.rect(3,3,10,10,D);t.rect(4,4,8,8,'638e99');t.rect(4,4,2,6,'b0d6d2');t.rect(10,9,2,3,'406477');t.save('glass_panel','Factory Glass Panel')
t=Tile();t.rect(2,0,3,16,BRASS);t.rect(11,0,3,16,BRASS);t.rect(2,0,1,16,GOLD);t.rect(0,2,16,3,IRON);t.rect(0,11,16,3,IRON);t.rect(0,2,16,1,SHINE);t.rect(0,11,16,1,SHINE);t.save('scaffold','Factory Scaffold')
# Transparent factory props.
def prop(id,name,rects):
 t=Tile()
 for x,y,w,h,c in rects:t.rect(x,y,w,h,c)
 t.save(id,name,'Object')
prop('valve','Red Steam Valve',[(6,2,4,12,D),(2,6,12,4,D),(7,3,2,10,'bd6570'),(3,7,10,2,'bd6570'),(6,6,4,4,BRASS),(7,7,2,2,GOLD)])
prop('chimney','Factory Chimney',[(5,4,6,12,D),(6,5,4,11,RUST),(4,3,8,2,IRON),(5,3,6,1,SHINE),(6,7,4,1,'6d513c'),(6,11,4,1,'6d513c'),(7,0,3,2,'a7b9c4')])
prop('steam_vent','Steam Vent',[(2,11,12,4,D),(3,12,10,2,IRON),(4,12,1,2,SHINE),(7,12,1,2,SHINE),(10,12,1,2,SHINE),(5,6,2,4,'91aeb4'),(8,2,2,5,'c1d5cd'),(6,0,2,2,'91aeb4')])
prop('tank','Copper Storage Tank',[(4,2,8,12,D),(5,3,6,10,RUST),(5,3,1,9,GOLD),(3,5,10,2,IRON),(3,10,10,2,IRON),(4,14,2,2,D),(10,14,2,2,D)])
prop('control_box','Factory Control Box',[(2,3,12,11,D),(3,4,10,9,IRON),(4,5,8,4,D),(5,6,6,2,'81c7c6'),(4,11,2,1,GOLD),(7,11,2,1,'bd6570'),(10,11,2,1,'9aba85')])
prop('battery','Copper Battery',[(6,1,4,2,SHINE),(4,3,8,12,D),(5,4,6,10,BRASS),(6,5,4,7,'81c7c6'),(7,6,2,2,GOLD),(6,8,3,1,GOLD),(7,9,1,2,GOLD)])
prop('engine','Steam Engine Block',[(3,4,10,8,D),(4,5,8,6,IRON),(5,6,6,1,SHINE),(5,8,6,1,SHINE),(2,6,2,4,BRASS),(12,6,2,4,BRASS),(4,12,3,3,D),(9,12,3,3,D),(6,1,4,3,RUST)])
prop('wheel','Flywheel',[(4,2,8,12,D),(2,4,12,8,D),(5,3,6,10,BRASS),(3,5,10,6,BRASS),(5,5,6,6,D),(7,3,2,10,GOLD),(3,7,10,2,GOLD),(6,6,4,4,IRON)])
prop('hanging_lamp','Factory Hanging Lamp',[(7,0,2,5,IRON),(4,5,8,2,D),(3,7,10,6,D),(4,8,8,4,GOLD),(5,8,3,2,'fff1ae'),(4,13,8,1,IRON)])
prop('coal_cart','Coal Mine Cart',[(2,6,12,7,D),(3,7,10,5,IRON),(3,6,10,2,'454052'),(5,4,3,3,D),(9,5,3,2,D),(4,13,3,3,D),(9,13,3,3,D),(5,14,1,1,SHINE),(10,14,1,1,SHINE)])
prop('toolbox','Copper Toolbox',[(5,2,6,4,D),(6,3,4,2,BRASS),(2,6,12,8,D),(3,7,10,6,RUST),(3,7,10,1,GOLD),(7,9,2,3,SHINE)])
prop('warning_sign','Factory Warning Sign',[(7,9,2,6,IRON),(2,2,12,8,D),(3,3,10,6,GOLD),(7,4,2,3,D),(7,8,2,1,D)])
prop('hanging_hook','Crane Hook',[(7,0,2,8,IRON),(6,8,4,3,SHINE),(9,10,2,4,SHINE),(5,13,6,2,SHINE),(4,10,2,4,SHINE),(4,9,2,2,GOLD)])
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
Path('/private/tmp/picell-steampunk-extra.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
