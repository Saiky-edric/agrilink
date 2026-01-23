import 'package:flutter/material.dart';
import 'dart:math' as math;

class TractorIconPainter extends CustomPainter {
  final Color backgroundColor;
  final Color tractorColor;
  
  const TractorIconPainter({
    this.backgroundColor = const Color(0xFF2E7D32), // Agrilink green
    this.tractorColor = const Color(0xFF4CAF50), // Green tractor to match splash
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);
    final iconSize = size.width * 0.8;
    
    // Draw background circle
    paint.color = backgroundColor;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width / 2, paint);
    
    // Draw border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.02;
    canvas.drawCircle(center, size.width / 2 - paint.strokeWidth / 2, paint);
    
    // Calculate tractor dimensions
    final tractorWidth = iconSize * 0.7;
    final tractorHeight = iconSize * 0.45;
    final tractorX = center.dx - tractorWidth / 2;
    final tractorY = center.dy - tractorHeight / 2;
    
    // Draw tractor
    _drawTractorIcon(canvas, Offset(tractorX, tractorY), tractorWidth, tractorHeight, paint);
  }
  
  void _drawTractorIcon(Canvas canvas, Offset position, double width, double height, Paint paint) {
    // Main tractor body
    paint.style = PaintingStyle.fill;
    paint.color = tractorColor;
    
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx,
        position.dy + height * 0.2,
        width * 0.65,
        height * 0.5,
      ),
      Radius.circular(width * 0.06),
    );
    canvas.drawRRect(bodyRect, paint);
    
    // Tractor cab (at back)
    paint.color = Color.lerp(tractorColor, Colors.black, 0.2)!;
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx + width * 0.05,
        position.dy + height * 0.05,
        width * 0.25,
        height * 0.4,
      ),
      Radius.circular(width * 0.04),
    );
    canvas.drawRRect(cabRect, paint);
    
    // Tractor window
    paint.color = Colors.lightBlue.shade100;
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx + width * 0.08,
        position.dy + height * 0.12,
        width * 0.15,
        height * 0.2,
      ),
      Radius.circular(width * 0.02),
    );
    canvas.drawRRect(windowRect, paint);
    
    // Engine grille (front)
    paint.color = Colors.grey.shade700;
    final grilleRect = Rect.fromLTWH(
      position.dx + width * 0.55,
      position.dy + height * 0.25,
      width * 0.08,
      height * 0.25,
    );
    canvas.drawRect(grilleRect, paint);
    
    // Front wheel (smaller)
    _drawWheelIcon(
      canvas,
      Offset(position.dx + width * 0.6, position.dy + height * 0.75),
      width * 0.12,
      paint,
    );
    
    // Rear wheel (larger)
    _drawWheelIcon(
      canvas,
      Offset(position.dx + width * 0.15, position.dy + height * 0.78),
      width * 0.16,
      paint,
    );
    
    // Headlight
    paint.color = Colors.yellow.shade600;
    canvas.drawCircle(
      Offset(position.dx + width * 0.63, position.dy + height * 0.3),
      width * 0.025,
      paint,
    );
    
    // Exhaust pipe (small)
    paint.color = Colors.grey.shade600;
    canvas.drawCircle(
      Offset(position.dx - width * 0.02, position.dy + height * 0.15),
      width * 0.02,
      paint,
    );
  }
  
  void _drawWheelIcon(Canvas canvas, Offset center, double radius, Paint paint) {
    // Tire (black)
    paint.style = PaintingStyle.fill;
    paint.color = Colors.grey.shade800;
    canvas.drawCircle(center, radius, paint);
    
    // Rim (metallic)
    paint.color = Colors.grey.shade400;
    canvas.drawCircle(center, radius * 0.7, paint);
    
    // Spokes
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = radius * 0.1;
    paint.color = Colors.grey.shade600;
    
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final spokeStart = Offset(
        center.dx + math.cos(angle) * radius * 0.3,
        center.dy + math.sin(angle) * radius * 0.3,
      );
      final spokeEnd = Offset(
        center.dx + math.cos(angle) * radius * 0.6,
        center.dy + math.sin(angle) * radius * 0.6,
      );
      
      canvas.drawLine(spokeStart, spokeEnd, paint);
    }
    
    // Center hub
    paint.style = PaintingStyle.fill;
    paint.color = Colors.grey.shade300;
    canvas.drawCircle(center, radius * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Widget wrapper for the tractor icon
class TractorIcon extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color tractorColor;
  
  const TractorIcon({
    super.key,
    this.size = 48,
    this.backgroundColor = Colors.green,
    this.tractorColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TractorIconPainter(
          backgroundColor: backgroundColor,
          tractorColor: tractorColor,
        ),
      ),
    );
  }
}