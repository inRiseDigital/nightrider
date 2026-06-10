import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/components/profile_bio_card.dart';
import 'package:nightride/components/profile_header.dart';
import 'package:nightride/components/profile_interests.dart';
import 'package:nightride/components/profile_top_bar.dart';
import 'package:nightride/components/rank_card.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/rank_system.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';
import 'package:nightride/services/favourites_service.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:nightride/pages/settings_page.dart';
import 'package:nightride/components/nightrite_refresh.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyPointsProvider); // awards daily login points
    final state = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final avatarBase64 = ref.watch(avatarBase64Provider).asData?.value;
    final partiesCount = ref.watch(favouritesStreamProvider).asData?.value.length ?? state.data.partiesAttended;

    final bool editing = state.isEditing;

    // view shows saved data, edit shows draft
    final List<String> shownInterests =
        editing ? state.draftInterests : state.data.interests;

    final hPad = AppResponsive.pagePadding(context);
    final bottomNavSpace = AppResponsive.bottomNavHeight(context) +
        AppResponsive.gap(context, 24);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppTheme.background, AppTheme.scaffold],
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
                    ProfileTopBar(
                      data: state.data,
                      isEditing: editing,
                      onMenu: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      ),
                      onCancel: controller.cancelEdit,
                    ),
                    SizedBox(height: AppResponsive.profileSectionGap(context)),

                    ProfileHeader(
                      state: state,
                      onEdit: controller.enterEdit,
                      onSave: controller.saveEdit,
                      onCancel: controller.cancelEdit,
                      avatarBase64: avatarBase64,
                    ),
                    SizedBox(height: AppResponsive.profileSectionGap(context)),

                    RankCard(data: state.data),
                    SizedBox(height: AppResponsive.profileSectionGap(context)),

                    ProfileBioCard(
                      isEditing: editing,
                      value: editing ? state.draftBio : state.data.bio,
                      onChanged: controller.setDraftBio,
                    ),
                    SizedBox(height: AppResponsive.profileSectionGap(context)),

                    // Interests
                    ProfileInterests(
                      isEditing: editing,
                      selectedInterests: shownInterests,
                      allOptions: controller.allInterestOptions,
                      isSelected: controller.isInterestSelected,
                      onToggle: controller.toggleInterest,
                      onRemove: controller.removeInterest,
                    ),
                    SizedBox(height: AppResponsive.profileSectionGap(context)),

                    // Gamified Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: AppResponsive.gap(context, 12),
                      mainAxisSpacing: AppResponsive.gap(context, 12),
                      childAspectRatio: AppResponsive.profileStatGridAspectRatio(context),
                      children: [
                        _StatFeatureCard(label: 'PARTIES', value: '$partiesCount', icon: Icons.celebration_rounded),
                        _StatFeatureCard(label: 'FRIENDS', value: '${state.data.friendsCount}', icon: Icons.people_alt_rounded),
                        _StatFeatureCard(label: 'STREAK', value: '${state.data.streakDays} DAYS', icon: Icons.local_fire_department_rounded),
                        _StatFeatureCard(
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
                    Center(
                      child: Text(
                        state.data.joinedText,
                        style: TextStyle(
                          fontSize: AppResponsive.font(context, 11),
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.35),
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

class _StatFeatureCard extends StatelessWidget {
  const _StatFeatureCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: AppResponsive.icon(context, 18).clamp(15.0, 18.0)),
          ),
          SizedBox(width: AppResponsive.gap(context, 10).clamp(8.0, 12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.0), fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 9).clamp(8.0, 10.0), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
