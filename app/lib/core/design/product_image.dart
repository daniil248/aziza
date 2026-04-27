import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tokens.dart';

/// Aesthetic product placeholder until real photography arrives.
/// Renders soft gradient based on category slug + outline icon.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    required this.categorySlug,
    this.borderRadius = AppRadius.lg,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String categorySlug;
  final double borderRadius;
  final BoxFit fit;

  static (Color, Color, IconData) _styleFor(String slug) {
    switch (slug) {
      case 'manty':
        return (const Color(0xFFF6E9C9), const Color(0xFFEBC97A), LucideIcons.utensils);
      case 'pelmeni':
        return (const Color(0xFFEFE7DA), const Color(0xFFD9C6A8), LucideIcons.cookingPot);
      case 'samsa':
        return (const Color(0xFFF3DCB6), const Color(0xFFD7A766), LucideIcons.croissant);
      case 'sauces':
        return (const Color(0xFFEFE6D8), const Color(0xFFCBB089), LucideIcons.droplet);
      default:
        return (AppColors.surfaceMuted, const Color(0xFFE3DFD5), LucideIcons.utensils);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: fit,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final (c1, c2, icon) = _styleFor(categorySlug);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2],
          ),
        ),
        child: Center(
          child: Icon(icon, size: 48, color: AppColors.textPrimary.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
