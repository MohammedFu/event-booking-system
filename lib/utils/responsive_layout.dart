import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isCompact(BuildContext context) =>
      isCompactWidth(MediaQuery.sizeOf(context).width);

  static bool isCompactWidth(double width) => width < 360;

  static bool isPhoneWidth(double width) => width < 600;

  static int serviceGridCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 430) return 2;
    return 1;
  }

  static double serviceGridAspectRatio(double width) {
    if (width >= 1100) return 0.9;
    if (width >= 760) return 0.84;
    if (width >= 430) return 0.76;
    return 1.28;
  }

  static double horizontalServiceCardWidth(double width, double padding) {
    if (width < 380) {
      return width - (padding * 2);
    }
    if (width < 600) {
      return width * 0.82;
    }
    return 280;
  }

  static double chipWidth(double width, {int columns = 2, double spacing = 8}) {
    if (width < 420) {
      return width;
    }
    return (width - (spacing * (columns - 1))) / columns;
  }
}
