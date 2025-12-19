import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/inventory/data/ingredient.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // 系统分配的应用 ID，用于隔离数据路径
  static const String _appId = "nutriscan-app-v1";

  /// 获取当前登录用户的 UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ==========================================
  // 用户资料逻辑 (解决 Login/Register 标红问题)
  // ==========================================

  /// 检查 users/{uid} 文档是否存在
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

  /// 创建或更新用户资料 (由 LoginForm/RegistrationForm 调用)
  /// 使用 merge: true 避免覆盖已有字段
  Future<void> upsertUserProfile({
    required String username,
    required String email,
    String imageUrl = "",
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError("未经过身份验证的用户（uid 为空）。");
    }

    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .set(
      {
        'username': username,
        'email': email,
        'image_url': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(), // merge 会保留已存在的 created_at
      },
      SetOptions(merge: true),
    );
  }

  /// 获取当前用户资料
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

  // ==========================================
  // 食材库存逻辑 (Inventory Logic)
  // ==========================================

  /// 保存分析后的食材到用户的私人库存
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
      'category': item.category,
      'calories': item.calories,
      'expiration_date': Timestamp.fromDate(item.expirationDate),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// 获取库存变化的实时流 (用于 Inventory Screen 展示)
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
          category: data['category'] ?? 'Other',
          expirationDate: (data['expiration_date'] as Timestamp).toDate(),
          calories: data['calories'],
        );
      }).toList();
    });
  }
}