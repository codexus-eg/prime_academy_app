import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/students/testimonials_api.dart';

Future<void> showTestimonialDialog(
  BuildContext context, {
  required int courseId,
  VoidCallback? onSubmitted,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TestimonialDialog(
      courseId: courseId,
      onSubmitted: onSubmitted,
    ),
  );
}

class _TestimonialDialog extends StatefulWidget {
  const _TestimonialDialog({
    required this.courseId,
    this.onSubmitted,
  });

  final int courseId;
  final VoidCallback? onSubmitted;

  @override
  State<_TestimonialDialog> createState() => _TestimonialDialogState();
}

class _TestimonialDialogState extends State<_TestimonialDialog> {
  final _controller = TextEditingController();
  var _submitting = false;
  var _ignoring = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await TestimonialsApi.submit(
        courseId: widget.courseId,
        content: content,
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التقييم')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _ignore() async {
    if (_ignoring) return;
    setState(() => _ignoring = true);
    try {
      await TestimonialsApi.ignore(courseId: widget.courseId);
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
    } on ApiException {
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _ignoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      title: Text(
        'تقييم الكورس',
        style: AppTypography.bodyLg.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          maxLines: 6,
          enabled: !_submitting && !_ignoring,
          decoration: InputDecoration(
            hintText: 'اكتب تقييمك هنا',
            filled: true,
            fillColor: AppColors.mainBg2,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide.none,
            ),
          ),
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _ignoring ? null : _ignore,
          child: _ignoring
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting || _controller.text.trim().isEmpty
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }
}
