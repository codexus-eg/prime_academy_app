import 'package:flutter/widgets.dart';

import '../../core/images/network_image_precache.dart';
import 'student_awards_cache.dart';
import 'student_profile_cache.dart';
import 'students_api.dart';

/// Loads profile, course images, and awards before Home is shown.
abstract final class HomeBootstrap {
  static Future<void> warm(BuildContext context) async {
    await NetworkImagePrecache.precacheLocalAssets(context);
    if (!context.mounted) return;

    final profile = await StudentsApi.fetchMyProfile();
    if (!context.mounted) return;

    await NetworkImagePrecache.precacheHomeVisuals(context, profile);
    StudentProfileCache.store(profile, visualsReady: true);
    if (!context.mounted) return;

    try {
      final awards = await StudentsApi.fetchStudentAwards(profile.id);
      StudentAwardsCache.store(awards);
      if (!context.mounted) return;
      await NetworkImagePrecache.precacheAwardAssets(context, awards);
    } catch (_) {
      // Awards tab will fetch if splash warmup fails.
    }
  }
}
