import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/controllers/user_controller.dart';
import 'package:stream_chat/app/screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stream_chat/app/screens/chat_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(UserController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "StreamChat",
      darkTheme: ThemeData.dark(),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("Has data -----");
            return  ChatScreen();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("Loadinggggg!!!!!!!1");
            return Center(child: CircularProgressIndicator());
          }
          print("-------- No data -----");
          return const AuthScreen();
        },
      ),
    );
  }
}
