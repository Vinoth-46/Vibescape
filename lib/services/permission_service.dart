import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  /// Requests the necessary permissions based on the Android version.
  /// Returns [true] if all required permissions are granted.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return false;

    if (await _isAndroid13OrAbove()) {
      // Android 13+ (API 33+)
      // Request Media Audio and Notification permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.audio,
        Permission.notification,
      ].request();

      // Check if Audio is granted (Notification is optional but recommended)
      bool audioGranted =
          statuses[Permission.audio] == PermissionStatus.granted;

      return audioGranted;
    } else {
      // Android 12 and below (API < 33)
      // Request Storage permission
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Checks if the necessary permissions are currently granted.
  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return false;

    if (await _isAndroid13OrAbove()) {
      return await Permission.audio.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  /// Opens the app settings if permission is permanently denied.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  Future<bool> _isAndroid13OrAbove() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }
}
