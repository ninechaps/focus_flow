import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 统一的应用输入框组件
/// 在整个应用中保持一致的输入框样式
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helper;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool autofocus;
  final int maxLines;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final bool enabled;
  final Widget? prefixIcon;
  final VoidCallback? onFieldSubmitted;
  final bool obscureText;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.controller,
    this.validator,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 59),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spacingXs),
          ],
          TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            minLines: widget.maxLines == 1 ? 1 : null,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            obscureText: widget.obscureText,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              // 当没有 prefixIcon 时，用 suffixIcon 占位来保持高度一致，不占位宽度
              suffixIcon: widget.prefixIcon == null ?
                const SizedBox(width: 0, height: 40) : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIconConstraints: const BoxConstraints(
                minHeight: 40,
              ),
            ),
            onFieldSubmitted: widget.onFieldSubmitted != null
                ? (_) => widget.onFieldSubmitted!()
                : null,
            validator: widget.validator,
          ),
          if (widget.helper != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              widget.helper!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
