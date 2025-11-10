import 'package:flutter/material.dart';
import 'package:stream_chat/screens/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "StreamChat",
      darkTheme: ThemeData.dark(),
      home: AuthScreen(),
    );
  }
}
