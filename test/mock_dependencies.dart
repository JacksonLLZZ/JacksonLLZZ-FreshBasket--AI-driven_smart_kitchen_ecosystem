/// Mock 类定义
/// 
/// 使用 mocktail 创建所有需要 mock 的依赖
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

// Dio Mock
class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

// Firebase Mock
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference<T> extends Mock
    implements CollectionReference<T> {}

// 注意：以下类是 sealed，不应该被 mock。如果需要测试这些类型，请使用 Fake 或者 stub
// class MockDocumentReference<T> extends Mock implements DocumentReference<T> {}
// class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {}
// class MockQuerySnapshot<T> extends Mock implements QuerySnapshot<T> {}
// class MockQuery<T> extends Mock implements Query<T> {}

// SharedPreferences Mock
class MockSharedPreferences extends Mock implements SharedPreferences {}

// 注册 fallback values (mocktail 需要)
void registerFallbackValues() {
  registerFallbackValue(RequestOptions(path: ''));
  registerFallbackValue(const Duration(seconds: 1));
}
