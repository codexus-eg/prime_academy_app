import 'package:flutter/material.dart';

class ContactSocialIcon {
  const ContactSocialIcon({
    required this.icon,
    required this.url,
    this.backgroundColor,
    this.gradient,
    this.padding = const EdgeInsets.all(8),
  });

  final IconData icon;
  final String url;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
}

abstract final class ContactContent {

  static const String storyBookAsset =
      'assets/web/landing_page/about_story.gif';

  static const List<ContactSocialIcon> socialIcons = [
    ContactSocialIcon(
      icon: Icons.facebook,
      backgroundColor: Color(0xFF2563EB),
      url: 'https://www.facebook.com/primeacademy.co',
    ),
    ContactSocialIcon(
      icon: Icons.camera_alt_outlined,
      gradient: LinearGradient(
        colors: [
          Color(0xFFEAB308),
          Color(0xFFDB2777),
          Color(0xFF7E22CE),
        ],
      ),
      url: 'https://www.instagram.com/primeacademy4insta/',
    ),
    ContactSocialIcon(
      icon: Icons.chat,
      backgroundColor: Color(0xFF16A34A),
      url: 'https://api.whatsapp.com/send/?phone=96556651979',
    ),
  ];
}
