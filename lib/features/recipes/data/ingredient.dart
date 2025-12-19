class Ingredient {
  final String name;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.expiryDate,
  });
}
