import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../../data/students/student_awards.dart';
import '../../data/students/student_profile.dart';
import '../../presentation/classification_quiz/data/classification_assets.dart';
import '../constants/course_assets.dart';
import '../widgets/quiz_answer_image.dart';
import 'persistent_network_image.dart';

/// Prefetches network images into Flutter's [ImageCache] before UI paint.
abstract final class NetworkImagePrecache {
  static const Duration defaultTimeout = Duration(seconds: 8);

  static bool isAvifUrl(String url) => url.toLowerCase().contains('.avif');

  static ImageProvider providerFor(
    String url, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    // AvifImage.network uses NetworkImage on web (native decoder).
    if (isAvifUrl(url) && !kIsWeb) {
      return NetworkAvifImage(url);
    }
    final ImageProvider base = NetworkImage(url);
    if (isAvifUrl(url)) {
      return base;
    }
    return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, base);
  }

  static Future<void> precacheUrl(
    BuildContext context,
    String url, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return precacheImage(
      providerFor(trimmed, cacheWidth: cacheWidth, cacheHeight: cacheHeight),
      context,
    ).then((_) {
      if (context.mounted) {
        PersistentNetworkImageCache.retain(context, trimmed);
      }
    });
  }

  /// Tries candidates in order; succeeds on the first that loads.
  static Future<void> precacheFirstAvailable(
    BuildContext context,
    List<String> urls, {
    int? cacheWidth,
    int? cacheHeight,
  }) async {
    for (final url in urls) {
      try {
        await precacheUrl(
          context,
          url,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );
        return;
      } catch (_) {
        // try next candidate
      }
    }
  }

  static Future<void> precacheAll(
    BuildContext context,
    Iterable<String> urls, {
    int? cacheWidth,
    int? cacheHeight,
    Duration timeout = defaultTimeout,
  }) async {
    final unique = <String>{
      for (final url in urls)
        if (url.trim().isNotEmpty) url.trim(),
    };
    if (unique.isEmpty) return;

    try {
      await Future.wait<void>(
        [
          for (final url in unique)
            precacheUrl(
              context,
              url,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
            ).then<void>((_) {}, onError: (_) {}),
        ],
      ).timeout(timeout);
    } on TimeoutException {
      // Show UI even if some images are still warming.
    }
  }

  static const localHomeAssets = [
    'assets/images/logo_prime.webp',
    'assets/images/logo_prime.png',
    'assets/images/icon_bell.png',
  ];

  static Future<void> precacheLocalAssets(BuildContext context) async {
    try {
      await Future.wait<void>([
        for (final path in localHomeAssets)
          precacheImage(AssetImage(path), context).then<void>(
            (_) {},
            onError: (_) {},
          ),
      ]).timeout(defaultTimeout);
    } on TimeoutException {
      // Continue even if a local asset is slow.
    }
  }

  /// Profile avatar + subject card icons/backgrounds used on home.
  static Future<void> precacheHomeVisuals(
    BuildContext context,
    StudentProfile profile, {
    Duration timeout = defaultTimeout,
  }) async {
    final backgroundUrls = <String>{};
    final iconUrls = <String>{};
    for (final course in profile.courses) {
      final visuals = CourseAssets.resolve(course.type);
      final bg = visuals.backgroundUrl;
      final icon = visuals.iconUrl;
      if (bg != null && bg.isNotEmpty) backgroundUrls.add(bg);
      if (icon != null && icon.isNotEmpty) iconUrls.add(icon);
    }

    try {
      await Future.wait<void>([
        // Avatar widgets do not pass cacheWidth/cacheHeight.
        precacheFirstAvailable(
          context,
          QuizAnswerImage.resolveCandidateUrls(profile.imageUrl),
        ),
        precacheAll(
          context,
          backgroundUrls,
          timeout: timeout,
        ),
        // Course icons are mostly AVIF (no ResizeImage in AvifImage.network).
        precacheAll(
          context,
          iconUrls,
          timeout: timeout,
        ),
      ]).timeout(timeout);
    } on TimeoutException {
      // Prefer showing home over waiting forever.
    }
  }

  static Future<void> precacheAwardAssets(
    BuildContext context,
    StudentAwards awards, {
    Duration timeout = defaultTimeout,
  }) async {
    final paths = <String>{
      ClassificationAssets.trophyEmptyImage,
      for (final level in awards.studentClassificationLevels)
        ClassificationAssets.characterImages[level.imageIndex.clamp(
          0,
          ClassificationAssets.characterImages.length - 1,
        )],
    };
    try {
      await Future.wait<void>([
        for (final path in paths)
          precacheImage(AssetImage(path), context).then<void>(
            (_) {},
            onError: (_) {},
          ),
      ]).timeout(timeout);
    } on TimeoutException {
      // Awards can still render while a character image finishes.
    }
  }
}
