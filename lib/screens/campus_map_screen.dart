import 'package:flutter/material.dart';

class CampusMapScreen extends StatelessWidget {
  const CampusMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('校園地圖'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          final targetWidth = (constraints.maxWidth * devicePixelRatio).round();
          final imageProvider = ResizeImage(const AssetImage('assets/images/map.jpg'), width: targetWidth);

          return InteractiveViewer(
            maxScale: 6.0,
            minScale: 0.8,
            child: Center(
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
} 