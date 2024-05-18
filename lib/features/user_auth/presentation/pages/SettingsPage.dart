import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static ThemeMode currentThemeMode = ThemeMode.light;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: MyApp.currentThemeMode,
      home: HomePage(),
      // home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
          child: Text('Login'),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkModeEnabled = MyApp.currentThemeMode == ThemeMode.dark;
  String _selectedLanguage = 'English';
  bool _enableNotifications = true;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // remove next line to add back button in page near settings, upside left corner
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Notifications'),
            trailing: Switch(
              value: _enableNotifications,
              onChanged: (bool value) {
                setState(() {
                  _enableNotifications = value;
                  if (value) {
                    _firebaseMessaging.subscribeToTopic('tasks');
                  } else {
                    _firebaseMessaging.unsubscribeFromTopic('tasks');
                  }
                });
              },
            ),
          ),
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                  _toggleDarkMode(value);
                });
              },
            ),
          ),

          ListTile(
            title: Text('Logout'),
            onTap: () {
              Navigator.popUntil(context, ModalRoute.withName('/login'));
            },
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode(bool enabled) {
    setState(() {
      MyApp.currentThemeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
    runApp(MyApp());
  }
}