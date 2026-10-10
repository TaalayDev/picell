"""Aligned 16×16 monster parts. Layer without repositioning."""
import json, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
D='293044';items=[];parts={}
def part(id,name,rects):
 p=[0]*256
 for x,y,w,h,c in rects:
  for yy in range(max(0,y),min(16,y+h)):
   for xx in range(max(0,x),min(16,x+w)):p[yy*16+xx]=0xff000000|int(c,16)
 f='monster_builder_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name='Monster Builder: '+name+' · 16×16',category='monster-builder',is_pro=False,width=16,height=16,pixels=p),separators=(',',':'))+'\n');items.append((f,p));parts[id]=p

for id,c,hi in [('moss','62896c','91af70'),('ember','a7674e','e4ae8e'),('night','695879','a18caf'),('ice','668d99','b5d5d8')]:
 part('body_'+id,id.title()+' Body',[(5,4,6,1,D),(4,5,8,8,D),(5,5,6,7,c),(6,5,4,1,hi),(6,12,4,1,c)])
 part('arms_'+id,id.title()+' Arms',[(2,7,2,6,D),(12,7,2,6,D),(2,8,2,4,c),(12,8,2,4,c),(2,8,1,2,hi),(12,8,1,2,hi)])
 part('feet_'+id,id.title()+' Feet',[(4,13,3,2,D),(9,13,3,2,D),(3,15,4,1,D),(9,15,4,1,D),(4,14,3,1,c),(9,14,3,1,c)])
part('body_slime','Slime Body',[(5,5,6,1,D),(3,6,10,7,D),(2,10,12,4,D),(4,6,8,6,'62896c'),(3,10,10,3,'62896c'),(5,6,5,1,'91af70')])
part('body_furry','Furry Body',[(4,4,8,1,D),(3,5,10,2,D),(4,7,8,6,D),(4,5,8,2,'986b4d'),(5,7,6,6,'986b4d'),(6,6,4,1,'be955b')])
part('body_stone','Stone Body',[(4,4,8,9,D),(5,5,6,7,'596a78'),(5,5,6,1,'96a6ad'),(8,6,1,3,D),(6,10,3,1,D)])
part('body_skeleton','Skeleton Body',[(5,4,6,5,D),(6,5,4,3,'d8cbb0'),(7,9,2,4,'d8cbb0'),(5,10,6,1,'d8cbb0'),(5,12,6,1,'d8cbb0')])
part('eyes_pair','Round Eyes',[(5,7,2,2,'d8cbb0'),(9,7,2,2,'d8cbb0'),(6,7,1,1,D),(9,7,1,1,D)])
part('eyes_angry','Angry Eyes',[(5,6,2,1,D),(9,6,2,1,D),(6,7,1,1,'e8c88c'),(9,7,1,1,'e8c88c')])
part('eye_cyclops','Cyclops Eye',[(6,6,4,1,D),(5,7,6,2,D),(6,7,4,2,'d8cbb0'),(7,7,2,2,'a7674e'),(8,7,1,1,D)])
part('eyes_four','Four Eyes',[(5,6,2,1,'e8c88c'),(9,6,2,1,'e8c88c'),(5,8,2,1,'e8c88c'),(9,8,2,1,'e8c88c')])
part('mouth_fangs','Fanged Mouth',[(6,10,4,2,D),(6,10,1,1,'d8cbb0'),(9,10,1,1,'d8cbb0')])
part('mouth_grin','Toothy Grin',[(5,10,6,2,D),(6,10,4,1,'d8cbb0'),(7,10,1,1,D),(9,10,1,1,D)])
part('mouth_beak','Monster Beak',[(6,9,4,2,'be955b'),(7,11,2,1,'e8c88c')])
part('mouth_tongue','Long Tongue',[(6,10,4,1,D),(7,11,2,3,'c46e88'),(8,13,2,1,'c46e88')])
part('horns_curved','Curved Horns',[(3,1,2,4,'be955b'),(4,3,2,2,'e8c88c'),(11,1,2,4,'be955b'),(10,3,2,2,'e8c88c')])
part('horn_single','Single Horn',[(7,0,2,4,'be955b'),(7,1,1,3,'e8c88c')])
part('ears_pointed','Pointed Ears',[(2,3,2,3,'62896c'),(3,4,2,2,'91af70'),(12,3,2,3,'62896c'),(11,4,2,2,'91af70')])
part('ears_round','Round Ears',[(2,3,3,3,'986b4d'),(3,4,1,1,'a7674e'),(11,3,3,3,'986b4d'),(12,4,1,1,'a7674e')])
part('antennae','Monster Antennae',[(5,1,1,4,'695879'),(10,1,1,4,'695879'),(4,0,3,1,'a18caf'),(9,0,3,1,'a18caf')])
part('crest','Feather Crest',[(5,2,2,3,'a7674e'),(7,0,2,5,'e4ae8e'),(9,2,2,3,'a7674e')])
part('wings_bat','Bat Wings',[(0,4,2,7,D),(2,6,2,6,D),(3,8,2,4,D),(1,5,1,5,'695879'),(2,7,2,4,'695879'),(14,4,2,7,D),(12,6,2,6,D),(11,8,2,4,D),(14,5,1,5,'695879'),(12,7,2,4,'695879')])
part('wings_feather','Feather Wings',[(0,5,3,3,'d8cbb0'),(1,8,3,3,'aa9b86'),(2,11,3,2,'d8cbb0'),(13,5,3,3,'d8cbb0'),(12,8,3,3,'aa9b86'),(11,11,3,2,'d8cbb0')])
part('tail_curl','Curled Tail',[(12,11,3,2,'62896c'),(14,7,1,5,'62896c'),(12,6,3,1,'91af70'),(12,7,1,2,'62896c')])
part('tail_spike','Spiked Tail',[(11,12,4,2,'a7674e'),(14,9,1,4,'a7674e'),(13,7,3,3,'e8c88c')])
part('arms_claws','Clawed Arms',[(2,7,2,5,'596a78'),(12,7,2,5,'596a78'),(1,12,1,2,'d8cbb0'),(3,12,1,2,'d8cbb0'),(12,12,1,2,'d8cbb0'),(14,12,1,2,'d8cbb0')])
part('arms_tentacles','Tentacle Arms',[(2,8,2,4,'695879'),(0,11,3,2,'695879'),(0,9,1,3,'a18caf'),(12,8,2,4,'695879'),(13,11,3,2,'695879'),(15,9,1,3,'a18caf')])
part('feet_talons','Taloned Feet',[(4,13,3,2,'be955b'),(9,13,3,2,'be955b'),(3,15,1,1,'d8cbb0'),(5,15,1,1,'d8cbb0'),(10,15,1,1,'d8cbb0'),(12,15,1,1,'d8cbb0')])
part('feet_tentacles','Tentacle Feet',[(5,13,2,2,'695879'),(9,13,2,2,'695879'),(3,15,4,1,'a18caf'),(9,15,4,1,'a18caf')])
part('belly','Golden Belly Patch',[(6,9,4,4,'be955b'),(7,9,2,1,'e8c88c')])
part('scales','Scale Markings',[(5,5,2,1,'91af70'),(9,5,2,1,'91af70'),(7,9,2,1,'91af70'),(5,11,2,1,'91af70'),(9,11,2,1,'91af70')])
part('spots','Purple Spots',[(5,5,2,1,'695879'),(10,6,1,1,'695879'),(5,9,1,2,'695879'),(9,12,2,1,'695879')])
part('armor','Monster Armor',[(5,9,6,4,'596a78'),(5,9,6,1,'96a6ad'),(7,10,2,2,'be955b')])
part('crown','Monster Crown',[(4,1,2,3,'be955b'),(7,0,2,4,'be955b'),(10,1,2,3,'be955b'),(4,4,8,1,'e8c88c'),(7,3,2,1,'a7674e')])
index=json.loads(ROOT.joinpath('index.json').read_text())
for f,p in items:
 if f not in index:index.append(f)
 data=json.loads(ROOT.joinpath(f).read_text());assert data['width']==data['height']==16 and len(p)==256 and all(0<=c<=0xffffffff for c in p)
