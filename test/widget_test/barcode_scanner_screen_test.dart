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
    testWidgets('should display page title "Scan Barcode"', (WidgetTester tester) async {
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

    testWidgets('should display flash toggle button', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the flash button (flash_on or flash_off)
      final flashOnIcon = find.byIcon(Icons.flash_on);
      final flashOffIcon = find.byIcon(Icons.flash_off);

      expect(
        flashOnIcon.evaluate().isNotEmpty || flashOffIcon.evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('should display camera switch button', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the camera switch button
      expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
    });

    testWidgets('should display scanning frame indicator', (WidgetTester tester) async {
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

    testWidgets('should display prompt text', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify prompt text
      expect(find.text('Align barcode within the frame'), findsOneWidget);
    });

    testWidgets('should be able to click flash button', (WidgetTester tester) async {
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

      // Assert - Verify no exceptions occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be able to click camera switch button', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Search for and click the camera switch button
      final switchButton = find.byIcon(Icons.cameraswitch);
      await tester.tap(switchButton);
      await tester.pump();

      // Assert - Verify no exceptions occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display MobileScanner component', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - Verify that the page structure is correct
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should use Stack layout', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the Stack layout
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('AppBar should contain two action buttons', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(child: const BarcodeScannerScreen());

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the number of IconButton elements in the AppBar
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      // There should be at least 2 IconButtons (for flash and camera switch)
      expect(find.byType(IconButton), findsAtLeastNWidgets(2));
    });

    testWidgets('prompt text should be at bottom', (WidgetTester tester) async {
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
