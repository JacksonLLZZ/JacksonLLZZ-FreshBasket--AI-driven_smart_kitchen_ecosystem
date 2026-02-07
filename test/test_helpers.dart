/// 测试辅助工具类
/// 
/// 提供常用的测试工具函数和常量
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

/// 初始化测试环境
/// 
/// 设置 Firebase 和 SharedPreferences 的测试实例
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 SharedPreferences (使用空的测试数据)
  SharedPreferences.setMockInitialValues({});
  
  // 设置 Firebase mocks
  setupFirebaseCoreMocks();
  
  // 初始化 Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase 可能已经初始化，忽略错误
  }
}

/// 设置 Firebase Core mocks
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
        }
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
      .setMockMethodCallHandler(firestoreChannel, (MethodCall methodCall) async {
    // 对于所有 Firestore 调用返回合适的 mock 数据
    if (methodCall.method == 'Query#snapshots') {
      // 返回一个空的 snapshot stream
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
      return {
        'user': null,
      };
    }
    if (methodCall.method == 'Auth#authStateChanges') {
      return null;
    }
    return null;
  });
}

/// 创建一个带有 Riverpod 的测试 Widget
Widget createTestApp({
  required Widget child,
  List<dynamic>? overrides,
}) {
  return ProviderScope(
    overrides: overrides?.cast() ?? [],
    child: MaterialApp(
      home: child,
    ),
  );
}

/// 等待所有异步操作完成
Future<void> pumpAndSettleWithDelay(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.pumpAndSettle();
  await Future.delayed(delay);
  await tester.pumpAndSettle();
}

/// 查找文本的辅助方法
Finder findTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!.contains(text),
  );
}

/// 测试用的常量
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Test123456';
  static const String testUsername = 'Test User';
  
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(milliseconds: 500);
}
