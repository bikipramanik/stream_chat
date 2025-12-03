import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/controllers/user_controller.dart';
import 'package:stream_chat/app/ui/screens/create_account_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();

  bool _isLoading = false;

  String enteredEmail = "";

  String enteredPassword = "";

  void onSubmit() async {
    final isValid = form.currentState!.validate();

    if (isValid) {
      form.currentState!.save();
      try {
        setState(() {
          _isLoading = true;
        });
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: enteredEmail,
              password: enteredPassword,
            );
        if (!mounted) {
          return;
        }
        print(userCredential);

        setState(() {
          _isLoading = false;
        });
        Get.delete<UserController>(force: true);
        Get.put(UserController());
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) {
          return;
        }
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'invalid-credential':
          case 'INVALID_LOGIN_CREDENTIALS':
            errorMessage = 'User not found.';
            break;
          default:
            errorMessage = e.message ?? 'Authentication failed.';
        }

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        print("-----------------------$errorMessage");
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
              SizedBox(child: Text("Log In", style: TextStyle(fontSize: 50))),
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
                          enteredEmail = newValue!;
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
                          enteredPassword = newValue!;
                        },
                      ),
                      if (!_isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateAccountScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Create New Account",
                                style: TextStyle(color: Colors.purple),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: onSubmit,
                              child: Text(
                                "Log in",
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
