import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/dto.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/design/widgets.dart';
import '../../core/providers.dart';
import 'product_form.dart';

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
                NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(LucideIcons.utensils), label: 'Товары'),
                NavigationDestination(icon: Icon(LucideIcons.receipt), label: 'Заказы'),
                NavigationDestination(icon: Icon(LucideIcons.users), label: 'Пользователи'),
              ],
            ),
    );
  }

  Widget _content() => switch (_section) {
        0 => const _DashboardSection(),
        1 => const ProductsSection(),
        2 => const _OrdersSection(),
        3 => const _UsersSection(),
        _ => const _DashboardSection(),
      };
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (LucideIcons.layoutDashboard, 'Dashboard'),
    (LucideIcons.utensils, 'Товары'),
    (LucideIcons.receipt, 'Заказы'),
    (LucideIcons.users, 'Пользователи'),
    (LucideIcons.crown, 'Подписки'),
    (LucideIcons.percent, 'Промокоды'),
    (LucideIcons.bell, 'Push'),
    (LucideIcons.chartColumn, 'Аналитика'),
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

class _OrdersSection extends StatelessWidget {
  const _OrdersSection();

  @override
  Widget build(BuildContext context) => _SectionWrapper(
        title: 'Заказы',
        child: Center(
          child: Text(
            'Активных заказов пока нет',
            style: AppTypography.body(AppColors.textSecondary),
          ),
        ),
      );
}

class _UsersSection extends StatelessWidget {
  const _UsersSection();

  @override
  Widget build(BuildContext context) => _SectionWrapper(
        title: 'Пользователи',
        child: Center(
          child: Text(
            'Список появится после подключения авторизации',
            style: AppTypography.body(AppColors.textSecondary),
          ),
        ),
      );
}
