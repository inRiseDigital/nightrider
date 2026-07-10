import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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

  static const _neonLime     = Color(0xFFDFFF2F);
  static const _border       = Color(0xFF333333);
  static const _cardSurface  = Color(0xFF0F0F0F);

  @override
  Widget build(BuildContext context) {
    final chipHeight = AppResponsive.mapChipHeight(context);
    final hPad       = AppResponsive.pagePadding(context);
    final innerPadH  = AppResponsive.gap(context, 16);
    final innerPadV  = AppResponsive.gap(context, 8);
    final fontSize   = AppResponsive.font(context, 13);
    final separator  = AppResponsive.gap(context, 8);

    return SizedBox(
      height: chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: separator),
        itemBuilder: (BuildContext context, int index) {
          final MapCategory item    = items[index];
          final bool        selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected?.call(selected ? null : index),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppResponsive.gap(context, 64),
                maxWidth: AppResponsive.gap(context, 160),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: innerPadH,
                  vertical:   innerPadV,
                ),
                decoration: BoxDecoration(
                  color: selected ? _neonLime : _cardSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? _neonLime : _border,
                    width: selected ? 1.5 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: selected ? const Color(0xFF070707) : Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
