import '../money/money.dart';

/// Authenticated user, mirrors backend `UserRead`.
class AuthUser {
  AuthUser({
    required this.id,
    this.phone,
    this.email,
    this.name,
    this.avatarUrl,
    required this.role,
    required this.locale,
    required this.isActive,
  });

  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final String role; // client | courier | admin
  final String locale;
  final bool isActive;

  bool get isCourier => role == 'courier';

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        name: j['name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        role: (j['role'] as String?) ?? 'client',
        locale: (j['locale'] as String?) ?? 'ru',
        isActive: (j['is_active'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'role': role,
        'locale': locale,
        'is_active': isActive,
      };
}

/// Result of register/login/refresh — tokens + the user.
class AuthResult {
  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
        tokenType: (j['token_type'] as String?) ?? 'bearer',
        user: AuthUser.fromJson(Map<String, dynamic>.from(j['user'] as Map)),
      );
}

/// Delivery address, mirrors backend `AddressRead`.
class AddressDto {
  AddressDto({
    required this.id,
    required this.label,
    required this.street,
    this.building,
    this.apt,
    this.entrance,
    this.floor,
    this.comment,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  final String id;
  final String label; // home | work | custom
  final String street;
  final String? building;
  final String? apt;
  final String? entrance;
  final String? floor;
  final String? comment;
  final double lat;
  final double lng;
  final bool isDefault;

  /// Single-line human-readable rendering for tiles.
  String get oneLine {
    final parts = <String>[street];
    if ((building ?? '').isNotEmpty) parts.add('д. $building');
    if ((apt ?? '').isNotEmpty) parts.add('кв. $apt');
    if ((floor ?? '').isNotEmpty) parts.add('${floor!} эт.');
    return parts.join(', ');
  }

  factory AddressDto.fromJson(Map<String, dynamic> j) => AddressDto(
        id: j['id'] as String,
        label: (j['label'] as String?) ?? 'home',
        street: (j['street'] as String?) ?? '',
        building: j['building'] as String?,
        apt: j['apt'] as String?,
        entrance: j['entrance'] as String?,
        floor: j['floor'] as String?,
        comment: j['comment'] as String?,
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        isDefault: (j['is_default'] as bool?) ?? false,
      );
}

/// Lightweight client/courier summary embedded in ops order views.
class PartyDto {
  PartyDto({this.id, this.name, this.phone});
  final String? id;
  final String? name;
  final String? phone;

  factory PartyDto.fromJson(Map<String, dynamic> j) => PartyDto(
        id: j['id'] as String?,
        name: j['name'] as String?,
        phone: j['phone'] as String?,
      );
}

/// One line in an order, mirrors backend `OrderItemRead`.
class OrderItemDto {
  OrderItemDto({
    required this.productId,
    required this.variantLabel,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });

  final String productId;
  final String variantLabel;
  final int qty;
  final Money unitPrice;
  final Money total;

  factory OrderItemDto.fromJson(Map<String, dynamic> j) => OrderItemDto(
        productId: j['product_id'] as String,
        variantLabel: (j['variant_label'] as String?) ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        unitPrice: Money((j['unit_price_minor'] as num?)?.toInt() ?? 0),
        total: Money((j['total_minor'] as num?)?.toInt() ?? 0),
      );
}

/// Order — covers both client (`OrderRead`) and ops (`OrderOpsRead`) shapes.
class OrderDto {
  OrderDto({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.promoCode,
    this.comment,
    required this.items,
    this.createdAt,
    this.client,
    this.courier,
    this.address,
  });

  final String id;
  final String code;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final Money subtotal;
  final Money deliveryFee;
  final Money discount;
  final Money total;
  final String? promoCode;
  final String? comment;
  final List<OrderItemDto> items;
  final DateTime? createdAt;
  // Ops-only fields:
  final PartyDto? client;
  final PartyDto? courier;
  final AddressDto? address;

  int get totalQty => items.fold(0, (a, b) => a + b.qty);

  factory OrderDto.fromJson(Map<String, dynamic> j) => OrderDto(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'pending',
        paymentMethod: (j['payment_method'] as String?) ?? 'cash',
        paymentStatus: (j['payment_status'] as String?) ?? 'pending',
        subtotal: Money((j['subtotal_minor'] as num?)?.toInt() ?? 0),
        deliveryFee: Money((j['delivery_fee_minor'] as num?)?.toInt() ?? 0),
        discount: Money((j['discount_minor'] as num?)?.toInt() ?? 0),
        total: Money((j['total_minor'] as num?)?.toInt() ?? 0),
        promoCode: j['promo_code'] as String?,
        comment: j['comment'] as String?,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => OrderItemDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        client: j['client'] != null
            ? PartyDto.fromJson(Map<String, dynamic>.from(j['client'] as Map))
            : null,
        courier: j['courier'] != null
            ? PartyDto.fromJson(Map<String, dynamic>.from(j['courier'] as Map))
            : null,
        address: j['address'] != null
            ? AddressDto.fromJson(Map<String, dynamic>.from(j['address'] as Map))
            : null,
      );
}

/// Courier order feed, mirrors backend `CourierOrders`.
class CourierFeed {
  CourierFeed({
    required this.available,
    required this.mine,
    required this.done,
  });

  final List<OrderDto> available;
  final List<OrderDto> mine;
  final List<OrderDto> done;

  factory CourierFeed.fromJson(Map<String, dynamic> j) {
    List<OrderDto> parse(String key) => ((j[key] as List?) ?? const [])
        .map((e) => OrderDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CourierFeed(
      available: parse('available'),
      mine: parse('mine'),
      done: parse('done'),
    );
  }
}

/// Courier as seen by admin, mirrors backend `CourierRead`.
class CourierDto {
  CourierDto({
    required this.id,
    this.phone,
    this.name,
    required this.isActive,
    required this.activeOrders,
  });

  final String id;
  final String? phone;
  final String? name;
  final bool isActive;
  final int activeOrders;

  factory CourierDto.fromJson(Map<String, dynamic> j) => CourierDto(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        name: j['name'] as String?,
        isActive: (j['is_active'] as bool?) ?? true,
        activeOrders: (j['active_orders'] as num?)?.toInt() ?? 0,
      );
}
