import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> userModel = Rxn<UserModel>();

  bool _suppressAuthChanges = false;

  @override
  void onInit() {
    firebaseUser.bindStream(
      _auth.authStateChanges().where((_) => !_suppressAuthChanges),
    );
    ever(firebaseUser, (_) => _loadUserModel(),);
    super.onInit();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email,required String password,required String userName,required String imgUrl})async{
    try{
      _suppressAuthChanges = true;
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;

      UserModel newUser = UserModel(uid: uid, userName: userName, email: email, imgUrl: imgUrl);
      await _firestore.collection("users").doc(uid).set({
        "username" : newUser.userName,
        "email" : newUser.email,
        "imageurl" : newUser.imgUrl,
      });
      _suppressAuthChanges = false;

      firebaseUser.value = _auth.currentUser;

      userModel.value = newUser;
    }catch(e){
      _suppressAuthChanges = false;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    userModel.value = null;
  }

  Future<void> _loadUserModel() async{
    final user = firebaseUser.value;
    if(user == null){
      userModel.value = null;
      return;
    }
    final doc = await _firestore.collection("users").doc(user.uid).get();

    if(doc.exists){
      userModel.value = UserModel.fromMap(doc.data()!, user.uid);
    }
  }
}
