import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/ProfilePage.dart';

import 'package:intl/intl.dart'; // Import intl package for date formatting
import '../../firebase_auth_implementation/firebase_auth_services.dart';

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


class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<TaskModel> tasks = [];
  String? selectedTask;
  DateTime? selectedDueDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks', style: TextStyle(fontSize: 22)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/task.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButton<String>(
                dropdownColor: Colors.blue, // Set dropdown background color
                value: selectedTask,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTask = newValue;
                  });
                },
                items: <String>[
                  'Solve 10 Maths Problems',
                  'Complete Science Project',
                  'Read a chapter of Marathi',
                  'Complete Maths Assignment',
                  'Write Essay on my school',
                  'Solve a History Quiz'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showAddTaskDialog(context);
              },
              child: Text('Add Task', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      title: Text(tasks[index].description,
                          style: TextStyle(fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned to: ${tasks[index].assignedTo}',
                              style: TextStyle(fontSize: 14)),
                          Text('Redeem Points: ${tasks[index].redeemPoints}',
                              style: TextStyle(fontSize: 14)),
                          Text('Added on: ${tasks[index].addedOn}',
                              style: TextStyle(fontSize: 14)),
                          Text('Due on: ${tasks[index].dueDate}',
                              style: TextStyle(fontSize: 14)),
                          Text(tasks[index].completed ? 'Completed' : 'Not Completed',
                              style: TextStyle(
                                fontSize: 14,
                                color: tasks[index].completed ? Colors.green : Colors.red,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    String description = selectedTask ?? '';
    String assignedTo = '';
    int? redeemPoints;
    DateTime? dueDate = selectedDueDate; // Variable to store the due date

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Task', style: TextStyle(fontSize: 20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      assignedTo = value;
                    },
                    decoration: InputDecoration(labelText: 'Assigned To'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      // Validate and parse the input as an integer
                      redeemPoints = _validateAndParse(value);
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Redeem Points'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: dueDate != null
                                ? DateFormat('dd MMM yyyy').format(dueDate!)
                                : '',
                          ),
                          decoration: InputDecoration(labelText: 'Due Date'),
                          onTap: () {
                            _selectDueDate(context, dueDate).then((value) {
                              if (value != null) {
                                setState(() {
                                  dueDate = value;
                                });
                              }
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _selectDueDate(context, dueDate).then((value) {
                            if (value != null) {
                              setState(() {
                                dueDate = value;
                              });
                            }
                          });
                        },
                        icon: Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel', style: TextStyle(fontSize: 18)),
                ),
                TextButton(
                  onPressed: () {
                    if (redeemPoints != null) {
                      setState(() {
                        tasks.add(TaskModel(
                          description: description,
                          assignedTo: assignedTo,
                          redeemPoints: redeemPoints!,
                          addedOn: DateFormat('dd MMM yyyy').format(DateTime.now()),
                          dueDate: dueDate != null
                              ? DateFormat('dd MMM yyyy').format(dueDate!)
                              : '',
                          completed: false, // Newly added field
                        ));
                      });
                      Navigator.of(context).pop();
                    } else {
                      // Show an error message or handle invalid input
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Error', style: TextStyle(fontSize: 20)),
                            content: Text(
                                'Please enter a number for Redeem Points.',
                                style: TextStyle(fontSize: 18)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK', style: TextStyle(fontSize: 18)),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text('Add', style: TextStyle(fontSize: 18)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectDueDate(BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    return picked;
  }

  int? _validateAndParse(String value) {
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }
}

class RewardsPage extends StatelessWidget {
  final List<RewardModel> rewards = [
    RewardModel(description: 'Extra 30 minutes of screen time', redeemPoints: 50),
    RewardModel(description: 'New toy', redeemPoints: 100),
    RewardModel(description: 'Trip to the zoo', redeemPoints: 150),
    RewardModel(description: 'Pizza party with friends', redeemPoints: 200),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards', style: TextStyle(fontSize: 22)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/reward.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 2,
              child: ListTile(
                title: Text(rewards[index].description,
                    style: TextStyle(fontSize: 16)),
                subtitle: Text('Redeem Points: ${rewards[index].redeemPoints}',
                    style: TextStyle(fontSize: 14)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RedeemPage extends StatefulWidget {
  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  int totalPoints = 300; // Example: Total points earned by the user
  List<RewardModel> redeemedRewards = []; // List to store redeemed rewards

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem', style: TextStyle(fontSize: 22)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/reward.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Available Points: $totalPoints',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: RewardsPage().rewards.length,
                itemBuilder: (context, index) {
                  final reward = RewardsPage().rewards[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      title: Text(reward.description,
                          style: TextStyle(fontSize: 16)),
                      subtitle: Text('Redeem Points: ${reward.redeemPoints}',
                          style: TextStyle(fontSize: 14)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _redeemReward(reward);
                        },
                        child: Text('Redeem'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redeemReward(RewardModel reward) {
    if (totalPoints >= reward.redeemPoints) {
      setState(() {
        redeemedRewards.add(reward);
        totalPoints -= reward.redeemPoints;
      });
      // Show a confirmation message or perform other actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reward.description} redeemed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show a message indicating insufficient points
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient points to redeem ${reward.description}'),
          duration: Duration(seconds: 2),
        ),
      );

    }
  }
}

class TaskModel {
  final String description;
  final String assignedTo;
  final int redeemPoints;
  final String addedOn;
  final String dueDate;
  final bool completed; // Newly added field

  TaskModel({
    required this.description,
    required this.assignedTo,
    required this.redeemPoints,
    required this.addedOn,
    required this.dueDate,
    required this.completed, // Newly added field
  });
}

class RewardModel {
  final String description;
  final int redeemPoints;

  RewardModel({required this.description, required this.redeemPoints});
}
