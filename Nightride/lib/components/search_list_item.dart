// lib/components/search_list_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/domain/search_models.dart';

class SearchListItem extends StatelessWidget {
  const SearchListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.showDivider,
  });

  final SearchSuggestionItem item;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 4.w, right: 6.w),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                children: <Widget>[
                  _AvatarCircle(url: item.avatarUrl),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Container(
                height: 1,
                margin: EdgeInsets.only(left: 70.w),
                color: Colors.white.withValues(alpha: 0.08),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final double s = 46.w;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          url == null
              ? const SizedBox.shrink()
              : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
    );
  }
}
