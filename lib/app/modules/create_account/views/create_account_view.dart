import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/modules/create_account/controllers/create_account_controller.dart';
import 'package:stream_chat/app/modules/create_account/widgets/user_image_picker.dart';

class CreateAccountView extends GetView<CreateAccountController> {
  const CreateAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 50)),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      UserImagePicker(
                        onPickedImage: controller.setImage,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: controller.emailController,
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.blue,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          labelStyle: TextStyle(color: Colors.grey),
                          floatingLabelStyle: TextStyle(color: Colors.blue),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          errorStyle: TextStyle(color: Colors.red),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return "Please enter a valid email address.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: controller.userNameController,
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.blue,
                        decoration: const InputDecoration(
                          labelText: "User Name",
                          labelStyle: TextStyle(color: Colors.grey),
                          floatingLabelStyle: TextStyle(color: Colors.blue),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          errorStyle: TextStyle(color: Colors.red),
                        ),
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              value.trim().length < 4) {
                            return "User name must be at least 4 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: controller.passwordController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.grey),
                          floatingLabelStyle: TextStyle(color: Colors.blue),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          errorStyle: TextStyle(color: Colors.red),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return "Password must be at least 6 characters long.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const CircularProgressIndicator();
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: controller.goToLogin,
                              child: const Text(
                                "Already have an account",
                                style: TextStyle(color: Colors.purple),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: controller.createAccount,
                              child: const Text(
                                "Create Account",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
