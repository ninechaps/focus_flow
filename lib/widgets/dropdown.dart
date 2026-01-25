import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// ProfessionalDropdown - 专业下拉菜单组件
/// ============================================================================

class _DropdownColors {
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color border = AppTheme.dividerColor;
  static const Color background = AppTheme.backgroundColor;
  static const Color surface = AppTheme.surfaceColor;
}

class _DropdownTypography {
  static const TextStyle labelStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _DropdownColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle inputStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.normal,
    color: _DropdownColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle helperStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: _DropdownColors.textSecondary,
    height: 1.3,
  );
}

/// 标准下拉菜单组件 - 用于 Goal 选择等
class ProfessionalDropdown<T> extends StatefulWidget {
  final String label;
  final String? helper;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const ProfessionalDropdown({
    super.key,
    required this.label,
    this.helper,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  State<ProfessionalDropdown<T>> createState() =>
      _ProfessionalDropdownState<T>();
}

/// PopupMenuButton 包装器 - 用于时间、年份等只显示图标的下拉菜单
class ProfessionalIconDropdown<T> extends StatelessWidget {
  final String displayText;
  final IconData icon;
  final List<PopupMenuEntry<T>> items;
  final void Function(T)? onSelected;

  const ProfessionalIconDropdown({
    super.key,
    required this.displayText,
    required this.icon,
    required this.items,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _DropdownColors.textPrimary,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: PopupMenuButton<T>(
            onSelected: onSelected,
            itemBuilder: (context) => items,
            child: Icon(
              icon,
              size: 18,
              color: _DropdownColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfessionalDropdownState<T> extends State<ProfessionalDropdown<T>> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: _DropdownTypography.labelStyle),
        const SizedBox(height: 4),
        Container(
          height: 38, // 统一高度标准
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isFocused ? _DropdownColors.primary : _DropdownColors.border,
              width: isFocused ? 1.5 : 1,
            ),
            color: _DropdownColors.background,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: _DropdownColors.primary.withAlpha(8),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: widget.value,
              items: widget.items,
              onChanged: widget.onChanged,
              isExpanded: true,
              focusNode: _focusNode,
              style: _DropdownTypography.inputStyle,
              dropdownColor: _DropdownColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: 14, // 14px
              ),
              isDense: true,
              icon: Icon(
                Icons.expand_more,
                size: 14,
                color: isFocused
                    ? _DropdownColors.primary
                    : _DropdownColors.textSecondary,
              ),
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 4),
          Text(widget.helper!, style: _DropdownTypography.helperStyle),
        ],
      ],
    );
  }
}
