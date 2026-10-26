"""Aligned 32x32 right-facing character parts, ready-made examples and previews.

Run from any directory. All geometry lives on the shared canvas; do not crop
parts. The random builder groups parts by rig role before importing layers.
"""
import json
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1] / 'assets/data/templates'
SIZE = 32
CATEGORY = 'side-character-builder'
OUTLINE = '252b3b'
parts = {}
files = []


def color(value):
    return 0xff000000 | int(value, 16)


def rect(pixels, x, y, width, height, shade):
    for yy in range(max(0, y), min(SIZE, y + height)):
        for xx in range(max(0, x), min(SIZE, x + width)):
            pixels[yy * SIZE + xx] = color(shade)


def line(pixels, a, b, shade):
    x, y = a
    x2, y2 = b
    dx, dy = abs(x2 - x), -abs(y2 - y)
    sx, sy = 1 if x < x2 else -1, 1 if y < y2 else -1
    err = dx + dy
    while True:
        if 0 <= x < SIZE and 0 <= y < SIZE:
            pixels[y * SIZE + x] = color(shade)
        if (x, y) == (x2, y2):
            break
        twice = 2 * err
        if twice >= dy:
            err += dy
            x += sx
        if twice <= dx:
            err += dx
            y += sy


def polygon(pixels, points, shade, outline=OUTLINE):
    for y in range(SIZE):
        crossings = []
        for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1]):
            if (y1 <= y + .5 < y2) or (y2 <= y + .5 < y1):
                crossings.append(x1 + (y + .5 - y1) * (x2 - x1) / (y2 - y1))
        crossings.sort()
        for start, end in zip(crossings[::2], crossings[1::2]):
            for x in range(SIZE):
                if start <= x + .5 < end:
                    pixels[y * SIZE + x] = color(shade)
    if outline:
        for a, b in zip(points, points[1:] + points[:1]):
            line(pixels, a, b, outline)


def shade_rect(pixels, x, y, width, height, shade):
    """Shade only the interior, preserving the silhouette and one-pixel outline."""
    for yy in range(max(0, y), min(SIZE, y + height)):
        for xx in range(max(0, x), min(SIZE, x + width)):
            i = yy * SIZE + xx
            if pixels[i] and pixels[i] != color(OUTLINE):
                pixels[i] = color(shade)


def save(name, category, pixels, filename, tags, description):
    assert len(pixels) == SIZE * SIZE and any(pixels)
    assert all(p == 0 or 0xff000000 <= p <= 0xffffffff for p in pixels)
    data = dict(name=name, category=category, is_pro=False, width=SIZE, height=SIZE,
                description=description, tags=tags, pixels=pixels)
    ROOT.joinpath(filename).write_text(json.dumps(data, separators=(',', ':')) + '\n')
    files.append(filename)


def part(slot, variant, role, paint):
    pixels = [0] * (SIZE * SIZE)
    paint(pixels)
    key = f'{slot}_{variant}'
    save(f'Side Character Builder: {slot.replace("_", " ").title()} {variant.title()} · 32×32',
         CATEGORY, pixels, f'side_character_builder_{key}_32.json',
         ['side-profile', 'facing-right', f'slot:{slot}', f'variant:{variant}', f'rig:{role}'],
         'Aligned 32×32 side-profile part. Import at the same origin without cropping. Faces right.')
    parts[key] = dict(pixels=pixels, role=role)


# Small, consistent ramps: a restrained far-side shade, one lit plane, and
# selective highlights. Joint caps stay open to avoid dark rings at elbows/knees.
for tone, skin, shadow, light in [
    ('light', 'e6b48c', 'b67d61', 'f4d4aa'),
    ('medium', 'bb805e', '885940', 'dda984'),
    ('deep', '8d6048', '5c4037', 'bd8b65'),
]:
    def head(p, skin=skin, shadow=shadow, light=light):
        polygon(p, [(14, 3), (18, 3), (20, 4), (21, 6), (21, 7), (22, 8),
                    (21, 9), (20, 9), (20, 10), (18, 11), (15, 10), (13, 9), (12, 7), (12, 5)], skin)
        shade_rect(p, 13, 5, 2, 4, shadow)
        shade_rect(p, 15, 9, 5, 2, shadow)
        shade_rect(p, 17, 4, 2, 2, light)
        rect(p, 18, 6, 1, 1, light)
        rect(p, 19, 6, 1, 1, OUTLINE)
        shade_rect(p, 14, 6, 2, 3, shadow)
        rect(p, 14, 7, 1, 1, light)
        rect(p, 20, 9, 1, 1, shadow)
    part('head', tone, 'head', head)
    part('neck', tone, 'neck', lambda p, s=skin, sh=shadow:
         (polygon(p, [(15, 10), (18, 10), (19, 13), (15, 13)], s),
          shade_rect(p, 15, 11, 2, 2, sh)))
    for side, x, role in [('far', 12, 'hand_l'), ('near', 20, 'hand_r')]:
        def hand(p, x=x, side=side, skin=skin, shadow=shadow, light=light):
            polygon(p, [(x-1, 21), (x+1, 21), (x+2, 22), (x+2, 23), (x, 24), (x-1, 23)],
                    shadow if side == 'far' else skin)
            rect(p, x, 21, 1, 1, shadow if side == 'far' else skin)
            if side == 'near':
                shade_rect(p, x, 22, 1, 1, light)
        part(f'hand_{side}', tone, role, hand)

