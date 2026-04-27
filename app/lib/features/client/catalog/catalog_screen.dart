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

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = ref.watch(localeProvider).languageCode;
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.navCatalog, style: context.display.copyWith(fontSize: 26)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v.trim(),
                decoration: InputDecoration(
                  hintText: t.catalogSearchHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Icon(LucideIcons.search, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
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
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: products.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(child: Text(t.catalogEmpty, style: context.bodyMuted));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _CatalogCard(
                      product: items[i],
                      locale: locale,
                      categorySlug:
                          _slugOf(items[i], categories.value ?? const []),
                    ),
                  );
                },
                loading: () => const ProductGridSkeleton(),
                error: (_, __) => AppErrorView(
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

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
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
