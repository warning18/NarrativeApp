import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/ability_check.dart';
import '../data/fate_coin.dart';
import '../data/journey_rules.dart' show watchesPerDay;
import '../data/land_crossing.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/aftermath_provider.dart'
    show lastFightOutcomeProvider, lastFightRetreatedProvider;
import '../providers/chapter_loop_provider.dart' show reachedChapterProvider;
import '../providers/clans_provider.dart'
    show factionsProvider, loadClanData, politicsProvider;
import '../providers/day_phase_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart' show loadGeography;
import '../providers/player_session_provider.dart';
import '../providers/walking_party_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../data/climate.dart' show WeatherKind;
import '../providers/climate_provider.dart' show skyHereProvider;
import '../widgets/companion_remark_bubble.dart' show SpokenLine, spokenRemarks;
import '../widgets/fight_sprites.dart';
import '../widgets/side_view/desert_kit.dart';
import '../widgets/side_view/encounter_figure.dart';
import '../widgets/side_view/cliffs_kit.dart';
import '../widgets/side_view/fen_kit.dart';
import '../widgets/side_view/frost_kit.dart';
import '../widgets/side_view/kit_hour.dart';
import '../widgets/side_view/ruins_kit.dart';
import '../widgets/d20_roll.dart';
import '../widgets/side_view/scene_versions.dart';
import '../widgets/side_view/side_view.dart';
import '../widgets/pixel_banner.dart' show ClanFlag;
import '../widgets/walk_bubble.dart';
import 'fight_screen.dart';

/// The story choice (`'<node>#<choice index>'`) whose crossing was just
/// lost or turned back from, after its check and fight went the party's
/// way: taken again, it sets out at once, with no check or fight played
/// twice. Held for the session only; leaving the app forgets it.
final crossingRetryProvider = StateProvider<String?>((ref) => null);

/// The random stream a crossing draws and rolls with: a fresh one each
/// time in play; a test overrides it with a seeded one so a crossing
/// played through the app goes the same way every run.
final landCrossingRandomProvider = Provider<Random?>((ref) => null);

/// Plays the land route [routeId] (land_routes.json) on its own screen,
/// the way a voyage plays on the voyage screen: true once the party is on
/// the far side. False when the road beat it, or it turned back: it is
/// where it set out, and the story stays there. A route not on file is no
/// crossing at all (true: the walk goes on as before).
Future<bool> runLandCrossing(
    BuildContext context, WidgetRef ref, String routeId) async {
  final routes = await loadedGameDb(ref, landRoutesSchema);
  final events = await loadedGameDb(ref, landEventsSchema);
  final route = landRouteFor(routes, routeId);
  if (route == null) return true;
  final known = landEventsFrom(events);
  final ruler = await crossingRulerOf(ref, route);
  if (!context.mounted) return false;
  final arrived = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => LandCrossingScreen(
        route: ruler.route,
        events: known,
        ruler: ruler.clanId,
        rulers: rulerPool(known, ruler.clanId, ruler.band),
        random: ref.read(landCrossingRandomProvider)),
  ));
  return arrived == true;
}

/// Who holds the land [route] crosses now (landRouteRuler: '' for no one),
/// the band the party's standing with them puts it in, and the route as
/// crossed (a clan's own road meets it more often: crossingRuler).
Future<({LandRoute route, String clanId, RulerBand band, bool clanRoad})>
    crossingRulerOf(WidgetRef ref, LandRoute route) async {
  final geography = await loadGeography(ref);
  final clans = await loadClanData(ref);
  return crossingRuler(route, geography, ref.read(politicsProvider), clans);
}

/// A land crossing (land_crossing.dart): an event a day, each asking what
/// the party does; the party's health is what runs out. The layout is a
/// plain one for now; the side view is UX's (docs/proposals/
/// land-expeditions.md).
/// An event that is a storm over the scene: the sandstorm in the desert and
/// the ash squall among the ruins fill the scene with their dust or ash.
bool crossingIsStorm(String? eventId) =>
    eventId == 'sandstorm' || eventId == 'ash_squall';

