import 'dart:math';

/// A rule word a die face carries on top of its number (v1.182), in the
/// manner of Slice & Dice: dice.json `keywords` on a face, a keyword
/// inscribed at the Hammersmith (see face_smithing.dart), or a Curse an
/// enemy lays on a face (see dice_tamper.dart).
///
/// - [cleave]: a strike also hits every other enemy standing, for
///   [cleaveSplashShare] of its damage.
/// - [pierce]: a strike goes through a raised guard and an Armored hide.
/// - [growth]: the face gains [growthStep] each time it's used this fight.
/// - [echo]: the face does what the party member before it does this
///   round (the first in line repeats what they did last round).
/// - [pain]: a strike hits for double, and costs its roller
///   [painHealthShare] of their max health (never the last point).
/// - [steady]: the face can't be rerolled once it lands, and is worth
///   [steadyBonus] more.
enum FaceKeyword { cleave, pierce, growth, echo, pain, steady }

/// What a Cleave strike (and a Volley, see party_combos.dart) deals every
/// other enemy standing, as a share of the blow.
const double cleaveSplashShare = 0.5;

/// What a Growth face gains each time it's used in a fight.
const int growthStep = 1;

/// A Pain strike's damage multiplier.
const int painDamageMultiplier = 2;

/// A Pain strike costs its roller this share of their max health.
const double painHealthShare = 0.08;

/// What a Steady face is worth on top of its number.
const int steadyBonus = 2;

/// The keyword named [name] (dice.json spelling, any case), or null.
FaceKeyword? faceKeywordNamed(String name) {
  final lower = name.trim().toLowerCase();
  for (final keyword in FaceKeyword.values) {
    if (keyword.name == lower) return keyword;
  }
  return null;
}

/// The keywords a dice.json face record carries (`keywords`, a list of
/// names; unknown names are skipped).
Set<FaceKeyword> faceKeywordsOf(Map<String, dynamic>? face) {
  final raw = face?['keywords'];
  if (raw is! List) return const {};
  return {
    for (final name in raw)
      if (faceKeywordNamed(name.toString()) != null)
        faceKeywordNamed(name.toString())!,
  };
}

/// Keywords that only mean something on a strike (an Attack face, or a
/// Skill face that deals damage).
const Set<FaceKeyword> strikeKeywords = {
  FaceKeyword.cleave,
  FaceKeyword.pierce,
  FaceKeyword.pain,
};

/// Whether [keyword] does anything on a face of [type] ('Attack',
/// 'Defend', 'Heal', 'Mana', 'Skill'): strike keywords want a face that
/// can hit, Growth and Steady a face with a number of its own or a skill
/// to lift, and Echo goes anywhere.
bool keywordFitsFaceType(FaceKeyword keyword, String type) {
  switch (keyword) {
    case FaceKeyword.cleave:
    case FaceKeyword.pierce:
    case FaceKeyword.pain:
      return type == 'Attack' || type == 'Skill';
    case FaceKeyword.growth:
    case FaceKeyword.steady:
      return type == 'Attack' ||
          type == 'Defend' ||
          type == 'Heal' ||
          type == 'Skill';
    case FaceKeyword.echo:
      return type != 'Empty';
  }
}

/// The health a Pain strike costs a roller of [maxHealth] at
/// [currentHealth]: [painHealthShare] of the max, at least 1, and never the
/// last point.
int painCost({required int maxHealth, required int currentHealth}) {
  if (currentHealth <= 1) return 0;
  final cost = max(1, (maxHealth * painHealthShare).round());
  return min(cost, currentHealth - 1);
}

/// The string key of [keyword]'s name ('keyword_cleave') and of its rules
/// line ('keyword_cleave_desc').
String keywordLabelKey(FaceKeyword keyword) => 'keyword_${keyword.name}';
String keywordDescriptionKey(FaceKeyword keyword) =>
    'keyword_${keyword.name}_desc';
