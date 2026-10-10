"""Aligned 16×16 front-facing character parts. Layer without repositioning."""
import json, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/data/templates'
D='293044';items=[];parts={}
def part(id,name,rects):
 p=[0]*256
 for x,y,w,h,c in rects:
  for yy in range(max(0,y),min(16,y+h)):
   for xx in range(max(0,x),min(16,x+w)):p[yy*16+xx]=0xff000000|int(c,16)
 f='character_builder_'+id+'_16.json';ROOT.joinpath(f).write_text(json.dumps(dict(name='Character Builder: '+name+' · 16×16',category='character-builder',is_pro=False,width=16,height=16,pixels=p),separators=(',',':'))+'\n');items.append((f,p));parts[id]=p
for tone,c,shadow in [('light','e8bc98','b78167'),('medium','bd8866','8b5e49'),('deep','805943','553b34')]:
 part('head_'+tone,'Head '+tone.title(),[(5,2,6,1,D),(4,3,8,4,D),(5,3,6,4,c),(6,7,4,1,shadow),(7,8,2,1,c)])
 part('arms_'+tone,'Arms '+tone.title(),[(3,9,2,4,D),(11,9,2,4,D),(3,10,2,2,c),(11,10,2,2,c)])
part('face_calm','Calm Face',[(6,4,1,1,D),(9,4,1,1,D),(7,6,2,1,'a7674e')])
part('face_smile','Smiling Face',[(6,4,1,1,D),(9,4,1,1,D),(6,6,1,1,D),(9,6,1,1,D),(7,7,2,1,D)])
part('face_stern','Stern Face',[(5,3,2,1,D),(9,3,2,1,D),(6,4,1,1,D),(9,4,1,1,D),(7,6,2,1,D)])
for color,c,hi in [('brown','694d43','986b4d'),('black','35404d','596a78'),('blond','be955b','e8c88c'),('red','a7674e','d99b70')]:
 part('hair_short_'+color,'Short Hair '+color.title(),[(5,1,6,1,D),(4,2,8,2,c),(4,4,1,2,c),(11,4,1,2,c),(5,2,5,1,hi)])
 part('hair_long_'+color,'Long Hair '+color.title(),[(4,1,8,1,D),(3,2,10,2,c),(3,4,2,5,c),(11,4,2,5,c),(4,2,6,1,hi),(3,8,2,1,D),(11,8,2,1,D)])
part('hair_mohawk','Copper Mohawk',[(7,0,2,4,'a7674e'),(7,0,1,3,'e8c88c')])
part('beard','Brown Beard',[(5,6,1,1,'694d43'),(10,6,1,1,'694d43'),(6,7,4,1,'694d43')])
for id,name,c,hi in [('shirt_green','Green Shirt','62896c','91af70'),('shirt_blue','Blue Shirt','507b80','8cb7ae'),('shirt_red','Red Shirt','a7674e','d99b70'),('shirt_cream','Cream Shirt','aa9b86','d8cbb0')]:
 part(id,name,[(5,8,6,5,D),(5,9,6,3,c),(3,8,2,2,c),(11,8,2,2,c),(6,9,4,1,hi)])
part('vest','Brass Button Vest',[(5,9,2,3,'694d43'),(9,9,2,3,'694d43'),(6,10,1,1,'be955b'),(9,10,1,1,'be955b')])
part('coat','Detective Coat',[(4,8,2,5,'694d43'),(10,8,2,5,'694d43'),(3,8,2,2,'694d43'),(11,8,2,2,'694d43'),(5,9,1,3,'986b4d'),(10,9,1,3,'986b4d')])
part('armor','Iron Breastplate',[(5,8,6,5,D),(5,9,6,3,'596a78'),(6,9,4,1,'96a6ad'),(7,10,2,2,'be955b'),(3,8,2,2,'596a78'),(11,8,2,2,'596a78')])
for id,name,c in [('pants_dark','Dark Trousers','485060'),('pants_brown','Brown Trousers','694d43'),('pants_blue','Blue Trousers','507b80')]:
 part(id,name,[(5,12,6,1,D),(5,13,2,2,c),(9,13,2,2,c),(7,13,2,2,D)])
