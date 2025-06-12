import 'package:flutter/material.dart';

String appName = 'نظم المستقبل للطاقة الشمسية والانظمة الحديثة';
String shortSlag = '';

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
  cardTheme: CardThemeData(
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
  cardTheme: CardThemeData(
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

String policy = '''store management app Privacy Policy
This privacy policy applies to the store management app app (hereby referred to as "Application") for mobile devices that was created by AbdulRasol A-Hilo (hereby referred to as "Service Provider") as a Freemium service. This service is intended for use "AS IS".


Information Collection and Use

The Application collects information when you download and use it. This information may include information such as

Your device's Internet Protocol address (e.g. IP address)
The pages of the Application that you visit, the time and date of your visit, the time spent on those pages
The time spent on the Application
The operating system you use on your mobile device
 


 

The Application does not gather precise information about the location of your mobile device.

The Application collects your device's location, which helps the Service Provider determine your approximate geographical location and make use of in below ways:

Geolocation Services: The Service Provider utilizes location data to provide features such as personalized content, relevant recommendations, and location-based services.
Analytics and Improvements: Aggregated and anonymized location data helps the Service Provider to analyze user behavior, identify trends, and improve the overall performance and functionality of the Application.
Third-Party Services: Periodically, the Service Provider may transmit anonymized location data to external services. These services assist them in enhancing the Application and optimizing their offerings.

 

The Service Provider may use the information you provided to contact you from time to time to provide you with important information, required notices and marketing promotions.


 

For a better experience, while using the Application, the Service Provider may require you to provide us with certain personally identifiable information, including but not limited to Store name. The information that the Service Provider request will be retained by them and used as described in this privacy policy.


Third Party Access

Only aggregated, anonymized data is periodically transmitted to external services to aid the Service Provider in improving the Application and their service. The Service Provider may share your information with third parties in the ways that are described in this privacy statement.


 

The Service Provider may disclose User Provided and Automatically Collected Information:

as required by law, such as to comply with a subpoena, or similar legal process;
when they believe in good faith that disclosure is necessary to protect their rights, protect your safety or the safety of others, investigate fraud, or respond to a government request;
with their trusted services providers who work on their behalf, do not have an independent use of the information we disclose to them, and have agreed to adhere to the rules set forth in this privacy statement.
 


Opt-Out Rights

You can stop all collection of information by the Application easily by uninstalling it. You may use the standard uninstall processes as may be available as part of your mobile device or via the mobile application marketplace or network.


Data Retention Policy

The Service Provider will retain User Provided data for as long as you use the Application and for a reasonable time thereafter. If you'd like them to delete User Provided Data that you have provided via the Application, please contact them at abdulrsol97@gmail.com and they will respond in a reasonable time.


Children

The Service Provider does not use the Application to knowingly solicit data from or market to children under the age of 13.


 

The Service Provider does not knowingly collect personally identifiable information from children. The Service Provider encourages all children to never submit any personally identifiable information through the Application and/or Services. The Service Provider encourage parents and legal guardians to monitor their children's Internet usage and to help enforce this Policy by instructing their children never to provide personally identifiable information through the Application and/or Services without their permission. If you have reason to believe that a child has provided personally identifiable information to the Service Provider through the Application and/or Services, please contact the Service Provider (abdulrsol97@gmail.com) so that they will be able to take the necessary actions. You must also be at least 16 years of age to consent to the processing of your personally identifiable information in your country (in some countries we may allow your parent or guardian to do so on your behalf).


Security

The Service Provider is concerned about safeguarding the confidentiality of your information. The Service Provider provides physical, electronic, and procedural safeguards to protect information the Service Provider processes and maintains.


Changes

This Privacy Policy may be updated from time to time for any reason. The Service Provider will notify you of any changes to the Privacy Policy by updating this page with the new Privacy Policy. You are advised to consult this Privacy Policy regularly for any changes, as continued use is deemed approval of all changes.


 

This privacy policy is effective as of 2025-04-09


Your Consent

By using the Application, you are consenting to the processing of your information as set forth in this Privacy Policy now and as amended by us.


Contact Us

If you have any questions regarding privacy while using the Application, or have questions about the practices, please contact the Service Provider via email at abdulrsol97@gmail.com.

''';
