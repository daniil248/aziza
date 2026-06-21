import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/auth_api.dart';
import '../../core/api/auth_dto.dart';
import '../../core/api/dto.dart';
import '../../core/api/order_status.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/design/widgets.dart';
import '../../core/providers.dart';
import '../../core/session/session.dart';
import 'product_form.dart';

/// Admin order list — filtered by an optional status.
final adminOrderStatusFilterProvider = StateProvider<String?>((ref) => null);

final adminOrdersProvider = FutureProvider<List<OrderDto>>((ref) async {
  final status = ref.watch(adminOrderStatusFilterProvider);
  return ref.read(ordersApiProvider).adminListOrders(status: status);
});

final adminCouriersProvider = FutureProvider<List<CourierDto>>(
  (ref) => ref.read(ordersApiProvider).adminListCouriers(),
);

const _orderStatuses = <String>[
  'pending',
  'confirmed',
  'preparing',
  'courier_assigned',
  'in_transit',
  'delivered',
  'cancelled',
];

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: Row(
        children: [
          if (wide) _Sidebar(selected: _section, onSelect: (i) => setState(() => _section = i)),
          Expanded(child: _content()),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (i) => setState(() => _section = i),
              destinations: const [
                NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Главная'),
                NavigationDestination(icon: Icon(LucideIcons.utensils), label: 'Товары'),
                NavigationDestination(icon: Icon(LucideIcons.receipt), label: 'Заказы'),
                NavigationDestination(icon: Icon(LucideIcons.bike), label: 'Курьеры'),
              ],
            ),
    );
  }

  Widget _content() => switch (_section) {
        0 => const _DashboardSection(),
        1 => const ProductsSection(),
        2 => const _OrdersSection(),
        3 => const _CouriersSection(),
        _ => const _DashboardSection(),
      };
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (LucideIcons.layoutDashboard, 'Главная'),
    (LucideIcons.utensils, 'Товары'),
    (LucideIcons.receipt, 'Заказы'),
    (LucideIcons.bike, 'Курьеры'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        color: AppColors.surfaceMuted,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(LucideIcons.crown, color: AppColors.gold, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Aziza Admin', style: AppTypography.subtitle(AppColors.textPrimary)),
                ],
              ),
            ),
            for (var i = 0; i < _items.length; i++)
              _SidebarItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                selected: selected == i,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('v0.1.0', style: AppTypography.caption(AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: selected ? AppColors.gold : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? AppColors.gold : AppColors.textPrimary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: AppTypography.bodyMedium(AppColors.textPrimary).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.display(AppColors.textPrimary)),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(child: child),
          ],
        ),
      );
}

class _DashboardSection extends ConsumerWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductsProvider);
    return _SectionWrapper(
      title: 'Сегодня',
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 2.4,
        children: [
          const _Kpi(label: 'Заказов', value: '24', delta: '+12%'),
          const _Kpi(label: 'Выручка', value: '186 400 ₸', delta: '+8%'),
          const _Kpi(label: 'Подписчиков', value: '142', delta: '+3'),
          _Kpi(
            label: 'Товаров',
            value: products.maybeWhen(data: (i) => '${i.length}', orElse: () => '—'),
            delta: '',
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.delta});
  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption(AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 28)),
            if (delta.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(delta,
                  style: AppTypography.caption(AppColors.success)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      );
}

