"""Convert the supplied transparent adventurer artwork to a layered template.

Usage: python3 scripts/convert_front_adventurer_template.py /path/to/source.png
Requires Pillow. The source is sampled, never repainted.
"""
import json
import sys
from pathlib import Path
from PIL import Image
from collections import deque

ROOT = Path(__file__).resolve().parents[1]
W, H = 64, 96
source = Image.open(sys.argv[1]).convert('RGBA')
# Remove the baked checkerboard by flood-filling only pale neutral pixels
# reachable from the image border. Enclosed eye whites remain untouched.
w, h = source.size
rgba = source.load()
def background(x, y):
    r, g, b, a = rgba[x, y]
    return a == 0 or (min(r, g, b) >= 150 and max(r, g, b) - min(r, g, b) <= 24)
queue = deque([(x, y) for x in range(w) for y in (0, h - 1)] +
              [(x, y) for y in range(h) for x in (0, w - 1)])
seen = bytearray(w * h)
while queue:
    x, y = queue.popleft()
    i = y * w + x
    if seen[i]:
        continue
    seen[i] = 1
    if not background(x, y):
        continue
    rgba[x, y] = (0, 0, 0, 0)
    for nx, ny in ((x-1,y), (x+1,y), (x,y-1), (x,y+1)):
        if 0 <= nx < w and 0 <= ny < h and not seen[ny*w+nx]:
            queue.append((nx, ny))

# Ignore nearly transparent antialiasing outside the actual silhouette.
box = source.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
assert box, 'The source is empty'
source = source.crop(box)
source.thumbnail((W - 4, H - 4), Image.Resampling.NEAREST)
image = Image.new('RGBA', (W, H))
image.paste(source, ((W - source.width) // 2, H - 2 - source.height))
# The source has translucent edge pixels; retain their original ARGB values.
pixels = [(a << 24 | r << 16 | g << 8 | b) if a else 0 for r, g, b, a in image.getdata()]
names = ['leg_l', 'leg_r', 'arm_l', 'body', 'arm_r', 'head']
buffers = {name: [0] * (W * H) for name in names}
# Six full-canvas regions: head, body, two complete arms and two complete legs.
def role(x, y, pixel):
    if y < 43:
        return 'head'
    r, g, b = (pixel >> 16) & 255, (pixel >> 8) & 255, pixel & 255
    # The scarf and its trailing end stay with the body.
    if y < 60 and r > g * 1.7 and r > b * 1.4:
        return 'body'
    if y < 45 and 12 <= x <= 40:
        return 'head'
    if y >= 71:
        return 'leg_l' if x < 26 else 'leg_r'
    if y >= 52 and x < 17:
        return 'arm_l'
    if y >= 52 and x >= 38:
        return 'arm_r'
    return 'body'
for i, pixel in enumerate(pixels):
    if pixel:
        buffers[role(i % W, i // W, pixel)][i] = pixel
layers = [dict(name=name, pixels=buffers[name], is_visible=True, is_locked=False, opacity=1)
          for name in names if any(buffers[name])]
# Disjoint source ownership preserves even translucent edges exactly.
assert all(sum(bool(layer['pixels'][i]) for layer in layers) == bool(pixels[i]) for i in range(W * H))
folder = ROOT / 'assets/data/templates'
filename = 'front_scarf_adventurer_64x96.json'
data = dict(name='Front Scarf Adventurer · 64×96', width=W, height=H, pixels=pixels,
            layers=layers, category='characters', is_pro=False,
            tags=['adventurer', 'front-view', 'facing-front', 'scarf', 'layered', '64x96'],
            description='Front-facing adventurer with brown hair, red scarf, blue tunic and leather boots, converted from supplied artwork. Six aligned editable layers: head, body, two arms and two legs. Transparent background.')
(folder / filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
index_file = folder / 'index.json'
index = json.loads(index_file.read_text())
if filename not in index:
    index.append(filename)
index_file.write_text(json.dumps(index, indent=1) + '\n')
image.save(ROOT / 'assets/images/templates/front_scarf_adventurer.png')
image.resize((W * 6, H * 6), Image.Resampling.NEAREST).save('/private/tmp/front-scarf-adventurer-preview.png')
print(f'Created {filename}: {len(layers)} aligned layers, {W}×{H}')
