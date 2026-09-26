// The recorded ElevenLabs narration: paragraphs split and named the same
// way every time, the whole-story script covering every paragraph the
// story screen can read aloud, and recordings made once and then kept.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/narration_clips.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/elevenlabs_tts_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/voice_settings_provider.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show composeNarration;

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative under ${Directory.current.path}');
}

PlayerSession _session({
  String raceId = 'human',
  String professionId = 'warrior',
  List<String> flags = const [],
  List<String> activeAllyIds = const [],
}) {
  return PlayerSession(
    level: 1,
    currentXP: 0,
    gold: 0,
    alignmentScore: 0,
    maxHealth: 100,
    currentHealth: 100,
    baseDamage: 10,
    baseArmor: 0,
    luck: 0,
    charisma: 0,
    strength: 0,
    dexterity: 0,
    constitution: 0,
    intelligence: 0,
    wisdom: 0,
    perception: 0,
    potionCount: 0,
    statPoints: 0,
    skillPoints: 0,
    maxSkillSlots: 3,
    flags: flags,
    activeQuestIds: const [],
    completedQuestIds: const [],
    inventoryItemIds: const [],
    equippedItemIds: const [],
    unlockedSkillIds: const [],
    unlockedShopIds: const [],
    unlockedQuestIds: const [],
    unlockedEnemyIds: const [],
    diceSkillAssignments: const {},
    raceId: raceId,
    professionId: professionId,
    ownedDiceIds: const [],
    equippedDiceId: null,
    knownSpellIds: const [],
  ).copyWith(characterName: 'Aldo', activeAllyIds: activeAllyIds);
}

const _voice = ElevenLabsVoiceSettings(
    enabled: true, voiceId: defaultElevenLabsVoiceId, apiKey: 'test-key');

