import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/order_status.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';
import '../../../core/session/session.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final locale = ref.watch(localeProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          if (session.isLoggedIn) ...[
            _UserHeader(name: session.user?.name, phone: session.user?.phone),
            const SizedBox(height: AppSpacing.lg),
          ],
          _Tile(
            icon: LucideIcons.crown,
            label: t.profileSubscription,
            onTap: () => context.push('/subscription'),
            badge: 'Premium',
          ),
          if (session.isLoggedIn) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Мои заказы',
                style: AppTypography.subtitle(AppColors.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.md),
            const _OrdersList(),
            const SizedBox(height: AppSpacing.xl),
            Text(t.profileAddresses,
                style: AppTypography.subtitle(AppColors.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.md),
            const _AddressesList(),
            const SizedBox(height: AppSpacing.xl),
          ],
          _Tile(
            icon: LucideIcons.languages,
            label: t.profileLanguage,
            trailing: Text(_localeName(locale.languageCode, t),
                style: AppTypography.caption(AppColors.textSecondary)),
            onTap: () => _showLangPicker(context, ref),
          ),
          _Tile(icon: LucideIcons.lifeBuoy, label: t.profileSupport, onTap: () {}),
          const SizedBox(height: AppSpacing.xl),
          if (session.isLoggedIn)
            OutlinedButton.icon(
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(t.profileLogout),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(LucideIcons.logIn, size: 18, color: Colors.white),
                label: const Text('Войти'),
              ),
            ),
        ],
      ),
    );
  }

  String _localeName(String code, AppL10n t) => switch (code) {
        'kk' => t.languageKk,
        'en' => t.languageEn,
        _ => t.languageRu,
      };

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
            trailing:
                selected ? const Icon(LucideIcons.check, color: AppColors.gold) : null,
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

class _UserHeader extends StatelessWidget {
  const _UserHeader({this.name, this.phone});
  final String? name;
  final String? phone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.goldSoft,
              child: Icon(LucideIcons.user, color: AppColors.goldPressed),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((name == null || name!.isEmpty) ? 'Гость' : name!,
                      style: AppTypography.subtitle(AppColors.textPrimary)),
                  if (phone != null && phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('+$phone',
                        style: AppTypography.caption(AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return orders.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Не удалось загрузить заказы: $e',
          style: AppTypography.caption(AppColors.textSecondary)),
      data: (list) {
        if (list.isEmpty) {
          return Text('Заказов пока нет',
              style: AppTypography.body(AppColors.textSecondary));
        }
        return Column(
          children: [
            for (final o in list.take(10))
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('№ ${o.code}',
                              style: AppTypography.bodyMedium(AppColors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          _StatusChip(status: o.status),
                        ],
                      ),
                    ),
                    Text(o.total.toString(),
                        style: AppTypography.bodyMedium(AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddressesList extends ConsumerWidget {
  const _AddressesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(myAddressesProvider);
    return addresses.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Не удалось загрузить адреса',
          style: AppTypography.caption(AppColors.textSecondary)),
      data: (list) {
        if (list.isEmpty) {
          return Text('Сохранённых адресов нет',
              style: AppTypography.body(AppColors.textSecondary));
        }
        return Column(
          children: [
            for (final a in list)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(a.oneLine,
                          style: AppTypography.body(AppColors.textPrimary)),
                    ),
                    if (a.isDefault)
                      const Icon(LucideIcons.star, size: 16, color: AppColors.gold),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = orderStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(info.label,
          style: AppTypography.caption(info.color).copyWith(fontWeight: FontWeight.w700)),
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
                horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
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
                    child: Text(badge!,
                        style: AppTypography.caption(Colors.white)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (trailing != null)
                  trailing!
                else
                  const Icon(LucideIcons.chevronRight,
                      size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ).withMargin(const EdgeInsets.only(bottom: AppSpacing.sm));
}

extension _MarginExt on Widget {
  Widget withMargin(EdgeInsets margin) => Padding(padding: margin, child: this);
}
