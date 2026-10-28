// The dice on the main Inventory page (UX mock, nothing built): the user asked
// for the dice to be reachable from the inventory. Left: the real screens
// today (the Inventory, then the sheet its Dice slot opens: a plain list).
// Middle: a Dice tab among the tabs, the die in hand lit, the others one
// Equip away. Right: the real ring of face slots (Core's v1.573 screen) that
// a tap on a die would open. All dark, with a warrior's real dice.
//   UX_SHOTS=docs/ux-shots flutter test test/ux_inventory_dice_mock_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/combat/dice_faces.dart' show dieDisplayName;
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader.addFont(Future.value(
          ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

const _phoneW = 400.0;
const _bg = Color(0xFF0B0A0D);
const _cream = Color(0xFFEDE3C8);
const _ash = Color(0xFF9A93A6);

TextStyle _px(double size, {Color color = _cream, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);
TextStyle _serif(double size,
        {Color color = _cream,
        FontStyle style = FontStyle.normal,
        FontWeight? w}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        color: color,
        fontStyle: style,
        fontWeight: w,
        height: 1.35);

const _phoneH2 = 760.0;

/// A warrior's dice: the one in hand, four in the bag, one made for a mage.
const _owned = [
  'starter_die',
  'iron_die',
  'bulwark_die',
  'pilgrim_die',
  'tempest_die',
  'arcane_die',
];

late Map<String, dynamic> _dice;

Widget _frame(Widget child, {String? caption, double h = _phoneH2}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _phoneW,
        height: h,
        decoration: BoxDecoration(
            color: const Color(0xFF17151B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A3642), width: 2)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
      if (caption != null) ...[
        const SizedBox(height: 8),
        SizedBox(
            width: _phoneW,
            child: Text(caption, style: _serif(12.5, color: _ash))),
      ],
    ]);

/// A die as a tile in its own skin: the stone, the mark cut in it, its edge
/// and its glow; [size] sides, the shape's name on it.
Widget _dieTile(String id, {double size = 46, bool lit = false}) {
  final skin = dieSkinOf(id);
  final faces = (_dice[id]['numberOfFaces'] as num).toInt();
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: skin.base,
      borderRadius: BorderRadius.circular(size * 0.22),
      border: Border.all(color: skin.edge, width: lit ? 2.2 : 1.4),
      boxShadow: [
        if (skin.glow != null || lit)
          BoxShadow(
              color: (skin.glow ?? const Color(0xFFE9B949))
                  .withValues(alpha: lit ? 0.55 : 0.35),
              blurRadius: lit ? 12 : 8),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(alignment: Alignment.center, children: [
      Positioned.fill(
          child:
              CustomPaint(painter: DiePatternPainter(skin.pattern, skin.edge))),
      Text('d$faces',
          style: _px(size * 0.34,
              color: skin.base.computeLuminance() > 0.45
                  ? const Color(0xFF1B1710)
                  : skin.edge,
              w: FontWeight.w600)),
    ]),
  );
}

Widget _appBar(BuildContext context) => Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF3A3642)))),
      child: Row(children: [
        Expanded(
            child: Text('Inventory & Equipment',
                style: Theme.of(context).textTheme.titleLarge)),
        const Icon(Icons.info_outline, size: 22),
        const SizedBox(width: 16),
        const Icon(Icons.compare_arrows, size: 22),
      ]),
    );

Widget _slotTile(String slot,
        {Widget? icon, String? name, bool lit = false, String? sub}) =>
    Expanded(
      child: Container(
        height: 62,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: lit ? const Color(0x22E9B949) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: lit ? const Color(0xFFE9B949) : const Color(0xFF3A3642),
              width: lit ? 1.6 : 1),
        ),
        child: Row(children: [
          SizedBox(width: 38, child: Center(child: icon)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.toUpperCase(), style: _px(10, color: _ash)),
                  Text(name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _serif(13.5, w: FontWeight.w600)),
                  if (sub != null) Text(sub, style: _serif(10.5, color: _ash)),
                ]),
          ),
        ]),
      ),
    );

