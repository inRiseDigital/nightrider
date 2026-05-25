import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';

class VenueModal extends ConsumerWidget {
  const VenueModal({super.key, required this.data, required this.onNavigate});

  final MapBottomCardData data;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(userLocationProvider).asData?.value;
    final double km = (userPos != null && data.lat != 0 && data.lng != 0)
        ? haversineKm(userPos.latitude, userPos.longitude, data.lat, data.lng)
        : 0;
    final String distLabel = formatDistance(km);
    final String travelLabel = formatTravel(km);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.gap(context, 14),
        AppResponsive.gap(context, 10),
        AppResponsive.gap(context, 14),
        AppResponsive.gap(context, 14),
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 40,
            offset: Offset(0, -18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Hero(
                    tag: 'venue_image_${data.title}',
                    child: Image.network(data.imageUrl, fit: BoxFit.cover),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.70),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        data.openText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 17).clamp(15.0, 18.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      distLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (travelLabel.isNotEmpty) ...[
                    const Gap(3),
                    Text(
                      travelLabel,
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Gap(6),
          Text(
            data.locationLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const Gap(10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('See full details'),
                ),
              ),
            ],
          ),
          const Gap(10),
        ],
      ),
    );
  }
}
