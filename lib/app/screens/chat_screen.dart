import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/controllers/user_controller.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});
  final userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    final user = userController.currentUser.value;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Something Wrong")));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        backgroundColor: const Color.fromARGB(255, 47, 47, 47),
        actions: [
          CircleAvatar(backgroundImage: NetworkImage(user.imgUrl)),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Log out?"),
                    content: Text("You sure you want to sign out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          FirebaseAuth.instance.signOut();
                        },
                        child: Text(
                          "Sign Out",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Center(child: Text("Chat Screen")),
    );
  }
}
