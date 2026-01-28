import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// ProfessionalDropdown - 专业下拉菜单组件
/// ============================================================================

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
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          displayText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
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
              color: colors.textSecondary,
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
    final colors = context.appColors;
    final isFocused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isFocused ? colors.primary : colors.divider,
              width: isFocused ? 1.5 : 1,
            ),
            color: colors.background,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(8),
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
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.normal,
                color: colors.textPrimary,
                height: 1.4,
              ),
              dropdownColor: colors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              isDense: true,
              icon: Icon(
                Icons.expand_more,
                size: 14,
                color: isFocused
                    ? colors.primary
                    : colors.textSecondary,
              ),
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helper!,
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
