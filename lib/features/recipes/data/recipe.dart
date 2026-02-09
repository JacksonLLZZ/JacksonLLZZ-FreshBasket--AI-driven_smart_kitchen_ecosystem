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

  // TheMealDB Unique field（Spoonacular is null）
  final String? instructions; // Cooking instructions
  final String? category; // Classification（such as Chicken, Dessert）
  final String? area; // district（such as Japanese, Italian）
  final String? tags; // sign（Comma-separated）
  final String? youtubeUrl; // YouTube video link

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.usedIngredients,
    required this.missedIngredients,
    this.instructions,
    this.category,
    this.area,
    this.tags,
    this.youtubeUrl,
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
      instructions: json['instructions'],
      category: json['category'],
      area: json['area'],
      tags: json['tags'],
      youtubeUrl: json['youtubeUrl'],
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
      'instructions': instructions,
      'category': category,
      'area': area,
      'tags': tags,
      'youtubeUrl': youtubeUrl,
    };
  }
}
