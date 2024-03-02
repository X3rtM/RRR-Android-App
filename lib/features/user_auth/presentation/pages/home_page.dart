import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/ProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';
import 'TasksPage.dart';
import 'RewardsPage.dart';
import 'RedeemPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Result Reward Redemption System',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuthService().signOut();
              Navigator.pushNamed(context, "/login"); // Navigate to login page after sign-out
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.pink, Colors.blueAccent], // Adjust colors as needed
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                child: Container(
                  width: 150,
                  height: 50,
                  child: Center(child: Text('Profile', style: TextStyle(fontSize: 18))),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TasksPage()),
                  );
                },
                child: Container(
                  width: 150,
                  height: 50,
                  child: Center(child: Text('Tasks', style: TextStyle(fontSize: 18))),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RewardsPage()),
                  );
                },
                child: Container(
                  width: 150,
                  height: 50,
                  child: Center(child: Text('Rewards', style: TextStyle(fontSize: 18))),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RedeemPage()),
                  );
                },
                child: Container(
                  width: 150,
                  height: 50,
                  child: Center(child: Text('Redeem', style: TextStyle(fontSize: 18))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}