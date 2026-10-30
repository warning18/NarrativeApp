// Four versions of every scene (docs/proposals/scene-backgrounds.md): a
// version is a window of the kit's own scrolling world, so version k+1 is the
// land right after version k, plus a landmark of its own (a dead tree, columns,
// a far ship, a cart) that scrolls past every so often. A scene shows its
// versions one after the other in a seeded order (1, 2, 3 or 4, 2, 3...), no
// two alike in a row.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'side_view.dart';

/// How many versions every scene has.
const int sceneVersionCount = 4;

/// The version shown at [step] of a scene seeded by [seed] (a route id, a
/// place id): the four versions in a shuffled order that starts over each
/// round, never the same twice in a row.
int sceneVersionAt(String seed, int step) {
  var h = 17;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final round = step ~/ sceneVersionCount;
  List<int> order(int r) {
    final rng = math.Random(h + r * 7919);
    return [0, 1, 2, 3]..shuffle(rng);
  }

  final now = order(round);
  final before =
      step % sceneVersionCount == 0 && round > 0 ? order(round - 1).last : null;
  // A round never opens on the version the last one closed on.
  if (before != null && now.first == before) {
    now.add(now.removeAt(0));
  }
  return now[step % sceneVersionCount];
}

/// [layers] of the scene [kit] ('desert', 'ruins', 'frost', 'fen', 'cliffs',
/// 'sea-open'..'sea-ashen', 'street-house'..'street-fort') as version
/// [version] (0 to 3): the world window, then the landmark.
List<SideLayer> withSceneVersion(
    List<SideLayer> layers, String kit, int version) {
  final v = version.clamp(0, sceneVersionCount - 1);
  if (v == 0 && !_marks.containsKey(kit)) {
    return layers;
  }
  final street = kit.startsWith('street-');
  return [
    for (final layer in layers)
      SideLayer(
          layer.speed,
          street || v == 0
              ? layer.paint
              : (c, s, scroll, t, u) =>
                  layer.paint(c, s, scroll + v * s.width, t, u)),
    if (v > 0 && _marks[kit] != null)
      SideLayer(0.8, (canvas, size, scroll, t, u) {
        final g = _G(canvas, size, u, _inkOf(kit));
        final cols = size.width / u;
        // The landmark comes round once every 1.7 screens.
        final period = cols * 1.7;
        final shift = (-(scroll / u) % period + period) % period;
        for (final dx in [shift, shift - period]) {
          canvas.save();
          canvas.translate(dx.floorToDouble() * u, 0);
          _marks[kit]![v - 1](g);
          canvas.restore();
        }
      }),
  ];
}

class _Ink {
  const _Ink(this.dark, this.mid, this.rim);
  final Color dark, mid, rim;
}

_Ink _inkOf(String id) {
  if (id.startsWith('sea-')) {
    return const _Ink(Color(0xFF0E1A26), Color(0xFF2A4358), Color(0xFFBFD6E0));
  }
  if (id.startsWith('street-')) {
    return const _Ink(Color(0xFF2A211B), Color(0xFF5A4636), Color(0xFFE0C089));
  }
  return switch (id) {
    'desert' =>
      const _Ink(Color(0xFF4A2F22), Color(0xFF7A5238), Color(0xFFE2B078)),
    'ruins' =>
      const _Ink(Color(0xFF1E1822), Color(0xFF3B3040), Color(0xFF8A7390)),
    'frost' =>
      const _Ink(Color(0xFF24383A), Color(0xFF4D6A6E), Color(0xFFF2F8FF)),
    'fen' =>
      const _Ink(Color(0xFF14201A), Color(0xFF2F4A3A), Color(0xFF8FB08A)),
    _ => const _Ink(Color(0xFF2B342F), Color(0xFF55635A), Color(0xFFD8D6C4)),
  };
}

/// The pixel grid a landmark is drawn on.
class _G {
  _G(this.c, this.size, this.u, this.ink) : cols = size.width / u;
  final Canvas c;
  final Size size;
  final double u;
  final _Ink ink;
  final double cols;

