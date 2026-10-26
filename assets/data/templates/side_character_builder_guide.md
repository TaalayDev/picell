# Side-profile character builder (32×32)

The Side Character Builder category contains aligned right-facing character parts.
Use **Random Side Character** to assemble an outfit. Enable **Face left** to mirror
all parts together. The five ready-made characters in **Characters** are Adventurer,
Worker, Knight, Mage, and Explorer, each available facing left or right.

The artwork uses clean one-pixel silhouettes, lighter joint transitions,
consistent near/far shading, and outfit-specific details. Ready-made characters
use the same bone-layer composition as the random builder.

All parts share a transparent 32×32 canvas. Import at the same origin without
cropping or scaling. Head, neck, and hands share a skin tone; sleeves match the
chosen torso; both legs and both boots use matching variants. Far limbs are darker
and sit behind the body. Hats, hair, and accessories are optional overlays.

The random builder imports sixteen separate layers named for the rig bones:
`hips`, `spine`, `neck`, `head`, and `arm`, `forearm`, `hand`, `thigh`, `shin`, `foot`
with `_l` (far) and `_r` (near) suffixes. Hair and hats merge into the head layer;
scarves and backpacks merge into the spine layer. Layer order preserves near/far
occlusion. The ready-made character templates are flattened; choose the random
builder when you need separately animated body parts.

For rigging, use a **32×32 editing canvas**, then add **Humanoid (side profile)** in
Setup. At its native size the placement box covers the full canvas, preserving the
transparent margins and aligning joints with the body parts. The preset can be
moved or stretched for other artwork. Enable the skeleton's **Mirror** option for a
left-facing character; names retain the same near/far meaning.

Try Walk, Run, Jump, Attack, Dash, and Fall. Use the animation configuration's
mirroring option to reverse motion for a left-facing character. Foot planting,
joint locks, attachment points, and half-pixel numeric controls remain available.

Generate these assets reproducibly with:

```
python3 scripts/create_side_character_templates.py
```

The script updates the template index without duplicating entries and creates a
preview at `/private/tmp/picell-side-character-examples.png` (right-facing row,
then left-facing row).
