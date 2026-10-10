"""Create original 16px steampunk enemy templates."""
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
def enemy(id,name,rects):
 t=Tile()
 for x,y,w,h,c in rects:t.rect(x,y,w,h,c)
 t.save('enemy_'+id,name,'Character')

B='be955b';G='e8c88c';I='596a78';S='96a6ad';R='a7674e';E='73ded3'
enemy('clockwork_guard','Clockwork Guard',[(5,1,6,7,D),(6,2,4,5,B),(6,3,4,2,D),(6,3,1,1,E),(9,3,1,1,E),(4,8,8,5,D),(5,9,6,3,I),(7,9,2,2,G),(2,8,2,4,B),(12,8,2,4,B),(4,13,3,2,D),(9,13,3,2,D)])
enemy('boiler_brute','Boiler Brute',[(4,1,2,4,D),(5,1,1,3,S),(3,5,10,8,D),(4,6,8,6,B),(5,7,6,4,D),(6,8,4,2,R),(7,8,2,1,'ffc878'),(1,7,2,6,I),(13,7,2,6,I),(4,13,3,2,D),(9,13,3,2,D),(10,3,2,2,S)])
enemy('gear_crab','Gear Crab',[(4,5,8,7,D),(5,6,6,5,B),(6,7,4,3,I),(7,8,2,1,G),(1,3,3,4,B),(12,3,3,4,B),(2,7,3,2,I),(11,7,3,2,I),(2,11,3,2,D),(11,11,3,2,D),(4,13,2,1,B),(10,13,2,1,B),(6,5,1,1,E),(9,5,1,1,E)])
enemy('steam_drone','Steam Drone',[(2,2,12,1,D),(7,1,2,4,B),(4,5,8,7,D),(5,6,6,5,B),(6,7,4,2,D),(7,7,2,1,E),(1,6,3,3,I),(12,6,3,3,I),(6,12,4,1,I),(7,13,2,2,S)])
enemy('copper_wasp','Copper Wasp',[(1,3,5,3,S),(10,3,5,3,S),(2,3,3,1,'d4e1dc'),(11,3,3,1,'d4e1dc'),(3,6,10,6,D),(4,7,8,4,B),(6,7,2,4,I),(10,7,2,4,I),(3,8,1,1,E),(1,9,2,1,G),(12,11,2,2,G)])
enemy('rail_crawler','Rail Crawler',[(3,4,10,8,D),(4,5,8,6,R),(5,6,6,2,D),(6,6,4,1,E),(5,9,6,1,B),(2,12,12,3,D),(3,13,2,1,S),(7,13,2,1,S),(11,13,2,1,S),(11,2,2,3,I)])
enemy('tesla_sentinel','Tesla Sentinel',[(7,1,2,2,G),(4,3,8,1,B),(6,4,4,2,I),(4,6,8,1,G),(6,7,4,2,I),(3,9,10,4,D),(4,10,8,2,B),(6,10,4,1,E),(2,13,3,2,I),(11,13,3,2,I),(1,4,1,2,E),(14,6,1,2,E)])
enemy('saw_walker','Saw Walker',[(6,2,4,2,S),(4,4,8,7,D),(5,5,6,5,I),(6,6,4,3,B),(7,7,2,1,D),(2,6,2,3,S),(12,6,2,3,S),(4,3,2,2,S),(10,10,2,2,S),(5,11,2,3,B),(9,11,2,3,B),(3,14,4,1,D),(9,14,4,1,D)])
enemy('mechanical_rat','Mechanical Rat',[(3,6,3,3,D),(4,7,1,1,B),(2,9,10,4,D),(3,10,8,2,I),(5,9,5,2,B),(3,10,1,1,E),(1,11,2,1,G),(4,13,2,1,D),(9,13,2,1,D),(12,10,3,1,B),(14,8,1,3,B)])
enemy('clockwork_spider','Clockwork Spider',[(5,5,6,7,D),(6,6,4,5,B),(7,7,2,2,I),(6,10,1,1,E),(9,10,1,1,E),(2,4,3,1,I),(11,4,3,1,I),(1,5,1,3,B),(14,5,1,3,B),(2,8,3,1,I),(11,8,3,1,I),(1,9,1,4,B),(14,9,1,4,B),(3,12,2,2,I),(11,12,2,2,I)])
enemy('airship_scout','Airship Scout',[(4,2,8,1,D),(2,3,12,5,D),(3,3,10,4,B),(4,3,6,1,G),(4,5,8,1,R),(5,8,1,3,I),(10,8,1,3,I),(4,11,8,3,D),(5,12,6,1,I),(7,12,2,1,E),(1,9,3,1,B),(12,9,3,1,B)])
enemy('steam_knight','Steam Knight',[(5,1,6,7,D),(6,2,4,5,I),(6,3,4,1,S),(6,5,4,1,E),(4,8,8,5,D),(5,9,6,3,B),(7,9,2,2,I),(1,7,3,7,D),(2,8,1,5,B),(13,3,1,9,S),(12,10,3,1,G),(4,13,3,2,I),(9,13,3,2,I)])
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
Path('/private/tmp/picell-steampunk-enemies.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created and validated',len(items),'16×16 steampunk enemies')
