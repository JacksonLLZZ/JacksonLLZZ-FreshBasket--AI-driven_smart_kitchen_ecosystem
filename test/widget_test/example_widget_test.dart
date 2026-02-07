/// Widget 测试示例
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('Widget Test Examples -', () {
    testWidgets('应该显示简单的文本 Widget', (WidgetTester tester) async {
      // Arrange
      const testText = 'Hello Kitchen App';
      final widget = createTestApp(
        child: const Scaffold(
          body: Center(
            child: Text(testText),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('应该响应按钮点击', (WidgetTester tester) async {
      // Arrange
      int counter = 0;
      final widget = createTestApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Counter: $counter'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          counter++;
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 初始状态
      expect(find.text('Counter: 0'), findsOneWidget);

      // Act - 点击按钮
      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();

      // Assert - 验证状态更新
      expect(find.text('Counter: 1'), findsOneWidget);
    });

    testWidgets('应该能找到包含特定文本的 Widget', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Kitchen App - Home'),
          ),
          body: const Center(
            child: Text('Welcome to our Kitchen Management System'),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      expect(findTextContaining('Kitchen'), findsNWidgets(2));
      expect(findTextContaining('Welcome'), findsOneWidget);
      expect(findTextContaining('Management'), findsOneWidget);
    });

    testWidgets('应该能测试表单输入', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final widget = createTestApp(
        child: Scaffold(
          body: Center(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Enter ingredient name',
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.pumpAndSettle();

      // Assert
      expect(controller.text, 'Apple');
      expect(find.text('Apple'), findsOneWidget);
    });
  });
}
