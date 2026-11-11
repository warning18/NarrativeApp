// The game's shared colours (v1.885): every colour that two or more files
// drew with, in one place, with the hex it always had. The eight semantic
// tokens of the theme (`InkColors`, dark and light) come first and are the
// source of the theme's values; the others are named by hue and lightness
// (`amber77` is a warm yellow at 77% lightness), a name to rename the day a
// colour gets a role. A colour only one painter uses stays beside it.
import 'package:flutter/material.dart' show Colors, MaterialColor;
import 'package:flutter/painting.dart';

abstract final class Palette {
  Palette._();

  // --- tokens
  static const Color bloodLight = Color(0xFFA5302A);
  static const Color emberLight = Color(0xFFA84E12);
  static const Color tideLight = Color(0xFF226565);
  static const Color healLight = Color(0xFF3D7A2C);
  static const Color seamLight = Color(0xFFCFC4AE);
  static const Color ashLight = Color(0xFF6B6356);
  static const Color ashDark = Color(0xFFA8A194);
  static const Color bloodDark = Color(0xFFD9544D);
  static const Color emberDark = Color(0xFFE0762B);
  static const Color goldDark = Color(0xFFF2C14E);
  static const Color goldLight = Color(0xFF8A5A00);
  static const Color healDark = Color(0xFF7DBE6A);
  static const Color seamDark = Color(0xFF3B3743);
  static const Color tideDark = Color(0xFF4FB0B0);
  static const Color voidDark = Color(0xFFA987EA);
  static const Color voidLight = Color(0xFF6A4FB0);

  // --- white
  static const Color white = Color(0xFFFFFFFF);

  // --- black
  static const Color black = Color(0xFF000000);

  // --- clear
  static const Color clear = Color(0x00000000);

  // --- night
  static const Color alpha33Night0 = Color(0x33000000);
  static const Color night11 = Color(0xFF1A181E);
  static const Color night11a = Color(0xFF1C1B1F);
  static const Color night14 = Color(0xFF2A241D);
  static const Color night15 = Color(0xFF2B2420);
  static const Color night15a = Color(0xFF24212A);
  static const Color night16 = Color(0xFF2B2A28);
  static const Color night17 = Color(0xFF2A2233);
  static const Color night17a = Color(0xFF2A2433);
  static const Color night17b = Color(0xFF2B2830);
  static const Color night18 = Color(0xFF2C2A30);
  static const Color night23 = Color(0xFF38343F);
  static const Color night25 = Color(0xFF3A3A44);
  static const Color night28 = Color(0xFF5A4636);
  static const Color night30 = Color(0xFF4A4552);
  static const Color night7 = Color(0xFF14110F);
  static const Color night8 = Color(0xFF141217);
  static const Color night8a = Color(0xFF141218);
  static const Color night8b = Color(0xFF1B1710);
  static const Color night8c = Color(0xFF14121A);
  static const Color night9 = Color(0xFF17151B);

  // --- stone
  static const Color stone35 = Color(0xFF6E5A46);
  static const Color stone35a = Color(0xFF5F5B55);
  static const Color stone35b = Color(0xFF6E6246);
  static const Color stone36 = Color(0xFF5A5463);
  static const Color stone39 = Color(0xFF7A4A7C);
  static const Color stone42 = Color(0xFF7C735B);
  static const Color stone43 = Color(0xFF6E6A73);
  static const Color stone48 = Color(0xFF8E8468);
  static const Color stone50 = Color(0xFFA3865A);
  static const Color stone50a = Color(0xFF8F8771);
  static const Color stone51 = Color(0xFF8C857A);
  static const Color stone57 = Color(0xFF8A8F98);
  static const Color stone57a = Color(0xFF7F92A6);
  static const Color stone60 = Color(0xFF8C98A6);
  static const Color stone61 = Color(0xFF9A93A6);
  static const Color stone62 = Color(0xFF9E9E9E);
  static const Color stone63 = Color(0xFFA7A39C);
  static const Color stone65 = Color(0xFFA3A3AA);
  static const Color stone65a = Color(0xFF9AA7B4);
  static const Color stone66 = Color(0xFFA9B59A);
  static const Color stone67 = Color(0xFFAAAAAA);
  static const Color stone69 = Color(0xFF9FB0C2);