/// The terrains a crossing draws a scene for (the route's `terrain`, which
/// is a biome id).
const crossingSceneTerrains = {
  'desert',
  'ruins',
  'frost',
  'fen',
  'sea_cliffs',
};

/// The layers of the scene for [terrain]; the goal comes forward with
/// [progress] 0 to 1.
///
/// [version] (0 to 3, sceneVersionAt) is the stretch of that land shown: its
/// own window of the world and its own landmark.
List<SideLayer> crossingLayers(String terrain, double progress,
    {int version = 0}) {
  final layers = switch (terrain) {
    'ruins' => ruinsLayers(progress: progress),
    'frost' => frostLayers(progress: progress),
    'fen' => fenLayers(progress: progress),
    'sea_cliffs' => cliffsLayers(progress: progress),
    _ => desertLayers(progress: progress),
  };
  final kit = switch (terrain) {
    'ruins' || 'frost' || 'fen' => terrain,
    'sea_cliffs' => 'cliffs',
    _ => 'desert',
  };
  return withSceneVersion(layers, kit, version);
}

/// The particles over a crossing's scene: a storm's own, else the sky's, else
/// the terrain's (heat shimmer in the desert, ash among the ruins).
SideParticles crossingParticles({
  required String terrain,
  required bool storm,
  WeatherKind? sky,
}) {
  if (storm) return terrain == 'ruins' ? SideParticles.ash : SideParticles.dust;
  return switch (sky) {
    WeatherKind.dust => SideParticles.dust,
    WeatherKind.rain => SideParticles.rain,
    WeatherKind.snow => SideParticles.snow,
    WeatherKind.ash => SideParticles.ash,
    WeatherKind.fog => SideParticles.fog,
    _ => switch (terrain) {
        'ruins' => SideParticles.ash,
        'frost' => SideParticles.snow,
        'fen' || 'sea_cliffs' => SideParticles.fog,
        _ => SideParticles.shimmer,
      },
  };
}

class LandCrossingScreen extends ConsumerStatefulWidget {
  const LandCrossingScreen({
    super.key,
    required this.route,
    required this.events,
    this.ruler = '',
    this.rulers = const [],
    this.random,
  });

  final LandRoute route;
  final Map<String, LandEvent> events;

  /// The clan that holds the land crossed (landRouteRuler), '' for no one:
  /// for the header's colour.
  final String ruler;

  /// The ruler's events the crossing may meet (rulerPool).
  final List<String> rulers;

  /// Injectable for tests; a fresh stream otherwise.
  final Random? random;

  @override
  ConsumerState<LandCrossingScreen> createState() => _LandCrossingScreenState();
}

/// The scene's height: the side view's own default.
const double _crossingSceneHeight = 190;

enum _Phase { event, result, arrived, failed, turnedBack }

