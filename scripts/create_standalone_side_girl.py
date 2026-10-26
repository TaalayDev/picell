"""Hand-authored, single-layer side-profile template; no builder dependencies."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 32, 48
PALETTE = {
    '.': 0, 'X': 0xff292b3d, 'h': 0xff573c39, 'H': 0xff956347,
    'a': 0xffc38b58, 's': 0xffc58a69, 'S': 0xffedb58a,
    'L': 0xffffd4a3, 'd': 0xff3c5968, 'm': 0xff5c91a1,
    'l': 0xff9ac6c6, 'r': 0xff88495d, 'R': 0xffca7186,
    'b': 0xff424251, 'B': 0xff69647a, 't': 0xff765344,
    'T': 0xffad805b, 'g': 0xffe6c17b,
}
# A complete right-facing girl, drawn directly as one pixel sprite.
ROWS = [
    '..........XXXXX',
    '.........XHHHhhX',
    '........XHaHHHhhX',
    '.......XHHHHHHhhhX',
    '.....XXhHHHHHHhhhX',
    '....XHHXhhhhSSSSSX',
    '....XHaXRhhsSSLSLX',
    '....XHHXhhhsSSSXSX',
    '....XHhXhhsSSSSSSX',
    '....XHh.XhsSSSSSSSX',
    '....XHh..XsSSSSSSX',
    '....Xhh...XsSSSSX',
    '.....Xh...XXssSX',
    '......X..XmmssSmX',
    '........XdmmllmmX',
    '.......XdmmllllmmX',
    '......XdmmllmmmmmmX',
    '......XdmmmmmXmmlmX',
    '......XdmmmmmXmmlmX',
    '......XdmmmmmXmmmmX',
    '......XdmmmmmXmmmmX',
    '......XdmmmmmXmmmmX',
    '......XddmmmXXdmmmX',
    '......XsSSSXdmmlmmX',
    '......XsSSSXdmmlmmX',
    '......XsSSSXdmmlmmX',
    '......XsSSSXdmmlmmX',
    '......XsSSSXttgttXX',
    '......XsSSSXrrrrrrX',
    '......XsSSXrRRRRrrX',
    '......XsLSXrRRRRrrX',
    '.......XXXrRRRRRrrrX',
    '........XrrRRRRRrrrrX',
    '........XXXXXXXXXXXXX',
    '.........XbBBXBBX',
    '.........XbBBXBBX',
    '.........XbBBXBBX',
    '.........XbBBXBBX',
    '.........XbBBXBBX',
    '.........XbBBXBBX',
    '.........XtttXttX',
    '.........XtTtXtTX',
    '.........XtTtXtTX',
    '.........XtTtXtTX',
    '.........XtttXttXXX',
    '.........XtttXttTTTX',
    '.........XXXXXXXXXXX',
]
assert len(ROWS) <= HEIGHT and all(len(row) <= WIDTH for row in ROWS)
pixels = [PALETTE[c] for row in ROWS for c in row.ljust(WIDTH, '.')]
pixels += [0] * (WIDTH * HEIGHT - len(pixels))
filename = 'side_profile_girl_32x48.json'
data = dict(name='Side Profile Girl · 32×48', category='characters', is_pro=False,
            width=WIDTH, height=HEIGHT, pixels=pixels,
            description='Complete right-facing girl with a chestnut ponytail, teal tunic, rose skirt, leggings and leather boots. Transparent background; imports as one editable layer.',
            tags=['side-profile', 'facing-right', 'character', 'girl', '32x48'])
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
preview = Path('/private/tmp/side-profile-girl.png')
preview.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH*scale, HEIGHT*scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
print(f'Created {filename} and {preview}')
