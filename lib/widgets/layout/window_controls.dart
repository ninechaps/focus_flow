import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Window control buttons area (reserved for future close/minimize/fullscreen)
class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingXs,
        right: AppTheme.spacingXs,
        top: 4,
        bottom: 2,
      ),
    );
  }
}
