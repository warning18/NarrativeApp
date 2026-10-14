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

/// The story choice (`'<node>#<choice index>'`) whose crossing was just
/// lost or turned back from, after its check and fight went the party's
/// way: taken again, it sets out at once, with no check or fight played
/// twice. Held for the session only; leaving the app forgets it.
final crossingRetryProvider = StateProvider<String?>((ref) => null);

/// Plays the land route [routeId] (land_routes.json) on its own screen,
/// the way a voyage plays on the voyage screen: true once the party is on
/// the far side. False when the road beat it, or it turned back: it is
/// where it set out, and the story stays there. A route not on file is no
/// crossing at all (true: the walk goes on as before).
Future<bool> runLandCrossing(
    BuildContext context, WidgetRef ref, String routeId) async {
  final routes =
      await ref.read(gameDbRepositoryProvider(landRoutesSchema)).loadRecords();
  final events =
      await ref.read(gameDbRepositoryProvider(landEventsSchema)).loadRecords();
  final route = landRouteFor(routes, routeId);
  if (route == null) return true;
  if (!context.mounted) return false;
  final arrived = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) =>
        LandCrossingScreen(route: route, events: landEventsFrom(events)),
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                tr(ref, 'crossing_day')
                    .replaceAll('{n}', '${min(_day + 1, _drawn.length)}')
                    .replaceAll('{m}', '${_drawn.length}'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TutorialTarget(
                id: 'crossing.health',
                child: Row(children: [
                  const Icon(Icons.favorite, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                        key: const Key('crossing_health'), value: health),
                  ),
                  const SizedBox(width: 8),
                  Text('${session.currentHealth}/${session.maxHealth}'),
                ]),
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
