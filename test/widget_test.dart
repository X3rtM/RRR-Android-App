import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/TasksPage.dart'; // Import the TasksPage widget
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void main() {
  // Mock FirebaseAuth and FirebaseFirestore instances
  group('TasksPage Widget Tests', () {
    late TasksPage tasksPage;

    setUp(() {
      tasksPage = TasksPage();
    });

    testWidgets('Test if TasksPage initializes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: tasksPage));

      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('Test if TasksPage fetches tasks for parent', (WidgetTester tester) async {
      // Mock currentUser and userType
      final MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
      final MockFirebaseFirestore mockFirebaseFirestore = MockFirebaseFirestore();

      when(mockFirebaseAuth.currentUser).thenReturn(MockUser());
      when(mockFirebaseAuth.currentUser!.uid).thenReturn('parent_uid');

      // Mock Firestore collection and document snapshots
      final mockCollection = MockCollectionReference();
      final mockDocument = MockDocumentSnapshot();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(mockFirebaseFirestore.collection('tasks')).thenReturn(mockCollection);
      when(mockCollection.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([mockDocument]);
      when(mockDocument.data()).thenReturn({
        'description': 'Task Description',
        'assignedTo': 'assigned_to_uid',
        'redeemPoints': 10,
        'dueDate': '2024-04-30',
        'addedOn': DateFormat('dd-MM-yyyy').format(DateTime.now()),
        'status': 'Incomplete',
      });

      // Set up widget with mocked dependencies
      await tester.pumpWidget(MaterialApp(
        home: tasksPage,
        navigatorObservers: [],
        builder: (BuildContext context, Widget? child) {
          return MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
              Provider<FirebaseFirestore>.value(value: mockFirebaseFirestore),
            ],
            child: tasksPage,
          );
        },
      ));

      await tester.pumpAndSettle();

      // Verify if the task description is rendered
      expect(find.text('Task Description'), findsOneWidget);
    });
  });
}

// Mock classes for FirebaseAuth and FirebaseFirestore
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}