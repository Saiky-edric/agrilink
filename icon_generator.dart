import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'lib/shared/widgets/tractor_icon_painter.dart';

void main() {
  runApp(IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IconGenerator(),
    );
  }
}

class IconGenerator extends StatefulWidget {
  const IconGenerator({super.key});

  @override
  _IconGeneratorState createState() => _IconGeneratorState();
}

class _IconGeneratorState extends State<IconGenerator> {
  final GlobalKey _iconKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    // Generate icon after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateIcon();
    });
  }

  Future<void> _generateIcon() async {
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary boundary = 
          _iconKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      
      // Convert to byte data
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save to file
      final file = File('assets/icons/app_icon.png');
      await file.writeAsBytes(pngBytes);
      
      print('✅ Tractor launcher icon generated successfully!');
      print('📁 Saved to: assets/icons/app_icon.png');
      
    } catch (e) {
      print('❌ Error generating icon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Generating Agrilink Tractor Icon...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            RepaintBoundary(
              key: _iconKey,
              child: SizedBox(
                width: 1024,
                height: 1024,
                child: CustomPaint(
                  painter: TractorIconPainter(
                    backgroundColor: Color(0xFF2E7D32), // Agrilink green
                    tractorColor: Color(0xFFD32F2F),   // Red tractor
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Check console for generation status',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}