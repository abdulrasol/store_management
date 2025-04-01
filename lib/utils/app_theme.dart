import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية
  static const Color primaryLight = Color(0xFF1E88E5); // زرقة متوسطة
  static const Color primaryLightVariant = Color(0xFF1565C0); // زرقة داكنة
  static const Color primaryDark = Color(0xFF0D47A1); // زرقة داكنة جدًا
  static const Color secondaryLight = Color(0xFFE3F2FD); // زرقة فاتحة
  static const Color secondaryLightVariant =
      Color(0xFFBBDEFB); // زرقة فاتحة جدًا

  // ألوان للوضع المظلم
  static const Color primaryDarkMode =
      Color(0xFF1565C0); // أزرق داكن للوضع المظلم
  static const Color backgroundDarkMode = Color(0xFF121212); // خلفية داكنة
  static const Color surfaceDarkMode = Color(0xFF1E1E1E); // سطح داكن
  static const Color secondaryDarkMode =
      Color(0xFF0D47A1); // تفاصيل زرقاء داكنة

  // ظلال رمادية مشتركة
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // الثيم الرئيسي (الوضع العادي)
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo', // استخدام الخط المحلي
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: secondaryLightVariant,
        onPrimaryContainer: primaryDark,
        secondary: primaryLightVariant,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: primaryDark,
        tertiary: primaryLightVariant,
        onTertiary: Colors.white,
        tertiaryContainer: secondaryLight,
        onTertiaryContainer: primaryDark,
        error: Colors.red.shade700,
        onError: Colors.white,
        errorContainer: Colors.red.shade100,
        onErrorContainer: Colors.red.shade900,
        surface: Colors.white,
        onSurface: Colors.grey.shade900,
        surfaceContainerHighest: Colors.grey.shade100,
        onSurfaceVariant: Colors.grey.shade700,
        outline: Colors.grey.shade400,
        outlineVariant: Colors.grey.shade300,
        shadow: Colors.black.withOpacity(0.1),
        scrim: Colors.black.withOpacity(0.3),
        inverseSurface: Colors.grey.shade900,
        onInverseSurface: Colors.white,
        inversePrimary: secondaryLight,
        surfaceTint: primaryLight.withOpacity(0.05),
      ),

      // تخصيصات الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: BorderSide(color: primaryLight),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      // تخصيصات حقول النص
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey.shade700,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey.shade400,
        ),
      ),

      // تخصيصات البطاقات
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.white,
        shadowColor: Colors.blue.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
      ),

      // تخصيصات خاصة بالقائمة المنسدلة
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          color: Colors.black87,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // تخصيصات للأيقونات
      iconTheme: IconThemeData(
        color: primaryLight,
        size: 24,
      ),

      // تخصيصات للرسوم البيانية
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 16,
      ),

      // تخصيصات للظلال
      shadowColor: Colors.blue.withOpacity(0.3),

      // تخصيصات للأدوات المسطحة (مثل التذييل والرأس)
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: primaryDark,
        ),
        iconTheme: IconThemeData(
          color: primaryLight,
        ),
      ),

      // تخصيصات للبراجريس بار
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryLight,
        linearTrackColor: secondaryLight,
        circularTrackColor: secondaryLight,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: secondaryLight,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: primaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // تخصيصات للهوفر والتفاعل
      hoverColor: secondaryLight.withOpacity(0.3),
      splashColor: secondaryLight.withOpacity(0.5),
      highlightColor: secondaryLight.withOpacity(0.2),
    );
  }

  // الثيم الثانوي (الوضع المظلم)
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo', // استخدام الخط المحلي
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryDarkMode,
        onPrimary: Colors.white,
        primaryContainer: Colors.blue.shade900,
        onPrimaryContainer: Colors.blue.shade100,
        secondary: secondaryDarkMode,
        onSecondary: Colors.white,
        secondaryContainer: Colors.blue.shade800,
        onSecondaryContainer: Colors.blue.shade100,
        tertiary: Colors.blue.shade200,
        onTertiary: Colors.blue.shade900,
        tertiaryContainer: Colors.blue.shade800,
        onTertiaryContainer: Colors.blue.shade100,
        error: Colors.red.shade300,
        onError: Colors.black,
        errorContainer: Colors.red.shade900,
        onErrorContainer: Colors.red.shade100,
        surface: surfaceDarkMode,
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF303030),
        onSurfaceVariant: Colors.white70,
        outline: Colors.grey.shade600,
        outlineVariant: Colors.grey.shade700,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
        inversePrimary: Colors.blue.shade800,
        surfaceTint: Colors.transparent,
      ),

      // تخصيصات الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkMode,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade300,
          side: BorderSide(color: Colors.blue.shade300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue.shade300,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      // تخصيصات حقول النص
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF272727),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey.shade300,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey.shade500,
        ),
      ),

      // تخصيصات البطاقات
      cardTheme: CardTheme(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: const Color(0xFF272727),
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),

      // تخصيصات خاصة بالقائمة المنسدلة
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          color: Colors.white,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF272727)),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // تخصيصات للأيقونات
      iconTheme: IconThemeData(
        color: Colors.blue.shade300,
        size: 24,
      ),

      // تخصيصات للرسوم البيانية
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 16,
      ),

      // تخصيصات للظلال
      shadowColor: Colors.black,

      // تخصيصات للأدوات المسطحة (مثل التذييل والرأس)
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDarkMode,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          color: Colors.blue.shade300,
        ),
      ),

      // تخصيصات للبراجريس بار
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Colors.blue.shade300,
        linearTrackColor: Colors.blue.shade800,
        circularTrackColor: Colors.blue.shade800,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.blue.shade800,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // تخصيصات للهوفر والتفاعل
      hoverColor: Colors.blue.shade900.withOpacity(0.3),
      splashColor: Colors.blue.shade800.withOpacity(0.5),
      highlightColor: Colors.blue.shade900.withOpacity(0.2),
    );
  }
}