  void r(Color colour, num x, num y, num w, num h) => sidePixels(
      c,
      u,
      Paint()..color = colour,
      x.toDouble(),
      y.toDouble(),
      w.toDouble(),
      h.toDouble());

  double rnd(int i, [int salt = 0]) {
    final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }
}

typedef _Mark = void Function(_G g);

final Map<String, List<_Mark>> _marks = {
  'desert': [
    (g) {
      _deadTree(g, 34, 62);
      _bones(g, 62, 63);
    },
    (g) {
      _cart(g, 46, 63);
      _birds(g, 74, 22, 3);
    },
    (g) {
      _stones(g, 30, 61);
      _cairn(g, 92, 63);
    },
  ],
  'ruins': [
    (g) => _columns(g, 36, 62),
    (g) => _archGate(g, 70, 62),
    (g) {
      _obelisk(g, 40, 62);
      _birds(g, 90, 18, 4);
    },
  ],
  'frost': [
    (g) => _pond(g, 56, 64),
    (g) {
      _fallenPine(g, 40, 63);
      _cairn(g, 96, 63);
    },
    (g) {
      _sledge(g, 38, 63);
      _signpost(g, 88, 63);
    },
  ],
  'fen': [
    (g) => _wisps(g, 30, 44, 7),
    (g) => _pier(g, 20, 62),
    (g) => _graves(g, 56, 62),
  ],
  'cliffs': [
    (g) {
      _birds(g, 40, 20, 5);
      _rockStack(g, 96, 63);
    },
    (g) => _boatRibs(g, 44, 63),
    (g) => _beacon(g, 78, 62),
  ],
  for (final w in const ['open', 'shallows', 'drowned', 'abyss', 'ashen'])
    'sea-$w': [
      (g) => _farShip(g, 70, 38),
      (g) => _island(g, 34, 38),
      (g) {
        switch (w) {
          case 'drowned':
            _mastTips(g, 60, 42);
          case 'abyss':
            _motes(g, 24, 46, 8);
          case 'ashen':
            _hulk(g, 72, 40);
          default:
            _buoy(g, 74, 46);
            _birds(g, 34, 14, 4);
        }
      },
    ],
  for (final s in const [
    'house',
    'tavern',
    'warehouse',
    'shop',
    'temple',
    'fort'
  ])
    'street-$s': [
      (g) {
        _marketCart(g, 14, 60);
        _barrels(g, 112, 60);
      },
      (g) {
        _lampPost(g, 12, 58);
        _crates(g, 114, 60);
      },
      (g) {
        _lampPost(g, 12, 58);
        _barrels(g, 114, 60);
      },
    ],
};

// --- props ---------------------------------------------------------------------

void _deadTree(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 16, 2, 16);
  for (var k = 0; k < 6; k++) {
    g.r(i.dark, x + 2 + k, y - 14 - k * 0.7, 1, 1);
    g.r(i.dark, x - 1 - k, y - 11 - k * 0.6, 1, 1);
  }
  g.r(i.dark, x + 5, y - 20, 1, 3);
  g.r(i.dark, x - 4, y - 16, 1, 3);
  g.r(i.rim, x, y - 16, 1, 6);
}

void _bones(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 5; k++) {
    g.r(i.rim, x + k * 2, y - 3 + (k == 0 || k == 4 ? 2 : (k == 2 ? 0 : 1)), 1,
        3);
  }
  g.r(i.rim, x - 1, y, 12, 1);
  g.r(i.rim, x + 12, y - 2, 3, 3);
  g.r(i.dark, x + 13, y - 1, 1, 1);
}

void _cart(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.mid, x, y - 6, 14, 4);
  g.r(i.dark, x, y - 6, 14, 1);
  g.r(i.dark, x + 14, y - 8, 1, 6);
  for (var dy = -2; dy <= 2; dy++) {
    final half = (2.6 - dy.abs() * 0.8).round();
    g.r(i.dark, x + 4 - half, y - 3 + dy, half * 2 + 1, 1);
  }
  g.r(i.mid, x + 3, y - 3, 1, 1);
  g.r(i.mid, x + 9, y - 8, 4, 2);
  g.r(i.dark, x + 16, y - 3, 2, 3);
}

