import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_chat/app/data/models/chat_message_model.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class IndividualChatController extends GetxController {
  final UserModel targetUser;

  IndividualChatController({required this.targetUser});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService.to;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final isComposing = false.obs;
  final isUploading = false.obs;

  String get currentUid => _authService.firebaseUser.value?.uid ?? '';

  String get chatId {
    final uid1 = currentUid;
    final uid2 = targetUser.uid;
    final uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(() {
      isComposing.value = messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Stream<List<ChatMessageModel>> getMessagesStream() {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data(), doc.id, currentUid);
      }).toList();
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentUid.isEmpty) return;

    messageController.clear();
    isComposing.value = false;

    debugPrint("✉️ [SEND MESSAGE START] 📤 From UID: '$currentUid' -> Receiver UID: '${targetUser.uid}' (${targetUser.userName}) | Text: '$text'");

    try {
      final chatDocRef = _firestore.collection('chats').doc(chatId);
      final messagesRef = chatDocRef.collection('messages');

      final addedDoc = await messagesRef.add({
        'senderId': currentUid,
        'receiverId': targetUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ [MESSAGE ADDED TO FIRESTORE] 📦 Msg Doc ID: '${addedDoc.id}' in chats/'$chatId'/messages");

      await chatDocRef.set({
        'participants': [currentUid, targetUser.uid],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      scrollToBottom();
    } catch (e) {
      debugPrint("❌ [SEND MESSAGE ERROR] 💥 $e");
      Get.snackbar(
        'Message Error',
        'Failed to send message: $e',
        backgroundColor: AppTheme.surfaceColor,
        colorText: AppTheme.errorColor,
      );
    }
  }

  Future<void> pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);
      await sendImageMessage(imageFile);
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Failed to pick image: $e',
        backgroundColor: AppTheme.surfaceColor,
        colorText: AppTheme.errorColor,
      );
    }
  }

  Future<void> sendImageMessage(File imageFile) async {
    if (currentUid.isEmpty) return;

    try {
      isUploading.value = true;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('chat_images/$chatId/$fileName');
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      final chatDocRef = _firestore.collection('chats').doc(chatId);
      final messagesRef = chatDocRef.collection('messages');

      await messagesRef.add({
        'senderId': currentUid,
        'receiverId': targetUser.uid,
        'text': '📷 Photo',
        'imageAttachment': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await chatDocRef.set({
        'participants': [currentUid, targetUser.uid],
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      scrollToBottom();
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to send image: $e',
        backgroundColor: AppTheme.surfaceColor,
        colorText: AppTheme.errorColor,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
