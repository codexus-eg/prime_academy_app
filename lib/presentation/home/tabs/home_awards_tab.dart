import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/students/student_awards.dart';
import '../../../data/students/students_api.dart';
import '../models/award_carousel_item.dart';
import '../student_profile_scope.dart';
import '../widgets/award_badge_card.dart';
import '../widgets/awards_celebration_overlay.dart';

class HomeAwardsTab extends StatefulWidget {
  const HomeAwardsTab({super.key});

  @override
  State<HomeAwardsTab> createState() => _HomeAwardsTabState();
}

class _HomeAwardsTabState extends State<HomeAwardsTab> {
  var _loading = false;
  var _hasError = false;
  StudentAwards? _awards;
  var _showCelebration = false;
  var _celebrationPlayed = false;

  int? get _studentId => StudentProfileScope.maybeOf(context)?.profile?.id;

  List<AwardCarouselItem> get _carouselItems {
    final awards = _awards;
    if (awards == null) return const [];
    return buildAwardCarouselItems(awards);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAwards());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _studentId;
    if (id != null && _awards == null && !_loading && !_hasError) {
      _loadAwards();
    }
  }

  Future<void> _loadAwards() async {
    final studentId = _studentId;
    if (studentId == null) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final awards = await StudentsApi.fetchStudentAwards(studentId);
      if (!mounted) return;

      final shouldCelebrate = !_celebrationPlayed &&
          awards.studentClassificationLevels.isNotEmpty &&
          awards.hasAwards;

      setState(() {
        _awards = awards;
        _loading = false;
        if (shouldCelebrate) {
          _showCelebration = true;
          _celebrationPlayed = true;
        }
      });

      if (shouldCelebrate) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _showCelebration = false);
        });
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);

    if (scope?.profile == null && !_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: AppSpacing.profileTabContentPadding,
          child: Column(
            children: [
              if (_hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextButton(
                    onPressed: _loadAwards,
                    child: const Text('تعذّر تحميل الجوائز — إعادة المحاولة'),
                  ),
                ),
              AwardsPanel(
                items: _carouselItems,
                loading: _loading,
              ),
            ],
          ),
        ),
        if (_showCelebration && (_awards?.hasAwards ?? false))
          AwardsCelebrationOverlay(visible: _showCelebration),
      ],
    );
  }
}
