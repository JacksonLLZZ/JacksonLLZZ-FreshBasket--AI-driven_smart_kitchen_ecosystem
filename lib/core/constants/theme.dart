import 'package:flutter/material.dart';

class AppTheme {
  // 定义四季主题的静态颜色常量，方便在 ProfileScreen 中引用
// A fresh, grassy green (less neon)
  static const Color springColor = Color(0xFF81C784); 
  
  // Soft Coral/Pinkish Red
  static const Color summerColor = Color(0xFFE57373); 
  
  // Apricot/Creamy Orange
  static const Color autumnColor = Color(0xFFFFB74D); 
  
  // Sky Blue
  static const Color winterColor = Color(0xFF64B5F6);
  
  // Renamed to Purple to match reality
  static const Color defaultColor = Color.fromARGB(255, 137, 97, 11);
  
  // 根据主题名称获取对应的 ThemeData
  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case 'Spring':
        return _buildTheme(springColor);
      case 'Summer':
        return _buildTheme(summerColor);
      case 'Autumn':
        return _buildTheme(autumnColor);
      case 'Winter':
        return _buildTheme(winterColor);
      default:
        return lightTheme;
    }
  }

  static ThemeData get lightTheme => _buildTheme(defaultColor);

  static ThemeData _buildTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: seedColor,
        titleTextStyle: TextStyle(
          color: seedColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}