import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/cdn_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/web/web_media.dart';
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

  static const defaultAsset = 'assets/images/avatar_user.png';

  @override
  State<ProfileAvatarUploader> createState() => _ProfileAvatarUploaderState();
}

class _ProfileAvatarUploaderState extends State<ProfileAvatarUploader> {
  var _uploading = false;
  var _hovering = false;
  var _imageVersion = 0;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
    final resolvedAvatar = CdnConfig.mediaUrl(widget.avatarUrl);
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
                    _buildAvatar(resolvedAvatar, innerSize),
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

  Widget _buildAvatar(String resolvedAvatar, double innerSize) {
    if (resolvedAvatar.isNotEmpty) {
      return Image.network(
        resolvedAvatar,
        key: ValueKey('$resolvedAvatar-$_imageVersion'),
        fit: BoxFit.cover,
        width: innerSize,
        height: innerSize,
        errorBuilder: (_, _, _) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Image.asset(
      ProfileAvatarUploader.defaultAsset,
      fit: BoxFit.cover,
    );
  }

  Widget _buildOverlay() {
    final overlayOpacity = _uploading
        ? 1.0
        : _hovering
            ? 1.0
            : _isMobile
                ? 0.35
                : 0.0;

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