outfits = [('green', '49795e', '87ae78', '304e46'),
           ('blue', '487793', '87b8c5', '2e4c66'),
           ('red', 'a15e4c', 'd79b72', '653e3f'),
           ('violet', '71628e', 'b3a0cc', '49415e'),
           ('armor', '687e91', 'b9c9d1', '3d4e67')]
for variant, base, light, shadow in outfits:
    def torso(p, base=base, light=light, shadow=shadow, variant=variant):
        polygon(p, [(14, 12), (18, 12), (20, 14), (20, 17), (19, 19), (18, 21), (13, 21), (12, 15)], base)
        shade_rect(p, 13, 14, 2, 6, shadow)
        shade_rect(p, 17, 14, 2, 3, light)
        line(p, (15, 12), (16, 14), 'd9c79b' if variant == 'green' else light)
        rect(p, 14, 20, 5, 1, '735344')
        rect(p, 17, 20, 1, 1, 'd8b775')
        if variant == 'green':
            line(p, (14, 13), (17, 19), '8e6c4b')
            rect(p, 16, 16, 1, 1, 'e0c18a')
        elif variant == 'blue':
            shade_rect(p, 16, 16, 3, 2, shadow)
            line(p, (16, 16), (18, 16), light)
            rect(p, 18, 19, 1, 1, 'c7b27d')
        elif variant == 'red':
            line(p, (18, 15), (17, 19), light)
            rect(p, 17, 16, 1, 1, 'e2c287')
            rect(p, 17, 18, 1, 1, 'e2c287')
            shade_rect(p, 14, 18, 2, 2, shadow)
        elif variant == 'violet':
            line(p, (17, 15), (18, 16), 'd8b775')
            line(p, (18, 16), (17, 17), 'd8b775')
            rect(p, 14, 21, 4, 1, light)
        else:
            line(p, (15, 14), (17, 15), light)
            line(p, (15, 17), (18, 17), shadow)
            line(p, (15, 18), (17, 19), light)
            rect(p, 18, 15, 1, 1, 'dfc894')
    part('torso', variant, 'spine', torso)
    for side, armrole, forearmrole in [('far', 'arm_l', 'forearm_l'), ('near', 'arm_r', 'forearm_r')]:
        def arm(p, side=side, base=base, light=light, shadow=shadow, variant=variant):
            pts = [(13, 13), (15, 14), (14, 17), (12, 18), (11, 17), (12, 15)] if side == 'far' else [
                (17, 13), (19, 13), (20, 15), (21, 18), (18, 18), (17, 15)]
            polygon(p, pts, shadow if side == 'far' else base)
            if side == 'near':
                shade_rect(p, 18, 14, 1, 3, light)
                rect(p, 19, 17, 1, 2, base)
                if variant == 'armor':
                    line(p, (18, 13), (19, 14), light)
                    rect(p, 19, 15, 1, 1, shadow)
            else:
                rect(p, 12, 17, 2, 1, shadow)
        def forearm(p, side=side, base=base, light=light, shadow=shadow, variant=variant):
            pts = [(11, 17), (13, 17), (14, 20), (13, 22), (11, 21)] if side == 'far' else [
                (18, 17), (20, 17), (22, 21), (20, 22), (19, 20)]
            polygon(p, pts, shadow if side == 'far' else base)
            rect(p, 12 if side == 'far' else 19, 17, 1, 2, shadow if side == 'far' else base)
            if side == 'near':
                shade_rect(p, 20, 19, 1, 2, light)
                line(p, (20, 21), (21, 21), 'a58b64' if variant == 'armor' else shadow)
        part(f'upper_arm_{side}', variant, armrole, arm)
        part(f'forearm_{side}', variant, forearmrole, forearm)

