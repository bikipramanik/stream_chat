import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/controllers/chat_screen_controller.dart';
import 'package:stream_chat/app/controllers/user_controller.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});
  final userController = Get.find<UserController>();
  final chatScreenController = Get.find<ChatScreenController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userController.currentUser.value;
      if (user == null) {
        return Scaffold(
          body: Center(child: Text("User null - Something Wrong")),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text("Chats"),
          backgroundColor: const Color.fromARGB(255, 47, 47, 47),
          actions: [
            InkWell(
              key: chatScreenController.menuKey,
              onTap: () {
                final RenderBox renderBox =
                    chatScreenController.menuKey.currentContext!
                            .findRenderObject()
                        as RenderBox;
                final Offset offset = renderBox.localToGlobal(Offset.zero);
                final Size size = renderBox.size;

                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    offset.dx,
                    offset.dy + size.height,
                    offset.dx + size.width,
                    offset.dy + size.height,
                  ),
                  items: [
                    PopupMenuItem(child: Text("Name: ${user.userName}")),
                    PopupMenuItem(child: Text("Email: ${user.email}")),
                  ],
                );
              },

              child: CircleAvatar(backgroundImage: NetworkImage(user.imgUrl)),
            ),
            SizedBox(width: 10),
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
                          onPressed: ()async {
                            Navigator.pop(context);
                            await FirebaseAuth.instance.signOut();
                            Get.delete<UserController>(force: true);
                            Get.put(UserController());
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
    });
  }
}
