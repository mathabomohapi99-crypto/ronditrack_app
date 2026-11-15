// NEW 10.2: the only place window-size breakpoints are written; nothing asks "is this a tablet?"
import 'package:flutter/widgets.dart';

enum WindowSize { compact, medium, expanded }

const double mediumBreakpoint = 600;
const double expandedBreakpoint = 840;

WindowSize windowSizeForWidth(double width) {
  if (width < mediumBreakpoint) return WindowSize.compact;
  if (width < expandedBreakpoint) return WindowSize.medium;
  return WindowSize.expanded;
}

extension WindowSizeContext on BuildContext {
  // Reads the WINDOW width (not the device), so split-screen and rotation are handled
  WindowSize get windowSize =>
      windowSizeForWidth(MediaQuery.sizeOf(this).width);
}
