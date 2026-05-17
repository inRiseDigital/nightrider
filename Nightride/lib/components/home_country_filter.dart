// lib/components/home_country_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/home_providers.dart';

String _flag(String code) {
  if (code.length != 2) return '🌍';
  const base = 0x1F1E6 - 0x41;
  return String.fromCharCodes(
      [base + code.codeUnitAt(0), base + code.codeUnitAt(1)]);
}

const _kNames = <String, String>{
  'LK': 'Sri Lanka',   'JP': 'Japan',       'US': 'USA',
  'GB': 'UK',          'DE': 'Germany',     'FR': 'France',
  'ES': 'Spain',       'AU': 'Australia',   'SG': 'Singapore',
  'KR': 'S. Korea',    'BR': 'Brazil',      'AE': 'UAE',
  'TH': 'Thailand',    'NL': 'Netherlands', 'IN': 'India',
  'CA': 'Canada',      'MX': 'Mexico',      'IT': 'Italy',
  'SE': 'Sweden',      'NZ': 'N. Zealand',  'BE': 'Belgium',
  'PT': 'Portugal',    'AR': 'Argentina',   'ZA': 'S. Africa',
  'SA': 'S. Arabia',
};

String _name(String code) => _kNames[code] ?? code;

// One background color per country for the tile
const _kColor = <String, Color>{
  'LK': Color(0xFF8B1A1A), 'JP': Color(0xFF991B1B), 'US': Color(0xFF1E3A8A),
  'GB': Color(0xFF1E3A5F), 'DE': Color(0xFF1C1C1C), 'FR': Color(0xFF1E3A8A),
  'ES': Color(0xFF92400E), 'AU': Color(0xFF78350F), 'SG': Color(0xFF7F1D1D),
  'KR': Color(0xFF1E3A8A), 'BR': Color(0xFF14532D), 'AE': Color(0xFF14532D),
  'TH': Color(0xFF1E3A8A), 'NL': Color(0xFF7F1D1D), 'IN': Color(0xFF78350F),
  'CA': Color(0xFF7F1D1D), 'MX': Color(0xFF14532D), 'IT': Color(0xFF14532D),
};

Color _colorFor(String code) => _kColor[code] ?? const Color(0xFF1E1E2E);

class HomeCountryFilter extends ConsumerWidget {
  const HomeCountryFilter({super.key});

  static const _fallback = ['LK', 'JP', 'US', 'GB', 'AU', 'DE', 'FR', 'KR'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetched = ref.watch(availableCountriesProvider).asData?.value ?? [];
    final countries = fetched.isNotEmpty ? fetched : _fallback;
    final selected = ref.watch(selectedCountryProvider);

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        itemCount: countries.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _CountryTile(
              flag: '🌍',
              label: AppLocalizations.of(context)!.all,
              isSelected: selected == 'ALL',
              bgColor: const Color(0xFF312E81),
              onTap: () =>
                  ref.read(selectedCountryProvider.notifier).state = 'ALL',
            );
          }
          final code = countries[i - 1];
          final isSel = selected == code;
          return _CountryTile(
            flag: _flag(code),
            label: _name(code),
            isSelected: isSel,
            bgColor: _colorFor(code),
            onTap: () => ref.read(selectedCountryProvider.notifier).state =
                isSel ? 'ALL' : code,
          );
        },
      ),
    );
  }
}

// ── Country tile ──────────────────────────────────────────────────────────────

class _CountryTile extends StatefulWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final Color bgColor;
  final VoidCallback onTap;

  const _CountryTile({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_CountryTile> createState() => _CountryTileState();
}

class _CountryTileState extends State<_CountryTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.label.length > 9
        ? '${widget.label.substring(0, 8)}…'
        : widget.label;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _down = true),
      onTapUp:     (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : (widget.isSelected ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 78,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.bgColor
                : widget.bgColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.07),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.bgColor.withValues(alpha: 0.6),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.flag,
                style: TextStyle(
                  fontSize: widget.isSelected ? 26 : 23,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: AppResponsive.font(context, 9.5),
                    fontWeight: widget.isSelected
                        ? FontWeight.w800
                        : FontWeight.w500,
                    letterSpacing: 0.1,
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
