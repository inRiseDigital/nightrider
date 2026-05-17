import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onSelected,
  });

  final List<MapCategory> items;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final chipHeight = AppResponsive.mapChipHeight(context);
    final hPad = AppResponsive.pagePadding(context);
    final innerPadH = AppResponsive.gap(context, 14);
    final innerPadV = AppResponsive.gap(context, 6);
    final fontSize = AppResponsive.font(context, 12);
    final separator = AppResponsive.gap(context, 8);

    return SizedBox(
      height: chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: separator),
        itemBuilder: (BuildContext context, int index) {
          final MapCategory item = items[index];
          final bool selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected?.call(selected ? null : index),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppResponsive.gap(context, 64),
                maxWidth: AppResponsive.gap(context, 160),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: innerPadH,
                  vertical: innerPadV,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.85)
                      : AppTheme.surface.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.55),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: selected ? Colors.white : AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
