import 'package:flutter/material.dart';

/// CorpFinity Design System - Warm Wellness Palette
/// Inspired by natural elements: terracotta, sage, sand, and forest
class AppColors {
  // Primary Palette - Warm Terracotta
  static const primary = Color(0xFFD97756);      // Warm terracotta
  static const primaryLight = Color(0xFFE8A090); // Soft coral
  static const primaryDark = Color(0xFFB85A3D);  // Deep terracotta
  
  // Secondary - Sage Green
  static const secondary = Color(0xFF7D9B76);    // Sage green
  static const secondaryLight = Color(0xFFA8C4A0); // Mint sage
  static const secondaryDark = Color(0xFF5A7A52); // Forest sage
  
  // Accent - Golden Sand
  static const accent = Color(0xFFE5B769);       // Warm gold
  static const accentLight = Color(0xFFF2D4A0);  // Pale sand
  
  // Neutrals - Warm Cream to Charcoal
  static const dark = Color(0xFF2D2A26);         // Warm charcoal
  static const darkMuted = Color(0xFF4A4640);    // Muted brown
  
  // Background & Surface - Cream tones
  static const background = Color(0xFFFAF7F2);   // Warm cream
  static const surface = Color(0xFFFFFDF9);      // Off-white
  static const surfaceElevated = Color(0xFFFFFFFF); // Pure white
  
  // Warm Gray Scale
  static const gray50 = Color(0xFFFBFAF8);
  static const gray100 = Color(0xFFF5F3EF);
  static const gray200 = Color(0xFFE8E4DD);
  static const gray300 = Color(0xFFD4CFC5);
  static const gray400 = Color(0xFFADA69A);
  static const gray500 = Color(0xFF8A8379);
  static const gray600 = Color(0xFF6B655C);
  static const gray700 = Color(0xFF4F4A43);
  static const gray800 = Color(0xFF36322D);
  static const gray900 = Color(0xFF1F1D1A);
  
  // Semantic Colors - Earthy tones
  static const success = Color(0xFF6B9B64);      // Forest green
  static const warning = Color(0xFFD4A84B);      // Amber gold
  static const error = Color(0xFFCB6B5E);        // Dusty red
  static const info = Color(0xFF6B8FAD);         // Slate blue
  
  // Goal Colors - Nature-inspired
  static const blue500 = Color(0xFF6B8FAD);      // Slate blue
  static const yellow500 = Color(0xFFD4A84B);    // Amber
  static const indigo500 = Color(0xFF7B7FA3);    // Dusty lavender
  static const red500 = Color(0xFFCB6B5E);       // Dusty rose
  static const green500 = Color(0xFF6B9B64);     // Forest
  static const pink500 = Color(0xFFB87D8B);      // Mauve
  
  // Mood Colors - Soft, calming
  static const moodGreat = Color(0xFFD4A84B);    // Warm gold
  static const moodGood = Color(0xFF6B8FAD);     // Calm blue
  static const moodOkay = Color(0xFF8A8379);     // Neutral stone
  static const moodTired = Color(0xFF7B7FA3);    // Soft lavender
  static const moodStressed = Color(0xFFCB6B5E); // Dusty coral
  
  // Gradient definitions
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFE8A090)],
  );
  
  static const secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFFA8C4A0)],
  );
  
  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
}
