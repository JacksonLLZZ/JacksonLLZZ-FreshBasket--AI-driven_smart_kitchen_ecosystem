import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/assistant/presentation/assistant_screen.dart';
import '../test_helpers.dart';

void main() {
  group('AssistantScreen -', () {
    testWidgets('should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      expect(find.byType(AssistantScreen), findsOneWidget);
    });

    testWidgets('should display app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display initial welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("Hello! I'm your kitchen AI assistant"), findsOneWidget);
    });

    testWidgets('should display text input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask me about recipes, ingredients...'), findsOneWidget);
    });

    testWidgets('should display send button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should display AI assistant avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('should display message list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should allow entering text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'test message');
      await tester.pump();

      expect(find.text('test message'), findsOneWidget);
    });

    testWidgets('should show loading indicator when sending message', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('send button should be disabled when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Button should be disabled (find IconButton with null onPressed)
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('should display user message after sending', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      await tester.enterText(find.byType(TextField), 'test message');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // User message should appear
      expect(find.text('test message'), findsOneWidget);
    });

    testWidgets('should clear text field after sending', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Text field should be empty
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('should not send empty messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );
      await tester.pumpAndSettle();

      final initialMessageCount = find.byType(Container).evaluate().length;

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message count should not increase
      final finalMessageCount = find.byType(Container).evaluate().length;
      expect(finalMessageCount, equals(initialMessageCount));
    });

    testWidgets('should display message timestamps', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );
      await tester.pumpAndSettle();

      // Timestamp format is HH:mm, should find time-like text
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('input field should have proper decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, equals('Ask me about recipes, ingredients...'));
      expect(textField.decoration?.filled, isTrue);
    });

    testWidgets('should allow submitting with keyboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(child: const AssistantScreen()),
      );

      await tester.enterText(find.byType(TextField), 'keyboard submit');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Message should be sent
      expect(find.text('keyboard submit'), findsOneWidget);
    });
  });
}
