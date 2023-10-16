import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enableorg/services/auth_state.dart';
import 'package:enableorg/ui/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:enableorg/models/user.dart' as model;

class UserLoginPage extends StatefulWidget {
  final Function(model.User) onLoginSuccess;
  final AuthState authState;

  UserLoginPage({required this.onLoginSuccess, required this.authState});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          height: 570,
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the container
            borderRadius: BorderRadius.circular(10), // Border radius
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5), // Shadow color
                spreadRadius: 5, // Spread radius
                blurRadius: 7, // Blur radius
                offset: Offset(0, 3), // Offset
              ),
            ],
          ),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: 196,
                    child: Image.asset('logo.png'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'User Login ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 5, 36, 83),
                      fontSize: 20,
                      fontFamily: 'Cormorant Garamond',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 360.0,
                      height: 70.0,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor:
                                const Color.fromARGB(255, 236, 240, 241)),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter an email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 360.0,
                      height: 70.0,
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor:
                                const Color.fromARGB(255, 236, 240, 241)),
                        obscureText: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 160.0,
                      height: 46.0,
                      child: CustomButton(
                        text: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Cormorant Garamond',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onPressed: () {
                          _showLoadingPopup(context);
                          if (_formKey.currentState?.validate() ?? false) {
                            _loginWithEmailAndPassword();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/manager/login');
                    },
                    child: Text('Manager Login'),
                  ),
                  //  if (isLoading) CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(204, 238, 238, 238),
    );
  }

  void _showLoadingPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible:
          false, // Prevent closing the dialog by tapping outside.
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Logging in...'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loginWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final UserCredential? userCredential =
          await widget.authState.signInWithEmailAndPassword(email, password);

      if (userCredential != null) {
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          final uid = firebaseUser.uid;

          final DocumentSnapshot userDocument = await FirebaseFirestore.instance
              .collection('User')
              .doc(uid)
              .get();

          final currentUser = model.User.fromDocumentSnapshot(userDocument);

          await _showAgreementPopup(); // Show the agreement popup.
          if (acceptedAgreement = true) {
            widget.onLoginSuccess(currentUser);
          }
        }
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Error'),
            content: Text('Failed to log in. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Login Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
          content: Text('Failed to log in. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool acceptedAgreement = true;
  Future<void> _showAgreementPopup() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('User Agreement'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Please read and accept the user agreement.',
                ),
                SizedBox(height: 10),
                CheckboxListTile(
                  title: Text('I agree to the terms and conditions'),
                  value: acceptedAgreement,
                  onChanged: (bool? value) {
                    setState(() {
                      acceptedAgreement = value!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the agreement popup.
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
