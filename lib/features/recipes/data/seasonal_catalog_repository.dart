import 'package:flutter/services.dart' show rootBundle;

import 'package:kitchen/features/shopping_list/domain/seasonal_food.dart'; // 按你实际路径改

class SeasonalCatalogRepository {
  SeasonalCatalogRepository({
    this.assetPath = 'assets/data/season_foods.json',
  });

  final String assetPath;
  List<SeasonalFood>? _cache;

  Future<List<SeasonalFood>> load() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString(assetPath);
    _cache = SeasonalFood.listFromJsonString(jsonStr);
    return _cache!;
  }
}
