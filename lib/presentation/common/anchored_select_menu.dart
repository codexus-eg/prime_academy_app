import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

class AnchoredSelectOption<T> {
  const AnchoredSelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Web Radix `SelectContent` (`position="popper"`): menu opens next to the
/// trigger instead of a bottom sheet at the end of the page.
Future<T?> showAnchoredSelectMenu<T>({
  required BuildContext triggerContext,
  required List<AnchoredSelectOption<T>> options,
  T? selected,
}) {
  final box = triggerContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    return Future<T?>.value(null);
  }

  final origin = box.localToGlobal(Offset.zero);
  final triggerSize = box.size;

  return showGeneralDialog<T>(
    context: triggerContext,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(triggerContext).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AnchoredSelectPage<T>(
        origin: origin,
        triggerSize: triggerSize,
        options: options,
        selected: selected,
        animation: animation,
      );
    },
  );
}

class _AnchoredSelectPage<T> extends StatelessWidget {
  const _AnchoredSelectPage({
    required this.origin,
    required this.triggerSize,
    required this.options,
    required this.selected,
    required this.animation,
  });

  final Offset origin;
  final Size triggerSize;
  final List<AnchoredSelectOption<T>> options;
  final T? selected;
  final Animation<double> animation;

  static const _gap = 4.0;
  static const _maxHeight = 384.0;
  static const _itemExtent = 40.0;
  static const _viewportPadding = 4.0;
  static const _screenPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final contentHeight =
        options.length * _itemExtent + _viewportPadding * 2;
    final spaceBelow =
        screen.height - origin.dy - triggerSize.height - _screenPadding;
    final spaceAbove = origin.dy - _screenPadding;
    final openBelow = spaceBelow >= 96 || spaceBelow >= spaceAbove;

    var height = math.min(contentHeight, _maxHeight);
    height = math.min(height, openBelow ? spaceBelow : spaceAbove);
    height = math.max(height, math.min(contentHeight, 48));

    final top = (openBelow
            ? origin.dy + triggerSize.height + _gap
            : origin.dy - _gap - height)
        .clamp(
          _screenPadding,
          math.max(_screenPadding, screen.height - height - _screenPadding),
        )
        .toDouble();
    final left = origin.dx
        .clamp(
          _screenPadding,
          math.max(
            _screenPadding,
            screen.width - triggerSize.width - _screenPadding,
          ),
        )
        .toDouble();

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: triggerSize.width,
            height: height,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                alignment: openBelow ? Alignment.topCenter : Alignment.bottomCenter,
                scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.mainBg2,
                    borderRadius: AppRadius.borderInput,
                    border: Border.all(color: AppColors.overlayWhite6),
                    boxShadow: AppShadows.xl,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.borderInput,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(_viewportPadding),
                      itemExtent: _itemExtent,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _SelectItem(
                          label: option.label,
                          selected: option.value == selected,
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectItem extends StatefulWidget {
  const _SelectItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SelectItem> createState() => _SelectItemState();
}

class _SelectItemState extends State<_SelectItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = _hovered || widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: highlight ? AppGradients.selectItemHover : null,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: AppTypography.filterLabel.copyWith(
                    color: AppColors.onDark,
                    fontSize: 16.8,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
