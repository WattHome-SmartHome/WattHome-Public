import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Login/adminCreateHome.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:watthome_app/Widgets/textField.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminCreateHome Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockDocumentReference mockDocumentReference;
    late MockCollectionReference mockCollectionReference;
    late MockDocumentSnapshot mockDocumentSnapshot;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockDocumentReference = MockDocumentReference();
      mockCollectionReference = MockCollectionReference();
      mockDocumentSnapshot = MockDocumentSnapshot();

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUid');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockFirebaseFirestore.collection('homes')).thenReturn(mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.add(any)).thenAnswer((_) async => mockDocumentReference);
      when(mockDocumentReference.collection('members')).thenReturn(mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.set(any)).thenAnswer((_) async => null);
      when(mockFirebaseFirestore.collection('users')).thenReturn(mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
      // when(mockDocumentReference.update(any)).thenAnswer((_) async => <String, dynamic>{});
    });

    testWidgets('Home name validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: AdminCreateHome()));

      await tester.enterText(find.byType(CustomTextField), '');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter a home name'), findsOneWidget);
    });

    testWidgets('Create home group successfully', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: AdminCreateHome()));

      await tester.enterText(find.byType(CustomTextField), 'Test Home');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(NavbarAdmin), findsOneWidget);
      expect(find.text('Home group "Test Home" created'), findsOneWidget);
    });

    testWidgets('Generate invite code', (WidgetTester tester) async {
      final state = AdminCreateHome().createState() as _AdminCreateHomeState;
      final inviteCode = state._generateInviteCode();

      expect(inviteCode.length, 5);
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(inviteCode), isTrue);
    });
  });
}

mixin _AdminCreateHomeState {
  _generateInviteCode() {}
}