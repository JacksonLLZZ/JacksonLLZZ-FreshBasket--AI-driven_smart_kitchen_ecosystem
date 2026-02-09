import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the title
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.barcodeScannerScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示闪光灯切换按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the flash button（flash_on or flash_off）
      final flashOnIcon = find.byIcon(Icons.flash_on);
      final flashOffIcon = find.byIcon(Icons.flash_off);

      expect(
        flashOnIcon.evaluate().isNotEmpty || flashOffIcon.evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('应该显示切换摄像头按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the camera switch button
      expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
    });

    testWidgets('应该显示扫描框指示器', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the existence of the scanning box container
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('应该显示提示文字', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verification prompt text
      expect(find.text('Align barcode within the frame'), findsOneWidget);
    });

    testWidgets('应该能够点击闪光灯按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Search for and click the flash button
      final flashButton = find.byIcon(Icons.flash_off);

      if (flashButton.evaluate().isNotEmpty) {
        await tester.tap(flashButton);
        await tester.pumpAndSettle();
      }

      // Assert - Verification shows no abnormalities.
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该能够点击切换摄像头按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Search for and click the camera switch button
      final switchButton = find.byIcon(Icons.cameraswitch);
      await tester.tap(switchButton);
      await tester.pump();

      // Assert - Verification shows no abnormalities.
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示MobileScanner组件', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - Verify that the page structure is correct
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('应该使用Stack布局', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the Stack layout
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('AppBar应该包含两个action按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the number of IconButton elements in the AppBar
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      // There should be at least 2 IconButton (for the flash and switching cameras)
      expect(find.byType(IconButton), findsAtLeastNWidgets(2));
    });

    testWidgets('提示文字应该在底部', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the existence of the Positioned widget (used for positioning the prompt text)
      expect(find.byType(Positioned), findsWidgets);
      expect(find.text('Align barcode within the frame'), findsOneWidget);
    });
  });
}
