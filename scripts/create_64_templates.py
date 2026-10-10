"""Generate original, editable 64px templates using a deliberately small palette."""
import json, math, random, struct, zlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/data/templates'
class Art:
    def __init__(self, color=None): self.p=[self.color(color)]*4096
    def color(self,c): return 0 if c is None else 0xff000000|int(c.lstrip('#'),16)
    def dot(self,x,y,c):
        if 0<=x<64 and 0<=y<64:self.p[y*64+x]=self.color(c)
    def rect(self,x,y,w,h,c):
        for yy in range(y,y+h):
            for xx in range(x,x+w):self.dot(xx,yy,c)
    def line(self,x,y,u,v,c):
        n=max(abs(u-x),abs(v-y),1)
        for i in range(n+1):self.dot(round(x+(u-x)*i/n),round(y+(v-y)*i/n),c)
    def poly(self,points,c):
        for y in range(min(p[1] for p in points),max(p[1] for p in points)+1):
            crossings=[]
            for (x1,y1),(x2,y2) in zip(points,points[1:]+points[:1]):
                if (y1<=y<y2) or (y2<=y<y1):crossings.append(x1+(y-y1)*(x2-x1)/(y2-y1))
            crossings.sort()
            for a,b in zip(crossings[::2],crossings[1::2]):self.rect(math.ceil(a),y,math.floor(b)-math.ceil(a)+1,1,c)
    def disc(self,x,y,r,c):
        for yy in range(y-r,y+r+1):
            for xx in range(x-r,x+r+1):
                if (xx-x)**2+(yy-y)**2<=r*r:self.dot(xx,yy,c)
    def save(self,file,name,category):
        (OUT/file).write_text(json.dumps(dict(name=name,category=category,is_pro=False,width=64,height=64,pixels=self.p),separators=(',',':'))+'\n')
        return self
DARK='18223b'; GOLD='ffd884'; LIGHT='fff0c2'
arts=[]
def save(a,file,name,cat='Background'):
    a.save(file,name,cat);arts.append((file,a))
# A richly detailed, rainy storefront.
a=Art('18233f');a.rect(0,37,64,27,'28354f');a.rect(5,15,54,35,'101b31');a.rect(8,17,48,29,'775662');a.rect(12,23,40,21,'d28c73')
a.rect(14,25,36,17,'f6cb83');a.rect(28,25,2,17,DARK);a.rect(41,25,2,17,DARK)
a.rect(10,12,44,8,'b63b64');a.rect(13,14,38,4,'ef8a93')
for x in range(15,50,7):a.rect(x,14,3,3,LIGHT)
a.rect(7,21,50,3,'24273f');a.rect(9,45,46,4,'ad7977');a.rect(24,31,13,11,'483744');a.rect(26,32,9,7,'a97363');a.rect(26,40,9,2,GOLD)
for x in [17,45]:a.rect(x,28,3,2,'fff0c2');a.rect(x+1,30,1,7,'ab796c')
for x in range(8,57,6):a.line(x,51,x+3,51,'775662');a.line(x-3,55,x+2,55,'b37677')
a.rect(56,27,2,20,DARK);a.disc(57,25,4,GOLD);a.disc(57,24,2,LIGHT)
for x,y in [(3,5),(14,2),(25,6),(38,1),(53,4),(61,12),(3,24),(59,38)]:a.line(x,y,x-1,y+5,'637d9a')
save(a,'rainy_pixel_cafe_64.json','Rainy Pixel Cafe · 64×64')
# Mountain lake, layered silhouettes, dock and reflected moon.
a=Art('283356');a.rect(0,13,64,13,'586b87');a.disc(48,12,7,'f7d3a5');a.disc(50,10,6,'283356')
a.poly([(0,33),(13,13),(26,33),(38,19),(56,35),(64,23),(64,43),(0,43)],'344a67')
a.poly([(6,24),(13,13),(19,24),(14,21),(12,23),(10,21)],'b0c7cc');a.rect(0,39,64,25,'244957')
for y in range(42,64,4):
 for x in range((y*7)%9,64,13):a.rect(x,y,7,1,'477b87')
for y in range(43,58,3):a.rect(44-(y%4),y,8+(y%5),1,'a6b5a0')
for x in [3,8,58,63]:
 a.rect(x,28,2,16,DARK);a.poly([(x-5,39),(x+1,23),(x+7,39)],'182f3f')
