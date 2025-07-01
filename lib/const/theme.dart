import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: const Color(0xFF1976D2), // Blue
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Gray
        cardColor: const Color(0xFFFFFFFF), // White
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1976D2), // Blue
          secondary: Color(0xFF4CAF50), // Green
          error: Color(0xFFD32F2F), // Red
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121), // Dark Gray
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF757575), // Medium Gray
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2), // Blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1976D2), // Blue
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
        ),
      );
}
