"""Create original 32×16 steampunk scenic backgrounds."""
import json, random, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
items=[]
D='293044';B='be955b';G='e8c88c';I='596a78';S='96a6ad';R='a7674e';L='62896c';H='91af70'
class Scene:
 def __init__(self,sky):self.p=[0xff000000|int(sky,16)]*512
 def rect(self,x,y,w,h,c):
  for yy in range(max(0,y),min(16,y+h)):
   for xx in range(max(0,x),min(32,x+w)):self.p[yy*32+xx]=0xff000000|int(c,16)
 def save(self,id,name):
  f='steampunk_background_'+id+'_32x16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name=name+' · 32×16',category='Background',is_pro=False,width=32,height=16,pixels=self.p),separators=(',',':'))+'\n');items.append((f,self.p))
def cloud(t,x,y,c):t.rect(x,y,6,2,c);t.rect(x+2,y-1,3,1,c)
def skyline(t,c,seed):
 r=random.Random(seed)
 for x in range(0,32,4):
  h=r.randrange(3,9);t.rect(x,16-h,3,h,c)
def windows(t,x,y,w,h):
 for yy in range(y,y+h,3):
  for xx in range(x,x+w,3):t.rect(xx,yy,1,1,G)
t=Scene('ab826f');t.rect(0,7,32,5,'bf9b7b');cloud(t,2,3,'dac3a0');cloud(t,19,2,'dac3a0');skyline(t,'796d70',1)
for x,y in [(2,7),(12,4),(25,6)]:t.rect(x,y,5,10,D);t.rect(x+1,y-2,2,2,D);windows(t,x+1,y+2,4,8)
t.rect(0,14,32,2,D);t.save('sunset_foundry','Sunset Foundry Skyline')
t=Scene('34465f');t.rect(24,1,3,3,'d8cbb0');skyline(t,'465568',2)
for x,y in [(0,6),(10,5),(22,7)]:t.rect(x,y,7,10,D);windows(t,x+1,y+2,6,8)
t.rect(0,14,32,2,I)
for x in [5,18,29]:t.rect(x,8,1,7,B);t.rect(x-1,7,3,2,G);t.rect(x,15,4,1,'8c826c')
t.save('rainy_city','Rainy Gaslit City')
t=Scene('718387');cloud(t,1,4,'bac4b6');cloud(t,19,2,'bac4b6');skyline(t,'566773',3);t.rect(0,12,32,4,D)
for x in [1,11,23]:t.rect(x,7,7,7,I);t.rect(x+1,8,5,4,R);t.rect(x+2,8,3,1,G);t.rect(x+5,2,2,6,D);cloud(t,x+4,1,'bac4b6')
t.save('steam_rooftops','Steam Over Rooftops')
t=Scene('a1b7a7');t.rect(0,10,32,6,L)
for x in range(1,32,6):t.rect(x,6,4,6,'486a5d');t.rect(x+1,4,2,3,H)
for x,y in [(3,3),(16,1)]:
 t.rect(x,y+3,11,9,'719b92');t.rect(x,y+3,1,9,B);t.rect(x+10,y+3,1,9,B);t.rect(x,y+8,11,1,B)
 for n in range(4):t.rect(x+5-n,y+n,2*n+1,1,B)
 t.rect(x+5,y+4,1,8,B)