void _birds(_G g, double x, double y, int n) {
  for (var k = 0; k < n; k++) {
    final bx = x + k * 7 + g.rnd(k, 1) * 4,
        by = y + (k % 3) * 3.0 + g.rnd(k, 2) * 3;
    g.r(g.ink.dark, bx, by, 1, 1);
    g.r(g.ink.dark, bx - 1, by - 1, 1, 1);
    g.r(g.ink.dark, bx + 1, by - 1, 1, 1);
    g.r(g.ink.dark, bx - 2, by - 1, 1, 1);
    g.r(g.ink.dark, bx + 2, by - 1, 1, 1);
  }
}

void _stones(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 3; k++) {
    final h = const [18, 13, 16][k];
    final sx = x + k * 9;
    g.r(i.dark, sx, y - h, 5, h);
    g.r(i.mid, sx, y - h, 1, h);
    g.r(i.rim, sx, y - h, 5, 1);
  }
  g.r(i.dark, x, y - 20, 14, 2);
  g.r(i.rim, x, y - 20, 14, 1);
}

void _cairn(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 4; k++) {
    final w = 9 - k * 2;
    g.r(k.isEven ? i.mid : i.dark, x + k, y - 2 - k * 2, w, 2);
    g.r(i.rim, x + k, y - 2 - k * 2, w, 1);
  }
}

void _columns(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 3; k++) {
    final h = const [22, 14, 18][k];
    final cx = x + k * 14;
    g.r(i.mid, cx, y - h, 6, h);
    g.r(i.rim, cx, y - h, 1, h);
    g.r(i.dark, cx + 5, y - h, 1, h);
    g.r(i.rim, cx - 1, y - h - 1, 8, 2);
    g.r(i.dark, cx - 1, y - 1, 8, 2);
  }
  g.r(i.mid, x + 18, y - 2, 6, 2);
  g.r(i.mid, x + 4, y - 1, 3, 1);
}

void _archGate(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.mid, x, y - 26, 7, 26);
  g.r(i.mid, x + 23, y - 20, 7, 20);
  g.r(i.rim, x, y - 26, 1, 26);
  g.r(i.rim, x + 23, y - 20, 1, 20);
  for (var k = 0; k < 14; k++) {
    final dy = 5 * math.sin(k / 13 * math.pi);
    g.r(i.mid, x + 7 + k, y - 26 - dy + 6, 1, 4);
  }
  g.r(i.dark, x + 10, y - 14, 10, 14);
}

void _obelisk(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x - 2, y - 2, 11, 2);
  for (var k = 0; k < 26; k++) {
    g.r(i.mid, x + 1 + (k > 20 ? (k - 20) * 0.3 : 0), y - 3 - k,
        5 - (k > 20 ? (k - 20) * 0.6 : 0), 1);
  }
  g.r(i.rim, x + 1, y - 28, 1, 25);
  g.r(i.rim, x + 7, y - 24, 6, 4);
  g.r(i.dark, x + 9, y - 20, 4, 3);
}

void _pond(_G g, double x, double y) {
  final i = g.ink;
  for (var dy = -3; dy <= 3; dy++) {
    final half = 22 * math.sqrt(math.max(0, 1 - (dy / 4) * (dy / 4)));
    g.r(const Color(0xFFBFD8E6), x - half, y + dy, half * 2, 1);
    g.r(const Color(0xFFE6F1F8), x - half * 0.6, y + dy, half * 1.0, 1);
  }
  g.r(i.mid, x - 10, y - 1, 6, 1);
  g.r(i.mid, x + 4, y, 8, 1);
  g.r(i.mid, x - 2, y + 1, 1, 2);
}

