import 'dart:math';

/// Curated, tone-matched name pools per race id (matching races.json), for
/// the "randomize" button on the character-name field. Unisex by design —
/// character creation has no separate gender field to key off of. Kept as
/// plain proper nouns (no EN/FR split): names aren't translated content,
/// they're flavor text a player can also just type over.
const Map<String, List<String>> _namesByRace = {
  'human': [
    'Aldric', 'Rowan', 'Mira', 'Talia', 'Bramwell', 'Corvin', 'Elsbeth',
    'Garrick', 'Isolde', 'Joren', 'Kestrel', 'Liora', 'Merrick', 'Nadia',
    'Osric', 'Perrin', 'Quinlan', 'Sabine', 'Torvin', 'Wren',
  ],
  'elf': [
    'Elowen', 'Thalindra', 'Sylvaris', 'Caelnor', 'Ithreal', 'Naeris',
    'Ondriel', 'Faelwyn', 'Virelle', 'Quorien', 'Aelindra', 'Belanor',
    'Cirwen', 'Eirwyn', 'Fenariel', 'Galewen', 'Hesperiel', 'Ilvaris',
    'Jorendel', 'Keliadris',
  ],
  'dwarf': [
    'Thrain', 'Borgni', 'Dain', 'Ulfric', 'Brenna', 'Hilda', 'Grimna',
    'Oskar', 'Fendrel', 'Karsa', 'Novak', 'Thora', 'Baldrin', 'Drusk',
    'Egrim', 'Fjolla', 'Grunhild', 'Harnik', 'Ingrid', 'Kordan',
  ],
  'orc': [
    'Ghazak', 'Vorka', 'Tharn', 'Grosh', 'Nakka', 'Ruzka', 'Draka', 'Kesh',
    'Vashna', 'Grukk', 'Heska', 'Morrga', 'Uzgar', 'Yulka', 'Zoraka',
    'Bakka', 'Dresha', 'Karnok', 'Molgra', 'Tuzka',
  ],
  'voidkin': [
    'Nyxara', 'Vael', 'Threnody', 'Ashcael', 'Wisperia', 'Corvael',
    'Duskryn', 'Hollowen', 'Ilvane', 'Jetheris', 'Kaelvox', 'Lethyr',
    'Morvane', 'Nyth', 'Oblith', 'Pallenor', 'Quyren', 'Ravencael',
    'Sylveth', 'Tenevar',
  ],
};

final List<String> _allNames = _namesByRace.values.expand((names) => names).toList();

/// A random character name, drawn from [raceId]'s own name pool when
/// recognized, or the combined pool of every race otherwise (an unknown or
/// null raceId shouldn't block the feature, just widen it).
String randomCharacterName(String? raceId, [Random? random]) {
  final rng = random ?? Random();
  final pool = _namesByRace[raceId] ?? _allNames;
  return pool[rng.nextInt(pool.length)];
}
