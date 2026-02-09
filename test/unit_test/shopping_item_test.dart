/// ShoppingItem data model test
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/shopping_cart/data/shopping_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('ShoppingItem Model -', () {
    test('The ShoppingItem instance should be created correctly', () {
      // Arrange & Act
      final item = ShoppingItem(
        id: '1',
        name: 'Tomato',
        amount: '2 pieces',
        addedAt: DateTime(2026, 2, 7),
      );

      // Assert
      expect(item.id, '1');
      expect(item.name, 'Tomato');
      expect(item.amount, '2 pieces');
      expect(item.addedAt, DateTime(2026, 2, 7));
    });

    test('The instance should be created using the create factory method', () {
      // Arrange
      final beforeCreate = DateTime.now();

      // Act
      final item = ShoppingItem.create(name: 'Milk', amount: '1 liter');

      final afterCreate = DateTime.now();

      // Assert
      expect(item.name, 'Milk');
      expect(item.amount, '1 liter');
      expect(item.id, '');
      expect(
        item.addedAt.isAfter(beforeCreate) || item.addedAt == beforeCreate,
        isTrue,
      );
      expect(
        item.addedAt.isBefore(afterCreate) || item.addedAt == afterCreate,
        isTrue,
      );
    });

    test('Should properly convert to Firestore format', () {
      // Arrange
      final item = ShoppingItem(
        id: '1',
        name: 'Bread',
        amount: '1 loaf',
        addedAt: DateTime(2026, 2, 7, 10, 30),
      );

      // Act
      final firestoreData = item.toFirestore();

      // Assert
      expect(firestoreData['name'], 'Bread');
      expect(firestoreData['amount'], '1 loaf');
      expect(firestoreData['addedAt'], isA<Timestamp>());
      expect(
        (firestoreData['addedAt'] as Timestamp).toDate(),
        DateTime(2026, 2, 7, 10, 30),
      );
    });

    test(
      'The instance should be created from the Firestore DocumentSnapshot',
      () async {
        // Arrange
        final fakeFirestore = FakeFirebaseFirestore();
        final testDate = DateTime(2026, 2, 7, 15, 45);

        await fakeFirestore.collection('test').doc('item1').set({
          'name': 'Cheese',
          'amount': '200g',
          'addedAt': Timestamp.fromDate(testDate),
        });

        final doc = await fakeFirestore.collection('test').doc('item1').get();

        // Act
        final item = ShoppingItem.fromFirestore(doc);

        // Assert
        expect(item.id, 'item1');
        expect(item.name, 'Cheese');
        expect(item.amount, '200g');
        expect(item.addedAt, testDate);
      },
    );

    test('fromFirestore should handle missing fields', () async {
      // Arrange
      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('test').doc('item2').set({
        'name': 'Apple',
      });

      final doc = await fakeFirestore.collection('test').doc('item2').get();

      // Act
      final item = ShoppingItem.fromFirestore(doc);

      // Assert
      expect(item.id, 'item2');
      expect(item.name, 'Apple');
      expect(item.amount, '');
      expect(item.addedAt, isNotNull);
      // addedAt It should be the current time
      final now = DateTime.now();
      final diff = now.difference(item.addedAt);
      expect(diff.inSeconds.abs(), lessThan(5));
    });

    test('fromFirestore should handle empty string fields', () async {
      // Arrange
      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('test').doc('item3').set({
        'name': '',
        'amount': '',
        'addedAt': Timestamp.now(),
      });

      final doc = await fakeFirestore.collection('test').doc('item3').get();

      // Act
      final item = ShoppingItem.fromFirestore(doc);

      // Assert
      expect(item.name, '');
      expect(item.amount, '');
    });
  });
}
