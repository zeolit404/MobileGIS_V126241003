import 'dart:ui';
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
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  static const String _himapsPath = 'assets/himaps_.jpeg';
  static const String _logoUnhasPath = 'assets/logo_unhas.png';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Navigasi otomatis ke HomePage setelah 2.5 detik
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background blur halus jika file foto tersedia
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Image.asset(
              _himapsPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              ),
            ),
          ),
          Container(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Universitas Hasanuddin
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _logoUnhasPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school,
                          size: 70,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PRAKTEK MOBILE GIS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'D4 Penginderaan Jauh & Sistem Informasi Geografis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                    ),
                  ),
                  Text(
                    'Fakultas Vokasi • Universitas Hasanuddin',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
