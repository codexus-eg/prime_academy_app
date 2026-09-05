import 'package:flutter/widgets.dart';

import '../data/auth/auth_controller.dart';

/// Hydrates [AuthController] once at startup so navigation chrome can react to
/// auth state without flicker.
class AuthScope extends StatefulWidget {
  const AuthScope({super.key, required this.child});

  final Widget child;

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> {
  @override
  void initState() {
    super.initState();
    AuthController.instance.hydrate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
