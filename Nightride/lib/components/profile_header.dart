import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _Avatar(url: d.avatarUrl, avatarBase64: avatarBase64),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                d.username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                d.pronouns,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              _StatText(label: 'Network', value: d.networkCount.toString()),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BadgesCollectionPage()),
          ),
          child: Column(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                padding: EdgeInsets.all(10.r),
                child: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/8644/8644445.png',
                  color: Colors.pinkAccent,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                height: 6.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
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
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(color: Colors.white60, fontSize: 13.sp),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
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
    final double s = 86.w;
    Widget child;

    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      child = Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover);
    } else if (url.isNotEmpty && url.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.06)),
        errorWidget: (_, __, ___) => Icon(Icons.person_rounded, color: Colors.white38, size: 44.sp),
      );
    } else {
      child = Icon(Icons.person_rounded, color: Colors.white38, size: 44.sp);
    }

    return Container(
      width: s,
      height: s,
      padding: EdgeInsets.all(3.w),
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
