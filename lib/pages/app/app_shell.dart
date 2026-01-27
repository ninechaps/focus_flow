import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../widgets/layout/sidebar.dart';
import '../../theme/app_theme.dart';

/// Main application shell with sidebar layout
/// This widget wraps all authenticated pages with the common sidebar navigation
class AppShell extends StatelessWidget {
  /// The child widget to display in the main content area
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed-width sidebar
          const Sidebar(),

          // Main content area
          Expanded(
            child: Stack(
              children: [
                // Page content (full height, no constraints from title bar)
                Container(
                  color: AppTheme.backgroundColor,
                  child: child,
                ),

                // Draggable title bar area (overlay for window dragging only)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _DraggableTitleBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draggable title bar for window movement (transparent overlay)
class _DraggableTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => appWindow.startDragging(),
      behavior: HitTestBehavior.translucent,
      child: const SizedBox(height: 28),
    );
  }
}
