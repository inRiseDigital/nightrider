// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/providers/common_search_providers.dart';

import '../core/theme/app_theme.dart';
import '../data/search_dummy_data.dart';
import '../components/search_app_bar.dart';
import '../components/search_section_header.dart';
import '../components/search_list_item.dart';
import '../components/search_empty_state.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(searchUiStateProvider);
    final results = ref.watch(searchFilteredProvider);
    final query = ref.watch(searchQueryProvider).trim();

    String headerText;
    switch (uiState) {
      case SearchUiState.idle:
        headerText = 'YOU MAY LIKE THESE';
        break;
      case SearchUiState.results:
        headerText = 'RESULTS (${results.length})';
        break;
      case SearchUiState.empty:
        headerText = 'NO RESULTS';
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppTheme.background, AppTheme.scaffold],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SearchAppBarRow(hintText: kSearchHint),
                SizedBox(height: 22.h),

                SearchSectionHeader(text: headerText),
                SizedBox(height: 14.h),

                Expanded(
                  child: Builder(
                    builder: (BuildContext context) {
                      if (uiState == SearchUiState.empty) {
                        return SearchEmptyState(
                          query: query,
                          onClear: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        );
                      }

                      // ✅ idle + results both show list
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = results[index];
                          return SearchListItem(
                            item: item,
                            onTap: () {},
                            showDivider: index != results.length - 1,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
