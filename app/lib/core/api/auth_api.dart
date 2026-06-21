import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth_dto.dart';

/// Prefs key holding the current access token. Shared with [SessionController]
/// so the dio interceptor and the session state never diverge.
const kAuthAccessKey = 'auth_access';

/// Thrown by auth/order APIs so the UI can show a readable message.
/// Unlike the catalog client, auth NEVER falls back to demo assets.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Maps a DioException into a human-readable [ApiException].
ApiException mapDioError(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  String? detail;
  if (data is Map && data['detail'] != null) {
    final d = data['detail'];
    if (d is String) {
      detail = d;
    } else if (d is List && d.isNotEmpty) {
      // FastAPI validation errors: list of {msg, loc, ...}.
      final first = d.first;
      if (first is Map && first['msg'] != null) detail = first['msg'] as String;
    }
  }
  if (detail != null) return ApiException(detail, statusCode: status);

  final friendly = switch (status) {
    401 => 'Неверный телефон или пароль',
    403 => 'Доступ запрещён',
    404 => 'Не найдено',
    409 => 'Конфликт: запись уже существует',
    null => 'Нет связи с сервером. Проверьте подключение.',
    _ => 'Ошибка сервера ($status)',
  };
  return ApiException(friendly, statusCode: status);
}

/// Builds a dio instance pointed at `${defaultApiBase()}/api/v1` with a Bearer
/// interceptor that reads the access token from shared_preferences.
Dio buildAuthedDio({String? baseUrl, SharedPreferences? prefs}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${baseUrl ?? defaultApiBase()}/api/v1',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Prefer an in-memory prefs handle; fall back to a fresh read.
        final p = prefs ?? await SharedPreferences.getInstance();
        final token = p.getString(kAuthAccessKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

/// Auth + profile + addresses. Throws [ApiException] on failure (no fallback).
class AuthApi {
  AuthApi({String? baseUrl, SharedPreferences? prefs})
      : _dio = buildAuthedDio(baseUrl: baseUrl, prefs: prefs);

  final Dio _dio;

  Future<AuthResult> register({
    required String phone,
    required String password,
    String? name,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/register', data: {
        'phone': phone,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      return AuthResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      return AuthResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthResult> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return AuthResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthUser> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthUser> patchMe({String? name, String? email, String? locale}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/auth/me', data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (locale != null) 'locale': locale,
      });
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // --- Addresses ---

  Future<List<AddressDto>> listAddresses() async {
    try {
      final res = await _dio.get<List<dynamic>>('/auth/me/addresses');
      return (res.data ?? const [])
          .map((e) => AddressDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AddressDto> createAddress({
    String label = 'home',
    required String street,
    String? building,
    String? apt,
    String? entrance,
    String? floor,
    String? comment,
    double lat = 0,
    double lng = 0,
    bool isDefault = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/me/addresses',
        data: {
          'label': label,
          'street': street,
          if (building != null && building.isNotEmpty) 'building': building,
          if (apt != null && apt.isNotEmpty) 'apt': apt,
          if (entrance != null && entrance.isNotEmpty) 'entrance': entrance,
          if (floor != null && floor.isNotEmpty) 'floor': floor,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          'lat': lat,
          'lng': lng,
          'is_default': isDefault,
        },
      );
      return AddressDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AddressDto> updateAddress(String id, Map<String, dynamic> patch) async {
    try {
      final res =
          await _dio.patch<Map<String, dynamic>>('/auth/me/addresses/$id', data: patch);
      return AddressDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete<void>('/auth/me/addresses/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
