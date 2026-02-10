import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// 计划/回顾 Tab 切换组件 — 胶囊样式
class ScheduleTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ScheduleTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final tabs = [l10n.scheduleTabPlan, l10n.scheduleTabReview];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
