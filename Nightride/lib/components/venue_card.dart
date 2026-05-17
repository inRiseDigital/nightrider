// lib/features/map/presentation/widgets/venue_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/components/marquee_text.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onMoreDetails,
  });

  final MapBottomCardData data;
  final VoidCallback onTap;
  final VoidCallback onMoreDetails;

  @override
  Widget build(BuildContext context) {
    final cardHeight = AppResponsive.mapBottomCardHeight(context);
    final imageWidth = AppResponsive.mapBottomCardImageSize(context);
    final innerPadding = AppResponsive.gap(context, 10);
    final radius = AppResponsive.radius(context, 22);
    final imageRadius = AppResponsive.radius(context, 16);
    final buttonHeight = AppResponsive.gap(context, 30).clamp(28.0, 36.0);

    final TextStyle titleStyle = TextStyle(
      color: Colors.white,
      fontSize: AppResponsive.font(context, 15.5),
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
      height: 1.05,
    );

    final TextStyle metaStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.70),
      fontSize: AppResponsive.font(context, 12),
      fontWeight: FontWeight.w700,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: cardHeight,
          padding: EdgeInsets.all(innerPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppTheme.surface.withValues(alpha: 0.98),
                const Color(0xFF131024).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 26.r,
                offset: Offset(0, 18.h),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.10),
                blurRadius: 24.r,
                offset: Offset(0, 14.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(imageRadius),
                child: SizedBox(
                  width: imageWidth,
                  height: double.infinity,
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
                              Colors.black.withValues(alpha: 0.00),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),

                      /// PRICE HINT
                      Positioned(
                        left: 8.w,
                        bottom: 8.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            data.priceHint,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: AppResponsive.gap(context, 10)),

              /// TEXT + BUTTON
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: MarqueeText(text: data.title, style: titleStyle),
                    ),
                    SizedBox(height: AppResponsive.gap(context, 6)),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.access_time_rounded,
                          size: AppResponsive.icon(context, 14),
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                        SizedBox(width: AppResponsive.gap(context, 6)),
                        Expanded(
                          child: MarqueeText(
                            text: data.openText,
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.gap(context, 10)),

                    /// MORE DETAILS BUTTON
                    SizedBox(
                      height: buttonHeight,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onMoreDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'More details',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
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
      ),
    );
  }
}
