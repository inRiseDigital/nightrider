// lib/pages/onboard_questionnaire_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Palette ───────────────────────────────────────────────────────────────────

const _kBlack    = Color(0xFF070707);
const _kDarkCard = Color(0xFF151515);
const _kBorder   = Color(0xFF333333);
const _kCream    = Color(0xFFF3EAD6);
const _kNeonLime = Color(0xFFDFFF2F);
const _kHotPink  = Color(0xFFFF3D73);
const _kGray     = Color(0xFF666666);

// ── Step data ─────────────────────────────────────────────────────────────────

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

const List<OnboardStepData> kOnboardSteps = <OnboardStepData>[
  OnboardStepData(
    title: 'Select your age',
    subtitle: 'This helps us personalize nightlife recommendations.',
    options: <String>[
      '18-20', '21-24', '25-30', '31-40', '40+',
      'Student', 'Working', 'Traveler',
    ],
    minSelect: 1,
    preselected: <String>{'21-24'},
  ),
  OnboardStepData(
    title: 'Choose your music taste.',
    subtitle: 'Select at least 3 genres to personalize your nightlife discovery.',
    options: <String>[
      'Dj', 'EDM', 'Techno', 'Hip-Hop', 'J-Pop', 'Jazz', 'House',
      'Trance', 'Drum & Bass', 'Afrobeat', 'Indie', 'K-Pop',
      'Reggaeton', 'Rock', 'R&B', 'Pop',
    ],
    minSelect: 3,
    preselected: <String>{'EDM'},
  ),
  OnboardStepData(
    title: "What's your vibe?",
    subtitle: 'Pick at least 2 so we can match the right events.',
    options: <String>[
      'Chill', 'Luxury', 'Underground', 'Party', 'Casual', 'Wild',
      'Romantic', 'High Energy', 'Outdoor', 'Late-night', 'Cozy', 'Social',
    ],
    minSelect: 2,
    preselected: <String>{'Chill'},
  ),
  OnboardStepData(
    title: 'Special Features You Love?',
    subtitle: 'Select at least 2 features you enjoy most.',
    options: <String>[
      'Live DJ', 'Dance Floor', 'Rooftop', 'VIP', 'Food', 'Cocktails',
      'Live Band', 'Neon Lights', 'Photo Booth', 'After Party', 'Games', 'Pool View',
    ],
    minSelect: 2,
    preselected: <String>{'Live DJ'},
  ),
  OnboardStepData(
    title: 'Best Time to Go Out?',
    subtitle: 'Choose what suits you best.',
    options: <String>[
      'Evening', 'Late Night', 'After Midnight',
      'Weekend Only', 'Weekdays', 'Anytime',
    ],
    minSelect: 1,
    preselected: <String>{'Late Night'},
  ),
  OnboardStepData(
    title: "What's your spending limit?",
    subtitle: 'Pick a range that feels comfortable.',
    options: <String>[
      'Free', '\$ - Budget', '\$\$ - Mid', '\$\$\$ - Premium', 'VIP Only', 'Deals Only',
    ],
    minSelect: 1,
    preselected: <String>{'\$\$ - Mid'},
  ),
];

const int kTotalSteps = 6;

// ── Riverpod state ────────────────────────────────────────────────────────────

@immutable
class OnboardQuestionnaireState {
  const OnboardQuestionnaireState({
    required this.stepIndex,
    required this.selectionsByStep,
  });

