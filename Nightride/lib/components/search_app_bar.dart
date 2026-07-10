// lib/components/search_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/providers/common_search_providers.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _darkGray   = Color(0xFF151515);
const Color _borderGray = Color(0xFF2A2A2A);
const Color _neonLime   = Color(0xFFDFFF2F);
const Color _white      = Color(0xFFFAFAFA);

class SearchAppBarRow extends ConsumerStatefulWidget {
  const SearchAppBarRow({super.key, required this.hintText});
  final String hintText;

  @override
  ConsumerState<SearchAppBarRow> createState() => _SearchAppBarRowState();
}

class _SearchAppBarRowState extends ConsumerState<SearchAppBarRow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
    _focusNode.addListener(() {
      ref.read(searchBarFocusedProvider.notifier).state = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String v) => ref.read(searchQueryProvider.notifier).state = v;

  void _clear() {
    _controller.clear();
    _setQuery('');
    FocusScope.of(context).unfocus();
  }

  static const InputBorder _noBorder = InputBorder.none;

  @override
  Widget build(BuildContext context) {
    final String query  = ref.watch(searchQueryProvider);
    final bool focused  = ref.watch(searchBarFocusedProvider);

    // Keep controller in sync with external state changes (e.g. filter pills)
    if (_controller.text != query) {
      _controller.value = _controller.value.copyWith(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
        composing: TextRange.empty,
      );
    }

    final bool glowOn     = focused || query.isNotEmpty;
    final Color borderCol = glowOn
        ? _neonLime.withValues(alpha: 0.60)
        : _borderGray;

    final List<BoxShadow> glowShadows = glowOn
        ? <BoxShadow>[
            BoxShadow(
              color: _neonLime.withValues(alpha: 0.20),
              blurRadius: 20,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: _neonLime.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[];

    final double barHeight    = AppResponsive.gap(context, 50).clamp(46.0, 56.0);
    final double inputFont    = AppResponsive.font(context, 14).clamp(12.5, 15.0);
    final double hintFont     = AppResponsive.font(context, 13.5).clamp(12.0, 14.5);
    final double iconSize     = AppResponsive.icon(context, 20).clamp(17.0, 22.0);
    final double clearBtnSize = AppResponsive.gap(context, 28).clamp(24.0, 32.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: barHeight,
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.gap(context, 14).clamp(10.0, 16.0),
      ),
      decoration: BoxDecoration(
        color: _darkGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: glowShadows,
      ),
      child: Row(
        children: <Widget>[
          // ── Magnifier icon ───────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey<bool>(glowOn),
              size: iconSize,
              color: glowOn ? _neonLime : _neonLime.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(width: 10),

          // ── Text field ───────────────────────────────────────────────────
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                inputDecorationTheme: const InputDecorationTheme(
                  border: _noBorder,
                  enabledBorder: _noBorder,
                  focusedBorder: _noBorder,
                  disabledBorder: _noBorder,
                  errorBorder: _noBorder,
                  focusedErrorBorder: _noBorder,
                  isDense: true,
                ),
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                onChanged: _setQuery,
                style: GoogleFonts.sourceSans3(
                  fontSize: inputFont,
                  fontWeight: FontWeight.w600,
                  color: _white.withValues(alpha: 0.95),
                ),
                cursorColor: _neonLime,
                cursorWidth: 2,
                decoration: InputDecoration(
                  isDense: true,
                  border: _noBorder,
                  enabledBorder: _noBorder,
                  focusedBorder: _noBorder,
                  disabledBorder: _noBorder,
                  errorBorder: _noBorder,
                  focusedErrorBorder: _noBorder,
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.sourceSans3(
                    fontSize: hintFont,
                    fontWeight: FontWeight.w400,
                    color: _white.withValues(alpha: 0.28),
                    letterSpacing: 0.2,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // ── Clear button ─────────────────────────────────────────────────
          AnimatedOpacity(
            duration: const Duration(milliseconds: 130),
            opacity: query.isNotEmpty ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: query.isEmpty,
              child: GestureDetector(
                onTap: _clear,
                child: Container(
                  width: clearBtnSize,
                  height: clearBtnSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _borderGray,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: AppResponsive.icon(context, 13).clamp(11.0, 15.0),
                    color: _white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
