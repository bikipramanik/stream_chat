import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/routes/app_pages.dart';

class ChatController extends GetxController {
  final GlobalKey menuKey = GlobalKey();
  final searchController = TextEditingController();

  final searchQuery = ''.obs;

  AuthService get authService => AuthService.to;
  Rxn<UserModel> get currentUser => authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Stream<List<UserModel>> getUsersStream() {
    final currentUid = authService.firebaseUser.value?.uid;
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) {
            if (searchQuery.value.isEmpty) return true;
            return user.userName.toLowerCase().contains(searchQuery.value) ||
                user.email.toLowerCase().contains(searchQuery.value);
          })
          .toList();
    });
  }

  Future<void> signOut() async {
    await authService.signOut();
    Get.offAllNamed(Routes.AUTH);
  }
}
