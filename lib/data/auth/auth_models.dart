import 'auth_session.dart';

class LinkedAccount {
  const LinkedAccount({
    required this.id,
    required this.name,
    this.role,
    this.imageUrl,
  });

  final int id;
  final String name;
  final int? role;
  final String? imageUrl;

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];

    return LinkedAccount(
      id: id is int ? id : int.parse(id.toString()),
      name: json['name'] as String? ?? '',
      role: role is int ? role : int.tryParse(role?.toString() ?? ''),
      imageUrl: json['image_url'] as String?,
    );
  }
}

sealed class LoginOutcome {
  const LoginOutcome();
}

final class LoginSuccess extends LoginOutcome {
  const LoginSuccess(this.user);

  final AuthUser user;
}

final class LoginRequiresSelection extends LoginOutcome {
  const LoginRequiresSelection({
    required this.selectionToken,
    required this.accounts,
  });

  final String selectionToken;
  final List<LinkedAccount> accounts;
}
