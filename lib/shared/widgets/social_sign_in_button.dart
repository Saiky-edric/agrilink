import 'package:flutter/material.dart';

enum SocialProvider {
  google,
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
    return Colors.white;
  }

  Color _getTextColor() {
    return const Color(0xFF1F1F1F);
  }

  BorderSide _getBorderSide() {
    return BorderSide(color: Colors.grey.shade300, width: 1);
  }

  Widget _getIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(
        'assets/images/logos/google_logo.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getText() {
    return 'Continue with Google';
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