Widget _slots(BuildContext context) {
  Widget gear(String slot, String id, String name) =>
      _slotTile(slot, icon: ItemPixelIcon(id, 'Armor', size: 26), name: name);
  return Padding(
    padding: const EdgeInsets.fromLTRB(13, 10, 13, 6),
    child: Column(children: [
      Row(children: [
        _slotTile('Dice',
            icon: _dieTile('starter_die', size: 34, lit: true),
            name: 'Lucky Die',
            sub: 'd6 · Bone',
            lit: true),
        gear('Head', 'helm_iron_cap', 'Iron Cap'),
      ]),
      Row(children: [
        gear('Top', 'armor_leather', 'Boiled Leather'),
        gear('Weapon', 'sword_t3', 'Steel Broadsword'),
      ]),
      Row(children: [
        gear('Bottom', 'plate_emberproof', 'Emberproof Plate'),
        gear('Foot', 'boots_worn_leather', 'Worn Leather Boots'),
      ]),
    ]),
  );
}

Widget _tabs() {
  Widget tab(String label, int n, {bool on = false, bool dot = false}) =>
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE9B949) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: on ? const Color(0xFFE9B949) : const Color(0xFF5A5468)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: _px(13,
                    color: on ? const Color(0xFF17151B) : _cream,
                    w: on ? FontWeight.w600 : null)),
            const SizedBox(width: 5),
            Text('$n',
                style: _px(12, color: on ? const Color(0xFF5A3B00) : _ash)),
            if (dot) ...[
              const SizedBox(width: 5),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFE9B949), shape: BoxShape.circle)),
            ],
          ]),
        ),
      );
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      tab('All', 17),
      tab('Gear', 5),
      tab('Dice', 6, on: true),
      tab('Charms', 1),
      tab('Materials', 3),
      tab('Books', 2),
    ]),
  );
}

Widget _dieRow(String id,
    {bool inHand = false, bool locked = false, String? madeFor}) {
  final skin = dieSkinOf(id);
  final faces = (_dice[id]['numberOfFaces'] as num).toInt();
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 7),
    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
    decoration: BoxDecoration(
      color: inHand ? const Color(0x22E9B949) : const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: inHand ? const Color(0xFFE9B949) : const Color(0xFF3A3642),
          width: inHand ? 1.6 : 1),
    ),
    child: Opacity(
      opacity: locked ? 0.55 : 1,
      child: Row(children: [
        SizedBox(
            width: 52,
            child: Center(child: _dieTile(id, size: 44, lit: inHand))),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dieDisplayName(id), style: _serif(16, w: FontWeight.w600)),
            Text('d$faces · $faces faces · ${skin.material}',
                style: _serif(12, color: _ash)),
            if (inHand)
              Text('In your hand',
                  style: _serif(11.5,
                      color: const Color(0xFFE9B949), style: FontStyle.italic))
            else if (locked)
              Text('Made for the $madeFor',
                  style: _serif(11.5, color: _ash, style: FontStyle.italic)),
          ]),
        ),
        if (inHand)
          const Icon(Icons.chevron_right, color: _ash)
        else if (locked)
          const Icon(Icons.lock_outline, color: _ash)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: const Color(0xFFB88CFF),
                borderRadius: BorderRadius.circular(6)),
            child:
                Text('Equip', style: _px(13, color: const Color(0xFF1B1030))),
          ),
      ]),
    ),
  );
}

Widget _diceTab(BuildContext context) => Column(children: [
      _appBar(context),
      _slots(context),
      _tabs(),
      Expanded(
        child: ListView(padding: const EdgeInsets.only(top: 10), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text('IN YOUR HAND', style: _px(11, color: _ash)),
          ),
          _dieRow('starter_die', inHand: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text('IN THE BAG', style: _px(11, color: _ash)),
          ),
          _dieRow('iron_die'),
          _dieRow('bulwark_die'),
          _dieRow('pilgrim_die'),
          _dieRow('tempest_die'),
          _dieRow('arcane_die', locked: true, madeFor: 'Mage'),
        ]),
      ),
    ]);

