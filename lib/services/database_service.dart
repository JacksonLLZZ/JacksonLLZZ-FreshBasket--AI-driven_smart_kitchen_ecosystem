import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/inventory/data/ingredient.dart';

class DatabaseService {
  static const String _appId = "nutriscan-app-v1";
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // theme related methods
  Future<void> updateTheme(String themeName) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('artifacts').doc(_appId).collection('users').doc(uid).set({
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
    return _db.collection('artifacts').doc(_appId).collection('users').doc(uid).snapshots();
  }

  Future<bool> userDocExists() async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _db.collection('artifacts').doc(_appId).collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> upsertUserProfile({
    required String username,
    required String email,
    String imageUrl = "",
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError("No user authenticated.");
    await _db.collection('artifacts').doc(_appId).collection('users').doc(uid).set({
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
    await _db.collection('artifacts').doc(_appId).collection('users').doc(uid).set({
      'allergens': allergens,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('artifacts').doc(_appId).collection('users').doc(uid).get();
    return doc.data();
  }

  // --- 食材库存逻辑 (保持不变) ---
  
  Future<void> saveIngredient(Ingredient item) async {
    final uid = _uid;
    if (uid == null) return;
    final docRef = _db.collection('artifacts').doc(_appId).collection('users').doc(uid).collection('inventory').doc(item.id);
    await docRef.set({
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'category': item.category,
      'calories': item.calories,
      'expiration_date': Timestamp.fromDate(item.expirationDate),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Ingredient>> getInventoryStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db.collection('artifacts').doc(_appId).collection('users').doc(uid).collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Ingredient(
          id: doc.id,
          name: data['name'] ?? '',
          quantity: (data['quantity'] ?? 0).toDouble(),
          unit: data['unit'] ?? '',
          category: data['category'] ?? 'Other',
          expirationDate: (data['expiration_date'] as Timestamp).toDate(),
          calories: data['calories'],
        );
      }).toList();
    });
  }
}