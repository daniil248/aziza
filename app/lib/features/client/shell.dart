import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/cart/cart.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/i18n/generated/app_localizations.dart';

class ClientShell extends ConsumerWidget {
  const ClientShell({super.key, required this.child});

  final Widget child;

  static const _routes = ['/', '/catalog', '/cart', '/profile'];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/profile')) return 3;
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/catalog')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final idx = _currentIndex(context);
    final cartCount = ref.watch(cartItemCountProvider);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_routes[i]),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.goldSoft,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house, size: 22, color: AppColors.textPrimary),
            selectedIcon: const Icon(LucideIcons.house, size: 22, color: AppColors.gold),
            label: t.navHome,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.layoutGrid, size: 22, color: AppColors.textPrimary),
            selectedIcon:
                const Icon(LucideIcons.layoutGrid, size: 22, color: AppColors.gold),
            label: t.navCatalog,
          ),
          NavigationDestination(
            icon: _CartIcon(count: cartCount, color: AppColors.textPrimary),
            selectedIcon: _CartIcon(count: cartCount, color: AppColors.gold),
            label: t.navCart,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.userRound, size: 22, color: AppColors.textPrimary),
            selectedIcon: const Icon(LucideIcons.userRound, size: 22, color: AppColors.gold),
            label: t.navProfile,
          ),
        ],
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(LucideIcons.shoppingBag, size: 22, color: color);
    if (count <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: AppTypography.caption(Colors.white).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
