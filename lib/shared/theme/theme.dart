import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.deepPurple,
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);
