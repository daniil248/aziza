import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.code});
  final String code;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  t.orderSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 32),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  t.orderSuccessSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _fade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Text(t.orderSuccessCode,
                          style: AppTypography.caption(AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        widget.code,
                        style: AppTypography.display(AppColors.textPrimary)
                            .copyWith(fontSize: 24, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: Text(t.orderSuccessHome),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text(t.orderSuccessTrack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
