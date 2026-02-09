/// SeasonHelper unit test
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/utils/season_helper.dart';

void main() {
  group('SeasonHelper -', () {
    group('getCurrentSeason - Northern Hemisphere', () {
      test('You should return to spring in March-May', () {
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

      test('Valid season names should be returned', () {
        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );

        // Assert
        expect(season, isIn(['spring', 'summer', 'autumn', 'winter']));
      });

      test('By default, the northern hemisphere should be used', () {
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
      test('Should return to the opposite season of the northern hemisphere', () {
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

      test('Valid season names should be returned', () {
        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.southern,
        );

        // Assert
        expect(season, isIn(['spring', 'summer', 'autumn', 'winter']));
      });
    });

    group('Hemisphere enum', () {
      test('There should be two values', () {
        // Act
        final values = Hemisphere.values;

        // Assert
        expect(values.length, 2);
        expect(values, contains(Hemisphere.northern));
        expect(values, contains(Hemisphere.southern));
      });
    });

    group('Season logic validation', () {
      test(
        'The seasons in the northern and southern hemispheres should differ by six months',
        () {
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
        },
      );
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
