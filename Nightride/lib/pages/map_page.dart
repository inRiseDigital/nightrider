import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:permission_handler/permission_handler.dart';

import 'package:nightride/components/category_chips_row.dart';
import 'package:nightride/components/map_top_search_bar.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/components/venue_card.dart';
import 'package:nightride/components/venue_modal.dart';
import 'package:nightride/components/venue_search_sheet.dart';
import 'package:nightride/core/config/maps_config.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/pages/events_grid_page.dart';
import 'package:nightride/pages/venue_details_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';

const String _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]''';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  MarkerId? _searchedVenueMarkerId;
  bool _locationPermissionGranted = false;

  int _topTabIndex = 0;
  final PageController _bottomCardsController = PageController(viewportFraction: 0.94);

  MapBottomCardData? _selectedVenue;
  List<MapBottomCardData> _currentEvents = [];
  bool _eventMarkersAdded = false;
  int? _selectedCategoryIndex;

  @override
  void dispose() {
    _mapController?.dispose();
    _bottomCardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebMap(context);

    ref.listen<MapFocus?>(mapFocusProvider, (_, focus) {
      if (focus == null) return;
      _dropRedPin(focus.lat, focus.lng);
      _drawRouteToFocus(focus.lat, focus.lng);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapFocusProvider.notifier).state = null;
      });
    });

    ref.listen<AsyncValue<List<MapBottomCardData>>>(mapEventsProvider, (_, next) {
      next.whenData((events) {
        _currentEvents = events;
        if (_mapController != null && !_eventMarkersAdded) {
          _addEventMarkers(events);
          _eventMarkersAdded = true;
        }
      });
    });

    final liveEvents = ref.watch(mapEventsProvider).asData?.value ?? [];
    if (liveEvents.isNotEmpty) _currentEvents = liveEvents;
    if (liveEvents.isNotEmpty && _mapController != null && !_eventMarkersAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_eventMarkersAdded) {
          _addEventMarkers(liveEvents);
          _eventMarkersAdded = true;
        }
      });
    }

    final l = AppLocalizations.of(context)!;

    final List<MapBottomCardData> allEvents =
        liveEvents.isNotEmpty ? liveEvents : kBottomCards;

    final List<MapBottomCardData> displayEvents = _selectedCategoryIndex == null
        ? allEvents
        : liveEvents.isNotEmpty
            ? liveEvents.where((e) {
                final label = kMapCategories[_selectedCategoryIndex!].label;
                return e.tags.any((t) => matchesGenre(t, label)) ||
                    matchesGenre(e.subtitle, label);
              }).toList()
            : <MapBottomCardData>[];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.scaffold,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(7.2200, 79.8500),
                zoom: 14.0,
              ),
              markers: Set<Marker>.from(_markers),
              polylines: Set<Polyline>.from(_polylines),
              style: _kDarkMapStyle,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onTap: (_) {
                setState(() {
                  _selectedVenue = null;
                  _polylines.clear();
                  if (_searchedVenueMarkerId != null) {
                    _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
                    _searchedVenueMarkerId = null;
                  }
                });
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MapTopSearchBar(
                      selectedIndex: _topTabIndex,
                      searchHint: l.searchEvents,
                      onChanged: (int i) {
                        setState(() {
                          _topTabIndex = i;
                          _selectedVenue = null;
                          _polylines.clear();
                          if (_searchedVenueMarkerId != null) {
                            _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
                            _searchedVenueMarkerId = null;
                          }
                        });
                        if (i == 0) _goToMyLocation();
                      },
                      onSearchTap: () => _showSearchSheet(context),
                      onGridTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EventsGridPage()),
                      ),
                    ),
                    const Gap(10),
                    CategoryChipsRow(
                      items: kMapCategories,
                      selectedIndex: _selectedCategoryIndex,
                      onSelected: (int? idx) {
                        setState(() {
                          _selectedCategoryIndex = idx;
                          _eventMarkersAdded = false;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _addEventMarkers(displayEvents);
                          _eventMarkersAdded = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: AppResponsive.gap(context, 14).clamp(12.0, 18.0),
            bottom: AppResponsive.bottomNavHeight(context) +
                MediaQuery.viewPaddingOf(context).bottom +
                AppResponsive.gap(context, 12) +
                AppResponsive.mapBottomCardHeight(context) +
                6 +
                AppResponsive.gap(context, 12),
            child: GestureDetector(
              onTap: () => _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(const CameraPosition(
                  target: LatLng(20, 0),
                  zoom: 1.5,
                )),
              ),
              child: Container(
                width: AppResponsive.icon(context, 44).clamp(36.0, 48.0),
                height: AppResponsive.icon(context, 44).clamp(36.0, 48.0),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.public_rounded, color: Colors.white.withValues(alpha: 0.85), size: AppResponsive.icon(context, 22).clamp(18.0, 22.0)),
              ),
            ),
          ),

          if (_selectedVenue != null)
            Positioned(
              left: AppResponsive.pagePadding(context),
              right: AppResponsive.pagePadding(context),
              bottom: AppResponsive.bottomNavHeight(context) +
                  MediaQuery.viewPaddingOf(context).bottom +
                  AppResponsive.gap(context, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppResponsive.maxContentWidth(context),
                  ),
                  child: VenueCard(
                    data: _selectedVenue!,
                    onTap: () => _showVenueModal(context, _selectedVenue!),
                    onMoreDetails: () {
                      final v = _selectedVenue!;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => v.id.isNotEmpty ? EventDetailPage(id: v.id) : VenueDetailsPage(data: v),
                      ));
                    },
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: AppResponsive.bottomNavHeight(context) +
                  MediaQuery.viewPaddingOf(context).bottom +
                  AppResponsive.gap(context, 12),
              child: SizedBox(
                height: AppResponsive.mapBottomCardHeight(context) + 6,
                child: PageView.builder(
                  controller: _bottomCardsController,
                  itemCount: displayEvents.length,
                  physics: const BouncingScrollPhysics(),
                  padEnds: false,
                  itemBuilder: (BuildContext context, int index) {
                    final item = displayEvents[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 12 : 6,
                        right: 6,
                      ),
                      child: VenueCard(
                        data: item,
                        onTap: () => _showVenueModal(context, item),
                        onMoreDetails: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => item.id.isNotEmpty ? EventDetailPage(id: item.id) : VenueDetailsPage(data: item),
                          ));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _dropRedPin(double lat, double lng) {
    const markerId = MarkerId('focused_pin');
    setState(() {
      if (_searchedVenueMarkerId != null) {
        _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
      }
      _searchedVenueMarkerId = markerId;
      _markers.add(Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });
  }

  Future<void> _drawRouteToFocus(double destLat, double destLng) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 5));

      await _fetchAndDrawRoute(
        position.latitude, position.longitude,
        destLat, destLng,
      );

      // Fit camera to show both the user and the destination
      final sw = LatLng(
        position.latitude < destLat ? position.latitude : destLat,
        position.longitude < destLng ? position.longitude : destLng,
      );
      final ne = LatLng(
        position.latitude > destLat ? position.latitude : destLat,
        position.longitude > destLng ? position.longitude : destLng,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 80),
      );
    } catch (e) {
      // Fallback: just animate to destination if location unavailable
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(destLat, destLng), zoom: 14.0),
      ));
    }
  }

  void _addEventMarkers(List<MapBottomCardData> events) {
    final icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('event_'));
      for (final v in events.where((e) => e.lat != 0 && e.lng != 0)) {
        _markers.add(Marker(
          markerId: MarkerId('event_${v.lat},${v.lng}'),
          position: LatLng(v.lat, v.lng),
          icon: icon,
          onTap: () => _onVenueSelected(v),
        ));
      }
    });
  }

  Future<void> _goToMyLocation() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) await Permission.locationWhenInUse.request();
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.5,
      )));
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _onVenueSelected(MapBottomCardData venue) async {
    setState(() => _selectedVenue = venue);

    if (venue.tags.contains('Search Result')) {
      const markerId = MarkerId('search_result');
      setState(() {
        if (_searchedVenueMarkerId != null) {
          _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
        }
        _searchedVenueMarkerId = markerId;
        _markers.add(Marker(
          markerId: markerId,
          position: LatLng(venue.lat, venue.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    }

    _drawRouteToVenue(venue);
  }

  Future<void> _drawRouteToVenue(MapBottomCardData venue) async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;
    if (venue.lat == 0 || venue.lng == 0) return;

    try {
      final position = await geo.Geolocator.getCurrentPosition();
      if (position.latitude == 0 || position.longitude == 0) return;

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(venue.lat, venue.lng),
        zoom: 17.5,
      )));

      await _fetchAndDrawRoute(
        position.latitude, position.longitude,
        venue.lat, venue.lng,
      );
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  Future<void> _fetchAndDrawRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    const String mapsKey = String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY', defaultValue: kGoogleMapsApiKey);
    if (mapsKey.isEmpty || mapsKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') return;

    final Uri uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$startLat,$startLng'
      '&destination=$endLat,$endLng'
      '&key=$mapsKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes == null || routes.isEmpty) return;

        final route = routes[0];
        final legs = route['legs'] as List;
        final int distanceMeters = (legs[0]['distance']['value'] as num).toInt();

        if (_selectedVenue != null) {
          setState(() {
            _selectedVenue = _selectedVenue!.copyWith(
              distanceKm: double.parse((distanceMeters / 1000).toStringAsFixed(1)),
            );
          });
        }

        final String encodedPoly = route['overview_polyline']['points'];
        final List<LatLng> points = _decodePolyline(encodedPoly);

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.redAccent,
            width: 5,
          ));
        });
      }
    } catch (e) {
      debugPrint("Directions error: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    if (_currentEvents.isNotEmpty && !_eventMarkersAdded) {
      _addEventMarkers(_currentEvents);
      _eventMarkersAdded = true;
    } else if (!_eventMarkersAdded) {
      _addEventMarkers(kBottomCards);
    }

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(const CameraPosition(
        target: LatLng(7.2200, 79.8500),
        zoom: 14.0,
      )));
      return;
    }

    setState(() => _locationPermissionGranted = true);

    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.5,
      )));
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _showVenueModal(BuildContext context, MapBottomCardData data) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) => VenueModal(
        data: data,
        onNavigate: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VenueDetailsPage(data: data)),
          );
        },
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) => VenueSearchSheet(
        initialVenues: _currentEvents.isNotEmpty ? _currentEvents : kBottomCards,
        onVenueSelect: (venue) => _onVenueSelected(venue),
      ),
    );
  }

  Widget _buildWebMap(BuildContext context) {
    final liveEvents = ref.watch(mapEventsProvider).asData?.value ?? [];
    final allEvents = liveEvents.isNotEmpty ? liveEvents : kBottomCards;
    final List<MapBottomCardData> displayEvents = _selectedCategoryIndex == null
        ? allEvents
        : allEvents.where((e) {
            final label = kMapCategories[_selectedCategoryIndex!].label;
            return e.tags.any((t) => matchesGenre(t, label)) ||
                matchesGenre(e.subtitle, label);
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: Stack(
        children: [
          fmap.FlutterMap(
            options: fmap.MapOptions(
              initialCenter: const ll.LatLng(20.0, 0.0),
              initialZoom: 2.0,
              onTap: (_, __) => setState(() => _selectedVenue = null),
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.therisetechvillage.nightride',
              ),
              fmap.MarkerLayer(
                markers: displayEvents
                    .where((e) => e.lat != 0 && e.lng != 0)
                    .map((e) => fmap.Marker(
                          point: ll.LatLng(e.lat, e.lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedVenue = e),
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFFE53935),
                              size: 36,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: CategoryChipsRow(
                items: kMapCategories,
                selectedIndex: _selectedCategoryIndex,
                onSelected: (int? idx) => setState(() => _selectedCategoryIndex = idx),
              ),
            ),
          ),
          if (_selectedVenue != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 50,
              child: VenueCard(
                data: _selectedVenue!,
                onTap: () => _showVenueModal(context, _selectedVenue!),
                onMoreDetails: () {
                  final v = _selectedVenue!;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => v.id.isNotEmpty
                        ? EventDetailPage(id: v.id)
                        : VenueDetailsPage(data: v),
                  ));
                },
              ),
            ),
        ],
      ),
    );
  }
}
