#!/usr/bin/env python3
"""The heads on the fight's cards (combat redesign A'): a crop of each fighter's
existing sprite, so a card shows a face instead of a round icon or an initial.

Writes assets/visuals/heads/<id>.png (nothing is drawn: every pixel is the
sprite's own): every enemy icon of assets/icons/enemies, the hero (the ronin
of assets/visuals/walker) and Vica (the guide dog, Fight - Attack facing east).
A tall figure keeps its top third (hat, hair, helmet and face); a wide one (an
animal on all fours) keeps the front of its body, where the head is.

Run from the repository root:  python3 tool/gen_fight_heads.py
"""
import glob
import os

from PIL import Image

OUT = 'assets/visuals/heads'
os.makedirs(OUT, exist_ok=True)


def head(im, tall_share=0.36, wide_box=(0.0, 0.0, 0.42, 0.58)):
    im = im.convert('RGBA')
    box = im.getchannel('A').getbbox()
    if box is None:
        return None
    im = im.crop(box)
    w, h = im.size
    if w > h * 1.25:
        l, t, r, b = wide_box
        crop = im.crop((int(w * l), int(h * t), int(w * r), int(h * b)))
    else:
        crop = im.crop((0, 0, w, max(12, int(h * tall_share))))
    box = crop.getchannel('A').getbbox()
    return crop.crop(box) if box else None


def save(name, im):
    if im is not None:
        im.save(f'{OUT}/{name}.png')


for path in sorted(glob.glob('assets/icons/enemies/*.png')):
    name = os.path.splitext(os.path.basename(path))[0]
    save(name, head(Image.open(path)))

# The hero: the ronin's hat and face.
ronin = Image.open('assets/visuals/walker/ronin_idle_east.png').convert('RGBA')
box = ronin.getchannel('A').getbbox()
ronin = ronin.crop(box)
save('hero', ronin.crop((0, 0, ronin.width, 17)))

# Vica: the dog's head and neck (the right part of her east-facing frame).
vica = Image.open(
    'assets/visuals/companion/dog_companion_animations/Fight_-_Attack/'
    'rotations/east.png').convert('RGBA')
box = vica.getchannel('A').getbbox()
vica = vica.crop(box)
save('vica', vica.crop((int(vica.width * 0.52), 0, vica.width,
                         int(vica.height * 0.58))))
print('heads:', len(glob.glob(f'{OUT}/*.png')))
