import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = _textTheme(base.textTheme, isDark: false);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.black,
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        secondary: AppColors.gold,
        surface: AppColors.lightSurface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.black,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerColor: AppColors.lightBorder,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        horizontalTitleGap: 10,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.lightSurfaceAlt,
        selectedColor: AppColors.sand,
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.lightMuted),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _inputBorder(AppColors.lightBorder),
        enabledBorder: _inputBorder(AppColors.lightBorder),
        focusedBorder: _inputBorder(AppColors.gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          foregroundColor: AppColors.black,
          side: const BorderSide(color: AppColors.lightBorder),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(AppColors.gold),
          textStyle: MaterialStateProperty.all<TextStyle?>(
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.black,
        unselectedLabelColor: AppColors.lightMuted,
        indicator: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.sand,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return GoogleFonts.tajawal(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: selected ? AppColors.black : AppColors.lightMuted,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    final textTheme = _textTheme(base.textTheme, isDark: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.yellow,
        surface: AppColors.darkSurface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerColor: AppColors.darkBorder,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        horizontalTitleGap: 10,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.darkSurfaceAlt,
        selectedColor: const Color(0xFF2F2818),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.darkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.darkMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _inputBorder(AppColors.darkBorder),
        enabledBorder: _inputBorder(AppColors.darkBorder),
        focusedBorder: _inputBorder(AppColors.gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          foregroundColor: const Color(0xFFE9E9E9),
          side: const BorderSide(color: AppColors.darkBorder),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(AppColors.yellow),
          textStyle: MaterialStateProperty.all<TextStyle?>(
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.yellow,
        unselectedLabelColor: AppColors.darkMuted,
        indicator: BoxDecoration(
          color: const Color(0xFF2F2818),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        indicatorColor: const Color(0xFF2F2818),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return GoogleFonts.tajawal(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: selected ? AppColors.yellow : AppColors.darkMuted,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, {required bool isDark}) {
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark ? const Color(0xFFE4E4E4) : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return GoogleFonts.tajawalTextTheme(base).copyWith(
      headlineSmall: GoogleFonts.tajawal(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        height: 1.45,
        color: titleColor,
      ),
      titleLarge: GoogleFonts.tajawal(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        height: 1.42,
        color: titleColor,
      ),
      titleMedium: GoogleFonts.tajawal(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: titleColor,
      ),
      titleSmall: GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.48,
        color: titleColor,
      ),
      bodyLarge: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.98,
        color: bodyColor,
      ),
      bodyMedium: GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.86,
        color: isDark ? const Color(0xFFCFCFCF) : AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.68,
        color: muted,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }

  static ButtonStyle _buttonStyle({
    Color? backgroundColor,
    required Color foregroundColor,
    BorderSide? side,
    TextStyle? textStyle,
  }) {
    return ButtonStyle(
      backgroundColor: backgroundColor == null
          ? null
          : MaterialStateProperty.all<Color>(backgroundColor),
      foregroundColor: MaterialStateProperty.all<Color>(foregroundColor),
      minimumSize: MaterialStateProperty.all<Size>(const Size.fromHeight(46)),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      side: side == null ? null : MaterialStateProperty.all<BorderSide>(side),
      shape: MaterialStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: MaterialStateProperty.all<TextStyle?>(textStyle),
    );
  }
}
