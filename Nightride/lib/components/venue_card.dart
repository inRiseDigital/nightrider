import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
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

    final Widget cardContent = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      data.priceHint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: AppResponsive.font(context, 11).clamp(10.0, 12.0),
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
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(child: MarqueeText(text: data.title, style: titleStyle)),
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
                    child: MarqueeText(text: data.openText, style: metaStyle),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.gap(context, 10)),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'More details',
                    style: TextStyle(
                      fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
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
    );

    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    Widget card = isIOS
        ? GlassMorphismMaterial(
            blurIntensity: 20.0,
            opacity: 0.15,
            tintColor: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            enableGlassBorder: true,
            enableBackgroundDistortion: false,
            child: SizedBox(
              height: cardHeight,
              child: Padding(
                padding: EdgeInsets.all(innerPadding),
                child: cardContent,
              ),
            ),
          )
        : Container(
            height: cardHeight,
            padding: EdgeInsets.all(innerPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: AppTheme.surface,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x99000000), blurRadius: 26, offset: Offset(0, 18)),
                BoxShadow(color: Color(0x26f15991), blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: cardContent,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
