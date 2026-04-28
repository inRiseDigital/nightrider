// lib/components/home_country_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/home_providers.dart';

String _flag(String code) {
  if (code.length != 2) return '';
  const base = 0x1F1E6 - 0x41;
  return String.fromCharCodes([base + code.codeUnitAt(0), base + code.codeUnitAt(1)]);
}

class HomeCountryFilter extends ConsumerWidget {
  const HomeCountryFilter({super.key});

  static const _fallbackCountries = ['LK', 'JP', 'US', 'GB', 'AU', 'DE', 'FR', 'KR'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(availableCountriesProvider);
    final fetched = async.asData?.value ?? [];
    final countries = fetched.isNotEmpty ? fetched : _fallbackCountries;

    final selected = ref.watch(selectedCountryProvider);

    return SizedBox(
      height: 34.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _Pill(label: AppLocalizations.of(context)!.all, code: 'ALL', selected: selected == 'ALL',
              onTap: () => ref.read(selectedCountryProvider.notifier).state = 'ALL'),
          Gap(8.w),
          ...countries.asMap().entries.map((entry) {
            final code = entry.value;
            final isSelected = selected == code;
            return Padding(
              padding: EdgeInsets.only(right: entry.key < countries.length - 1 ? 8.w : 0),
              child: _Pill(
                label: '${_flag(code)} $code',
                code: code,
                selected: isSelected,
                onTap: () {
                  final next = isSelected ? 'ALL' : code;
                  ref.read(selectedCountryProvider.notifier).state = next;
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.code, required this.selected, required this.onTap});
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.70),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
