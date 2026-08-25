import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/modules/chat/controllers/chat_controller.dart';
import 'package:stream_chat/app/modules/chat/views/individual_chat_view.dart';
import 'package:stream_chat/app/modules/chat/widgets/user_card.dart';
import 'package:stream_chat/app/routes/app_pages.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Obx(() {
          final user = controller.currentUser.value;
          return Row(
            children: [
              GestureDetector(
                key: controller.menuKey,  
                onTap: () => _showProfileMenu(context, user),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.surfaceColorLight,
                  backgroundImage: (user != null && user.imgUrl.isNotEmpty)
                      ? NetworkImage(user.imgUrl)
                      : null,
                  child: (user == null || user.imgUrl.isEmpty)
                      ? const Icon(Icons.person, size: 20, color: AppTheme.textSecondary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "StreamChat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    user != null ? "@${user.userName}" : "Connecting...",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            tooltip: "Call History",
            onPressed: () => Get.toNamed(Routes.CALL_HISTORY),
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.textPrimary),
          ),
          IconButton(
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search contacts or messages...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => controller.searchController.clear(),
                      )
                    : const SizedBox.shrink()),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // User Feed List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: controller.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading contacts",
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surfaceColorLight,
                            ),
                          ),
                          child: const Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Contacts Found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "When other users join, they will appear here.",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserCard(
                      user: user,
                      onTap: () {
                        Get.to(() => IndividualChatView(targetUser: user));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, UserModel? user) {
    if (user == null) return;
    final RenderBox renderBox =
        controller.menuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      context: context,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceColorLight),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out of StreamChat?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              Get.back();
              await controller.signOut();
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }
}
