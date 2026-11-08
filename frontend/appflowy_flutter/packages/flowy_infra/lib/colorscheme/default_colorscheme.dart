import 'package:flutter/material.dart';

import 'colorscheme.dart';

/// Warm neutrals used by the light and dark themes.
///
/// Light page is white, text is off-black, and the sidebar is a warm gray.
/// Dark page is near-black, text is soft white, and the sidebar is one step
/// lighter. Accents stay neutral. Tag colors are muted pastels.
class ColorSchemeConstants {
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF37352F);
  static const inkSoft = Color(0xFF787774);
  static const inkFaint = Color(0xFF9B9A97);
  static const lightHover = Color(0x1437352F);
  static const lightSelector = Color(0xFFEFEFEE);
  static const lightFill = Color(0xFFF7F7F5);
  static const lightCallout = Color(0xFFF7F6F3);
  static const lightLine = Color(0xFFE9E9E7);
  static const lightBorder = Color(0xFFE3E2E0);
  static const lightBorderColor = lightLine;
  static const darkBorderColor = Color(0xFF373737);
  static const darkPage = Color(0xFF191919);
  static const darkSidebar = Color(0xFF202020);
  static const darkRaised = Color(0xFF252525);
  static const darkHover = Color(0xFF2C2C2C);
  static const darkLine = Color(0xFF2F2F2F);
  static const darkText = Color(0xFFEDEDEC);
  static const darkFaint = Color(0xFF9B9B9B);
}

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: ColorSchemeConstants.white,
          hover: ColorSchemeConstants.lightHover,
          selector: ColorSchemeConstants.lightSelector,
          red: const Color(0xFFE03E3E),
          yellow: const Color(0xFFDFAB01),
          green: const Color(0xFF0F7B6C),
          shader1: ColorSchemeConstants.ink,
          shader2: const Color(0xFF5F5E5B),
          shader3: ColorSchemeConstants.inkFaint,
          shader4: const Color(0xFFC7C6C3),
          shader5: ColorSchemeConstants.lightBorder,
          shader6: const Color(0xFFF1F1EF),
          shader7: ColorSchemeConstants.ink,
          bg1: ColorSchemeConstants.lightFill,
          bg2: ColorSchemeConstants.lightHover,
          bg3: ColorSchemeConstants.lightSelector,
          bg4: ColorSchemeConstants.ink,
          tint1: const Color(0xFFE8DEEE),
          tint2: const Color(0xFFF5E0E9),
          tint3: const Color(0xFFFBE4E4),
          tint4: const Color(0xFFFADEC9),
          tint5: const Color(0xFFFDECC8),
          tint6: const Color(0xFFE8F3D8),
          tint7: const Color(0xFFDBEDDB),
          tint8: const Color(0xFFD4F0EA),
          tint9: const Color(0xFFD3E5EF),
          main1: ColorSchemeConstants.ink,
          main2: ColorSchemeConstants.ink,
          shadow: const Color(0x14000000),
          sidebarBg: ColorSchemeConstants.lightFill,
          divider: ColorSchemeConstants.lightLine,
          topbarBg: ColorSchemeConstants.white,
          icon: ColorSchemeConstants.ink,
          text: ColorSchemeConstants.ink,
          secondaryText: ColorSchemeConstants.inkSoft,
          strongText: ColorSchemeConstants.ink,
          input: ColorSchemeConstants.white,
          hint: ColorSchemeConstants.inkFaint,
          primary: ColorSchemeConstants.ink,
          onPrimary: ColorSchemeConstants.white,
          hoverBG1: ColorSchemeConstants.lightHover,
          hoverBG2: ColorSchemeConstants.lightHover,
          hoverBG3: ColorSchemeConstants.lightCallout,
          hoverFG: ColorSchemeConstants.ink,
          questionBubbleBG: ColorSchemeConstants.lightCallout,
          progressBarBGColor: ColorSchemeConstants.lightSelector,
          toolbarColor: ColorSchemeConstants.white,
          toggleButtonBGColor: ColorSchemeConstants.lightBorder,
          calendarWeekendBGColor: ColorSchemeConstants.lightFill,
          gridRowCountColor: ColorSchemeConstants.inkFaint,
          borderColor: ColorSchemeConstants.lightLine,
          scrollbarColor: const Color(0x3337352F),
          scrollbarHoverColor: const Color(0x6637352F),
          lightIconColor: ColorSchemeConstants.inkFaint,
          toolbarHoverColor: const Color(0xFFF1F1EF),
        );

  const DefaultColorScheme.dark()
      : super(
          surface: ColorSchemeConstants.darkPage,
          hover: const Color(0x0EFFFFFF),
          selector: ColorSchemeConstants.darkHover,
          red: const Color(0xFFFF7369),
          yellow: const Color(0xFFFFDC49),
          green: const Color(0xFF4DAB9A),
          shader1: ColorSchemeConstants.darkPage,
          shader2: ColorSchemeConstants.darkSidebar,
          shader3: ColorSchemeConstants.darkFaint,
          shader4: const Color(0xFF5A5A5A),
          shader5: const Color(0xFFD4D4D4),
          shader6: ColorSchemeConstants.darkText,
          shader7: ColorSchemeConstants.white,
          bg1: ColorSchemeConstants.darkPage,
          bg2: const Color(0x14FFFFFF),
          bg3: ColorSchemeConstants.darkHover,
          bg4: ColorSchemeConstants.darkText,
          tint1: const Color(0xFF4A3060),
          tint2: const Color(0xFF5A3048),
          tint3: const Color(0xFF5C3A45),
          tint4: const Color(0xFF5C3D28),
          tint5: const Color(0xFF5C4E2A),
          tint6: const Color(0xFF3D4A2A),
          tint7: const Color(0xFF244533),
          tint8: const Color(0xFF1F4544),
          tint9: const Color(0xFF1E3A4C),
          main1: ColorSchemeConstants.darkText,
          main2: ColorSchemeConstants.darkText,
          shadow: const Color(0xFF000000),
          sidebarBg: ColorSchemeConstants.darkSidebar,
          divider: ColorSchemeConstants.darkLine,
          topbarBg: ColorSchemeConstants.darkSidebar,
          icon: const Color(0xFFD4D4D4),
          text: ColorSchemeConstants.darkText,
          secondaryText: ColorSchemeConstants.darkFaint,
          strongText: ColorSchemeConstants.white,
          input: ColorSchemeConstants.darkRaised,
          hint: ColorSchemeConstants.darkFaint,
          primary: ColorSchemeConstants.darkText,
          onPrimary: ColorSchemeConstants.darkPage,
          hoverBG1: const Color(0x0FFFFFFF),
          hoverBG2: const Color(0x14FFFFFF),
          hoverBG3: ColorSchemeConstants.darkRaised,
          hoverFG: ColorSchemeConstants.white,
          questionBubbleBG: ColorSchemeConstants.darkRaised,
          progressBarBGColor: ColorSchemeConstants.darkLine,
          toolbarColor: ColorSchemeConstants.darkRaised,
          toggleButtonBGColor: const Color(0xFF5A5A5A),
          calendarWeekendBGColor: ColorSchemeConstants.darkSidebar,
          gridRowCountColor: ColorSchemeConstants.darkFaint,
          borderColor: const Color(0xFF373737),
          scrollbarColor: const Color(0x33FFFFFF),
          scrollbarHoverColor: const Color(0x66FFFFFF),
          lightIconColor: ColorSchemeConstants.darkFaint,
          toolbarHoverColor: ColorSchemeConstants.darkHover,
        );
}
