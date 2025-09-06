// File: lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestPermissions() async {
    // Request microphone permission for voice features
    await Permission.microphone.request();

    // Request storage permission for saving audio files
    await Permission.storage.request();

    // Request notification permission for app notifications
    await Permission.notification.request();
  }

  static Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  static Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
