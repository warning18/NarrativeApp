import 'package:flutter/material.dart';

/// "Stitched Ink", the app's look: a dark book you read, stitched to a
/// game you play.
///
/// - The prose is the hero: story text is Spectral at reading size, and
///   the chrome around it steps back.
/// - Systems speak in pixels: numbers, labels, buttons and dice use
///   Pixelify Sans, so mechanics read as game and writing reads as book.
/// - Titles, chapters and places are set in IM Fell English SC.
/// - 4 px corners and 1 px seams instead of shadows.
///
/// [buildAppTheme] applies the type and shapes to any [ColorScheme], so
/// every palette in Settings shares them; [stitchedInkScheme] is the
/// palette the look was drawn in (Shroud ground, Banner gold, Void purple),
/// with a parchment variant for light mode.
class InkFonts {
  InkFonts._();

  /// Narration and body text.
  static const String prose = 'Spectral';

  /// Numbers, labels, buttons, dice.
  static const String system = 'PixelifySans';

  /// Chapters, places, screen titles.
  static const String display = 'IMFellEnglishSC';
}

/// Colours with a meaning beyond the [ColorScheme]: HP, attacks, mana,
/// the Void, healing, and the page's seams. Read with
/// `Theme.of(context).extension<InkColors>()` or [InkColors.of].
@immutable
class InkColors extends ThemeExtension<InkColors> {
  const InkColors({
    required this.gold,
    required this.blood,
    required this.ember,
    required this.tide,
    required this.voidColor,
    required this.heal,
    required this.seam,
    required this.ash,
  });

  /// The main action; where the player is.
  final Color gold;

  /// HP and damage taken.
  final Color blood;

  /// Attacks, danger, telegraphs.
  final Color ember;

  /// Mana, the sea, defending.
  final Color tide;

  /// The tear, Rare items, alignment.
  final Color voidColor;

  /// Healing.
  final Color heal;

  /// Borders and dividers: the page's stitching.
  final Color seam;

  /// Quiet, secondary text.
  final Color ash;

  static const InkColors dark = InkColors(
    gold: Color(0xFFF2C14E),
    blood: Color(0xFFD9544D),
    ember: Color(0xFFE0762B),
    tide: Color(0xFF4FB0B0),
    voidColor: Color(0xFFA987EA),
    heal: Color(0xFF7DBE6A),
    seam: Color(0xFF3B3743),
    ash: Color(0xFFA8A194),
  );

  static const InkColors light = InkColors(
    gold: Color(0xFF8A5A00),
    blood: Color(0xFFA5302A),
    ember: Color(0xFFA84E12),
    tide: Color(0xFF226565),
    voidColor: Color(0xFF6A4FB0),
    heal: Color(0xFF3D7A2C),
    seam: Color(0xFFCFC4AE),
    ash: Color(0xFF6B6356),
  );

  /// The theme's own, or the dark or light default when a theme was built
  /// without one (a test's bare MaterialApp).
  static InkColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<InkColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  InkColors copyWith({
    Color? gold,
    Color? blood,
    Color? ember,
    Color? tide,
    Color? voidColor,
    Color? heal,
    Color? seam,
    Color? ash,
  }) =>
      InkColors(
        gold: gold ?? this.gold,
        blood: blood ?? this.blood,
        ember: ember ?? this.ember,
        tide: tide ?? this.tide,
        voidColor: voidColor ?? this.voidColor,
        heal: heal ?? this.heal,
        seam: seam ?? this.seam,
        ash: ash ?? this.ash,
      );

  @override
  InkColors lerp(ThemeExtension<InkColors>? other, double t) {
    if (other is! InkColors) return this;
    return InkColors(
      gold: Color.lerp(gold, other.gold, t)!,
      blood: Color.lerp(blood, other.blood, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      tide: Color.lerp(tide, other.tide, t)!,
      voidColor: Color.lerp(voidColor, other.voidColor, t)!,
      heal: Color.lerp(heal, other.heal, t)!,
      seam: Color.lerp(seam, other.seam, t)!,
      ash: Color.lerp(ash, other.ash, t)!,
    );
  }
}

/// The Stitched Ink palette: Shroud and Cloth with Bone ink and Banner
/// gold in the dark; parchment and sepia ink in the light.
ColorScheme stitchedInkScheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFF2C14E),
      onPrimary: Color(0xFF1A1408),
      primaryContainer: Color(0xFF2E2A1A),
      onPrimaryContainer: Color(0xFFF2C14E),
      secondary: Color(0xFF4FB0B0),
      onSecondary: Color(0xFF0E1A1A),
      secondaryContainer: Color(0xFF14262A),
      onSecondaryContainer: Color(0xFF7FD0D0),
      tertiary: Color(0xFFA987EA),
      onTertiary: Color(0xFF1A1225),
      tertiaryContainer: Color(0xFF2A2233),
      onTertiaryContainer: Color(0xFFC4B2EE),
      error: Color(0xFFD9544D),
      onError: Color(0xFF1A0908),
      errorContainer: Color(0xFF2E1A1A),
      onErrorContainer: Color(0xFFE88A84),
      surface: Color(0xFF141217),
      onSurface: Color(0xFFECE7DC),
      onSurfaceVariant: Color(0xFFA8A194),
      surfaceContainerLowest: Color(0xFF0E0D10),
      surfaceContainerLow: Color(0xFF1A181E),
      surfaceContainer: Color(0xFF1F1C23),
      surfaceContainerHigh: Color(0xFF24212A),
      surfaceContainerHighest: Color(0xFF29252E),
      surfaceTint: Colors.transparent,
      outline: Color(0xFF5A5463),
      outlineVariant: Color(0xFF3B3743),
      inverseSurface: Color(0xFFECE7DC),
      onInverseSurface: Color(0xFF141217),
      inversePrimary: Color(0xFF8A5A00),
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8A5A00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF2DFB0),
    onPrimaryContainer: Color(0xFF3A2600),
    secondary: Color(0xFF226565),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFE6E3),
    onSecondaryContainer: Color(0xFF0E3333),
    tertiary: Color(0xFF6A4FB0),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE4DAF6),
    onTertiaryContainer: Color(0xFF2A1A55),
    error: Color(0xFFA5302A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF5D9D5),
    onErrorContainer: Color(0xFF4A0E0A),
    surface: Color(0xFFF3EBD8),
    onSurface: Color(0xFF231F1A),
    onSurfaceVariant: Color(0xFF5E574B),
    surfaceContainerLowest: Color(0xFFFBF6EA),
    surfaceContainerLow: Color(0xFFEFE6D1),
    surfaceContainer: Color(0xFFEAE0C9),
    surfaceContainerHigh: Color(0xFFE4D9C0),
    surfaceContainerHighest: Color(0xFFDDD1B6),
    surfaceTint: Colors.transparent,
    outline: Color(0xFF9C917C),
    outlineVariant: Color(0xFFCFC4AE),
    inverseSurface: Color(0xFF231F1A),
    onInverseSurface: Color(0xFFF3EBD8),
    inversePrimary: Color(0xFFF2C14E),
    shadow: Colors.black,
    scrim: Colors.black,
  );
}

