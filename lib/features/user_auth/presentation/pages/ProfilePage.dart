import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late CustomUser _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  String _photoURL = '';
  int _points = 0;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!;
    _user = CustomUser.fromUser(user);

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic>? userData =
        documentSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _photoURL = userData?['photoURL'] ?? '';
          _nameController.text = _capitalize(userData?['name'] ?? '');
          _dobController.text = userData?['dob'] ?? '';
          _mobileController.text = userData?['mobile'] ?? '';
          _ageController.text = _calculateAge(_dobController.text);
          _user = CustomUser(
            uid: _user.uid,
            email: _user.email,
            username: userData?['username'] ?? '',
            name: _user.name,
            age: _user.age,
            dob: _user.dob,
            mobile: _user.mobile,
            userType: userData?['userType'], // Assign userType from Firestore data
          );

          // Fetch points if the user is of type child
          if (_user.userType == 'child') {
            FirebaseFirestore.instance
                .collection('points')
                .doc(user.uid)
                .get()
                .then((DocumentSnapshot pointsSnapshot) {
              if (pointsSnapshot.exists) {
                Map<String, dynamic>? data =
                pointsSnapshot.data() as Map<String, dynamic>?;

                if (data != null) {
                  setState(() {
                    _points = data['points'] ?? 0;
                    print('Points: $_points');
                  });
                }
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _user.userType == 'child'
                  ? Text(
                '$_points points',
                style: TextStyle(fontSize: 16),
              )
                  : SizedBox.shrink(),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(user: _user),
                ),
              );
            },
            icon: Icon(Icons.edit),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/profile.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: _selectImage,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: _photoURL.isNotEmpty
                          ? NetworkImage(_photoURL)
                          : null,
                    ),
                    SizedBox(height: 10),
                    Text(
                      _user.username,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    _buildTableRow('Name', _nameController.text),
                    _buildTableRow('Email', _user.email),
                    _buildTableRow('Mobile Number', _mobileController.text),
                    _buildTableRow('Date of Birth', _dobController.text),
                    _buildTableRow('Age', _ageController.text),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value),
          ),
        ),
      ],
    );
  }

  void _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _saveImageToFirebase(imageFile);
    }
  }

  Future<void> _saveImageToFirebase(File imageFile) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      String uid = user.uid;

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('user_images').child('$uid.jpg');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoURL': imageUrl,
      });
      setState(() {
        _photoURL = imageUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    List<String> words = value.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return words.join(' ');
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return '';
    DateTime birthDate = DateFormat('dd-MM-yyyy').parse(dob);
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age.toString();
  }
}

class CustomUser {
  final String uid;
  final String email;
  final String username;
  final String? name;
  final String? age;
  final String? dob;
  final String? mobile;
  final String? userType;

  CustomUser({
    required this.uid,
    required this.email,
    required this.username,
    this.name,
    this.age,
    this.dob,
    this.mobile,
    this.userType,
  });

  factory CustomUser.fromUser(User user) {
    return CustomUser(
      uid: user.uid,
      email: user.email ?? '',
      username: user.displayName ?? '',
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final CustomUser user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late CustomUser _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;

    FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic>? userData =
        documentSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _nameController.text = userData?['name'] ?? '';
          _dobController.text = userData?['dob'] ?? '';
          _mobileController.text = userData?['mobile'] ?? '';
          _ageController.text = _calculateAge(_dobController.text);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            onPressed: () {
              _saveProfileChanges();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (text) {
                _nameController.value = TextEditingValue(
                  text: _capitalize(text),
                  selection: _nameController.selection,
                );
              },
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _selectDate(context);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _dobController,
                  decoration: InputDecoration(labelText: 'Date of Birth (DD-MM-YYYY)'),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{0,10}$')),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    List<String> words = value.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return words.join(' ');
  }

  void _saveProfileChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({
        'name': _nameController.text,
        'dob': _dobController.text,
        'mobile': _mobileController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
        _ageController.text = _calculateAge(_dobController.text);
      });
    }
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return '';
    DateTime birthDate = DateFormat('dd-MM-yyyy').parse(dob);
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age.toString();
  }
}
