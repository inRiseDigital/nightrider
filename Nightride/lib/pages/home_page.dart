// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/components/home_category_rail.dart';
import 'package:nightride/components/home_country_filter.dart';
import 'package:nightride/components/home_featured_carousel.dart';
import 'package:nightride/components/home_location_row.dart';
import 'package:nightride/components/home_section_title.dart';
import 'package:nightride/components/home_top_bar.dart';
import 'package:nightride/components/home_trending_list.dart';
import 'package:nightride/components/home_ui_bits.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/profile_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/home_dummy_data.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider).data;
    final locationLabel = profile.city.isNotEmpty
        ? profile.city
        : profile.countryCode.isNotEmpty
            ? profile.countryCode
            : '';
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const HomeSmoothScrollBehavior(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppTheme.background, AppTheme.scaffold],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 110.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HomeTopBar(title: kAppTitle),
                  GapH(10),
                  if (locationLabel.isNotEmpty) HomeLocationRow(country: locationLabel),
                  if (locationLabel.isNotEmpty) GapH(16),
                  const HomeFeaturedCarousel(),
                  GapH(22),
                  HomeSectionTitle(title: l.exploreCategories),
                  GapH(12),
                  const HomeCategoryRail(),
                  GapH(14),
                  const HomeCountryFilter(),
                  GapH(18),
                  HomeSectionTitle(title: l.trendingEvents),
                  GapH(12),
                  const HomeTrendingList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
