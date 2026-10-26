"""Convert the supplied transparent robot artwork to a layered template.

Usage: python3 scripts/convert_robot_template.py /path/to/source.png
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
def role(x, y):
    if y < 40:
        return 'head'
    if y < 44 and 24 <= x <= 41:
        return 'body'
    if x < 23 and y < 78:
        return 'arm_l'
    if x > 46 and y < 78:
        return 'arm_r'
    if y < 65 or (y < 71 and 22 <= x <= 47):
        return 'body'
    return 'leg_l' if x < 34 else 'leg_r'
for i, pixel in enumerate(pixels):
    if pixel:
        buffers[role(i % W, i // W)][i] = pixel
layers = [dict(name=name, pixels=buffers[name], is_visible=True, is_locked=False, opacity=1)
          for name in names if any(buffers[name])]
# Disjoint source ownership preserves even translucent edges exactly.
assert all(sum(bool(layer['pixels'][i]) for layer in layers) == bool(pixels[i]) for i in range(W * H))
folder = ROOT / 'assets/data/templates'
filename = 'clockwork_robot_64x96.json'
data = dict(name='Clockwork Robot · 64×96', width=W, height=H, pixels=pixels,
            layers=layers, category='characters', is_pro=False,
            tags=['robot', 'steampunk', 'clockwork', 'layered', '64x96'],
            description='Brass clockwork robot with cyan lenses and core, converted from supplied artwork. Aligned editable head, body, arm and leg layers; transparent background.')
(folder / filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
index_file = folder / 'index.json'
index = json.loads(index_file.read_text())
if filename not in index:
    index.append(filename)
index_file.write_text(json.dumps(index, indent=1) + '\n')
image.save(ROOT / 'assets/images/templates/clockwork_robot.png')
image.resize((W * 6, H * 6), Image.Resampling.NEAREST).save('/private/tmp/clockwork-robot-preview.png')
print(f'Created {filename}: {len(layers)} aligned layers, {W}×{H}')
