// lib/pages/notifications_page.dart
//
// Destination for the Home tab's bell icon. No notification feed backend
// exists yet, so this renders the retro-poster empty state.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppTheme.cream),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.anton(
            color: AppTheme.cream,
            fontSize: AppResponsive.font(context, 20).clamp(16.0, 24.0),
            letterSpacing: 2,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderGray, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 34,
                  color: AppTheme.cream.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ALL QUIET FOR NOW',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
                  color: AppTheme.cream,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You'll see updates about your saved events and plans here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.cream.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
