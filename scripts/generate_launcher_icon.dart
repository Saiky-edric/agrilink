import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:agrlink1/shared/widgets/tractor_icon_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚜 Generating Agrilink Tractor Launcher Icons...');
  
  // Generate icons in different sizes
  final iconSizes = [1024, 512, 192, 144, 96, 72, 48];
  
  for (final size in iconSizes) {
    await generateTractorIcon(size);
  }
  
  print('✅ All launcher icons generated successfully!');
  print('📁 Icons saved to: assets/icons/');
  print('🔧 Run: flutter pub get && flutter pub run flutter_launcher_icons');
}

Future<void> generateTractorIcon(int size) async {
  try {
    // Create a custom paint widget
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Create the tractor icon painter
    final painter = TractorIconPainter(
      backgroundColor: Color(0xFF2E7D32), // Agrilink green
      tractorColor: Color(0xFF4CAF50),   // Green tractor to match splash
    );
    
    // Paint the icon
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    
    // Save to file
    final file = File('assets/icons/app_icon_${size}x$size.png');
    await file.writeAsBytes(uint8List);
    
    // Also save main icon
    if (size == 1024) {
      final mainFile = File('assets/icons/app_icon.png');
      await mainFile.writeAsBytes(uint8List);
    }
    
    print('✅ Generated ${size}x$size icon');
    
  } catch (e) {
    print('❌ Error generating ${size}x$size icon: $e');
  }
}