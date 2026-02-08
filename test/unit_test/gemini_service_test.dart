import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kitchen/features/assistant/domain/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiService -', () {
    late GeminiService service;

    setUp(() async {
      service = GeminiService();
      SharedPreferences.setMockInitialValues({});
    });

    test('should instantiate without errors', () {
      expect(service, isNotNull);
      expect(service, isA<GeminiService>());
    });

    test('getApiKey should return null when no key is saved', () async {
      final apiKey = await service.getApiKey();
      
      expect(apiKey, isNull);
    });

    test('saveApiKey should store API key', () async {
      const testKey = 'test_api_key_12345';
      
      await service.saveApiKey(testKey);
      final retrievedKey = await service.getApiKey();
      
      expect(retrievedKey, equals(testKey));
    });

    test('saveApiKey should overwrite existing key', () async {
      const firstKey = 'first_key';
      const secondKey = 'second_key';
      
      await service.saveApiKey(firstKey);
      await service.saveApiKey(secondKey);
      
      final retrievedKey = await service.getApiKey();
      expect(retrievedKey, equals(secondKey));
    });

    test('clearApiKey should remove stored key', () async {
      const testKey = 'test_api_key';
      
      await service.saveApiKey(testKey);
      await service.clearApiKey();
      
      final retrievedKey = await service.getApiKey();
      expect(retrievedKey, isNull);
    });

    test('clearApiKey should not throw when no key exists', () async {
      // Should not throw
      await service.clearApiKey();
      
      final apiKey = await service.getApiKey();
      expect(apiKey, isNull);
    });

    test('getResponse should throw when API key is not configured', () async {
      expect(
        () => service.getResponse('test message'),
        throwsA(isA<Exception>()),
      );
    });

    test('getResponse should throw with descriptive message when key is null', () async {
      try {
        await service.getResponse('test');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('API key not configured'));
      }
    });

    test('getResponse should throw when API key is empty string', () async {
      await service.saveApiKey('');
      
      expect(
        () => service.getResponse('test message'),
        throwsA(isA<Exception>()),
      );
    });

    test('saveApiKey should handle empty string', () async {
      await service.saveApiKey('');
      final key = await service.getApiKey();
      
      expect(key, equals(''));
    });

    test('saveApiKey should handle long API keys', () async {
      final longKey = 'a' * 500;
      
      await service.saveApiKey(longKey);
      final retrievedKey = await service.getApiKey();
      
      expect(retrievedKey, equals(longKey));
    });

    test('saveApiKey should handle special characters', () async {
      const specialKey = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
      
      await service.saveApiKey(specialKey);
      final retrievedKey = await service.getApiKey();
      
      expect(retrievedKey, equals(specialKey));
    });

    test('multiple save and clear operations should work correctly', () async {
      await service.saveApiKey('key1');
      await service.clearApiKey();
      await service.saveApiKey('key2');
      
      final key = await service.getApiKey();
      expect(key, equals('key2'));
    });

    test('getResponse with invalid API key should throw', () async {
      await service.saveApiKey('invalid_key_123');
      
      // Will fail because API key is invalid
      expect(
        () => service.getResponse('test message'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
