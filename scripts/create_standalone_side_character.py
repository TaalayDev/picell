"""Hand-authored, single-layer side-profile template; no builder dependencies."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 32, 48
PALETTE = {
    '.': 0, 'X': 0xff252b3b, 'h': 0xff523c38, 'H': 0xff87604a,
    's': 0xffc58b68, 'S': 0xffedbb8d, 'L': 0xffffd6a2,
    'g': 0xff345b55, 'G': 0xff568875, 'l': 0xff8bb59a,
    'r': 0xffa25043, 'R': 0xffdd8660, 'b': 0xff4a4149,
    'B': 0xff72616a, 't': 0xff79513d, 'T': 0xffb27d50,
    'y': 0xffe3bb72,
}
# Each row is deliberately drawn as one full sprite, facing right.
ROWS = [
    '.........XXXXXX',
    '........XHHHHhhX',
    '.......XHHHHHhhhX',
    '.......XHHHHHhhhhX',
    '.......XhhhhhSSSSX',
    '.......XhhhsSSLSLX',
    '.......XhhsSSSSXSX',
    '........XhSsSSSSSSX',
    '........XhsSSSSSSSSX',
    '.........XsSSSSSSXX',
    '..........XsSSSSX',
    '..........XssSSX',
    '.........XXssSX',
    '........XrRRRRRX',
    '.......XrRRRrrrX',
    '......XGGlllGXXX',
    '.....XgGGllGGGGX',
    '.....XgGGGGGGGlGX',
    '.....XgGGGGGGlGGX',
    '.....XgGGGgGGGGGX',
    '.....XgGGGgGGGGGX',
    '.....XggGGgGGGGGX',
    '......XgGGgGGGGGX',
    '......XgGGgGGGGGX',
    '......XgGGgGGGGGX',
    '......XggGXGGGGGX',
    '......XggGXGGGGGX',
    '......XggGXGGGGGX',
    '......XggGXGGGGGX',
    '......XssSXttytXX',
    '......XsSSXtttttX',
    '.......XXXbBBBbbX',
    '........XbbBBBbbX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XbbBBXbBX',
    '........XttttXttX',
    '........XtTTtXtTX',
    '........XtTTtXtTX',
    '........XttttXttXXX',
    '........XttttXttTTTX',
    '........XXXXXXXXXXXX',
]
assert len(ROWS) <= HEIGHT and all(len(row) <= WIDTH for row in ROWS)
pixels = [PALETTE[c] for row in ROWS for c in row.ljust(WIDTH, '.')]
pixels += [0] * (WIDTH * HEIGHT - len(pixels))
filename = 'side_profile_ranger_32x48.json'
data = dict(name='Side Profile Ranger · 32×48', category='characters', is_pro=False,
            width=WIDTH, height=HEIGHT, pixels=pixels,
            description='Complete right-facing ranger with a green tunic, copper scarf and leather boots. Transparent background; imports as one editable layer.',
            tags=['side-profile', 'facing-right', 'character', 'ranger', '32x48'])
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
preview = Path('/private/tmp/side-profile-ranger.png')
preview.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH*scale, HEIGHT*scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
print(f'Created {filename} and {preview}')
