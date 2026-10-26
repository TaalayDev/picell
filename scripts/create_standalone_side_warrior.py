"""Hand-authored, single-layer side-profile template; no builder dependencies."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 32, 48
PALETTE = {
    '.': 0, 'X': 0xff282936, 'h': 0xff493530, 'H': 0xff79513b,
    's': 0xffba7957, 'S': 0xffe5aa78, 'L': 0xffffcf99,
    'd': 0xff503b35, 'm': 0xff81573e, 't': 0xffaf7a4e,
    'g': 0xffbd934e, 'G': 0xffeed18a, 'b': 0xff3e414f,
    'B': 0xff606577, 'r': 0xff823e43, 'R': 0xffbb5c54,
    'i': 0xff8395a0, 'I': 0xffc1d1d6,
}
# One complete warrior with swept hair, bare arms and leather armor.
ROWS = [
    '..........XXXX',
    '.........XHHhhX',
    '........XHHHhhhXX',
    '.......XHHHHHhhhhX',
    '.......XhhhHHhhhhX',
    '.......XhhhhhSSSSX',
    '.......XhhhhsSLSLX',
    '.......XhhhsSSSXSX',
    '........XhhSsSSSSSX',
    '........XhhsSSSSSSSX',
    '.........XhsSSSSSXX',
    '..........XhhSSSX',
    '..........XhhhSX',
    '.........XXssSX',
    '........XssSSSSX',
    '.......XssSSSSSmX',
    '......XssSSSSSmtX',
    '.....XssSLLSSXmtmX',
    '.....XsSSSSSSXmtmX',
    '.....XsSSSSSXdmttX',
    '.....XssSSSSXdmtmX',
    '......XsSSSXdmttmX',
    '......XsSSSXdtmtmX',
    '......XssSSXdtmtmX',
    '......XssSSXdmttmX',
    '......XXssXXdmtmmX',
    '......XdmmXXdmmmXX',
    '......XmItXXggGggX',
    '......XmmmXXgggggX',
    '......XmItXXrRRrrX',
    '......XdmmXXrRRrrX',
    '......XsSSXXrrRrrX',
    '......XsLSXXrrXrrX',
    '.......XXXbBBBXBBX',
    '........XbbBBBXBBX',
    '........XbbBBBXBBX',
    '........XbbBBBXBBX',
    '........XdmmmXXmmX',
    '........XmiImXmImX',
    '........XdmmmXmmmX',
    '........XdmtmXmtmX',
    '........XdmtmXmtmX',
    '........XdmmmXmmmX',
    '........XdmtmXmtmX',
    '........XdmmmXmmmXXX',
    '........XdmmmXmmttttX',
    '........XXXXXXXXXXXXX',
]
assert len(ROWS) <= HEIGHT and all(len(row) <= WIDTH for row in ROWS)
pixels = [PALETTE[c] for row in ROWS for c in row.ljust(WIDTH, '.')]
pixels += [0] * (WIDTH * HEIGHT - len(pixels))
filename = 'side_profile_warrior_32x48.json'
data = dict(name='Side Profile Warrior · 32×48', category='characters', is_pro=False,
            width=WIDTH, height=HEIGHT, pixels=pixels,
            description='Complete right-facing warrior with swept brown hair, bare arms, leather armor, metal-studded bracers and a crimson battle skirt. Transparent background; imports as one editable layer.',
            tags=['side-profile', 'facing-right', 'character', 'warrior', '32x48'])
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
preview = Path('/private/tmp/side-profile-warrior.png')
preview.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH*scale, HEIGHT*scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
print(f'Created {filename} and {preview}')
