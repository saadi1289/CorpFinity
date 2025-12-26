import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CorpFinity Typography System
/// Heading: Space Grotesk - geometric, modern, distinctive
/// Body: DM Sans - clean, readable, friendly
class AppTextStyles {
  // Heading font - Space Grotesk for bold, geometric headings
  static TextStyle get _headingStyle => GoogleFonts.spaceGrotesk();
  
  // Body font - DM Sans for readable body text
  static TextStyle get _bodyStyle => GoogleFonts.dmSans();
  
  // Display styles - Hero text
  static TextStyle get display => _headingStyle.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
  );
  
  static TextStyle get displaySmall => _headingStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
  );
  
  // Heading styles
  static TextStyle get h1 => _headingStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
  );
  
  static TextStyle get h2 => _headingStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.25,
  );
  
  static TextStyle get h3 => _headingStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static TextStyle get h4 => _headingStyle.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );
  
  // Body styles
  static TextStyle get bodyLarge => _bodyStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  
  static TextStyle get body => _bodyStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
  
  static TextStyle get bodyMedium => _bodyStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => _bodyStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Utility styles
  static TextStyle get caption => _bodyStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static TextStyle get captionBold => _bodyStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get tiny => _headingStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.3,
  );
  
  static TextStyle get button => _headingStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  // Accent styles
  static TextStyle get quote => GoogleFonts.libreBaskerville(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.7,
  );
  
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
