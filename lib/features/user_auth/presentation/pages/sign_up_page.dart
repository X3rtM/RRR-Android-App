import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/login_page.dart';
import 'package:flutter_firebase/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:flutter_firebase/global/common/toast.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isSigningUp = false;
  bool isInvalidEmail = false;
  bool isInvalidPassword = false;
  String? _userType;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Sign Up"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("img/login_bckgnd.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 30,
                ),
                FormContainerWidget(
                  controller: _usernameController,
                  hintText: "Username",
                  isPasswordField: false,
                ),
                SizedBox(
                  height: 10,
                ),
                FormContainerWidget(
                  controller: _emailController,
                  hintText: "Email",
                  isPasswordField: false,
                ),
                if (isInvalidEmail)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Invalid email address",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  height: 10,
                ),
                FormContainerWidget(
                  controller: _passwordController,
                  hintText: "Password",
                  isPasswordField: true,
                ),
                if (isInvalidPassword)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Password must be at least 8 characters",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'child',
                      groupValue: _userType,
                      onChanged: (value) {
                        setState(() {
                          _userType = value;
                        });
                      },
                    ),
                    Text('Child'),
                    SizedBox(width: 20),
                    Radio<String>(
                      value: 'parent',
                      groupValue: _userType,
                      onChanged: (value) {
                        setState(() {
                          _userType = value;
                        });
                      },
                    ),
                    Text('Parent'),
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _signUp,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isSigningUp
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                      onTap: () {
                        navigateToLoginPage();
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    // Get values from controllers
    String email = _emailController.text;
    String password = _passwordController.text;
    String username = _usernameController.text; // Retrieve username

    bool _isValidEmail(String email) {
      // Basic email validation using RegExp
      return RegExp(r"^[a-zA-Z0-9]+@[gmail,yahoo,hotmail,]+\.[com]+").hasMatch(email);
    }

    // Validate email and password ...
    setState(() {
      isSigningUp = true;
    });

    User? user = await _auth.signUpWithEmailAndPassword(email, password);

    setState(() {
      isSigningUp = false;
    });

    if (user != null) {
      // Save user data including username to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'username': username, // Save username
        'userType': _userType, // Save user type
        // Other user data
      });

      showToast(message: "User is successfully created as $_userType");
      Navigator.pushNamed(context, "/home");
    } else {
      showToast(message: "Error occurred while signing up");
    }
  }

  void navigateToLoginPage() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void showToast({required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }
}