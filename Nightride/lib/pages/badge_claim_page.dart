// lib/pages/badge_claim_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlack   = Color(0xFF070707);
const _kDark    = Color(0xFF151515);
const _kBorder  = Color(0xFF2A2A2A);
const _kLime    = Color(0xFFDFFF2F);
const _kPink    = Color(0xFFFF3D73);
const _kCream   = Color(0xFFF3EAD6);
const _kWhite   = Color(0xFFFAFAFA);

// ── Badge task data ───────────────────────────────────────────────────────────

class _Task {
  final String title;
  final String description;
  final double progress;
  final bool isClaimed;
  const _Task({
    required this.title,
    required this.description,
    required this.progress,
    required this.isClaimed,
  });
}

const _kTasks = <_Task>[
  _Task(
    title: 'WEEKEND WARRIOR',
    description: 'Attend 3 parties in one weekend',
    progress: 1.0,
    isClaimed: false,
  ),
  _Task(
    title: 'EARLY BIRD',
    description: 'Check in before 10 PM',
    progress: 1.0,
    isClaimed: true,
  ),
  _Task(
    title: 'SOCIAL BUTTERFLY',
    description: 'Connect with 20 new people',
    progress: 0.7,
    isClaimed: false,
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class BadgeClaimPage extends StatelessWidget {
  const BadgeClaimPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBlack,
        body: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _kWhite.withValues(alpha: 0.65), size: 18),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Gap(12),

                      // ── Mascot with sparkle ring ──────────────────────────
                      _MascotSection(),

                      const Gap(32),

                      // ── YOU UNLOCKED IT! ───────────────────────────────────
                      Text(
                        'YOU UNLOCKED IT!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.anton(
                          color: _kLime,
                          fontSize: AppResponsive.font(context, 40),
                          letterSpacing: 1.5,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: _kLime.withValues(alpha: 0.55),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      const Gap(14),

                      // ── Decorative divider stars ───────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Star(_kLime, 14),
                          const Gap(8),
                          _Star(_kPink, 10),
                          const Gap(8),
                          _Star(_kLime, 18),
                          const Gap(8),
                          _Star(_kPink, 10),
                          const Gap(8),
                          _Star(_kLime, 14),
                        ],
                      ),
                      const Gap(18),

                      // ── Badge name ────────────────────────────────────────
                      Text(
                        'PARTY STARTER BADGE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.anton(
                          color: _kCream,
                          fontSize: AppResponsive.font(context, 26),
                          letterSpacing: 1.2,
                          height: 1.1,
                        ),
                      ),
                      const Gap(10),

                      // Subtitle
                      Text(
                        'You have unlocked new milestones.\nKeep the party going!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kWhite.withValues(alpha: 0.42),
                          fontSize: AppResponsive.font(context, 13),
                          height: 1.5,
                        ),
                      ),

                      const Gap(32),

                      // ── XP chips ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Chip(label: '+500 XP', color: _kLime),
                          const Gap(10),
                          _Chip(label: 'EXCLUSIVE ACCESS', color: _kPink),
                        ],
                      ),

                      const Gap(36),

                      // ── Progress tasks ────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _kLime,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _kLime.withValues(alpha: 0.55),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'PROGRESS',
                            style: GoogleFonts.anton(
                              color: _kCream.withValues(alpha: 0.50),
                              fontSize: 11,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),

                      ..._kTasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskItem(task: task),
                          )),

                      const Gap(24),
                    ],
                  ),
                ),
              ),

              // ── AWESOME CTA ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 20),
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Rewards Claimed!',
                          style: GoogleFonts.anton(
                              color: _kBlack, letterSpacing: 1),
                        ),
                        backgroundColor: _kLime,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: AppResponsive.gap(context, 60).clamp(52.0, 66.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _kLime,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kLime.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'AWESOME',
                      style: GoogleFonts.anton(
                        color: _kBlack,
                        fontSize: AppResponsive.font(context, 22),
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mascot + sparkle decorations ──────────────────────────────────────────────

class _MascotSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                  color: _kLime.withValues(alpha: 0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.10),
                  blurRadius: 48,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),

          // Inner glow ring
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kLime.withValues(alpha: 0.06),
              border: Border.all(
                  color: _kLime.withValues(alpha: 0.22), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Sparkles — positioned around the mascot
          const Positioned(top: 8,   left: 24,  child: _Sparkle('✦', 26, _kLime)),
          const Positioned(top: 2,   right: 36, child: _Sparkle('★', 20, _kPink)),
          const Positioned(top: 32,  right: 14, child: _Sparkle('✶', 16, _kLime)),
          const Positioned(bottom: 22, left: 14, child: _Sparkle('✦', 18, _kPink)),
          const Positioned(bottom: 8,  right: 24, child: _Sparkle('★', 22, _kLime)),
          const Positioned(top: 70,  left: 6,   child: _Sparkle('✶', 12, _kWhite)),
          const Positioned(bottom: 50, right: 6, child: _Sparkle('✦', 14, _kWhite)),
          const Positioned(top: 14,  left: 90,  child: _Sparkle('★', 10, _kPink)),

          // Mascot image — large and centered
          Image.asset(
            'assets/images/logo.png',
            width: 168,
            height: 168,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Text('🎉', style: TextStyle(fontSize: 88)),
          ),
        ],
      ),
    );
  }
}

// ── Sparkle character ─────────────────────────────────────────────────────────

class _Sparkle extends StatelessWidget {
  final String char;
  final double size;
  final Color color;
  const _Sparkle(this.char, this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      char,
      style: TextStyle(
        color: color.withValues(alpha: 0.80),
        fontSize: size,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.50),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

// ── Decorative star shape ─────────────────────────────────────────────────────

class _Star extends StatelessWidget {
  final Color color;
  final double size;
  const _Star(this.color, this.size);

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦',
      style: TextStyle(
        color: color.withValues(alpha: 0.80),
        fontSize: size,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.55), blurRadius: 8),
        ],
      ),
    );
  }
}

// ── Task item ─────────────────────────────────────────────────────────────────

class _TaskItem extends StatelessWidget {
  final _Task task;
  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final isReady = task.progress >= 1.0 && !task.isClaimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isClaimed
              ? _kLime.withValues(alpha: 0.35)
              : isReady
                  ? _kPink.withValues(alpha: 0.35)
                  : _kBorder,
        ),
        boxShadow: task.isClaimed
            ? [BoxShadow(
                color: _kLime.withValues(alpha: 0.08),
                blurRadius: 14,
              )]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.anton(
                    color: _kCream,
                    fontSize: AppResponsive.font(context, 14),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (task.isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('DONE',
                      style: GoogleFonts.anton(
                          color: _kLime, fontSize: 9, letterSpacing: 1.2)),
                )
              else if (isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPink.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('READY',
                      style: GoogleFonts.anton(
                          color: _kPink, fontSize: 9, letterSpacing: 1.2)),
                )
              else
                Text(
                  '${(task.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.40),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const Gap(5),
          Text(
            task.description,
            style: TextStyle(
              color: _kWhite.withValues(alpha: 0.38),
              fontSize: AppResponsive.font(context, 12),
              height: 1.4,
            ),
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation(
                task.isClaimed
                    ? _kLime
                    : isReady
                        ? _kPink
                        : _kLime.withValues(alpha: 0.50),
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reward chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.anton(
          color: color,
          fontSize: AppResponsive.font(context, 11),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
