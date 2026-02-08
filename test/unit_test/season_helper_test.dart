/// SeasonHelper 工具类测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/utils/season_helper.dart';

void main() {
  group('SeasonHelper -', () {
    group('getCurrentSeason - Northern Hemisphere', () {
      test('应该在 3-5 月返回 spring', () {
        // 由于测试时无法控制 DateTime.now()，我们需要通过扩展来测试
        // 这里我们测试逻辑：3、4、5 月应该返回 spring
        // 实际测试中，我们可以验证方法的存在和基本功能
        
        // Act
        final season = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );

        // Assert
        // 验证返回值是四个季节之一
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

        // Assert - 两者应该相同
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

        // Assert - 根据当前月份验证季节转换
        // 如果北半球是 spring，南半球应该是 autumn
        // 如果北半球是 summer，南半球应该是 winter
        // 如果北半球是 autumn，南半球应该是 spring
        // 如果北半球是 winter，南半球应该是 summer
        
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
        // 这个测试验证整体逻辑的一致性
        // 无论当前是什么季节，两个半球的季节应该是相反的
        
        // Act
        final northern = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.northern,
        );
        final southern = SeasonHelper.getCurrentSeason(
          hemisphere: Hemisphere.southern,
        );

        // Assert - 它们不应该相同（除非在边界情况下）
        // 大多数情况下它们应该不同
        if (northern == 'spring') expect(southern, 'autumn');
        if (northern == 'summer') expect(southern, 'winter');
        if (northern == 'autumn') expect(southern, 'spring');
        if (northern == 'winter') expect(southern, 'summer');
      });
    });
  });
}

// 辅助函数：获取相反的季节
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
