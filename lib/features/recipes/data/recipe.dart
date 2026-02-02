class RecipeIngredient {
  final String name;
  final String original;
  final String? image;

  RecipeIngredient({required this.name, required this.original, this.image});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      original: json['original'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'original': original, 'image': image};
  }
}

class Recipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<RecipeIngredient> usedIngredients;
  final List<RecipeIngredient> missedIngredients;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.usedIngredients,
    required this.missedIngredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
      usedIngredients:
          (json['usedIngredients'] as List?)
              ?.map((e) => RecipeIngredient.fromJson(e))
              .toList() ??
          [],
      missedIngredients:
          (json['missedIngredients'] as List?)
              ?.map((e) => RecipeIngredient.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'usedIngredientCount': usedIngredientCount,
      'missedIngredientCount': missedIngredientCount,
      'usedIngredients': usedIngredients.map((e) => e.toJson()).toList(),
      'missedIngredients': missedIngredients.map((e) => e.toJson()).toList(),
    };
  }
}
