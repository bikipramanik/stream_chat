import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/models/user_model.dart';

class UserController extends GetxController {
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  onInit() {
    super.onInit();
    fetchUser();
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
