import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedTo', isEqualTo: currentUser.uid)
            .where('status', whereIn: ['Incomplete', 'MarkedByParent'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return NotificationItem(taskData: doc.data() as Map<String, dynamic>);
            }).toList(),
          );
        },
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> taskData;

  NotificationItem({required this.taskData});

  @override
  Widget build(BuildContext context) {
    final String description = taskData['description'];
    final String status = taskData['status'];

    // Check if the task is newly added based on its status
    final bool isNewTask = status == 'Incomplete' || status == 'MarkedByParent';

    return Card(
      child: ListTile(
        title: Text(isNewTask ? 'A new task has been assigned to you' : description),
        subtitle: Text('Status: $status'),
        trailing: Text(taskData['dueDate']),
      ),
    );
  }
}


