// NEW 10.2: Material 3 theme from ONE seed colour, light and dark, plus the status extension
import 'package:flutter/material.dart';
import 'package:ronditrack/core/theme/status_colors.dart';

const rondiSeed = Color(0xFF0B6E4F);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: rondiSeed,
    brightness: brightness,
  ),
  extensions: <ThemeExtension<dynamic>>[
    if (brightness == Brightness.light)
      StatusColors.light
    else
      StatusColors.dark,
  ],
);
