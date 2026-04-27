import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/dto.dart';
import '../../../core/cart/cart.dart';
import '../../../core/design/product_image.dart';
import '../../../core/design/skeletons.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/design/widgets.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _selectedVariant = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = ref.watch(localeProvider).languageCode;
    final productAsync = ref.watch(productDetailProvider(widget.slug));
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      body: productAsync.when(
        data: (p) {
          final cat = categories.firstWhere(
            (c) => c.id == p.categoryId,
            orElse: () => CategoryDto(id: '', slug: '', sort: 0, nameI18n: const {}),
          );
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                backgroundColor: AppColors.surface,
                leading: const _BackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Hero(
                      tag: 'product-${p.slug}',
                      child: ProductImage(
                        imageUrl: p.mainImageUrl,
                        categorySlug: cat.slug,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name(locale), style: context.display.copyWith(fontSize: 28)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(p.description(locale), style: context.bodyMuted),
                      const SizedBox(height: AppSpacing.xl),
                      if (p.variants.isNotEmpty) ...[
                        Text(t.productSize, style: context.subtitle),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: List.generate(p.variants.length, (i) {
                            final v = p.variants[i];
                            return AppChip(
                              label: v.displayLabel(locale),
                              selected: i == _selectedVariant,
                              onTap: () => setState(() => _selectedVariant = i),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.productKbju, style: context.subtitle),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _Kbju(label: t.productCalories, value: p.kbju.kcal.toStringAsFixed(0)),
                                _Kbju(label: t.productProtein, value: p.kbju.protein.toStringAsFixed(1)),
                                _Kbju(label: t.productFat, value: p.kbju.fat.toStringAsFixed(1)),
                                _Kbju(label: t.productCarbs, value: p.kbju.carb.toStringAsFixed(1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(t.productIngredients, style: context.subtitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(p.ingredients(locale), style: context.body),
                      const SizedBox(height: AppSpacing.xl),
                      Text(t.productCooking, style: context.subtitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(p.cooking(locale), style: context.body),
                      const SizedBox(height: AppSpacing.xxl),
                      _Related(
                        currentSlug: p.slug,
                        categoryId: p.categoryId,
                        locale: locale,
                        label: t.productRelated,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ProductDetailSkeleton(),
        error: (_, __) => AppErrorView(
          message: t.errorNetwork,
          onRetry: () => ref.invalidate(productDetailProvider(widget.slug)),
        ),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (p) {
          if (p.variants.isEmpty) return const SizedBox.shrink();
          final variant = p.variants[_selectedVariant.clamp(0, p.variants.length - 1)];
          final categorySlug = categories
              .firstWhere(
                (c) => c.id == p.categoryId,
                orElse: () => CategoryDto(id: '', slug: '', sort: 0, nameI18n: const {}),
              )
              .slug;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).addProduct(
                        product: p,
                        variant: variant,
                        categorySlug: categorySlug,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.textPrimary,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: t.goToCart,
                        textColor: AppColors.gold,
                        onPressed: () => context.go('/cart'),
                      ),
                      content: Text(
                        t.inCart,
                        style: AppTypography.bodyMedium(Colors.white),
                      ),
                    ),
                  );
                },
                child: Text('${t.productAddToCart} · ${variant.price}'),
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: AppColors.surfaceMuted,
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
}

class _Related extends ConsumerWidget {
  const _Related({
    required this.currentSlug,
    required this.categoryId,
    required this.locale,
    required this.label,
  });
  final String currentSlug;
  final String categoryId;
  final String locale;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(productsProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final related = all
        .where((p) => p.categoryId == categoryId && p.slug != currentSlug)
        .take(8)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();

    String slugOf(String catId) {
      for (final c in categories) {
        if (c.id == catId) return c.slug;
      }
      return '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.subtitle(AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) {
              final p = related[i];
              return SizedBox(
                width: 130,
                child: GestureDetector(
                  onTap: () => context.push('/product/${p.slug}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ProductImage(
                          imageUrl: p.mainImageUrl,
                          categorySlug: slugOf(p.categoryId),
                          borderRadius: AppRadius.md,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        p.name(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.small(AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppL10n.of(context).fromPrice(p.fromPrice.toString()),
                        style: AppTypography.small(AppColors.gold)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Kbju extends StatelessWidget {
  const _Kbju({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: AppTypography.subtitle(AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(AppColors.textSecondary)),
        ],
      );
}
