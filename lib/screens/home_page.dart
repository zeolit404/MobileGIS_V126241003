import 'package:flutter/material.dart';

import 'history_page.dart';
import 'map_page.dart';
import 'survey_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Dark Slate Blue yang elegan
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mobile GIS Unhas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            // Fitur Ashabul: Tampilkan NIM
            Text(
              'NIM: V126241003 — M. Arief Abdillah',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        // Fitur Ariel: Menu Navigasi Pindah ke Bagian Atas (Top TabBar)
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber, // Aksen kuning emas
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Peta RBI'),
            Tab(icon: Icon(Icons.edit_location_alt_outlined), text: 'Survei'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MapPage(),
          SurveyFormPage(),
          HistoryPage(),
        ],
      ),
    );
  }
}
