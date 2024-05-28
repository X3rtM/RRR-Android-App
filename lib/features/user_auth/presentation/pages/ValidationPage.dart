import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TasksPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ValidationPage extends StatefulWidget {
  @override
  _ValidationPageState createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  late List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasksForValidation();
  }

  Future<void> _fetchTasksForValidation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedBy', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'MarkedByChild') // Filter by completed tasks
            .get();

        setState(() {
          tasks = querySnapshot.docs
              .map((doc) => TaskModel.fromMap(
            doc.id,
            doc.data(),
            assignedBy: doc['assignedBy'],
          ))
              .toList();
        });
      } catch (e) {
        print('Error fetching tasks for validation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode=Theme.of(context).brightness==Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Validation Page'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Colors.grey,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: isDarkMode ? null: DecorationImage(
            image: AssetImage("assets/img/task.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskItem(task);
          },
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(task.description),
        subtitle: FutureBuilder(
          future: _fetchAssignedUserName(task.assignedTo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Assigned To: Loading...');
            } else if (snapshot.hasError) {
              return Text('Assigned To: Error loading user name');
            } else {
              final userName = snapshot.data;
              return Text('Assigned To: ${userName ?? 'Unknown'}');
            }
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _showAssignPointsDialog(task);
              },
              icon: Icon(Icons.check),
              color: Colors.green,
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _setTaskIncomplete(task);
              },
              icon: Icon(Icons.close),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  _setTaskIncomplete(TaskModel task) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'status': 'Incomplete',
      });
      _fetchTasksForValidation();
    } catch (e) {
      print('Error setting task incomplete: $e');
    }
  }

  Future<String?> _fetchAssignedUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null) {
        return userData['name']; // Return the user's name
      }
    } catch (e) {
      print('Error fetching assigned user name: $e');
    }
    return null;
  }

  _showAssignPointsDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) {
        int? assignedPoints;
        return AlertDialog(
          title: Text('Assign Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assign points for the task "${task.description}"'),
              SizedBox(height: 16),
              Text('Max Points: ${task.redeemPoints}'),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Points'),
                onChanged: (value) {
                  assignedPoints = int.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (assignedPoints != null &&
                    assignedPoints! <= task.redeemPoints) {
                  _completeTask(task, assignedPoints!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid points. Please enter valid points.'),
                    ),
                  );
                }
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  _completeTask(TaskModel task, int assignedPoints) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'status': 'MarkedByParent',
        'assignedPoints': assignedPoints,
      });
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(task.id).get();
      final userId = task.assignedTo; // Get userId from task
      print('Assigned Points: $assignedPoints');
      _updateUserPoints(assignedPoints, userId); // Pass userId
      _fetchTasksForValidation();
    } catch (e) {
      print('Error completing task: $e');
    }
  }

  Future<void> _updateUserPoints(int assignedPoints, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['userType'] == 'child') {
        final currentPoints = userData['cur_points'] ?? 0;
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'cur_points': currentPoints + assignedPoints, // Increment user points
        });
      }
    } catch (e) {
      print('Error updating user points: $e');
    }
  }
}