import '../../recipes/data/seasonal_catalog_repository.dart';
import 'package:kitchen/core/utils/season_helper.dart';
import 'seasonal_food.dart';

class RecommendationService {
  RecommendationService(this.repo);

  final SeasonalCatalogRepository repo;

  Future<List<SeasonalFood>> getSeasonalPicks({
    Hemisphere hemisphere = Hemisphere.northern,
  }) async {
    final all = await repo.load();
    final season = SeasonHelper.getCurrentSeason(hemisphere: hemisphere);

    return all.where((item) {
      final isInSeason = item.seasons.contains(season);
      final isStaple = item.tags.contains('staple'); // fallback
      return isInSeason || isStaple;
    }).toList();
  }

  Future<List<SeasonalFood>> search(String query) async {
    final all = await repo.load();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((i) {
      final nameHit = i.name.toLowerCase().contains(q);
      final aliasHit = i.aliases.any((a) => a.toLowerCase().contains(q));
      return nameHit || aliasHit;
    }).toList();
  }
}
