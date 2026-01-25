import 'dart:convert';

class SeasonalFood {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> seasons; // ["spring","summer","autumn","winter"]
  final String category;
  final int defaultShelfLifeDays;
  final List<String> tags;

  const SeasonalFood({
    required this.id,
    required this.name,
    required this.aliases,
    required this.seasons,
    required this.category,
    required this.defaultShelfLifeDays,
    required this.tags,
  });

  factory SeasonalFood.fromJson(Map<String, dynamic> json) {
    return SeasonalFood(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List).map((e) => e.toString()).toList(),
      seasons: (json['seasons'] as List).map((e) => e.toString()).toList(),
      category: json['category'] as String,
      defaultShelfLifeDays: (json['default_shelf_life_days'] as num).toInt(),
      tags: (json['tags'] as List).map((e) => e.toString()).toList(),
    );
  }

  static List<SeasonalFood> listFromJsonString(String jsonStr) {
    final data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => SeasonalFood.fromJson(e as Map<String, dynamic>)).toList();
  }
}
