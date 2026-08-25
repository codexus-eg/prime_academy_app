import '../../core/config/api_config.dart';
import '../../core/config/cdn_config.dart';
import '../../core/utils/video_source.dart';
import '../quizzes/quiz_models.dart';
import 'module_material.dart';

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value);
  return parsed == 0 ? null : parsed;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class UserCourse {
  const UserCourse({
    required this.id,
    required this.title,
    required this.isEnrolled,
    required this.modules,
    this.description,
  });

  final int id;
  final String title;
  final String? description;
  final bool isEnrolled;
  final List<UserCourseModule> modules;

  factory UserCourse.fromJson(Map<String, dynamic> json) {
    final modulesJson = json['modules'];
    final modules = modulesJson is List
        ? modulesJson
            .whereType<Map<String, dynamic>>()
            .map(UserCourseModule.fromJson)
            .toList()
        : <UserCourseModule>[];

    return UserCourse(
      id: _asInt(json['id']),

      title: (json['title'] ?? json['name'] ?? '') as String,
      description: json['description'] as String?,
      isEnrolled: json['isEnrolled'] == true,
      modules: modules,
    );
  }
}

class UserCourseModule {
  const UserCourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.color,
    required this.special,
    required this.items,
    this.description,
  });

  final int id;
  final int courseId;
  final String title;

  final String color;
  final bool special;
  final String? description;
  final List<UserModuleItem> items;

  factory UserCourseModule.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = itemsJson is List
        ? itemsJson
            .whereType<Map<String, dynamic>>()
            .map(UserModuleItem.fromJson)
            .toList()
        : <UserModuleItem>[];

    return UserCourseModule(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      title: (json['title'] ?? json['name'] ?? '') as String,
      color: (json['color'] as String? ?? 'DEFAULT').toUpperCase(),
      special: json['special'] == true,
      description: json['description'] as String?,
      items: items,
    );
  }
}

enum ModuleItemType { lesson, quiz, externalSource, unknown }

class UserModuleItem {
  const UserModuleItem({
    required this.id,
    required this.order,
    required this.type,
    this.lesson,
    this.quiz,
    this.externalSource,
  });

  final int id;
  final int order;
  final ModuleItemType type;
  final UserModuleLesson? lesson;
  final UserModuleQuiz? quiz;
  final UserModuleExternalSource? externalSource;

  factory UserModuleItem.fromJson(Map<String, dynamic> json) {
    final lessonJson = json['lesson'];
    final quizJson = json['quiz'];
    final externalJson = json['external_source'];

    final lesson = lessonJson is Map<String, dynamic>
        ? UserModuleLesson.fromJson(lessonJson)
        : null;
    final quiz =
        quizJson is Map<String, dynamic> ? UserModuleQuiz.fromJson(quizJson) : null;
    final external = externalJson is Map<String, dynamic>
        ? UserModuleExternalSource.fromJson(externalJson)
        : null;

    final type = switch (json['item_type']) {
      'lesson' => ModuleItemType.lesson,
      'quiz' => ModuleItemType.quiz,
      'external_source' => ModuleItemType.externalSource,
      _ => lesson != null
          ? ModuleItemType.lesson
          : quiz != null
              ? ModuleItemType.quiz
              : external != null
                  ? ModuleItemType.externalSource
                  : ModuleItemType.unknown,
    };

    return UserModuleItem(
      id: _asInt(json['id']),
      order: _asInt(json['order']),
      type: type,
      lesson: lesson,
      quiz: quiz,
      externalSource: external,
    );
  }
}

class UserModuleLesson {
  const UserModuleLesson({
    required this.id,
    required this.title,
    required this.videoLength,
    required this.accessWithoutEnrollment,
    required this.watched,
    required this.hasTrophy,
    this.lastPosition,
    this.duration,
    this.externalUrl,
  });

  final int id;
  final String title;
  final int videoLength;
  final bool accessWithoutEnrollment;
  final bool watched;
  final bool hasTrophy;
  final int? lastPosition;
  final int? duration;
  final String? externalUrl;

  factory UserModuleLesson.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    return UserModuleLesson(
      id: _asInt(json['id']),
      title: (json['title'] as String? ?? ''),
      videoLength: _asInt(json['video_length']),
      accessWithoutEnrollment: json['access_without_enrollment'] == true,
      watched: json['watched'] == true,
      hasTrophy: json['hasTrophy'] == true,
      lastPosition:
          progress is Map<String, dynamic> ? _asInt(progress['last_position']) : null,
      duration:
          progress is Map<String, dynamic> ? _asInt(progress['duration']) : null,
      externalUrl: json['external_url'] as String?,
    );
  }
}

class ModuleTeacher {
  const ModuleTeacher({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? imageUrl;

  factory ModuleTeacher.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'];
    String? rawUrl;
    if (image is String) {
      rawUrl = image;
    } else {
      final imageMap = _asMap(image);
      final nested = imageMap?['url'];
      if (nested is String) rawUrl = nested;
    }
    return ModuleTeacher(
      id: _asInt(json['id']),
      name: (json['name'] as String? ?? ''),
      imageUrl: rawUrl != null && rawUrl.isNotEmpty
          ? ApiConfig.mediaUrl(rawUrl)
          : null,
    );
  }
}

class UserModuleItems {
  const UserModuleItems({
    required this.id,
    required this.courseId,
    required this.title,
    required this.isEnrolled,
    required this.items,
    this.materials = const [],
    this.teacher,
  });

  final int id;
  final int courseId;
  final String title;
  final bool isEnrolled;
  final List<UserModuleItem> items;

  final List<ModuleMaterial> materials;
  final ModuleTeacher? teacher;