class ProductsSection extends ConsumerWidget {
  const ProductsSection({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ProductDetailDto? initial,
  }) async {
    final categories = ref.read(categoriesProvider).value ?? const [];
    if (categories.isEmpty) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProductForm(initial: initial, categories: categories),
      ),
    );
    if (saved == true) {
      ref.invalidate(adminProductsProvider);
      ref.invalidate(productsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final api = ref.read(adminApiProvider);

    return _SectionWrapper(
      title: 'Товары',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
        label: const Text('Добавить'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
      child: productsAsync.when(
        data: (items) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              const _ProductTableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final p = items[i];
                    final cat = categories.firstWhere(
                      (c) => c.id == p.categoryId,
                      orElse: () =>
                          CategoryDto(id: '', slug: '—', sort: 0, nameI18n: const {'ru': '—'}),
                    );
                    return _ProductRow(
                      product: p,
                      categoryName: cat.name('ru'),
                      imageAbs: api.absoluteImageUrl(p.mainImageUrl),
                      onTap: () => _openForm(context, ref, initial: p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(
          message: 'Не удалось загрузить товары: $e',
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
      ),
    );
  }
}

class _ProductTableHeader extends StatelessWidget {
  const _ProductTableHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            const SizedBox(width: 56), // image slot
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 4, child: _h('Товар')),
            Expanded(flex: 2, child: _h('Категория')),
            Expanded(flex: 1, child: _h('Вариантов')),
            Expanded(flex: 2, child: _h('Цена от')),
            const SizedBox(width: 24),
          ],
        ),
      );

  static Widget _h(String s) => Text(
        s,
        style: AppTypography.caption(AppColors.textSecondary)
            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.categoryName,
    required this.imageAbs,
    required this.onTap,
  });

  final ProductDetailDto product;
  final String categoryName;
  final String imageAbs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: imageAbs.isEmpty
                    ? Container(
                        color: AppColors.surface,
                        child: const Icon(LucideIcons.image,
                            color: AppColors.textTertiary),
                      )
                    : Image.network(
                        imageAbs,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(LucideIcons.imageOff,
                              color: AppColors.textTertiary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 4,
              child: Text(
                product.name('ru'),
                style: AppTypography.body(AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                categoryName,
                style: AppTypography.body(AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.variants.length}',
                style: AppTypography.body(AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.fromPrice.toString(),
                style: AppTypography.body(AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _OrdersSection extends ConsumerWidget {
  const _OrdersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final filter = ref.watch(adminOrderStatusFilterProvider);
    final couriers = ref.watch(adminCouriersProvider).value ?? const [];

    return _SectionWrapper(
      title: 'Заказы',
      action: _StatusFilterDropdown(
        value: filter,
        onChanged: (v) =>
            ref.read(adminOrderStatusFilterProvider.notifier).state = v,
      ),
      child: ordersAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(
          message: 'Не удалось загрузить заказы: $e',
          onRetry: () => ref.invalidate(adminOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Text('Заказов нет',
                  style: AppTypography.body(AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) =>
                _AdminOrderCard(order: orders[i], couriers: couriers),
          );
        },
      ),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text('Все статусы', style: AppTypography.body(AppColors.textSecondary)),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Все статусы')),
            for (final s in _orderStatuses)
              DropdownMenuItem<String?>(value: s, child: Text(orderStatusInfo(s).label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerStatefulWidget {
  const _AdminOrderCard({required this.order, required this.couriers});
  final OrderDto order;
  final List<CourierDto> couriers;

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(adminCouriersProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final api = ref.read(ordersApiProvider);
    final info = orderStatusInfo(o.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('№ ${o.code}', style: AppTypography.subtitle(AppColors.textPrimary)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(info.label,
                    style: AppTypography.caption(info.color)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(o.total.toString(),
                  style: AppTypography.bodyMedium(AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (o.client?.name != null && o.client!.name!.isNotEmpty) o.client!.name!,
              if (o.client?.phone != null && o.client!.phone!.isNotEmpty)
                '+${o.client!.phone!}',
              if (o.address != null) o.address!.oneLine,
            ].join(' · '),
            style: AppTypography.caption(AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LabeledDropdown<String>(
                  label: 'Статус',
                  value: o.status,
                  items: {for (final s in _orderStatuses) s: orderStatusInfo(s).label},
                  onChanged: (v) {
                    if (v != null && v != o.status) {
                      _run(() => api.adminSetStatus(o.id, v));
                    }
                  },
                ),
                _LabeledDropdown<String?>(
                  label: 'Курьер',
                  value: o.courier?.id,
                  items: {
                    null: '— не назначен —',
                    for (final c in widget.couriers)
                      c.id: '${c.name ?? c.phone ?? c.id} (${c.activeOrders})',
                  },
                  onChanged: (v) {
                    if (v != o.courier?.id) {
                      _run(() => api.adminAssignCourier(o.id, v));
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: AppTypography.caption(AppColors.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: [
                for (final e in items.entries)
                  DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _CouriersSection extends ConsumerWidget {
  const _CouriersSection();

  Future<void> _createCourier(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _NewCourierDialog(),
    );
    if (created == true) ref.invalidate(adminCouriersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriersAsync = ref.watch(adminCouriersProvider);
    return _SectionWrapper(
      title: 'Курьеры',
      action: ElevatedButton.icon(
        onPressed: () => _createCourier(context, ref),
        icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
        label: const Text('Добавить'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
      child: couriersAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(
          message: 'Не удалось загрузить курьеров: $e',
          onRetry: () => ref.invalidate(adminCouriersProvider),
        ),
        data: (couriers) {
          if (couriers.isEmpty) {
            return Center(
              child: Text('Курьеров пока нет',
                  style: AppTypography.body(AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            itemCount: couriers.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) => _CourierRow(courier: couriers[i]),
          );
        },
      ),
    );
  }
}

class _CourierRow extends ConsumerWidget {
  const _CourierRow({required this.courier});
  final CourierDto courier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.goldSoft,
            child: Icon(
              courier.isActive ? LucideIcons.bike : LucideIcons.userX,
              size: 18,
              color: AppColors.goldPressed,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courier.name ?? '—',
                    style: AppTypography.body(AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '+${courier.phone ?? ''} · активных: ${courier.activeOrders}',
                  style: AppTypography.caption(AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(courier.isActive ? 'Активен' : 'Отключён',
              style: AppTypography.caption(
                  courier.isActive ? AppColors.success : AppColors.textSecondary)),
          Switch(
            value: courier.isActive,
            onChanged: (v) async {
              try {
                await ref
                    .read(ordersApiProvider)
                    .adminUpdateCourier(courier.id, isActive: v);
                ref.invalidate(adminCouriersProvider);
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NewCourierDialog extends ConsumerStatefulWidget {
  const _NewCourierDialog();

  @override
  ConsumerState<_NewCourierDialog> createState() => _NewCourierDialogState();
}

class _NewCourierDialogState extends ConsumerState<_NewCourierDialog> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length >= 10 && _pass.text.length >= 6;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(ordersApiProvider).adminCreateCourier(
            phone: _digits,
            name: _name.text.trim(),
            password: _pass.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый курьер'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Имя'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Телефон'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _pass,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Пароль (мин. 6)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: AppTypography.caption(AppColors.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _valid && !_busy ? _submit : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Создать'),
        ),
      ],
    );
  }
}
