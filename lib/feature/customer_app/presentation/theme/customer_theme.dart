import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Spice & Ember" palette — mirrors pakafghanrestaurant.co.uk.
class CColors {
  CColors._();

  static const ink = Color(0xFF1A140F);
  static const inkSoft = Color(0xFF251D15);
  static const inkElev = Color(0xFF332819);
  static const gold = Color(0xFFC68A2E);
  static const goldLight = Color(0xFFE3AC57);
  static const goldPale = Color(0xFFF3DFB3);
  static const rust = Color(0xFFA8431F);
  static const rustDeep = Color(0xFF7E2F14);
  static const olive = Color(0xFF57603C);
  static const cream = Color(0xFFF8F2E6);
  static const pageGrey = Color(0xFFF1F1EF); // light grey page (cart / checkout)
  static const cream2 = Color(0xFFEFE3C9);
  static const paper = Color(0xFFFFFDF8);
  static const text = Color(0xFF241D15);
  static const muted = Color(0xFF8A7C67);
  static const mutedLight = Color(0xFFB3A68C);
  static const line = Color(0xFFE7DABB);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold],
  );
}

class CShadows {
  CShadows._();

  static const soft = [BoxShadow(color: Color(0x1A23190A), blurRadius: 36, offset: Offset(0, 14))];
  static const large = [BoxShadow(color: Color(0x381A140F), blurRadius: 64, offset: Offset(0, 30))];
  static const rust = [BoxShadow(color: Color(0x59A8431F), blurRadius: 24, offset: Offset(0, 10))];
}

class CText {
  CText._();

  static TextStyle display(double size, {Color color = CColors.ink, FontStyle? style}) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.12,
    fontStyle: style,
  );

  static TextStyle body(
    double size, {
    Color color = CColors.text,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

  /// Small uppercase label shown above section titles.
  static TextStyle eyebrow({Color color = CColors.rust}) =>
      GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 2.2, color: color);
}

ThemeData buildCustomerTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: CColors.cream,
    colorScheme: const ColorScheme.light(
      primary: CColors.rust,
      secondary: CColors.gold,
      surface: CColors.paper,
      onPrimary: Colors.white,
      onSurface: CColors.text,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: CColors.text, displayColor: CColors.ink),
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.poppins(color: CColors.mutedLight, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CColors.gold, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CColors.ink,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
