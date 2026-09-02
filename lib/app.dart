import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'theme/game_colors.dart';

class PuzzlioApp extends StatelessWidget {
  const PuzzlioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzlio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

const double kMatRadius = 20;
const double kChipRadius = 14;

/// Builds the app's theme for one brightness. Chrome (app bar, dialogs,
/// buttons) stays a quiet, near-monochrome ink/paper pair; color is spent
/// on each game's own accent from [GameColors] instead of a single brand
/// hue, so [GameColors.hanada] is reused here only as the seed for
/// generic interactive states (button fills, selection highlights).
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GameColors.hanada,
    brightness: brightness,
  );
  final background = isDark ? const Color(0xFF17181B) : const Color(0xFFF1F1EC);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
  );

  final bodyTextTheme = GoogleFonts.zenKakuGothicNewTextTheme(base.textTheme);
  final displayStyle = GoogleFonts.kosugiMaru();

  TextStyle asDisplay(TextStyle? style) => displayStyle.copyWith(
        fontSize: style?.fontSize,
        color: style?.color,
        height: style?.height,
      );

  final textTheme = bodyTextTheme.copyWith(
    headlineMedium: asDisplay(bodyTextTheme.headlineMedium),
    titleLarge: asDisplay(bodyTextTheme.titleLarge),
    titleMedium: asDisplay(bodyTextTheme.titleMedium),
    labelSmall: bodyTextTheme.labelSmall?.copyWith(letterSpacing: 0.2),
    labelMedium: bodyTextTheme.labelMedium?.copyWith(letterSpacing: 0.2),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle:
          textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMatRadius)),
      titleTextStyle:
          textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kChipRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kChipRadius),
        ),
        textStyle: bodyTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: bodyTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
    ),
  );
}
