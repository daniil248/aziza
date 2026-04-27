import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/cart/cart.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/money/money.dart';

enum _Time { asap, scheduled }

enum _Pay { cash, card, kaspi }

class _DemoAddress {
  const _DemoAddress(this.label, this.line, this.icon);
  final String label;
  final String line;
  final IconData icon;
}

const _addresses = <_DemoAddress>[
  _DemoAddress('Дом', 'Абая 150, кв. 12, 5 эт.', LucideIcons.house),
  _DemoAddress('Работа', 'Жибек жолы 87, оф. 504', LucideIcons.briefcase),
];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _addressIdx = 0;
  _Time _time = _Time.asap;
  _Pay _pay = _Pay.card;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.checkoutTitle),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          _SectionLabel(text: t.checkoutAddress),
          ..._addresses.asMap().entries.map(
                (e) => _AddressTile(
                  addr: e.value,
                  selected: _addressIdx == e.key,
                  onTap: () => setState(() => _addressIdx = e.key),
                ),
              ),
          _AddNewAddress(label: t.checkoutAddNewAddress),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(text: t.checkoutTime),
          _TwoToggle(
            left: t.checkoutTimeAsap,
            right: t.checkoutTimeScheduled,
            isLeft: _time == _Time.asap,
            onChanged: (v) => setState(() => _time = v ? _Time.asap : _Time.scheduled),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(text: t.checkoutPayment),
          _PayTile(
            icon: LucideIcons.creditCard,
            label: t.checkoutPaymentCard,
            selected: _pay == _Pay.card,
            onTap: () => setState(() => _pay = _Pay.card),
          ),
          _PayTile(
            icon: LucideIcons.smartphone,
            label: t.checkoutPaymentKaspi,
            selected: _pay == _Pay.kaspi,
            onTap: () => setState(() => _pay = _Pay.kaspi),
          ),
          _PayTile(
            icon: LucideIcons.banknote,
            label: t.checkoutPaymentCash,
            selected: _pay == _Pay.cash,
            onTap: () => setState(() => _pay = _Pay.cash),
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: t.checkoutCommentHint,
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(LucideIcons.messageSquare, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _Summary(state: cart, t: t),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: cart.isEmpty
                ? null
                : () {
                    final code = _generateCode();
                    ref.read(cartProvider.notifier).clear();
                    if (mounted) context.go('/order-success?code=$code');
                  },
            child: Text('${t.checkoutPlaceOrder} · ${cart.total}'),
          ),
        ),
      ),
    );
  }
}

String _generateCode() {
  final rand = Random();
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  final l = '${letters[rand.nextInt(letters.length)]}${letters[rand.nextInt(letters.length)]}${letters[rand.nextInt(letters.length)]}';
  final n = 1000 + rand.nextInt(9000);
  return '$l-$n';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          text,
          style: AppTypography.subtitle(AppColors.textPrimary).copyWith(fontSize: 16),
        ),
      );
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.addr,
    required this.selected,
    required this.onTap,
  });
  final _DemoAddress addr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: selected ? AppColors.goldSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    addr.icon,
                    size: 20,
                    color: selected ? AppColors.goldPressed : AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addr.label,
                          style: AppTypography.bodyMedium(AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          addr.line,
                          style: AppTypography.caption(AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(LucideIcons.check, size: 18, color: AppColors.goldPressed),
                ],
              ),
            ),
          ),
        ),
      );
}

class _AddNewAddress extends StatelessWidget {
  const _AddNewAddress({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.plus, size: 18, color: AppColors.gold),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.bodyMedium(AppColors.gold)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TwoToggle extends StatelessWidget {
  const _TwoToggle({
    required this.left,
    required this.right,
    required this.isLeft,
    required this.onChanged,
  });
  final String left;
  final String right;
  final bool isLeft;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Expanded(child: _opt(left, isLeft, () => onChanged(true))),
            Expanded(child: _opt(right, !isLeft, () => onChanged(false))),
          ],
        ),
      );

  Widget _opt(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.base,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]
                : null,
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium(AppColors.textPrimary)
                .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      );
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: selected ? AppColors.goldSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: selected ? AppColors.goldPressed : AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium(AppColors.textPrimary)
                          .copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.goldPressed : AppColors.divider,
                        width: 2,
                      ),
                      color: selected ? AppColors.goldPressed : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.t});
  final CartState state;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Money value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(AppColors.textSecondary).copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                value.toString(),
                style: AppTypography.body(AppColors.textPrimary).copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
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
          row(t.cartSubtotal, state.subtotal),
          row(t.cartDelivery, state.deliveryFee),
          if (!state.discount.isZero) row(t.cartDiscount, state.discount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          row(t.cartTotal, state.total, bold: true),
        ],
      ),
    );
  }
}
