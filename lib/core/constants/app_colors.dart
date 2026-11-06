import 'package:flutter/material.dart';

class NoteColors {
  static const List<Color> palette = [
    Color(0xFFF7F5F0), // Базовий теплий бежевий
    Color(0xFFE8EFEA), // Шавлієвий зелений
    Color(0xFFF3EAE4), // М'який персиковий/теракотовий
    Color(0xFFE8EEF5), // Пастельний блакитний
    Color(0xFFEFE8F5), // М'який лавандовий
    Color(0xFFF5F0E6), // Теплий медовий
  ];

  static Color get(int index) {
    if (index < 0 || index >= palette.length) {
      return palette[0];
    }
    return palette[index];
  }
}

