import '../../../data/students/student_awards.dart';

sealed class AwardCarouselItem {
  const AwardCarouselItem();
}

class AwardLevelCarouselItem extends AwardCarouselItem {
  const AwardLevelCarouselItem({
    required this.level,
    required this.count,
  });

  final StudentAwardLevel level;
  final int count;
}

class AwardCertificateCarouselItem extends AwardCarouselItem {
  const AwardCertificateCarouselItem({
    required this.templateIndex,
    required this.certificates,
  });

  final int templateIndex;
  final List<StudentAwardCertificate> certificates;
}

List<AwardCarouselItem> buildAwardCarouselItems(StudentAwards awards) {
  final items = <AwardCarouselItem>[];

  final levelGroups = <String, ({StudentAwardLevel level, int count})>{};
  for (final entry in awards.studentClassificationLevels) {
    final key = '${entry.title}-${entry.imageIndex}';
    final existing = levelGroups[key];
    if (existing == null) {
      levelGroups[key] = (level: entry, count: 1);
    } else {
      levelGroups[key] = (level: existing.level, count: existing.count + 1);
    }
  }

  for (final group in levelGroups.values) {
    items.add(
      AwardLevelCarouselItem(level: group.level, count: group.count),
    );
  }

  final certGroups = <int, List<StudentAwardCertificate>>{};
  for (final cert in awards.certificates) {
    certGroups.putIfAbsent(cert.templateIndex, () => []).add(cert);
  }

  for (final entry in certGroups.entries) {
    items.add(
      AwardCertificateCarouselItem(
        templateIndex: entry.key,
        certificates: entry.value,
      ),
    );
  }

  return items;
}

String formatAwardCount(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return count.toString();
}