assert len(index)==len(set(index));ROOT.joinpath('index.json').write_text(json.dumps(index,indent=1)+'\n')
def png(path,tiles,cols):
 cell=96;w=cols*cell;h=((len(tiles)+cols-1)//cols)*cell;raw=bytearray()
 for y in range(h):
  raw.append(0)
  for x in range(w):
   n=y//cell*cols+x//cell;c=tiles[n][(y%cell//6)*16+x%cell//6] if n<len(tiles) else 0
   c=c or (0xffe5e6ee if (x//12+y//12)%2 else 0xffd7dae5);raw.extend([(c>>16)&255,(c>>8)&255,c&255])
 def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b))
 Path(path).write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
png('/private/tmp/picell-monster-builder-parts.png',[p for f,p in items],8)

recipes=[['wings_bat','tail_curl','feet_moss','body_moss','arms_moss','eyes_pair','mouth_fangs','horns_curved'],['feet_ember','body_ember','arms_claws','eyes_angry','mouth_grin','crest'],['wings_feather','feet_talons','body_ice','arms_ice','eyes_pair','mouth_beak','horn_single'],['feet_tentacles','body_night','arms_tentacles','eye_cyclops','mouth_tongue','antennae'],['feet_moss','body_slime','eyes_pair','mouth_grin','crown'],['feet_ember','body_furry','arms_ember','eyes_four','mouth_fangs','ears_round']]
examples=[]
for recipe in recipes:
 p=[0]*256
 for id in recipe:p=[b or a for a,b in zip(p,parts[id])]
 examples.append(p)
png('/private/tmp/picell-monster-builder-examples.png',examples,6)
Path('assets/data/templates/monster_builder_guide.md').write_text("# Monster Builder (16×16)\n\nLayer transparent parts at x=0, y=0 without cropping. All parts share a front-facing pose. Suggested order: wings/tail → feet → body → arms → belly/markings/armor → eyes → mouth → ears/horns/crest → crown. Choose one part per slot; ears, horns and crests can overlap. Faces align to eyes at rows 6–8 and mouths at rows 9–11. Bodies occupy rows 4–12 and feet rows 13–15. These are static parts, not animation frames.\n")
print('Created and validated',len(items),'monster parts and six assembled previews')
