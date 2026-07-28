import 'package:flutter/material.dart';

import '../../data/sse/sse_service.dart';

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
    SseService.instance.connect();
  }

  @override
  void dispose() {
    SseService.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