  final int stepIndex;
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

final onboardQuestionnaireFlowProvider =
    NotifierProvider<OnboardQuestionnaireFlowNotifier, OnboardQuestionnaireState>(
  OnboardQuestionnaireFlowNotifier.new,
);

class OnboardQuestionnaireFlowNotifier
    extends Notifier<OnboardQuestionnaireState> {
  @override
  OnboardQuestionnaireState build() {
    final Map<int, Set<String>> initial = {};
    for (int i = 0; i < kOnboardSteps.length; i++) {
      initial[i] = {...kOnboardSteps[i].preselected};
    }
    return OnboardQuestionnaireState(stepIndex: 0, selectionsByStep: initial);
  }

  OnboardStepData get currentStep => kOnboardSteps[state.stepIndex];
  Set<String>     get currentSelection => state.selectionsByStep[state.stepIndex] ?? {};
  bool            get canContinue => currentSelection.length >= currentStep.minSelect;

  void toggleOption(String option) {
    final map  = {...state.selectionsByStep};
    final next = {...(map[state.stepIndex] ?? <String>{})};

    if (currentStep.minSelect == 1) {
      next..clear()..add(option);
    } else {
      next.contains(option) ? next.remove(option) : next.add(option);
    }
    map[state.stepIndex] = next;
    state = state.copyWith(selectionsByStep: map);
  }

  void nextStep()     { if (state.stepIndex < kOnboardSteps.length - 1) state = state.copyWith(stepIndex: state.stepIndex + 1); }
  void previousStep() { if (state.stepIndex > 0) state = state.copyWith(stepIndex: state.stepIndex - 1); }
  void skipStep()     => nextStep();

  Future<void> completeOnboarding(BuildContext context) async {
    final sel = state.selectionsByStep;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserProfileService(FirebaseFirestore.instance).saveOnboardingAnswers(
        uid:       uid,
        ageRange:  (sel[0] ?? {}).firstOrNull ?? '',
        genres:    (sel[1] ?? {}).toList(),
        vibes:     (sel[2] ?? {}).toList(),
        features:  (sel[3] ?? {}).toList(),
        goOutTime: (sel[4] ?? {}).firstOrNull ?? '',
        budget:    (sel[5] ?? {}).firstOrNull ?? '',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('ob_ageRange',  (sel[0] ?? {}).firstOrNull ?? '');
    await prefs.setString('ob_genres',    (sel[1] ?? {}).join(','));
    await prefs.setString('ob_vibes',     (sel[2] ?? {}).join(','));
    await prefs.setString('ob_features',  (sel[3] ?? {}).join(','));
    await prefs.setString('ob_goOutTime', (sel[4] ?? {}).firstOrNull ?? '');
    await prefs.setString('ob_budget',    (sel[5] ?? {}).firstOrNull ?? '');

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppShellPage()),
        (route) => false,
      );
    }
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class OnboardQuestionnaireTemplatePage extends ConsumerWidget {
  const OnboardQuestionnaireTemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s        = ref.watch(onboardQuestionnaireFlowProvider);
    final step     = kOnboardSteps[s.stepIndex];
    final selected = s.selectionsByStep[s.stepIndex] ?? {};
    final enabled  = selected.length >= step.minSelect;

    return Scaffold(
      backgroundColor: _kBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: logo + brand + step indicators ─────────────────────
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: AppResponsive.font(context, 32).clamp(26.0, 36.0),
                    height: AppResponsive.font(context, 32).clamp(26.0, 36.0),
                    fit: BoxFit.contain,
                  ),
                  const Gap(10),
                  Text(
                    'NIGHTRIDE',
                    style: GoogleFonts.anton(
                      color: _kCream,
                      fontSize: AppResponsive.font(context, 17).clamp(14.0, 20.0),
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  _StepDots(total: kTotalSteps, active: s.stepIndex),
                ],
              ),

              const Gap(12),

              // ── Step counter label ─────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'STEP',
                    style: GoogleFonts.anton(color: _kGray, fontSize: 11, letterSpacing: 2),
                  ),
                  const Gap(6),
                  Text(
                    '${s.stepIndex + 1}',
                    style: GoogleFonts.anton(color: _kNeonLime, fontSize: 13, letterSpacing: 1),
                  ),
                  Text(
                    ' / $kTotalSteps',
                    style: GoogleFonts.anton(color: _kGray, fontSize: 11, letterSpacing: 1),
                  ),
                ],
              ),

              const Gap(28),

              // ── Animated step body ─────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.04, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _StepBody(
                  key: ValueKey<int>(s.stepIndex),
                  title: step.title,
                  subtitle: step.subtitle,
                  options: step.options,
                  selected: selected,
                  onTap: (v) => ref.read(onboardQuestionnaireFlowProvider.notifier).toggleOption(v),
                ),
              ),

              const Spacer(),

              // ── Navigation buttons ─────────────────────────────────────────
              Row(
                children: [
                  if (s.stepIndex > 0) ...[
                    _BackButton(
                      onTap: () => ref.read(onboardQuestionnaireFlowProvider.notifier).previousStep(),
                    ),
                    const Gap(12),
                  ],
                  Expanded(
                    child: _NextButton(
                      label: s.stepIndex == kTotalSteps - 1 ? 'FINISH' : 'NEXT',
                      enabled: enabled,
                      onTap: enabled
                          ? () {
                              if (s.stepIndex == kTotalSteps - 1) {
                                ref.read(onboardQuestionnaireFlowProvider.notifier).completeOnboarding(context);
                              } else {
                                ref.read(onboardQuestionnaireFlowProvider.notifier).nextStep();
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),

              const Gap(16),

              // ── Skip ───────────────────────────────────────────────────────
              if (s.stepIndex != kTotalSteps - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => ref.read(onboardQuestionnaireFlowProvider.notifier).skipStep(),
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text(
                        'skip',
                        style: TextStyle(
                          color: _kGray,
                          fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

              const Gap(4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step body ─────────────────────────────────────────────────────────────────

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
      children: [
        Text(
          title,
          style: GoogleFonts.anton(
            color: _kCream,
            fontSize: AppResponsive.font(context, 24).clamp(20.0, 28.0),
            letterSpacing: 0.5,
            height: 1.15,
          ),
        ),
        const Gap(10),
        Text(
          subtitle,
          style: TextStyle(
            color: _kGray,
            fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5),
            height: 1.4,
          ),
        ),
        const Gap(28),
        _OptionsWrap(options: options, selected: selected, onTap: onTap),
      ],
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.active});
  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
          width: isActive ? 28 : 8,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? _kNeonLime : _kBorder,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [BoxShadow(color: _kNeonLime.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        );
      }),
    );
  }
}

// ── Options wrap ──────────────────────────────────────────────────────────────

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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((label) {
        return _OptionChip(
          label: label,
          selected: selected.contains(label),
          onTap: () => onTap(label),
        );
      }).toList(),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kNeonLime.withValues(alpha: 0.12) : _kDarkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kNeonLime : _kBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _kNeonLime.withValues(alpha: 0.18), blurRadius: 12, spreadRadius: 0)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.anton(
            color: selected ? _kNeonLime : const Color(0xFF888888),
            fontSize: AppResponsive.font(context, 13).clamp(11.5, 14.5),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? _kNeonLime : _kDarkCard,
            borderRadius: BorderRadius.circular(14),
            border: enabled ? null : Border.all(color: _kBorder),
            boxShadow: enabled
                ? [BoxShadow(color: _kNeonLime.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.anton(
              color: enabled ? _kBlack : _kGray,
              fontSize: AppResponsive.font(context, 16).clamp(14.0, 18.0),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          'BACK',
          style: GoogleFonts.anton(
            color: _kCream,
            fontSize: AppResponsive.font(context, 14).clamp(12.0, 16.0),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
