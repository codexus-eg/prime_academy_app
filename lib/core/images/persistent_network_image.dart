import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../theme/app_colors.dart';
import 'network_image_precache.dart';

/// Keeps decoded course/home images alive after widgets dispose, so returning
/// to المواد shows them immediately instead of refetching.
abstract final class PersistentNetworkImageCache {
  static final _decoded = <String, ui.Image>{};
  static final _listeners = <String, ImageStreamListener>{};
  static final _streams = <String, ImageStream>{};
  static final _tick = ValueNotifier<int>(0);

  static ui.Image? decoded(String url) => _decoded[url];

  static void addListener(VoidCallback listener) => _tick.addListener(listener);

  static void removeListener(VoidCallback listener) =>
      _tick.removeListener(listener);

  static void _notify() => _tick.value++;

  static void retain(BuildContext context, String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _listeners.containsKey(trimmed)) return;

    final cache = PaintingBinding.instance.imageCache;
    if (cache.maximumSizeBytes < 200 << 20) {
      cache.maximumSizeBytes = 200 << 20;
    }

    final provider = NetworkImagePrecache.providerFor(trimmed);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        if (_decoded.containsKey(trimmed)) return;
        _decoded[trimmed] = info.image.clone();
        _notify();
      },
      onError: (_, _) {},
    );
    stream.addListener(listener);
    _listeners[trimmed] = listener;
    _streams[trimmed] = stream;
  }

  static void clear() {
    for (final entry in _streams.entries) {
      final listener = _listeners[entry.key];
      if (listener != null) {
        entry.value.removeListener(listener);
      }
    }
    for (final image in _decoded.values) {
      image.dispose();
    }
    _decoded.clear();
    _listeners.clear();
    _streams.clear();
    _notify();
  }
}

class PersistentNetworkImage extends StatefulWidget {
  const PersistentNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  State<PersistentNetworkImage> createState() => _PersistentNetworkImageState();
}

class _PersistentNetworkImageState extends State<PersistentNetworkImage> {
  @override
  void initState() {
    super.initState();
    PersistentNetworkImageCache.addListener(_onCacheChanged);
  }

  @override
  void dispose() {
    PersistentNetworkImageCache.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final url = widget.url?.trim();
    if (url != null && url.isNotEmpty) {
      PersistentNetworkImageCache.retain(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url?.trim();
    if (url == null || url.isEmpty) {
      return const ColoredBox(color: AppColors.courseCardImageFallback);
    }

    final decoded = PersistentNetworkImageCache.decoded(url);
    if (decoded != null) {
      return RawImage(
        image: decoded,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: FilterQuality.high,
      );
    }

    final provider = NetworkImagePrecache.providerFor(url);

    if (provider is NetworkAvifImage) {
      return AvifImage(
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        frameBuilder: _frameBuilder,
        errorBuilder: _errorBuilder,
      );
    }

    return Image(
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      frameBuilder: _frameBuilder,
      errorBuilder: _errorBuilder,
    );
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || frame != null) return child;
    return const ColoredBox(color: AppColors.courseCardImageFallback);
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const ColoredBox(color: AppColors.courseCardImageFallback);
  }
}
