import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MobileGISApp());
}

class MobileGISApp extends StatelessWidget {
  const MobileGISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktek Mobile GIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Tema Modern Indigo / Slate Blue (elegan, bukan full hijau)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Royal Blue
          primary: const Color(0xFF1E40AF),
          secondary: const Color(0xFF0F766E), // Deep Teal aksen
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
