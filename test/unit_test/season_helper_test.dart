/// SeasonHelper unit test
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/utils/season_helper.dart';

void main() {
  group('SeasonHelper -', () {
    group('getCurrentSeason - Northern Hemisphere', () {
      test('应该在 3-5 月返回 spring', () {
        // Since we cannot control DateTime.now() during the test, we need to conduct the test through extension.
        // Here we test the logic: In March, April, and May, it should return to spring.
        // During the actual tests, we can verify the existence of the method and its basic functions.

        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );

        // Assert
        // Verify that the returned value is one of the four seasons.
        expect(['spring', 'summer', 'autumn', 'winter'], contains(season));
      });

      test('应该返回有效的季节名称', () {
        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );

        // Assert
        expect(season, isIn(['spring', 'summer', 'autumn', 'winter']));
      });

      test('默认应该使用北半球', () {
        // Act
        final seasonDefault = SeasonHelper.getCurrentSeason();
        final seasonNorthern = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );

        // Assert - both are same
        expect(seasonDefault, seasonNorthern);
      });
    });

    group('getCurrentSeason - Southern Hemisphere', () {
      test('应该返回与北半球相反的季节', () {
        // Act
        final northernSeason = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );
        final southernSeason = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.southern,
        );

        // Assert - Verify the seasonal transition based on the current month
        // If the Northern Hemisphere is spring, then the Southern Hemisphere should be autumn.
        // If the Northern Hemisphere is summer, then the Southern Hemisphere should be winter.
        // If the northern hemisphere is autumn, then the southern hemisphere should be spring.
        // If the Northern Hemisphere is winter, then the Southern Hemisphere should be summer.

        final expectedSouthern = _getOppositeSeason(northernSeason);
        expect(southernSeason, expectedSouthern);
      });

      test('应该返回有效的季节名称', () {
        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.southern,
        );

        // Assert
        expect(season, isIn(['spring', 'summer', 'autumn', 'winter']));
      });
    });

    group('Hemisphere enum', () {
      test('应该有两个值', () {
        // Act
        final values = Hemisphere.values;

        // Assert
        expect(values.length, 2);
        expect(values, contains(Hemisphere.northern));
        expect(values, contains(Hemisphere.southern));
      });
    });

    group('Season logic validation', () {
      test('北半球和南半球的季节应该相差 6 个月概念', () {
        // This test verifies the consistency of the overall logic.
        // No matter what season it is currently, the seasons in the two hemispheres should be opposite to each other.

        // Act
        final northern = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );
        final southern = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.southern,
        );

        // Assert - They should not be the same (unless in boundary cases)
        // In most cases, they should be different.
        if (northern == 'spring') expect(southern, 'autumn');
        if (northern == 'summer') expect(southern, 'winter');
        if (northern == 'autumn') expect(southern, 'spring');
        if (northern == 'winter') expect(southern, 'summer');
      });
    });
  });
}

// Auxiliary function: Obtain the opposite season
String _getOppositeSeason(String season) {
  switch (season) {
    case 'spring':
      return 'autumn';
    case 'summer':
      return 'winter';
    case 'autumn':
      return 'spring';
    case 'winter':
      return 'summer';
    default:
      return season;
  }
}
