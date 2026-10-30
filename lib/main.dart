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
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
