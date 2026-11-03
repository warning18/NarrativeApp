#!/usr/bin/env python3
"""Turns the generated world (docs/maps/fmg-seed102) into a ChartGeography.

  git checkout origin/claude/fmg-map-experiment -- docs/maps/fmg-seed102   # the generated world
  python3 tool/fmg_chart/fmg_to_chart.py docs/maps/fmg-seed102 > tool/fmg_chart/chart_fmg.dart
  dart format tool/fmg_chart/chart_fmg.dart

Reads game-map-data.json (places, lands, rivers) and game-map.svg (the
relief icons, for the mountain ranges), scales everything from the generator's
1600x1000 canvas into the chart's 256x176 units, and writes the Dart for a
`chartWorldFmg` the game's painter can draw. Needs shapely and numpy.
It writes only what the chart builds from data; the villages, bridges, seats
and trade roads of the design are carried over in the preview (see
preview_test.dart) and listed in docs/maps/fmg-chart/CHART.md.
"""
import json, math, re, sys, os
import numpy as np
from shapely.geometry import Polygon, MultiPolygon, Point, LineString, box
from shapely.ops import voronoi_diagram, unary_union

SRC = sys.argv[1] if len(sys.argv) > 1 else 'docs/maps/fmg-seed102'  # game-map-data.json, game-map.svg, scripts/spec.json
data = json.load(open(os.path.join(SRC, 'game-map-data.json')))
spec = json.load(open(os.path.join(SRC, 'scripts/spec.json')))
svg = open(os.path.join(SRC, 'game-map.svg')).read()

W, H = 256.0, 176.0
MARGIN = 6.0                   # units of sea kept round the lands
STRETCH = 1.25                 # vertical stretch over horizontal (the lands are wider than the chart)
MIN_GAP = 10.8                 # the closest two places are on chart B (tern/upper: 10.6)

_xs = [p[0] for v in data['lands'].values() for p in v]
_ys = [p[1] for v in data['lands'].values() for p in v]
X0, X1, Y0, Y1 = min(_xs), max(_xs), min(_ys), max(_ys)
KX = (W - 2 * MARGIN) / (X1 - X0)
KY = min(KX * STRETCH, (H - 2 * MARGIN) / (Y1 - Y0))
OFFX = MARGIN
OFFY = (H - (Y1 - Y0) * KY) / 2


def S(p):
    return (round((p[0] - X0) * KX + OFFX, 1), round((p[1] - Y0) * KY + OFFY, 1))


def dart_pts(pts):
    return '[' + ', '.join('Offset(%g, %g)' % (x, y) for x, y in pts) + ']'


lands = {k: Polygon([S(p) for p in v]) for k, v in data['lands'].items()}
land_order = ['old_continent', 'ashen_continent', 'lantern_isles']
places = {k: S(v) for k, v in data['places'].items()}

# ---- places: spread clustered districts to the spacing the chart's labels need
SEA_PLACES = {k for k, v in spec['rules'].items() if v.get('land') == 'SEA'}
import random
random.seed(7)
anchor = dict(places)
pos = {k: list(v) for k, v in places.items()}
land_all = unary_union(list(lands.values()))
inland = land_all.buffer(-0.9)
for it in range(400):
    moved = False
    ids = list(pos)
    for i, a in enumerate(ids):
        for b in ids[i + 1:]:
            dx, dy = pos[b][0] - pos[a][0], pos[b][1] - pos[a][1]
            d = math.hypot(dx, dy)
            if d >= MIN_GAP:
                continue
            if d < 1e-6:
                ang = random.random() * 6.283
                dx, dy, d = math.cos(ang), math.sin(ang), 1.0
            push = (MIN_GAP - d) / 2 + 0.05
            for who, sgn in ((a, -1), (b, 1)):
                nx = pos[who][0] + sgn * dx / d * push
                ny = pos[who][1] + sgn * dy / d * push
                ok = (not land_all.contains(Point(nx, ny))) if who in SEA_PLACES else inland.contains(Point(nx, ny))
                if ok:
                    pos[who] = [nx, ny]
                    moved = True
    # a light pull back toward where the place was put
    for k in pos:
        if k in SEA_PLACES:
            continue
        nx = pos[k][0] + (anchor[k][0] - pos[k][0]) * 0.02
        ny = pos[k][1] + (anchor[k][1] - pos[k][1]) * 0.02
        if inland.contains(Point(nx, ny)):
            pos[k] = [nx, ny]
    if not moved:
        break
