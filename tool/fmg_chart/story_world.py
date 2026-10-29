#!/usr/bin/env python3
"""A story-true geography for the world chart, drawn from the story and the globe: the whole sphere.

  python3 tool/fmg_chart/story_world.py > lib/data/chart_story.dart
  dart format lib/data/chart_story.dart

Since board 11 (the world sphere) the chart covers the whole globe, 360 degrees of longitude by 180 of latitude,
in the chart's 256 x 176 units: x = (lon / 360 + 0.5) * 256 and y = (0.5 - lat / 180) * 176 (ChartGeography's
lonSpan and latSpan say so to the globe and the climate). Ten lands: the story's three, moved in longitude to
the board's layout with their latitudes kept (the Ashen Continent west, the Old Continent east, the Lantern
Isles between), five empty lands, and a polar land at each pole; twelve archipelagos fill the seas.

The story lands are still drawn here as they were first designed, on the old band of 225 x 140 degrees
(OLD_* below), and remapped: each point keeps its latitude and its longitude is stretched from the land's old
span to its new one (STORY_LON). The empty lands and the archipelagos are drawn on the board's flat picture
(1440 x 720 pixels, four to a degree) and scaled to chart units (BOARD). Latitude sets the climate
(climate.dart), so each land sits where its weather should be. The coasts are made complex by growing each
outline with noise, so the shape has bays and headlands.
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
EDGE = 2.0                    # units of open sea kept at the chart's left and right edges (the seam)
LON_SPAN, LAT_SPAN = 360.0, 180.0


def old_lonlat(x, y):
    """A point of the old band chart (225 x 140 degrees) as longitude and latitude."""
    return (x / W - 0.5) * 225.0, (0.5 - y / H) * 140.0


def chart_xy(lon, lat):
    """The chart point (whole sphere) at a longitude and latitude."""
    return (lon / LON_SPAN + 0.5) * W, (0.5 - lat / LAT_SPAN) * H


def board(pts):
    """Points drawn on board 11's flat picture (1440 x 720 px) in chart units."""
    return [(x * W / 1440.0, y * H / 720.0) for x, y in pts]

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
    # Alster is one place (v1.534): its districts are walked on its own plan, not on the chart
    'alster': (85, 144),
    'crash': (112, 128), 'sleeper': (125, 121), 'wells': (139, 128),
    # Saltmouth is one place (v1.536): its districts are walked on its own plan, not on the chart
    'saltmouth': (160, 110),
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

# a zone is a biome land; each is the part of its land nearest its seeds. The climate follows the latitude, as on
# Earth: frost at both poles, temperate and cold lands in the middle latitudes, and the hot, dry and wet belts
# about the equator (the Waste and Saltmouth, with a jungle in between).
ZONES = [
    ('temperate', 'The Alster Marches', 'Les Marches d’Alster', [(80, 138), (74, 128), (92, 146), (62, 140), (100, 130), (102, 140)]),
    ('desert', 'The Waste', 'La Désolation', [(112, 116), (126, 110), (140, 116), (120, 100), (112, 128), (150, 114)]),
    ('arid_coast', 'The Salt Coast', 'La Côte de Sel', [(158, 91), (168, 98), (166, 106), (148, 90), (148, 102)]),
    ('temperate', 'The Tallow Downs', 'Les Landes de suif', [(150, 138), (176, 126), (130, 142), (170, 142)]),            # the Old Continent's south-east
    ('sea_cliffs', 'The Lantern Isles', 'Les Îles de la Lanterne', [(56, 77)]),
    ('sea_cliffs', 'The Cove', 'La Crique', [(121, 47)]),
    ('ashlands', 'The Ash Flats', 'Les Plaines de cendre', [(134, 36), (126, 38), (146, 31)]),
    ('volcanic', 'The Red Hills', 'Les Collines rouges', [(166, 38), (158, 46)]),
    ('frost', 'The Frost Reach', 'Les Confins du Givre', [(118, 18), (136, 16), (156, 17), (100, 20), (110, 28)]),
    ('tear', 'The Hollow Cape', 'Le Cap Creux', [(204, 24), (192, 30), (216, 26), (190, 18)]),
    ('fen', 'The Grey Fen', 'Le Marais gris', [(74, 38), (60, 44), (48, 30), (66, 32), (56, 38)]),
    ('sea_cliffs', 'The Wrack Cliffs', 'Les Falaises du Varech', [(94, 50), (100, 54), (86, 54), (88, 48)]),
]

