import 'package:flutter/material.dart';
import 'dart:math' as math;

class TractorLoadingAnimation extends StatefulWidget {
  final double width;
  final double height;
  
  const TractorLoadingAnimation({
    super.key,
    this.width = 200,
    this.height = 100,
  });

  @override
  State<TractorLoadingAnimation> createState() => _TractorLoadingAnimationState();
}

class _TractorLoadingAnimationState extends State<TractorLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _tractorController;
  late AnimationController _wheelController;
  late AnimationController _dustController;
  
  late Animation<double> _tractorPosition;
  late Animation<double> _wheelRotation;
  late Animation<double> _dustOpacity;

  @override
  void initState() {
    super.initState();
    
    // Tractor movement animation (8 seconds to match splash screen)
    _tractorController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Wheel rotation animation (should complete multiple rotations during 8 seconds)
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Dust particle animation (varies throughout the 8 seconds)
    _dustController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Setup animations
    _tractorPosition = Tween<double>(
      begin: -120,
      end: widget.width + 120,
    ).animate(CurvedAnimation(
      parent: _tractorController,
      curve: Curves.easeInOut, // Smooth start and end
    ));
    
    _wheelRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.linear,
    ));
    
    _dustOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dustController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    // Start tractor movement (single 8-second journey)
    _tractorController.forward();
    
    // Start continuous wheel rotation
    _wheelController.repeat();
    
    // Start dust particle effects
    _dustController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tractorController.dispose();
    _wheelController.dispose();
    _dustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _tractorController,
          _wheelController,
          _dustController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: TractorAnimationPainter(
              tractorPosition: _tractorPosition.value,
              wheelRotation: _wheelRotation.value,
              dustOpacity: _dustOpacity.value,
            ),
          );
        },
      ),
    );
  }
}

class TractorAnimationPainter extends CustomPainter {
  final double tractorPosition;
  final double wheelRotation;
  final double dustOpacity;

  TractorAnimationPainter({
    required this.tractorPosition,
    required this.wheelRotation,
    required this.dustOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    
    // Draw dust particles first (behind tractor)
    _drawDustParticles(canvas, size, paint);
    
    // Draw ground line
    _drawGround(canvas, size, paint);
    
    // Draw tractor
    _drawTractor(canvas, size, paint);
  }

  void _drawDustParticles(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.brown.withOpacity(dustOpacity * 0.3);
    
    // Create multiple dust particles behind the tractor
    for (int i = 0; i < 8; i++) {
      final particleX = tractorPosition - 20 - (i * 8);
      final particleY = size.height * 0.8 + (math.sin(wheelRotation + i) * 3);
      final particleSize = 2.0 + (i % 3);
      
      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        paint,
      );
    }
  }

  void _drawGround(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.brown.shade300;
    paint.strokeWidth = 2;
    
    canvas.drawLine(
      Offset(0, size.height * 0.85),
      Offset(size.width, size.height * 0.85),
      paint,
    );
  }

  void _drawTractor(Canvas canvas, Size size, Paint paint) {
    final tractorWidth = 80.0;
    final tractorHeight = 50.0;
    final tractorY = size.height * 0.5;
    
    // Main tractor body (engine at front)
    paint.style = PaintingStyle.fill;
    paint.color = Colors.red.shade700;
    
    final tractorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        tractorPosition,
        tractorY,
        tractorWidth * 0.7,
        tractorHeight * 0.6,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(tractorRect, paint);
    
    // Tractor cab (at the back/left side)
    paint.color = Colors.red.shade800;
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        tractorPosition + tractorWidth * 0.05, // Cab at back
        tractorY - tractorHeight * 0.2,
        tractorWidth * 0.3,
        tractorHeight * 0.5,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(cabRect, paint);
    
    // Tractor windows (facing right)
    paint.color = Colors.lightBlue.shade200;
    final windowRect = Rect.fromLTWH(
      tractorPosition + tractorWidth * 0.1, // Window in cab
      tractorY - tractorHeight * 0.15,
      tractorWidth * 0.2,
      tractorHeight * 0.25,
    );
    canvas.drawRect(windowRect, paint);
    
    // Engine grille (front of tractor)
    paint.color = Colors.grey.shade800;
    final grilleRect = Rect.fromLTWH(
      tractorPosition + tractorWidth * 0.6,
      tractorY + tractorHeight * 0.1,
      tractorWidth * 0.1,
      tractorHeight * 0.4,
    );
    canvas.drawRect(grilleRect, paint);
    
    // Draw wheels (front wheel smaller, rear wheel larger)
    _drawWheel(
      canvas,
      Offset(tractorPosition + tractorWidth * 0.7, tractorY + tractorHeight * 0.7), // Front wheel (smaller)
      12,
      paint,
    );
    
    _drawWheel(
      canvas,
      Offset(tractorPosition + tractorWidth * 0.1, tractorY + tractorHeight * 0.7), // Rear wheel (larger)
      18,
      paint,
    );
    
    // Exhaust pipe (at the back)
    paint.color = Colors.grey.shade700;
    canvas.drawCircle(
      Offset(tractorPosition - 5, tractorY - tractorHeight * 0.1), // Behind tractor
      3,
      paint,
    );
    
    // Exhaust smoke (trailing behind)
    paint.color = Colors.grey.withOpacity(dustOpacity * 0.4);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          tractorPosition - 10 - (i * 8), // Smoke trails behind
          tractorY - tractorHeight * 0.1 - (i * 6),
        ),
        2.0 + i,
        paint,
      );
    }
    
    // Front headlights
    paint.color = Colors.yellow.shade300;
    canvas.drawCircle(
      Offset(tractorPosition + tractorWidth * 0.72, tractorY + tractorHeight * 0.2),
      2,
      paint,
    );
  }

  void _drawWheel(Canvas canvas, Offset center, double radius, Paint paint) {
    // Wheel tire (black)
    paint.style = PaintingStyle.fill;
    paint.color = Colors.grey.shade800;
    canvas.drawCircle(center, radius, paint);
    
    // Wheel rim (metallic)
    paint.color = Colors.grey.shade400;
    canvas.drawCircle(center, radius * 0.7, paint);
    
    // Wheel spokes (rotating)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = Colors.grey.shade600;
    
    for (int i = 0; i < 6; i++) {
      final angle = wheelRotation + (i * math.pi / 3);
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
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant TractorAnimationPainter oldDelegate) {
    return oldDelegate.tractorPosition != tractorPosition ||
           oldDelegate.wheelRotation != wheelRotation ||
           oldDelegate.dustOpacity != dustOpacity;
  }
}