places = {k: (round(v[0], 1), round(v[1], 1)) for k, v in pos.items()}
_d = sorted(math.dist(places[a], places[b]) for a in places for b in places if a < b)
sys.stderr.write('places: closest pair %.1f (chart B: 10.6), moved up to %.1f units\n' % (_d[0], max(math.dist(places[k], anchor[k]) for k in places)))

# ---- coasts: coarse like the hand-drawn charts (the painter breaks them up)
EPS_COAST = 1.1
coast_loops = []
for k in land_order:
    poly = lands[k].simplify(EPS_COAST, preserve_topology=True)
    pts = list(poly.exterior.coords)[:-1]
    coast_loops.append(pts)
    lands[k] = Polygon(pts)

# ---- rivers: the longest, simplified, source to mouth as the data gives them
rivers = []
for r in data['rivers']:
    ls = LineString([S(p) for p in r])
    if ls.length < 10:
        continue
    ls = ls.simplify(0.9)
    rivers.append(list(ls.coords))

# ---- zones: each country's share of its land (nearest of its places)
BIOME = {'The Alster Marches': 'temperate', 'The Waste': 'desert', 'The Salt Coast': 'arid_coast',
         'The Ashen Coast': 'ashlands', 'The Grey Fen': 'fen', 'The Frost Reach': 'frost',
         'The Hollow Cape': 'tear', 'The Throne’s Demesne': 'sea_cliffs'}
FR = {'The Alster Marches': 'Les Marches d’Alster', 'The Waste': 'La Désolation',
      'The Salt Coast': 'La Côte de Sel', 'The Ashen Coast': 'The Ashen Coast',
      'The Grey Fen': 'Le Marais gris', 'The Frost Reach': 'Les Confins du Givre',
      'The Hollow Cape': 'Le Cap Creux', 'The Throne’s Demesne': 'The Throne’s Demesne'}
land_of_region = {}
for name, ids in spec['countries'].items():
    for k in land_order:
        if any(lands[k].buffer(1.5).contains(Point(places[i])) for i in ids if i in places):
            land_of_region[name] = k
            break
zones = []
for k in land_order:
    regs = [n for n, kk in land_of_region.items() if kk == k]
    pts = [(n, Point(places[i])) for n in regs for i in spec['countries'][n] if i in places]
    if not pts:
        continue
    if len(regs) == 1:
        shares = {regs[0]: lands[k]}
    else:
        vor = voronoi_diagram(unary_union([p for _, p in pts]), envelope=box(-50, -50, W + 50, H + 50))
        shares = {}
        for cell in vor.geoms:
            owner = min(pts, key=lambda t: t[1].distance(cell.representative_point()))[0]
            shares[owner] = shares.get(owner, Polygon()).union(cell)
        shares = {n: g.intersection(lands[k]) for n, g in shares.items()}
    for n, g in shares.items():
        parts = list(g.geoms) if isinstance(g, MultiPolygon) else [g]
        parts = [p for p in parts if p.area > 20]
        if not parts:
            continue
        main = max(parts, key=lambda p: p.area)
        main = main.simplify(1.0, preserve_topology=True)
        if isinstance(main, MultiPolygon):
            main = max(main.geoms, key=lambda p: p.area)
        zones.append((n, BIOME[n], list(main.exterior.coords)[:-1], main.representative_point().coords[0]))

# ---- ranges: the relief icons that are mountains, clustered into ranges
mounts = []
terr = re.search(r'<g id="terrain"[^>]*>(.*?)</g>', svg, re.S).group(1)
for m in re.finditer(r'<use href="#relief-simple-mount[^"]*"[^>]*?x="([\d.]+)" y="([\d.]+)" width="([\d.]+)"', terr):
    x, y, w = float(m.group(1)), float(m.group(2)), float(m.group(3))
    mounts.append((x + w / 2, y + w / 2, w))
