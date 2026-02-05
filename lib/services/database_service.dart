import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/inventory/data/ingredient.dart';
import '../core/utils/food_validator.dart';

class DatabaseService {
  static const String _appId = "nutriscan-app-v1";
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

  // 新增：更新用户过敏原/饮食偏好
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

  // --- 食材库存逻辑 (保持不变) ---

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

  /// 检查是否存在相似的食材
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

  /// 合并食材数量(更新现有条目)
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

  /// 删除指定食材
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

  /// 批量删除过期食材
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

  /// 更新食材过期日期
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

  /// 更新食材信息（数量和过期日期）
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

  /// 批量删除食材
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
}
