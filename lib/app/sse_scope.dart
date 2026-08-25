import 'package:flutter/material.dart';

import '../../data/sse/sse_event_handlers.dart';
import '../../data/sse/sse_service.dart';
import '../../presentation/auth/login_page.dart';
import '../../router/app_router.dart';

class SseScope extends StatefulWidget {
  const SseScope({super.key, required this.child});

  final Widget child;

  @override
  State<SseScope> createState() => _SseScopeState();
}

class _SseScopeState extends State<SseScope> {
  @override
  void initState() {
    super.initState();
    SseEventHandlers.currentUri = () {
      try {
        return appRouter.routerDelegate.currentConfiguration.uri;
      } catch (_) {
        return null;
      }
    };
    SseEventHandlers.onInvalidToken = () {
      appRouter.go(LoginPage.routePath);
    };
    SseService.instance.connect();
  }

  @override
  void dispose() {
    SseEventHandlers.currentUri = null;
    SseEventHandlers.onInvalidToken = null;
    SseService.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
