import 'dart:convert';

import '../../core/images/persistent_network_image.dart';
import '../courses/lesson_page_cache.dart';
import '../students/student_awards_cache.dart';
import '../students/student_profile_cache.dart';
import 'auth_state_notifier.dart';
import 'auth_token_storage.dart';
import 'jwt_utils.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.token,
    this.email,
    this.role,
    this.canSwitch = false,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String token;
  final String? email;
  final int? role;
  final bool canSwitch;
  final String? imageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];

    return AuthUser(
      id: id is int ? id : int.parse(id.toString()),
      name: json['name'] as String? ?? '',
      token: json['token'] as String,
      email: json['email'] as String?,
      role: role is int ? role : int.tryParse(role?.toString() ?? ''),
      canSwitch: _parseCanSwitch(json['can_switch']),
      imageUrl: json['image_url'] as String?,
    );
  }

  AuthUser copyWith({
    String? token,
    String? name,
    bool? canSwitch,
    String? imageUrl,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      token: token ?? this.token,
      email: email,
      role: role,
      canSwitch: canSwitch ?? this.canSwitch,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'token': token,
        'email': email,
        'role': role,
        'can_switch': canSwitch,
        'image_url': imageUrl,
      };

  static bool _parseCanSwitch(dynamic value) {
    if (value == true || value == 1 || value == '1' || value == 'true') {
      return true;
    }
    return false;
  }
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
    AuthStateNotifier.onChanged?.call(user);
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

  static void clearAccountCaches() {
    StudentProfileCache.clear();
    StudentAwardsCache.clear();
    PersistentNetworkImageCache.clear();
    LessonPageCache.clear();
  }

  static Future<void> replaceUser(
    AuthUser user, {
    String? refreshToken,
  }) async {
    clearAccountCaches();
    await save(user, refreshToken: refreshToken);
  }

  static Future<void> clear() {
    clearAccountCaches();
    AuthStateNotifier.onChanged?.call(null);
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
