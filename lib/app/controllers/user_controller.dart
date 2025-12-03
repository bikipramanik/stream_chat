import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';

class UserController extends GetxController {
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  late final StreamSubscription _sub;

  @override
  void onInit() {
    super.onInit();

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        currentUser.value = null;
      } else {
        await fetchUser();
      }
    });
  }

  @override
  void onClose() {
    _sub.cancel();
    super.onClose();
  }

  Future<void> fetchUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        currentUser.value = UserModel.fromMap(userDoc.data()!, uid);
      }
    } catch (e) {
      print("Error fetching user $e");
    }
  }
}
