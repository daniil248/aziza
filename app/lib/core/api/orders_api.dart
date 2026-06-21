import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';
import 'auth_dto.dart';

/// Orders for client, courier, and admin-ops. All calls send the Bearer token
/// via the shared interceptor and throw [ApiException] on failure.
class OrdersApi {
  OrdersApi({String? baseUrl, SharedPreferences? prefs})
      : _dio = buildAuthedDio(baseUrl: baseUrl, prefs: prefs);

  final Dio _dio;

  // --- Client ---

  /// items: list of {product_id, variant_label, qty}.
  Future<OrderDto> createOrder({
    required String addressId,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'cash',
    String? comment,
    String? promoCode,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/orders', data: {
        'address_id': addressId,
        'items': items,
        'payment_method': paymentMethod,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      });
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<OrderDto>> listMyOrders() async {
    try {
      final res = await _dio.get<List<dynamic>>('/orders');
      return (res.data ?? const [])
          .map((e) => OrderDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> getOrder(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> cancelOrder(String id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/orders/$id/cancel');
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // --- Courier ---

  Future<CourierFeed> courierOrders() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/courier/orders');
      return CourierFeed.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> courierTake(String orderId) async {
    try {
      final res =
          await _dio.post<Map<String, dynamic>>('/courier/orders/$orderId/take');
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// status: in_transit | delivered
  Future<OrderDto> courierSetStatus(String orderId, String status) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/courier/orders/$orderId/status',
        data: {'status': status},
      );
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // --- Admin ops ---

  Future<List<OrderDto>> adminListOrders({String? status}) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/admin/orders',
        queryParameters: {if (status != null && status.isNotEmpty) 'status': status},
      );
      return (res.data ?? const [])
          .map((e) => OrderDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> adminGetOrder(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/admin/orders/$id');
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> adminSetStatus(String id, String status) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/orders/$id/status',
        data: {'status': status},
      );
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<OrderDto> adminAssignCourier(String orderId, String? courierId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/orders/$orderId/assign',
        data: {'courier_id': courierId},
      );
      return OrderDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<CourierDto>> adminListCouriers() async {
    try {
      final res = await _dio.get<List<dynamic>>('/admin/couriers');
      return (res.data ?? const [])
          .map((e) => CourierDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CourierDto> adminCreateCourier({
    required String phone,
    String? name,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/admin/couriers', data: {
        'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
        'password': password,
      });
      return CourierDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CourierDto> adminUpdateCourier(
    String id, {
    bool? isActive,
    String? name,
    String? password,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/admin/couriers/$id', data: {
        if (isActive != null) 'is_active': isActive,
        if (name != null) 'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
      });
      return CourierDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
