// Where a town's services stand on its city plan (wave 14): fixed pins for
// the notice board, the market, the tavern, the temple, the forge and the
// harbour, each on a real lot or square of the town's record in
// city_plans.json. Laid out here, on the record's raw JSON (no dart:ui, so
// tool/city_plans/ can run it), and stored in the record as `services`; the
// game reads them through town_services.dart.
import 'dart:convert';

/// The kinds of service a town's plan can show, as the record writes them.
const List<String> townServiceKinds = [
  'notice_board',
  'market',
  'tavern',
  'temple',
  'forge',
  'harbour',
];

/// The district a town's forge stands in, where the story puts its smiths;
/// a town not listed has no forge pin.
const Map<String, String> townForgeDistricts = {
  'saltmouth': 'saltmouth_wharf',
  'ashen_quarter': 'ashen_quarter_cinder_row',
  'emberwick': 'emberwick_smithy_lane',
  'akagiri': 'akagiri_forge_terrace',
  'white_anchorage': 'white_anchorage_hulls',
};

typedef _P = ({double x, double y});

List<_P> _poly(Object? raw) => [
      for (final p in (raw as List? ?? const []))
        if (p is List && p.length >= 2)
          (x: (p[0] as num).toDouble(), y: (p[1] as num).toDouble()),
    ];

_P _centre(List<_P> poly) {
  if (poly.isEmpty) return (x: 500, y: 500);
  var x = 0.0, y = 0.0;
  for (final p in poly) {
    x += p.x;
    y += p.y;
  }
  return (x: x / poly.length, y: y / poly.length);
}

bool _inside(_P p, List<_P> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.y > p.y) != (b.y > p.y) &&
        p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

double _d2(_P a, _P b) => (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);

/// The service pins of the town [cityId], from its raw record [record] (a
/// city_plans.json entry): `{id, kind, at: [x, y], district}` each, in the
/// order of [townServiceKinds]. Each stands on a square (the market, the
/// notice board, the harbour) or a building lot (the tavern, the temple,
/// the forge) of the record, in the district that lot or square lies in;
/// a lot already carrying a way (the record's `anchors`) is passed over
/// while another is free. The same record gives the same pins.
List<Map<String, Object>> placeTownServices(
    String cityId, Map<String, dynamic> record) {
  final districts = <String, List<_P>>{
    for (final MapEntry(:key, :value)
        in ((record['districts'] as Map?) ?? const {}).entries)
      key.toString(): _poly((value as Map)['shape']),
  };
  String? districtAt(_P p) {
    for (final MapEntry(:key, :value) in districts.entries) {
      if (_inside(p, value)) return key;
    }
    return null;
  }

  final squares = [
    for (final s in (record['squares'] as List? ?? const []))
      if (s is Map)
        (kind: s['kind']?.toString() ?? '', shape: _poly(s['shape'])),
  ];
  final lots = [
    for (final b in (record['buildings'] as List? ?? const []))
      if (b is Map)
        (
          id: b['id']?.toString() ?? '',
          kind: b['kind']?.toString() ?? '',
          district: b['district']?.toString() ?? '',
          centre: _centre(_poly(b['shape'])),
        ),
  ];
  final held = {
    for (final v in ((record['anchors'] as Map?) ?? const {}).values)
      v.toString(),
  };
  final taken = <String>{};
  final out = <Map<String, Object>>[];

  List<_P>? squareOf(String kind) {
    for (final s in squares) {
      if (s.kind == kind && s.shape.length >= 3) return s.shape;
    }
    return null;
  }

  void pin(String kind, _P at) {
    final district = districtAt(at);
    if (district == null) return;
    out.add({
      'id': '${cityId}_$kind',
      'kind': kind,
      'at': [at.x.round(), at.y.round()],
      'district': district,
    });
  }

  /// The free lot of [kinds] (any kind when empty) nearest [to], in
  /// [district] when given: a lot with no way on it first.
  void onLot(String kind, _P to, {Set<String> kinds = const {}, String? in_}) {
    final pool = [
      for (final l in lots)
        if ((kinds.isEmpty || kinds.contains(l.kind)) &&
            (in_ == null || l.district == in_) &&
            !taken.contains(l.id) &&
            districtAt(l.centre) == l.district)
          l,
    ]..sort((a, b) {
        final h = (held.contains(a.id) ? 1 : 0)
            .compareTo(held.contains(b.id) ? 1 : 0);
        if (h != 0) return h;
        final d = _d2(a.centre, to).compareTo(_d2(b.centre, to));
        return d != 0 ? d : a.id.compareTo(b.id);
      });
    if (pool.isEmpty) return;
    taken.add(pool.first.id);
    pin(kind, pool.first.centre);
  }

  final market = squareOf('market');
  final heart = market == null ? (x: 500.0, y: 500.0) : _centre(market);
  // The notice board: the plaza's middle, else the market's north edge.
  final plaza = squareOf('plaza');
  _P? board;
  if (plaza != null) {
    board = _centre(plaza);
  } else if (market != null) {
    final top = market.reduce((a, b) => a.y <= b.y ? a : b);
    final p = (x: (heart.x + top.x) / 2, y: (heart.y + top.y) / 2);
    board = _inside(p, market) ? p : null;
  }
  if (board != null) pin('notice_board', board);
  if (market != null) pin('market', heart);
  onLot('tavern', heart, kinds: const {'house', 'hall'});
  onLot('temple', heart, kinds: const {'temple'});
  final forge = townForgeDistricts[cityId];
  final forgeShape = forge == null ? null : districts[forge];
  if (forge != null && forgeShape != null) {
    final label = ((record['districts'] as Map)[forge] as Map)['label'];
    final at = _poly([label]).firstOrNull ?? _centre(forgeShape);
    onLot('forge', at,
        kinds: const {'house', 'shed', 'warehouse', 'stall'}, in_: forge);
  }
  final quay = squareOf('quay');
  if (quay != null) pin('harbour', _centre(quay));
  return out;
}

/// city_plans.json's text: indented JSON with every point ([x, y]) kept on one line.
String encodeCityPlans(Object? value) {
  final text = const JsonEncoder.withIndent('  ').convert(value);
  return '${text.replaceAllMapped(RegExp(r'\[\s+(-?\d+),\s+(-?\d+)\s+\]'), (m) => '[${m[1]}, ${m[2]}]')}\n';
}