a.poly([(11,60),(26,48),(36,48),(32,63)],'604844')
for y in [51,54,57,60]:a.line(16,y,32,y,'a58063')
a.rect(25,48,2,13,'ac8d67');a.rect(33,48,2,13,'ac8d67')
save(a,'moonlit_mountain_lake_64.json','Moonlit Mountain Lake · 64×64')
# Floating island and a miniature tower.
a=Art('b2ddd4');a.rect(0,40,64,24,'8ebbc2')
for x,y in [(1,12),(37,5),(43,30)]:a.rect(x,y,16,3,'e6f1d6');a.rect(x+4,y-2,8,2,'e6f1d6')
a.poly([(10,34),(53,34),(43,51),(28,59),(15,46)],'554c69');a.poly([(12,35),(32,38),(28,57),(18,44)],'82707d');a.poly([(9,30),(20,25),(45,25),(55,31),(51,36),(18,37)],'547e62');a.rect(18,28,29,4,'91b86e')
a.rect(27,15,15,15,'b4a187');a.rect(29,15,4,14,'dfc9a0');a.poly([(24,16),(34,5),(45,16)],'454465');a.rect(34,21,5,9,'4b4360');a.rect(30,18,3,3,GOLD)
a.rect(37,39,4,14,'74d0de');a.rect(39,40,2,15,'c0f2ec')
for x,y in [(17,29),(21,32),(47,30)]:a.dot(x,y,'f0b5af');a.dot(x+1,y,'fff0c2')
save(a,'floating_watchtower_64.json','Floating Watchtower · 64×64')
# Underwater ruins: coral, sunbeams and tiled masonry.
a=Art('19516a')
for y,c in [(16,'1d667b'),(35,'194c66'),(52,'163950')]:a.rect(0,y,64,64-y,c)
for x in [8,28,46]:a.poly([(x,0),(x+3,0),(x+18,52),(x+10,52)],'297287')
a.rect(9,46,46,7,'637a81');a.rect(15,28,6,19,'88a6a2');a.rect(43,28,6,19,'88a6a2');a.rect(12,25,40,5,'abc0ad');a.rect(18,20,28,5,'77968e');a.rect(21,17,22,3,'abc0ad')
for x in [15,43]:
 for y in range(31,47,4):a.rect(x+1,y,4,1,'536f7c')
for x in range(10,55,8):a.rect(x,48,5,1,'a0b5a3')
for x,y in [(5,53),(57,57),(10,60)]:
 a.line(x,y,x,y-11,'df7f8c');a.line(x,y-4,x-4,y-8,'df7f8c');a.line(x,y-6,x+4,y-11,'ffad98')
for x,y in [(30,34),(55,14),(8,30),(38,9)]:a.disc(x,y,2,'60a4b0');a.dot(x-1,y-1,'beddd3')
a.poly([(29,39),(34,35),(38,39),(34,42)],'edb45e');a.poly([(38,39),(41,36),(41,42)],'edb45e');a.dot(31,38,DARK)
save(a,'sunken_temple_64.json','Sunken Temple · 64×64')
# Transparent character sprites with bold silhouettes and clean clusters.
a=Art();a.disc(32,53,13,'26374a');a.rect(20,26,24,25,DARK);a.poly([(18,29),(23,17),(40,17),(46,30)],'214d57');a.rect(24,19,15,12,'6da89c');a.rect(27,24,12,9,'e0b386');a.rect(25,19,16,5,'417977');a.rect(28,25,9,3,DARK);a.dot(30,26,GOLD);a.rect(23,34,18,13,'4f8a7f');a.rect(24,36,5,10,'87bd9f');a.rect(22,45,21,3,'be9563');a.rect(23,48,7,10,'473b4c');a.rect(34,48,7,10,'473b4c');a.rect(21,56,10,4,DARK);a.rect(34,56,10,4,DARK)
a.line(46,22,46,53,'9b6b4e');a.disc(46,20,4,GOLD);a.disc(46,19,2,LIGHT);a.rect(40,35,6,5,'e0b386');a.rect(18,34,5,11,'34616a')
save(a,'lantern_ranger_64.json','Lantern Ranger · 64×64','Character')
a=Art();a.disc(32,55,16,'26374a');a.rect(20,12,25,23,DARK);a.rect(22,14,21,18,'a7cad0');a.rect(24,16,17,12,'416779');a.rect(26,20,5,4,'8af2d1');a.rect(35,20,4,4,'8af2d1');a.rect(28,28,9,2,DARK);a.rect(30,7,3,7,'608e9d');a.disc(31,6,3,'ffd884');a.rect(21,35,23,16,'719ead');a.rect(25,38,15,10,'365366');a.rect(28,40,9,5,'ffad75');a.rect(15,36,5,16,'a7cad0');a.rect(45,36,5,16,'a7cad0');a.rect(15,48,5,6,'416779');a.rect(45,48,5,6,'416779');a.rect(24,51,6,8,'608e9d');a.rect(36,51,6,8,'608e9d');a.rect(21,57,11,4,DARK);a.rect(34,57,11,4,DARK)
for x in [23,41]:a.dot(x,15,LIGHT);a.dot(x,31,'416779')
save(a,'copper_core_robot_64.json','Copper Core Robot · 64×64','Character')
index=json.loads((OUT/'index.json').read_text())
for file,_ in arts:
 if file not in index:index.append(file)
(OUT/'index.json').write_text(json.dumps(index,indent=1)+'\n')
# A lossless nearest-neighbor contact sheet for review, without image dependencies.
w,h=64*3*4,64*2*4; data=bytearray(w*h*3)
for n,(_,a) in enumerate(arts):
 for y in range(64):
  for x in range(64):
   c=a.p[y*64+x] or 0xffe2e4ec
   for dy in range(4):
    for dx in range(4):
     i=(((n//3)*256+y*4+dy)*w+(n%3)*256+x*4+dx)*3
     data[i:i+3]=bytes([(c>>16)&255,(c>>8)&255,c&255])
def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
raw=b''.join(b'\0'+data[y*w*3:(y+1)*w*3] for y in range(h))
Path('/private/tmp/picell-64-templates.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
print('Created',len(arts),'templates')
