import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

/// A single shimmering placeholder box (one line/block of a skeleton screen).
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.inputBackground,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A card-shaped shimmer: mirrors the app's list-card layout (icon + 2 lines).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Skeleton(width: 38, height: 38, radius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 13),
                SizedBox(height: 8),
                Skeleton(height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical stack of [SkeletonCard]s — drop-in for list loading states.
class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [for (var i = 0; i < itemCount; i++) const SkeletonCard()],
    );
  }
}
