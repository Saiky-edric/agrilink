import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum SocialProvider {
  google,
  facebook,
}

class SocialSignInButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _getBorderSide(),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getIcon(),
                  const SizedBox(width: 12),
                  Text(
                    _getText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (provider) {
      case SocialProvider.google:
        return Colors.white;
      case SocialProvider.facebook:
        return const Color(0xFF1877F2);
    }
  }

  Color _getTextColor() {
    switch (provider) {
      case SocialProvider.google:
        return const Color(0xFF1F1F1F);
      case SocialProvider.facebook:
        return Colors.white;
    }
  }

  BorderSide _getBorderSide() {
    switch (provider) {
      case SocialProvider.google:
        return BorderSide(color: Colors.grey.shade300, width: 1);
      case SocialProvider.facebook:
        return BorderSide.none;
    }
  }

  Widget _getIcon() {
    switch (provider) {
      case SocialProvider.google:
        return SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: GoogleLogoPainter(),
            size: const Size(24, 24),
          ),
        );
      case SocialProvider.facebook:
        return SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: FacebookLogoPainter(),
            size: const Size(24, 24),
          ),
        );
    }
  }

  String _getText() {
    switch (provider) {
      case SocialProvider.google:
        return 'Continue with Google';
      case SocialProvider.facebook:
        return 'Continue with Facebook';
    }
  }
}

// Accurate Google Logo Painter - Based on official Google brand guidelines
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    
    // Official Google Colors
    const blueColor = Color(0xFF4285F4);  // Google Blue
    const redColor = Color(0xFFEA4335);   // Google Red
    const yellowColor = Color(0xFFFBBC05); // Google Yellow
    const greenColor = Color(0xFF34A853); // Google Green
    
    // Draw the G shape using precise paths
    final path = Path();
    
    // Main circle outline
    paint.color = blueColor;
    canvas.drawCircle(center, radius, paint);
    
    // Create the "G" cutout
    paint.color = Colors.white;
    
    // Inner circle (creates the hollow center)
    canvas.drawCircle(center, radius * 0.55, paint);
    
    // Right side opening (creates the G opening)
    final cutoutRect = Rect.fromLTWH(
      center.dx,
      center.dy - radius * 0.25,
      radius,
      radius * 0.5,
    );
    canvas.drawRect(cutoutRect, paint);
    
    // Horizontal bar of the G
    paint.color = blueColor;
    final barRect = Rect.fromLTWH(
      center.dx + radius * 0.2,
      center.dy - radius * 0.1,
      radius * 0.6,
      radius * 0.2,
    );
    canvas.drawRect(barRect, paint);
    
    // Color segments using clip paths
    canvas.save();
    
    // Red section (top-left quarter)
    final redPath = Path();
    redPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159, // 180 degrees
      1.5708,   // 90 degrees
    );
    canvas.clipPath(redPath);
    paint.color = redColor;
    canvas.drawCircle(center, radius, paint);
    
    canvas.restore();
    canvas.save();
    
    // Yellow section (bottom-left quarter)
    final yellowPath = Path();
    yellowPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // 270 degrees
      1.5708,  // 90 degrees
    );
    canvas.clipPath(yellowPath);
    paint.color = yellowColor;
    canvas.drawCircle(center, radius, paint);
    
    canvas.restore();
    canvas.save();
    
    // Green section (bottom-right quarter)
    final greenPath = Path();
    greenPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0,       // 0 degrees
      1.5708,  // 90 degrees
    );
    canvas.clipPath(greenPath);
    paint.color = greenColor;
    canvas.drawCircle(center, radius, paint);
    
    canvas.restore();
    
    // Blue section is already the base, so no additional clipping needed
    
    // Redraw the inner elements to ensure they're on top
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);
    
    // Right opening
    canvas.drawRect(cutoutRect, paint);
    
    // Blue horizontal bar
    paint.color = blueColor;
    canvas.drawRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Accurate Facebook Logo Painter - Based on official Facebook brand guidelines
class FacebookLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white
      ..isAntiAlias = true;
    
    final width = size.width;
    final height = size.height;
    
    // Create precise Facebook 'f' logo path
    final path = Path();
    
    // Start from top of vertical line
    path.moveTo(width * 0.45, height * 0.15);
    
    // Top horizontal line (header of 'f')
    path.lineTo(width * 0.75, height * 0.15);
    path.lineTo(width * 0.75, height * 0.30);
    path.lineTo(width * 0.58, height * 0.30);
    
    // Middle horizontal line (crossbar of 'f')
    path.lineTo(width * 0.58, height * 0.42);
    path.lineTo(width * 0.70, height * 0.42);
    path.lineTo(width * 0.70, height * 0.52);
    path.lineTo(width * 0.58, height * 0.52);
    
    // Bottom part of vertical line
    path.lineTo(width * 0.58, height * 0.85);
    path.lineTo(width * 0.45, height * 0.85);
    path.lineTo(width * 0.45, height * 0.52);
    
    // Connection back to start (left side)
    path.lineTo(width * 0.35, height * 0.52);
    path.lineTo(width * 0.35, height * 0.42);
    path.lineTo(width * 0.45, height * 0.42);
    
    // Complete the path
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Optional: Add some refinement to make it look more like the official logo
    // Top serif (small line at the top)
    final topSerif = Path();
    topSerif.moveTo(width * 0.45, height * 0.15);
    topSerif.lineTo(width * 0.48, height * 0.12);
    topSerif.lineTo(width * 0.75, height * 0.12);
    topSerif.lineTo(width * 0.75, height * 0.18);
    topSerif.lineTo(width * 0.48, height * 0.18);
    topSerif.close();
    
    // Draw the refined top
    paint.style = PaintingStyle.fill;
    canvas.drawPath(topSerif, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}