clusters = []
for x, y, w in mounts:
    near = [c for c in clusters if any(math.hypot(x - a, y - b) < 38 for a, b, _ in c)]
    merged = [(x, y, w)]
    for c in near:
        merged += c
        clusters.remove(c)
    clusters.append(merged)
RANGE_NAMES = [('The Rime Teeth', 'Les Dents de Givre', True, False),
               ('The Firebacks', 'Les Dos-de-Feu', False, True),
               ('The Scaffold Crags', 'Les Rocs des Échafauds', False, False),
               ('The Vigil Ridge', 'La Crête de la Veille', True, False),
               ('The Alster Downs', 'Les Collines d’Alster', False, False),
               ('The Lantern Cliffs', 'Les Falaises de la Lanterne', False, False)]
ranges = []
clusters = sorted([c for c in clusters if len(c) >= 6], key=lambda c: -len(c))[:6]
for c, (en, fr, snow, ember) in zip(clusters, RANGE_NAMES):
    arr = np.array([[a, b] for a, b, _ in c])
    mean = arr.mean(axis=0)
    u, s_, vt = np.linalg.svd(arr - mean)
    axis = vt[0]
    t = (arr - mean) @ axis
    order = np.argsort(t)
    bins = np.array_split(order, 4)
    line = [S(tuple(arr[b].mean(axis=0))) for b in bins if len(b)]
    size = round(float(np.mean([w for _, _, w in c])) * KX * 0.55, 1)
    ranges.append((en, fr, line, max(3.0, min(5.0, size * 3)), snow, ember))

# ---- labels: seas, set in the open water far from every land
all_land = unary_union(list(lands.values()))
sea = []
for en, fr, near in [('the Narrow Sea', 'la Mer Étroite', places['storm']),
                     ('the Open Water', 'la Haute Mer', (50, 150)),
                     ('the Grey Water', 'l’Eau Grise', (225, 12))]:
    best, bd = near, -1
    for dx in range(-24, 25, 4):
        for dy in range(-16, 17, 4):
            q = (min(W - 20, max(20, near[0] + dx)), min(H - 8, max(8, near[1] + dy)))
            d = all_land.distance(Point(q))
            if d > bd:
                best, bd = q, d
    sea.append((en, fr, best))

out = []
out.append('// GENERATED by tool/fmg_chart/fmg_to_chart.py from docs/maps/fmg-seed102: do not edit by hand.')
out.append('// ignore_for_file: prefer_const_constructors')
out.append('// A fourth geography for the world chart, from the generated world (a preview: nothing uses it).')
out.append("import 'dart:ui' show Offset;\n\nimport 'package:narrative_data_app/data/map_charts.dart';\n")
out.append('final ChartGeography chartWorldFmg = ChartGeography(')
out.append('  places: {')
for k, (x, y) in places.items():
    out.append("    '%s': Offset(%g, %g)," % (k, x, y))
out.append('  },')
out.append('  lands: [' + ',\n    '.join(dart_pts(p) for p in coast_loops) + ',\n  ],')
out.append('  rivers: [' + ',\n    '.join(dart_pts(r) for r in rivers) + ',\n  ],')
out.append('  labels: [')
for en, fr, (x, y) in sea:
    out.append("    ChartLabel('%s', '%s', %g, %g, 1, sea: true)," % (en, fr, x, y))
out.append('  ],')
out.append('  zones: [')
for n, b, poly, (lx, ly) in zones:
    out.append("    ChartZone('%s', '%s', '%s', Offset(%g, %g), %s)," % (b, n, FR[n], lx, ly, dart_pts([(round(x, 1), round(y, 1)) for x, y in poly])))
out.append('  ],')
out.append('  ranges: [')
for en, fr, line, size, snow, ember in ranges:
    out.append("    ChartRange('%s', '%s', %s, %g, snow: %s, ember: %s)," % (en, fr, dart_pts(line), size, str(snow).lower(), str(ember).lower()))
out.append('  ],')
out.append(');\n')
print('\n'.join(out))
sys.stderr.write('lands %s | rivers %d | zones %d | ranges %d\n' % ([len(c) for c in coast_loops], len(rivers), len(zones), len(ranges)))
sys.stderr.write('mount icons %d -> clusters %s\n' % (len(mounts), [len(c) for c in clusters]))
