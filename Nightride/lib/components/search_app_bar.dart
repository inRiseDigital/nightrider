import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/providers/common_search_providers.dart';

import '../core/theme/app_theme.dart';

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
    final String query = ref.watch(searchQueryProvider);
    final bool focused = ref.watch(searchBarFocusedProvider);

    if (_controller.text != query) {
      _controller.value = _controller.value.copyWith(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
        composing: TextRange.empty,
      );
    }

    final bool glowOn = focused || query.isNotEmpty;

    final Color borderColor = glowOn
        ? AppTheme.primary.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.06);

    final List<BoxShadow> glowShadows = glowOn
        ? <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: 0.5,
              offset: const Offset(0, 0),
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 38,
              spreadRadius: 3,
              offset: const Offset(0, 5),
            ),
          ]
        : const <BoxShadow>[];

    final barHeight = AppResponsive.gap(context, 46).clamp(42.0, 52.0);
    final inputFont = AppResponsive.font(context, 13.5).clamp(12.0, 14.5);
    final hintFont = AppResponsive.font(context, 13).clamp(11.5, 14.0);
    final iconSize = AppResponsive.icon(context, 18).clamp(15.0, 20.0);
    final clearBtnSize = AppResponsive.gap(context, 30).clamp(26.0, 34.0);

    return Row(
      children: <Widget>[
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            height: barHeight,
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.gap(context, 12).clamp(10.0, 14.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: glowShadows,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search_rounded,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: glowOn ? 0.92 : 0.78),
                ),
                const SizedBox(width: 10),

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
                      style: TextStyle(
                        fontSize: inputFont,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      cursorColor: AppTheme.primary,
                      decoration: InputDecoration(
                        isDense: true,
                        border: _noBorder,
                        enabledBorder: _noBorder,
                        focusedBorder: _noBorder,
                        disabledBorder: _noBorder,
                        errorBorder: _noBorder,
                        focusedErrorBorder: _noBorder,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: hintFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: query.isNotEmpty ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: query.isEmpty,
                    child: InkWell(
                      onTap: _clear,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: clearBtnSize,
                        height: clearBtnSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: glowOn ? 0.08 : 0.06,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: glowOn ? 0.10 : 0.06,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: AppResponsive.icon(context, 16).clamp(13.0, 18.0),
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
