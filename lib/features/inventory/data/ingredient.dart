import 'dart:math';

class Ingredient {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final DateTime expirationDate;
  final String? calories;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.expirationDate,
    this.calories,
  });

  // 获取是否过期
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  // 工厂方法：将 API 结果转换为模型对象
  factory Ingredient.fromApi({
    required String name,
    required double qty,
    required String unit,
    required String category,
    required int calories,
  }) {
    return Ingredient(
      id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(100).toString(),
      name: name,
      quantity: qty,
      unit: unit,
      category: category,
      // 默认设置为 7 天后过期
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      calories: "$calories kcal",
    );
  }
}