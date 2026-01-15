import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:natdemy/core/theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  static Widget rectangular({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  static Widget circular({
    required double size,
  }) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: size / 2,
      shape: BoxShape.circle,
    );
  }

  static Widget courseCard() {
    return const CourseCardShimmer();
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider.withOpacity(0.5),
      highlightColor: AppColors.divider.withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading.circular(size: 60),
          const SizedBox(height: 12),
          ShimmerLoading.rectangular(width: 80, height: 16),
          const SizedBox(height: 8),
          ShimmerLoading.rectangular(width: 60, height: 12),
        ],
      ),
    );
  }
}