# The Old Continent sits ten units further north than first drawn, so Saltmouth is on the equator's edge
# and the crossing to the Cove Camp is about three weeks long (58 units).
OLD_DY = -10
LANDS['old'] = [(x, y + OLD_DY) for x, y in LANDS['old']]
for _k in ('alster', 'crash', 'sleeper', 'wells', 'saltmouth'):
    PLACES[_k] = (PLACES[_k][0], PLACES[_k][1] + OLD_DY)

PLACE_ZONE = {  # the zone each place belongs to (geography.json)
    'The Alster Marches': ['alster'],
    'The Waste': ['crash', 'sleeper', 'wells'],
    'The Salt Coast': ['saltmouth'],
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
    ('The Alster Downs', 'Les Collines d’Alster', [(68, 120), (84, 116), (96, 112)], 3.6, False, False),
    ('The Lantern Cliffs', 'Les Falaises de la Lanterne', [(44, 70), (56, 66), (70, 68)], 3.0, False, False),
]

RIVERS = [  # Alster's river to its harbour; the freshwater burn at the Cove
    [(106, 107), (104, 118), (100, 128), (92, 131), (82, 130), (72, 130), (64, 131)],
    [(121, 33), (122, 38), (121, 43)],
]

ARCHIPELAGOS = {
    # empty for now: open water with small lands, for ship content (voyages, wrecks, hunts) later.
    # id: (centre x, centre y, half-width, half-height, islands, seed). Each sits clear of the crossing,
    # the sea roads, the other lands and the chart's edges.
    'north_west': (22, 40, 7, 13, 4, 3),
    'mid_sea': (102, 78, 8, 6, 4, 5),
    'east_narrows': (180, 66, 10, 7, 5, 8),
    'south_east': (222, 144, 14, 9, 5, 11),
}

SEAS = [('the Narrow Sea', 'la Mer Étroite', (112, 64)), ('the Open Water', 'la Haute Mer', (60, 154)),
        ('the Grey Water', 'l’Eau Grise', (236, 46))]


# ------------------------------------------------------------------ the sphere
# Each story land's longitudes on the whole sphere (board 11); its latitudes stay as they were.
STORY_LON = {'ashen': (-122.0, -4.0), 'old': (12.0, 134.0), 'lantern': (-34.0, 8.0)}

# The empty lands, drawn on board 11's flat picture (pixels, four to a degree), clockwise.
EMPTY_LANDS = {
    'west': [(15, 420), (60, 395), (120, 392), (160, 420), (172, 490), (150, 540), (130, 580), (70, 582), (25, 560),
             (10, 500)],
    'equator': [(290, 330), (330, 305), (400, 300), (450, 320), (472, 360), (450, 400), (400, 420), (345, 422),
                (300, 395), (285, 360)],
    'south_west': [(270, 470), (320, 452), (390, 450), (460, 480), (500, 520), (470, 555), (400, 590), (360, 595),
                   (300, 560), (268, 520)],
    'north_east': [(870, 180), (920, 140), (1000, 120), (1070, 115), (1120, 125), (1145, 160), (1120, 200),
                   (1060, 215), (980, 235), (900, 220)],
    'east': [(1260, 280), (1310, 252), (1370, 250), (1405, 270), (1410, 340), (1395, 410), (1350, 460), (1300, 470),
             (1265, 430), (1252, 350)],
}
# The polar lands: an ice cap over each pole, its coast at about these latitudes (the north one draws back over the
# far north-west, where an island lies off it).
POLAR = {'polar_north': 74.0, 'polar_south': -68.0}
LAND_ORDER = ('ashen', 'old', 'lantern', 'west', 'equator', 'south_west', 'north_east', 'east', 'polar_north',
              'polar_south')
