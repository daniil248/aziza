import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'tokens.dart';

const _baseColor = Color(0xFFEDEDED);
const _highlightColor = Color(0xFFF8F8F8);

/// Generic shimmer wrapper used by all skeletons.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: _baseColor,
        highlightColor: _highlightColor,
        period: const Duration(milliseconds: 1300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _SkeletonBox(
                width: double.infinity,
                height: 0,
                radius: AppRadius.md,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            const _SkeletonBox(width: 80, height: 12),
          ],
        ),
      );
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.78,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
}

class HeroCarouselSkeleton extends StatelessWidget {
  const HeroCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: _baseColor,
        highlightColor: _highlightColor,
        period: const Duration(milliseconds: 1300),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
          itemBuilder: (_, __) => const _SkeletonBox(
            width: 220,
            height: 200,
            radius: AppRadius.lg,
          ),
        ),
      );
}

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: _baseColor,
        highlightColor: _highlightColor,
        period: const Duration(milliseconds: 1300),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                width: double.infinity,
                height: 280,
                radius: AppRadius.lg,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SkeletonBox(width: 240, height: 28),
              const SizedBox(height: AppSpacing.sm),
              const _SkeletonBox(width: double.infinity, height: 14),
              const SizedBox(height: 6),
              const _SkeletonBox(width: double.infinity, height: 14),
              const SizedBox(height: 6),
              const _SkeletonBox(width: 200, height: 14),
            ],
          ),
        ),
      );
}
