import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dto.dart';

/// Resolves API base URL.
/// - Web (debug): localhost (CORS configured server-side)
/// - Android emulator: 10.0.2.2 (host loopback)
/// - Physical device: must override via --dart-define=API_BASE_URL=http://<host-ip>:8000
String defaultApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'http://localhost:8000';
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';
}

/// HTTP client with bundled-JSON fallback.
///
/// On any HTTP error (server down, network blocked, public deploy with no API),
/// falls back to JSON snapshots in `assets/demo/`. This makes the deployed
/// web build self-contained for showcasing the design.
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: '${baseUrl ?? defaultApiBase()}/api/v1',
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 6),
            sendTimeout: const Duration(seconds: 4),
            responseType: ResponseType.json,
            headers: {'Accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Future<List<CategoryDto>> listCategories() async {
    final raw = await _fetchJson(
      path: '/categories',
      assetFallback: 'assets/demo/categories.json',
    );
    final list = raw as List<dynamic>;
    return list
        .map((e) => CategoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({List<ProductCardDto> items, int total})> listProducts({
    String? category,
    String? query,
    int limit = 30,
    int offset = 0,
  }) async {
    final raw = await _fetchJson(
      path: '/products',
      queryParams: {
        if (category != null) 'category': category,
        if (query != null && query.isNotEmpty) 'q': query,
        'limit': limit,
        'offset': offset,
      },
      assetFallback: 'assets/demo/products_list.json',
    );
    final data = raw as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? const [])
        .map((e) => ProductCardDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (items: items, total: (data['total'] as num?)?.toInt() ?? items.length);
  }

  Future<ProductDetailDto> getProduct(String slug) async {
    final raw = await _fetchJson(
      path: '/products/$slug',
      assetFallback: 'assets/demo/product_$slug.json',
    );
    return ProductDetailDto.fromJson(raw as Map<String, dynamic>);
  }

  Future<dynamic> _fetchJson({
    required String path,
    Map<String, dynamic>? queryParams,
    required String assetFallback,
  }) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: queryParams);
      return res.data;
    } on DioException {
      // API unreachable — fall back to bundled snapshot.
      final raw = await rootBundle.loadString(assetFallback);
      return jsonDecode(raw);
    }
  }
}
