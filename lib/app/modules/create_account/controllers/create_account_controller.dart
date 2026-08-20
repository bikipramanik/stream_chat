import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/routes/app_pages.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class CreateAccountController extends GetxController {
  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final Rxn<File> pickedImage = Rxn<File>();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void setImage(File image) {
    pickedImage.value = image;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> createAccount() async {
    if (pickedImage.value == null) {
      Get.snackbar(
        'Image Required',
        'Please select a profile picture to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
      );
      return;
    }

    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    try {
      isLoading.value = true;
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users_images')
          .child('$uid.jpg');

      await storageRef.putFile(pickedImage.value!);
      final imageUrl = await storageRef.getDownloadURL();

      final newUser = UserModel(
        uid: uid,
        userName: userNameController.text.trim(),
        email: emailController.text.trim(),
        imgUrl: imageUrl,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': newUser.userName,
        'email': newUser.email,
        'imageurl': newUser.imgUrl,
      });

      AuthService.to.currentUser.value = newUser;
      Get.offAllNamed(Routes.CHAT);
    } on FirebaseAuthException catch (error) {
      String errorMessage;
      switch (error.code) {
        case 'email-already-in-use':
          errorMessage = 'This email address is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password must be at least 6 characters long.';
          break;
        default:
          errorMessage = error.message ?? 'Account creation failed.';
      }
      Get.snackbar(
        'Sign Up Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToLogin() {
    Get.back();
  }
}
