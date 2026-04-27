import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          _Tile(
            icon: LucideIcons.crown,
            label: t.profileSubscription,
            onTap: () => context.push('/subscription'),
            badge: 'Premium',
          ),
          _Tile(icon: LucideIcons.mapPin, label: t.profileAddresses, onTap: () {}),
          _Tile(icon: LucideIcons.receipt, label: t.profileOrders, onTap: () {}),
          _Tile(
            icon: LucideIcons.languages,
            label: t.profileLanguage,
            trailing: Text(_localeName(locale.languageCode, t), style: AppTypography.caption(AppColors.textSecondary)),
            onTap: () => _showLangPicker(context, ref),
          ),
          _Tile(icon: LucideIcons.lifeBuoy, label: t.profileSupport, onTap: () {}),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: Text(t.profileLogout),
          ),
        ],
      ),
    );
  }

  String _localeName(String code, AppL10n t) {
    return switch (code) {
      'kk' => t.languageKk,
      'en' => t.languageEn,
      _ => t.languageRu,
    };
  }

  void _showLangPicker(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) {
        Widget tile(String code, String label) {
          final selected = ref.read(localeProvider).languageCode == code;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? const Icon(LucideIcons.check, color: AppColors.gold)
                : null,
            onTap: () {
              ref.read(localeProvider.notifier).set(Locale(code));
              Navigator.of(sheetCtx).pop();
            },
          );
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              tile('ru', t.languageRu),
              tile('kk', t.languageKk),
              tile('en', t.languageEn),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: context.body)),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.caption(Colors.white)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (trailing != null) trailing! else
                  const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ).withMargin(const EdgeInsets.only(bottom: AppSpacing.sm));
}

extension _MarginExt on Widget {
  Widget withMargin(EdgeInsets margin) => Padding(padding: margin, child: this);
}
