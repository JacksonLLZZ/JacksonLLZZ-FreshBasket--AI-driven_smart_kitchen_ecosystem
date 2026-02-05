import 'dart:math';

class Ingredient {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final DateTime expirationDate;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
  });

  // 获取是否过期
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  // 工厂方法：创建新的食材对象
  factory Ingredient.create({
    required String name,
    required double qty,
    required String unit,
    DateTime? expirationDate,
  }) {
    return Ingredient(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(100).toString(),
      name: name,
      quantity: qty,
      unit: unit,
      expirationDate:
          expirationDate ?? DateTime.now().add(const Duration(days: 7)),
    );
  }
}
