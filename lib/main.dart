import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolCare',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6EFD),
          brightness: Brightness.light,
        ),

        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'SF Pro Display'),
          displayMedium: TextStyle(fontFamily: 'SF Pro Display'),
          displaySmall: TextStyle(fontFamily: 'SF Pro Display'),

          titleLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600),

          bodyLarge: TextStyle(fontFamily: 'SF Pro Text'),
          bodyMedium: TextStyle(fontFamily: 'SF Pro Text'),
          bodySmall: TextStyle(fontFamily: 'SF Pro Text'),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}