NOISE = {'west': 0.6, 'equator': 0.6, 'south_west': 0.6, 'north_east': 0.6, 'east': 0.6}

# The empty lands' zones, by the climate of their latitude (names are placeholders for Narrative's).
EMPTY_ZONES = [
    # the east land: hot and dry in the north, a jungle on the equator, temperate in the south
    ('desert', 'The Pale Dunes', 'Les Dunes pâles', [(1330, 278), (1300, 290), (1370, 285)]),
    ('jungle', 'The Tidewood', 'Le Bois des marées', [(1330, 350), (1300, 375), (1370, 360)]),
    ('temperate', 'The Orchard Coast', 'La Côte des vergers', [(1330, 440), (1300, 450)]),
    # the west land: a hot dry coast in the north, temperate in the south
    ('desert', 'The Ember Dunes', 'Les Dunes de braise', [(80, 430), (120, 440)]),
    ('temperate', 'The Wick Meadows', 'Les Prés de la mèche', [(80, 530), (110, 550)]),
    # the equator land: the jungle belt
    ('jungle', 'The Green Deep', 'Les Profondeurs vertes', [(380, 360), (320, 360), (440, 360)]),
    # the south-west land: the dry belt, then temperate
    ('desert', 'The Bone Flats', 'Les Plaines d’os', [(330, 470), (420, 480)]),
    ('temperate', 'The Grey Downs', 'Les Collines grises', [(360, 560), (440, 540)]),
    # the north-east land: cold-temperate, frost along its north coast
    ('temperate', 'The Long Pines', 'Les Longs Pins', [(980, 190), (1060, 180), (920, 190)]),
    ('frost', 'The Rime Coast', 'La Côte du Givre', [(1010, 128), (1080, 125)]),
    # the polar lands
    ('frost', 'The White Crown', 'La Couronne blanche', [(300, 20), (700, 25), (1100, 30), (1350, 45)]),
    ('frost', 'The Mute Ice', 'Les Glaces muettes', [(200, 690), (600, 690), (1000, 690), (1300, 690)]),
]

# The sea places, put on the sphere by hand: the storm on the crossing between the Lantern Isles and the Old
# Continent; the wreck in the cold sea east of the Ashen Continent.
SEA_AT = {'storm': (790, 300), 'wreck': (830, 128)}

# Twelve archipelagos, empty for ship content (voyages, wrecks, hunts) later: id -> (centre, half-size in board
# pixels, islands, seed). Each sits clear of the lands and of the crossing.
BOARD_ARCHIPELAGOS = {
    'far_north_west': ((130, 68), (95, 22), 4, 1),
    'north_west': ((105, 170), (60, 30), 4, 3),
    'west_isles': ((115, 315), (45, 40), 5, 4),
    'frost_isle': ((930, 100), (30, 10), 2, 6),
    'ashen_east': ((745, 205), (40, 30), 4, 7),
    'lantern_east': ((850, 335), (35, 28), 3, 9),
    'mid_sea': ((955, 290), (65, 32), 5, 5),
    'old_north': ((1150, 290), (42, 35), 4, 8),
    'north_east': ((1215, 205), (42, 32), 4, 10),
    'far_east': ((1360, 140), (60, 28), 3, 12),
    'south_mid': ((635, 520), (60, 40), 5, 13),
    'south_east': ((1335, 540), (55, 35), 4, 11),
}


