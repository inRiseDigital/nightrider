import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    final Color borderColor =
        glowOn
            ? AppTheme.primary.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.06);

    final List<BoxShadow> glowShadows =
        glowOn
            ? <BoxShadow>[
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.22),
                blurRadius: 16.r,
                spreadRadius: 0.5.r,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 38.r,
                spreadRadius: 3.r,
                offset: Offset(0, 5.h),
              ),
            ]
            : const <BoxShadow>[];

    return Row(
      children: <Widget>[
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        SizedBox(width: 8.w),

        /// ✅ ONE container that wraps search icon + input + clear
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: glowShadows,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: Colors.white.withValues(alpha: glowOn ? 0.92 : 0.78),
                ),
                SizedBox(width: 10.w),

                /// ✅ Force TextField to NEVER draw its own focused border
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      // prevent any theme focus color / decoration borders
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
                        fontSize: 13.5.sp,
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
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                /// ✅ clear button inside same glowing container
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: query.isNotEmpty ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: query.isEmpty,
                    child: InkWell(
                      onTap: _clear,
                      borderRadius: BorderRadius.circular(999.r),
                      child: Container(
                        width: 30.sp,
                        height: 30.sp,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: glowOn ? 0.08 : 0.06,
                          ),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: glowOn ? 0.10 : 0.06,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.sp,
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
