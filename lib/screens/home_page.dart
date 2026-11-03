import 'package:flutter/material.dart';

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
