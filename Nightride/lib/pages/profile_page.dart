import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/components/profile_bio_card.dart';
import 'package:nightride/components/profile_header.dart';
import 'package:nightride/components/profile_interests.dart';
import 'package:nightride/components/profile_social_links.dart';
import 'package:nightride/components/profile_top_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:nightride/pages/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final avatarBase64 = ref.watch(avatarBase64Provider).asData?.value;

    final bool editing = state.isEditing;

    // view shows saved data, edit shows draft
    final List<String> shownInterests =
        editing ? state.draftInterests : state.data.interests;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppTheme.background, AppTheme.scaffold],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
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
                SizedBox(height: 25.h),

                ProfileHeader(
                  state: state,
                  onEdit: controller.enterEdit,
                  onSave: controller.saveEdit,
                  onCancel: controller.cancelEdit,
                  avatarBase64: avatarBase64,
                ),
                SizedBox(height: 20.h),

                ProfileBioCard(
                  isEditing: editing,
                  value: editing ? state.draftBio : state.data.bio,
                  onChanged: controller.setDraftBio,
                ),
                SizedBox(height: 18.h),

                // Interests 
                ProfileInterests(
                  isEditing: editing,
                  selectedInterests: shownInterests,
                  allOptions: controller.allInterestOptions,
                  isSelected: controller.isInterestSelected,
                  onToggle: controller.toggleInterest,
                  onRemove: controller.removeInterest,
                ),
                SizedBox(height: 20.h),

                // Gamified Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 2.2,
                  children: [
                    _StatFeatureCard(label: 'PARTIES', value: '${state.data.partiesAttended}', icon: Icons.celebration_rounded),
                    _StatFeatureCard(label: 'FRIENDS', value: '${state.data.friendsCount}', icon: Icons.people_alt_rounded),
                    _StatFeatureCard(label: 'STREAK', value: '${state.data.streakDays} DAYS', icon: Icons.local_fire_department_rounded),
                    _StatFeatureCard(label: 'RANK', value: state.data.rank > 0 ? '#${state.data.rank}' : '—', icon: Icons.leaderboard_rounded),
                  ],
                ),

                SizedBox(height: 40.h),
                Center(
                  child: Text(
                    state.data.joinedText,
                    style: TextStyle(
                      fontSize: 11.sp,
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