void main() {
  group('narration clips', () {
    test('paragraphs split on blank lines, trimmed, empties dropped', () {
      expect(narrationParagraphs('  One.\n\nTwo.\n  \n\n Three. '),
          ['One.', 'Two.', 'Three.']);
      expect(narrationParagraphs('Line one\nline two'), ['Line one\nline two']);
      expect(narrationParagraphs('   '), isEmpty);
    });

    test('the header is not read aloud', () {
      expect(storyHeaderFor('[CHAPTER 3] The spire.'), 'CHAPTER 3');
      expect(storyBodyFor('[CHAPTER 3] The spire.'), 'The spire.');
    });

    test('a clip id is stable and changes with text, voice and model', () {
      String id(String text, {String voice = 'v', String model = 'm'}) =>
          narrationClipId(text: text, voiceId: voice, modelId: model);
      expect(id('Hello'), id('Hello'));
      expect(id('Hello'), hasLength(16));
      expect(id('Hello'), matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(id('Hello'), isNot(id('Hello.')));
      expect(id('Hello'), isNot(id('Hello', voice: 'w')));
      expect(id('Hello'), isNot(id('Hello', model: 'n')));
      expect(id('Déchirure'), isNot(id('Dechirure')));
    });
  });

  group('whole-story script', () {
    final nodes = [
      for (final entry
          in _loadJson('assets/Cleaned_Narrative_DAG.json').entries)
        StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
    ];

    for (final french in [false, true]) {
      final language = french ? 'French' : 'English';

      test('covers every paragraph the story screen reads ($language)', () {
        // Parties and flags that bring out companion asides, callbacks,
        // persona sentences and hub lines.
        final allFlags = {
          for (final node in nodes) ...[
            for (final callback in node.flagCallbacks) ...[
              callback.flag,
              ...callback.andFlags,
            ],
          ],
        }.toList();
        final sessions = [
          _session(),
          _session(
              raceId: 'voidkin',
              professionId: 'mage',
              activeAllyIds: ['vess'],
              flags: allFlags),
          _session(
              raceId: 'dwarf',
              professionId: 'cleric',
              activeAllyIds: ['kelda', 'sable']),
          _session(raceId: 'orc', professionId: 'rogue', activeAllyIds: [
            'grosh',
          ]),
        ];
        for (final session in sessions) {
          final script = narrationScript(
            nodes,
            french: french,
            personalize: (text) =>
                personalizeFor(session, text, french: french),
          ).toSet();
          for (final node in nodes) {
            final spoken = readAloudParagraphs(node, session, french: french);
            // The same words the screen shows, only cut into clips.
            String words(String text) =>
                text.replaceAll(RegExp(r'\s+'), ' ').trim();
            expect(
                words(spoken.join(' ')),
                words(storyBodyFor(
                    composeNarration(node, session, french: french))),
                reason: 'node ${node.id}');
            for (final paragraph in spoken) {
              expect(script, contains(paragraph),
                  reason: 'node ${node.id}, ${session.raceId} '
                      '${session.professionId} ${session.activeAllyIds}');
            }
          }
        }
      });
    }

    test('lists each paragraph once, in story order', () {
      final session = _session();
      final script = narrationScript(nodes,
          french: false,
          personalize: (text) => personalizeFor(session, text, french: false));
      expect(script.toSet(), hasLength(script.length));
      expect(script.first,
          narrationParagraphs(storyBodyFor(nodes.first.description)).first);
      expect(script.every((p) => p.trim() == p && p.isNotEmpty), isTrue);
    });
  });

  group('recordings', () {
    late Directory root;
    late List<String> requested;
    late ElevenLabsTtsNotifier notifier;

    setUp(() {
      root = Directory.systemTemp.createTempSync('narration_test');
      requested = [];
      notifier = ElevenLabsTtsNotifier(
        recordings: NarrationRecordings(root: () async => root),
        synthesize: ({
          required String text,
          required String apiKey,
          required String voiceId,
        }) async {
          requested.add(text);
          return Uint8List.fromList(utf8.encode('mp3:$text'));
        },
      );
    });

    tearDown(() {
      notifier.dispose();
      root.deleteSync(recursive: true);
    });

    test('each paragraph is recorded once and kept on the device', () async {
      final paragraphs = ['First.', 'Second.', 'Third.'];
      expect(
          await notifier.isRecorded(paragraphs,
              settings: _voice, language: AppLanguage.en),
          isFalse);

      final progress = <int>[];
      final recorded = await notifier.recordAll(paragraphs,
          settings: _voice,
          language: AppLanguage.en,
          onProgress: (done, total) => progress.add(done));
      expect(recorded, 3);
      expect(requested, paragraphs);
      expect(progress, [1, 2, 3]);
      expect(
          await notifier.isRecorded(paragraphs,
              settings: _voice, language: AppLanguage.en),
          isTrue);
      expect(
          await notifier.recordings
              .count(voiceId: _voice.voiceId, language: AppLanguage.en),
          3);

      // Nothing is asked of ElevenLabs a second time.
      expect(
          await notifier.recordAll(paragraphs,
              settings: _voice, language: AppLanguage.en),
          0);
      expect(requested, hasLength(3));

      // The clip holds what ElevenLabs sent, with its words beside it.
      final file = await notifier.recordings.fileFor('Second.',
          voiceId: _voice.voiceId, language: AppLanguage.en);
      expect(utf8.decode(file.readAsBytesSync()), 'mp3:Second.');
      expect(File(file.path.replaceFirst('.mp3', '.txt')).readAsStringSync(),
          'Second.');
    });

    test('recordings are kept per language and per voice', () async {
      await notifier
          .recordAll(['Bonjour.'], settings: _voice, language: AppLanguage.fr);
      expect(
          await notifier.isRecorded(['Bonjour.'],
              settings: _voice, language: AppLanguage.en),
          isFalse);
      final other = _voice.copyWith(voiceId: 'another');
      expect(
          await notifier.isRecorded(['Bonjour.'],
              settings: other, language: AppLanguage.fr),
          isFalse);

      await notifier.recordings.deleteVoice(_voice.voiceId);
      expect(
          await notifier.recordings
              .count(voiceId: _voice.voiceId, language: AppLanguage.fr),
          0);
    });

    test('without a key, only recorded paragraphs can be voiced', () async {
      final noKey = _voice.copyWith(clearApiKey: true);
      await expectLater(
          notifier.clipFor('Unrecorded.',
              settings: noKey, language: AppLanguage.en),
          throwsA(isA<ElevenLabsException>()));
      expect(requested, isEmpty);

      await notifier
          .recordAll(['Recorded.'], settings: _voice, language: AppLanguage.en);
      final file = await notifier.clipFor('Recorded.',
          settings: noKey, language: AppLanguage.en);
      expect(file.existsSync(), isTrue);
    });

    test('a paragraph asked for twice at once is recorded once', () async {
      final clips = await Future.wait([
        notifier.clipFor('Twice.', settings: _voice, language: AppLanguage.en),
        notifier.clipFor('Twice.', settings: _voice, language: AppLanguage.en),
      ]);
      expect(requested, ['Twice.']);
      expect(clips[0].path, clips[1].path);
      expect(clips[0].existsSync(), isTrue);
    });

    test('recording the whole story stops when cancelled', () async {
      var calls = 0;
      final recorded = await notifier.recordAll(['A.', 'B.', 'C.'],
          settings: _voice,
          language: AppLanguage.en,
          cancelled: () => calls++ >= 1);
      expect(recorded, 1);
    });

    test('the characters left to record are counted', () async {
      await notifier
          .recordAll(['Done.'], settings: _voice, language: AppLanguage.en);
      final pending = await notifier.missingFrom(['Done.', 'Left over.'],
          settings: _voice, language: AppLanguage.en);
      expect(pending.missing, ['Left over.']);
      expect(pending.characters, 'Left over.'.length);
    });
  });

  test('ElevenLabs errors read as the reason it gives', () {
    expect(
        elevenLabsErrorMessage(
            '{"detail":{"status":"quota_exceeded","message":"Out of credits."}}',
            401),
        'Out of credits.');
    expect(elevenLabsErrorMessage('{"detail":"Voice not found"}', 404),
        'Voice not found');
    expect(elevenLabsErrorMessage('<html>', 401),
        'The ElevenLabs API key was refused.');
    expect(elevenLabsErrorMessage('', 500),
        'ElevenLabs request failed (HTTP 500).');
  });
}
