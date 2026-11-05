import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import 'history_page.dart';
import 'map_page.dart';
import 'survey_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
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
      default:
        return const HistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Dark Slate Blue elegan
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
          // 1. Status Cuaca Makassar Khusus pada Laman Survei
          if (_currentIndex == 1)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_weather?.location ?? "Makassar"}: ${_weather?.tempString ?? "30°C"} ${_weather?.condition ?? "Cerah"}',
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

          // 2. Status Mode Online / Offline Khusus pada Laman Peta
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.shade400, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Mode Online (RBI)',
                        style: TextStyle(
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
        ],
      ),
    );
  }
}
