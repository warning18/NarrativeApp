import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/ability_check.dart';
import '../data/journey_rules.dart' show watchesPerDay;
import '../data/land_crossing.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart' show reachedChapterProvider;
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../data/climate.dart' show WeatherKind;
import '../providers/climate_provider.dart' show skyHereProvider;
import '../widgets/side_view/desert_kit.dart';
import '../widgets/side_view/ruins_kit.dart';
import '../widgets/side_view/side_view.dart';

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
  if (!context.mounted) return false;
  final arrived = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => LandCrossingScreen(
        route: route,
        events: landEventsFrom(events),
        random: ref.read(landCrossingRandomProvider)),
  ));
  return arrived == true;
}

/// A land crossing (land_crossing.dart): an event a day, each asking what
/// the party does; the party's health is what runs out. The layout is a
/// plain one for now; the side view is UX's (docs/proposals/
/// land-expeditions.md).
class LandCrossingScreen extends ConsumerStatefulWidget {
  const LandCrossingScreen({
    super.key,
    required this.route,
    required this.events,
    this.random,
  });

  final LandRoute route;
  final Map<String, LandEvent> events;

  /// Injectable for tests; a fresh stream otherwise.
  final Random? random;

  @override
  ConsumerState<LandCrossingScreen> createState() => _LandCrossingScreenState();
}

enum _Phase { event, result, arrived, failed, turnedBack }

class _LandCrossingScreenState extends ConsumerState<LandCrossingScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<String> _drawn =
      drawCrossing(widget.route, widget.events.keys, random: _random);
  var _day = 0;
  var _phase = _Phase.event;
  var _daysSpent = 0;
  String _note = '';
  String _checkLine = '';
  var _busy = false;

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
  }

  Future<void> _choose(LandChoice choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    final lang = ref.read(appLanguageProvider);
    final notifier = ref.read(playerSessionProvider.notifier);
    var outcome = choice.outcome;
    var checkLine = '';
    if (choice.hasCheck) {
      final result = rollAbilityCheck(
        ability: choice.check!,
        dc: landCheckDc(choice.dc, _chapter),
        session: ref.read(playerSessionProvider),
        random: _random,
      );
      outcome = result.success ? choice.success : choice.fail;
      checkLine = '${trFor(lang, '${result.ability}_label')} '
          '${trFor(lang, 'check_label')}: '
          '${result.roll} + ${result.modifier} = ${result.total} '
          '${trFor(lang, 'vs_dc_label')} ${result.dc} — '
          '${trFor(lang, result.success ? 'ability_check_success' : 'ability_check_fail')}';
    }
    final session = ref.read(playerSessionProvider);
    final step = afterLandStep(
        health: session.currentHealth,
        maxHealth: session.maxHealth,
        change: outcome.healthChange(session.maxHealth));
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
      _checkLine = checkLine;
      _phase = step.failed ? _Phase.failed : _Phase.result;
    });
  }

  void _next() {
    setState(() {
      _day++;
      _note = '';
      _checkLine = '';
      _phase = _day >= _drawn.length ? _Phase.arrived : _Phase.event;
    });
  }

  void _turnBack() => setState(() => _phase = _Phase.turnedBack);

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
                    if (choice.goldCost > 0)
                      '(${choice.goldCost} ${tr(ref, 'gold_label')})',
                  ].join(' ')),
                ),
              ),
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
            if (_checkLine.isNotEmpty)
              Text(_checkLine, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(_note, style: theme.textTheme.bodyLarge),
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
            if (_checkLine.isNotEmpty)
              Text(_checkLine, style: theme.textTheme.bodySmall),
            if (_note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_note, style: theme.textTheme.bodyLarge),
            ],
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
    // desert kit while it crosses a desert, the ruins kit among ruins; a
    // terrain with no kit yet keeps only the strip of day and health.
    final terrain = widget.route.terrain;
    final scene = terrain == 'desert' || terrain == 'ruins';
    final ruins = terrain == 'ruins';
    final progress = _phase == _Phase.arrived
        ? 1.0
        : _drawn.isEmpty
            ? 0.0
            : ((_day + (_phase == _Phase.result ? 1 : 0)) / _drawn.length)
                .clamp(0.0, 1.0);
    final storm = _phase == _Phase.event && event?.id == 'sandstorm';
    final sky = ref.watch(skyHereProvider)?.today().kind;
    final particles = storm
        ? SideParticles.dust
        : switch (sky) {
            WeatherKind.dust => SideParticles.dust,
            WeatherKind.rain => SideParticles.rain,
            WeatherKind.snow => SideParticles.snow,
            WeatherKind.ash => SideParticles.ash,
            WeatherKind.fog => SideParticles.fog,
            _ => ruins ? SideParticles.ash : SideParticles.shimmer,
          };
    final hud = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                tr(ref, 'crossing_day')
                    .replaceAll('{n}', '${min(_day + 1, _drawn.length)}')
                    .replaceAll('{m}', '${_drawn.length}'),
                style:
                    theme.textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
          TutorialTarget(
            id: 'crossing.health',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 96,
                    child: LinearProgressIndicator(
                        key: const Key('crossing_health'), value: health),
                  ),
                  const SizedBox(width: 6),
                  Text('${session.currentHealth}/${session.maxHealth}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white)),
                ]),
              ),
            ),
          ),
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
          ),
          body: Column(
            children: [
              if (scene)
                Stack(
                  children: [
                    SideViewScene(
                      key: const Key('crossing_scene'),
                      layers: ruins
                          ? ruinsLayers(progress: progress)
                          : desertLayers(progress: progress),
                      actors: desertActors(),
                      particles: particles,
                      intensity: storm ? 1 : 0.6,
                      moving: _phase == _Phase.result,
                    ),
                    Positioned(left: 0, right: 0, top: 0, child: hud),
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
