import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

enum SortBy {
  Name,
  DueDate,
  AssignedOn,
  Points,
}

DateTime _parseDate(String dateString) {
  List<String> dateParts = dateString.split('-');
  int year = int.parse(dateParts[2]);
  int month = int.parse(dateParts[1]);
  int day = int.parse(dateParts[0]);
  return DateTime(year, month, day);
}

class _TasksPageState extends State<TasksPage> {
  late User currentUser;
  String userType = '';
  late List<TaskModel> tasks = [];
  SortBy sortBy = SortBy.Name;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _isMounted = true;
    _getUserType(currentUser.uid);
  }

  @override
  void dispose() {
    _isMounted = false; // Set flag to false when disposed
    super.dispose();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc['userType'];
      if (userType == 'parent') {
        _fetchTasks(userType, userId);
      } else if (userType == 'child') {
        _fetchChildTasks(userId);
      }
    });
  }

  Future<void> _fetchTasks(String userType, String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where(userType == 'parent' ? 'assignedBy' : 'assignedTo',
          isEqualTo: userId)
          .get();

      final List<TaskModel> allTasks = querySnapshot.docs.map((doc) {
        return TaskModel.fromMap(
          doc.id,
          doc.data(),
          assignedBy: doc['assignedBy'],
        );
      }).toList();

      // Sorting tasks by user names
      if (_isMounted) {
        allTasks.sort((task1, task2) {
          switch (sortBy) {
            case SortBy.Name:
              return task1.assignedTo
                  .toLowerCase()
                  .compareTo(task2.assignedTo.toLowerCase());
            case SortBy.DueDate:
              return task1.dueDate.compareTo(task2.dueDate);
            case SortBy.AssignedOn:
              return task1.addedOn.compareTo(task2.addedOn);
            case SortBy.Points:
              return task1.redeemPoints.compareTo(task2.redeemPoints);
          }
        });

        if (_isMounted) {
          setState(() {
            tasks = allTasks;
          });
        }
      }
    } catch (e) {
      if (_isMounted) {
        print('Error fetching tasks: $e');
      }
    }
  }

  Future<void> _fetchChildTasks(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .get();

      final List<TaskModel> allTasks = querySnapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.id, doc.data(), assignedBy: '');
      }).toList();

      if (_isMounted) {
        if (_searchText.isNotEmpty) {
          allTasks.retainWhere((task) =>
              task.description.toLowerCase().contains(_searchText.toLowerCase()));
        }

        // Sort tasks based on selected criteria
        allTasks.sort((task1, task2) {
          switch (sortBy) {
            case SortBy.Name:
              return task1.description
                  .toLowerCase()
                  .compareTo(task2.description.toLowerCase());
            case SortBy.DueDate:
              return _parseDate(task1.dueDate)
                  .compareTo(_parseDate(task2.dueDate));
            case SortBy.AssignedOn:
              return _parseDate(task1.addedOn)
                  .compareTo(_parseDate(task2.addedOn));
            case SortBy.Points:
              return task1.redeemPoints.compareTo(task2.redeemPoints);
            default:
              return 0;
          }
        });

        setState(() {
          tasks = allTasks;
        });
      }
    } catch (e) {
      if (_isMounted) {
        print('Error fetching child tasks: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Tasks'),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Only set the image if the theme is not dark
          image: isDarkMode ? null : DecorationImage(
            image: AssetImage('assets/img/task.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: userType == 'child' ? _buildChildTasks() : _buildParentTasks(),
      ),
    );
  }

  Widget _buildParentTasks() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _showAddTaskDialog();
          },
          child: Text('Add Task'),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSearchBar((filteredTasks) {
                  setState(() {
                    tasks = filteredTasks;
                  });
                }, isParent: true),
              ),
            ),
            PopupMenuButton<SortBy>(
              icon:Icon(Icons.sort),
              onSelected: (sortBy) {
                setState(() {
                  this.sortBy = sortBy;
                });
                _fetchTasks('parent', userId);
                },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                PopupMenuItem<SortBy>(
                  value: SortBy.DueDate,
                  child: Text('Sort by Due Date'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.AssignedOn,
                  child: Text('Sort by Assigned On'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.Name,
                  child: Text('Sort by Name'),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (option) {
                if (option == 'Task History') {
                  setState(() {
                    tasks = tasks.where((task) => task.status == 'MarkedByParent').toList();
                  });
                } else {
                  _fetchTasks('parent', userId);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'Task History',
                  child: Text('Task History'),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              List<TaskModel> tasksList = tasks;
              if (snapshot.hasData) {
                tasksList = tasksList.where((task) {
                  return task.description.toLowerCase().contains(_searchText.toLowerCase()) ||
                      task.assignedTo.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();

                tasksList = tasksList.where((task) => task.status != 'Completed').toList(); // Filter incomplete tasks

                tasksList.sort((a, b) {
                  switch (sortBy) {
                    case SortBy.Name:
                      return a.assignedTo.toLowerCase().compareTo(b.assignedTo.toLowerCase());
                    case SortBy.DueDate:
                      return _parseDate(b.dueDate).compareTo(_parseDate(a.dueDate)); // Sort in descending order
                    case SortBy.AssignedOn:
                      return _parseDate(b.addedOn).compareTo(_parseDate(a.addedOn)); // Sort in descending order
                    case SortBy.Points:
                      return a.redeemPoints.compareTo(b.redeemPoints);
                    default:
                      return 0; // Default case
                  }
                });
              }

              return ListView.builder(
                itemCount: tasksList.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(tasksList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChildTasks() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSearchBar((filteredTasks) {
                  setState(() {
                    tasks = filteredTasks;
                  });
                }, isParent: false),
              ),
            ),
            PopupMenuButton<SortBy>(
              onSelected: (sortBy) {
                setState(() {
                  this.sortBy = sortBy;
                });
                _fetchTasks('child', userId); // Fetch tasks with updated sorting
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                PopupMenuItem<SortBy>(
                  value: SortBy.DueDate,
                  child: Text('Sort by Due Date'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.AssignedOn,
                  child: Text('Sort by Assigned On'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.Points,
                  child: Text('Sort by Points'),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              List<TaskModel> tasksList = tasks;
              if (snapshot.hasData) {
                tasksList = tasksList.where((task) {
                  return task.description.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();
                switch (sortBy) {
                  case SortBy.DueDate:
                    tasksList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                    break;
                  case SortBy.AssignedOn:
                    tasksList.sort((a, b) => a.addedOn.compareTo(b.addedOn));
                    break;
                  case SortBy.Points:
                    tasksList.sort((a, b) => a.redeemPoints.compareTo(b.redeemPoints));
                    break;
                  default:
                    break;
                }
              }
              return ListView.builder(
                itemCount: tasksList.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(tasksList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<TaskModel> filterAndSortTasks(List<TaskModel> allTasks) {
    String searchQuery = _searchController.text.toLowerCase();
    List<TaskModel> filteredTasks = allTasks.where((task) =>
    task.description.toLowerCase().contains(searchQuery) ||
        task.assignedTo.toLowerCase().contains(searchQuery)).toList();

    switch (sortBy) {
      case SortBy.DueDate:
        filteredTasks.sort((task1, task2) => task1.dueDate.compareTo(task2.dueDate));
        break;
      case SortBy.AssignedOn:
        filteredTasks.sort((task1, task2) => task1.addedOn.compareTo(task2.addedOn));
        break;
      case SortBy.Name:
        filteredTasks.sort((task1, task2) => task1.assignedTo.toLowerCase().compareTo(task2.assignedTo.toLowerCase()));
        break;
      default:
        break;
    }
    return filteredTasks;
  }

  TextField buildSearchBar(Function(List<TaskModel>) filterTasks, {required bool isParent}) {
    return TextField(
      controller: _searchController, // Use the search controller
      onChanged: (value) {
        setState(() {
          _searchText = value; // Update the search text
        });
        List<TaskModel> filtered = tasks.where((task) {
          if (isParent) {
            return task.description.toLowerCase().contains(_searchText.toLowerCase()) ||
                task.assignedTo.toLowerCase().contains(_searchText.toLowerCase());
          } else {
            return task.description.toLowerCase().contains(_searchText.toLowerCase());
          }
        }).toList();
        filterTasks(filtered);
      },
      decoration: InputDecoration(
        hintText: isParent ? 'Search by description or name' : 'Search by description',
        border: OutlineInputBorder(),
      ),
    );
  }

  String _formatDate(String dateString) {
    // Split the dateString using "-" as the separator
    List<String> dateParts = dateString.split('-');

    // Ensure that there are three parts (day, month, year)
    if (dateParts.length == 3) {
      int day = int.tryParse(dateParts[0]) ?? 0;
      int month = int.tryParse(dateParts[1]) ?? 0;
      int year = int.tryParse(dateParts[2]) ?? 0;

      // Create a DateTime object from the parsed parts
      DateTime dateTime = DateTime(year, month, day);

      // Format the DateTime object as required
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

      return formattedDate;
    } else {
      return ''; // Return empty string if the date format is invalid
    }
  }

  Widget _buildTaskItem(TaskModel task) {
    Color statusColor;
    String statusText;
    switch (task.status) {
      case 'Incomplete':
        statusColor = Colors.red;
        statusText = 'Incomplete';
        break;
      case 'MarkedByParent':
        statusColor = Colors.green;
        statusText = 'Marked by Parent';
        break;
      case 'MarkedByChild':
        statusColor = Colors.blue;
        statusText = 'Marked by Child';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Incomplete';
        break;
    }

    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              task.description,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Assigned On, Deadline
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned On:\n${_formatDate(task.addedOn)}'),
                      SizedBox(height: 5),
                      Text('Deadline:\n${_formatDate(task.dueDate)}'),
                      SizedBox(height: 1),
                    ],
                  ),
                ),
                SizedBox(width: 1.5),
                // Column 2: Points, Assigned To
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points:\n${task.redeemPoints}'),
                      SizedBox(height: 5),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(task.assignedTo).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Assigned To: Loading...'); // Show loading indicator
                          }
                          if (snapshot.hasError) {
                            return Text('Error: Unable to fetch user data'); // Show error message
                          }
                          if (snapshot.hasData && snapshot.data!.exists) {
                            Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;

                            // Display the name of the child user
                            return Text('Assigned To: \n${userData?['name'] ?? 'Unknown'}');
                          } else {
                            return Text('Assigned To: Unknown'); // Show if user data doesn't exist
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 1),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (userType == 'parent') ...[
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _showEditTaskDialog(task);
                                },
                              ),
                              SizedBox(width: 0.5), // Adjust spacing between icons
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _removeTask(task);
                                },
                              ),
                            ],
                            if (userType == 'child' && task.status == 'Incomplete')
                              IconButton(
                                icon: Icon(Icons.check,color: Colors.green),
                                onPressed: () {
                                  _updateTaskStatus(task, 'MarkedByChild');
                                },
                              ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left:16, top:1, bottom:8),
            child: Text('Status: $statusText', style: TextStyle(color: statusColor)),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(TaskModel task, String updatedStatus) {
    String taskId = task.id;

    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': updatedStatus,
    }).then((_) {
      setState(() {
        task.status = updatedStatus;
      });
      print('Task status updated successfully');
    }).catchError((error) {
      print('Error updating task status: $error');
    });
  }

  void _showAddTaskDialog() {
    String description = '';
    String assignedTo = '';
    int redeemPoints = 0;
    String dueDate = '';

    bool descriptionError = false;
    bool assignedToError = false;
    bool redeemPointsError = false;
    bool dueDateError = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        errorText: descriptionError ? 'Description cannot be empty' : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          description = value;
                          descriptionError = value.isEmpty;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Assigned To',
                        errorText: assignedToError ? 'Assigned To cannot be empty' : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          assignedTo = value;
                          assignedToError = value.isEmpty;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Redeem Points',
                        errorText: redeemPointsError ? 'Redeem Points cannot be empty' : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          redeemPoints = int.tryParse(value) ?? 0;
                          redeemPointsError = value.isEmpty;
                        });
                      },
                    ),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                dueDate = DateFormat('dd-MM-yyyy').format(selectedDate);
                                dueDateError = false;
                              });
                            }
                          },
                          child: Text(
                            dueDate.isEmpty ? 'Select Due Date' : dueDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (description.isEmpty) setState(() => descriptionError = true);
                    if (assignedTo.isEmpty) setState(() => assignedToError = true);
                    if (redeemPoints == 0) setState(() => redeemPointsError = true);
                    if (dueDate.isEmpty) setState(() => dueDateError = true);

                    if (!descriptionError && !assignedToError && !redeemPointsError && !dueDateError) {
                      _addTask(description, assignedTo, redeemPoints, dueDate);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    String description = task.description;
    String assignedTo = task.assignedTo;
    int redeemPoints = task.redeemPoints;
    String dueDate = task.dueDate;

    bool descriptionError = false;
    bool assignedToError = false;
    bool redeemPointsError = false;
    bool dueDateError = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        errorText: descriptionError ? 'Description cannot be empty' : null,
                      ),
                      controller: TextEditingController(text: description),
                      onChanged: (value) {
                        setState(() {
                          description = value;
                          descriptionError = value.isEmpty;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Assigned To',
                        errorText: assignedToError ? 'Assigned To cannot be empty' : null,
                      ),
                      controller: TextEditingController(text: assignedTo),
                      onChanged: (value) {
                        setState(() {
                          assignedTo = value;
                          assignedToError = value.isEmpty;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Redeem Points',
                        errorText: redeemPointsError ? 'Redeem Points cannot be empty' : null,
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: redeemPoints.toString()),
                      onChanged: (value) {
                        setState(() {
                          redeemPoints = int.tryParse(value) ?? 0;
                          redeemPointsError = value.isEmpty;
                        });
                      },
                    ),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateFormat('dd-MM-yyyy').parse(dueDate),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                dueDate = DateFormat('dd-MM-yyyy').format(selectedDate);
                                dueDateError = false;
                              });
                            }
                          },
                          child: Text(
                            dueDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (description.isEmpty) setState(() => descriptionError = true);
                if (assignedTo.isEmpty) setState(() => assignedToError = true);
                if (redeemPoints == 0) setState(() => redeemPointsError = true);
                if (dueDate.isEmpty) setState(() => dueDateError = true);

                if (!descriptionError && !assignedToError && !redeemPointsError && !dueDateError) {
                  _updateTask(task.id, description, assignedTo, redeemPoints, dueDate);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _resolveUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['name'];
    } else {
      return '';
    }
  }

  Stream<String> _resolveUserNameStream(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot['name'];
      } else {
        return '';
      }
    });
  }

  void _addTask(String description, String assignedToName, int redeemPoints, String dueDate) async {
    String assignedBy = FirebaseAuth.instance.currentUser!.uid;
    String assignedToUid = await _resolveUserUID(assignedToName); // Resolve UID from name

    try {
      DocumentReference newTaskRef = await FirebaseFirestore.instance.collection('tasks').add({
        'description': description,
        'assignedTo': assignedToUid, // Save UID instead of name
        'redeemPoints': redeemPoints,
        'dueDate': dueDate,
        'addedOn': DateFormat('dd-MM-yyyy').format(DateTime.now()),
        'status': "Incomplete",
        'assignedBy': assignedBy,
      });

      String taskId = newTaskRef.id;
      setState(() {
        tasks.add(TaskModel(
          id: taskId,
          description: description,
          assignedTo: assignedToUid, // Save UID instead of name
          redeemPoints: redeemPoints,
          dueDate: dueDate,
          addedOn: DateFormat('dd-MM-yyyy').format(DateTime.now()), // This line was missing in your original code
          assignedBy: assignedBy,
          status: "Incomplete",
        ));
      });

      print('Task added successfully');
      _fetchTasks('parent', assignedBy);
    } catch (error) {
      print('Error adding task: $error');
    }
  }

  Future<String> _resolveUserUID(String assignedTo) async {
    String assignedToUid = '';
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: assignedTo)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      assignedToUid = userSnapshot.docs.first.id;
    }

    return assignedToUid;
  }

  void _updateTask(String taskId, String description, String assignedTo, int redeemPoints, String dueDate) {
    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'description': description,
      'assignedTo': assignedTo,
      'redeemPoints': redeemPoints,
      'dueDate': dueDate,
    }).then((_) {
      print('Task updated successfully');
      String userId = FirebaseAuth.instance.currentUser!.uid;
      _fetchTasks('parent', userId);
    }).catchError((error) {
      print('Error updating task: $error');
    });
  }

  void _removeTask(TaskModel task) {
    FirebaseFirestore.instance.collection('tasks').doc(task.id).delete().then((_) {
      print('Task deleted successfully');
      String userId = FirebaseAuth.instance.currentUser!.uid;
      _fetchTasks('parent', userId);
    }).catchError((error) {
      print('Error deleting task: $error');
    });
  }
}

class TaskModel {
  final String id;
  final String description;
  final String assignedTo;
  final int redeemPoints;
  final String dueDate;
  final String addedOn;
  final String assignedBy; // Added assignedBy field
  String status;

  TaskModel({
    required this.id,
    required this.description,
    required this.assignedTo,
    required this.redeemPoints,
    required this.dueDate,
    required this.addedOn,
    required this.assignedBy, // Added assignedBy parameter
    required this.status,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> data, {required String assignedBy}) {
    return TaskModel(
      id: id,
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      redeemPoints: data['redeemPoints'] ?? 0,
      dueDate: data['dueDate'] ?? '',
      addedOn: data['addedOn'] ?? '',
      assignedBy: assignedBy, // Assign the value of assignedBy
      status: data['status'] ?? 'Incomplete', // Default value
    );
  }
}