# Narrative's names (docs/proposals/location-names-narrative.md): the empty lands, the oceans (labels, at board
# pixels), the archipelagos and their islands (in the order the islands are listed, largest first).
LAND_NAMES = {
    'west': ('The Sundown Lands', 'Les Terres du couchant'),
    'equator': ('The Green Girdle', 'La Ceinture verte'),
    'south_west': ('The Gaunt Lands', 'Les Terres décharnées'),
    'north_east': ('The Morning Shore', 'Le Rivage du matin'),
    'east': ('The Far Dawn', 'L’Aube lointaine'),
    'polar_north': ('The Long Winter', 'Le Long Hiver'),
    'polar_south': ('The Last Shelf', 'La Dernière Banquise'),
}
OCEANS = [('the Sundown Deep', 'les Abysses du couchant', (225, 385)),
          ('the Dawn Deep', 'les Abysses de l’aube', (1200, 625)),
          ('the Rime Sea', 'la Mer du Givre', (1050, 92)),
          ('the Silent Sea', 'la Mer du silence', (900, 612))]
ARCHIPELAGO_NAMES = {
    'far_north_west': ('The Seabird Teeth', 'Les Dents des oiseaux',
                       [('Skua Rock', 'Le Rocher du skua'), ('The Fulmar', 'Le Fulmar'),
                        ('Puffin Hold', 'Le Terrier des macareux')]),
    'north_west': ('The Cold Beacons', 'Les Phares froids',
                   [('Beacon Cairn', 'Le Cairn-phare'), ('Ice Candle', 'La Bougie de glace'),
                    ('The Last Wick', 'La Dernière Mèche')]),
    'west_isles': ('The Sundown Isles', 'Les Îles du couchant', [('Vesper', 'Vêpres'), ('Compline', 'Complies')]),
    'frost_isle': ('The Hoar Isle', 'L’Île de givre', [('Hoarhold', 'Le Fort de givre')]),
    'ashen_east': ('The Ember Stone', 'La Pierre de braise', [('Cinder Rock', 'Le Roc de cendre')]),
    'lantern_east': ('The Lantern Sisters', 'Les Sœurs de la Lanterne',
                     [('Tinder', 'L’Amadou'), ('Taper', 'Le Cierge'), ('Snuff', 'L’Éteignoir')]),
    'mid_sea': ('The Stepping Stones', 'Les Pierres du gué',
                [('First Stone', 'La Première Pierre'), ('Salt Stone', 'La Pierre salée'),
                 ('Gull’s Rest', 'Le Repos du goéland'), ('Wreckers’ Cay', 'L’Îlot des naufrageurs'),
                 ('Last Stone', 'La Dernière Pierre')]),
    'old_north': ('The Giant’s Hand', 'La Main du géant',
                  [('Thumb Rock', 'Le Rocher du pouce'), ('Index Rock', 'Le Rocher de l’index')]),
    'north_east': ('The Twin Lights', 'Les Feux jumeaux',
                   [('First Light', 'La Première Lueur'), ('Second Light', 'La Seconde Lueur')]),
    'far_east': ('The Last Landfall', 'La Dernière Escale', [('Farewell Isle', 'L’Île des Adieux')]),
    'south_mid': ('The Quiet Reefs', 'Les Récifs silencieux',
                  [('Hush Reef', 'Le Récif du silence'), ('Drift Isle', 'L’Île à la dérive'),
                   ('Ice-Tongue', 'La Langue de glace')]),
    'south_east': ('The Whalers’ Graves', 'Les Tombes des baleiniers',
                   [('Harpoon', 'Le Harpon'), ('Tallow Cay', 'L’Îlot du suif'), ('Spout', 'Le Souffleur')]),
}