void _fallenPine(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 5, 28, 4);
  g.r(i.rim, x, y - 5, 28, 1);
  for (var k = 0; k < 5; k++) {
    g.r(i.dark, x + 4 + k * 5, y - 8 - (k % 2), 1, 3);
  }
  g.r(i.mid, x + 26, y - 6, 4, 6);
}

void _sledge(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 2, 18, 1);
  g.r(i.dark, x - 1, y - 4, 1, 3);
  g.r(i.mid, x + 2, y - 7, 12, 5);
  g.r(i.rim, x + 2, y - 7, 12, 1);
  g.r(i.dark, x + 5, y - 10, 5, 3);
}

void _signpost(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 16, 2, 16);
  g.r(i.mid, x + 2, y - 15, 9, 4);
  g.r(i.rim, x + 2, y - 15, 9, 1);
  g.r(i.mid, x - 8, y - 10, 8, 3);
}

void _wisps(_G g, double x, double y, int n) {
  for (var k = 0; k < n; k++) {
    final wx = x + k * 13 + g.rnd(k, 1) * 6, wy = y + g.rnd(k, 2) * 14;
    for (var dy = -3; dy <= 3; dy++) {
      for (var dx = -3; dx <= 3; dx++) {
        final d = dx * dx + dy * dy;
        if (d <= 1) {
          g.r(const Color(0xFFD8F5C8), wx + dx, wy + dy, 1, 1);
        } else if (d <= 9 && (dx + dy) % 2 == 0) {
          g.r(const Color(0xFF8FD6A0).withValues(alpha: 0.45), wx + dx, wy + dy,
              1, 1);
        }
      }
    }
  }
}

void _pier(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.mid, x, y - 3, 44, 2);
  g.r(i.rim, x, y - 3, 44, 1);
  for (var k = 0; k < 6; k++) {
    g.r(i.dark, x + 2 + k * 8, y - 3, 2, 12);
  }
  g.r(i.dark, x + 38, y - 12, 2, 9);
  g.r(const Color(0xFFFFD27A), x + 38, y - 14, 2, 2);
}

void _graves(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 4; k++) {
    final gx = x + k * 11, lean = k.isEven ? 1 : -1;
    g.r(i.mid, gx, y - 8, 5, 8);
    g.r(i.rim, gx, y - 8, 5, 1);
    g.r(i.mid, gx + lean, y - 10, 3, 2);
    if (k == 1) {
      g.r(i.dark, gx + 2, y - 15, 1, 8);
      g.r(i.dark, gx, y - 13, 5, 1);
    }
  }
}

void _rockStack(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 3; k++) {
    final w = 12 - k * 3;
    g.r(k.isEven ? i.mid : i.dark, x + k * 1.5, y - 3 - k * 3, w, 3);
    g.r(i.rim, x + k * 1.5, y - 3 - k * 3, w, 1);
  }
}

void _boatRibs(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 2, 34, 2);
  for (var k = 0; k < 7; k++) {
    final h = 10 - (k - 3).abs() * 1.6;
    g.r(i.dark, x + 3 + k * 4, y - 2 - h, 1, h);
    g.r(i.mid, x + 4 + k * 4, y - 2 - h + 2, 1, h - 2);
  }
  g.r(i.dark, x + 34, y - 8, 2, 8);
}

void _beacon(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 20, 2, 20);
  g.r(i.mid, x - 2, y - 22, 6, 2);
  g.r(const Color(0xFFFFB43C), x - 1, y - 27, 4, 5);
  g.r(const Color(0xFFFFE08A), x, y - 26, 2, 3);
  g.r(i.rim.withValues(alpha: 0.5), x - 4, y - 30, 1, 1);
}

void _farShip(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 2, 11, 2);
  g.r(i.dark, x + 1, y - 3, 9, 1);
  g.r(i.dark, x + 5, y - 14, 1, 12);
  for (var k = 0; k < 9; k++) {
    g.r(i.rim.withValues(alpha: 0.85), x + 6, y - 13 + k, 1 + k * 0.5, 1);
  }
  for (var k = 0; k < 6; k++) {
    g.r(i.rim.withValues(alpha: 0.7), x + 4 - k * 0.6, y - 12 + k, 1 + k * 0.4,
        1);
  }
}

