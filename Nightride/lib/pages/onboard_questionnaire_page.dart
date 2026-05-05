// lib/features/onboarding/presentation/pages/onboard_questionnaire_template.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DUMMY DATA (define before UI code — no mixing)
/// ─────────────────────────────────────────────────────────────────────────────

@immutable
class OnboardStepData {
  const OnboardStepData({
    required this.title,
    required this.subtitle,
    required this.options,
    this.minSelect = 1,
    this.preselected = const <String>{},
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final int minSelect;
  final Set<String> preselected;
}

/// ✅ 6 steps (more chips)
const List<OnboardStepData> kOnboardSteps = <OnboardStepData>[
  OnboardStepData(
    title: 'Select your age',
    subtitle: 'This helps us personalize nightlife recommendations.',
    options: <String>[
      '18-20',
      '21-24',
      '25-30',
      '31-40',
      '40+',
      'Student',
      'Working',
      'Traveler',
    ],
    minSelect: 1,
    preselected: <String>{'21-24'},
  ),
  OnboardStepData(
    title: 'Choose the type of music taste.',
    subtitle:
        'Select at least 3 genres to personalize your nightlife\ndiscovery.',
    options: <String>[
      'Dj',
      'EDM',
      'Techno',
      'Hip-Hop',
      'J-Pop',
      'Jazz',
      'House',
      'Trance',
      'Drum & Bass',
      'Afrobeat',
      'Indie',
      'K-Pop',
      'Reggaeton',
      'Rock',
      'R&B',
      'Pop',
    ],
    minSelect: 3,
    preselected: <String>{'EDM'},
  ),
  OnboardStepData(
    title: 'What’s your vibe?',
    subtitle: 'Pick at least 2 so we can match the right events.',
    options: <String>[
      'Chill',
      'Luxury',
      'Underground',
      'Party',
      'Casual',
      'Wild',
      'Romantic',
      'High Energy',
      'Outdoor',
      'Late-night',
      'Cozy',
      'Social',
    ],
    minSelect: 2,
    preselected: <String>{'Chill'},
  ),
  OnboardStepData(
    title: 'Special Features You Love?',
    subtitle: 'Select at least 2 features you enjoy most.',
    options: <String>[
      'Live DJ',
      'Dance Floor',
      'Rooftop',
      'VIP',
      'Food',
      'Cocktails',
      'Live Band',
      'Neon Lights',
      'Photo Booth',
      'After Party',
      'Games',
      'Pool View',
    ],
    minSelect: 2,
    preselected: <String>{'Live DJ'},
  ),
  OnboardStepData(
    title: 'Best Time to Go Out?',
    subtitle: 'Choose what suits you best.',
    options: <String>[
      'Evening',
      'Late Night',
      'After Midnight',
      'Weekend Only',
      'Weekdays',
      'Anytime',
    ],
    minSelect: 1,
    preselected: <String>{'Late Night'},
  ),
  OnboardStepData(
    title: "What's your spending limit?",
    subtitle: 'Pick a range that feels comfortable.',
    options: <String>[
      'Free',
      '\$ - Budget',
      '\$\$ - Mid',
      '\$\$\$ - Premium',
      'VIP Only',
      'Deals Only',
    ],
    minSelect: 1,
    preselected: <String>{'\$\$ - Mid'},
  ),
];

const String kBrandName = 'Nightride';
const int kTotalSteps = 6;

/// ─────────────────────────────────────────────────────────────────────────────
/// STATE (Riverpod NotifierProvider)
/// ─────────────────────────────────────────────────────────────────────────────

@immutable
class OnboardQuestionnaireState {
  const OnboardQuestionnaireState({
    required this.stepIndex,
    required this.selectionsByStep,
  });

  final int stepIndex; // 0..5
  final Map<int, Set<String>> selectionsByStep;

  OnboardQuestionnaireState copyWith({
    int? stepIndex,
    Map<int, Set<String>>? selectionsByStep,
  }) {
    return OnboardQuestionnaireState(
      stepIndex: stepIndex ?? this.stepIndex,
      selectionsByStep: selectionsByStep ?? this.selectionsByStep,
    );
  }
}

final onboardQuestionnaireFlowProvider = NotifierProvider<
  OnboardQuestionnaireFlowNotifier,
  OnboardQuestionnaireState
>(OnboardQuestionnaireFlowNotifier.new);

class OnboardQuestionnaireFlowNotifier
    extends Notifier<OnboardQuestionnaireState> {
  @override
  OnboardQuestionnaireState build() {
    final Map<int, Set<String>> initial = <int, Set<String>>{};
    for (int i = 0; i < kOnboardSteps.length; i++) {
      initial[i] = <String>{...kOnboardSteps[i].preselected};
    }
    return OnboardQuestionnaireState(stepIndex: 0, selectionsByStep: initial);
  }

  OnboardStepData get currentStep => kOnboardSteps[state.stepIndex];
  Set<String> get currentSelection =>
      state.selectionsByStep[state.stepIndex] ?? <String>{};

  bool get canContinue => currentSelection.length >= currentStep.minSelect;

  void toggleOption(String option) {
    final Map<int, Set<String>> map = <int, Set<String>>{
      ...state.selectionsByStep,
    };
    final Set<String> next = <String>{...(map[state.stepIndex] ?? <String>{})};

    if (currentStep.minSelect == 1) {
      next
        ..clear()
        ..add(option);
    } else {
      if (next.contains(option)) {
        next.remove(option);
      } else {
        next.add(option);
      }
    }

    map[state.stepIndex] = next;
    state = state.copyWith(selectionsByStep: map);
  }

  void nextStep() {
    if (state.stepIndex >= kOnboardSteps.length - 1) return;
    state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  void previousStep() {
    if (state.stepIndex <= 0) return;
    state = state.copyWith(stepIndex: state.stepIndex - 1);
  }

  void skipStep() => nextStep();

  Future<void> completeOnboarding(BuildContext context) async {
    final sel = state.selectionsByStep;

    // Save to Firestore if a user is already signed in
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserProfileService(FirebaseFirestore.instance).saveOnboardingAnswers(
        uid: uid,
        ageRange: (sel[0] ?? {}).firstOrNull ?? '',
        genres: (sel[1] ?? {}).toList(),
        vibes: (sel[2] ?? {}).toList(),
        features: (sel[3] ?? {}).toList(),
        goOutTime: (sel[4] ?? {}).firstOrNull ?? '',
        budget: (sel[5] ?? {}).firstOrNull ?? '',
      );
    }

    // Always persist locally so splash doesn't re-show onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Store answers in prefs too so they can be saved after sign-up
    await prefs.setString('ob_ageRange', (sel[0] ?? {}).firstOrNull ?? '');
    await prefs.setString('ob_genres',   (sel[1] ?? {}).join(','));
    await prefs.setString('ob_vibes',    (sel[2] ?? {}).join(','));
    await prefs.setString('ob_features', (sel[3] ?? {}).join(','));
    await prefs.setString('ob_goOutTime',(sel[4] ?? {}).firstOrNull ?? '');
    await prefs.setString('ob_budget',   (sel[5] ?? {}).firstOrNull ?? '');

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppShellPage()),
        (route) => false,
      );
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// PAGE (subtle elegant animations)
/// ─────────────────────────────────────────────────────────────────────────────

class OnboardQuestionnaireTemplatePage extends ConsumerStatefulWidget {
  const OnboardQuestionnaireTemplatePage({super.key});

  @override
  ConsumerState<OnboardQuestionnaireTemplatePage> createState() =>
      _OnboardQuestionnaireTemplatePageState();
}

class _OnboardQuestionnaireTemplatePageState
    extends ConsumerState<OnboardQuestionnaireTemplatePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OnboardQuestionnaireState s = ref.watch(
      onboardQuestionnaireFlowProvider,
    );
    final OnboardStepData step = kOnboardSteps[s.stepIndex];
    final Set<String> selected = s.selectionsByStep[s.stepIndex] ?? <String>{};
    final bool enabled = selected.length >= step.minSelect;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            final double t = _glowController.value;
            final double dy = math.sin(t * math.pi) * 0.10; // gentle breathing
            final double glow = 0.18 + (0.10 * t);

            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF0A0712),
                    Color(0xFF120A20),
                    Color(0xFF0A0712),
                  ],
                ),
              ),
              child: Stack(
                children: <Widget>[
                  _PurpleGlowBackdropAnimated(
                    centerY: -0.55 + dy,
                    intensity: glow,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _HeaderRow(
                          activeIndex: s.stepIndex + 1,
                          total: kTotalSteps,
                        ),
                        Gap(44.h),

                        /// ✅ Elegant step transition (fade + slide)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 360),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) {
                            final Animation<Offset> slide = Tween<Offset>(
                              begin: const Offset(0.03, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              ),
                            );
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: _StepBody(
                            key: ValueKey<int>(s.stepIndex),
                            title: step.title,
                            subtitle: step.subtitle,
                            options: step.options,
                            selected: selected,
                            onTap:
                                (String v) => ref
                                    .read(
                                      onboardQuestionnaireFlowProvider.notifier,
                                    )
                                    .toggleOption(v),
                          ),
                        ),

                        const Spacer(),

                        // Previous + Next/Finish row
                        Row(
                          children: [
                            if (s.stepIndex > 0) ...[
                              _GhostButton(
                                label: 'Back',
                                onTap: () => ref
                                    .read(onboardQuestionnaireFlowProvider.notifier)
                                    .previousStep(),
                              ),
                              SizedBox(width: 12.w),
                            ],
                            Expanded(
                              child: _PrimaryButtonBreathing(
                                label: s.stepIndex == kTotalSteps - 1 ? 'Finish' : 'Next',
                                enabled: enabled,
                                breathe: enabled,
                                onTap: enabled
                                    ? () {
                                        if (s.stepIndex == kTotalSteps - 1) {
                                          ref
                                              .read(onboardQuestionnaireFlowProvider.notifier)
                                              .completeOnboarding(context);
                                        } else {
                                          ref
                                              .read(onboardQuestionnaireFlowProvider.notifier)
                                              .nextStep();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        Gap(18.h),

                        // Skip — hidden on last step
                        if (s.stepIndex != kTotalSteps - 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(onboardQuestionnaireFlowProvider.notifier)
                                  .skipStep(),
                              behavior: HitTestBehavior.translucent,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                                child: Text(
                                  'skip',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Gap(6.h),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// STEP BODY (kept separate so AnimatedSwitcher is clean)
/// ─────────────────────────────────────────────────────────────────────────────

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        Gap(14.h),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13.2.sp,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        Gap(34.h),
        _OptionsWrap(options: options, selected: selected, onTap: onTap),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// BACKDROP GLOW (animated)
/// ─────────────────────────────────────────────────────────────────────────────

class _PurpleGlowBackdropAnimated extends StatelessWidget {
  const _PurpleGlowBackdropAnimated({
    required this.centerY,
    required this.intensity,
  });

  final double centerY;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, centerY),
              radius: 1.18,
              colors: <Color>[
                AppTheme.primary.withValues(alpha: intensity),
                const Color(0x00000000),
              ],
              stops: const <double>[0.0, 1.0],
            ),
          ),
          child: const SizedBox(),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HEADER (brand + pink indicator)
/// ─────────────────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.activeIndex, required this.total});

  final int activeIndex; // 1..total
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const _BrandMark(),
        Gap(10.w),
        Text(
          kBrandName,
          style: GoogleFonts.orbitron(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        _ProgressSegments(total: total, activeIndex: activeIndex),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.total, required this.activeIndex});

  final int total;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(total, (int i) {
        final bool active = (i + 1) == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 6.w),
          width: active ? 34.w : 28.w,
          height: 5.h,
          decoration: BoxDecoration(
            color:
                active
                    ? AppTheme.accent
                    : AppTheme.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999.r),
          ),
        );
      }),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// OPTIONS WRAP (chips) – adds subtle pop on select
/// ─────────────────────────────────────────────────────────────────────────────

class _OptionsWrap extends StatelessWidget {
  const _OptionsWrap({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10.w,
        runSpacing: 12.h,
        children:
            options.map((String label) {
              final bool isSelected = selected.contains(label);
              return _OptionChip(
                label: label,
                selected: isSelected,
                onTap: () => onTap(label),
              );
            }).toList(),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          scale: selected ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color:
                  selected
                      ? AppTheme.primary.withValues(alpha: 0.35)
                      : AppTheme.surface.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    selected
                        ? AppTheme.primaryLight.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow:
                  selected
                      ? <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                          blurRadius: 18.r,
                          offset: Offset(0, 10.h),
                        ),
                      ]
                      : const <BoxShadow>[],
            ),
            child: Text(
              label,
              style: TextStyle(
                color:
                    selected
                        ? Colors.white.withValues(alpha: 0.95)
                        : AppTheme.primaryLight.withValues(alpha: 0.92),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// BUTTON (subtle breathing when enabled)
/// ─────────────────────────────────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.70),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButtonBreathing extends StatefulWidget {
  const _PrimaryButtonBreathing({
    required this.label,
    required this.enabled,
    required this.breathe,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool breathe;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButtonBreathing> createState() =>
      _PrimaryButtonBreathingState();
}

class _PrimaryButtonBreathingState extends State<_PrimaryButtonBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.breathe) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PrimaryButtonBreathing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.breathe && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.breathe && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58.h,
      width: double.infinity,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.enabled ? 1.0 : 0.55,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double t = widget.breathe ? _c.value : 0.0;
            final double glow = 0.12 + (0.10 * t);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                boxShadow:
                    widget.enabled
                        ? <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: glow),
                            blurRadius: 26.r,
                            offset: Offset(0, 14.h),
                          ),
                        ]
                        : const <BoxShadow>[],
              ),
              child: ElevatedButton(
                onPressed: widget.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white.withValues(alpha: 0.92),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
