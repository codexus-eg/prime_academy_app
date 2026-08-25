import 'dart:convert';

import 'auth_token_storage.dart';
import 'jwt_utils.dart';
import '../../core/images/persistent_network_image.dart';
import '../students/student_awards_cache.dart';
import '../students/student_profile_cache.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.token,
    this.email,
    this.role,
  });

  final int id;
  final String name;
  final String token;
  final String? email;
  final int? role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];

    return AuthUser(
      id: id is int ? id : int.parse(id.toString()),
      name: json['name'] as String? ?? '',
      token: json['token'] as String,
      email: json['email'] as String?,
      role: role is int ? role : int.tryParse(role?.toString() ?? ''),
    );
  }

  AuthUser copyWith({String? token}) {
    return AuthUser(
      id: id,
      name: name,
      token: token ?? this.token,
      email: email,
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'token': token,
        'email': email,
        'role': role,
      };
}

abstract final class AuthSession {
  static Future<void> save(
    AuthUser user, {
    String? refreshToken,
  }) async {
    await AuthTokenStorage.writeUser(jsonEncode(user.toJson()));
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await AuthTokenStorage.writeRefreshToken(refreshToken);
    }
  }

  static Future<AuthUser?> load() async {
    final raw = await AuthTokenStorage.readUser();
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> loadRefreshToken() {
    return AuthTokenStorage.readRefreshToken();
  }

  static Future<void> clear() {
    StudentProfileCache.clear();
    StudentAwardsCache.clear();
    PersistentNetworkImageCache.clear();
    return AuthTokenStorage.clear();
  }

  static Future<bool> isRestorable() async {
    final user = await load();
    if (user == null) return false;

    final refreshToken = await loadRefreshToken();
    if (refreshToken != null &&
        refreshToken.isNotEmpty &&
        !JwtUtils.isExpired(refreshToken)) {
      return true;
    }

    return !JwtUtils.isExpired(user.token);
  }

  static Future<DateTime?> sessionExpiresAt() async {
    final user = await load();
    if (user == null) return null;

    final refreshToken = await loadRefreshToken();
    final refreshExp = refreshToken == null
        ? null
        : JwtUtils.expirationDate(refreshToken);
    final accessExp = JwtUtils.expirationDate(user.token);

    if (refreshExp == null) return accessExp;
    if (accessExp == null) return refreshExp;
    return refreshExp.isAfter(accessExp) ? refreshExp : accessExp;
  }
}
