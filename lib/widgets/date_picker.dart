import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// DatePicker - 专业日期选择器
/// ============================================================================

/// 专业日期选择器组件
class DatePicker extends StatelessWidget {
  final String label;
  final String? helper;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback? onClear;
  final String Function(DateTime)? formatDate;

  const DatePicker({
    super.key,
    required this.label,
    this.helper,
    this.selectedDate,
    required this.onDateChanged,
    this.onClear,
    this.formatDate,
  });

  String _defaultFormat(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasDate = selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final date = await showDialog<DateTime>(
                context: context,
                builder: (context) => DatePickerDialog(
                  initialDate: selectedDate ?? DateTime.now(),
                ),
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: hasDate ? colors.primary : colors.divider,
                  width: hasDate ? 1.5 : 1,
                ),
                color: colors.background,
                boxShadow: hasDate
                    ? [
                        BoxShadow(
                          color: colors.primary.withAlpha(8),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: hasDate
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      hasDate
                          ? (formatDate?.call(selectedDate!) ??
                              _defaultFormat(selectedDate!))
                          : '选择日期',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.normal,
                        color: hasDate ? colors.textPrimary : colors.textHint,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (hasDate && onClear != null) ...[
                    const SizedBox(width: AppTheme.spacingSm),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          onClear?.call();
                          onDateChanged(null);
                        },
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// 日期选择对话框
class DatePickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const DatePickerDialog({
    super.key,
    required this.initialDate,
  });

  @override
  State<DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<DatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _selectedHour = _selectedDate.hour;
    _selectedMinute = _selectedDate.minute;

    if (_selectedMinute < 15) {
      _selectedMinute = 0;
    } else if (_selectedMinute < 45) {
      _selectedMinute = 30;
    } else {
      _selectedMinute = 0;
      _selectedHour = (_selectedHour + 1) % 24;
    }
  }

  void _selectDate(int day) {
    setState(() {
      _selectedDate = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        day,
        _selectedHour,
        _selectedMinute,
      );
    });
  }

  void _setHour(int hour) {
    setState(() {
      _selectedHour = hour;
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      );
    });
  }

  void _setMinute(int minute) {
    setState(() {
      _selectedMinute = minute;
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      );
    });
  }

  void _clear() {
    Navigator.pop(context);
  }

  void _confirm() {
    Navigator.pop(context, _selectedDate);
  }

  bool _isToday(int day) {
    final today = DateTime.now();
    return day == today.day &&
        _displayedMonth.month == today.month &&
        _displayedMonth.year == today.year;
  }

  bool _isSelected(int day) {
    return day == _selectedDate.day &&
        _displayedMonth.month == _selectedDate.month &&
        _displayedMonth.year == _selectedDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = monthNames[_displayedMonth.month - 1];
    final year = _displayedMonth.year;

    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;

    return Dialog(
      backgroundColor: colors.background,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month and Year
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        year.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: PopupMenuButton<int>(
                          onSelected: (selectedYear) {
                            setState(() {
                              _displayedMonth = DateTime(
                                selectedYear,
                                _displayedMonth.month,
                              );
                            });
                          },
                          itemBuilder: (context) {
                            return List.generate(
                              20,
                              (index) {
                                final y = year - 10 + index;
                                return PopupMenuItem(
                                  value: y,
                                  child: Text(y.toString()),
                                );
                              },
                            );
                          },
                          child: Icon(
                            Icons.expand_more,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _displayedMonth =
                                  DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                            });
                          },
                          child: Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _displayedMonth =
                                  DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                            });
                          },
                          child: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['日', '一', '二', '三', '四', '五', '六']
                    .map((day) => SizedBox(
                          width: 30,
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int week = 0;
                      week < (startingWeekday + daysInMonth + 6) ~/ 7;
                      week++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (int day = 0; day < 7; day++)
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: _buildDayCell(
                              week,
                              day,
                              startingWeekday,
                              daysInMonth,
                              colors,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Time selector row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTimeSelector(colors),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colors.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: Text(
                          '清除',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(AppColors colors) {
    final timeOptions = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute in [0, 30]) {
        timeOptions.add(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        );
      }
    }

    final currentTime =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '选择时间: $currentTime',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: PopupMenuButton<String>(
            onSelected: (selectedTime) {
              final parts = selectedTime.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);
              _setHour(hour);
              _setMinute(minute);
            },
            itemBuilder: (context) {
              return timeOptions.map((timeStr) {
                return PopupMenuItem(
                  value: timeStr,
                  child: Text(timeStr),
                );
              }).toList();
            },
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    int week,
    int day,
    int startingWeekday,
    int daysInMonth,
    AppColors colors,
  ) {
    final cellIndex = week * 7 + day;
    final dayOfMonth = cellIndex - startingWeekday + 1;

    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
      return const SizedBox();
    }

    final isSelected = _isSelected(dayOfMonth);
    final isToday = _isToday(dayOfMonth);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectDate(dayOfMonth),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                dayOfMonth.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : colors.textPrimary,
                ),
              ),
              if (isToday && !isSelected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(2),
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