  factory UserModuleItems.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = itemsJson is List
        ? itemsJson
            .whereType<Map<String, dynamic>>()
            .map(UserModuleItem.fromJson)
            .toList()
        : <UserModuleItem>[];

    final materialsJson = json['materials'];
    final materials = materialsJson is List
        ? materialsJson
            .whereType<Map<String, dynamic>>()
            .map(ModuleMaterial.fromJson)
            .toList()
        : <ModuleMaterial>[];

    final teacherJson = _asMap(json['teacher']);

    return UserModuleItems(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      title: (json['title'] ?? json['name'] ?? '') as String,
      isEnrolled: json['isEnrolled'] == true,
      items: items,
      materials: materials,
      teacher: teacherJson != null ? ModuleTeacher.fromJson(teacherJson) : null,
    );
  }
}

enum LessonVideoKind { none, mp4, youtube, embed }

class LessonPlayback {
  const LessonPlayback({
    required this.id,
    required this.title,
    required this.isEnrolled,
    required this.accessWithoutEnrollment,
    required this.kind,
    this.videoUrl,
    this.thumbnailUrl,
    this.cards = const [],
    this.classificationQuizId,
    this.knowledgeQuizId,
    this.chatId,
    this.classificationQuizStatus,
    this.knowledgeQuizStatus,
    this.lastPosition,
    this.duration,
    this.watched = false,
    this.hasTestimonial = false,
    this.cardsCompleted = false,
  });

  final int id;
  final String title;
  final bool isEnrolled;
  final bool accessWithoutEnrollment;

  final String? videoUrl;
  final String? thumbnailUrl;
  final LessonVideoKind kind;

  final List<LessonCard> cards;

  final int? classificationQuizId;
  final int? knowledgeQuizId;
  final int? chatId;
  final LessonQuizStatus? classificationQuizStatus;
  final LessonQuizStatus? knowledgeQuizStatus;
  final int? lastPosition;
  final int? duration;
  final bool watched;
  final bool hasTestimonial;
  final bool cardsCompleted;

  bool get hasAccess => isEnrolled || accessWithoutEnrollment;

  factory LessonPlayback.fromJson(Map<String, dynamic> json) {

    final videoSource = json['video_source'];
    final external = json['external_url'] as String?;
    final thumbnail = json['thumbnail'];

    String? url;
    String? mime;
    if (videoSource is Map<String, dynamic> &&
        (videoSource['url'] as String?)?.isNotEmpty == true) {
      url = CdnConfig.mediaUrl(videoSource['url'] as String);
      mime = videoSource['mime_type'] as String?;
    } else if (external != null && external.isNotEmpty) {
      url = external;
    }

    final kind = VideoSource.classify(mimeType: mime, videoUrl: url);

    final cardsJson = json['cards'];
    final cards = cardsJson is List
        ? cardsJson
            .whereType<Map<String, dynamic>>()
            .map(LessonCard.fromJson)
            .toList()
        : <LessonCard>[];

    final progress = json['progress'];

    return LessonPlayback(
      id: _asInt(json['id']),
      title: (json['title'] as String? ?? ''),
      isEnrolled: json['isEnrolled'] == true,
      accessWithoutEnrollment: json['access_without_enrollment'] == true,
      kind: kind,
      videoUrl: url,
      thumbnailUrl: thumbnail is Map<String, dynamic> &&
              (thumbnail['url'] as String?)?.isNotEmpty == true
          ? CdnConfig.mediaUrl(thumbnail['url'] as String)
          : null,
      cards: cards,
      classificationQuizId: json['classification_quiz_id'] == null
          ? null
          : _asInt(json['classification_quiz_id']),
      knowledgeQuizId: json['knowledge_quiz_id'] == null
          ? null
          : _asInt(json['knowledge_quiz_id']),
      chatId: _asIntOrNull(json['chatId'] ?? json['chat_id']),
      classificationQuizStatus:
          json['classificationQuizStatus'] is Map<String, dynamic>
              ? LessonQuizStatus.fromJson(
                  json['classificationQuizStatus'] as Map<String, dynamic>,
                )
              : null,
      knowledgeQuizStatus: json['knowledgeQuizStatus'] is Map<String, dynamic>
          ? LessonQuizStatus.fromJson(
              json['knowledgeQuizStatus'] as Map<String, dynamic>,
            )
          : null,
      lastPosition: progress is Map<String, dynamic>
          ? _asInt(progress['last_position'])
          : null,
      duration: progress is Map<String, dynamic>
          ? _asInt(progress['duration'])
          : null,
      watched: json['watched'] == true,
      hasTestimonial: json['hasTestimonial'] == true,
      cardsCompleted: json['cardsCompleted'] == true,
    );
  }

}

class LessonCard {
  const LessonCard({
    required this.id,
    required this.text,
    required this.answerText,
  });

  final int id;
  final String text;
  final String answerText;

  factory LessonCard.fromJson(Map<String, dynamic> json) {
    return LessonCard(
      id: _asInt(json['id']),
      text: (json['text'] as String? ?? ''),
      answerText: (json['answer_text'] as String? ?? ''),
    );
  }
}

class UserModuleQuiz {
  const UserModuleQuiz({required this.id, this.theme});

  final int id;
  final String? theme;

  factory UserModuleQuiz.fromJson(Map<String, dynamic> json) {
    return UserModuleQuiz(
      id: _asInt(json['id']),
      theme: json['theme'] as String?,
    );
  }
}

class UserModuleExternalSource {
  const UserModuleExternalSource({
    required this.id,
    required this.title,
    this.url,
  });

  final int id;
  final String title;
  final String? url;

  factory UserModuleExternalSource.fromJson(Map<String, dynamic> json) {
    return UserModuleExternalSource(
      id: _asInt(json['id']),
      title: (json['title'] as String? ?? ''),
      url: json['url'] as String?,
    );
  }
}
