#!/usr/bin/env python3
"""Draws one glyph per skill on the 16 px blank gems of assets/icons/skills.

    python3 tool/gen_skill_glyphs.py [school ...]    # default: every school
    python3 tool/png8.py                             # then store as palette PNGs

The older skills' icons were the same blank gem for a whole school (17 martial
skills shared one grey diamond). The frame keeps carrying the school (the gem in
tool/skill_gems/<school>.png: its colour and shape) and a 7x7 cream pictogram
carries the skill (docs/proposals/art-consistency.md). Each glyph is a bitmap:
'#' is cream, 'o' the dark shade, '.' leaves the gem showing. It is placed at
(5, 5), the room a diamond leaves in its middle (an Earth shield has less).
"""
import os
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
GEMS = os.path.join(ROOT, 'tool', 'skill_gems')
ICONS = os.path.join(ROOT, 'assets', 'icons', 'skills')
CREAM = (250, 242, 218, 255)
SHADE = (24, 18, 28, 255)

SCHOOLS = {
    # The martial skills (element None): one grey diamond each, until now.
    'martial': {
        'power_strike': ["...#...", "...#...", "...#...", "...#...", ".#####.", "...#...", "...#..."],
        'heavy_attack': ["..###..", ".#####.", ".#####.", "..###..", "...#...", "...#...", "...#..."],
        'heavy_windup': ["..###..", ".#####.", ".##.##.", "...#...", "...#...", "...#...", "...#..."],
        'battle_trance': ["..###..", ".#...#.", "#.###.#", "#.#o#.#", "#.###.#", ".#...#.", "..###.."],
        'final_stand': [".###...", ".####..", ".###...", ".#.....", ".#.....", ".#.....", ".#....."],
        'focus_mind': [".......", "..###..", ".#...#.", "#..#..#", ".#...#.", "..###..", "......."],
        'guard_break': ["###.###", "###.###", "##.#.##", "#.###.#", "#######", ".#####.", "..###.."],
        'human_diplomacy': [".#####.", "#.....#", "#.....#", "#.....#", ".#####.", "..#....", ".#....."],
        'human_quick_study': ["#######", "#..#..#", "#..#..#", "#..#..#", "#..#..#", "#######", "......."],
        'improvised_strike': ["..##...", ".####..", ".####..", "..##...", "...#...", "....#..", "....#.."],
        'lucky_strike': ["...#...", "...#...", "#######", ".#####.", "..###..", ".##.##.", "##...##"],
        'orc_savage_cleave': ["#.#.#..", "#.#.#..", ".#.#.#.", ".#.#.#.", "..#.#.#", "..#.#.#", "......."],
        'precision_thrust': ["...#...", "..###..", "..###..", "...#...", "...#...", "...#...", "...#..."],
        'ruthless_edge': ["...#...", "..###..", "..###..", "..###..", ".#####.", "...#...", "...#..."],
        'warrior_execute': [".#####.", "#######", "#.###.#", "#######", ".#####.", ".#.#.#.", "......."],
        'warrior_whirlwind': ["..###..", ".#.....", "#..###.", "#..#.#.", "#..###.", ".#....#", "..###.."],
        'zealous_conviction': ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"],
    },
    # The fire skills (and the pack's howl, which wore the same orange gem).
    'fire': {
        'cleric_smite': ["....##.", "...##..", "..##...", ".#####.", "...##..", "..##...", ".##...."],
        'fireball': ["#......", ".#..##.", "..####.", ".#####.", ".#####.", "..###..", "......."],
        'inner_fire': ["...#...", "..##...", "..###..", ".####.#", ".#####.", ".#####.", "..###.."],
        'mage_meteor': ["#......", ".#.....", "..#.##.", "...####", "...####", "....##.", "......."],
        'molten_backlash': [".#####.", "#.....#", "#..#..#", "#.###.#", "#..#..#", "#.....#", ".#####."],
        'orc_berserk_rage': ["#.....#", ".#...#.", "..#.#..", "#######", "#.###.#", "#######", ".#.#.#."],
        'pack_howl': ["..###..", ".##....", "##.....", "##.....", ".##....", "..###..", "......."],
        'warcry': ["#.....#", ".#...#.", "..#.#..", "#.#.#.#", "..#.#..", ".#...#.", "#.....#"],
    },
    # The wind skills: the elves' and the rangers' and the shadow's.
    'wind': {
        'elf_arcane_focus': ["...#...", "...#...", "..###..", "#######", "..###..", "...#...", "...#..."],
        'elf_keen_eye': [".......", "..###..", ".#...#.", "#.###.#", ".#...#.", "..###..", "......."],
        'ranger_aimed_shot': ["....###", "....###", "...#.##", "..#...#", ".#.....", "#......", "......."],
        'ranger_multi_shot': ["#..#..#", ".#.#.#.", "..###..", "...#...", "...#...", "...#...", "...#..."],
        'rogue_shadow_clone': [".#####.", "#######", "#.###.#", "#######", "#######", "#######", "#.#.#.#"],
        'steady_aim': ["...#...", "...#...", "##.#.##", ".#####.", "##.#.##", "...#...", "...#..."],
    },
    # The earth skills on the shield-shaped gem (the stances and the skins).
    'earth_shield': {
        'brace': ["..#.#..", "..#.#..", "..#.#..", ".##.##.", ".##.##.", "##...##", "#######"],
        'bulwark_stance': ["#######", "###.###", "#######", "#.###.#", "#######", "###.###", "#######"],
        'dwarf_stoneskin': [".#####.", "#######", "###.###", "#######", "##.####", "#######", ".#####."],
        'stone_resolve': ["...#...", "..###..", "..###..", ".#####.", ".#####.", "#######", "#######"],
        'warrior_iron_stance': ["######.", "#######", ".#####.", "..###..", "..###..", ".#####.", "#######"],
    },
}


# Where the 7x7 glyph starts on the gem: (5, 5) in a diamond's middle; a shield
# has its room higher.
OFFSET = {'earth_shield': (4, 3)}


def draw(school, skill, bitmap):
    gem = Image.open(os.path.join(GEMS, school + '.png')).convert('RGBA')
    px = gem.load()
    ox, oy = OFFSET.get(school, (5, 5))
    for y, row in enumerate(bitmap):
        assert len(row) == 7, (skill, row)
        for x, ch in enumerate(row):
            if ch == '#':
                px[x + ox, y + oy] = CREAM
            elif ch == 'o':
                px[x + ox, y + oy] = SHADE
    gem.save(os.path.join(ICONS, skill + '.png'))


def main(argv):
    names = argv or list(SCHOOLS)
    for school in names:
        for skill, bitmap in SCHOOLS[school].items():
            draw(school, skill, bitmap)
        print(school, len(SCHOOLS[school]), 'glyphs')


if __name__ == '__main__':
    main(sys.argv[1:])
