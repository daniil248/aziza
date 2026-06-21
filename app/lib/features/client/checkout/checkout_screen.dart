import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/auth_dto.dart';
import '../../../core/cart/cart.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/session/session.dart';

enum _Pay { cash, card, kaspi }

extension on _Pay {
  String get apiValue => switch (this) {
        _Pay.cash => 'cash',
        _Pay.card => 'card_online',
        _Pay.kaspi => 'kaspi',
      };
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId; // null while none picked / adding new
  bool _addingNew = false;
  _Pay _pay = _Pay.card;
  final _commentCtrl = TextEditingController();

  // New-address fields.
  final _streetCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _streetCtrl.dispose();
    _buildingCtrl.dispose();
    _aptCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<AddressDto> addresses) async {
    if (_busy) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authApiProvider);
      final orders = ref.read(ordersApiProvider);

      // Resolve the delivery address: either a picked saved one, or create new.
      String addressId;
      if (_addingNew || addresses.isEmpty) {
        if (_streetCtrl.text.trim().isEmpty) {
          throw ApiException('Укажите улицу доставки');
        }
        final created = await auth.createAddress(
          street: _streetCtrl.text.trim(),
          building: _buildingCtrl.text.trim(),
          apt: _aptCtrl.text.trim(),
          floor: _floorCtrl.text.trim(),
          isDefault: addresses.isEmpty,
        );
        addressId = created.id;
        ref.invalidate(myAddressesProvider);
      } else {
        addressId = _selectedAddressId ?? addresses.first.id;
      }

      // Map cart -> [{product_id, variant_label, qty}].
      final items = cart.items
          .map((i) => {
                'product_id': i.productId,
                'variant_label': i.variantLabel,
                'qty': i.qty,
              })
          .toList();

      final order = await orders.createOrder(
        addressId: addressId,
        items: items,
        paymentMethod: _pay.apiValue,
        comment: _commentCtrl.text.trim(),
        promoCode: cart.promo?.code,
      );

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (mounted) context.go('/order-success?code=${Uri.encodeComponent(order.code)}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Не удалось оформить заказ. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final cart = ref.watch(cartProvider);
    final session = ref.watch(sessionProvider);

    if (!session.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(t.checkoutTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.lock, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Войдите, чтобы оформить заказ',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle(AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Войти'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final addressesAsync = ref.watch(myAddressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.checkoutTitle),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Не удалось загрузить адреса: $e',
                textAlign: TextAlign.center,
                style: AppTypography.body(AppColors.textSecondary)),
          ),
        ),
        data: (addresses) {
          // Default selection: the default address, else the first.
          _selectedAddressId ??= addresses.isEmpty
              ? null
              : (addresses.firstWhere((a) => a.isDefault,
                      orElse: () => addresses.first))
                  .id;
          final showForm = _addingNew || addresses.isEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
            children: [
              _SectionLabel(text: t.checkoutAddress),
              ...addresses.map(
                (a) => _AddressTile(
                  addr: a,
                  selected: !showForm && _selectedAddressId == a.id,
                  onTap: () => setState(() {
                    _selectedAddressId = a.id;
                    _addingNew = false;
                  }),
                ),
              ),
              if (!showForm)
                _AddNewAddress(
                  label: t.checkoutAddNewAddress,
                  onTap: () => setState(() => _addingNew = true),
                )
              else
                _NewAddressForm(
                  street: _streetCtrl,
                  building: _buildingCtrl,
                  apt: _aptCtrl,
                  floor: _floorCtrl,
                  canCancel: addresses.isNotEmpty,
                  onCancel: () => setState(() => _addingNew = false),
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

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(LucideIcons.circleAlert, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!, style: AppTypography.caption(AppColors.error)),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: cart.isEmpty || _busy || !session.isLoggedIn
                ? null
                : () => _placeOrder(addressesAsync.value ?? const []),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('${t.checkoutPlaceOrder} · ${cart.total}'),
          ),
        ),
      ),
    );
  }
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
  final AddressDto addr;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (addr.label) {
        'work' => LucideIcons.briefcase,
        'custom' => LucideIcons.mapPin,
        _ => LucideIcons.house,
      };

  String get _labelText => switch (addr.label) {
        'work' => 'Работа',
        'custom' => 'Адрес',
        _ => 'Дом',
      };

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
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(_icon,
                      size: 20,
                      color: selected ? AppColors.goldPressed : AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_labelText,
                            style: AppTypography.bodyMedium(AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(addr.oneLine,
                            style: AppTypography.caption(AppColors.textSecondary)),
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
  const _AddNewAddress({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                const Icon(LucideIcons.plus, size: 18, color: AppColors.gold),
                const SizedBox(width: AppSpacing.sm),
                Text(label,
                    style: AppTypography.bodyMedium(AppColors.gold)
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

class _NewAddressForm extends StatelessWidget {
  const _NewAddressForm({
    required this.street,
    required this.building,
    required this.apt,
    required this.floor,
    required this.canCancel,
    required this.onCancel,
  });
  final TextEditingController street;
  final TextEditingController building;
  final TextEditingController apt;
  final TextEditingController floor;
  final bool canCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: street,
            decoration: const InputDecoration(hintText: 'Улица *'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: building,
                  decoration: const InputDecoration(hintText: 'Дом'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: apt,
                  decoration: const InputDecoration(hintText: 'Квартира'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: floor,
                  decoration: const InputDecoration(hintText: 'Этаж'),
                ),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onCancel, child: const Text('Отмена')),
            ),
          ],
        ],
      ),
    );
  }
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
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: selected ? AppColors.goldPressed : AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(label,
                        style: AppTypography.bodyMedium(AppColors.textPrimary).copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500)),
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
                child: Text(label,
                    style: AppTypography.body(AppColors.textSecondary).copyWith(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                    )),
              ),
              Text(value.toString(),
                  style: AppTypography.body(AppColors.textPrimary)
                      .copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
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
