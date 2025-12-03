import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/bindings/auth_binding.dart';
import 'package:stream_chat/app/controllers/auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stream_chat/app/ui/screens/auth_screen.dart';
import 'package:stream_chat/app/ui/screens/chat_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(initialBinding: AuthBinding(), home: Root());
  }
}

class Root extends GetWidget<AuthController> {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.firebaseUser.value;
      if (user == null) {
        return AuthScreen();
      } else {
        return ChatScreen();
      }
    });
  }
}
