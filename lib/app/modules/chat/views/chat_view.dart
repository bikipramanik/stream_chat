import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/modules/chat/controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chats"),
          backgroundColor: const Color.fromARGB(255, 47, 47, 47),
          actions: [
            InkWell(
              key: controller.menuKey,
              onTap: () {
                final RenderBox renderBox = controller.menuKey.currentContext!
                    .findRenderObject() as RenderBox;
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
              child: CircleAvatar(
                backgroundImage: NetworkImage(user.imgUrl),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text("Log out?"),
                    content: const Text("Are you sure you want to sign out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Get.back();
                          await controller.signOut();
                        },
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
        body: const Center(child: Text("Chat Screen")),
      );
    });
  }
}
