import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/assistant/domain/assistant_service.dart';

void main() {
  group('AssistantService -', () {
    late AssistantService service;

    setUp(() {
      service = AssistantService();
    });

    test('should instantiate without errors', () {
      expect(service, isNotNull);
      expect(service, isA<AssistantService>());
    });

    test('getResponse should return fallback for recipe query', () async {
      final response = await service.getResponse('recipe');
      
      expect(response, isNotNull);
      expect(response, isA<String>());
      expect(response.toLowerCase(), contains('recipe'));
    });

    test('getResponse should return fallback for shopping query', () async {
      final response = await service.getResponse('shopping');
      
      expect(response, isNotNull);
      expect(response, isA<String>());
      expect(response.toLowerCase(), contains('shopping'));
    });

    test('getResponse should return general help message for other queries', () async {
      final response = await service.getResponse('hello');
      
      expect(response, isNotNull);
      expect(response, isA<String>());
      expect(response.toLowerCase(), contains('assistant'));
    });

    test('getResponse should handle empty string', () async {
      final response = await service.getResponse('');
      
      expect(response, isNotNull);
      expect(response, isA<String>());
    });
  });
}
