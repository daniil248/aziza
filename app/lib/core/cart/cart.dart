import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/dto.dart';
import '../i18n/locale_resolver.dart';
import '../money/money.dart';
import '../providers.dart';

/// One item in the cart. Identified by `productId + variantLabel`.
class CartItem {
  CartItem({
    required this.productId,
    required this.slug,
    required this.nameI18n,
    required this.categorySlug,
    required this.variantLabel,
    required this.variantI18n,
    required this.weightG,
    required this.unitPrice,
    required this.qty,
    this.imageUrl,
  });

  final String productId;
  final String slug;
  final Map<String, dynamic> nameI18n;
  final String categorySlug;
  final String variantLabel;
  final Map<String, dynamic> variantI18n;
  final int weightG;
  final Money unitPrice;
  final int qty;
  final String? imageUrl;

  String get key => '$productId::$variantLabel';

  String name(String locale) => pickI18n(nameI18n, locale);
  String variantName(String locale) {
    final v = pickI18n(variantI18n, locale);
    return v.isNotEmpty ? v : variantLabel;
  }

  Money get total => unitPrice * qty;

  CartItem copyWith({int? qty}) => CartItem(
        productId: productId,
        slug: slug,
        nameI18n: nameI18n,
        categorySlug: categorySlug,
        variantLabel: variantLabel,
        variantI18n: variantI18n,
        weightG: weightG,
        unitPrice: unitPrice,
        qty: qty ?? this.qty,
        imageUrl: imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'slug': slug,
        'nameI18n': nameI18n,
        'categorySlug': categorySlug,
        'variantLabel': variantLabel,
        'variantI18n': variantI18n,
        'weightG': weightG,
        'unitPriceMinor': unitPrice.minor,
        'qty': qty,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: j['productId'] as String,
        slug: j['slug'] as String,
        nameI18n: Map<String, dynamic>.from(j['nameI18n'] as Map),
        categorySlug: (j['categorySlug'] as String?) ?? '',
        variantLabel: j['variantLabel'] as String,
        variantI18n: Map<String, dynamic>.from(j['variantI18n'] as Map? ?? {}),
        weightG: (j['weightG'] as num).toInt(),
        unitPrice: Money((j['unitPriceMinor'] as num).toInt()),
        qty: (j['qty'] as num).toInt(),
        imageUrl: j['imageUrl'] as String?,
      );
}

/// Promo evaluation outcome. Stored on cart state when a code is applied.
class AppliedPromo {
  const AppliedPromo({
    required this.code,
    required this.type,
    required this.value,
    required this.minOrderMinor,
  });

  final String code;
  final String type; // 'percent' | 'amount' | 'free_delivery'
  final int value;
  final int minOrderMinor;
}

/// Stub promo catalog matching the API seed. Replace with API lookup
/// when /api/v1/promos/validate is wired.
const _knownPromos = <String, AppliedPromo>{
  'WELCOME10':
      AppliedPromo(code: 'WELCOME10', type: 'percent', value: 10, minOrderMinor: 200_000),
  'FREEDLV':
      AppliedPromo(code: 'FREEDLV', type: 'free_delivery', value: 0, minOrderMinor: 300_000),
  'AZIZA1500':
      AppliedPromo(code: 'AZIZA1500', type: 'amount', value: 150_000, minOrderMinor: 500_000),
};

class CartState {
  CartState({
    required this.items,
    this.promo,
  });

  final List<CartItem> items;
  final AppliedPromo? promo;

  bool get isEmpty => items.isEmpty;
  int get totalQty => items.fold(0, (a, b) => a + b.qty);

  Money get subtotal =>
      items.fold(Money.zero, (acc, item) => acc + item.total);

  /// Free delivery above 5000 ₸, premium subscribers, or with FREEDLV promo.
  Money get deliveryFee {
    if (promo?.type == 'free_delivery' && subtotal.minor >= (promo?.minOrderMinor ?? 0)) {
      return Money.zero;
    }
    if (subtotal.minor == 0) return Money.zero;
    if (subtotal.minor >= 500_000) return const Money(50_000); // 500 ₸
    return const Money(80_000); // 800 ₸
  }

  Money get discount {
    if (promo == null) return Money.zero;
    if (subtotal.minor < promo!.minOrderMinor) return Money.zero;
    return switch (promo!.type) {
      'percent' => Money((subtotal.minor * promo!.value) ~/ 100),
      'amount' => Money(promo!.value),
      _ => Money.zero,
    };
  }

  Money get total {
    final raw = subtotal + deliveryFee - discount;
    return raw.minor < 0 ? Money.zero : raw;
  }

  CartState copyWith({List<CartItem>? items, AppliedPromo? promo, bool clearPromo = false}) =>
      CartState(
        items: items ?? this.items,
        promo: clearPromo ? null : (promo ?? this.promo),
      );

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'promo': promo?.code,
      };

  factory CartState.fromJson(Map<String, dynamic> j) {
    final items = ((j['items'] as List?) ?? const [])
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final code = j['promo'] as String?;
    return CartState(items: items, promo: code == null ? null : _knownPromos[code]);
  }
}

class CartController extends StateNotifier<CartState> {
  CartController(this._prefs) : super(CartState(items: const [])) {
    _load();
  }

  static const _key = 'cart_v1';
  final SharedPreferences _prefs;

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = CartState.fromJson(decoded);
    } catch (_) {
      // ignore corrupt cart, start fresh
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void addProduct({
    required ProductCardDto product,
    required VariantDto variant,
    required String categorySlug,
    int qty = 1,
  }) {
    final newItem = CartItem(
      productId: product.id,
      slug: product.slug,
      nameI18n: product.nameI18n,
      categorySlug: categorySlug,
      variantLabel: variant.label,
      variantI18n: variant.labelI18n,
      weightG: variant.weightG,
      unitPrice: variant.price,
      qty: qty,
      imageUrl: product.mainImageUrl,
    );
    final idx = state.items.indexWhere((i) => i.key == newItem.key);
    final next = [...state.items];
    if (idx >= 0) {
      next[idx] = next[idx].copyWith(qty: next[idx].qty + qty);
    } else {
      next.add(newItem);
    }
    state = state.copyWith(items: next);
    _persist();
  }

  void setQty(String key, int qty) {
    final next = <CartItem>[];
    for (final it in state.items) {
      if (it.key == key) {
        if (qty <= 0) continue;
        next.add(it.copyWith(qty: qty));
      } else {
        next.add(it);
      }
    }
    state = state.copyWith(items: next);
    _persist();
  }

  void remove(String key) => setQty(key, 0);

  void clear() {
    state = CartState(items: const []);
    _persist();
  }

  /// Returns null on success, error code on failure ('unknown' | 'min_order').
  String? applyPromo(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      state = state.copyWith(clearPromo: true);
      _persist();
      return null;
    }
    final promo = _knownPromos[code];
    if (promo == null) return 'unknown';
    if (state.subtotal.minor < promo.minOrderMinor) return 'min_order';
    state = state.copyWith(promo: promo);
    _persist();
    return null;
  }

  void clearPromo() {
    state = state.copyWith(clearPromo: true);
    _persist();
  }
}

final cartProvider = StateNotifierProvider<CartController, CartState>(
  (ref) => CartController(ref.read(sharedPrefsProvider)),
);

final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).totalQty,
);
