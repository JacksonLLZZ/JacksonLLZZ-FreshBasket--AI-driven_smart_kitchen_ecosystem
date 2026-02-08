enum Hemisphere { northern, southern }

class SeasonHelper {
  static String getSelectedSeasonOrSystem({
    required String theme,
    Hemisphere hemisphere = Hemisphere.northern,
  }) {
    const valid = ['Spring', 'Summer', 'Autumn', 'Winter'];
    if (valid.contains(theme)) {
      return theme.toLowerCase();
    }
    return getCurrentSeason(hemisphere: hemisphere);
  }

  static String getCurrentSeason({
    Hemisphere hemisphere = Hemisphere.northern,
  }) {
    final month = DateTime.now().month;

    // Northern hemisphere
    String s;
    if (month >= 3 && month <= 5) {
      s = 'spring';
    } else if (month >= 6 && month <= 8) {
      s = 'summer';
    } else if (month >= 9 && month <= 11) {
      s = 'autumn';
    } else {
      s = 'winter';
    }

    if (hemisphere == Hemisphere.northern) return s;

    // Southern hemisphere (shifted by 6 months)
    if (s == 'spring') return 'autumn';
    if (s == 'summer') return 'winter';
    if (s == 'autumn') return 'spring';
    return 'summer';
  }
}
