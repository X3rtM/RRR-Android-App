import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RedeemPage extends StatefulWidget {
  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  late User currentUser;
  String userType = '';
  late List<RedeemModel> rewards = [];
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _getUserType(currentUser.uid);
    dateController = TextEditingController();
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userType = userDoc['userType']?.toString() ?? ''; // Safely handle null value
    setState(() {
      this.userType = userType;
      _fetchRewards();
    });
  }

  Future<void> _fetchRewards() async {
    try {
      QuerySnapshot querySnapshot;
      // Fetch rewards assigned to the current user
      querySnapshot = await FirebaseFirestore.instance
          .collection('rewards')
          .where('assignedTo', isEqualTo: currentUser.uid)
          .get();

      final List<RedeemModel> allRewards = querySnapshot.docs.map((doc) {
        return RedeemModel.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        rewards = allRewards;
      });
    } catch (e) {
      print('Error fetching rewards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Rewards'),
        actions: [
          if (userType == 'child')
            PopupMenuButton<int>(
              onSelected: (item) => _onSelected(context, item),
              itemBuilder: (context) => [
                PopupMenuItem<int>(value: 0, child: Text('Redeem History')),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          isDarkMode ? SizedBox.shrink() : Image.asset(
            'assets/img/reward.jpg', // Replace 'assets/background.jpg' with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: _buildChildRewards(),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildChildRewards() {
    return ListView.builder(
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return _buildRewardItem(rewards[index]);
      },
    );
  }

  Widget _buildRewardItem(RedeemModel reward) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          reward.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points: ${reward.points}',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            if (reward.dateUpTo != null)
              Text(
                'Date Up To: ${DateFormat('dd MMM yyyy').format(reward.dateUpTo!)}',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _redeemReward(reward);
          },
          child: Text('Redeem'),
        ), // Moved redeem button to the right side
      ),
    );
  }

  Future<void> _redeemReward(RedeemModel reward) async {
    try {
      // Get the current user document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      // Get the current user's points from the document
      final int? userPoints = userDoc['cur_points'];

      if (userPoints != null && userPoints >= reward.points) {
        // Update user points in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'cur_points': userPoints - reward.points});

        // Add to redeem history in Firestore
        await FirebaseFirestore.instance.collection('redeemHistory').add({
          'userId': currentUser.uid,
          'rewardId': reward.id,
          'rewardName': reward.name,
          'points': reward.points,
          'redeemedAt': Timestamp.now(),
        });

        // Remove the redeemed reward from the redeem section
        await FirebaseFirestore.instance.collection('rewards').doc(reward.id).delete();

        // Update UI by fetching rewards again
        _fetchRewards();

        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reward.name} redeemed successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show message indicating insufficient points
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough points to redeem this reward right now.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error redeeming reward: $e');
    }
  }

  Future<void> _onSelected(BuildContext context, int item) async {
    switch (item) {
      case 0:
        await _showRedeemHistory(context);
        break;
    }
  }

  Future<void> _showRedeemHistory(BuildContext context) async {
    try {
      // Fetch redeem history for the current user
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('redeemHistory')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final List<RedeemModel> history = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RedeemModel(
          id: doc.id,
          name: data['rewardName'],
          points: data['points'],
          dateUpTo: (data['redeemedAt'] as Timestamp).toDate(),
        );
      }).toList();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Redeem History'),
            content: Container(
              width: double.maxFinite,
              child: history.isEmpty
                  ? Center(child: Text('No history available'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final reward = history[index];
                  return ListTile(
                    title: Text(reward.name),
                    subtitle: Text(
                      'Redeemed on: ${DateFormat('dd MMM yyyy').format(reward.dateUpTo!)}',
                    ),
                  );
                },
              ),
            ),
            actions: [
              if (userType == 'child')
                TextButton(
                  onPressed: () async {
                    await _deleteAllRedeemHistory();
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Delete All'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching redeem history: $e');
    }
  }

  Future<void> _deleteAllRedeemHistory() async {
    try {
      // Fetch all redeem history documents for the current user
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('redeemHistory')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Delete each document
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All redeem history deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting redeem history: $e');
    }
  }
}

class RedeemModel {
  final String id;
  final String name;
  final int points;
  final DateTime? dateUpTo; // Date up to field

  RedeemModel({
    required this.id,
    required this.name,
    required this.points,
    this.dateUpTo, // Initialize dateUpTo field
  });

  factory RedeemModel.fromMap(String id, dynamic data) {
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    return RedeemModel(
      id: id,
      name: map['name'],
      points: map['points'],
      dateUpTo: map['dateUpTo'] != null ? (map['dateUpTo'] as Timestamp)
          .toDate() : null, // Assign dateUpTo value
    );
  }
}

