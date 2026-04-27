import 'package:dio/dio.dart';

import 'api_client.dart';
import 'dto.dart';

/// Admin API — CRUD + image upload. Routes through the same base URL as the
/// public client. Auth gating will be added when admin login is wired.
class AdminApi {
  AdminApi({String? baseUrl})
      : _base = baseUrl ?? defaultApiBase(),
        _dio = Dio(
          BaseOptions(
            baseUrl: '${baseUrl ?? defaultApiBase()}/api/v1/admin',
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            responseType: ResponseType.json,
            headers: {'Accept': 'application/json'},
          ),
        );

  final String _base;
  final Dio _dio;

  String get apiBase => _base;

  /// Resolve a relative `/static/...` URL against the API host.
  String absoluteImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$_base$url';
  }

  Future<List<ProductDetailDto>> listProducts() async {
    final res = await _dio.get<List<dynamic>>('/products');
    return (res.data ?? const [])
        .map((e) => ProductDetailDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ProductDetailDto> createProduct(Map<String, dynamic> payload) async {
    final res = await _dio.post<Map<String, dynamic>>('/products', data: payload);
    return ProductDetailDto.fromJson(res.data!);
  }

  Future<ProductDetailDto> updateProduct(String id, Map<String, dynamic> payload) async {
    final res = await _dio.patch<Map<String, dynamic>>('/products/$id', data: payload);
    return ProductDetailDto.fromJson(res.data!);
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete<void>('/products/$id');
  }

  /// Returns `/static/products/<file>` URL — pass through `absoluteImageUrl`
  /// before showing in <img> tag.
  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/upload',
      data: form,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return res.data!['url'] as String;
  }
}
