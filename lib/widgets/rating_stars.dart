import 'package:flutter/material.dart';

/// Widget that displays a rating with stars
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.starSize = 20,
    this.showValue = true,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  final double rating;
  final double starSize;
  final bool showValue;
  final TextStyle? textStyle;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final halfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < fullStars
                ? Icons.star
                : (i == fullStars && halfStar ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
            size: starSize,
          ),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: textStyle ??
                const TextStyle(
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}









