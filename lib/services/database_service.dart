import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/inventory/data/ingredient.dart';
import '../features/shopping_cart/data/shopping_item.dart';
import '../core/utils/food_validator.dart';

class DatabaseService {
  static const String _appId = "FreshBasket-app-v1";
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // theme related methods
  Future<void> updateTheme(String themeName) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .set({
          'theme': themeName,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<String> watchThemeSelection() {
    return getUserProfileStream().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['theme'] ?? 'Default';
      }
      return 'Default';
    });
  }

  //get user profile stream
  Stream<DocumentSnapshot> getUserProfileStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  Future<bool> userDocExists() async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<void> upsertUserProfile({
    required String username,
    required String email,
    String imageUrl = "",
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError("No user authenticated.");
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .set({
          'username': username,
          'email': email,
          'image_url': imageUrl,
          'updated_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // New: Update user allergens/dietary preferences
  Future<void> updateAllergens(List<String> allergens) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .set({
          'allergens': allergens,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .get();
    return doc.data();
  }

  // --- Ingredient inventory logic (unchanged) ---

  Future<void> saveIngredient(Ingredient item) async {
    final uid = _uid;
    if (uid == null) return;
    final docRef = _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(item.id);
    await docRef.set({
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'expiration_date': Timestamp.fromDate(item.expirationDate),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Ingredient>> getInventoryStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Ingredient(
              id: doc.id,
              name: data['name'] ?? '',
              quantity: (data['quantity'] ?? 0).toDouble(),
              unit: data['unit'] ?? '',
              expirationDate: (data['expiration_date'] as Timestamp).toDate(),
            );
          }).toList();
        });
  }

  /// Check if similar ingredient exists
  Future<Ingredient?> findSimilarIngredient(String name) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final snapshot = await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final existingName = data['name'] as String? ?? '';

        if (FoodValidator.isSimilarName(existingName, name)) {
          return Ingredient(
            id: doc.id,
            name: data['name'] ?? '',
            quantity: (data['quantity'] ?? 0).toDouble(),
            unit: data['unit'] ?? '',
            expirationDate: (data['expiration_date'] as Timestamp).toDate(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error finding similar ingredient: $e');
    }

    return null;
  }

  /// Merge ingredient quantity (update existing entry)
  Future<void> mergeIngredient(
    Ingredient existing,
    double additionalQty,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final totalQty = existing.quantity + additionalQty;

      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(existing.id)
          .update({
            'quantity': totalQty,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error merging ingredient: $e');
      rethrow;
    }
  }

  /// Delete specified ingredient
  Future<void> deleteIngredient(String ingredientId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(ingredientId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting ingredient: $e');
      rethrow;
    }
  }

  /// Batch delete expired ingredients
  Future<int> deleteExpiredIngredients() async {
    final uid = _uid;
    if (uid == null) return 0;

    try {
      final now = Timestamp.now();
      final snapshot = await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .where('expiration_date', isLessThan: now)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error deleting expired ingredients: $e');
      rethrow;
    }
  }

  /// Update ingredient expiration date
  Future<void> updateExpirationDate(
    String ingredientId,
    DateTime newDate,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(ingredientId)
          .update({
            'expiration_date': Timestamp.fromDate(newDate),
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating expiration date: $e');
      rethrow;
    }
  }

  /// Update ingredient information (quantity and expiration date)
  Future<void> updateIngredient(
    String ingredientId,
    double quantity,
    DateTime expirationDate,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(ingredientId)
          .update({
            'quantity': quantity,
            'expiration_date': Timestamp.fromDate(expirationDate),
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating ingredient: $e');
      rethrow;
    }
  }

  /// Batch delete ingredients
  Future<void> deleteMultipleIngredients(List<String> ingredientIds) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final batch = _db.batch();
      for (final id in ingredientIds) {
        final docRef = _db
            .collection('artifacts')
            .doc(_appId)
            .collection('users')
            .doc(uid)
            .collection('inventory')
            .doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting multiple ingredients: $e');
      rethrow;
    }
  }

  // ==================== Shopping Cart Methods ====================

  /// Add item to shopping cart
  Future<void> addToShoppingCart(ShoppingItem item) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('shopping_cart')
          .add(item.toFirestore());
    } catch (e) {
      debugPrint('Error adding to shopping cart: $e');
      rethrow;
    }
  }

  /// Get shopping cart item stream
  Stream<List<ShoppingItem>> getShoppingCartStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('shopping_cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();
        });
  }

  /// Remove item from shopping cart
  Future<void> removeFromShoppingCart(String itemId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('shopping_cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from shopping cart: $e');
      rethrow;
    }
  }

  /// Clear shopping cart
  Future<void> clearShoppingCart() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final snapshot = await _db
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(uid)
          .collection('shopping_cart')
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing shopping cart: $e');
      rethrow;
    }
  }
}
