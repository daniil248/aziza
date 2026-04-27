import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/dto.dart';
import '../../../core/design/product_image.dart';
import '../../../core/design/skeletons.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/design/widgets.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final locale = ref.watch(localeProvider).languageCode;
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(t: t)),
            SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(t.homeTopOfWeek, style: context.title),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: products.when(
                  data: (items) => _HeroCarousel(
                    items: items.take(4).toList(),
                    locale: locale,
                  ),
                  loading: () => const HeroCarouselSkeleton(),
                  error: (_, __) => AppErrorView(
                    message: t.errorNetwork,
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(t.homeRecommended, style: context.title),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: categories.maybeWhen(
                  data: (cats) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        final selected = ref.watch(selectedCategoryProvider) == null;
                        return AppChip(
                          label: t.catalogAll,
                          selected: selected,
                          onTap: () =>
                              ref.read(selectedCategoryProvider.notifier).state = null,
                        );
                      }
                      final c = cats[i - 1];
                      final selected = ref.watch(selectedCategoryProvider) == c.slug;
                      return AppChip(
                        label: c.name(locale),
                        selected: selected,
                        onTap: () => ref
                            .read(selectedCategoryProvider.notifier)
                            .state = selected ? null : c.slug,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemCount: cats.length + 1,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            products.when(
              data: (items) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductCard(
                      product: items[i],
                      locale: locale,
                      categorySlug: _slugOf(items[i], categories.value ?? const []),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: 600, child: ProductGridSkeleton()),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                child: AppErrorView(
                  message: t.errorNetwork,
                  onRetry: () => ref.invalidate(productsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _slugOf(ProductCardDto p, List<CategoryDto> cats) {
    for (final c in cats) {
      if (c.id == p.categoryId) return c.slug;
    }
    return '';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.t});
  final AppL10n t;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.homeGreeting, style: context.smallMuted),
                      const SizedBox(height: 2),
                      Text(t.appName, style: context.display.copyWith(fontSize: 26)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.bell, size: 22),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const PremiumBadge(label: 'Premium Member'),
          ],
        ),
      );
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({required this.items, required this.locale});
  final List<ProductCardDto> items;
  final String locale;

  @override
  Widget build(BuildContext context) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, i) {
          final p = items[i];
          return _HeroCard(product: p, locale: locale);
        },
      );
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.product, required this.locale});
  final ProductCardDto product;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final slug =
        categories.firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => CategoryDto(id: '', slug: '', sort: 0, nameI18n: const {}),
        ).slug;
    return GestureDetector(
      onTap: () => context.push('/product/${product.slug}'),
      child: SizedBox(
        width: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(
              imageUrl: product.mainImageUrl,
              categorySlug: slug,
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name(locale),
                        style: context.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      AppL10n.of(context).fromPrice(product.fromPrice.toString()),
                      style: AppTypography.caption(AppColors.gold)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.locale,
    required this.categorySlug,
  });
  final ProductCardDto product;
  final String locale;
  final String categorySlug;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/product/${product.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'product-${product.slug}',
                child: ProductImage(
                  imageUrl: product.mainImageUrl,
                  categorySlug: categorySlug,
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.name(locale),
              style: AppTypography.small(AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              AppL10n.of(context).fromPrice(product.fromPrice.toString()),
              style: AppTypography.small(AppColors.gold)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
