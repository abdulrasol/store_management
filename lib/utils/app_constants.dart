import 'package:flutter/material.dart';

String appName = 'نظم المستقبل للطاقة الشمسية والانظمة الحديثة';
String shortSlag =
    'اشراف وتنفيذ وتجهيز منظومات الطاقة الشمسية المنزلية والزراعية والصناعية';

var appTheme = ThemeData(
  // This is the theme of your application.
  //
  // TRY THIS: Try running your application with "flutter run". You'll see
  // the application has a purple toolbar. Then, without quitting the app,
  // try changing the seedColor in the colorScheme below to Colors.green
  // and then invoke "hot reload" (save your changes or press the "hot
  // reload" button in a Flutter-supported IDE, or press "r" if you used
  // the command line to start the app).
  //
  // Notice that the counter didn't reset back to zero; the application
  // state is not lost during the reload. To reset the state, use hot
  // restart instead.
  //
  // This works for code too, not just values: Most code changes can be
  // tested with just a hot reload.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue.shade600,
    hoverColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),

  fontFamily: 'Rubik',
  fontFamilyFallback: ['Cairo', 'Tajawal'],
  //colorSchemeSeed: Colors.blue.shade600,

  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade400),
  useMaterial3: true,
);

// add reminder page

final inputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderSide: BorderSide(
      width: 1,
    ),
    borderRadius: BorderRadius.all(Radius.circular(7.0)),
  ),
);
final horSpace = const SizedBox(width: 12);
final verSpace = const SizedBox(height: 12);

var lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.blue.shade600,
  scaffoldBackgroundColor: Colors.grey.shade50, // خلفية فاتحة جدًا
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white, // خلفية بيضاء للتطبيق بار
    foregroundColor: Colors.black87, // لون نص التطبيق بار
    elevation: 0, // إزالة الظل من التطبيق بار
    titleTextStyle: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    iconTheme: IconThemeData(color: Colors.black87),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0, // إزالة الظل من الأزرار
      textStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none, // إزالة حدود حقول الإدخال
    ),
    filled: true,
    fillColor: Colors.white, // خلفية بيضاء لحقول الإدخال
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(
      fontFamily: 'Cairo',
      color: Colors.grey,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Cairo',
      color: Colors.grey,
    ),
    prefixIconColor: Colors.grey,
  ),
  cardTheme: CardTheme(
    elevation: 0, // إزالة الظل من البطاقات
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    color: Colors.white, // خلفية بيضاء للبطاقات
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
      color: Colors.black87,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      color: Colors.black87,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 48,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Colors.black87,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: Colors.black87,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Colors.black87,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      color: Colors.blue,
    ),
  ),
  colorScheme:
      ColorScheme.fromSwatch().copyWith(secondary: Colors.blue.shade600),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  primaryColor: Colors.blue.shade800,
  scaffoldBackgroundColor: Colors.grey.shade900,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black87,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade800,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.grey.shade800,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(
      fontFamily: 'Cairo',
      color: Colors.grey,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Cairo',
      color: Colors.grey,
    ),
    prefixIconColor: Colors.grey,
  ),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    color: Colors.grey.shade800,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
      color: Colors.white70,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      color: Colors.white70,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 48,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Cairo',
      fontSize: 34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Colors.white70,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Cairo',
    ),
  ),
); // استخدم خط Cairo من الأصول