Widget _notes() => Container(
      width: _phoneW,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1D1B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3642))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dice on the Inventory page', style: _px(15, w: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            'Today the Dice slot is one tile that shows the die’s raw id and opens a list that is all text (the left pictures); the real dice screen, with the ring of face slots, is somewhere else (the Character tab). The dice you own are two taps from anywhere you manage gear, and not on the Inventory at all.',
            style: _serif(13)),
        const SizedBox(height: 12),
        Text('The proposal', style: _px(15, w: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            '• The Dice slot tile says the die’s name and drawn look ("Lucky Die", d6 · Bone), lit like the die in hand, and a tap on it goes to the Dice tab.\n• A Dice tab among the tabs, with the count of dice you own, shown only when you own more than the one you hold.\n• In your hand: the die lit in gold, its look, its name, "d6 · 6 faces · Bone", a chevron.\n• In the bag: the other dice, each with the same line and one labelled Equip. A die made for another class keeps its row, greyed, with a padlock and who it is for (the rule the sheet has today).',
            style: _serif(13)),
        const SizedBox(height: 12),
        Text('Swapping and the faces', style: _px(15, w: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            '• Equip swaps the die in hand at once: the old one goes to the bag, the row lights.\n• A tap on a die (the one in hand or one in the bag) opens the dice screen on that die: the ring of face slots, one slot for each face, the skill on it and Change (the right picture, Core’s v1.573 screen as it is). That screen already has the die picker; the tab is the way in, and "Equip this die" sits there too.\n• The look is the die’s own skin (stone, mark, edge, glow) from the data; the polyhedron shapes of the dice-family picture come with the dice art.',
            style: _serif(13)),
        const SizedBox(height: 12),
        Text('What it needs', style: _px(15, w: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            'Nothing from Core for the tab. The dice screen takes an optional die to open on (`initialDieId`: its `_selectedDiceId` exists), a two-line change in Core’s screen; the name fix (`dieDisplayName`) is one line. UX builds the tab with the inventory build (v1.594); about half a day more.',
            style: _serif(13)),
      ]),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the inventory dice mock is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('dice on the inventory page', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    _dice = jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
        as Map<String, dynamic>;
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark));
    tester.view.physicalSize = const Size(_phoneW, _phoneH2);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          navigatorKey: nav,
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const InventoryScreen(),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 6,
          'strength': 4,
          'dexterity': 3,
          'constitution': 4,
          'intelligence': 2,
          'inventoryItemIds': const [
            'sword_t3',
            'armor_leather',
            'helm_iron_cap',
            'boots_worn_leather',
            'plate_emberproof'
          ],
          'equippedItemIds': const [
            'sword_t3',
            'armor_leather',
            'helm_iron_cap',
            'boots_worn_leather',
            'plate_emberproof'
          ],
          'ownedDiceIds': _owned,
          'equippedDiceId': 'starter_die',
        })));
    await _settle(tester, n: 6);

    Future<ui.Image> grab() async {
      late ui.Image image;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await b.toImage(pixelRatio: 1.5);
      });
      return image;
    }

    final todayTop = await grab();
    await tester.tap(find.text('starter_die').first);
    await _settle(tester, n: 3);
    final todaySheet = await grab();
    nav.currentState!.pop();
    await _settle(tester, n: 2);
    nav.currentState!
        .push(MaterialPageRoute(builder: (_) => const DiceLoadoutScreen()));
    await _settle(tester, n: 6);
    final ring = await grab();

    Widget shot(ui.Image im) => SizedBox(
        width: _phoneW,
        height: _phoneH2,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: RawImage(
                image: im,
                width: _phoneW,
                height: _phoneH2,
                fit: BoxFit.fill)));

    const boardW = 5 * (_phoneW + 20) + 20;
    final board = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 1000);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: _bg,
        body: RepaintBoundary(
          key: board,
          child: Container(
            width: boardW,
            height: 1000,
            color: _bg,
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The dice on the main Inventory page',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'The user asked for the dice to be accessible from the Inventory. Left: the real screens today. Middle: a Dice tab. Right: the real ring of face slots a tap on a die would open. Nothing is built.',
                  style: _serif(12.5, color: _ash)),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  shot(todayTop),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: _phoneW,
                      child: Text(
                          '1. Today: the Dice slot shows the raw id "starter_die".',
                          style: _serif(12.5, color: _ash))),
                ]),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  shot(todaySheet),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: _phoneW,
                      child: Text(
                          '2. Today: a tap on it opens a list that is all text (the faces in a sentence, no look).',
                          style: _serif(12.5, color: _ash))),
                ]),
                const SizedBox(width: 20),
                Builder(
                    builder: (context) => _frame(_diceTab(context),
                        caption:
                            '3. Proposed: a Dice tab. The die in hand lit, the others one Equip away, a padlock for another class’s.')),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  shot(ring),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: _phoneW,
                      child: Text(
                          '4. A tap on a die opens this, the real dice screen (Core’s ring of face slots). Today it opens on the first die of the list (here a mage’s); the proposal opens it on the die tapped.',
                          style: _serif(12.5, color: _ash))),
                ]),
                const SizedBox(width: 20),
                _notes(),
              ]),
            ]),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 4);
    await tester.runAsync(() async {
      final b =
          board.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/inventory-dice-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
