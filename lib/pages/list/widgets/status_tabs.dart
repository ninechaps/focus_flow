import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/enums.dart';

/// Status tabs for filtering tasks by their status
/// Displays three tabs with Chinese labels and count badges: 待办、进行中、已完成
class StatusTabs extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?>? onStatusChanged;
  final List<Task> tasks;

  const StatusTabs({
    super.key,
    this.selectedStatus,
    this.onStatusChanged,
    this.tasks = const [],
  });

  Map<String, int> _calculateCounts() {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.pending:
          pending++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
        case TaskStatus.completed:
          completed++;
          break;
        case TaskStatus.deleted:
          break;
      }
    }

    return {
      'pending': pending,
      'in_progress': inProgress,
      'completed': completed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final counts = _calculateCounts();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _StatusTab(
            label: '待办',
            value: 'pending',
            count: counts['pending'] ?? 0,
            isSelected: selectedStatus == 'pending',
            onTap: () => onStatusChanged?.call(
              selectedStatus == 'pending' ? null : 'pending',
            ),
          ),
          _StatusTab(
            label: '进行中',
            value: 'in_progress',
            count: counts['in_progress'] ?? 0,
            isSelected: selectedStatus == 'in_progress',
            onTap: () => onStatusChanged?.call(
              selectedStatus == 'in_progress' ? null : 'in_progress',
            ),
          ),
          _StatusTab(
            label: '已完成',
            value: 'completed',
            count: counts['completed'] ?? 0,
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

/// Individual status tab button with count badge
class _StatusTab extends StatefulWidget {
  final String label;
  final String value;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatusTab({
    required this.label,
    required this.value,
    required this.count,
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
    final colors = context.appColors;
    final bool isActive = widget.isSelected;

    return MouseRegion(
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
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? colors.primary
                      : _isHovered
                          ? colors.textPrimary
                          : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primaryLight
                      : colors.badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? colors.primary
                        : colors.textHint,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
