import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';

enum _Plan { monthly, yearly }

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  _Plan _plan = _Plan.monthly;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Theme(
      data: buildPremiumTheme(),
      child: Scaffold(
        backgroundColor: AppColors.premiumBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          backgroundColor: AppColors.premiumBg,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(LucideIcons.crown, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  t.subscriptionTitle,
                  style: AppTypography.display(Colors.white).copyWith(fontSize: 36),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.subscriptionTagline,
                  style: AppTypography.body(Colors.white70),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _Benefit(label: t.subscriptionBenefit1),
                _Benefit(label: t.subscriptionBenefit2),
                _Benefit(label: t.subscriptionBenefit3),
                const Spacer(),
                _PlanToggle(
                  selected: _plan,
                  onChanged: (p) => setState(() => _plan = p),
                  monthly: t.subscriptionMonthly,
                  yearly: t.subscriptionYearly,
                  saveLabel: t.subscriptionSave(17),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      '${t.subscriptionSubscribe} · ${_plan == _Plan.monthly ? t.subscriptionPriceMonthly : t.subscriptionPriceYearly}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            const Icon(LucideIcons.check, color: AppColors.gold, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTypography.body(Colors.white)),
            ),
          ],
        ),
      );
}

class _PlanToggle extends StatelessWidget {
  const _PlanToggle({
    required this.selected,
    required this.onChanged,
    required this.monthly,
    required this.yearly,
    required this.saveLabel,
  });

  final _Plan selected;
  final ValueChanged<_Plan> onChanged;
  final String monthly;
  final String yearly;
  final String saveLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.premiumSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                label: monthly,
                selected: selected == _Plan.monthly,
                onTap: () => onChanged(_Plan.monthly),
              ),
            ),
            Expanded(
              child: _Tab(
                label: yearly,
                badge: saveLabel,
                selected: selected == _Plan.yearly,
                onTap: () => onChanged(_Plan.yearly),
              ),
            ),
          ],
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.base,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium(
                  selected ? Colors.white : Colors.white70,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.caption(
                      selected ? AppColors.gold : Colors.white,
                    ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
