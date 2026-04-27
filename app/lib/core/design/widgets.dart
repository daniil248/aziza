import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Generic centered loading indicator using brand color.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      );
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: context.bodyMuted, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
              ],
            ],
          ),
        ),
      );
}

/// Pill-style category chip used in catalog and home filters.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.base,
          curve: AppDuration.cubicEmphasized,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTypography.caption(
              selected ? AppColors.surface : AppColors.textPrimary,
            ).copyWith(fontSize: 14),
          ),
        ),
      );
}

/// Premium gold badge ("Premium Member").
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption(Colors.white).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
