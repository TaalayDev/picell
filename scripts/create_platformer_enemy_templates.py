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
def enemy(id,name,rects):
 t=Tile()
 for x,y,w,h,c in rects:t.rect(x,y,w,h,c)
 t.save('enemy_'+id,name,'Character')
enemy('slime','Meadow Slime',[(4,5,8,2,D),(2,7,12,6,D),(3,7,10,5,'5e9c6f'),(5,6,6,2,'9aca88'),(5,9,2,2,D),(10,9,2,2,D),(6,12,5,1,'3e6a57')])
enemy('beetle','Shell Beetle',[(5,4,6,9,D),(6,5,4,7,'cb755e'),(7,5,1,6,'f0ad80'),(3,6,2,1,D),(11,6,2,1,D),(3,10,2,1,D),(11,10,2,1,D),(5,2,1,3,D),(10,2,1,3,D),(6,11,1,1,'ffe09b'),(9,11,1,1,'ffe09b')])
enemy('snail','Trail Snail',[(2,10,12,4,D),(3,11,10,2,'88b39a'),(5,4,8,7,D),(6,5,6,5,'b88461'),(7,6,4,1,'edba7f'),(9,7,2,2,'76513f'),(2,8,1,3,'88b39a'),(4,8,1,3,'88b39a'),(2,8,1,1,D),(4,8,1,1,D)])
enemy('caterpillar','Leaf Caterpillar',[(2,7,12,6,D),(3,8,10,4,'78ac72'),(3,8,2,3,'bed58b'),(6,8,2,3,'a2c37e'),(9,8,2,3,'a2c37e'),(3,10,1,1,D),(3,13,2,1,D),(7,13,2,1,D),(11,13,2,1,D),(2,5,1,3,D),(5,5,1,3,D)])
enemy('bee','Angry Bee',[(3,6,10,7,D),(4,7,8,5,'e5b95a'),(6,7,2,5,D),(10,7,2,5,D),(3,3,4,3,'c4dedc'),(9,3,4,3,'c4dedc'),(4,4,2,1,'eef1dd'),(10,4,2,1,'eef1dd'),(3,8,1,1,D),(1,9,2,1,D),(12,11,2,1,D)])
enemy('bat','Night Bat',[(1,4,3,5,D),(12,4,3,5,D),(2,5,4,5,'695879'),(10,5,4,5,'695879'),(5,5,6,7,D),(6,6,4,5,'92809b'),(5,3,2,3,D),(9,3,2,3,D),(6,7,1,1,'ffe09b'),(9,7,1,1,'ffe09b')])
enemy('bird','Sky Bird',[(5,5,7,7,D),(6,6,5,5,'779fc0'),(7,5,3,3,'b5d5d8'),(9,6,1,1,D),(11,7,3,2,'e5b95a'),(2,6,4,4,'527c9a'),(3,5,2,2,'b5d5d8'),(6,12,1,2,'e5b95a'),(9,12,1,2,'e5b95a')])
enemy('hopper','Meadow Hopper',[(4,5,8,8,D),(5,6,6,6,'668c77'),(3,3,4,4,D),(9,3,4,4,D),(4,4,2,2,'e5b95a'),(10,4,2,2,'e5b95a'),(5,9,6,1,'a2c37e'),(2,11,3,3,'668c77'),(11,11,3,3,'668c77')])
enemy('walking_mushroom','Walking Mushroom',[(4,3,8,2,D),(2,5,12,4,D),(3,5,10,3,'c46e88'),(5,4,6,3,'e59c9e'),(4,6,2,1,'ffe09b'),(10,6,1,1,'ffe09b'),(6,9,4,4,'ddc9aa'),(6,10,1,1,D),(9,10,1,1,D),(4,13,3,2,D),(9,13,3,2,D)])
enemy('rolling_spike','Rolling Spike Orb',[(4,4,8,8,D),(5,5,6,6,'748b99'),(6,6,4,4,'a9bec4'),(7,1,2,3,'dce7d9'),(7,12,2,3,'dce7d9'),(1,7,3,2,'dce7d9'),(12,7,3,2,'dce7d9'),(3,3,2,2,'dce7d9'),(11,11,2,2,'dce7d9'),(7,7,2,2,D)])
enemy('walker_robot','Patrol Robot',[(4,2,8,7,D),(5,3,6,5,'8fabb2'),(6,4,4,2,'40546c'),(7,4,2,1,'98dfd1'),(5,9,6,4,'627d91'),(2,9,3,3,'8fabb2'),(11,9,3,3,'8fabb2'),(5,13,2,2,D),(9,13,2,2,D),(7,10,2,2,'edba7f')])
enemy('hover_drone','Hover Drone',[(4,4,8,7,D),(5,5,6,5,'788ba5'),(6,6,4,2,'e593a2'),(2,5,2,4,'a7b9c9'),(12,5,2,4,'a7b9c9'),(6,11,4,1,'e5b95a'),(7,13,2,2,'edba7f'),(7,2,2,2,'a7b9c9')])
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
Path('/private/tmp/picell-platformer-enemies.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 platformer templates')
