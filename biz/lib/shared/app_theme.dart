import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Build the dark appearance with --dart-define=LIGHT_UI=false.
class AppAppearance {
  static const bool isLight = bool.fromEnvironment(
    'LIGHT_UI',
    defaultValue: true,
  );
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
    statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: isLight
        ? Brightness.dark
        : Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
}

class AppColors {
  static const Color background = AppAppearance.isLight
      ? Color(0xFFF8F7F3)
      : Color(0xFF0F0F0F);
  static const Color surface = AppAppearance.isLight
      ? Colors.white
      : Color(0xFF202026);
  static const Color surfaceMuted = AppAppearance.isLight
      ? Color(0xFFF0EFE9)
      : Color(0xFF262B35);
  static const Color textPrimary = AppAppearance.isLight
      ? Color(0xFF242622)
      : Colors.white;
  static const Color textSecondary = AppAppearance.isLight
      ? Color(0xFF686D63)
      : Color(0xFFABABAD);
  static const Color border = AppAppearance.isLight
      ? Color(0xFFE5E5DD)
      : Color(0xFF2A3144);
  static const Color chatIncoming = AppAppearance.isLight
      ? Colors.white
      : Color(0xE6272533);
  static const Color chatOutgoing = AppAppearance.isLight
      ? Color(0xFFFFF0B2)
      : Color(0xE6FFF9B4);
  static const Color chatOutgoingText = Color(0xFF3D3734);
  static const Color link = AppAppearance.isLight
      ? Color(0xFF375FA8)
      : Color(0xFF85C0FF);
  static const Color accentForeground = Color(0xFF242622);
  static const Color accentText = AppAppearance.isLight
      ? Color(0xFF746000)
      : primary;
  static const Color selected = AppAppearance.isLight
      ? Color(0xFFFFE989)
      : Color(0xFFEDEFF3);
  // Explicit foregrounds for photo/video overlays and saturated controls.
  static const Color rose = AppAppearance.isLight
      ? Color(0xFFA13478)
      : Color(0xFFFF8EC9);
  static const Color error = AppAppearance.isLight
      ? Color(0xFFB42333)
      : Color(0xFFFF8B95);
  static const Color notification = Color(0xFFD92D20);
  static const Color onMedia = Colors.white;
  static const Color onColor = Colors.white;
  static const Color mediaScrim = Color(0x99000000);
  static const Color barrier = Color(0x66000000);
  static const Color shadow = Color(0x14000000);
  static const Color disabled = AppAppearance.isLight
      ? Color(0xFF777C72)
      : Color(0xFFABABAD);
  // Legacy names resolve to semantic light surfaces as well.

  static const Color main = background;
  static const Color primary = Color(0xFFFFE407);
  static const Color secondPage = surface;
  static const Color ocBox = surfaceMuted;
  static const Color ocMain = Color(0xFFFFE407);
  static const Color undo = Color(0xFF666666);
  static const Color base_background = background;
  static const Color premMain = Color(0xFFFFEB8A);
  static const Color ocBg = Color(0xFFFFF0E9);
  static const Color ocSecondBg = Color(0xFFFFF2D8);

  static const Color mainLightColor = Color(0xFFFFE407);
  static const Color mainDarkColor = accentForeground;

  static const Color color_ff202026 = surface;
}

class AppFonts {
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

class Durations {}

class AppTheme {
  static ThemeData get theme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFE2BE32),
          brightness: AppAppearance.isLight
              ? Brightness.light
              : Brightness.dark,
        ).copyWith(
          primary: AppColors.accentText,
          onPrimary: AppAppearance.isLight
              ? Colors.white
              : AppColors.accentForeground,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      textTheme: Typography.material2021().black.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: AppAppearance.overlayStyle,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentText,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
