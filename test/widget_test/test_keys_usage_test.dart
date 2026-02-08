/// 使用 TestKeys 的 Widget 测试示例
/// 
/// 演示如何使用 TestKeys 常量来定位和操作 UI 元素
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/constants/test_keys.dart';

import '../test_helpers.dart';

void main() {
  group('使用 TestKeys 的测试示例 -', () {
    testWidgets('应该能通过 key 找到并操作按钮', (WidgetTester tester) async {
      // Arrange
      bool buttonPressed = false;
      final widget = createTestApp(
        child: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key(TestKeys.ingredientSaveButton),
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Save'),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.tap(find.byKey(const Key(TestKeys.ingredientSaveButton)));
      await tester.pumpAndSettle();

      // Assert
      expect(buttonPressed, isTrue);
    });

    testWidgets('应该能通过 key 找到并输入文本到 TextField', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final widget = createTestApp(
        child: Scaffold(
          body: Center(
            child: TextField(
              key: const Key(TestKeys.ingredientNameField),
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Ingredient Name',
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.enterText(
        find.byKey(const Key(TestKeys.ingredientNameField)),
        'Apple',
      );
      await tester.pumpAndSettle();

      // Assert
      expect(controller.text, 'Apple');
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('应该能通过索引 key 找到列表项', (WidgetTester tester) async {
      // Arrange
      final items = ['Apple', 'Banana', 'Orange'];
      final widget = createTestApp(
        child: Scaffold(
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                key: Key(TestKeys.listItem(TestKeys.inventoryItemTile, index)),
                title: Text(items[index]),
              );
            },
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert - 验证每个列表项都能通过 key 找到
      for (var i = 0; i < items.length; i++) {
        final key = Key(TestKeys.listItem(TestKeys.inventoryItemTile, i));
        expect(find.byKey(key), findsOneWidget);
      }
    });

    testWidgets('应该能通过 ID key 找到特定项', (WidgetTester tester) async {
      // Arrange
      const itemId = 'item_123';
      final widget = createTestApp(
        child: Scaffold(
          body: Center(
            child: Card(
              key: Key(TestKeys.itemWithId(TestKeys.inventoryItemTile, itemId)),
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      final key = Key(TestKeys.itemWithId(TestKeys.inventoryItemTile, itemId));
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('应该能组合使用多个 keys 进行复杂交互', (WidgetTester tester) async {
      // Arrange
      final nameController = TextEditingController();
      final qtyController = TextEditingController();
      bool saved = false;

      final widget = createTestApp(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  key: const Key(TestKeys.ingredientNameField),
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key(TestKeys.ingredientQuantityField),
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key(TestKeys.ingredientSaveButton),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        qtyController.text.isNotEmpty) {
                      saved = true;
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );

      // Act - 模拟用户填写表单并保存
      await tester.pumpWidget(widget);

      // 输入名称
      await tester.enterText(
        find.byKey(const Key(TestKeys.ingredientNameField)),
        'Chicken',
      );

      // 输入数量
      await tester.enterText(
        find.byKey(const Key(TestKeys.ingredientQuantityField)),
        '500',
      );

      // 点击保存按钮
      await tester.tap(find.byKey(const Key(TestKeys.ingredientSaveButton)));
      await tester.pumpAndSettle();

      // Assert
      expect(nameController.text, 'Chicken');
      expect(qtyController.text, '500');
      expect(saved, isTrue);
    });
  });
}
