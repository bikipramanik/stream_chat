import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_chat/app/data/models/chat_message_model.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/modules/chat/controllers/individual_chat_controller.dart';
import 'package:stream_chat/app/modules/chat/widgets/chat_bubble.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class IndividualChatView extends StatefulWidget {
  final UserModel targetUser;

  const IndividualChatView({
    super.key,
    required this.targetUser,
  });

  @override
  State<IndividualChatView> createState() => _IndividualChatViewState();
}

class _IndividualChatViewState extends State<IndividualChatView> {
  late final IndividualChatController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      IndividualChatController(targetUser: widget.targetUser),
      tag: widget.targetUser.uid,
    );
  }

  @override
  void dispose() {
    Get.delete<IndividualChatController>(tag: widget.targetUser.uid);
    super.dispose();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColorLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Share Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentItem(
                    icon: Icons.camera_alt_rounded,
                    color: Colors.purpleAccent,
                    label: 'Camera',
                    onTap: () {
                      Get.back();
                      controller.pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.photo_library_rounded,
                    color: Colors.blueAccent,
                    label: 'Gallery',
                    onTap: () {
                      Get.back();
                      controller.pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.insert_drive_file_rounded,
                    color: Colors.amber,
                    label: 'Document',
                    onTap: () {
                      Get.back();
                      Get.snackbar("Document", "Document sharing coming soon!",
                          backgroundColor: AppTheme.surfaceColor,
                          colorText: AppTheme.textPrimary);
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.headset_rounded,
                    color: Colors.tealAccent,
                    label: 'Audio',
                    onTap: () {
                      Get.back();
                      Get.snackbar("Audio", "Audio sharing coming soon!",
                          backgroundColor: AppTheme.surfaceColor,
                          colorText: AppTheme.textPrimary);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.surfaceColorLight,
                backgroundImage: widget.targetUser.imgUrl.isNotEmpty
                    ? NetworkImage(widget.targetUser.imgUrl)
                    : null,
                child: widget.targetUser.imgUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: AppTheme.textSecondary)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                widget.targetUser.userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.targetUser.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.snackbar("Call", "Calling ${widget.targetUser.userName}...",
                          backgroundColor: AppTheme.primaryColor,
                          colorText: Colors.white);
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text("Audio Call"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.snackbar("Video Call", "Video calling ${widget.targetUser.userName}...",
                          backgroundColor: AppTheme.primaryColor,
                          colorText: Colors.white);
                    },
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text("Video Call"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: InkWell(
          onTap: _showUserProfile,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.surfaceColorLight,
                  backgroundImage: widget.targetUser.imgUrl.isNotEmpty
                      ? NetworkImage(widget.targetUser.imgUrl)
                      : null,
                  child: widget.targetUser.imgUrl.isEmpty
                      ? const Icon(Icons.person, size: 20, color: AppTheme.textSecondary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.targetUser.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              Get.snackbar("Audio Call", "Calling ${widget.targetUser.userName}...",
                  backgroundColor: AppTheme.surfaceColor, colorText: AppTheme.textPrimary);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              Get.snackbar("Video Call", "Starting video call...",
                  backgroundColor: AppTheme.surfaceColor, colorText: AppTheme.textPrimary);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
            onPressed: _showUserProfile,
          ),
        ],
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            // Uploading progress banner
            Obx(() {
              if (controller.isUploading.value) {
                return const LinearProgressIndicator(
                  backgroundColor: AppTheme.surfaceColor,
                  color: AppTheme.primaryColor,
                  minHeight: 3,
                );
              }
              return const SizedBox.shrink();
            }),

            // Real-time Chat Messages List
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: controller.getMessagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading messages: ${snapshot.error}",
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceColorLight),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Say 👋 to @${widget.targetUser.userName}!",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "No messages here yet. Start the conversation!",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Auto scroll to bottom when new message arrives
                  controller.scrollToBottom();

                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(
                        message: message,
                        userAvatarUrl: widget.targetUser.imgUrl,
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Attachment Clip Button
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded,
                        color: AppTheme.textSecondary),
                    onPressed: _showAttachmentOptions,
                  ),

                  // Text Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.surfaceColorLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.messageController,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Type a message...",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => controller.sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.emoji_emotions_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send or Mic Action Button
                  Obx(() {
                    final isComposing = controller.isComposing.value;
                    return GestureDetector(
                      onTap: isComposing ? controller.sendMessage : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isComposing
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColorLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isComposing ? Icons.send_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
