import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/constants/theme.dart';

void main() {
  group('AppTheme -', () {
    test('should have correct static color values', () {
      // Test all static colors
      expect(AppTheme.springColor, const Color(0xFF81C784));
      expect(AppTheme.summerColor, const Color(0xFFE57373));
      expect(AppTheme.autumnColor, const Color(0xFFFFB74D));
      expect(AppTheme.winterColor, const Color(0xFF64B5F6));
      expect(AppTheme.defaultColor, const Color.fromARGB(255, 137, 97, 11));
    });

    test('lightTheme should return default theme', () {
      final theme = AppTheme.lightTheme;
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.defaultColor);
    });

    test('getTheme should return Spring theme', () {
      final theme = AppTheme.getTheme('Spring');
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.springColor);
      expect(theme.appBarTheme.foregroundColor, AppTheme.springColor);
    });

    test('getTheme should return Summer theme', () {
      final theme = AppTheme.getTheme('Summer');
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.summerColor);
      expect(theme.appBarTheme.foregroundColor, AppTheme.summerColor);
    });

    test('getTheme should return Autumn theme', () {
      final theme = AppTheme.getTheme('Autumn');
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.autumnColor);
      expect(theme.appBarTheme.foregroundColor, AppTheme.autumnColor);
    });

    test('getTheme should return Winter theme', () {
      final theme = AppTheme.getTheme('Winter');
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.winterColor);
      expect(theme.appBarTheme.foregroundColor, AppTheme.winterColor);
    });

    test('getTheme should return default theme for unknown name', () {
      final theme = AppTheme.getTheme('Unknown');
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, AppTheme.defaultColor);
    });

    test('getTheme should return default theme for empty string', () {
      final theme = AppTheme.getTheme('');
      
      expect(theme, isNotNull);
      expect(theme.colorScheme.primary, AppTheme.defaultColor);
    });

    test('all themes should have consistent structure', () {
      final themes = [
        AppTheme.getTheme('Spring'),
        AppTheme.getTheme('Summer'),
        AppTheme.getTheme('Autumn'),
        AppTheme.getTheme('Winter'),
        AppTheme.lightTheme,
      ];

      for (final theme in themes) {
        // Verify all themes use Material 3
        expect(theme.useMaterial3, true);
        
        // Verify AppBar theme configuration
        expect(theme.appBarTheme.centerTitle, true);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.backgroundColor, Colors.white);
        expect(theme.appBarTheme.titleTextStyle?.fontSize, 20);
        expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.bold);
        
        // Verify input decoration theme
        expect(theme.inputDecorationTheme.filled, true);
        expect(theme.inputDecorationTheme.fillColor, Colors.white);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      }
    });

    test('themes should have different primary colors', () {
      final springTheme = AppTheme.getTheme('Spring');
      final summerTheme = AppTheme.getTheme('Summer');
      final autumnTheme = AppTheme.getTheme('Autumn');
      final winterTheme = AppTheme.getTheme('Winter');
      final defaultTheme = AppTheme.lightTheme;

      // Verify each theme has a unique primary color
      expect(springTheme.colorScheme.primary, isNot(summerTheme.colorScheme.primary));
      expect(springTheme.colorScheme.primary, isNot(autumnTheme.colorScheme.primary));
      expect(springTheme.colorScheme.primary, isNot(winterTheme.colorScheme.primary));
      expect(summerTheme.colorScheme.primary, isNot(autumnTheme.colorScheme.primary));
      expect(summerTheme.colorScheme.primary, isNot(winterTheme.colorScheme.primary));
      expect(autumnTheme.colorScheme.primary, isNot(winterTheme.colorScheme.primary));
    });

    test('input decoration theme should have rounded borders', () {
      final theme = AppTheme.lightTheme;
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      
      expect(border.borderRadius, BorderRadius.circular(12));
    });

    test('elevated button theme should have proper configuration', () {
      final theme = AppTheme.lightTheme;
      
      expect(theme.elevatedButtonTheme.style, isNotNull);
      
      final padding = theme.elevatedButtonTheme.style?.padding?.resolve({});
      expect(padding, const EdgeInsets.symmetric(vertical: 16));
      
      final shape = theme.elevatedButtonTheme.style?.shape?.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
    });

    test('color scheme should be generated from seed color', () {
      final theme = AppTheme.getTheme('Spring');
      
      // Verify color scheme is properly generated
      expect(theme.colorScheme, isNotNull);
      expect(theme.colorScheme.primary, AppTheme.springColor);
      expect(theme.colorScheme.secondary, isNotNull);
      expect(theme.colorScheme.surface, isNotNull);
    });
  });
}
