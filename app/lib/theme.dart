import 'package:flutter/material.dart';

/// 纸墨配色，跟网页版保持一致。
const Color kPaper = Color(0xFFEFE8DC);
const Color kCard = Color(0xFFFFFCF5);
const Color kInk = Color(0xFF17150F);
const Color kInkSoft = Color(0xFF3D372D);
const Color kMuted = Color(0xFF7B7264);
const Color kLine = Color(0xFFDFD4BF);
const Color kLineStrong = Color(0xFFCDBFA5);
const Color kAccent = Color(0xFFC24A26);
const Color kAccentSoft = Color(0xFFF3DCD2);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kPaper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccent,
      primary: kInk,
      surface: kCard,
      brightness: Brightness.light,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: kInk,
      displayColor: kInk,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPaper,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerColor: kLine,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kInk,
      contentTextStyle: TextStyle(color: kPaper, fontSize: 13),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

BoxDecoration cardDecoration() => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: kLine),
      boxShadow: const [
        BoxShadow(color: Color(0x0D17150F), blurRadius: 8, offset: Offset(0, 3)),
      ],
    );

TextStyle serifStyle({
  double size = 17,
  FontWeight weight = FontWeight.w600,
  Color color = kInk,
  double height = 1.65,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: 0.2,
    );

TextStyle labelStyle({
  double size = 11,
  Color color = kMuted,
  double spacing = 0.8,
}) =>
    TextStyle(fontSize: size, color: color, letterSpacing: spacing);
