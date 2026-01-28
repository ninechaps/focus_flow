import 'package:flutter/material.dart';

/// Global theme configuration for the application
/// Provides compact, desktop-appropriate sizing for fonts and inputs
/// Color palette: Minimalist blue for productivity/trust
class AppTheme {
  AppTheme._();

  // ===================
  // Font Sizes - Compact desktop scale
  // ===================
  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 13.0;
  static const double fontSizeLg = 15.0;
  static const double fontSizeXl = 17.0;
  static const double fontSizeXxl = 21.0;
  static const double fontSizeDisplay = 26.0;

  // ===================
  // Spacing - Tighter for compact layout
  // ===================
  static const double spacingXs = 2.0;
  static const double spacingSm = 6.0;
  static const double spacingMd = 10.0;
  static const double spacingLg = 14.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 28.0;

  // ===================
  // Input Field Sizes
  // ===================
  static const double inputHeight = 32.0;
  static const double buttonHeight = 30.0;
  static const double iconSizeSm = 14.0;
  static const double iconSizeMd = 16.0;
  static const double iconSizeLg = 20.0;

  // ===================
  // Border Radius
  // ===================
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;

  // ===================
  // Colors - Modern Indigo Palette (Light)
  // ===================
  static const MaterialColor primaryColor = MaterialColor(0xFF6366F1, <int, Color>{
    50: Color(0xFFEEF2FF),
    100: Color(0xFFE0E7FF),
    200: Color(0xFFC7D2FE),
    300: Color(0xFFA5B4FC),
    400: Color(0xFF818CF8),
    500: Color(0xFF6366F1),
    600: Color(0xFF4F46E5),
    700: Color(0xFF4338CA),
    800: Color(0xFF3730A3),
    900: Color(0xFF312E81),
  });
  static const Color accentColor = Color(0xFF06B6D4); // Cyan for accents
  static const Color textPrimary = Color(0xFF1E293B); // Slate-800
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textHint = Color(0xFF94A3B8); // Slate-400
  static const Color dividerColor = Color(0xFFE2E8F0); // Slate-200
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444); // Red-500
  static const Color successColor = Color(0xFF10B981); // Emerald-500

  // ===================
  // Colors - Dark Palette
  // ===================
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate-100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color darkTextHint = Color(0xFF64748B); // Slate-500
  static const Color darkDividerColor = Color(0xFF334155); // Slate-700
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Slate-900
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Slate-800
  static const Color darkPrimaryColor = Color(0xFF818CF8); // Indigo-400 (brighter for dark)

  /// Build the complete light ThemeData for the application
  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // Text Theme - Compact sizes for desktop
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXxl,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXl,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXl,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // Input Decoration Theme - Compact styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontSize: fontSizeSm,
          color: textHint,
        ),
        labelStyle: const TextStyle(
          fontSize: fontSizeSm,
          color: textSecondary,
        ),
        errorStyle: const TextStyle(
          fontSize: fontSizeXs,
          color: errorColor,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Elevated Button Theme - Compact
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        size: iconSizeMd,
        color: textSecondary,
      ),

      // AppBar Theme - Compact
      appBarTheme: const AppBarTheme(
        toolbarHeight: 40,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(
          size: iconSizeMd,
          color: textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: dividerColor,
        space: spacingMd,
      ),
    );
  }

  /// Build the complete dark ThemeData for the application
  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,

      // Text Theme - Dark colors
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeDisplay,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXxl,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXl,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXl,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMd,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
        ),
      ),

      // Input Decoration Theme - Dark styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkDividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkDividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryColor.shade400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontSize: fontSizeSm,
          color: darkTextHint,
        ),
        labelStyle: const TextStyle(
          fontSize: fontSizeSm,
          color: darkTextSecondary,
        ),
        errorStyle: const TextStyle(
          fontSize: fontSizeXs,
          color: errorColor,
        ),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),

      // Elevated Button Theme - Compact
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        size: iconSizeMd,
        color: darkTextSecondary,
      ),

      // AppBar Theme - Compact
      appBarTheme: const AppBarTheme(
        toolbarHeight: 40,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLg,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: IconThemeData(
          size: iconSizeMd,
          color: darkTextPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: darkDividerColor,
        space: spacingMd,
      ),
    );
  }
}

/// Extension on BuildContext for theme-aware color access
/// Use context.appColors.xxx instead of AppTheme.xxx for dark mode support
extension AppThemeContext on BuildContext {
  AppColors get appColors => AppColors.of(this);
}

/// Theme-aware color palette accessor
class AppColors {
  final BuildContext _context;

  const AppColors._(this._context);

  factory AppColors.of(BuildContext context) => AppColors._(context);

  bool get isDark => Theme.of(_context).brightness == Brightness.dark;

  // Primary
  Color get primary => isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
  MaterialColor get primarySwatch => AppTheme.primaryColor;
  Color get primaryHover => isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);
  Color get accent => AppTheme.accentColor;

  // Text
  Color get textPrimary => isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get textSecondary => isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get textHint => isDark ? AppTheme.darkTextHint : AppTheme.textHint;

  // Surfaces
  Color get background => isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
  Color get surface => isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
  Color get divider => isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;

  // Semantic
  Color get error => AppTheme.errorColor;
  Color get success => AppTheme.successColor;

  // Special derived colors
  /// Light primary tint for selected items (e.g., active nav items, selected cards)
  Color get primaryLight => isDark
      ? primary.withValues(alpha: 0.15)
      : const Color(0xFFEEF2FF);

  /// Subtle hover background
  Color get hoverBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFFF1F5F9);

  /// Badge background for counts
  Color get badgeBg => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFF1F5F9);

  /// Active badge background
  Color get activeBadgeBg => isDark
      ? primary.withValues(alpha: 0.2)
      : const Color(0xFFE0E7FF);

  /// Shadow color
  Color get shadow => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  /// Subtle shadow color
  Color get shadowLight => isDark
      ? Colors.black.withValues(alpha: 0.15)
      : Colors.black.withValues(alpha: 0.05);

  /// Dialog surface color
  Color get dialogSurface => isDark
      ? const Color(0xFF1E293B)
      : Colors.white;

  /// Dialog border color
  Color get dialogBorder => isDark
      ? const Color(0xFF334155)
      : const Color(0xFFE2E8F0);

  /// Subtask left border color
  Color get subtaskBorder => isDark
      ? primary.withValues(alpha: 0.3)
      : const Color(0xFFE0E7FF);

  /// On-primary text color (text on primary-colored backgrounds)
  Color get onPrimary => Colors.white;

  /// Checkbox/toggle unchecked border
  Color get checkboxBorder => isDark
      ? const Color(0xFF475569)
      : AppTheme.dividerColor;

  /// Progress section background
  Color get progressBg => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : const Color(0xFFF1F5F9);

  /// Detail section border
  Color get sectionBorder => isDark
      ? const Color(0xFF334155)
      : const Color(0xFFF1F5F9);
}
