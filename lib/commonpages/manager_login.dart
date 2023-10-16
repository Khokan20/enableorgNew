import 'package:enableorg/ui/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enableorg/models/user.dart' as model;
import 'package:enableorg/services/auth_state.dart';
import 'package:enableorg/commonpages/terms_conditions_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerLoginPage extends StatefulWidget {
  final Function(model.User) onLoginSuccess;
  final AuthState authState;

  ManagerLoginPage({required this.onLoginSuccess, required this.authState});

  @override
  State<ManagerLoginPage> createState() => _ManagerLoginPageState();
}

class _ManagerLoginPageState extends State<ManagerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool acceptedTerms = false; // Track whether terms and conditions are accepted


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

@override
void initState() {
  super.initState();
  //_checkAcceptedTerms(); // Check if the user has accepted the terms.
}
  
  void _checkAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final isAccepted = prefs.getBool('acceptedTerms') ?? false;
    setState(() {
      acceptedTerms = isAccepted;
    });
  }

  @override
  Widget build(BuildContext context) {

   /*  if (!acceptedTerms) {
      _showTermsConditionsPopup();
      return SizedBox.shrink(); // Return an empty widget while terms and conditions are not accepted
    }*/
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          height: 572,
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
          child: SizedBox(
            child: Form(
              key: _formKey, // Set the form key here
              child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: 196,
                    child: Image.asset('logo.png'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Manager Login ',
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
                      Navigator.pushNamed(context, '/user/login');
                    },
                    child: Text('User Login'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Forgot your password?',
                    style: TextStyle(
                      color: Color(0xFF161D58),
                      fontSize: 16,
                      fontFamily: 'Cormorant Garamond',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(204, 238, 238, 238),
    );
  }

  void _showTermsConditionsPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TermsConditionsPopup(
        onAccept: _acceptTerms,
      ),
    );
  }

Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true);
    setState(() {
      acceptedTerms = true;
    });
  }

  Future<void> _loginWithEmailAndPassword() async {
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

          if (!currentUser.isManager) {
            throw ErrorDescription("User does not exist");
          }

          widget.onLoginSuccess(currentUser);
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
}
