/// Widget test example using TestKeys
///
/// Demonstrate how to use TestKeys constants to locate and manipulate UI elements
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/constants/test_keys.dart';

import '../test_helpers.dart';

void main() {
  group('TestKeys usage test examples -', () {
    testWidgets('should be able to find and operate button via key', (WidgetTester tester) async {
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

    testWidgets('should be able to find and enter text into TextField via key', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      final widget = createTestApp(
        child: Scaffold(
          body: Center(
            child: TextField(
              key: const Key(TestKeys.ingredientNameField),
              controller: controller,
              decoration: const InputDecoration(labelText: 'Ingredient Name'),
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

    testWidgets('should be able to find list item via index key', (WidgetTester tester) async {
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

      // Assert - Verify that each list item can be found through the key.
      for (var i = 0; i < items.length; i++) {
        final key = Key(TestKeys.listItem(TestKeys.inventoryItemTile, i));
        expect(find.byKey(key), findsOneWidget);
      }
    });

    testWidgets('should be able to find specific item via ID key', (WidgetTester tester) async {
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

    testWidgets('should be able to combine multiple keys for complex interaction', (WidgetTester tester) async {
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
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key(TestKeys.ingredientQuantityField),
                  controller: qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
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

      // Act - Simulate a user filling out a form and saving it.
      await tester.pumpWidget(widget);

      // Enter the name
      await tester.enterText(
        find.byKey(const Key(TestKeys.ingredientNameField)),
        'Chicken',
      );

      // Input quantity
      await tester.enterText(
        find.byKey(const Key(TestKeys.ingredientQuantityField)),
        '500',
      );

      // Click the "Save" button
      await tester.tap(find.byKey(const Key(TestKeys.ingredientSaveButton)));
      await tester.pumpAndSettle();

      // Assert
      expect(nameController.text, 'Chicken');
      expect(qtyController.text, '500');
      expect(saved, isTrue);
    });
  });
}
