import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat/widgets/user_image_picker.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final form = GlobalKey<FormState>();

  bool _isLoading = false;

  String _enteredEmail = "";

  String _enteredPassword = "";
  String _enteredUserName = "";
  File? _pickedImage;

  void onSubmit() async {
    final isValid = form.currentState!.validate();
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("You have to select an Image")));
      return;
    }
    if (isValid) {
      form.currentState!.save();
      try {
        setState(() {
          _isLoading = true;
        });
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _enteredEmail,
              password: _enteredPassword,
            );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("users_images")
            .child("${userCredential.user!.uid}.jpg");
        await storageRef.putFile(_pickedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
              "username": _enteredUserName,
              "email": _enteredEmail,
              "imageurl": imageUrl,
            });
        setState(() {
          _isLoading = false;
        });
        print(" -------------------------------$imageUrl");

        Navigator.pop(context);
        if (!mounted) {
          return;
        }

        print(userCredential);
      } on FirebaseAuthException catch (error) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) {
          return;
        }
        String errorMessage;
        switch (error.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered.';
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

        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } on FirebaseException catch (error) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) {
          return;
        }
        String errorMessage;
        switch (error.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered.';
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

        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: Text("Create Account", style: TextStyle(fontSize: 50)),
              ),

              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Form(
                  key: form,
                  child: Column(
                    spacing: 10,
                    children: [
                      UserImagePicker(
                        onPickedImage: (pickedImage) {
                          _pickedImage = pickedImage;
                        },
                      ),
                      TextFormField(
                        style: TextStyle(color: Colors.black),
                        cursorColor: Colors.blue,
                        decoration: InputDecoration(
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
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return "Please enter a valid email address.";
                          }
                          return null;
                        },

                        onSaved: (newValue) {
                          _enteredEmail = newValue!;
                        },
                      ),
                      TextFormField(
                        style: TextStyle(color: Colors.black),
                        cursorColor: Colors.blue,
                        decoration: InputDecoration(
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
                            return "User name must be atleast 4.";
                          }
                          return null;
                        },

                        onSaved: (newValue) {
                          _enteredUserName = newValue!;
                        },
                      ),
                      TextFormField(
                        style: TextStyle(color: Colors.black),

                        decoration: InputDecoration(
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
                            return "Password must be atleast 6 characters long.";
                          }
                          return null;
                        },

                        onSaved: (newValue) {
                          _enteredPassword = newValue!;
                        },
                      ),
                      if (!_isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Already have an account",
                                style: TextStyle(color: Colors.purple),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: onSubmit,
                              child: Text(
                                "Create Account",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      if (_isLoading) const CircularProgressIndicator(),
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
