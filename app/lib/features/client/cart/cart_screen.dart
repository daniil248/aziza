import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/cart/cart.dart';
import '../../../core/design/product_image.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return _Empty(t: t);

    final locale = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.cartTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        children: [
          for (final item in cart.items) ...[
            _LineItem(item: item, locale: locale),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
          _PromoInput(state: cart),
          const SizedBox(height: AppSpacing.xl),
          _Totals(state: cart, t: t),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: () => context.push('/checkout'),
            child: Text('${t.cartCheckout} · ${cart.total}'),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.t});
  final AppL10n t;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t.cartTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(LucideIcons.shoppingBag,
                      size: 36, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.cartEmpty, style: context.title.copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 240,
                  child: ElevatedButton(
                    onPressed: () => context.go('/catalog'),
                    child: Text(t.cartGoShopping),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LineItem extends ConsumerWidget {
  const _LineItem({required this.item, required this.locale});

  final CartItem item;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ProductImage(
              imageUrl: item.imageUrl,
              categorySlug: item.categorySlug,
              borderRadius: AppRadius.sm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name(locale),
                  style: AppTypography.bodyMedium(AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.variantName(locale),
                  style: AppTypography.caption(AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  item.total.toString(),
                  style: AppTypography.bodyMedium(AppColors.gold)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          QtyStepper(
            value: item.qty,
            onChanged: (v) => ref.read(cartProvider.notifier).setQty(item.key, v),
          ),
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              icon: value <= 1 ? LucideIcons.trash2 : LucideIcons.minus,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 28,
              child: Center(
                child: Text(
                  '$value',
                  style: AppTypography.bodyMedium(AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _Btn(icon: LucideIcons.plus, onTap: () => onChanged(value + 1)),
          ],
        ),
      );
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
        ),
      );
}

class _PromoInput extends ConsumerStatefulWidget {
  const _PromoInput({required this.state});
  final CartState state;

  @override
  ConsumerState<_PromoInput> createState() => _PromoInputState();
}

class _PromoInputState extends ConsumerState<_PromoInput> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.state.promo;
    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.ticket, size: 18, color: AppColors.goldPressed),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                applied.code,
                style: AppTypography.bodyMedium(AppColors.goldPressed)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearPromo();
                _ctrl.clear();
              },
              child: Text(AppL10n.of(context).promoRemove),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: AppL10n.of(context).cartPromoHint,
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Icon(LucideIcons.ticket, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: TextButton(
              onPressed: () {
                final err = ref.read(cartProvider.notifier).applyPromo(_ctrl.text);
                setState(() => _error = err);
              },
              child: Text(AppL10n.of(context).promoApply),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error == 'unknown'
                ? AppL10n.of(context).promoUnknown
                : AppL10n.of(context).promoMinOrder,
            style: AppTypography.caption(AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.state, required this.t});
  final CartState state;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(color ?? AppColors.textSecondary)
                      .copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
                ),
              ),
              Text(
                value,
                style: AppTypography.body(color ?? AppColors.textPrimary)
                    .copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          row(t.cartSubtotal, state.subtotal.toString()),
          row(t.cartDelivery,
              state.deliveryFee.isZero ? t.deliveryFree : state.deliveryFee.toString(),
              color: state.deliveryFee.isZero ? AppColors.success : null),
          if (!state.discount.isZero)
            row(t.cartDiscount, '−${state.discount}', color: AppColors.success),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          row(t.cartTotal, state.total.toString(), bold: true),
        ],
      ),
    );
  }
}
