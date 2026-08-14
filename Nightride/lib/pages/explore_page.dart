// lib/pages/explore_page.dart
//
// "VIEW ALL" destination for the Home tab's EXPLORE section — a full grid
// of genre/category tiles, each opening CategoryDetailPage. Distinct from
// EventsGridPage (which groups trending events by category); this page is
// about browsing categories themselves.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/category_detail_page.dart';

class _ExploreCat {
  final String label;
  final String category;
  final IconData icon;
  final Color bg;
  const _ExploreCat(this.label, this.category, this.icon, this.bg);
}

const _kExploreCats = <_ExploreCat>[
  _ExploreCat('TECHNO',     'TECHNO', Icons.language,                AppTheme.teal),
  _ExploreCat('HOUSE',      'HOUSE',  Icons.sentiment_satisfied_alt, AppTheme.neonLime),
  _ExploreCat('LATIN',      'EDM',    Icons.park,                    AppTheme.teal),
  _ExploreCat('LIVE MUSIC', 'LIVE',   Icons.bolt,                    AppTheme.hotPink),
  _ExploreCat('CLUBS',      'CLUB',   Icons.nightlife_rounded,       AppTheme.hotPink),
  _ExploreCat('DJ SETS',    'DJ',     Icons.headphones_rounded,      AppTheme.hotPink),
  _ExploreCat('RAVE',       'RAVE',   Icons.blur_on_rounded,         AppTheme.teal),
  _ExploreCat('EDM',        'EDM',    Icons.bolt_rounded,            AppTheme.neonLime),
];

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? _kExploreCats
        : _kExploreCats
            .where((c) => c.label.toLowerCase().contains(_query))
            .toList();

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
          'EXPLORE',
          style: GoogleFonts.anton(
            color: AppTheme.cream,
            fontSize: AppResponsive.font(context, 20).clamp(16.0, 24.0),
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _ExploreSearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'NO MATCHES',
                      style: GoogleFonts.anton(
                        color: AppTheme.cream.withValues(alpha: 0.4),
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) =>
                        _ExploreGridTile(cat: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _ExploreSearchBar extends StatelessWidget {
  const _ExploreSearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: AppTheme.cream, fontSize: 14),
        cursorColor: AppTheme.neonLime,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search categories',
          hintStyle: TextStyle(color: AppTheme.cream.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.cream.withValues(alpha: 0.5), size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ExploreGridTile extends StatefulWidget {
  const _ExploreGridTile({required this.cat});
  final _ExploreCat cat;

  @override
  State<_ExploreGridTile> createState() => _ExploreGridTileState();
}

class _ExploreGridTileState extends State<_ExploreGridTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    const fg = Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CategoryDetailPage(category: cat.category),
        ));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: cat.bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cat.bg.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, color: fg, size: 30),
              const SizedBox(height: 10),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: 13,
                  color: fg,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