def remap_design():
    """Moves the story lands to the sphere and adds the rest of the world (see the module's header)."""
    global ARCHIPELAGOS, SEAS
    old = {k: list(v) for k, v in LANDS.items()}
    polys = {k: Polygon(v) for k, v in old.items()}
    span = {}
    for k, v in old.items():
        lons = [old_lonlat(x, y)[0] for x, y in v]
        span[k] = (min(lons), max(lons))

    def land_of(pt):
        q = Point(pt)
        return min(polys, key=lambda k: polys[k].distance(q))

    def move(pt, land=None):
        land = land or land_of(pt)
        lon, lat = old_lonlat(*pt)
        a0, a1 = span[land]
        b0, b1 = STORY_LON[land]
        return chart_xy(b0 + (lon - a0) / (a1 - a0) * (b1 - b0), lat)

    for k in old:
        LANDS[k] = [move(p, k) for p in old[k]]
    for k, pt in list(PLACES.items()):
        PLACES[k] = board([SEA_AT[k]])[0] if k in SEA_PLACES else move(pt)
    # Saltmouth (v1.536), set in the sphere's own units at the centre of its old six district spots
    PLACES['saltmouth'] = (207.002, 98.093)
    for i, (biome, name, fr, seeds) in enumerate(ZONES):
        ZONES[i] = (biome, name, fr, [move(p) for p in seeds])
    for i, (name, fr, line, size, snow, ember) in enumerate(RANGES):
        RANGES[i] = (name, fr, [move(p) for p in line], size, snow, ember)
    for i, line in enumerate(RIVERS):
        RIVERS[i] = [move(p) for p in line]
    for k, pt in list(FEATURES.items()):
        FEATURES[k] = move(pt)

    for k, v in EMPTY_LANDS.items():
        LANDS[k] = board(v)
    for biome, name, fr, seeds in EMPTY_ZONES:
        ZONES.append((biome, name, fr, board(seeds)))
    ARCHIPELAGOS = {}
    for aid, ((cx, cy), (hx, hy), count, seed) in BOARD_ARCHIPELAGOS.items():
        (x, y), = board([(cx, cy)])
        ARCHIPELAGOS[aid] = (x, y, hx * W / 1440.0, hy * H / 720.0, count, seed)
    SEAS = [('the Narrow Sea', 'la Mer Étroite', board([(770, 440)])[0]),
            ('the Open Water', 'la Haute Mer', board([(560, 610)])[0]),
            ('the Grey Water', 'l’Eau Grise', board([(800, 100)])[0])] + \
           [(en, fr, board([at])[0]) for en, fr, at in OCEANS]


def polar_land(name, rng):
    """The ice cap over a pole: from the chart's top (or bottom) edge down to a wobbling coast."""
    north = name == 'polar_north'
    xs = np.linspace(0, W, 129)
    wob = np.cumsum(rng.normal(0, 0.9, xs.size))
    wob = ndimage.gaussian_filter1d(wob - np.linspace(wob[0], wob[-1], xs.size), 2.0)
    coast = []
    for x, w in zip(xs, wob):
        lat = POLAR[name]
        lon = (x / W - 0.5) * LON_SPAN
        if north and lon < -76:
            # drawn back over the far north-west, where an island lies off the cap
            lat += 6.0 * min(1.0, (-76 - lon) / 20.0)
        coast.append((float(x), chart_xy(0, lat)[1] + float(w) * (1 if north else -1)))
    edge = 0.0 if north else H
    pts = [(0.0, edge)] + coast + [(W, edge)]
    return Polygon(pts if north else list(reversed(pts)))


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
    for name in POLAR:
        out[name] = [polar_land(name, rng)]
    for name, outline in LANDS.items():
        f = signed_field(outline)
        f = f + NOISE.get(name, 1.0) * (13.0 * n1 + 6.5 * n2 + 2.6 * n3)
        if name in STORY_LON:
            # narrower than first drawn: grown a little, so the coast places stay ashore
            f = f + 2.5
        # land stays off the seam at the chart's left and right edges (the poles are the polar lands')
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        edge = np.minimum(xx, shape[1] - xx) / RES
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


