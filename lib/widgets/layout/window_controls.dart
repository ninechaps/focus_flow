import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../theme/app_theme.dart';

/// Window control buttons for close, minimize, and full-screen toggle
class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _isFullScreen = false;

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      appWindow.maximize();
    } else {
      appWindow.restore();
    }
  }

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

class _WindowButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const _WindowButton({
    required this.color,
    required this.hoverColor,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: _isHovered
                ? Icon(
                    widget.icon,
                    size: 8,
                    color: Colors.black54,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
