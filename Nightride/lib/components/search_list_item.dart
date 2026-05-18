// lib/components/search_list_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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
        padding: const EdgeInsets.only(left: 4, right: 6),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: <Widget>[
                  _AvatarCircle(url: item.avatarUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppResponsive.font(context, 14.5).clamp(13.0, 15.5),
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppResponsive.font(context, 11.5).clamp(10.0, 12.5),
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
                margin: const EdgeInsets.only(left: 70),
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
    final double s = AppResponsive.gap(context, 46).clamp(40.0, 52.0);

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
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