def build_archipelagos(main_union):
    rng = np.random.default_rng(SEED + 100)
    shape = (int(H * RES), int(W * RES))
    n1, n2, n3 = noise(shape, 8, rng), noise(shape, 4, rng), noise(shape, 2, rng)
    out = {}
    for aid, (cx, cy, hx, hy, count, seed) in ARCHIPELAGOS.items():
        r = np.random.default_rng(seed * 17 + 1)
        centres = []
        tries = 0
        while len(centres) < count and tries < 4000:
            tries += 1
            a, rr = r.random() * 2 * math.pi, math.sqrt(r.random())
            x, y = cx + hx * rr * math.cos(a), cy + hy * rr * math.sin(a)
            if all(math.dist((x, y), c[:2]) > 7.5 for c in centres) and main_union.distance(Point(x, y)) > 6:
                centres.append((x, y, 2.4 + 3.4 * r.random() ** 1.3))
        field = np.full(shape, -50.0)
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        for (x, y, rad) in centres:
            field = np.maximum(field, rad - np.hypot(xx / RES - x, yy / RES - y))
        field = field + 1.6 * n1 + 0.8 * n2 + 0.35 * n3
        field = ndimage.gaussian_filter(field, 1.0)
        polys = []
        for c in measure.find_contours(field, 0.0):
            pts = [(p[1] / RES, p[0] / RES) for p in c]
            if len(pts) > 4:
                poly = Polygon(pts).buffer(0)
                if isinstance(poly, Polygon) and poly.area >= 3.0:
                    polys.append(poly.simplify(0.25, preserve_topology=True))
        polys.sort(key=lambda p: -p.area)
        out[aid] = polys
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
    for lat in range(-80, 90, 10):
        y = (0.5 - lat / 180) * H * px
        d.line([(0, y), (W * px, y)], fill=(40, 80, 92), width=1)
        d.text((4, y + 2), '%d°' % lat, fill=(120, 170, 180))
    for v in lands.values():
        for poly in v:
            d.polygon([(x * px, y * px) for x, y in poly.exterior.coords], fill=(72, 70, 80), outline=(150, 148, 160))
    pal = {'temperate': (90, 130, 80), 'desert': (170, 140, 80), 'arid_coast': (150, 120, 90), 'sea_cliffs': (110, 110, 130),
           'ashlands': (100, 95, 100), 'volcanic': (150, 80, 70), 'frost': (150, 170, 190), 'tear': (130, 100, 160), 'fen': (70, 110, 100),
           'jungle': (60, 120, 60)}
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
    best = np.full(mask.shape, -1, dtype=int)
    yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
    # each land is split among the zones whose seeds lie on it, so no zone reaches across the sea
    for name in LAND_ORDER:
        own = land_mask({name: lands[name][:1]})
        poly = lands[name][0]
        here = [zi for zi, z in enumerate(ZONES) if poly.buffer(3.0).contains(Point(z[3][0]))]
        bestd = np.full(mask.shape, 1e9)
        for zi in here:
            for sx, sy in ZONES[zi][3]:
                d = (xx / RES - sx) ** 2 + (yy / RES - sy) ** 2
                upd = own & (d < bestd)
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
    return (0.5 - y / H) * LAT_SPAN, (x / W - 0.5) * LON_SPAN


FEATURES = {  # 'kind|name' -> where; the rest of each feature is chart B's (names, notes, clan, angle)
    'village|Tallow Street': (75, 133), 'bridge|The Stone Bridge': (100, 128), 'giant|the stone giant of Alster’s harbour': (57, 126),
    'village|the Salt Pans': (139, 98), 'giant|the giant in Saltmouth’s harbour mouth': (151, 85),
    'seat|The Brig': (140, 81), 'seat|Lowtide': (194, 90),
    'seat|The Lantern Throne': PLACES['candlehold'], 'village|the Salt Marsh': (66, 83), 'seat|The Open Hand’s hall': (66, 76),
    'seat|The Spire of Judgment': PLACES['spire'], 'seat|Anvil Gate': (155, 46), 'seat|Highhearth': PLACES['highhearth'],
    'village|the Frost Quarry': (170, 17), 'seat|Akagiri': PLACES['akagiri'], 'village|the Hot Springs': (172, 43),
    'seat|The Exorcists’ Gate': (158, 31), 'site|The Exorcists’ Road': (152, 36), 'village|the Slag Kilns': (151, 33),
    'seat|The Kindly Hill': PLACES['kindly'], 'seat|The Heron’s Wake': (62, 37), 'village|the False Lamps': (99, 54),
    'seat|The Vigil’s Wall': (186, 31),
}


