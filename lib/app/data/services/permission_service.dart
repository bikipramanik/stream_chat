import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraAndMicrophonePermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  static Future<bool> requestMicrophonePermissionOnly() async {
    final microphoneStatus = await Permission.microphone.request();

    if (microphoneStatus.isGranted) {
      return true;
    }

    if (microphoneStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }
}
