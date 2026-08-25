import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/web/web_media.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../data/upload/upload_api.dart';
import '../../../data/upload/upload_mime.dart';
import '../../../data/users/users_api.dart';

class ProfileAvatarUploader extends StatefulWidget {
  const ProfileAvatarUploader({
    super.key,
    this.avatarUrl,
    this.size = AppSpacing.profileAvatarSize,
    this.onUploaded,
  });

  final String? avatarUrl;
  final double size;
  final Future<void> Function()? onUploaded;

  /// Web `PiStudentFill` used when the student has no uploaded photo.
  static const defaultAsset = 'assets/icons/profile/student_fill.svg';

  @override
  State<ProfileAvatarUploader> createState() => _ProfileAvatarUploaderState();
}

class _ProfileAvatarUploaderState extends State<ProfileAvatarUploader> {
  var _uploading = false;
  var _hovering = false;
  var _imageVersion = 0;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;

    final picked = await pickWebFile(accept: 'image/jpeg,image/png,image/webp');
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final mimeType = UploadMime.normalizeProfileImageMime(
        mimeType: picked.mimeType,
        filename: picked.name,
      );
      if (!UploadMime.isSupportedProfileImageMime(mimeType)) {
        throw ApiException('نوع الملف غير مدعوم');
      }

      final uploadName = _profileUploadFilename(picked.name, mimeType);
      final presigned = await UploadApi.getPresignedUrlForProfileImage(
        mimeType: picked.mimeType,
        filename: uploadName,
      );
      await UploadApi.uploadBytes(
        url: presigned.url,
        bytes: picked.bytes,
        contentType: mimeType,
      );
      await UploadApi.registerAttachmentUpload(presigned.key);
      await UsersApi.uploadProfileImage(
        ChatMediaUpload(
          key: presigned.key,
          name: uploadName,
          size: picked.bytes.length,
          mimeType: mimeType,
        ),
      );
      if (!mounted) return;
      setState(() => _imageVersion++);
      await widget.onUploaded?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الصورة')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر رفع الصورة')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _profileUploadFilename(String originalName, String mimeType) {
    var name = originalName.trim();
    if (name.isEmpty) name = 'profile';

    if (mimeType != 'image/jpeg') return name;

    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return name;

    final dot = name.lastIndexOf('.');
    if (dot > 0) {
      return '${name.substring(0, dot)}.jpg';
    }
    return '$name.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final innerSize = widget.size - (AppSpacing.xs * 2);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickAndUpload,
          customBorder: const CircleBorder(),
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.profileRing,
              boxShadow: AppShadows.profileRing,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.profileInner,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAvatar(innerSize),
                    _buildOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double innerSize) {
    final candidates = QuizAnswerImage.resolveCandidateUrls(widget.avatarUrl);
    if (candidates.isEmpty) return _defaultAvatar();

    return _AvatarNetworkImage(
      key: ValueKey('${widget.avatarUrl}-$_imageVersion'),
      urls: candidates,
      size: innerSize,
      fallback: _defaultAvatar(),
    );
  }

  Widget _defaultAvatar() {
    return ColoredBox(
      color: AppColors.mainBg2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: SvgPicture.asset(
          ProfileAvatarUploader.defaultAsset,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            AppColors.courseTitleGradientStart,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final overlayOpacity = _uploading || _hovering ? 1.0 : 0.0;

    return AnimatedOpacity(
      opacity: overlayOpacity,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Center(
          child: _uploading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

class _AvatarNetworkImage extends StatefulWidget {
  const _AvatarNetworkImage({
    super.key,
    required this.urls,
    required this.size,
    required this.fallback,
  });

  final List<String> urls;
  final double size;
  final Widget fallback;

  @override
  State<_AvatarNetworkImage> createState() => _AvatarNetworkImageState();
}

class _AvatarNetworkImageState extends State<_AvatarNetworkImage> {
  var _index = 0;

  @override
  void didUpdateWidget(covariant _AvatarNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.urls, widget.urls)) {
      _index = 0;
    }
  }

  void _tryNext() {
    if (_index >= widget.urls.length - 1) return;
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urls[_index.clamp(0, widget.urls.length - 1)];

    void onError() {
      if (_index < widget.urls.length - 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryNext();
        });
      }
    }

    if (url.toLowerCase().contains('.avif')) {
      return AvifImage.network(
        url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) {
          onError();
          if (_index >= widget.urls.length - 1) return widget.fallback;
          return const SizedBox.shrink();
        },
      );
    }

    return Image.network(
      url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) {
        onError();
        if (_index >= widget.urls.length - 1) return widget.fallback;
        return const SizedBox.shrink();
      },
    );
  }
}
