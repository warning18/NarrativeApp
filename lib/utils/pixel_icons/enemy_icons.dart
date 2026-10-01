/// Icon paths for enemies (generated from enemies.json). The file name
/// matches the enemy's id exactly.
class EnemyIcons {
  EnemyIcons._();

  static String pathFor(String enemyId) =>
      'assets/icons/enemies/${_borrowed[enemyId] ?? enemyId}.png';

  /// Enemies drawn with another's icon until they have their own: the
  /// Tide-Mother's arm (see sea_beasts.dart) as the Unstitched, and the
  /// v1.176-v1.182 foes as the nearest of their kind.
  static const Map<String, String> _borrowed = {
    'kraken_arm': 'tear_spawn',
    // v1.196's chapter 1: the casino's first fight, the wreck's
    // scavengers and the Inquisitor-General.
    'den_bouncer': 'slum_thug',
    'den_looter': 'street_bandit',
    'sore_loser': 'slum_thug',
    'wreck_scavenger': 'street_bandit',
    'aurel_vane': 'inquisition_high_warden',
    'brine_jack': 'smuggler_captain',
    'glass_shepherd': 'hollow_reflection',
    'knell_keeper': 'hollow_court_zealot',
    'purifier_vell': 'inquisition_warden',
    'rime_bailiff': 'bone_sexton',
  };

  static const List<String> allIds = [
    'angel_judicator',
    'angel_sentinel',
    'aurel_vane',
    'bone_sexton',
    'bone_warden',
    'brine_jack',
    'catacomb_ghoul',
    'cultist_acolyte',
    'demon_imp',
    'demon_tormentor',
    'den_bouncer',
    'den_looter',
    'dock_overseer',
    'drowned_pilgrim',
    'frost_kept_giant',
    'glass_shepherd',
    'grosh_turned',
    'harbor_rat',
    'hollow_court_inquisitor',
    'hollow_court_zealot',
    'hollow_reflection',
    'horn_taker',
    'inquisition_auxiliary',
    'inquisition_high_warden',
    'inquisition_legate',
    'inquisition_penitent',
    'inquisition_soldier',
    'inquisition_warden',
    'iron_golem',
    'kelda_turned',
    'knell_keeper',
    'kraken_arm',
    'kroll_the_branded',
    'liora_turned',
    'malrik_turned',
    'maren_turned',
    'masked_penitent',
    'plague_hound',
    'purifier_vell',
    'rat_matriarch',
    'rime_bailiff',
    'sable_turned',
    'slum_thug',
    'smuggler_captain',
    'sore_loser',
    'strand_colossus',
    'street_bandit',
    'tear_spawn',
    'teind_rider',
    'tobin_turned',
    'unmade_knight',
    'vess_turned',
    'void_archon',
    'void_hound',
    'void_manifestation',
    'void_sovereign',
    'void_stalker',
    'void_wisp',
    'white_admiral',
    'white_soldier',
    'wreck_scavenger',
  ];
}
