import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class PuzzlioApp extends StatelessWidget {
  const PuzzlioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF5B5FEF);

    return MaterialApp(
      title: 'Puzzlio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
