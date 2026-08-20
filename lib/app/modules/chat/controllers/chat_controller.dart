import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/routes/app_pages.dart';

class ChatController extends GetxController {
  final GlobalKey menuKey = GlobalKey();

  Rxn<UserModel> get currentUser => AuthService.to.currentUser;

  Future<void> signOut() async {
    await AuthService.to.signOut();
    Get.offAllNamed(Routes.AUTH);
  }
}
