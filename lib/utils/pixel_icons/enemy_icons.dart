/// Icon paths for enemies (generated from enemies.json). The file name
/// matches the enemy's id exactly.
class EnemyIcons {
  EnemyIcons._();

  static String pathFor(String enemyId) => 'assets/icons/enemies/$enemyId.png';

  static const List<String> allIds = [
    'angel_judicator',
    'angel_sentinel',
    'bone_warden',
    'catacomb_ghoul',
    'cultist_acolyte',
    'demon_imp',
    'demon_tormentor',
    'dock_overseer',
    'harbor_rat',
    'hollow_court_inquisitor',
    'hollow_court_zealot',
    'hollow_reflection',
    'inquisition_auxiliary',
    'inquisition_high_warden',
    'inquisition_penitent',
    'inquisition_soldier',
    'inquisition_warden',
    'iron_golem',
    'kroll_the_branded',
    'plague_hound',
    'rat_matriarch',
    'slum_thug',
    'smuggler_captain',
    'street_bandit',
    'tear_spawn',
    'void_archon',
    'void_hound',
    'void_manifestation',
    'void_sovereign',
    'void_stalker',
    'void_wisp',
  ];
}
