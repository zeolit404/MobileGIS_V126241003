import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'services/theme_manager.dart';

void main() {
  runApp(const MobileGISApp());
}

class MobileGISApp extends StatelessWidget {
  const MobileGISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Praktek Mobile GIS',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          // Tema Terang (Light Mode)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Royal Blue
              brightness: Brightness.light,
              primary: const Color(0xFF1E40AF),
              secondary: const Color(0xFF0F766E),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B), // Dark Slate Blue
              foregroundColor: Colors.white,
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          // Tema Gelap (Dark Mode)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.dark,
              primary: const Color(0xFF3B82F6),
              secondary: const Color(0xFF14B8A6),
              surface: const Color(0xFF1E293B),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade800),
              ),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
