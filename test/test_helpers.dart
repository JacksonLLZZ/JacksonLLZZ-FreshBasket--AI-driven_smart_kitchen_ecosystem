/// 测试辅助工具类
/// 
/// 提供常用的测试工具函数和常量
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
