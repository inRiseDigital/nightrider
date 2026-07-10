// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/providers/common_search_providers.dart';

import '../data/search_dummy_data.dart';
import '../components/search_app_bar.dart';
import '../components/search_section_header.dart';
import '../components/search_list_item.dart';
import '../components/search_empty_state.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _black      = Color(0xFF070707);
const Color _borderGray = Color(0xFF2A2A2A);
const Color _neonLime  = Color(0xFFDFFF2F);
const Color _hotPink   = Color(0xFFFF3D73);
const Color _teal      = Color(0xFF62D6C8);
const Color _white     = Color(0xFFFAFAFA);
const Color _cream     = Color(0xFFF3EAD6);

// ── Filter pills ─────────────────────────────────────────────────────────────
const List<String> _filterPills = <String>['ALL', 'CLUBS', 'BARS', 'EVENTS'];

// ── Active filter provider (local to this page) ───────────────────────────────
final _activeFilterProvider = StateProvider<String>((ref) => 'ALL');

// ── Category tile model ───────────────────────────────────────────────────────
class _CategoryTile {
  const _CategoryTile({
    required this.label,
    required this.emoji,
    required this.bg,
    required this.textColor,
    required this.filterQuery,
    this.glowColor,
  });
  final String label;
  final String emoji;
  final Color bg;
  final Color textColor;
  final String filterQuery;
  final Color? glowColor;
}

const List<_CategoryTile> _categories = <_CategoryTile>[
  _CategoryTile(
    label: 'TECHNO',
    emoji: '⚡',
    bg: _teal,
    textColor: Color(0xFF070707),
    filterQuery: 'techno',
    glowColor: Color(0x5062D6C8),
  ),
  _CategoryTile(
    label: 'HOUSE',
    emoji: '🎛',
    bg: _neonLime,
    textColor: Color(0xFF070707),
    filterQuery: 'house',
    glowColor: Color(0x50DFFF2F),
  ),
  _CategoryTile(
    label: 'LATIN',
    emoji: '🔥',
    bg: _hotPink,
    textColor: _white,
    filterQuery: 'latin',
    glowColor: Color(0x50FF3D73),
  ),
  _CategoryTile(
    label: 'LIVE MUSIC',
    emoji: '🎸',
    bg: Color(0xFF1C1C1C),
    textColor: _white,
    filterQuery: 'live',
    glowColor: Color(0x30FAFAFA),
  ),
];

// ── Search Page ───────────────────────────────────────────────────────────────
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState     = ref.watch(searchUiStateProvider);
    final results     = ref.watch(searchFilteredProvider);
    final query       = ref.watch(searchQueryProvider).trim();
    final activeFilter = ref.watch(_activeFilterProvider);

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Fixed header block ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── "EXPLORE" heading with accent dot ───────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'EXPLORE',
                        style: GoogleFonts.anton(
                          fontSize: 40.sp,
                          color: _cream,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _neonLime,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _neonLime.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // ── Search bar ──────────────────────────────────────────
                  const SearchAppBarRow(hintText: kSearchHint),
                  SizedBox(height: 14.h),

                  // ── Filter pills ────────────────────────────────────────
                  SizedBox(
                    height: 36.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterPills.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (BuildContext ctx, int i) {
                        final String pill = _filterPills[i];
                        final bool isActive = activeFilter == pill;
                        return _FilterPill(
                          label: pill,
                          isActive: isActive,
                          onTap: () {
                            ref.read(_activeFilterProvider.notifier).state = pill;
                            if (pill == 'ALL') {
                              ref.read(searchQueryProvider.notifier).state = '';
                            } else {
                              ref.read(searchQueryProvider.notifier).state =
                                  pill.toLowerCase();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ── Section header ──────────────────────────────────────
                  SearchSectionHeader(
                    text: _resolveHeaderText(uiState, results.length),
                  ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),

            // ── Scrollable content area ───────────────────────────────────
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  // Empty state
                  if (uiState == SearchUiState.empty) {
                    return SearchEmptyState(
                      query: query,
                      onClear: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(_activeFilterProvider.notifier).state = 'ALL';
                      },
                    );
                  }

                  // Idle — 2x2 category grid
                  if (uiState == SearchUiState.idle) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _CategoryGrid(
                        onCategoryTap: (String filterQuery) {
                          ref.read(searchQueryProvider.notifier).state =
                              filterQuery;
                        },
                      ),
                    );
                  }

                  // Results list
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (BuildContext context, int index) {
                      final item = results[index];
                      return SearchListItem(
                        item: item,
                        onTap: () {},
                        showDivider: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveHeaderText(SearchUiState uiState, int count) {
    switch (uiState) {
      case SearchUiState.idle:
        return 'BROWSE VIBES';
      case SearchUiState.results:
        return 'RESULTS ($count)';
      case SearchUiState.empty:
        return 'NO RESULTS';
    }
  }
}

// ── Filter pill widget ────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isActive ? _neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: isActive ? _neonLime : _borderGray,
            width: 1.5,
          ),
          boxShadow: isActive
              ? <BoxShadow>[
                  BoxShadow(
                    color: _neonLime.withValues(alpha: 0.30),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: GoogleFonts.anton(
            fontSize: 12.sp,
            color: isActive ? _black : _white.withValues(alpha: 0.75),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── 2x2 Category grid ─────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onCategoryTap});
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        mainAxisExtent: 128.h,
      ),
      itemCount: _categories.length,
      itemBuilder: (BuildContext context, int index) {
        final tile = _categories[index];
        return _CategoryTileWidget(
          tile: tile,
          onTap: () => onCategoryTap(tile.filterQuery),
        );
      },
    );
  }
}

// ── Category tile widget ──────────────────────────────────────────────────────
class _CategoryTileWidget extends StatefulWidget {
  const _CategoryTileWidget({required this.tile, required this.onTap});
  final _CategoryTile tile;
  final VoidCallback onTap;

  @override
  State<_CategoryTileWidget> createState() => _CategoryTileWidgetState();
}

class _CategoryTileWidgetState extends State<_CategoryTileWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: tile.bg,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: tile.glowColor != null
                ? <BoxShadow>[
                    BoxShadow(
                      color: tile.glowColor!,
                      blurRadius: 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Emoji in a subtle circle
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  tile.emoji,
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),

              // Label
              Text(
                tile.label,
                style: GoogleFonts.anton(
                  fontSize: 18.sp,
                  color: tile.textColor,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
