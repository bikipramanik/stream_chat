import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/data/services/call_service.dart';
import 'package:stream_chat/app/data/services/notification_service.dart';
import 'package:stream_chat/app/routes/app_pages.dart';
import 'package:stream_chat/app/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  Get.put(AuthService());
  Get.put(CallService());
  Get.put(NotificationService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.to;
    final initialRoute =
        authService.firebaseUser.value != null ? Routes.CHAT : Routes.AUTH;

    return GetMaterialApp(
      title: 'Stream Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
