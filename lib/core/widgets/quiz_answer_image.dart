import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../config/cdn_config.dart';
import '../theme/app_colors.dart';

class QuizAnswerImage extends StatelessWidget {
  const QuizAnswerImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.iconColor,
  });

  final String? imageUrl;
  final BoxFit fit;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final candidates = resolveCandidateUrls(imageUrl);
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    return _NetworkImageWithFallback(
      urls: candidates,
      fit: fit,
      iconColor: iconColor ?? AppColors.onDark.withValues(alpha: 0.35),
    );
  }

  static List<String> resolveCandidateUrls(String? raw) {
    if (raw == null) return const [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];

    final primary = _toLoadableUrl(trimmed);
    if (primary == null || primary.isEmpty) return const [];

    final urls = <String>[primary];

    final relative = _relativeMediaKey(trimmed) ??
        (primary.contains('cdn-media/')
            ? primary.split('cdn-media/').last
            : null);

    if (relative != null && relative.isNotEmpty) {

      if (kIsWeb && kDebugMode) {
        final directProd =
            'https://cdn.primeacademy.education/primeacademy/$relative';
        final directDev =
            'https://cdn-dev.primeacademy.education/primeacademydev/$relative';
        if (!urls.contains(directProd)) urls.add(directProd);
        if (!urls.contains(directDev)) urls.add(directDev);
      }
    }

    return urls;
  }

  static String? _relativeMediaKey(String path) {
    const knownPrefixes = [
      'https://cdn.primeacademy.education/primeacademy/',
      'https://cdn.primeacademy.education/primeacademy',
      'http://cdn.primeacademy.education/primeacademy/',
      'https://cdn-dev.primeacademy.education/primeacademydev/',
      'https://cdn-dev.primeacademy.education/primeacademydev',
      'http://127.0.0.1:8787/cdn-media/',
    ];

    var normalized = path;
    for (final prefix in knownPrefixes) {
      if (normalized.startsWith(prefix)) {
        normalized = normalized.substring(prefix.length);
        if (normalized.startsWith('/')) {
          normalized = normalized.substring(1);
        }
        return normalized;
      }
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return null;
    }
    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }

  static String? _toLoadableUrl(String path) {
    final relative = _relativeMediaKey(path);
    if (relative == null) {

      return path;
    }
    final resolved = CdnConfig.mediaUrl(relative);
    return resolved.isEmpty ? null : resolved;
  }
}

class _NetworkImageWithFallback extends StatefulWidget {
  const _NetworkImageWithFallback({
    required this.urls,
    required this.fit,
    required this.iconColor,
  });

  final List<String> urls;
  final BoxFit fit;
  final Color iconColor;

  @override
  State<_NetworkImageWithFallback> createState() =>
      _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<_NetworkImageWithFallback> {
  var _index = 0;

  @override
  void didUpdateWidget(covariant _NetworkImageWithFallback oldWidget) {
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
    final error = Icon(
      Icons.broken_image_outlined,
      color: widget.iconColor,
      size: 28,
    );

    if (url.toLowerCase().contains('.avif')) {
      return AvifImage.network(
        url,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) {
          if (_index < widget.urls.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tryNext();
            });
            return const SizedBox.shrink();
          }
          return error;
        },
      );
    }

    return Image.network(
      url,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,

      cacheWidth: widget.fit == BoxFit.cover ? null : 512,
      headers: const {
        'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.iconColor.withValues(alpha: 0.5),
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) {
        if (_index < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tryNext();
          });
          return const SizedBox.shrink();
        }
        return error;
      },
    );
  }
}
