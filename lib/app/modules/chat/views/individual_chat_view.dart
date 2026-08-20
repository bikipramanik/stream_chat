import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/chat_message_model.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _loadSampleMessages();
  }

  void _loadSampleMessages() {
    final now = DateTime.now();
    _messages.addAll([
      ChatMessageModel(
        id: '1',
        senderId: widget.targetUser.uid,
        text: 'Hey! 👋 Welcome to StreamChat!',
        isMe: false,
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ChatMessageModel(
        id: '2',
        senderId: widget.targetUser.uid,
        text: 'How is the new UI refactoring coming along?',
        isMe: false,
        timestamp: now.subtract(const Duration(minutes: 14)),
      ),
      ChatMessageModel(
        id: '3',
        senderId: 'me',
        text: 'Hey @${widget.targetUser.userName}! Everything is super smooth with GetX and modern Flutter widgets 🚀',
        isMe: true,
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
      ChatMessageModel(
        id: '4',
        senderId: widget.targetUser.uid,
        text: 'That looks fantastic! Let me know if you want to test instant messaging or voice calls.',
        isMe: false,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'me',
          text: text,
          isMe: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isComposing = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                      Get.snackbar("Camera", "Camera action clicked",
                          backgroundColor: AppTheme.surfaceColor,
                          colorText: AppTheme.textPrimary);
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.photo_library_rounded,
                    color: Colors.blueAccent,
                    label: 'Gallery',
                    onTap: () {
                      Get.back();
                      Get.snackbar("Gallery", "Gallery action clicked",
                          backgroundColor: AppTheme.surfaceColor,
                          colorText: AppTheme.textPrimary);
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.insert_drive_file_rounded,
                    color: Colors.amber,
                    label: 'Document',
                    onTap: () {
                      Get.back();
                      Get.snackbar("Document", "Document action clicked",
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
                      Get.snackbar("Audio", "Audio action clicked",
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
                Stack(
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.onlineColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.surfaceColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.targetUser.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Online",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.onlineColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(
                    message: message,
                    userAvatarUrl: widget.targetUser.imgUrl,
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
                              controller: _messageController,
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
                              onChanged: (text) {
                                setState(() {
                                  _isComposing = text.trim().isNotEmpty;
                                });
                              },
                              onSubmitted: (_) => _sendMessage(),
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
                  GestureDetector(
                    onTap: _isComposing ? _sendMessage : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isComposing
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColorLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isComposing ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
