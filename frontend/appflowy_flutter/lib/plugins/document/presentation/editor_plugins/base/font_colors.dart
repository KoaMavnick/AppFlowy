import 'package:flutter/material.dart';

class EditorFontColors {
  static final lightColors = [
    const Color(0x00FFFFFF),
    const Color(0xFFE8DEEE),
    const Color(0xFFF5E0E9),
    const Color(0xFFFBE4E4),
    const Color(0xFFFADEC9),
    const Color(0xFFFDECC8),
    const Color(0xFFE8F3D8),
    const Color(0xFFDBEDDB),
    const Color(0xFFD4F0EA),
    const Color(0xFFD44C47),
    const Color(0xFFCB912F),
    const Color(0xFF448361),
    const Color(0xFF9065B0),
    const Color(0xFFC14C8A),
    const Color(0xFFD9730D),
    const Color(0xFF337EA9),
    const Color(0xFF0F7B6C),
    const Color(0xFF787774),
  ];

  static final darkColors = [
    const Color(0x00FFFFFF),
    const Color(0xFF4A3060),
    const Color(0xFF5A3048),
    const Color(0xFF5C3A45),
    const Color(0xFF5C3D28),
    const Color(0xFF5C4E2A),
    const Color(0xFF3D4A2A),
    const Color(0xFF244533),
    const Color(0xFF1F4544),
    const Color(0xFFFF7369),
    const Color(0xFFFFDC49),
    const Color(0xFF4DAB9A),
    const Color(0xFFC4A0E0),
    const Color(0xFFE08AB8),
    const Color(0xFFFFA344),
    const Color(0xFF7EB6D9),
    const Color(0xFF4DAB9A),
    const Color(0xFFD4D4D4),
  ];

  // if the input color doesn't exist in the list, return the input color itself.
  static Color? fromBuiltInColors(BuildContext context, Color? color) {
    if (color == null) {
      return null;
    }

    final brightness = Theme.of(context).brightness;

    // if the dark mode color using light mode, return it's corresponding light color. Same for light mode.
    if (brightness == Brightness.light) {
      if (darkColors.contains(color)) {
        return lightColors[darkColors.indexOf(color)];
      }
    } else {
      if (lightColors.contains(color)) {
        return darkColors[lightColors.indexOf(color)];
      }
    }
    return color;
  }
}
