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

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

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
          'EXPLORE',
          style: GoogleFonts.anton(
            color: AppTheme.cream,
            fontSize: AppResponsive.font(context, 20).clamp(16.0, 24.0),
            letterSpacing: 2,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: _kExploreCats.length,
        itemBuilder: (context, i) => _ExploreGridTile(cat: _kExploreCats[i]),
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