def write_dart(lands, zones):
    out = ['// GENERATED by tool/fmg_chart/story_world.py: do not edit by hand.',
           '// ignore_for_file: prefer_const_constructors',
           '// A story-true geography for the world chart, drawn from the story and the globe: the whole sphere (board 11),',
           '// the travel-history map\'s chart (MapShape.story, see map_charts.dart and travel_history.dart).',
           "import 'dart:math' as math;\nimport 'dart:ui' show Offset;\n\nimport 'map_charts.dart';\n",
           'final ChartGeography chartWorldStory = ChartGeography(',
           '  lonSpan: 2 * math.pi,', '  latSpan: math.pi,', '  places: {']
    for k, (x, y) in PLACES.items():
        out.append("    '%s': Offset(%g, %g)," % (k, x, y))
    out.append('  },')
    loops = []
    loops_index = {}
    for name in LAND_ORDER:
        poly = lands[name][0].simplify(0.3, preserve_topology=True)
        loops.append(list(poly.exterior.coords)[:-1])
    for aid in ARCHIPELAGOS:
        loops_index[aid] = []
        for poly in lands['arch:' + aid]:
            loops_index[aid].append(len(loops))
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
    out.append('')
    out.append('/// The empty lands (the climate bands\' fill, for what comes later, the polar lands among them), by id, the')
    out.append('/// index in `lands`.')
    out.append('const Map<String, int> storyEmptyLands = {')
    for name in LAND_ORDER[3:]:
        out.append("  '%s': %d," % (name, LAND_ORDER.index(name)))
    out.append('};')
    out.append('')
    def q(t):
        return "'%s'" % t.replace("'", "\\'")
    out.append('/// The empty lands\' names (Narrative\'s), by id: English, French.')
    out.append('const Map<String, ({String en, String fr})> storyLandNames = {')
    for k, (en, fr) in LAND_NAMES.items():
        out.append("  '%s': (en: %s, fr: %s)," % (k, q(en), q(fr)))
    out.append('};')
    out.append('')
    out.append('/// The archipelagos\' names (Narrative\'s), by id: English, French.')
    out.append('const Map<String, ({String en, String fr})> storyArchipelagoNames = {')
    for k, (en, fr, _) in ARCHIPELAGO_NAMES.items():
        out.append("  '%s': (en: %s, fr: %s)," % (k, q(en), q(fr)))
    out.append('};')
    out.append('')
    out.append('/// Each island\'s name (Narrative\'s), by its index in `lands`.')
    out.append('const Map<int, ({String en, String fr})> storyIslandNames = {')
    for aid, ix in loops_index.items():
        names = ARCHIPELAGO_NAMES[aid][2]
        assert len(names) == len(ix), (aid, len(names), len(ix))
        for i, (en, fr) in zip(ix, names):
            out.append("  %d: (en: %s, fr: %s)," % (i, q(en), q(fr)))
    out.append('};')
    out.append('')
    out.append('/// The archipelagos: empty lands for ship content, by id, each the indices of its islands in `lands`.')
    out.append('const Map<String, List<int>> storyArchipelagoLands = {')
    for aid, ix in loops_index.items():
        out.append("  '%s': %s," % (aid, ix))
    out.append('};')
    return '\n'.join(out)


def main():
    remap_design()
    lands = build_lands()
    main_union = unary_union([p for v in lands.values() for p in v])
    for aid, polys in build_archipelagos(main_union).items():
        lands['arch:' + aid] = polys
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
