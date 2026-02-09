/// Test auxiliary tool class
///
/// Provide commonly used test tool functions and constants
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Initialize the test environment
///
/// Set up a test instance of Firebase and SharedPreferences
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences (using empty test data)
  SharedPreferences.setMockInitialValues({});

  // set Firebase mocks
  setupFirebaseCoreMocks();

  // initialize Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase may have been initialized, so ignore the error.
  }
}

/// set Firebase Core mocks
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Firebase Core method channel
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'Firebase#initializeCore') {
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'messagingSenderId': 'test-sender-id',
                'projectId': 'test-project',
              },
              'pluginConstants': {},
            },
          ];
        }
        if (methodCall.method == 'Firebase#initializeApp') {
          return {
            'name': methodCall.arguments['appName'],
            'options': methodCall.arguments['options'],
            'pluginConstants': {},
          };
        }
        return null;
      });

  // Mock Cloud Firestore method channel
  const MethodChannel firestoreChannel = MethodChannel(
    'plugins.flutter.io/cloud_firestore',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firestoreChannel, (
        MethodCall methodCall,
      ) async {
        // For all Firestore calls, return the appropriate mock data.
        if (methodCall.method == 'Query#snapshots') {
          // Return an empty snapshot stream
          return null;
        }
        return null;
      });

  // Mock Firebase Auth method channel
  const MethodChannel authChannel = MethodChannel(
    'plugins.flutter.io/firebase_auth',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(authChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'Auth#registerIdTokenListener') {
          return {'user': null};
        }
        if (methodCall.method == 'Auth#authStateChanges') {
          return null;
        }
        return null;
      });
}

/// Create a test Widget with Riverpod
Widget createTestApp({required Widget child, List<dynamic>? overrides}) {
  return ProviderScope(
    overrides: overrides?.cast() ?? [],
    child: MaterialApp(home: child),
  );
}

/// Wait for all asynchronous operations to complete
Future<void> pumpAndSettleWithDelay(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.pumpAndSettle();
  await Future.delayed(delay);
  await tester.pumpAndSettle();
}

/// Auxiliary methods for searching text
Finder findTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.data != null && widget.data!.contains(text),
  );
}

/// Test constants
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Test123456';
  static const String testUsername = 'Test User';

  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(milliseconds: 500);
}
