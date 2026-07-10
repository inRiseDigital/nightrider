import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/components/profile_bio_card.dart';
import 'package:nightride/components/profile_header.dart';
import 'package:nightride/components/profile_interests.dart';
import 'package:nightride/components/profile_top_bar.dart';
import 'package:nightride/components/rank_card.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/rank_system.dart';
import '../providers/profile_providers.dart';
import 'package:nightride/services/favourites_service.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:nightride/pages/settings_page.dart';
import 'package:nightride/components/nightrite_refresh.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kBlack      = Color(0xFF070707);
const _kNeonLime   = Color(0xFFDFFF2F);
const _kBorderGray = Color(0xFF333333);
const _kCard       = Color(0xFF0F0F0F);
const _kWhite      = Color(0xFFFAFAFA);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyPointsProvider); // awards daily login points
    final state        = ref.watch(profileProvider);
    final controller   = ref.read(profileProvider.notifier);
    final avatarBase64 = ref.watch(avatarBase64Provider).asData?.value;
    final partiesCount = ref.watch(favouritesStreamProvider).asData?.value.length
        ?? state.data.partiesAttended;

    final bool editing = state.isEditing;
    final List<String> shownInterests =
        editing ? state.draftInterests : state.data.interests;

    final hPad          = AppResponsive.pagePadding(context);
    final bottomNavSpace = AppResponsive.bottomNavHeight(context) +
        AppResponsive.gap(context, 24);

    return Scaffold(
      backgroundColor: _kBlack,
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF0D0D0D), _kBlack],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: NightRiteRefresh(
                onRefresh: () async {
                  ref.invalidate(profileProvider);
                  ref.invalidate(userProfileDocProvider);
                  await Future<void>.delayed(const Duration(milliseconds: 600));
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppResponsive.gap(context, 14),
                    hPad,
                    bottomNavSpace,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Top bar (settings / cancel) ──
                      ProfileTopBar(
                        data: state.data,
                        isEditing: editing,
                        onMenu: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        ),
                        onCancel: controller.cancelEdit,
                      ),
                      SizedBox(height: AppResponsive.profileSectionGap(context)),

                      // ── Avatar / name / rank badge / network ──
                      ProfileHeader(
                        state: state,
                        onEdit: controller.enterEdit,
                        onSave: controller.saveEdit,
                        onCancel: controller.cancelEdit,
                        avatarBase64: avatarBase64,
                      ),
                      SizedBox(height: AppResponsive.profileSectionGap(context)),

                      // ── Rank progress card ──
                      RankCard(data: state.data),
                      SizedBox(height: AppResponsive.profileSectionGap(context)),

                      // ── Bio card ──
                      ProfileBioCard(
                        isEditing: editing,
                        value: editing ? state.draftBio : state.data.bio,
                        onChanged: controller.setDraftBio,
                      ),
                      SizedBox(height: AppResponsive.profileSectionGap(context)),

                      // ── Interests chips ──
                      ProfileInterests(
                        isEditing: editing,
                        selectedInterests: shownInterests,
                        allOptions: controller.allInterestOptions,
                        isSelected: controller.isInterestSelected,
                        onToggle: controller.toggleInterest,
                        onRemove: controller.removeInterest,
                      ),
                      SizedBox(height: AppResponsive.profileSectionGap(context)),

                      // ── Stats grid (4 cards) ──
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppResponsive.gap(context, 12),
                        mainAxisSpacing: AppResponsive.gap(context, 12),
                        childAspectRatio:
                            AppResponsive.profileStatGridAspectRatio(context),
                        children: [
                          _StatCard(
                            label: 'PARTIES',
                            value: '$partiesCount',
                            icon: Icons.celebration_rounded,
                          ),
                          _StatCard(
                            label: 'FRIENDS',
                            value: '${state.data.friendsCount}',
                            icon: Icons.people_alt_rounded,
                          ),
                          _StatCard(
                            label: 'STREAK',
                            value: '${state.data.streakDays} DAYS',
                            icon: Icons.local_fire_department_rounded,
                          ),
                          _StatCard(
                            label: 'RANK',
                            value: () {
                              final t = RankSystem.tierFor(state.data.rank);
                              return '${t.emoji} ${t.name}';
                            }(),
                            icon: Icons.leaderboard_rounded,
                          ),
                        ],
                      ),

                      SizedBox(height: AppResponsive.gap(context, 32)),

                      // ── Joined date footer ──
                      Center(
                        child: Text(
                          state.data.joinedText,
                          style: TextStyle(
                            fontSize: AppResponsive.font(context, 11),
                            fontWeight: FontWeight.w700,
                            color: _kWhite.withValues(alpha: 0.25),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats grid card ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorderGray, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon in neonLime pill
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _kNeonLime,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _kBlack,
              size: AppResponsive.icon(context, 18).clamp(15.0, 20.0),
            ),
          ),

          SizedBox(width: AppResponsive.gap(context, 10).clamp(8.0, 13.0)),

          // Value + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _kWhite,
                    fontSize: AppResponsive.font(context, 13).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.font(context, 9).clamp(8.0, 10.0),
                    color: _kWhite.withValues(alpha: 0.40),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