  // --- paper
  static const Color alpha00Paper100 = Color(0x00FFFFFF);
  static const Color paper79 = Color(0xFFD8D0BC);
  static const Color paper85 = Color(0xFFD9DDD2);
  static const Color paper88 = Color(0xFFE4E2DC);
  static const Color paper89 = Color(0xFFECE7DC);
  static const Color paper89a = Color(0xFFE9E6DF);
  static const Color paper93 = Color(0xFFF2F0EA);
  static const Color paper95 = Color(0xFFEFF3F6);

  // --- red
  static const Color red29 = Color(0xFF6E3527);
  static const Color red32 = Color(0xFF8A1A1A);
  static const Color red39 = Color(0xFF9B2A2A);
  static const Color red41 = Color(0xFFB3261E);
  static const Color red44 = Color(0xFFB0472E);
  static const Color red46 = Color(0xFFC0392B);
  static const Color red50 = Color(0xFFCF3E2F);
  static const Color red55 = Color(0xFFE53935);
  static const Color red58 = Color(0xFFE8473F);
  static const Color red59 = Color(0xFFEC407A);

  // --- orange
  static const Color orange11 = Color(0xFF2A1C10);
  static const Color orange16 = Color(0xFF3A2818);
  static const Color orange17 = Color(0xFF3A2A1E);
  static const Color orange17a = Color(0xFF3A2A1C);
  static const Color orange22 = Color(0xFF4A3426);
  static const Color orange25 = Color(0xFF5A3A26);
  static const Color orange28 = Color(0xFF5E4630);
  static const Color orange30 = Color(0xFF6B4A2E);
  static const Color orange35 = Color(0xFF7A5A3A);
  static const Color orange35a = Color(0xFF7A5B3A);
  static const Color orange38 = Color(0xFF8A6038);
  static const Color orange44 = Color(0xFF9A7448);
  static const Color orange45 = Color(0xFFB8862B);
  static const Color orange52 = Color(0xFFE0752B);
  static const Color orange52a = Color(0xFFB08A58);
  static const Color orange52b = Color(0xFFE0702A);
  static const Color orange54 = Color(0xFFB5935F);
  static const Color orange55 = Color(0xFFD9A441);
  static const Color orange56 = Color(0xFFFF6A1F);
  static const Color orange56a = Color(0xFFF2992E);
  static const Color orange58 = Color(0xFFB59A74);
  static const Color orange59 = Color(0xFFFF7A2E);
  static const Color orange60 = Color(0xFFC9A46A);
  static const Color orange60a = Color(0xFFC9A86A);
  static const Color orange61 = Color(0xFFC9A070);
  static const Color orange62 = Color(0xFFFF8A3D);
  static const Color orange62a = Color(0xFFFF8A3C);
  static const Color orange65 = Color(0xFFE5B566);
  static const Color orange65a = Color(0xFFF2B85A);
  static const Color orange68 = Color(0xFFF2A36B);
  static const Color orange71 = Color(0xFFFFC96B);
  static const Color orange71a = Color(0xFFFFC66B);
  static const Color orange73 = Color(0xFFE2B890);
  static const Color orange73a = Color(0xFFE9B48A);
  static const Color orange74 = Color(0xFFFFD27A);

  // --- brown
  static const Color brown13 = Color(0xFF2B2118);

  // --- amber
  static const Color amber46 = Color(0xFFD4A017);
  static const Color amber47 = Color(0xFFC9A227);
  static const Color amber61 = Color(0xFFE8B94E);
  static const Color amber66 = Color(0xFFC9B58A);
  static const Color amber7 = Color(0xFF1A1408);
  static const Color amber74 = Color(0xFFDCCB9F);
  static const Color amber77 = Color(0xFFFFE08A);
  static const Color amber77a = Color(0xFFD9CDB0);
  static const Color amber77b = Color(0xFFFFE48A);
  static const Color amber83 = Color(0xFFFFE9A8);
  static const Color amber84 = Color(0xFFE8DFC4);
  static const Color amber84a = Color(0xFFEADFC2);
  static const Color amber85 = Color(0xFFE6DFCB);
  static const Color amber86 = Color(0xFFEDE3C8);
  static const Color amber87 = Color(0xFFEFE6CF);
  static const Color amber88 = Color(0xFFEFE6D2);
  static const Color amber88a = Color(0xFFEDE6D6);
  static const Color amber91 = Color(0xFFF1EBDD);

