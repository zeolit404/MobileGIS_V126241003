import 'dart:async';
import 'package:flutter/material.dart';

import '../services/theme_manager.dart';
import '../services/weather_service.dart';
import 'history_page.dart';
import 'map_page.dart';
import 'photo_history_page.dart';
import 'survey_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  WeatherData? _weather;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    // Refresh cuaca secara periodik setiap 3 menit
    _weatherTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted) _fetchWeather();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final w = await WeatherService.getMakassarWeather();
    if (mounted) {
      setState(() => _weather = w);
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const MapPage();
      case 1:
        return const SurveyFormPage();
      case 2:
        return const HistoryPage();
      default:
        return const PhotoHistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mobile GIS Unhas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            // Tetap menyematkan NIM & Identitas Anda
            Text(
              'NIM: V126241003 — M. Arief Abdillah',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // 1. Status Cuaca Makassar Real-Time (Khusus pada Laman Survei)
          if (_currentIndex == 1)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade400, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _weather?.icon ?? Icons.wb_sunny_rounded,
                        color: Colors.amberAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_weather?.tempString ?? "30°C"} ${_weather?.condition ?? "Cerah"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Tombol Pengubah Tema (Theme Switcher: Terang / Gelap)
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager.themeModeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: InkWell(
                    onTap: ThemeManager.toggleTheme,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.amberAccent : Colors.white38,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: isDark ? Colors.amberAccent : Colors.amber.shade200,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDark ? 'Gelap' : 'Terang',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildPage(_currentIndex),
      // MENU DIKEMBALIKAN KE BAWAH (BottomNavigationBar)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            _fetchWeather(); // Segarkan cuaca saat tab survei dibuka
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.blueAccent),
            label: 'Peta RBI',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_location_alt_outlined),
            selectedIcon: Icon(Icons.edit_location_alt, color: Colors.blueAccent),
            label: 'Survei',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Colors.blueAccent),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: Colors.blueAccent),
            label: 'Foto',
          ),
        ],
      ),
    );
  }
}
