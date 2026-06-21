import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../api/auth_dto.dart';
import '../api/orders_api.dart';
import '../providers.dart';

/// Persisted session: the authenticated user plus access/refresh tokens.
class SessionState {
  const SessionState({this.user, this.accessToken, this.refreshToken});

  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;

  bool get isLoggedIn => (accessToken ?? '').isNotEmpty && user != null;
  bool get isCourier => user?.isCourier ?? false;

  SessionState copyWith({AuthUser? user, String? accessToken, String? refreshToken}) =>
      SessionState(
        user: user ?? this.user,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  static const empty = SessionState();
}

/// Holds the session and persists it to shared_preferences. The access token is
/// stored under [kAuthAccessKey] so the dio interceptor reads the same value.
class SessionController extends StateNotifier<SessionState> {
  SessionController(this._prefs, this._auth) : super(SessionState.empty) {
    loadFromPrefs();
  }

  static const _refreshKey = 'auth_refresh';
  static const _userKey = 'auth_user';

  final SharedPreferences _prefs;
  final AuthApi _auth;

  String? get bearer => state.accessToken;

  /// Restore a previously persisted session at bootstrap.
  void loadFromPrefs() {
    final access = _prefs.getString(kAuthAccessKey);
    final refresh = _prefs.getString(_refreshKey);
    final userRaw = _prefs.getString(_userKey);
    if (access == null || userRaw == null) return;
    try {
      final user = AuthUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      state = SessionState(user: user, accessToken: access, refreshToken: refresh);
    } catch (_) {
      // Corrupt — start logged out.
    }
  }

  Future<void> _store(AuthResult result) async {
    await _prefs.setString(kAuthAccessKey, result.accessToken);
    await _prefs.setString(_refreshKey, result.refreshToken);
    await _prefs.setString(_userKey, jsonEncode(result.user.toJson()));
    state = SessionState(
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }

  /// Throws [ApiException] on failure.
  Future<AuthUser> loginWithPassword(String phone, String password) async {
    final result = await _auth.login(phone: phone, password: password);
    await _store(result);
    return result.user;
  }

  /// Throws [ApiException] on failure.
  Future<AuthUser> register(String phone, String password, {String? name}) async {
    final result = await _auth.register(phone: phone, password: password, name: name);
    await _store(result);
    return result.user;
  }

  /// Replace the cached user (e.g. after PATCH /auth/me).
  Future<void> updateUser(AuthUser user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _prefs.remove(kAuthAccessKey);
    await _prefs.remove(_refreshKey);
    await _prefs.remove(_userKey);
    state = SessionState.empty;
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(prefs: ref.read(sharedPrefsProvider)),
);

final ordersApiProvider = Provider<OrdersApi>(
  (ref) => OrdersApi(prefs: ref.read(sharedPrefsProvider)),
);

final sessionProvider = StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(
    ref.read(sharedPrefsProvider),
    ref.read(authApiProvider),
  ),
);

/// Current user's orders. Watch the session so it refreshes on login/logout.
final myOrdersProvider = FutureProvider<List<OrderDto>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return const [];
  return ref.read(ordersApiProvider).listMyOrders();
});

/// Current user's saved delivery addresses.
final myAddressesProvider = FutureProvider<List<AddressDto>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) return const [];
  return ref.read(authApiProvider).listAddresses();
});
