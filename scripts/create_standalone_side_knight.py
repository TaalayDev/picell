"""Hand-authored layered side-profile knight template; no builder dependencies."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 32, 48
PALETTE = {
    '.': 0, 'X': 0xff252b3b, 'd': 0xff465469, 'm': 0xff74899d,
    's': 0xffa5bdca, 'L': 0xffe3edf0, 'r': 0xff793749,
    'R': 0xffbc5360, 'H': 0xffe38680, 'g': 0xffad813e,
    'G': 0xffebc478, 'b': 0xff383c50,
}
# Complete hand-authored right-facing knight, including armor and plume.
ROWS = [
    '..........XXXX',
    '.........XHRRRX',
    '........XHRRRrX',
    '........XRRrrX',
    '.........XrrX',
    '........XXXXXXX',
    '.......XmssLLssX',
    '......XmssLLsssmX',
    '......XdssLsssssX',
    '......XdssssssssXX',
    '......XdmXXXXXXXXXX',
    '......XdmsdddddddX',
    '......XdmssmsssssX',
    '.......XdmssXmXmX',
    '........XdmsssssX',
    '........XXdmmmXX',
    '.......XmmssssX',
    '......XXXXXXXssX',
    '.....XmsLLssmXssX',
    '....XmsLLsssmXssX',
    '....XdssssssmXmssX',
    '.....XddmmmXXmssLX',
    '.....XdmmssXdmssLX',
    '.....XdmmssXdmsssX',
    '.....XdmmssXdmsssX',
    '.....XXmmmXXdmsssX',
    '.....XdmsLsXddmmmX',
    '.....XdmsLsXggGggX',
    '.....XdmsLsXgggggX',
    '.....XdmmssXdmssmX',
    '.....XXmmmXXdmssmX',
    '.....XdmsLsXXmssmX',
    '.....XdmmssXbXmmmX',
    '......XXXXXbbXmssX',
    '........XdmssXmssX',
    '........XdmssXmssX',
    '........XdmssXmssX',
    '........XXmmXXmmXX',
    '........XdmsLXsLsX',
    '........XXmmXXmmXX',
    '........XdmssXmssX',
    '........XdmssXmssX',
    '........XdmssXmssX',
    '........XdmmmXmmmX',
    '........XdmmmXmssXXX',
    '........XdmmmXmmssLLX',
    '........XXXXXXXXXXXXX',
]
assert len(ROWS) <= HEIGHT and all(len(row) <= WIDTH for row in ROWS)
pixels = [PALETTE[c] for row in ROWS for c in row.ljust(WIDTH, '.')]
pixels += [0] * (WIDTH * HEIGHT - len(pixels))
# Keep every part on the same canvas so imports preserve alignment. The
# side-view artwork shows one arm; split both visible legs independently.
LAYER_NAMES = ['thigh_l', 'shin_l', 'foot_l', 'thigh_r', 'shin_r', 'foot_r',
               'hips', 'torso', 'neck', 'upper_arm_r', 'forearm_r', 'hand_r',
               'head', 'Helmet plume']
layer_pixels = {name: [0] * (WIDTH * HEIGHT) for name in LAYER_NAMES}
def part_at(x, y):
    if y < 5:
        return 'Helmet plume'
    if y < 16:
        return 'head'
    if y == 16:
        return 'neck'
    if 17 <= y <= 33 and x <= 11:
        return 'upper_arm_r' if y <= 25 else ('forearm_r' if y <= 30 else 'hand_r')
    if y <= 26:
        return 'torso'
    if y <= 33:
        return 'hips'
    side = 'l' if x <= 12 else 'r'
    return ('thigh_' if y <= 37 else ('shin_' if y <= 42 else 'foot_')) + side
for i, pixel in enumerate(pixels):
    if pixel:
        layer_pixels[part_at(i % WIDTH, i // WIDTH)][i] = pixel
layers = [dict(name=name, pixels=layer_pixels[name], is_visible=True,
               is_locked=False, opacity=1.0) for name in LAYER_NAMES]
assert all(any(layer['pixels']) for layer in layers)
assert [next((layer['pixels'][i] for layer in reversed(layers)
              if layer['pixels'][i]), 0) for i in range(WIDTH * HEIGHT)] == pixels
filename = 'side_profile_knight_32x48.json' 
data = dict(name='Side Profile Knight · 32×48', category='characters', is_pro=False,
            width=WIDTH, height=HEIGHT, pixels=pixels, layers=layers,
            description='Complete right-facing knight with silver plate armor, a closed visor and a crimson plume. Transparent background; imports as 14 aligned editable layers for the helmet, plume, body, arm and legs.',
            tags=['side-profile', 'facing-right', 'character', 'knight', 'layered', '32x48'])
folder = ROOT / 'assets/data/templates'
(folder / filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
index_path = folder / 'index.json'
index = json.loads(index_path.read_text())
if filename not in index:
    index.append(filename)
index_path.write_text(json.dumps(index, indent=1) + '\n')

# Nearest-neighbor preview of the actual template pixels, on a checkerboard.
scale = 10
raw = bytearray()
for y in range(HEIGHT * scale):
    raw.append(0)
    for x in range(WIDTH * scale):
        value = pixels[(y // scale) * WIDTH + x // scale]
        value = value or (0xffe1e4ed if (x // 40 + y // 40) % 2 else 0xffcdd3e0)
        raw.extend([(value >> 16) & 255, (value >> 8) & 255, value & 255])
def chunk(kind, payload):
    return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload))
preview = Path('/private/tmp/side-profile-knight.png')
preview.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH*scale, HEIGHT*scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
print(f'Created {filename} and {preview}')
