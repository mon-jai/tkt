import 'package:flutter/material.dart';

class CampusMapScreen extends StatelessWidget {
  const CampusMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('校園地圖'),
      ),
      body: InteractiveViewer(
        maxScale: 6.0,
        minScale: 0.8,
        child: Center(
          child: Image.asset(
            'assets/images/map.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 