void _island(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 26; k++) {
    final h = 7 * math.sin(k / 25 * math.pi);
    g.r(i.dark, x + k, y - h, 1, h + 1);
  }
  g.r(i.mid, x + 10, y - 12, 1, 6);
  for (var k = -3; k <= 3; k++) {
    g.r(i.mid, x + 10 + k, y - 12 - (3 - k.abs()) * 0.5, 1, 1);
  }
}

void _buoy(_G g, double x, double y) {
  g.r(const Color(0xFFD64A3A), x, y - 4, 3, 3);
  g.r(const Color(0xFFF2E8D8), x, y - 2, 3, 1);
  g.r(g.ink.dark, x + 1, y - 7, 1, 3);
}

void _mastTips(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 2; k++) {
    final mx = x + k * 19;
    g.r(i.dark, mx, y - 12 + k * 3, 1, 12);
    g.r(i.dark, mx - 3, y - 9 + k * 3, 7, 1);
    g.r(i.mid, mx + 1, y - 8 + k * 3, 3, 2);
  }
}

void _motes(_G g, double x, double y, int n) {
  for (var k = 0; k < n; k++) {
    final mx = x + k * 14 + g.rnd(k, 1) * 6, my = y + g.rnd(k, 2) * 14;
    g.r(const Color(0xFFB88CFF), mx, my, 2, 2);
    g.r(const Color(0xFFB88CFF).withValues(alpha: 0.4), mx - 1, my - 1, 4, 4);
  }
}

void _hulk(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 3, 22, 3);
  g.r(i.dark, x + 2, y - 5, 18, 2);
  g.r(i.dark, x + 12, y - 16, 1, 12);
  g.r(i.dark, x + 8, y - 12, 9, 1);
  g.r(const Color(0xFFFF8A3C), x + 6, y - 6, 2, 1);
  g.r(const Color(0xFFFF8A3C), x + 15, y - 5, 1, 1);
}

void _marketCart(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.mid, x, y - 8, 20, 4);
  g.r(i.rim, x, y - 8, 20, 1);
  g.r(const Color(0xFFB04A3A), x + 2, y - 11, 6, 3);
  g.r(const Color(0xFFD9A93C), x + 9, y - 11, 6, 3);
  g.r(i.dark, x + 3, y - 4, 4, 4);
  g.r(i.dark, x + 14, y - 4, 4, 4);
  g.r(i.dark, x - 5, y - 6, 5, 1);
}

void _barrels(_G g, double x, double y) {
  final i = g.ink;
  for (var k = 0; k < 2; k++) {
    final bx = x + k * 9;
    g.r(i.mid, bx, y - 9, 7, 9);
    g.r(i.rim, bx, y - 9, 7, 1);
    g.r(i.dark, bx, y - 6, 7, 1);
    g.r(i.dark, bx, y - 2, 7, 1);
  }
  g.r(i.mid, x + 3, y - 17, 7, 8);
  g.r(i.dark, x + 3, y - 14, 7, 1);
}

void _crates(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.mid, x, y - 8, 9, 8);
  g.r(i.dark, x, y - 8, 9, 1);
  g.r(i.dark, x + 4, y - 8, 1, 8);
  g.r(i.mid, x + 10, y - 6, 7, 6);
  g.r(i.dark, x + 10, y - 6, 7, 1);
  g.r(i.mid, x + 3, y - 15, 8, 7);
  g.r(i.dark, x + 3, y - 15, 8, 1);
}

void _lampPost(_G g, double x, double y) {
  final i = g.ink;
  g.r(i.dark, x, y - 26, 2, 26);
  g.r(i.dark, x - 2, y - 28, 6, 2);
  g.r(const Color(0xFFFFD27A), x - 1, y - 33, 4, 5);
  g.r(i.dark, x - 2, y - 34, 6, 1);
}
