"""Convert the supplied transparent adventurer artwork to a layered template.

Usage: python3 scripts/convert_scarf_adventurer_template.py /path/to/source.png
Requires Pillow. The source is sampled, never repainted.
"""
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
W, H = 64, 96
source = Image.open(sys.argv[1]).convert('RGBA')
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
    r, g, b = (pixel >> 16) & 255, (pixel >> 8) & 255, pixel & 255
    if 44 <= y < 62 and r > g * 1.8 and r > b * 1.5:
        return 'body'
    # Hair and face sit above the scarf. The trailing scarf stays on the body.
    if (y < 49 and (x >= 21 or y < 44)) or (y < 52 and x >= 43):
        return 'head'
    if y >= 76:
        return 'leg_l' if x < 36 else 'leg_r'
    if (58 <= y < 65 and x < 33) or (65 <= y < 76 and x < 29):
        return 'arm_l'
    if y >= 63 and x >= 46:
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
filename = 'scarf_adventurer_64x96.json'
data = dict(name='Scarf Adventurer · 64×96', width=W, height=H, pixels=pixels,
            layers=layers, category='characters', is_pro=False,
            tags=['adventurer', 'side-profile', 'facing-right', 'scarf', 'layered', '64x96'],
            description='Right-facing adventurer with brown hair, red scarf, blue tunic and leather boots, converted from supplied artwork. Six aligned editable layers: head, body, two arms and two legs. Transparent background.')
(folder / filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
index_file = folder / 'index.json'
index = json.loads(index_file.read_text())
if filename not in index:
    index.append(filename)
index_file.write_text(json.dumps(index, indent=1) + '\n')
image.save(ROOT / 'assets/images/templates/scarf_adventurer.png')
image.resize((W * 6, H * 6), Image.Resampling.NEAREST).save('/private/tmp/scarf-adventurer-preview.png')
print(f'Created {filename}: {len(layers)} aligned layers, {W}×{H}')
