import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/category_chips_row.dart';
import 'package:nightride/components/venue_card.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/pages/venue_details_page.dart';

class VenueSearchSheet extends StatefulWidget {
  const VenueSearchSheet({super.key, this.onVenueSelect, this.initialVenues = kBottomCards});
  final Function(MapBottomCardData venue)? onVenueSelect;
  final List<MapBottomCardData> initialVenues;

  @override
  State<VenueSearchSheet> createState() => _VenueSearchSheetState();
}

class _VenueSearchSheetState extends State<VenueSearchSheet> {
  final TextEditingController _textController = TextEditingController();
  String _searchQuery = '';

  late List<MapBottomCardData> _searchResults = [...widget.initialVenues];
  bool _isSearching = false;
  bool _isAllActive = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
         // If query is cleared, revert to 'All' state if it was active, or just empty?
         // User requested default show venues. 
         // Let's decide: Clearing text usually resets. 
         // But here, let's keep it clean: if empty, show all if active.
         if (_isAllActive) {
           _searchResults = [...widget.initialVenues];
         } else {
           _searchResults = [];
         }
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isAllActive = false; // Typing disables 'All' mode purely visually
    });

    final String token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    final Uri uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?country=lk&proximity=79.8500,7.2200&types=poi,address,place,locality,neighborhood&limit=100&access_token=$token',
    );

    try {
      final http.Response response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] as List;

        final List<MapBottomCardData> results = features.map((f) {
          final center = f['center'] as List;
          final String name = f['text'] ?? 'Unknown Place';
          final String address = f['place_name'] ?? '';
          
          return MapBottomCardData(
            title: name,
            subtitle: 'Points of Interest',
            locationLine: address,
            imageUrl: 'https://images.unsplash.com/photo-1514525253440-b393452e8d03?auto=format&fit=crop&w=900&q=80',
            tags: ['Search Result'],
            distanceKm: 0.0,
            openText: 'Open Now',
            priceHint: 'Free',
            lat: center[1].toDouble(),
            lng: center[0].toDouble(),
          );
        }).toList();

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Error searching: $e");
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.scaffold.withValues(alpha: 0.98),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Gap(12.h),
                    Center(
                      child: Container(
                        width: 50.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Gap(20.h),
                    
                    // Unified Search Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        height: 54.h,
                        padding: EdgeInsets.only(left: 14.w, right: 6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(27.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 22.sp),
                            Gap(10.w),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                autofocus: false, // Don't autofocus to keep list visible nicely
                                style: TextStyle(color: Colors.white, fontSize: 15.sp),
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _performSearch(val);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search venues...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 15.sp,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_isSearching)
                              Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            
                            // Integrated "All" Button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAllActive = !_isAllActive;
                                  if (_isAllActive) {
                                    // Turning ON: Show default list
                                    _textController.clear();
                                    _searchQuery = '';
                                    _searchResults = [...widget.initialVenues];
                                  } else {
                                    // Turning OFF: Hide default list
                                    if (_searchQuery.isEmpty) {
                                        _searchResults = [];
                                    }
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: _isAllActive ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: _isAllActive 
                                      ? null 
                                      : Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  'All',
                                  style: TextStyle(
                                    color: _isAllActive 
                                        ? Colors.white 
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Gap(16.h),
                    // Show chips only if the list is empty (user hid results or searching yielded nothing)
                    if (_searchResults.isEmpty && _searchQuery.isEmpty)
                      CategoryChipsRow(items: kMapCategories),
                    Gap(12.h),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = _searchResults[index];
                      return _SearchResultItem(
                        data: data,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onVenueSelect?.call(data);
                        },
                      );
                    },
                    childCount: _searchResults.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({required this.data, required this.onTap});
  final MapBottomCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.location_on_rounded, color: AppTheme.primaryLight, size: 22.sp),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(2.h),
                  Text(
                    data.locationLine,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap(10.w),
            Text(
              '${data.distanceKm} km',
              style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
