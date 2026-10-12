#!/usr/bin/env python3
"""A story-true geography for the world chart, drawn from the story and the globe.

  python3 tool/fmg_chart/story_world.py > tool/fmg_chart/chart_story.dart
  dart format tool/fmg_chart/chart_story.dart

The chart is a band of 225 degrees of longitude by 140 of latitude (70N to 70S): x = (lon / 225 + 0.5) * 256 and
y = (0.5 - lat / 140) * 176. Latitude sets the climate (climate.dart), so each land sits where its weather
should be: the Ashen Continent in the cold north, the Old Continent in the south with Alster's vale about 45S
and the Waste in the dry belt, the Lantern Isles between them in the west.

Everything below is drawn by hand as rough outlines and places (DESIGN); the coasts are then made complex by
growing the outline with noise, so the shape has bays and headlands but only the lands the story names.
Needs numpy, scipy, scikit-image, shapely and PIL.
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from skimage import measure
from shapely.geometry import Polygon, Point, LineString, MultiPolygon
from shapely.ops import unary_union

W, H = 256.0, 176.0
RES = 4                       # grid cells per chart unit
SEED = 21
EDGE = 9.0                    # units of open sea kept at every edge of the chart

# ---------------------------------------------------------------- the design
LANDS = {
    # rough outlines, clockwise; the noise makes the coast
    'ashen': [(36, 40), (40, 27), (52, 18), (68, 13), (90, 11), (120, 10), (150, 11), (172, 13), (190, 12), (206, 13),
              (222, 17), (231, 26), (229, 37), (214, 40), (200, 35), (192, 38), (184, 42), (176, 48), (160, 52),
              (142, 52), (132, 55), (128, 49), (118, 49), (112, 55), (98, 58), (76, 60), (60, 58), (46, 53),
              (38, 47)],
    'old': [(56, 134), (68, 122), (92, 114), (106, 106), (122, 104), (138, 100), (146, 94), (154, 91), (162, 96),
            (172, 100), (183, 106), (188, 118), (184, 132), (172, 144), (150, 152), (121, 157), (96, 161),
            (74, 161), (58, 153), (52, 144)],
    'lantern': [(33, 74), (42, 66), (58, 62), (74, 66), (82, 76), (76, 87), (58, 92), (40, 88)],
}

PLACES = {
    # the Old Continent: Alster in the south-west, the Waste, Saltmouth on the northern headland
    'hovel': (87, 141), 'beggar': (73, 150), 'alley': (89, 152), 'bridge': (100, 138), 'hold': (78, 134),
    'sewers': (102, 150), 'docks': (64, 141),
    'crash': (112, 128), 'sleeper': (125, 121), 'wells': (139, 128),
    'upper': (148, 112), 'wharf': (156, 101), 'tern': (168, 107), 'berths': (168, 119),
    # at sea
    'storm': (147, 76), 'wreck': (238, 24),
    # the Ashen Continent
    'camp': (121, 44),
    'quarter': (131, 33), 'emberwick': (144, 41), 'spire': (146, 27), 'akagiri': (166, 36),
    'wrack': (94, 50), 'cloister': (60, 46), 'court': (48, 30), 'kindly': (74, 38),
    'reliquary': (118, 18), 'heart': (132, 20), 'rimewell': (108, 29), 'highhearth': (158, 17),
    'shore': (214, 28), 'battle': (199, 33), 'greyhithe': (188, 22), 'anchorage': (205, 21),
    # the Lantern Isles
    'candlehold': (56, 77),
}
SEA_PLACES = {'storm', 'wreck'}

# a zone is a biome land; each is the part of its land nearest its seeds
ZONES = [
    ('temperate', 'The Alster Marches', 'Les Marches d’Alster', [(80, 148), (74, 138), (92, 156), (62, 150), (100, 140), (102, 150)]),
    ('desert', 'The Waste', 'La Désolation', [(112, 126), (126, 120), (140, 126), (120, 110), (112, 138), (172, 134), (160, 142)]),
    ('arid_coast', 'The Salt Coast', 'La Côte de Sel', [(158, 101), (168, 108), (166, 116), (148, 100)]),
    ('sea_cliffs', 'The Lantern Isles', 'Les Îles de la Lanterne', [(56, 77)]),
    ('sea_cliffs', 'The Cove', 'La Crique', [(121, 47)]),
    ('ashlands', 'The Ash Flats', 'Les Plaines de cendre', [(134, 36), (126, 38), (146, 31)]),
    ('volcanic', 'The Red Hills', 'Les Collines rouges', [(166, 38), (158, 46)]),
    ('frost', 'The Frost Reach', 'Les Confins du Givre', [(118, 18), (136, 16), (156, 17), (100, 20), (110, 28)]),
    ('tear', 'The Hollow Cape', 'Le Cap Creux', [(204, 24), (192, 30), (216, 26), (190, 18)]),
    ('fen', 'The Grey Fen', 'Le Marais gris', [(74, 38), (60, 44), (48, 30), (66, 32), (56, 38)]),
    ('sea_cliffs', 'The Wrack Cliffs', 'Les Falaises du Varech', [(94, 50), (100, 54), (86, 54), (88, 48)]),
]

PLACE_ZONE = {  # the zone each place belongs to (geography.json)
    'The Alster Marches': ['hovel', 'beggar', 'alley', 'bridge', 'hold', 'sewers', 'docks'],
    'The Waste': ['crash', 'sleeper', 'wells'],
    'The Salt Coast': ['upper', 'wharf', 'tern', 'berths'],
    'The Lantern Isles': ['candlehold'],
    'The Cove': ['camp'],
    'The Ash Flats': ['quarter', 'emberwick', 'spire'],
    'The Red Hills': ['akagiri'],
    'The Frost Reach': ['reliquary', 'heart', 'rimewell', 'highhearth'],
    'The Hollow Cape': ['shore', 'battle', 'greyhithe', 'anchorage'],
    'The Grey Fen': ['cloister', 'court', 'kindly'],
    'The Wrack Cliffs': ['wrack'],
}

RANGES = [  # (name, fr, line, size, snow, ember)
    ('The Rime Teeth', 'Les Dents de Givre', [(84, 20), (92, 25), (98, 32)], 5.0, True, False),
    ('The Firebacks', 'Les Dos-de-Feu', [(150, 46), (158, 48), (170, 46)], 4.4, False, True),
    ('The Alster Downs', 'Les Collines d’Alster', [(68, 130), (84, 126), (96, 122)], 3.6, False, False),
    ('The Lantern Cliffs', 'Les Falaises de la Lanterne', [(46, 72), (58, 69), (72, 73)], 3.6, False, False),
]

RIVERS = [  # Alster's river to its harbour; the freshwater burn at the Cove
    [(106, 117), (104, 128), (100, 138), (92, 141), (82, 140), (72, 140), (64, 141)],
    [(121, 33), (122, 38), (121, 43)],
]

SEAS = [('the Narrow Sea', 'la Mer Étroite', (118, 78)), ('the Open Water', 'la Haute Mer', (214, 128)),
        ('the Grey Water', 'l’Eau Grise', (236, 50))]


# ------------------------------------------------------------------- the land
def noise(shape, scale, rng):
    """Smooth value noise, one feature about [scale] chart units across."""
    gh, gw = int(shape[0] / (scale * RES)) + 3, int(shape[1] / (scale * RES)) + 3
    g = rng.random((gh, gw))
    z = ndimage.zoom(g, (shape[0] / (gh - 2), shape[1] / (gw - 2)), order=3)[:shape[0], :shape[1]]
    return z - 0.5


def signed_field(outline):
    img = Image.new('L', (int(W * RES), int(H * RES)), 0)
    ImageDraw.Draw(img).polygon([(x * RES, y * RES) for x, y in outline], fill=1)
    inside = np.array(img).astype(bool)
    d_in = ndimage.distance_transform_edt(inside)
    d_out = ndimage.distance_transform_edt(~inside)
    return (d_in - d_out) / RES


def build_lands():
    rng = np.random.default_rng(SEED)
    shape = (int(H * RES), int(W * RES))
    n1, n2, n3 = noise(shape, 30, rng), noise(shape, 12, rng), noise(shape, 5, rng)
    out = {}
    for name, outline in LANDS.items():
        f = signed_field(outline)
        f = f + 13.0 * n1 + 6.5 * n2 + 2.6 * n3
        # land stays off the chart's edges: the band ends at 70N and 70S, and beyond it is open sea
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        edge = np.minimum(np.minimum(xx, shape[1] - xx), np.minimum(yy, shape[0] - yy)) / RES
        f = f - np.clip(EDGE - edge, 0, None) * 5.0
        f = ndimage.gaussian_filter(f, 1.2)
        # an outline must stay well off the chart's edge
        cs = measure.find_contours(f, 0.0)
        cs = [c for c in cs if len(c) > 40 * RES / 4]
        polys = []
        for c in cs:
            pts = [(p[1] / RES, p[0] / RES) for p in c]
            if len(pts) > 4 and pts[0] == pts[-1]:
                pts = pts[:-1]
            if len(pts) > 4:
                polys.append(Polygon(pts))
        polys.sort(key=lambda p: -p.area)
        out[name] = polys
    return out


def checks(lands):
    union = unary_union([p for v in lands.values() for p in v])
    bad = []
    for k, (x, y) in PLACES.items():
        pt = Point(x, y)
        if k in SEA_PLACES:
            if union.distance(pt) < 4:
                bad.append((k, 'too near land %.1f' % union.distance(pt)))
        elif not union.buffer(-2.0).contains(pt):
            bad.append((k, 'not inland by 2 units (dist to coast %.1f)' % (-union.exterior_distance(pt) if hasattr(union, 'exterior_distance') else union.boundary.distance(pt))))
    ids = list(PLACES)
    close = sorted((math.dist(PLACES[a], PLACES[b]), a, b) for i, a in enumerate(ids) for b in ids[i + 1:])
    return bad, close[:6]


def debug_png(lands, path, zones=(), px=8):
    img = Image.new('RGB', (int(W * px), int(H * px)), (24, 50, 60))
    d = ImageDraw.Draw(img)
    for lat in range(-60, 70, 10):
        y = (0.5 - lat / 140) * H * px
        d.line([(0, y), (W * px, y)], fill=(40, 80, 92), width=1)
        d.text((4, y + 2), '%d°' % lat, fill=(120, 170, 180))
    for v in lands.values():
        for poly in v:
            d.polygon([(x * px, y * px) for x, y in poly.exterior.coords], fill=(72, 70, 80), outline=(150, 148, 160))
    pal = {'temperate': (90, 130, 80), 'desert': (170, 140, 80), 'arid_coast': (150, 120, 90), 'sea_cliffs': (110, 110, 130),
           'ashlands': (100, 95, 100), 'volcanic': (150, 80, 70), 'frost': (150, 170, 190), 'tear': (130, 100, 160), 'fen': (70, 110, 100)}
    for biome, nm, fr, poly in zones:
        d.polygon([(x * px, y * px) for x, y in poly.exterior.coords], fill=pal.get(biome, (90, 90, 90)), outline=(230, 230, 230))
        c = poly.representative_point()
        d.text((c.x * px - 20, c.y * px + 10), nm, fill=(255, 255, 255))
    for name, fr, line, size, snow, ember in RANGES:
        d.line([(x * px, y * px) for x, y in line], fill=(230, 230, 240), width=3)
    for r in RIVERS:
        d.line([(x * px, y * px) for x, y in r], fill=(80, 140, 200), width=3)
    for k, (x, y) in PLACES.items():
        c = (255, 120, 120) if k in SEA_PLACES else (242, 193, 78)
        d.ellipse([x * px - 5, y * px - 5, x * px + 5, y * px + 5], fill=c)
        d.text((x * px + 7, y * px - 5), k, fill=(255, 255, 255))
    for biome, nm, fr, seeds in ZONES:
        for (x, y) in seeds:
            d.rectangle([x * px - 2, y * px - 2, x * px + 2, y * px + 2], outline=(120, 220, 120))
    img.save(path)


def land_mask(lands):
    img = Image.new('L', (int(W * RES), int(H * RES)), 0)
    d = ImageDraw.Draw(img)
    for v in lands.values():
        for poly in v:
            d.polygon([(x * RES, y * RES) for x, y in poly.exterior.coords], fill=1)
    return np.array(img).astype(bool)


def build_zones(lands):
    """Each zone is the land nearest its seeds (a nearest-seed split of the land, cell by cell)."""
    mask = land_mask(lands)
    ys, xs = np.nonzero(mask)
    best = np.full(mask.shape, -1, dtype=int)
    bestd = np.full(mask.shape, 1e9)
    yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
    for zi, (biome, name, fr, seeds) in enumerate(ZONES):
        for sx, sy in seeds:
            d = (xx / RES - sx) ** 2 + (yy / RES - sy) ** 2
            upd = d < bestd
            best[upd] = zi
            bestd[upd] = d[upd]
    best[~mask] = -1
    zones = []
    for zi, (biome, name, fr, seeds) in enumerate(ZONES):
        m = (best == zi)
        m = ndimage.binary_opening(m, iterations=2)
        lab, n = ndimage.label(m)
        if n == 0:
            continue
        sizes = ndimage.sum(m, lab, range(1, n + 1))
        m = lab == (1 + int(np.argmax(sizes)))
        cs = measure.find_contours(np.pad(m, 1).astype(float), 0.5)
        c = max(cs, key=len)
        pts = [((p[1] - 1) / RES, (p[0] - 1) / RES) for p in c]
        poly = Polygon(pts).buffer(-0.15).simplify(0.4)
        if isinstance(poly, MultiPolygon):
            poly = max(poly.geoms, key=lambda g: g.area)
        zones.append((biome, name, fr, poly))
    return zones


def zone_report(zones):
    out = []
    by_name = {z[1]: z[3] for z in zones}
    for name, ids in PLACE_ZONE.items():
        for i in ids:
            if name in by_name and not by_name[name].contains(Point(PLACES[i])):
                actual = [n for n, g in by_name.items() if g.contains(Point(PLACES[i]))]
                out.append((i, 'expected', name, 'in', actual))
    return out


def smooth_line(pts, n=4):
    ls = LineString(pts)
    return [ls.interpolate(i / (len(pts) * n - 1), normalized=True).coords[0] for i in range(len(pts) * n)]


def dart_pts(pts):
    return '[' + ', '.join('Offset(%g, %g)' % (round(x, 1), round(y, 1)) for x, y in pts) + ']'


def latlon(x, y):
    return (0.5 - y / H) * 140.0, (x / W - 0.5) * 225.0


FEATURES = {  # 'kind|name' -> where; the rest of each feature is chart B's (names, notes, clan, angle)
    'village|Tallow Street': (75, 143), 'bridge|The Stone Bridge': (100, 138), 'giant|the stone giant of Alster’s harbour': (57, 136),
    'village|the Salt Pans': (139, 108), 'giant|the giant in Saltmouth’s harbour mouth': (151, 95),
    'seat|The Brig': (140, 91), 'seat|Lowtide': (194, 100),
    'seat|The Lantern Throne': PLACES['candlehold'], 'village|the Salt Marsh': (66, 83), 'seat|The Open Hand’s hall': (66, 76),
    'seat|The Spire of Judgment': PLACES['spire'], 'seat|Anvil Gate': (155, 46), 'seat|Highhearth': PLACES['highhearth'],
    'village|the Frost Quarry': (170, 17), 'seat|Akagiri': PLACES['akagiri'], 'village|the Hot Springs': (172, 43),
    'seat|The Exorcists’ Gate': (158, 31), 'site|The Exorcists’ Road': (152, 36), 'village|the Slag Kilns': (151, 33),
    'seat|The Kindly Hill': PLACES['kindly'], 'seat|The Heron’s Wake': (62, 37), 'village|the False Lamps': (99, 54),
    'seat|The Vigil’s Wall': (186, 31),
}


def write_dart(lands, zones):
    out = ['// GENERATED by tool/fmg_chart/story_world.py: do not edit by hand.',
           '// A story-true geography for the world chart, drawn from the story and the globe (a preview: nothing uses it).',
           "import 'dart:ui' show Offset;\n\nimport 'package:narrative_data_app/data/map_charts.dart';\n",
           'final ChartGeography chartWorldStory = ChartGeography(', '  places: {']
    for k, (x, y) in PLACES.items():
        out.append("    '%s': Offset(%g, %g)," % (k, x, y))
    out.append('  },')
    loops = []
    for name in ('ashen', 'old', 'lantern'):
        poly = lands[name][0].simplify(0.3, preserve_topology=True)
        loops.append(list(poly.exterior.coords)[:-1])
    out.append('  lands: [' + ',\n    '.join(dart_pts(l) for l in loops) + ',\n  ],')
    out.append('  rivers: [' + ',\n    '.join(dart_pts(smooth_line(r)) for r in RIVERS) + ',\n  ],')
    out.append('  labels: [')
    for en, fr, (x, y) in SEAS:
        out.append("    ChartLabel('%s', '%s', %g, %g, 1, sea: true)," % (en, fr, x, y))
    out.append('  ],')
    out.append('  zones: [')
    for biome, name, fr, poly in zones:
        c = poly.representative_point().coords[0]
        out.append("    ChartZone('%s', '%s', '%s', Offset(%g, %g), %s)," % (biome, name, fr, round(c[0], 1), round(c[1], 1), dart_pts(list(poly.exterior.coords)[:-1])))
    out.append('  ],')
    out.append('  ranges: [')
    for en, fr, line, size, snow, ember in RANGES:
        out.append("    ChartRange('%s', '%s', %s, %g, snow: %s, ember: %s)," % (en, fr, dart_pts(line), size, str(snow).lower(), str(ember).lower()))
    out.append('  ],')
    out.append(');\n')
    out.append('/// Where the features that have a story role stand, by "kind|name" (the rest is chart B\'s).')
    out.append('const Map<String, Offset> storyFeatureAt = {')
    for k, (x, y) in FEATURES.items():
        out.append("  '%s': Offset(%g, %g)," % (k.replace("'", "\\'"), x, y))
    out.append('};')
    return '\n'.join(out)


def main():
    lands = build_lands()
    bad, close = checks(lands)
    print('off-land / spacing:', bad, [(round(a, 1), b, c) for a, b, c in close], file=sys.stderr)
    zones = build_zones(lands)
    print('zone misses:', zone_report(zones), file=sys.stderr)
    if '--debug' in sys.argv:
        debug_png(lands, sys.argv[sys.argv.index('--debug') + 1], zones)
    return lands, zones


if __name__ == '__main__':
    lands, zones = main()
    for k, v in lands.items():
        print(k, [round(p.area) for p in v][:6], file=sys.stderr)
    if '--debug' not in sys.argv:
        print(write_dart(lands, zones))