/// The app's theme over [scheme]: Stitched Ink's type, shapes and
/// components, in whatever colours the palette gives.
ThemeData buildAppTheme(ColorScheme scheme) {
  final dark = scheme.brightness == Brightness.dark;
  final ink = dark ? InkColors.dark : InkColors.light;
  // Seams and quiet text follow the scheme, so other palettes keep their
  // own tint; the meaning colours stay the same everywhere.
  final colors = ink.copyWith(
    seam: scheme.outlineVariant,
    ash: scheme.onSurfaceVariant,
  );
  const radius = BorderRadius.all(Radius.circular(4));
  const shape = RoundedRectangleBorder(borderRadius: radius);
  final seamSide = BorderSide(color: scheme.outlineVariant);

  final base = ThemeData(
    colorScheme: scheme,
    brightness: scheme.brightness,
    useMaterial3: true,
    fontFamily: InkFonts.prose,
  );
  final t = base.textTheme;
  TextStyle? display(TextStyle? s) =>
      s?.copyWith(fontFamily: InkFonts.display, fontWeight: FontWeight.w400);
  TextStyle? system(TextStyle? s) => s?.copyWith(fontFamily: InkFonts.system);
  final textTheme = t.copyWith(
    displayLarge: display(t.displayLarge),
    displayMedium: display(t.displayMedium),
    displaySmall: display(t.displaySmall),
    headlineLarge: display(t.headlineLarge),
    headlineMedium: display(t.headlineMedium),
    headlineSmall: display(t.headlineSmall),
    titleLarge: display(t.titleLarge),
    titleMedium: system(t.titleMedium),
    titleSmall: system(t.titleSmall),
    labelLarge: system(t.labelLarge),
    labelMedium: system(t.labelMedium),
    labelSmall: system(t.labelSmall),
    bodyLarge: t.bodyLarge?.copyWith(height: 1.5),
  );
  const buttonText =
      TextStyle(fontFamily: InkFonts.system, fontSize: 15, height: 1.2);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [colors],
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: seamSide),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      titleTextStyle: TextStyle(
        fontFamily: InkFonts.display,
        fontSize: 22,
        color: scheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: shape,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: InkFonts.system,
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        padding: buttonPadding,
        minimumSize: const Size(64, 48),
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // Story choices are elevated buttons: a card of Cloth with a seam,
      // its text in the prose face.
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: shape,
        side: seamSide,
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        disabledBackgroundColor: scheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
          fontFamily: InkFonts.prose,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        padding: buttonPadding,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: shape, textStyle: buttonText),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: shape,
        textStyle: buttonText.copyWith(fontSize: 13),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: shape,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius, side: seamSide),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: radius, side: seamSide),
      side: seamSide,
      labelStyle: TextStyle(
        fontFamily: InkFonts.system,
        fontSize: 12,
        color: scheme.onSurface,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius, side: seamSide),
      titleTextStyle: TextStyle(
        fontFamily: InkFonts.display,
        fontSize: 24,
        color: scheme.onSurface,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        side: seamSide,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius, side: seamSide),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: 15,
        color: scheme.onInverseSurface,
      ),
      shape: shape,
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: scheme.outline)),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      borderRadius: const BorderRadius.all(Radius.circular(2)),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(
        fontFamily: InkFonts.system,
        fontSize: 12,
        color: scheme.onInverseSurface,
      ),
      decoration:
          BoxDecoration(color: scheme.inverseSurface, borderRadius: radius),
    ),
  );
}

/// A dashed line down the left edge of a box: the stitched thread a
/// story page is sewn along, coloured by where the story is.
class StitchedEdgePainter extends CustomPainter {
  const StitchedEdgePainter({required this.color, this.width = 2});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    const dash = 5.0;
    const gap = 4.0;
    final x = width / 2;
    for (var y = 0.0; y < size.height; y += dash + gap) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(StitchedEdgePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}

/// A dashed horizontal rule: the seam between two parts of a page.
class StitchRule extends StatelessWidget {
  const StitchRule({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 8).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 4),
                color: c,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A small tag in the system face: a choice's cost ("+20 G"), a rarity,
/// a condition.
class InkTag extends StatelessWidget {
  const InkTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: InkFonts.system,
          fontSize: 12,
          height: 1.2,
          color: color,
        ),
      ),
    );
  }
}