t.rect(0,14,32,2,D);t.save('conservatory','Brass Garden Conservatory')
t=Scene('6c887d')
for x in [1,8,18,27]:t.rect(x,0,2,14,'496259');t.rect(x-2,2,6,4,'577766')
for x,y in [(4,5),(13,3),(25,6)]:t.rect(x,y,2,11,'634d43');t.rect(x-3,y-3,8,4,L);t.rect(x-2,y-3,6,1,H);t.rect(x,y+5,3,1,R)
t.rect(0,14,32,2,'354f4e');t.rect(18,14,10,1,'507b80');t.save('copper_forest','Copper Root Forest')
t=Scene('485260');t.rect(0,5,32,1,I);t.rect(0,12,32,4,D)
for x in [2,15,27]:t.rect(x,0,2,13,I);t.rect(x,1,1,11,B)
for x in [5,19]:t.rect(x,6,9,7,B);t.rect(x+1,7,7,5,R);t.rect(x+3,8,3,2,G);t.rect(x+2,4,5,2,I)
t.rect(0,2,32,2,R);t.rect(0,2,32,1,G);t.save('boiler_hall','Grand Boiler Hall')
t=Scene('96755e');t.rect(0,0,32,1,B);t.rect(0,13,32,3,'634d43')
for x in [2,11]:t.rect(x,3,7,9,D);t.rect(x+1,4,5,7,'416676');t.rect(x+3,4,1,7,B);t.rect(x+1,7,5,1,B)
t.rect(21,2,9,9,D);t.rect(22,3,7,7,B);t.rect(23,4,2,2,'d8cbb0');t.rect(26,7,2,2,'d8cbb0');t.rect(6,11,19,2,D);t.rect(8,13,2,3,D);t.rect(21,13,2,3,D);t.save('detective_office','Gaslit Detective Office')
t=Scene('667783');skyline(t,'526472',4);t.rect(0,11,32,5,'416676');t.rect(0,10,32,1,B)
for x in [4,16,27]:t.rect(x,5,2,7,D);t.rect(x-2,6,6,1,D)
t.rect(8,9,10,2,D);t.rect(10,7,6,2,R);t.rect(12,5,2,2,I)
for x in [2,10,20,28]:t.rect(x,13,3,1,'719b92')
t.save('canal','Copper Canal Dock')
t=Scene('82918c');cloud(t,20,2,'b8bba7');t.rect(0,12,32,4,'a1b7a7');t.rect(0,11,32,2,D)
for x in [3,15,27]:t.rect(x,4,2,9,I);t.rect(x-1,4,4,1,B)
for x in range(3,28):
 y=4+min(x-3,27-x)//4;t.rect(x,y,1,1,B)
t.rect(0,10,32,1,G);t.save('sky_bridge','Suspended Brass Sky Bridge')
t=Scene('8e715f');t.rect(0,3,32,9,'765b50');t.rect(0,12,32,4,'493f3e')
for x in [1,12,23]:
 t.rect(x,4,8,8,D)
 for y in [7,11]:t.rect(x,y,8,1,B)
 for xx,c in [(1,R),(3,L),(5,G)]:t.rect(x+xx,5,1,2,c);t.rect(x+xx,9,1,2,c)
t.rect(5,1,22,1,B);t.rect(15,2,1,2,B);t.rect(13,3,5,2,G);t.save('archive','Clockwork Archive Library')
t=Scene('9aab9c');t.rect(0,10,32,6,L);t.rect(0,13,32,2,'507b80');t.rect(0,13,32,1,'8cb7ae');t.rect(24,4,2,8,B);t.rect(22,4,6,1,B)
for x,y in [(4,7),(15,5)]:t.rect(x,y,2,7,'634d43');t.rect(x-2,y-2,6,3,L);t.rect(x-1,y-2,4,1,H)
t.rect(23,8,6,5,D);t.rect(24,9,4,3,B);t.rect(25,10,2,1,D);t.save('water_garden','Water Wheel Garden')
t=Scene('394759');t.rect(0,12,32,4,D);t.rect(1,4,13,9,I);t.rect(3,6,9,5,B);t.rect(5,7,5,3,'d8cbb0');t.rect(7,7,1,3,D);t.rect(7,9,3,1,D);t.rect(18,3,2,10,B);t.rect(20,3,8,2,B);t.rect(26,5,2,7,I);t.rect(24,7,6,4,R);t.rect(25,8,4,2,G);t.rect(0,1,32,1,I);t.save('clock_tower','Clock Tower Interior')
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 data=json.loads(ROOT.joinpath(f).read_text());assert data['width']==32 and data['height']==16 and len(p)==512 and all(c>>24==255 for c in p)
assert len(index)==len(set(index));ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n')
cols=3;cw=192;ch=96;w=cols*cw;h=((len(items)+cols-1)//cols)*ch;raw=bytearray()
for y in range(h):
 raw.append(0)
 for x in range(w):
  n=y//ch*cols+x//cw;c=items[n][1][(y%ch//6)*32+x%cw//6];raw.extend([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
Path('/private/tmp/picell-backgrounds32x16.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'32×16 backgrounds')
