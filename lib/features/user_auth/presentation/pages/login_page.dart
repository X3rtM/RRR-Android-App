import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:flutter_firebase/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:flutter_firebase/global/common/toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  void _initializeSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = _preferences.getString('email') ?? '';
      _passwordController.text = _preferences.getString('password') ?? '';
      _rememberMe = _preferences.getBool('rememberMe') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Login"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("img/login_bckgnd.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  FormContainerWidget(
                    controller: _emailController,
                    hintText: "Email",
                    isPasswordField: false,
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  SizedBox(height: 10),
                  FormContainerWidget(
                    controller: _passwordController,
                    hintText: "Password",
                    isPasswordField: true,
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                            _preferences.setBool('rememberMe', value);
                          });
                        },
                      ),
                      Text('Remember Me'),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          // Implement forgot password functionality
                          _forgotPassword();
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      _signIn();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isSigning
                            ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _signInWithGoogle();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.google,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Sign in with Google",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage()),
                                (route) => false,
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      User? user = await _auth.signInWithEmailAndPassword(email, password);

      setState(() {
        _isSigning = false;
      });

      if (user != null) {
        showToast(message: "User is successfully signed in");
        Navigator.pushNamed(context, "/home");
      } else {
        showToast(message: "Some error occurred");
      }
    } catch (e) {
      showToast(message: "Failed to sign in: $e");
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isSigning = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '204717000834-7gqfsabhohifacopumr9mnkkbot8l3j2.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult =
        await _firebaseAuth.signInWithCredential(credential);
        final User? user = authResult.user;

        setState(() {
          _isSigning = false;
        });

        if (user != null) {
          showToast(message: "User is successfully signed in");
          Navigator.pushNamed(context, "/home");
        } else {
          showToast(message: "Some error occurred");
        }
      } else {
        showToast(message: "Google Sign-In cancelled");
        setState(() {
          _isSigning = false;
        });
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
      String errorMessage = "Error occurred during Google Sign-In";

      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'account-exists-with-different-credential':
            errorMessage =
            "An account already exists with the same email address but different sign-in credentials.";
            break;
          case 'invalid-credential':
            errorMessage = "The credential received is malformed or has expired.";
            break;
          case 'operation-not-allowed':
            errorMessage =
            "Google Sign-In is currently not enabled. Please contact support.";
            break;
          case 'user-disabled':
            errorMessage = "The user account has been disabled by an administrator.";
            break;
          case 'user-not-found':
            errorMessage =
            "There is no user corresponding to the given Google sign-in credentials.";
            break;
          case 'wrong-password':
            errorMessage = "Invalid password provided for the Google account.";
            break;
          default:
            errorMessage = "An unknown error occurred. Please try again later.";
            break;
        }
      }
      showToast(message: errorMessage);
      setState(() {
        _isSigning = false;
      });
    }
  }

  void _forgotPassword() async {
    String email = _emailController.text;
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      showToast(message: "Password reset email sent to $email");
    } catch (error) {
      print("Forgot Password Error: $error");
      showToast(message: "Failed to send password reset email: $error");
    }
  }
}