for variant, base, light, shadow in [('dark', '465164', '708095', '303a4c'),
                                    ('brown', '75594c', 'a18361', '4e4140'),
                                    ('blue', '476c83', '7b9caa', '30495d')]:
    part('hips', variant, 'hips', lambda p, c=base, sh=shadow:
         (polygon(p, [(13, 20), (18, 20), (19, 22), (18, 24), (14, 24), (13, 22)], c),
          shade_rect(p, 13, 21, 2, 2, sh)))
    for side in ['far', 'near']:
        x = 14 if side == 'far' else 18
        c = shadow if side == 'far' else base
        def thigh(p, x=x, c=c, side=side, light=light):
            polygon(p, [(x-1, 22), (x+1, 22), (x+1, 26), (x-1, 26), (x-2, 24)], c)
            rect(p, x-1, 22, 2, 1, c)
            rect(p, x-1, 25, 2, 2, c)
            if side == 'near':
                shade_rect(p, x, 23, 1, 2, light)
        def shin(p, x=x, c=c, side=side, light=light):
            polygon(p, [(x-1, 25), (x+1, 25), (x+1, 29), (x-1, 30), (x-1, 28)], c)
            rect(p, x-1, 25, 2, 1, c)
            if side == 'near':
                shade_rect(p, x, 27, 1, 2, light)
        part(f'thigh_{side}', variant, f'thigh_{"l" if side == "far" else "r"}', thigh)
        part(f'shin_{side}', variant, f'shin_{"l" if side == "far" else "r"}', shin)

for variant, base, light in [('leather', '725146', 'ad805b'), ('iron', '61798e', 'b4c5cd'), ('black', '354152', '697b8e')]:
    for side, x in [('far', 14), ('near', 18)]:
        def foot(p, x=x, c=base, hi=light, side=side, variant=variant):
            toe = x+4 if side == 'near' else x+3
            polygon(p, [(x-1, 28), (x+1, 28), (x+1, 29), (toe, 29), (toe+1, 30), (toe, 31), (x-1, 31)], c)
            rect(p, x, 28, 1, 2, c)
            if side == 'near':
                shade_rect(p, x, 29, 2, 1, hi)
                if variant == 'iron':
                    shade_rect(p, toe-1, 30, 2, 1, hi)
            line(p, (x-1, 31), (toe, 31), OUTLINE)
        part(f'foot_{side}', variant, f'foot_{"l" if side == "far" else "r"}', foot)

for variant, base, light in [('brown', '695044', 'a27b54'), ('black', '34404f', '69768a'),
                              ('blond', 'bd975e', 'ead198'), ('red', '98554c', 'd99171')]:
    def hair(p, base=base, light=light, variant=variant):
        pts = [(13, 2), (18, 2), (20, 3), (21, 5), (18, 4), (16, 5), (14, 7), (13, 8), (11, 6), (12, 3)]
        if variant == 'brown':
            pts = [(13, 2), (15, 1), (16, 2), (19, 2), (21, 4), (20, 5), (17, 4), (15, 5), (14, 8), (12, 8), (11, 5)]
        polygon(p, pts, base)
        line(p, (13, 3), (17, 3), light)
        if variant == 'blond':
            polygon(p, [(12, 6), (14, 7), (13, 10), (12, 12), (10, 12), (11, 9)], base)
            rect(p, 12, 7, 1, 1, '876448')
        elif variant == 'red':
            shade_rect(p, 12, 5, 1, 2, light)
    part('hair', variant, 'head', hair)

part('hat', 'cap', 'head', lambda p:
     (polygon(p, [(13, 1), (18, 1), (20, 2), (21, 4), (12, 4)], '557b67'),
      rect(p, 18, 4, 6, 1, OUTLINE), line(p, (14, 2), (18, 2), 'a1b68a'),
      rect(p, 20, 3, 1, 1, 'd4bb7c')))
part('hat', 'helmet', 'head', lambda p:
     (polygon(p, [(13, 1), (18, 1), (21, 3), (22, 5), (20, 6), (17, 5), (15, 7), (14, 10), (12, 10), (11, 5)], '667d91'),
      line(p, (14, 2), (18, 2), 'b4c5cd'), rect(p, 14, 5, 1, 1, 'd9c696'),
      rect(p, 13, 7, 1, 2, '91a9b8')))
part('hat', 'hood', 'head', lambda p:
     (polygon(p, [(16, 0), (19, 2), (21, 4), (19, 4), (17, 5), (15, 7), (15, 11), (13, 12), (11, 10), (10, 6), (12, 3)], '6c5d86'),
      line(p, (12, 5), (12, 9), 'aa99bc'), line(p, (17, 5), (15, 7), 'c3a67c'),
      rect(p, 15, 8, 1, 2, 'c3a67c')))
