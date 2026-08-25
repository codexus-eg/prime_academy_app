import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'app/prime_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _enableAndroidPhotoPicker();
  runApp(const PrimeApp());
}

/// Use the system Photo Picker so the app does not need READ_MEDIA_* permissions
/// (Google Play Photos and videos permissions policy).
void _enableAndroidPhotoPicker() {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}
