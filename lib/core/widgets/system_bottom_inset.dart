import 'package:flutter/material.dart';

/// Resolves the device's bottom system inset (3-button nav / gesture bar /
/// iOS home indicator) without relying on fixed pixel values.
///
/// Prefer [viewPadding] over [padding]: a parent [SafeArea] may already have
/// consumed [MediaQuery.padding], while [viewPadding] always reflects the
/// raw system inset.
abstract final class SystemBottomInset {
  static double of(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  /// Bottom padding = system inset + optional extra (e.g. docked bar height).
  static EdgeInsets paddingOf(
    BuildContext context, {
    double extra = 0,
  }) =>
      EdgeInsets.only(bottom: of(context) + extra);

  /// Clearance for scrollable content sitting above a docked bottom bar.
  static double contentClearanceOf(
    BuildContext context, {
    required double barContentHeight,
  }) =>
      barContentHeight + of(context);
}

/// Docks [child] above the system navigation area.
///
/// When [extendBackgroundIntoInset] is true and [backgroundColor] is set, the
/// color fills the unsafe inset so the bar looks continuous behind the
/// system buttons, while interactive content stays in the safe region.
class BottomDockedSafeArea extends StatelessWidget {
  const BottomDockedSafeArea({
    super.key,
    required this.child,
    this.backgroundColor,
    this.extendBackgroundIntoInset = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final bool extendBackgroundIntoInset;

  @override
  Widget build(BuildContext context) {
    final inset = SystemBottomInset.of(context);
    if (inset <= 0) return child;

    final padded = Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: child,
    );

    if (!extendBackgroundIntoInset || backgroundColor == null) {
      return padded;
    }

    return ColoredBox(
      color: backgroundColor!,
      child: padded,
    );
  }
}