  // --- green
  static const Color green40 = Color(0xFF3F8F5A);
  static const Color green43 = Color(0xFF3E9B57);
  static const Color green45 = Color(0xFF43A047);
  static const Color green53 = Color(0xFF6FBF4E);
  static const Color green63 = Color(0xFF6FD08C);
  static const Color green63a = Color(0xFF95D16F);
  static const Color green64 = Color(0xFFA8D96D);
  static const Color green74 = Color(0xFF9FD8A6);

  // --- teal
  static const Color teal53 = Color(0xFF38D6C0);
  static const Color teal79 = Color(0xFFA0F5E8);

  // --- cyan
  static const Color cyan34 = Color(0xFF2F5D7C);
  static const Color cyan64 = Color(0xFF4FC3F7);
  static const Color cyan69 = Color(0xFF8FC3CF);
  static const Color cyan73 = Color(0xFF9FC2D6);
  static const Color cyan75 = Color(0xFF80D8FF);
  static const Color cyan76 = Color(0xFF86D6FF);
  static const Color cyan87 = Color(0xFFCFE3EE);
  static const Color cyan88 = Color(0xFFC4EBFF);
  static const Color cyan93 = Color(0xFFE6F2F4);

  // --- blue
  static const Color blue12 = Color(0xFF0B1230);
  static const Color blue23 = Color(0xFF1E3F57);
  static const Color blue54 = Color(0xFF4C8FC7);
  static const Color blue61 = Color(0xFF42A5F5);
  static const Color blue71 = Color(0xFF8D6CFF);
  static const Color blue74 = Color(0xFF7C8CFF);
  static const Color blue78 = Color(0xFF8E9CFF);
  static const Color blue96 = Color(0xFFEAF4FF);
  static const Color blue97 = Color(0xFFF5F7FB);
  static const Color blue97a = Color(0xFFF4F7FA);

  // --- purple
  static const Color purple28 = Color(0xFF3A2A66);
  static const Color purple71 = Color(0xFF9A6BFF);

  // --- roles (the Material named colours the game used in 2+ files)
  /// A gain, a success, "better".
  static const MaterialColor good = Colors.green;

  /// Magic and the void-touched.
  static const MaterialColor arcane = Colors.deepPurple;

  /// A cool grey-blue for the plain and the technical.
  static const MaterialColor slate = Colors.blueGrey;

  /// Water and teal marks.
  static const MaterialColor lagoon = Colors.teal;

  /// Danger by fire.
  static const MaterialColor hot = Colors.deepOrange;

  /// No colour: unavailable, unknown.
  static const MaterialColor neutral = Colors.grey;

  /// A deeper good, for text.
  static const Color goodDeep = Color(0xFF388E3C);

  /// A warning, a hit.
  static const MaterialColor alert = Colors.red;

  /// A deep amber, for text on pale.
  static const Color amberDeep = Color(0xFFFF8F00);

  /// The second magic purple.
  static const MaterialColor violet = Colors.purple;

  /// A firm good, for numbers.
  static const Color goodStrong = Color(0xFF43A047);

  /// Warm orange.
  static const MaterialColor flame = Colors.orange;

  /// Wood and earth.
  static const MaterialColor earth = Colors.brown;

  /// A deep gold for the coin.
  static const Color goldDeep = Color(0xFFFFA000);

  /// A soft red-pink.
  static const MaterialColor rose = Colors.pink;

  /// Evening indigo.
  static const MaterialColor dusk = Colors.indigo;

  /// A firm red, for damage.
  static const Color danger = Color(0xFFD32F2F);
}
