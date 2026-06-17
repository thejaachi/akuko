import 'package:flutter/widgets.dart';

/// Standard responsive breakpoints (logical pixels).
enum DeviceScreen { mobile, tablet, desktop }

class Breakpoints {
  const Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Responsive helpers built on top of [MediaQuery].
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  DeviceScreen get deviceScreen {
    final w = screenWidth;
    if (w >= Breakpoints.tablet) return DeviceScreen.desktop;
    if (w >= Breakpoints.mobile) return DeviceScreen.tablet;
    return DeviceScreen.mobile;
  }

  bool get isMobile => deviceScreen == DeviceScreen.mobile;
  bool get isTablet => deviceScreen == DeviceScreen.tablet;
  bool get isDesktop => deviceScreen == DeviceScreen.desktop;

  /// Pick a value based on the current breakpoint, falling back to [mobile].
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceScreen) {
      case DeviceScreen.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceScreen.tablet:
        return tablet ?? mobile;
      case DeviceScreen.mobile:
        return mobile;
    }
  }
}

/// Number of columns to use for a responsive grid of book covers.
int responsiveGridCount(BuildContext context) => context.responsive(
      mobile: 2,
      tablet: 4,
      desktop: 6,
    );

/// Widget that builds different layouts per breakpoint.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => context.responsive(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
