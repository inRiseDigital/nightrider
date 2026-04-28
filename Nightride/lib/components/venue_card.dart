// lib/features/map/presentation/widgets/venue_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/marquee_text.dart';
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
    final TextStyle titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 15.8.sp,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
      height: 1.05,
    );

    final TextStyle metaStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.70),
      fontSize: 12.2.sp,
      fontWeight: FontWeight.w700,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          height: 118.h,
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
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
            children: <Widget>[
              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox(
                  width: 110.w,
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

              Gap(10.w),

              /// TEXT + BUTTON
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 18.h,
                      child: MarqueeText(text: data.title, style: titleStyle),
                    ),
                    Gap(6.h),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.access_time_rounded,
                          size: 14.sp,
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                        Gap(6.w),
                        Expanded(
                          child: MarqueeText(
                            text: data.openText,
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                    Gap(10.h),

                    /// MORE DETAILS BUTTON
                    SizedBox(
                      height: 34.h,
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