part('accessory', 'scarf', 'spine', lambda p:
     (polygon(p, [(14, 12), (19, 12), (19, 13), (14, 14), (13, 17), (11, 18), (12, 14)], 'a8584b'),
      line(p, (15, 12), (18, 12), 'e0a17b'), rect(p, 12, 15, 1, 2, 'd48366')))
part('accessory', 'backpack', 'spine', lambda p:
     (polygon(p, [(10, 13), (12, 13), (13, 15), (13, 20), (12, 21), (9, 21), (8, 19), (8, 15)], '735548'),
      line(p, (9, 15), (12, 15), 'ad805b'), rect(p, 10, 17, 1, 2, 'ccb17e'),
      rect(p, 9, 20, 3, 1, '4e4140')))

ORDER = ['upper_arm_far', 'forearm_far', 'hand_far', 'thigh_far', 'shin_far', 'foot_far',
         'hips', 'thigh_near', 'shin_near', 'foot_near', 'torso', 'neck', 'head',
         'upper_arm_near', 'forearm_near', 'hand_near', 'hair', 'hat', 'accessory']


def assemble(tone, outfit, pants, boots, hair, hat=None, accessory=None):
    choices = dict(head=tone, neck=tone, hand_far=tone, hand_near=tone,
                   torso=outfit, upper_arm_far=outfit, forearm_far=outfit,
                   upper_arm_near=outfit, forearm_near=outfit, hips=pants,
                   thigh_far=pants, shin_far=pants, thigh_near=pants, shin_near=pants,
                   foot_far=boots, foot_near=boots, hair=hair, hat=hat, accessory=accessory)
    # Match the random builder's sixteen bone layers, including merged
    # head/torso overlays. Ready-made sprites and rigged imports must agree.
    layers = {}
    for slot in ORDER:
        variant = choices[slot]
        if variant is not None:
            source = parts[f'{slot}_{variant}']
            previous = layers.setdefault(source['role'], [0] * (SIZE * SIZE))
            layers[source['role']] = [b or a for a, b in zip(previous, source['pixels'])]
    result = [0] * (SIZE * SIZE)
    for layer in layers.values():
        result = [b or a for a, b in zip(result, layer)]
    return result


def mirror(pixels):
    return [pixels[y*SIZE + SIZE-1-x] for y in range(SIZE) for x in range(SIZE)]


recipes = [
    ('adventurer', 'Adventurer', ('light', 'green', 'brown', 'leather', 'brown', None, 'backpack')),
    ('worker', 'Worker', ('medium', 'blue', 'dark', 'black', 'black', 'cap', None)),
    ('knight', 'Knight', ('medium', 'armor', 'dark', 'iron', 'black', 'helmet', None)),
    ('mage', 'Mage', ('deep', 'violet', 'brown', 'leather', 'red', 'hood', None)),
    ('explorer', 'Explorer', ('deep', 'red', 'blue', 'leather', 'blond', None, 'scarf')),
]
examples = []
for facing in ['right', 'left']:
    for key, name, recipe in recipes:
        pixels = assemble(*recipe)
        if facing == 'left':
            pixels = mirror(pixels)
        save(f'Side Profile {name} · {facing.title()} · 32×32', 'characters', pixels,
             f'side_character_{key}_{facing}_32.json', ['side-profile', f'facing-{facing}', '32x32'],
             'Ready-made side-profile character. Use the Side Character Builder category for separate editable parts.')
        examples.append(pixels)

index = json.loads(ROOT.joinpath('index.json').read_text())
for filename in files:
    if filename not in index:
        index.append(filename)
assert len(index) == len(set(index))
ROOT.joinpath('index.json').write_text(json.dumps(index, indent=1) + '\n')


def preview(path, tiles, columns, scale=6):
    cell = SIZE * scale + 24
    width, height = columns * cell, ((len(tiles) + columns - 1) // columns) * cell
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            tile = y // cell * columns + x // cell
            px, py = (x % cell - 12) // scale, (y % cell - 12) // scale
            shade = 0xffe1e4ed if (x // (scale*2) + y // (scale*2)) % 2 else 0xffcdd3e0
            if tile < len(tiles) and 0 <= px < SIZE and 0 <= py < SIZE:
                shade = tiles[tile][py * SIZE + px] or shade
            raw.extend([(shade >> 16) & 255, (shade >> 8) & 255, shade & 255])
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    Path(path).write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
                           + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


preview('/private/tmp/picell-side-character-examples.png', examples, 5)
print(f'Created {len(parts)} aligned parts and {len(examples)} complete side-profile characters')
