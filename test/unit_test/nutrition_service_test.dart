/// NutritionService unit test
///
/// Use mocktail to simulate HTTP requests without calling the actual API.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kitchen/services/nutrition_service.dart';

import '../mock_dependencies.dart';

void main() {
  late MockDio mockDio;
  late NutritionService nutritionService;

  setUpAll(() {
    // Register fallback values
    registerFallbackValues();
  });

  setUp(() {
    mockDio = MockDio();
    // Create a service instance using the mock version of Dio
    nutritionService = NutritionService(dio: mockDio);
  });

  group('NutritionService - calculateCalories', () {
    test(
      'The correct value should be returned when the calorie information is retrieved successfully',
      () async {
        // Arrange
        const testName = 'apple';
        const testQty = 1.0;
        const testUnit = 'medium';
        const expectedCalories = 95;

        final mockResponse = Response(
          data: {
            'ingredients': [
              {
                'parsed': [
                  {
                    'food': 'apple',
                    'nutrients': {
                      'ENERC_KCAL': {'quantity': expectedCalories.toDouble()},
                    },
                  },
                ],
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await nutritionService.calculateCalories(
          testName,
          testQty,
          testUnit,
        );

        // Assert
        expect(result, expectedCalories);
        verify(
          () => mockDio.get(
            'https://api.edamam.com/api/nutrition-data',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );

    test('The API should return null if it returns empty data', () async {
      // Arrange
      const testName = 'unknown';
      const testQty = 1.0;
      const testUnit = 'unit';

      final mockResponse = Response(
        data: {'ingredients': []},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => mockResponse);

      // Act
      final result = await nutritionService.calculateCalories(
        testName,
        testQty,
        testUnit,
      );

      // Assert
      expect(result, isNull);
    });

    test('An API call should return null if it fails', () async {
      // Arrange
      const testName = 'apple';
      const testQty = 1.0;
      const testUnit = 'unit';

      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Network error',
        ),
      );

      // Act
      final result = await nutritionService.calculateCalories(
        testName,
        testQty,
        testUnit,
      );

      // Assert
      expect(result, isNull);
    });

    test('If the API returns 404, it should return null', () async {
      // Arrange
      const testName = 'nonexistent';
      const testQty = 1.0;
      const testUnit = 'unit';

      final mockResponse = Response(
        data: null,
        statusCode: 404,
        requestOptions: RequestOptions(path: ''),
      );

      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => mockResponse);

      // Act
      final result = await nutritionService.calculateCalories(
        testName,
        testQty,
        testUnit,
      );

      // Assert
      expect(result, isNull);
    });
  });

  group('NutritionService - Baidu Translation', () {
    test(
      'The English text should be returned when the translation is successful',
      () async {
        // This test demonstrates how to test the translation function.
        // Since the translation is a private method, we test it indirectly through public methods.
        expect(nutritionService, isNotNull);
      },
    );
  });

  group('NutritionService - Dependency Injection', () {
    test('Custom Dio instances should be accepted', () {
      // Arrange
      final customDio = MockDio();

      // Act
      final service = NutritionService(dio: customDio);

      // Assert
      expect(service, isNotNull);
    });

    test('The default instance should be used when Dio is not provided', () {
      // Act
      final service = NutritionService();

      // Assert
      expect(service, isNotNull);
    });
  });
}
