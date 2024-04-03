import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter_firebase/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/login_page.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:lottie/lottie.dart';
import "dart:async";
import "dart:math";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDC-EDE7d1aOzLZrgzyq9Gi-H4LxjEsYCU",
        appId: "1:204717000834:web:b5d7aeff32c2a510ad8c9b",
        messagingSenderId: "204717000834",
        projectId: "flutter-firebase-87542",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      home: SplashScreen(), // Use SplashScreen as the initial route
      routes: {
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Timer _timer;
  late int _currentIndex;
  List<String> _messages = [
    "'Education is the passport to the future, for tomorrow belongs to those who prepare for it today.' ~Malcolm X",
    "'Learning never exhausts the mind.' ~Leonardo da Vinci",
    "'Education is not the filling of a pail, but the lighting of a fire.' ~William Butler Yeats",
    "'The only person who is educated is the one who has learned how to learn and change.' ~Carl Rogers",
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = Random().nextInt(_messages.length);
    _startTimer();
    _navigateToLogin();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  void _navigateToLogin() {
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: CloudShapeContainer(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  _messages[_currentIndex],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Lottie.asset(
                  "assets/animations/animation_1709532387249.json",
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey[200]! // Set the color of the cloud
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(0, size.height * 0.25, size.width * 0.1, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.12, size.height * 0.15, size.width * 0.22, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.22, size.height * 0.05, size.width * 0.32, size.height * 0.05);
    path.quadraticBezierTo(size.width * 0.42, size.height * 0.05, size.width * 0.42, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.52, size.height * 0.15, size.width * 0.52, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.62, size.height * 0.25, size.width * 0.65, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.25, size.width * 0.85, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.25, size.width, size.height * 0.35);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class CloudShapeContainer extends StatelessWidget {
  final Widget child;

  CloudShapeContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CloudShapePainter(),
      child: ClipPath(
        clipper: _CloudShapeClipper(),
        child: Container(
          child: child,
        ),
      ),
    );
  }
}

class _CloudShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(0, size.height * 0.25, size.width * 0.1, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.12, size.height * 0.15, size.width * 0.22, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.22, size.height * 0.05, size.width * 0.32, size.height * 0.05);
    path.quadraticBezierTo(size.width * 0.42, size.height * 0.05, size.width * 0.42, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.52, size.height * 0.15, size.width * 0.52, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.62, size.height * 0.25, size.width * 0.65, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.25, size.width * 0.85, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.25, size.width, size.height * 0.35);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}