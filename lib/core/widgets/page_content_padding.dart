import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class PageContentPadding extends StatelessWidget {
  const PageContentPadding({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
    this.padding,
  });

  final Widget child;
  final double top;
  final double bottom;
  final EdgeInsetsDirectional? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsetsDirectional.fromSTEB(
            AppSpacing.pageContentHorizontal,
            top,
            AppSpacing.pageContentHorizontal,
            bottom,
          ),
      child: child,
    );
  }
}
