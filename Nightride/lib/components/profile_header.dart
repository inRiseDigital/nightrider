import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/rank_system.dart';
import 'package:nightride/pages/badges_collection_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/profile_models.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.avatarBase64,
  });

  final ProfileState state;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? avatarBase64;

  @override
  Widget build(BuildContext context) {
    final d = state.data;
    final sideImage = AppResponsive.profileSideImageSize(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _Avatar(url: d.avatarUrl, avatarBase64: avatarBase64),
        SizedBox(width: AppResponsive.profileHeaderGap(context)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                d.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppResponsive.profileUsernameFont(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (d.pronouns.isNotEmpty)
                Text(
                  d.pronouns,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: AppResponsive.profilePronounsFont(context),
                  ),
                ),
              SizedBox(height: AppResponsive.gap(context, 5)),
              _RankBadge(points: d.rank),
              SizedBox(height: AppResponsive.gap(context, 6)),
              _StatText(label: 'Network', value: d.networkCount.toString()),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BadgesCollectionPage()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: sideImage,
                height: sideImage,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppResponsive.radius(context, 16)),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                padding: EdgeInsets.all(AppResponsive.gap(context, 10)),
                child: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/8644/8644445.png',
                  color: Colors.pinkAccent,
                ),
              ),
              SizedBox(height: AppResponsive.gap(context, 4)),
              Container(
                height: AppResponsive.gap(context, 6),
                width: sideImage * 0.55,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.profileNetworkFont(context);
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(color: Colors.white60, fontSize: size),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, this.avatarBase64});
  final String url;
  final String? avatarBase64;

  @override
  Widget build(BuildContext context) {
    final double s = AppResponsive.profileAvatarSize(context);
    final double fallbackIcon = s * 0.5;
    Widget child;

    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      child = Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover);
    } else if (url.isNotEmpty && url.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.06)),
        errorWidget: (_, __, ___) => Icon(Icons.person_rounded, color: Colors.white38, size: fallbackIcon),
      );
    } else {
      child = Icon(Icons.person_rounded, color: Colors.white38, size: fallbackIcon);
    }

    return Container(
      width: s,
      height: s,
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.65), width: 2),
      ),
      child: ClipOval(child: child),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
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
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.8.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    final tier = RankSystem.tierFor(points);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: tier.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tier.emoji, style: TextStyle(fontSize: 10.sp)),
          SizedBox(width: 4.w),
          Text(
            tier.name,
            style: TextStyle(
              color: tier.color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.8.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}
