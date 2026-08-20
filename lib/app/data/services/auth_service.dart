import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      currentUser.value = null;
    } else {
      await fetchUserData(user.uid);
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        currentUser.value = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      Get.log("Error fetching user data: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser.value = null;
  }
}
