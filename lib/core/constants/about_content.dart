import 'package:flutter/material.dart';

class AboutSection {
  const AboutSection({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;
}

class AboutCounter {
  const AboutCounter({
    required this.title,
    required this.maxValue,
    required this.icon,
  });

  final String title;
  final int maxValue;
  final IconData icon;
}

abstract final class AboutContent {
  static const List<String> mainInfo = [
    'المنصات التعليميه كثيره ومتعدده ولكن في برايم اكاديمي نقدم محتوي مختلف '
        'تماما عن طريق اتباع افضل الطرق الحديثه في توصيل المعلومات واتباع '
        'انظمه الذكاء الاصطناعي التي تجذب الطلاب نحو المذاكره والتفوق والتطور',
  ];

  static const List<AboutSection> secondaryInfo = [
    AboutSection(
      title: 'نظام الدوري التعليمي',
      text:
          'وهو نظام يتيج للطلاب التنافس من خلال المعلومات الذين يكتسبونها من '
          'مُعلمين برايم اكاديمي وبالتالي تذداد ثقتهم في انفسهم ويُساعدهم هذا '
          'النظام علي التأقلم علي جو الامتحانات وكسر التوتر الذي يصاحبهم اثناء '
          'تواجدهم في اللجنه',
      icon: Icons.co_present,
    ),
    AboutSection(
      title: 'الحصص المسجله واوراق العمل',
      text:
          'يقوم المعلم بتسجيل الحصه ووضعها علي بروفايل الطالب حتي يكون مرجعا له '
          'في أي وقت بالاضافه الي أوراق العمل الذي يبتكرها المعلم بأسلوبه السهل '
          'والبسيط حتي يساعد الطالب علي المذاكره بشكل بسيط وسهل ويراعي المعلم '
          'وضع كل أفكار الامتحانات في أوراق العمل حتي نضمن للطالب العلامه الكامل',
      icon: Icons.videocam,
    ),
    AboutSection(
      title: 'نظام المتابعه المستمره',
      text:
          'يقوم المعلم بتصحيح الواجبات ومتابعه الطلاب عبر المنصه وجروب الواتساب '
          'الخاص بالمجموعه حتي يبقي المعلم مع الطالب في كل الأوقات وليس وقت '
          'الحصه فقط',
      icon: Icons.how_to_reg,
    ),
    AboutSection(
      title: 'الاداره والسيكرتاريه',
      text:
          'تتميز اداره وسيكرتاريه برايم اكاديمي بالتعاون الدائم والمستمر والرد '
          'علي جميع الاسأله في الحال وتسهيل أي عقبات لاولياء الأمور والطلاب',
      icon: Icons.assignment,
    ),
  ];

  static const List<AboutCounter> counters = [
    AboutCounter(title: 'كفاءة المعلمين', maxValue: 100, icon: Icons.co_present),
    AboutCounter(
        title: 'نتائج الطلاب', maxValue: 100, icon: Icons.school),
    AboutCounter(
        title: 'الكفاءة الادراية', maxValue: 100, icon: Icons.groups),
    AboutCounter(title: 'مهارات التواصل', maxValue: 100, icon: Icons.forum),
  ];
}
