import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/category_chips_row.dart';
import 'package:nightride/components/venue_card.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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
      _isAllActive = false;
    });

    String token = '';
    try { token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? ''; } catch (_) {}
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
    final inputFont = AppResponsive.font(context, 15).clamp(13.0, 16.0);
    final smallFont = AppResponsive.font(context, 11).clamp(10.0, 12.0);
    final labelFont = AppResponsive.font(context, 13).clamp(11.5, 14.0);

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Gap(12),
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(20),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.gap(context, 16).clamp(14.0, 20.0),
                      ),
                      child: Container(
                        height: AppResponsive.gap(context, 54).clamp(48.0, 60.0),
                        padding: EdgeInsets.only(
                          left: AppResponsive.gap(context, 14).clamp(12.0, 16.0),
                          right: AppResponsive.gap(context, 6).clamp(4.0, 8.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: AppResponsive.icon(context, 22).clamp(18.0, 24.0),
                            ),
                            Gap(AppResponsive.gap(context, 10).clamp(8.0, 12.0)),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                autofocus: false,
                                style: TextStyle(color: Colors.white, fontSize: inputFont),
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _performSearch(val);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search venues...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: inputFont,
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
                                padding: const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),

                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAllActive = !_isAllActive;
                                  if (_isAllActive) {
                                    _textController.clear();
                                    _searchQuery = '';
                                    _searchResults = [...widget.initialVenues];
                                  } else {
                                    if (_searchQuery.isEmpty) {
                                      _searchResults = [];
                                    }
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isAllActive ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
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
                                    fontSize: labelFont,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Gap(16),
                    if (_searchResults.isEmpty && _searchQuery.isEmpty)
                      CategoryChipsRow(items: kMapCategories),
                    const Gap(12),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.gap(context, 16).clamp(14.0, 20.0),
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = _searchResults[index];
                      return _SearchResultItem(
                        data: data,
                        smallFont: smallFont,
                        labelFont: labelFont,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryLight,
            fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.data,
    required this.smallFont,
    required this.labelFont,
    required this.onTap,
  });
  final MapBottomCardData data;
  final double smallFont;
  final double labelFont;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = AppResponsive.gap(context, 44).clamp(38.0, 50.0);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppTheme.primaryLight,
                size: AppResponsive.icon(context, 22).clamp(18.0, 24.0),
              ),
            ),
            Gap(AppResponsive.gap(context, 12).clamp(10.0, 14.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFont,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    data.locationLine,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: smallFont,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(10),
            Text(
              '${data.distanceKm} km',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: smallFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