class _LandCrossingScreenState extends ConsumerState<LandCrossingScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<String> _drawn = drawCrossing(
      widget.route, widget.events.keys,
      random: _random, rulers: widget.rulers);
  var _day = 0;

  /// The scene version on show, and the dissolve that brings the next one in
  /// (a short pixel dissolve when the day, and with it the version, changes).
  int? _shownVersion;
  SideLayer? _dissolve;
  DateTime _dissolveUntil = DateTime.fromMillisecondsSinceEpoch(0);

  List<SideLayer> _sceneLayers(
      int version, List<SideLayer> Function(int version) layersFor,
      {required bool reduceMotion}) {
    final shown = _shownVersion;
    if (shown != null && shown != version && !reduceMotion) {
      _dissolve = sceneDissolve(layersFor(shown), layersFor(version));
      _dissolveUntil = DateTime.now().add(const Duration(milliseconds: 1100));
    }
    _shownVersion = version;
    final dissolve = _dissolve;
    if (dissolve != null && DateTime.now().isBefore(_dissolveUntil)) {
      return [dissolve];
    }
    return layersFor(version);
  }

  var _phase = _Phase.event;
  var _daysSpent = 0;
  String _note = '';
  String _checkLine = '';
  var _busy = false;

  /// The check being rolled under the choices (Wave 6: the Skill
  /// Challenge's die, d20_roll.dart, in place of a line of text), kept at
  /// rest beside its outcome; null for a choice with no check.
  AbilityCheckResult? _roll;
  bool _landed = false;
  Completer<void>? _landing;

  /// How long the sum stays under the landed die before the outcome.
  static const Duration _rollLinger = Duration(milliseconds: 700);

  void _onLanded() {
    if (!mounted || _landed) return;
    setState(() => _landed = true);
    Future.delayed(_rollLinger, () {
      final landing = _landing;
      if (landing != null && !landing.isCompleted) landing.complete();
    });
  }

  /// The party's health as it set out: a lost crossing carries it back no
  /// better off (see turnBackHealth).
  int? _departureHealth;

  int get _chapter => ref.read(reachedChapterProvider);

  LandEvent? get _event =>
      _day < _drawn.length ? widget.events[_drawn[_day]] : null;

  @override
  void initState() {
    super.initState();
    _departureHealth = ref.read(playerSessionProvider).currentHealth;
    if (_drawn.isEmpty) _phase = _Phase.arrived;
    // A walking companion may say a word as the walk starts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakUp());
  }

  /// A companion's word on the road (Core's speakUpOnWalk), as a bubble over
  /// their figure for a few seconds.
  SpokenLine? _spoken;
  Timer? _spokenTimer;

  void _speakUp() {
    if (!mounted || _phase == _Phase.arrived) return;
    final remark = speakUpOnWalk(ref);
    if (remark == null) return;
    final line = spokenRemarks(ref, [remark]).firstOrNull;
    if (line == null) return;
    setState(() => _spoken = line);
    _spokenTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _spoken = null);
    });
  }

  @override
  void dispose() {
    _spokenTimer?.cancel();
    super.dispose();
  }

  /// What stands on the road at the day's event, walking in from the left
  /// (encounter_figure.dart); one walk per day, kept across rebuilds.
  EncounterWalk? _walk;
  int _walkDay = -1;

  EncounterWalk? _encounterWalk(LandEvent? event) {
    if (event == null || _phase != _Phase.event) return null;
    if (_walkDay == _day) return _walk;
    _walkDay = _day;
    final fight = event.choices.where((c) => c.isFight).firstOrNull;
    final figure =
        roadEncounterFigure(event.id, fightEnemyId: fight?.fightEnemyId);
    return _walk = figure == null
        ? null
        : EncounterWalk(
            sprite: figure.sprite,
            animate: !MediaQuery.of(context).disableAnimations);
  }

  Future<void> _choose(LandChoice choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (choice.isFight) return _fight(choice);
    final lang = ref.read(appLanguageProvider);
    var outcome = choice.outcome;
    var checkLine = '';
    if (choice.hasCheck) {
      var result = rollAbilityCheck(
        ability: choice.check!,
        dc: landCheckDc(choice.dc, _chapter),
        session: ref.read(playerSessionProvider),
        random: _random,
      );
      checkLine = await _showRoll(result, lang);
      if (!mounted) return;
      // A failed check, and a fate coin in the pack: the player may flip it
      // to roll the check once more (fate_coin.dart).
      if (fateCoinWorthFlipping(result) &&
          carriesFateCoin(ref.read(playerSessionProvider).inventoryItemIds)) {
        final offer = Completer<bool>();
        setState(() => _coinOffer = offer);
        final flip = await offer.future;
        if (!mounted) return;
        setState(() => _coinOffer = null);
        if (flip &&
            await ref.read(playerSessionProvider.notifier).spendFateCoin()) {
          final face = flipFateCoin(_random);
          result = rerolledCheck(result, _random);
          checkLine =
              '${trFor(lang, 'fate_coin_landed').replaceAll('{face}', trFor(lang, 'fate_coin_${face.name}'))} '
              '${await _showRoll(result, lang)}';
          if (!mounted) return;
        }
      }
      outcome = result.success ? choice.success : choice.fail;
    }
    await _settle(outcome, checkLine);
  }

  /// A fate coin offered on the failed check: completes with whether the
  /// player flips it.
  Completer<bool>? _coinOffer;

  /// The checks rolled so far: a second roll (the fate coin's) tumbles anew.
  var _rolls = 0;

  /// Rolls [result]'s die under the choices and waits for it to land and
  /// its sum to be read; returns the check's line.
  Future<String> _showRoll(AbilityCheckResult result, AppLanguage lang) async {
    final checkLine = '${trFor(lang, '${result.ability}_label')} '
        '${trFor(lang, 'check_label')}: '
        '${result.roll} + ${result.modifier} = ${result.total} '
        '${trFor(lang, 'vs_dc_label')} ${result.dc} — '
        '${trFor(lang, result.success ? 'ability_check_success' : 'ability_check_fail')}';
    // The die rolls under the choices; the outcome follows once it has
    // landed and the sum has been read.
    final landing = Completer<void>();
    setState(() {
      _roll = result;
      _rolls++;
      _landed = false;
      _landing = landing;
      _checkLine = checkLine;
    });
    // A die that never tumbles (motion reduced) lands all the same.
    Future.delayed(d20RollDuration + _rollLinger * 2, _onLanded);
    await landing.future;
    return checkLine;
  }

  /// A fight on the road (the scavengers, v1.305.0): played on the battle
  /// screen, with the party's own health, rewards and loot. Won, the
  /// choice's success follows; broken off, its fail; lost, the crossing
  /// is lost and the party carried back (see turnBackHealth).
  Future<void> _fight(LandChoice choice) async {
    final lang = ref.read(appLanguageProvider);
    final enemies = await loadedGameDb(ref, enemiesSchema);
    final enemy = enemies[choice.fightEnemyId] as Map<String, dynamic>?;
    if (!mounted) return;
    if (enemy == null) return _settle(choice.fail, '');
    ref.read(combatActiveProvider.notifier).state = true;
    final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) =>
            FightScreen(enemyId: choice.fightEnemyId!, enemy: enemy)));
    ref.read(combatActiveProvider.notifier).state = false;
    final retreated = ref.read(lastFightRetreatedProvider);
    ref.read(lastFightRetreatedProvider.notifier).state = false;
    // The road tells the fight itself: no aftermath for the next scene.
    ref.read(lastFightOutcomeProvider.notifier).state = null;
    if (!mounted) return;
    if (won == true) {
      return _settle(choice.success, trFor(lang, 'crossing_fight_won'));
    }
    if (retreated) {
      return _settle(choice.fail, trFor(lang, 'crossing_fight_fled'));
    }
    // A permadeath loss: the run is over, there is no road to go on.
    if (won == null) return Navigator.of(context).pop(false);
    await _settle(const LandOutcome(), trFor(lang, 'crossing_fight_lost'),
        lost: true);
  }

  /// [outcome] on the party, told by [line] (the check or the fight) and
  /// the outcome's note, and a day gone; [lost] (a fight lost) or health
  /// run out loses the crossing.
  Future<void> _settle(LandOutcome outcome, String line,
      {bool lost = false}) async {
    final lang = ref.read(appLanguageProvider);
    final notifier = ref.read(playerSessionProvider.notifier);
    final session = ref.read(playerSessionProvider);
    final change = afterLandStep(
        health: session.currentHealth,
        maxHealth: session.maxHealth,
        change: outcome.healthChange(session.maxHealth));
    final step = lost ? (health: 0, failed: true) : change;
    final target = step.failed
        ? turnBackHealth(session.maxHealth,
            departureHealth: _departureHealth ?? session.currentHealth)
        : step.health;
    await notifier.applyChoiceEffects(
      goldMod: outcome.gold,
      healAmount: target - session.currentHealth,
      // What the road takes or turns up is no deed to approve of.
      goldIsProfit: false,
    );
    final days = 1 + outcome.days;
    _daysSpent += days;
    await notifier.passTime(watchesPerDay * days, chapter: _chapter);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = outcome.noteFor(lang == AppLanguage.fr);
      _checkLine = line;
      _phase = step.failed ? _Phase.failed : _Phase.result;
    });
  }

  void _next() {
    setState(() {
      _day++;
      _note = '';
      _checkLine = '';
      _roll = null;
      _landing = null;
      _phase = _day >= _drawn.length ? _Phase.arrived : _Phase.event;
    });
  }

  void _turnBack() => setState(() => _phase = _Phase.turnedBack);

  /// The check's die: tumbling under the choices ([rolling]), its sum
  /// coming up once it lands; or set down small beside the outcome.
  Widget _rollView(ThemeData theme, {required bool rolling}) {
    final roll = _roll!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          KeyedSubtree(
            key: ValueKey('crossing_roll_$_rolls'),
            child: D20Roll(
              key: const Key('crossing_roll'),
              roll: roll.roll,
              success: roll.success,
              size: rolling ? 120 : 64,
              rolling: rolling,
              onLanded: rolling ? _onLanded : null,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: rolling && !_landed ? 0 : 1,
            child: Text(
              _checkLine,
              key: const Key('crossing_roll_line'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// The bubble over the companion who spoke: above their head, kept in view.
  Widget _walkBubble(SpokenLine line) {
    final party = ref.read(walkingPartyProvider);
    final index = party.indexWhere((m) => m.id == line.companionId);
    final xs = walkingPartyXs(party.length);
    const unit = _crossingSceneHeight / sideViewRows;
    final width = MediaQuery.sizeOf(context).width;
    final bubbleWidth = min(300.0, width - 16);
    final at = (index < 0 ? xs.first : xs[index]) * unit;
    final left = (at - 24).clamp(8.0, width - bubbleWidth - 8).toDouble();
    // Anchored just above the figure's head, under the HUD's row, scaled down
    // a little when the words need more room than is left.
    return Positioned(
      left: left,
      top: 34,
      width: bubbleWidth,
      bottom: _crossingSceneHeight - 40 * unit,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomLeft,
        child: WalkBubble(
          key: const Key('walk_bubble'),
          speaker: line.speaker,
          line: line.line,
          width: bubbleWidth,
          tailX: (at - left - 7).clamp(8.0, bubbleWidth - 22).toDouble(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final event = _event;
    final done = _phase == _Phase.arrived ||
        _phase == _Phase.failed ||
        _phase == _Phase.turnedBack;
    final health = session.maxHealth <= 0
        ? 0.0
        : (session.currentHealth / session.maxHealth).clamp(0.0, 1.0);

    Widget body;
    switch (_phase) {
      case _Phase.event:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(event!.nameFor(fr), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(event.textFor(fr), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            for (final choice in event.choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  key: Key('crossing_choice_${choice.id}'),
                  onPressed: _busy || choice.goldCost > session.gold
                      ? null
                      : () => _choose(choice),
                  child: Text([
                    choice.textFor(fr),
                    if (choice.hasCheck)
                      '(${tr(ref, '${choice.check}_label')} '
                          '${landCheckDc(choice.dc, _chapter)})',
                    if (choice.isFight) tr(ref, 'crossing_fight_tag'),
                    if (choice.goldCost > 0)
                      '(${choice.goldCost} ${tr(ref, 'gold_label')})',
                  ].join(' ')),
                ),
              ),
            if (_roll != null) _rollView(theme, rolling: true),
            if (_coinOffer case final offer?) ...[
              const SizedBox(height: 8),
              Text(tr(ref, 'fate_coin_offer'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              FilledButton(
                key: const Key('crossing_fate_coin'),
                onPressed: () => offer.complete(true),
                child: Text(tr(ref, 'fate_coin_flip_button')),
              ),
              TextButton(
                key: const Key('crossing_fate_coin_keep'),
                onPressed: () => offer.complete(false),
                child: Text(tr(ref, 'fate_coin_keep_button')),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              key: const Key('crossing_turn_back'),
              onPressed: _busy ? null : _turnBack,
              child: Text(tr(ref, 'crossing_turn_back')),
            ),
          ],
        );
      case _Phase.result:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_roll == null && _checkLine.isNotEmpty)
              Text(_checkLine, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(_note, style: theme.textTheme.bodyLarge),
            if (_roll != null) _rollView(theme, rolling: false),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('crossing_next'),
              onPressed: _next,
              child: Text(tr(ref, 'continue_button')),
            ),
          ],
        );
      case _Phase.arrived || _Phase.failed || _Phase.turnedBack:
        final message = switch (_phase) {
          _Phase.arrived => tr(ref, 'crossing_arrived'),
          _Phase.failed => tr(ref, 'crossing_failed'),
          _ => tr(ref, 'crossing_turned_back'),
        }
            .replaceAll('{n}', '$_daysSpent');
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_roll == null && _checkLine.isNotEmpty)
              Text(_checkLine, style: theme.textTheme.bodySmall),
            if (_note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_note, style: theme.textTheme.bodyLarge),
            ],
            if (_roll != null) _rollView(theme, rolling: false),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('crossing_done'),
              onPressed: () =>
                  Navigator.of(context).pop(_phase == _Phase.arrived),
              child: Text(tr(ref, 'continue_button')),
            ),
          ],
        );
    }

    // The scene over the words (board 6), by the route's terrain: the
    // desert, ruins, frost, fen or sea cliffs kit; a terrain with no kit
    // yet keeps only the strip of day and health.
    final terrain = widget.route.terrain;
    final scene = crossingSceneTerrains.contains(terrain);
    final progress = _phase == _Phase.arrived
        ? 1.0
        : _drawn.isEmpty
            ? 0.0
            : ((_day + (_phase == _Phase.result ? 1 : 0)) / _drawn.length)
                .clamp(0.0, 1.0);
    final phase = ref.watch(dayPhaseProvider);
    final storm = _phase == _Phase.event && crossingIsStorm(event?.id);
    final sky = ref.watch(skyHereProvider)?.today().kind;
    final particles =
        crossingParticles(terrain: terrain, storm: storm, sky: sky);
    // The road's ruler (Core's v1.512): its colour under the title, and its
    // name and flag on the screen, so the player sees why this road's events.
    final rulerClan =
        widget.ruler.isEmpty ? null : ref.watch(factionsProvider)[widget.ruler];
    final rulerColour =
        rulerClan == null ? null : Color(rulerClan.patron.color);
    final hud = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    tr(ref, 'crossing_day')
                        .replaceAll('{n}', '${min(_day + 1, _drawn.length)}')
                        .replaceAll('{m}', '${_drawn.length}'),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TutorialTarget(
                    id: 'crossing.health',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          // Shrinks with the screen and the text, so large text on
                          // a narrow phone keeps the numbers whole.
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 96),
                              child: LinearProgressIndicator(
                                  key: const Key('crossing_health'),
                                  value: health),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('${session.currentHealth}/${session.maxHealth}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (rulerClan != null && rulerColour != null) ...[
            const SizedBox(height: 6),
            DecoratedBox(
              key: const Key('crossing_ruler'),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: rulerColour, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ClanFlag(factionId: widget.ruler, height: 16),
                  const SizedBox(width: 6),
                  Text(
                    tr(ref, 'crossing_ruler').replaceAll('{clan}',
                        rulerClan.shortFor(ref.watch(appLanguageProvider))),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );

    return PopScope(
      // The crossing is played in one sitting: its end is the way out.
      canPop: done,
      child: TutorialTrigger(
        topic: TutorialTopic.landCrossing,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.route.nameFor(fr)),
            bottom: rulerColour == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(3),
                    child: ColoredBox(
                      key: const Key('crossing_ruler_band'),
                      color: rulerColour,
                      child: const SizedBox(height: 3, width: double.infinity),
                    ),
                  ),
          ),
          body: Column(
            children: [
              if (scene)
                Stack(
                  children: [
                    SideViewScene(
                      key: const Key('crossing_scene'),
                      height: _crossingSceneHeight,
                      layers: _sceneLayers(
                          sceneVersionAt(widget.route.id, _day),
                          (v) => withHourStars(
                              crossingLayers(terrain, progress, version: v),
                              phase),
                          reduceMotion:
                              MediaQuery.of(context).disableAnimations),
                      overlay: hourWash(phase),
                      actors: desertActors(
                          party: ref.watch(walkingPartyProvider),
                          moving: _phase == _Phase.result,
                          encounter: _encounterWalk(event)),
                      particles: particles,
                      intensity: storm ? 1 : 0.6,
                      moving: _phase == _Phase.result,
                    ),
                    Positioned(left: 0, right: 0, top: 0, child: hud),
                    if (_spoken != null) _walkBubble(_spoken!),
                  ],
                )
              else
                hud,
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [body],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
