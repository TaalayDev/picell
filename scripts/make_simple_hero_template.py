"""Generate the layered 'Simple Hero' example template (32x32).

Usage: python3 scripts/make_simple_hero_template.py
Six full-canvas layers named like the Basic Character bone preset
(leg_l, leg_r, arm_l, body, arm_r, head) so a skeleton binds by name.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
W = H = 32

SKIN, HAIR, SHIRT, BELT = 0xF2C79B, 0x5B3A29, 0x3B82F6, 0x7C4A21
PANTS, SHOE, EYE, MOUTH = 0x374151, 0x1F2937, 0x111827, 0xB45353


def argb(rgb):
    return 0xFF000000 | rgb


def darker(rgb, k=0.68):
    return argb(int(((rgb >> 16) & 255) * k) << 16 | int(((rgb >> 8) & 255) * k) << 8 | int((rgb & 255) * k))


def layer(rect, paint):
    """paint(x, y) -> rgb inside rect; rect edges get a darker outline."""
    x0, y0, x1, y1 = rect
    px = [0] * (W * H)
    for y in range(y0, y1):
        for x in range(x0, x1):
            c = paint(x, y)
            edge = x in (x0, x1 - 1) or y in (y0, y1 - 1)
            px[y * W + x] = darker(c) if edge else argb(c)
    return px


def head(x, y):
    if y <= 4 or (y <= 8 and (x <= 11 or x >= 20)):
        return HAIR
    if y == 7 and x in (13, 14, 17, 18):
        return EYE
    if y == 10 and x in (15, 16):
        return MOUTH
    return SKIN


def body(x, y):
    return BELT if y == 19 else PANTS if y == 20 else SHIRT


def arm(x, y):
    return SKIN if y >= 18 else SHIRT


def leg(x, y):
    return SHOE if y >= 27 else PANTS


layers = [
    ('leg_l', layer((11, 21, 16, 30), leg)),
    ('leg_r', layer((16, 21, 21, 30), leg)),
    ('arm_l', layer((7, 12, 11, 21), arm)),
    ('body', layer((11, 12, 21, 21), body)),
    ('arm_r', layer((21, 12, 25, 21), arm)),
    ('head', layer((11, 2, 21, 12), head)),
]
flat = [0] * (W * H)
for _, px in layers:
    for i, p in enumerate(px):
        if p:
            flat[i] = p

filename = 'simple_hero_32x32.json'
data = dict(
    name='Simple Hero · 32×32',
    width=W,
    height=H,
    pixels=flat,
    layers=[dict(name=n, pixels=px, is_visible=True, is_locked=False, opacity=1) for n, px in layers],
    category='characters',
    is_pro=False,
    tags=['character', 'simple', 'rig', 'example', 'layered', '32x32'],
    description='A tiny hero made of head, body, arm and leg layers. Open the bone rig editor, add the Basic '
                'character skeleton and apply a ready-made animation.',
)
folder = ROOT / 'assets/data/templates'
(folder / filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
index_file = folder / 'index.json'
index = json.loads(index_file.read_text())
if filename not in index:
    index.append(filename)
index_file.write_text(json.dumps(index, indent=1) + '\n')
print(f'Created {filename}')
