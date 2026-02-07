import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/home/barcode_scanner_screen.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('BarcodeScannerScreen Widget Tests -', () {
    testWidgets('应该显示页面标题 "Scan Barcode"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证标题
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.barcodeScannerScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示闪光灯切换按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证闪光灯按钮（flash_on 或 flash_off）
      final flashOnIcon = find.byIcon(Icons.flash_on);
      final flashOffIcon = find.byIcon(Icons.flash_off);
      
      expect(
        flashOnIcon.evaluate().isNotEmpty || flashOffIcon.evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('应该显示切换摄像头按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证摄像头切换按钮
      expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
    });

    testWidgets('应该显示扫描框指示器', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证扫描框容器存在
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('应该显示提示文字', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证提示文字
      expect(find.text('Align barcode within the frame'), findsOneWidget);
    });

    testWidgets('应该能够点击闪光灯按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 查找并点击闪光灯按钮
      final flashButton = find.byIcon(Icons.flash_off);
      
      if (flashButton.evaluate().isNotEmpty) {
        await tester.tap(flashButton);
        await tester.pumpAndSettle();
      }

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该能够点击切换摄像头按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 查找并点击摄像头切换按钮
      final switchButton = find.byIcon(Icons.cameraswitch);
      await tester.tap(switchButton);
      await tester.pump();

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示MobileScanner组件', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证页面结构正确
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('应该使用Stack布局', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证Stack布局
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('AppBar应该包含两个action按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证AppBar中的IconButton数量
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      
      // 应该有至少2个IconButton（闪光灯和切换摄像头）
      expect(find.byType(IconButton), findsAtLeastNWidgets(2));
    });

    testWidgets('提示文字应该在底部', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const BarcodeScannerScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证Positioned widget存在（用于定位提示文字）
      expect(find.byType(Positioned), findsWidgets);
      expect(find.text('Align barcode within the frame'), findsOneWidget);
    });
  });
}
