import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Displays a star rating with support for partial stars (e.g., 4.5 stars)
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color emptyColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 20,
    this.color = AppTheme.featuredGold,
    this.emptyColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return _buildStar(index);
      }),
    );
  }

  Widget _buildStar(int index) {
    // Calculate how much of this star should be filled
    final double starValue = rating - index;
    
    if (starValue >= 1.0) {
      // Full star
      return Icon(
        Icons.star,
        size: size,
        color: color,
      );
    } else if (starValue > 0.0 && starValue < 1.0) {
      // Partial star
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Empty star background
            Icon(
              Icons.star_border,
              size: size,
              color: emptyColor,
            ),
            // Filled portion
            ClipRect(
              clipper: _StarClipper(fillPercentage: starValue),
              child: Icon(
                Icons.star,
                size: size,
                color: color,
              ),
            ),
          ],
        ),
      );
    } else {
      // Empty star
      return Icon(
        Icons.star_border,
        size: size,
        color: emptyColor,
      );
    }
  }
}

/// Custom clipper to show partial star fill
class _StarClipper extends CustomClipper<Rect> {
  final double fillPercentage;

  _StarClipper({required this.fillPercentage});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      0,
      size.width * fillPercentage,
      size.height,
    );
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}
