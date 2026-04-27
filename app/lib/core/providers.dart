import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/admin_api.dart';
import 'api/api_client.dart';
import 'api/dto.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final adminApiProvider = Provider<AdminApi>((ref) => AdminApi());

final adminProductsProvider = FutureProvider<List<ProductDetailDto>>((ref) async {
  try {
    return await ref.read(adminApiProvider).listProducts();
  } catch (_) {
    // Fallback for deployed admin without a reachable backend — show read-only
    // list pulled from bundled JSON. Mutations will surface a clear error.
    final cards = await ref.read(productsProvider.future);
    final api = ref.read(apiClientProvider);
    return Future.wait(cards.map((c) => api.getProduct(c.slug)));
  }
});

final categoriesProvider = FutureProvider<List<CategoryDto>>(
  (ref) => ref.read(apiClientProvider).listCategories(),
);

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<ProductCardDto>>((ref) async {
  final api = ref.read(apiClientProvider);
  final categorySlug = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categories = await ref.watch(categoriesProvider.future);

  final result = await api.listProducts(category: categorySlug, query: query);
  var items = result.items;

  // Client-side filter — also covers the asset-fallback path where the
  // bundled JSON contains all products.
  if (categorySlug != null) {
    final catId = categories
        .firstWhere(
          (c) => c.slug == categorySlug,
          orElse: () => categories.first,
        )
        .id;
    items = items.where((p) => p.categoryId == catId).toList();
  }
  if (query.isNotEmpty) {
    items = items.where((p) {
      return p.nameI18n.values.whereType<String>().any(
            (v) => v.toLowerCase().contains(query),
          );
    }).toList();
  }
  return items;
});

final productDetailProvider =
    FutureProvider.family<ProductDetailDto, String>((ref, slug) async {
  final api = ref.read(apiClientProvider);
  return api.getProduct(slug);
});

/// Locale persisted across launches.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._prefs) : super(_load(_prefs));

  static const _key = 'locale';
  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences p) {
    final code = p.getString(_key) ?? 'ru';
    return Locale(code);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await _prefs.setString(_key, locale.languageCode);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at app bootstrap'),
);

final localeProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(ref.read(sharedPrefsProvider)),
);
