import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Status tabs for filtering tasks by their status
/// Displays three tabs: TODO, In Progress, Completed
class StatusTabs extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?>? onStatusChanged;

  const StatusTabs({
    super.key,
    this.selectedStatus,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _StatusTab(
            label: 'TODO',
            value: 'pending',
            isSelected: selectedStatus == 'pending',
            onTap: () => onStatusChanged?.call(
              selectedStatus == 'pending' ? null : 'pending',
            ),
          ),
          _StatusTab(
            label: 'In Progress',
            value: 'in_progress',
            isSelected: selectedStatus == 'in_progress',
            onTap: () => onStatusChanged?.call(
              selectedStatus == 'in_progress' ? null : 'in_progress',
            ),
          ),
          _StatusTab(
            label: 'Completed',
            value: 'completed',
            isSelected: selectedStatus == 'completed',
            onTap: () => onStatusChanged?.call(
              selectedStatus == 'completed' ? null : 'completed',
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual status tab button
class _StatusTab extends StatefulWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatusTab({
    required this.label,
    required this.value,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isSelected;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!_isHovered) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
          }
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: _getBackgroundColor(isActive),
              border: Border(
                bottom: BorderSide(
                  color: isActive ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primaryColor
                      : _isHovered
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isActive) {
    if (isActive) {
      return AppTheme.primaryColor.withValues(alpha: 0.05);
    }
    if (_isHovered) {
      return AppTheme.backgroundColor;
    }
    return Colors.transparent;
  }
}
