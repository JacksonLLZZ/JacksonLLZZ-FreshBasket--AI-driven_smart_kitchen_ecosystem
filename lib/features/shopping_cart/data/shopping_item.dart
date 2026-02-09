import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final String amount; // such as "2 cups", "100g", etc.
  final DateTime addedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.addedAt,
  });

  // From Firestore
  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'] ?? '',
      amount: data['amount'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  // Create a new shopping cart item
  factory ShoppingItem.create({required String name, required String amount}) {
    return ShoppingItem(
      id: '',
      name: name,
      amount: amount,
      addedAt: DateTime.now(),
    );
  }
}