part('skirt','Green Skirt',[(5,12,6,1,'62896c'),(4,13,8,2,'62896c'),(5,13,1,2,'91af70'),(10,13,1,2,'354f4e')])
for id,name,c in [('boots_brown','Leather Boots','694d43'),('boots_iron','Iron Boots','596a78'),('shoes_black','Black Shoes','293044')]:
 part(id,name,[(5,14,2,1,c),(9,14,2,1,c),(4,15,3,1,c),(9,15,3,1,c)])
part('belt','Brass Buckle Belt',[(5,12,6,1,'694d43'),(7,12,2,1,'e8c88c')])
part('hat_fedora','Detective Fedora',[(5,0,6,2,'694d43'),(4,2,8,1,'be955b'),(3,3,10,1,'694d43')])
part('hat_cap','Worker Cap',[(5,1,6,2,'62896c'),(4,3,9,1,'354f4e'),(5,1,5,1,'91af70')])
part('helmet','Iron Helmet',[(5,0,6,1,D),(4,1,8,3,'596a78'),(5,1,6,1,'96a6ad'),(4,4,1,2,'596a78'),(11,4,1,2,'596a78')])
part('glasses','Round Glasses',[(5,4,3,2,D),(8,4,3,2,D),(6,4,1,1,'96a6ad'),(9,4,1,1,'96a6ad')])
part('goggles','Brass Goggles',[(4,4,8,1,'694d43'),(5,4,3,2,'be955b'),(8,4,3,2,'be955b'),(6,4,1,1,'8cb7ae'),(9,4,1,1,'8cb7ae')])
part('scarf','Red Scarf',[(6,8,4,1,'a7674e'),(9,9,1,3,'a7674e'),(9,9,1,1,'e8bc98')])
part('sword','Left Hand Sword',[(1,5,1,6,'96a6ad'),(0,11,3,1,'be955b'),(1,12,1,3,'694d43')])
part('shield','Right Hand Shield',[(13,8,3,6,D),(14,9,2,4,'596a78'),(14,10,1,2,'be955b')])
part('lantern','Left Hand Lantern',[(1,10,2,1,'596a78'),(0,11,4,4,D),(1,12,2,2,'e8c88c')])
part('fishing_rod','Right Hand Fishing Rod',[(14,4,1,11,'986b4d'),(15,2,1,3,'d8cbb0')])
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
png('/private/tmp/picell-character-builder-parts.png',[p for f,p in items],8)
recipes=[['pants_brown','boots_brown','head_light','arms_light','shirt_cream','face_calm','hair_short_brown','coat','hat_fedora','lantern'],['pants_dark','boots_iron','head_medium','arms_medium','armor','face_stern','helmet','sword','shield'],['pants_blue','shoes_black','head_deep','arms_deep','shirt_green','face_smile','hair_short_black','hat_cap','fishing_rod'],['skirt','boots_brown','head_light','arms_light','shirt_blue','face_calm','hair_long_red','belt'],['pants_dark','boots_brown','head_medium','arms_medium','shirt_red','face_stern','hair_mohawk','goggles','vest'],['pants_brown','shoes_black','head_deep','arms_deep','shirt_cream','face_smile','hair_long_blond','glasses','scarf']]
examples=[]
for recipe in recipes:
 p=[0]*256
 for id in recipe:p=[b or a for a,b in zip(p,parts[id])]
 examples.append(p)
png('/private/tmp/picell-character-builder-examples.png',examples,6)
Path('assets/data/templates/character_builder_guide.md').write_text('''# Modular character builder (16×16)\n\nAll character_builder_*_16.json parts use the same transparent 16×16 canvas and a front-facing pose. Import each part onto a separate layer at x=0, y=0, without cropping or scaling.\n\nLayer order, bottom to top: trousers/skirt → shoes/boots → head → arms → shirt/armor → face → hair → vest/coat → belt/scarf → hat/helmet → glasses/goggles → held item. Choose one skin tone for both head and arms. Choose one part per slot; hats can cover hair, and skirts can cover the upper part of shoes. Left/right refer to the image sides.\n\nHead occupies rows 2–7, torso rows 8–12, legs rows 13–14 and feet row 15. Hands sit at columns 3–4 and 11–12. Held items sit beside the hands. Parts are static; this set does not include animation frames.\n''')
print('Created and validated',len(items),'aligned character parts and six assembled previews')
