/// Mock 类定义
/// 
/// 使用 mocktail 创建所有需要 mock 的依赖
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/services/database_service.dart';
import 'package:kitchen/services/nutrition_service.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart' as kitchen;
import 'package:kitchen/features/shopping_cart/data/shopping_item.dart' as kitchen;
import 'package:kitchen/features/shopping_list/domain/recommendation_service.dart';
import 'package:kitchen/features/shopping_list/domain/seasonal_food.dart';
import 'package:kitchen/core/utils/season_helper.dart';

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

// DatabaseService Mock
class MockDatabaseService extends Mock implements DatabaseService {}

// Firestore Snapshots Mocks
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

// NutritionService Mock
class MockNutritionService extends Mock implements NutritionService {}

// Fake classes for complex types that cannot be mocked
class FakeIngredient extends Fake implements kitchen.Ingredient {}

class FakeShoppingItem extends Fake implements kitchen.ShoppingItem {}

class FakeDateTime extends Fake implements DateTime {}

class MockRecommendationService extends Mock implements RecommendationService {}

class MockSeasonalFood extends Mock implements SeasonalFood {}

// 注册 fallback values (mocktail 需要)
void registerFallbackValues() {
  registerFallbackValue(RequestOptions(path: ''));
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(FakeIngredient());
  registerFallbackValue(FakeShoppingItem());
  registerFallbackValue(DateTime.now());
  registerFallbackValue(<String>[]);
  registerFallbackValue(<kitchen.Ingredient>[]);
  registerFallbackValue(<kitchen.ShoppingItem>[]);
  registerFallbackValue(Hemisphere.northern);
}
