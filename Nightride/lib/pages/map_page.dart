import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:permission_handler/permission_handler.dart';

import 'package:nightride/components/place_sheet.dart';
import 'package:nightride/data/services/open_map_service.dart';
import 'package:nightride/data/services/overpass_service.dart';
import 'package:nightride/components/map_top_search_bar.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/components/venue_card.dart';
import 'package:nightride/components/venue_modal.dart';
import 'package:nightride/components/venue_search_sheet.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/pages/events_grid_page.dart';
import 'package:nightride/pages/venue_details_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';

// ── Retro nightclub dark map style ───────────────────────────────────────────
const String _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#07070f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8a9a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#07070f"},{"weight":2}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#9a9aaa"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#6a6a7a"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0c0c14"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#0e0e18"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#111120"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0a1a12"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#22223a"},{"weight":1}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#5a5a7a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1e1e32"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#242438"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#2e2e4a"},{"weight":1.5}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#6a6a8a"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#181828"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#12121e"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#050510"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3a3a5a"}]}
]''';

// ── Filter categories shown as pill row ──────────────────────────────────────
const _kFilterLabels = <String>['ALL', 'CLUBS', 'BARS', 'EVENTS'];

// ── Brand colours ─────────────────────────────────────────────────────────────
const _kBlack    = Color(0xFF070707);
const _kSurface  = Color(0xFF0F0F0F);
const _kBorder   = Color(0xFF252525);
const _kNeonLime = Color(0xFFDFFF2F);
const _kHotPink  = Color(0xFFFF3D73);
const _kTeal     = Color(0xFF62D6C8);

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _RouteInfo {
  final String destName;
  final String distance;
  final String duration;
  final String mode;
  const _RouteInfo({
    required this.destName,
    required this.distance,
    required this.duration,
    this.mode = 'driving',
  });
  _RouteInfo copyWith({
    String? destName,
    String? distance,
    String? duration,
    String? mode,
  }) =>
      _RouteInfo(
        destName: destName ?? this.destName,
        distance: distance ?? this.distance,
        duration: duration ?? this.duration,
        mode: mode ?? this.mode,
      );
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};
  MarkerId? _searchedVenueMarkerId;
  bool _locationPermissionGranted = false;

  // ── Filter / tab state ────────────────────────────────────────────────────
  int  _topTabIndex        = 0;  // location button
  int  _filterIndex        = 0;  // ALL / CLUBS / BARS / EVENTS pill
  final PageController _bottomCardsController =
      PageController(viewportFraction: 0.92);

  MapBottomCardData? _selectedVenue;
  List<MapBottomCardData> _currentEvents  = [];
  bool _eventMarkersAdded = false;
  int? _selectedCategoryIndex;

  _RouteInfo? _routeInfo;
  LatLng? _routeOrigin;
  LatLng? _routeDest;
  String? _pendingDestName;
  geo.Position?       _cachedPosition;
  Map<String, String> _modeDurations = {};

  List<MapBottomCardData> _nearbyVenues   = [];
  bool _venueMarkersLoaded  = false;
  bool _showPolaroids       = true;

  // Draggable polaroid card positions (null = use defaults on first build)
  final List<Offset?> _cardOffsets = [null, null, null];
  int _draggingCard = -1;

  @override
  void dispose() {
    _mapController?.dispose();
    _bottomCardsController.dispose();
    super.dispose();
  }

  // ── Filter helper ─────────────────────────────────────────────────────────
  List<MapBottomCardData> _applyFilter(List<MapBottomCardData> all) {
    if (_filterIndex == 0) return all; // ALL
    final label = _kFilterLabels[_filterIndex].toLowerCase();
    return all.where((v) {
      final cat = v.subtitle.toLowerCase();
      final tags = v.tags.map((t) => t.toLowerCase()).toList();
      return cat.contains(label) || tags.any((t) => t.contains(label));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebMap(context);

    ref.listen<MapFocus?>(mapFocusProvider, (_, focus) {
      if (focus == null) return;
      final destName = focus.label.isNotEmpty ? focus.label : 'Destination';
      _resolveAndStorePlaceId(destName, focus.lat, focus.lng);
      _focusSingleLocation(focus);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapFocusProvider.notifier).state = null;
      });
    });

    ref.listen<AsyncValue<List<MapBottomCardData>>>(mapEventsProvider,
        (_, next) {
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
    if (liveEvents.isNotEmpty &&
        _mapController != null &&
        !_eventMarkersAdded) {
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

    final List<MapBottomCardData> poolBeforeFilter =
        _nearbyVenues.isNotEmpty
            ? _nearbyVenues
            : (_selectedCategoryIndex == null
                ? allEvents
                : liveEvents.isNotEmpty
                    ? liveEvents.where((e) {
                        final label =
                            kMapCategories[_selectedCategoryIndex!].label;
                        return e.tags.any((t) => matchesGenre(t, label)) ||
                            matchesGenre(e.subtitle, label);
                      }).toList()
                    : <MapBottomCardData>[]);

    final List<MapBottomCardData> displayEvents =
        _applyFilter(poolBeforeFilter);

    // Lazy-initialize draggable polaroid positions on first build
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    _cardOffsets[0] ??= Offset(14, sh * 0.06);
    _cardOffsets[1] ??= Offset(sw - 160, 0);
    _cardOffsets[2] ??= Offset(sw - 168, sh * 0.46 - 210);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: _kBlack,
      body: Stack(
        children: <Widget>[
          // ── Google Map ───────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(7.2200, 79.8500),
                zoom: 14.0,
              ),
              markers:   Set<Marker>.from(_markers),
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
                    _markers.removeWhere(
                        (m) => m.markerId == _searchedVenueMarkerId);
                    _searchedVenueMarkerId = null;
                  }
                });
              },
            ),
          ),

          // ── Navigation top header (replaces search bar while routing) ────
          if (_routeInfo != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildNavTopHeader(),
            ),

          // ── Search bar + filter pills ────────────────────────────────────
          if (_routeInfo == null)
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
                              _markers.removeWhere(
                                  (m) => m.markerId == _searchedVenueMarkerId);
                              _searchedVenueMarkerId = null;
                            }
                          });
                          if (i == 0) _goToMyLocation();
                        },
                        onSearchTap: () => _showSearchSheet(context),
                        onGridTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EventsGridPage()),
                        ),
                      ),
                      const Gap(10),
                      // ── Retro filter pills ───────────────────────────────
                      _FilterPillRow(
                        labels: _kFilterLabels,
                        selectedIndex: _filterIndex,
                        onSelected: (i) => setState(() => _filterIndex = i),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Globe / world view FAB ────────────────────────────────────────
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
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: LatLng(20, 0), zoom: 1.5),
                ),
              ),
              child: Container(
                width:  AppResponsive.icon(context, 44).clamp(36.0, 48.0),
                height: AppResponsive.icon(context, 44).clamp(36.0, 48.0),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.public_rounded,
                  color: Colors.white.withValues(alpha: 0.70),
                  size: AppResponsive.icon(context, 22).clamp(18.0, 22.0),
                ),
              ),
            ),
          ),

          // ── Floating polaroid cards (reference-style overlay) ────────────
          if (_routeInfo == null && _selectedVenue == null && displayEvents.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 104,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_showPolaroids) ...[
                    if (displayEvents.isNotEmpty)
                      Positioned(
                        left: _cardOffsets[0]!.dx,
                        top:  _cardOffsets[0]!.dy,
                        child: GestureDetector(
                          onPanStart: (_) => setState(() => _draggingCard = 0),
                          onPanUpdate: (d) => setState(
                              () => _cardOffsets[0] = _cardOffsets[0]! + d.delta),
                          onPanEnd: (_) => setState(() => _draggingCard = -1),
                          child: AnimatedScale(
                            scale: _draggingCard == 0 ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Transform.rotate(
                              angle: -0.09,
                              child: _PolaroidCard(
                                data: displayEvents[0],
                                onTap: () => _showVenueModal(context, displayEvents[0]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (displayEvents.length > 1)
                      Positioned(
                        left: _cardOffsets[1]!.dx,
                        top:  _cardOffsets[1]!.dy,
                        child: GestureDetector(
                          onPanStart: (_) => setState(() => _draggingCard = 1),
                          onPanUpdate: (d) => setState(
                              () => _cardOffsets[1] = _cardOffsets[1]! + d.delta),
                          onPanEnd: (_) => setState(() => _draggingCard = -1),
                          child: AnimatedScale(
                            scale: _draggingCard == 1 ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Transform.rotate(
                              angle: 0.06,
                              child: _PolaroidCard(
                                data: displayEvents[1],
                                onTap: () => _showVenueModal(context, displayEvents[1]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (displayEvents.length > 2)
                      Positioned(
                        left: _cardOffsets[2]!.dx,
                        top:  _cardOffsets[2]!.dy,
                        child: GestureDetector(
                          onPanStart: (_) => setState(() => _draggingCard = 2),
                          onPanUpdate: (d) => setState(
                              () => _cardOffsets[2] = _cardOffsets[2]! + d.delta),
                          onPanEnd: (_) => setState(() => _draggingCard = -1),
                          child: AnimatedScale(
                            scale: _draggingCard == 2 ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Transform.rotate(
                              angle: -0.05,
                              child: _PolaroidCard(
                                data: displayEvents[2],
                                onTap: () => _showVenueModal(context, displayEvents[2]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Close button
                    Positioned(
                      top: 0,
                      left: MediaQuery.of(context).size.width / 2 - 16,
                      child: GestureDetector(
                        onTap: () => setState(() => _showPolaroids = false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    // Re-open button when cards are dismissed
                    Positioned(
                      top: 0,
                      left: MediaQuery.of(context).size.width / 2 - 52,
                      child: GestureDetector(
                        onTap: () => setState(() => _showPolaroids = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_rounded,
                                  color: Colors.white54, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'SHOW CARDS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Bottom content: nav panel / venue sheet / bottom cards ────────
          if (_routeInfo != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppResponsive.bottomNavHeight(context) +
                  MediaQuery.viewPaddingOf(context).bottom,
              child: _buildNavBottomPanel(),
            )
          else if (_selectedVenue != null)
            Positioned(
              left: 0,
              right: 0,
              // Body already sits above the nav bar (shell Scaffold has no
              // extendBody), so anchor the sheet flush to the bottom instead
              // of adding the nav-bar height again and leaving a map gap.
              bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.76,
                ),
                child: GoogleMapsPlaceSheet(
                  venue: _selectedVenue!,
                  onClose: _closeVenueSheet,
                  onDirections: () {
                    final v = _selectedVenue!;
                    _closeVenueSheet();
                    _drawRouteToVenue(v);
                  },
                  onStart: () {
                    final v = _selectedVenue!;
                    _closeVenueSheet();
                    _startNavigation(v);
                  },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "NEARBY" section label
                  if (displayEvents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _kNeonLime,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NEARBY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: AppResponsive.font(context, 11),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${displayEvents.length} spots',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.30),
                              fontSize: AppResponsive.font(context, 10),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
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
                            left: index == 0 ? 14 : 7,
                            right: 7,
                          ),
                          child: VenueCard(
                            data: item,
                            onTap: () => _showVenueModal(context, item),
                            onMoreDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => item.id.isNotEmpty
                                      ? EventDetailPage(id: item.id)
                                      : VenueDetailsPage(data: item),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers: navigation / route / location ────────────────────────────────

  Future<void> _resolveAndStorePlaceId(
      String name, double lat, double lng) async {
    if (!mounted) return;
    // no-op: place ID resolution removed (Google Places replaced by OpenMapService)
  }

  /// Opens the map on a single selected location: clears every other marker
  /// and any route, drops one pin, zooms in tightly so only that place is in
  /// view (no bounds-fit that would zoom out to show all markers), and shows
  /// the place detail sheet for it.
  void _focusSingleLocation(MapFocus focus) {
    const markerId = MarkerId('focused_pin');
    // Prefer a matching event from the pool (richer data); otherwise build a
    // card from the fields carried on the focus itself.
    final matched = _currentEvents.where((e) =>
        (e.lat - focus.lat).abs() < 1e-6 &&
        (e.lng - focus.lng).abs() < 1e-6);
    final MapBottomCardData card = matched.isNotEmpty
        ? matched.first
        : MapBottomCardData(
            id: focus.id,
            placeId: focus.placeId,
            title: focus.label.isNotEmpty ? focus.label : 'Selected location',
            subtitle: focus.subtitle,
            locationLine: focus.locationLine,
            imageUrl: focus.imageUrl,
            tags: focus.tags,
            distanceKm: 0,
            openText: '',
            priceHint: focus.priceHint,
            lat: focus.lat,
            lng: focus.lng,
          );
    setState(() {
      _polylines.clear();
      _routeInfo = null;
      _markers.removeWhere((m) => m.markerId.value.startsWith('event_'));
      if (_searchedVenueMarkerId != null) {
        _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
      }
      // Keep event markers from being re-added on the next build.
      _eventMarkersAdded = true;
      _searchedVenueMarkerId = markerId;
      _markers.add(Marker(
        markerId: markerId,
        position: LatLng(focus.lat, focus.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
      _selectedVenue = card;
    });
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(focus.lat, focus.lng), zoom: 16.0),
    ));
  }

  void _addEventMarkers(List<MapBottomCardData> events) {
    final icon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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
        locationSettings:
            const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      _cachedPosition = position;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.5)));
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _onVenueSelected(MapBottomCardData venue) {
    if (venue.tags.contains('Search Result')) {
      const markerId = MarkerId('search_result');
      if (_searchedVenueMarkerId != null) {
        _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
      }
      _searchedVenueMarkerId = markerId;
      _markers.add(Marker(
        markerId: markerId,
        position: LatLng(venue.lat, venue.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    setState(() => _selectedVenue = venue);

    if (venue.lat != 0 && venue.lng != 0) {
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(venue.lat, venue.lng), zoom: 16.0),
      ));
    }
  }

  void _closeVenueSheet() {
    setState(() {
      _selectedVenue = null;
      if (_searchedVenueMarkerId != null) {
        _markers.removeWhere((m) => m.markerId == _searchedVenueMarkerId);
        _searchedVenueMarkerId = null;
      }
    });
  }

  Future<void> _drawRouteToVenue(MapBottomCardData venue) async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;
    if (venue.lat == 0 || venue.lng == 0) return;
    try {
      final position = await geo.Geolocator.getCurrentPosition();
      if (position.latitude == 0 || position.longitude == 0) return;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(venue.lat, venue.lng), zoom: 17.5)));
      await _fetchAndDrawRoute(
          position.latitude, position.longitude, venue.lat, venue.lng);
      _fetchAllModeTimes(
          position.latitude, position.longitude, venue.lat, venue.lng);
    } catch (e) {
      debugPrint('Route error: $e');
    }
  }

  Future<void> _fetchAndDrawRoute(
      double startLat, double startLng, double endLat, double endLng,
      {String mode = 'driving'}) async {
    try {
      final route = await OpenMapService.getRoute(
          startLat, startLng, endLat, endLng,
          mode: mode);
      if (route == null || !mounted) return;

      final points = _decodePolyline(route.encodedPolyline);

      setState(() {
        if (_selectedVenue != null) {
          _selectedVenue = _selectedVenue!.copyWith(
            distanceKm: double.parse(
                (route.distanceMeters / 1000).toStringAsFixed(1)),
          );
        }

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: _kHotPink,
          width: 5,
          geodesic: true,
        ));

        if (_pendingDestName != null) {
          _routeInfo = _RouteInfo(
            destName: _pendingDestName!,
            distance: route.distanceText,
            duration: route.durationText,
            mode: mode,
          );
          _pendingDestName = null;
        } else if (_routeInfo != null) {
          _routeInfo = _routeInfo!.copyWith(
            distance: route.distanceText,
            duration: route.durationText,
            mode: mode,
          );
        }
      });
    } catch (e) {
      debugPrint('OSRM route error: $e');
    }
  }

  void _addOriginMarker(double lat, double lng) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'origin_marker');
      _markers.add(Marker(
        markerId: const MarkerId('origin_marker'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your location'),
      ));
    });
  }

  void _clearNavigation() {
    setState(() {
      _routeInfo       = null;
      _routeOrigin     = null;
      _routeDest       = null;
      _pendingDestName = null;
      _modeDurations   = {};
      _polylines.clear();
      _markers.removeWhere((m) =>
          m.markerId.value == 'origin_marker' ||
          m.markerId.value == 'focused_pin');
      _searchedVenueMarkerId = null;
    });
  }

  Future<void> _fetchAllModeTimes(
      double startLat, double startLng, double endLat, double endLng) async {
    const modes = ['driving', 'walking', 'bicycling'];
    final futures = modes.map((mode) async {
      final route = await OpenMapService.getRoute(
          startLat, startLng, endLat, endLng,
          mode: mode);
      if (route == null) return null;
      return MapEntry(mode, route.durationText);
    });
    final results = await Future.wait(futures);
    if (!mounted) return;
    final map = <String, String>{};
    for (final r in results) {
      if (r != null) map[r.key] = r.value;
    }
    setState(() => _modeDurations = map);
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
      shift  = 0;
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

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(
          const CameraPosition(target: LatLng(7.2200, 79.8500), zoom: 14.0)));
      return;
    }

    setState(() => _locationPermissionGranted = true);

    geo.Position? position = await geo.Geolocator.getLastKnownPosition();
    if (position == null) {
      try {
        position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.low),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Location error: $e');
      }
    }

    if (position != null) {
      _cachedPosition = position;
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 14.0)));
      _loadNearbyVenues(position.latitude, position.longitude);
    } else {
      final bounds = await _mapController?.getVisibleRegion();
      if (bounds != null) {
        final cLat =
            (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final cLng =
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        _loadNearbyVenues(cLat, cLng);
      }
    }
  }

  Future<void> _loadNearbyVenues(double lat, double lng,
      {int radiusMeters = 5000}) async {
    if (_venueMarkersLoaded) return;
    final osmVenues = await OverpassService.fetchNearbyVenues(
        lat: lat, lng: lng, radiusMeters: radiusMeters);
    if (!mounted) return;
    final cards = osmVenues
        .map((v) => MapBottomCardData(
              id: '',
              title: v.name,
              subtitle: v.typeLabel,
              locationLine: v.address ?? v.typeLabel,
              imageUrl: '',
              tags: [v.type.toUpperCase()],
              distanceKm: haversineKm(lat, lng, v.lat, v.lng),
              openText: v.openingHours ?? '—',
              priceHint: '',
              lat: v.lat,
              lng: v.lng,
            ))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    setState(() {
      _nearbyVenues        = cards;
      _venueMarkersLoaded  = true;
    });
    if (cards.isNotEmpty) _addVenueMarkers(cards);
  }

  void _addVenueMarkers(List<MapBottomCardData> venues) {
    final icon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('venue_'));
      for (final v in venues) {
        _markers.add(Marker(
          markerId: MarkerId('venue_${v.lat},${v.lng}'),
          position: LatLng(v.lat, v.lng),
          icon: icon,
          onTap: () => _onVenueSelected(v),
        ));
      }
    });
  }

  Future<void> _startNavigation(MapBottomCardData venue) async {
    if (venue.lat == 0 || venue.lng == 0) return;
    setState(() {
      _selectedVenue   = null;
      _pendingDestName = venue.title;
    });
    try {
      final geo.Position position = _cachedPosition ??
          await geo.Geolocator.getLastKnownPosition() ??
          await geo.Geolocator.getCurrentPosition(
            locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.low),
          ).timeout(const Duration(seconds: 8));
      _routeOrigin = LatLng(position.latitude, position.longitude);
      _routeDest   = LatLng(venue.lat, venue.lng);
      _addOriginMarker(position.latitude, position.longitude);
      await _fetchAndDrawRoute(
          position.latitude, position.longitude, venue.lat, venue.lng);
      _fetchAllModeTimes(
          position.latitude, position.longitude, venue.lat, venue.lng);
      final sw = LatLng(
        position.latitude < venue.lat ? position.latitude : venue.lat,
        position.longitude < venue.lng ? position.longitude : venue.lng,
      );
      final ne = LatLng(
        position.latitude > venue.lat ? position.latitude : venue.lat,
        position.longitude > venue.lng ? position.longitude : venue.lng,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: sw, northeast: ne), 100),
      );
    } catch (e) {
      debugPrint('Start nav error: $e');
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
        initialVenues:
            _currentEvents.isNotEmpty ? _currentEvents : kBottomCards,
        onVenueSelect: (venue) => _onVenueSelected(venue),
      ),
    );
  }

  // ── Retro dark navigation top header ─────────────────────────────────────
  Widget _buildNavTopHeader() {
    final info    = _routeInfo!;
    final safePad = MediaQuery.viewPaddingOf(context).top;
    return Container(
      color: _kSurface,
      padding: EdgeInsets.fromLTRB(4, safePad + 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Origin → destination row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Colors.white.withValues(alpha: 0.85), size: 22),
                onPressed: _clearNavigation,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.circle, color: _kTeal, size: 10),
                      const SizedBox(width: 8),
                      Text('Your location',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Container(
                            width: 1,
                            height: 14,
                            margin: const EdgeInsets.only(left: 4, right: 14),
                            color: _kBorder),
                      ]),
                    ),
                    Row(children: [
                      const Icon(Icons.location_on, color: _kHotPink, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(info.destName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_vert,
                    color: Colors.white.withValues(alpha: 0.40), size: 22),
                onPressed: null,
              ),
            ],
          ),
          // Mode pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: [
                _buildModePill(Icons.directions_car_rounded, 'driving'),
                const SizedBox(width: 8),
                _buildModePill(Icons.directions_walk_rounded, 'walking'),
                const SizedBox(width: 8),
                _buildModePill(Icons.directions_bike_rounded, 'bicycling'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill(IconData icon, String mode) {
    final isSelected = _routeInfo?.mode == mode;
    final time = isSelected
        ? (_routeInfo?.duration ?? '')
        : (_modeDurations[mode] ?? '');
    return GestureDetector(
      onTap: () async {
        if (_routeOrigin == null || _routeDest == null) return;
        await _fetchAndDrawRoute(
          _routeOrigin!.latitude, _routeOrigin!.longitude,
          _routeDest!.latitude,  _routeDest!.longitude,
          mode: mode,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _kNeonLime.withValues(alpha: 0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? _kNeonLime.withValues(alpha: 0.70)
                : _kBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? _kNeonLime
                    : Colors.white.withValues(alpha: 0.50),
                size: 18),
            if (time.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(time,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? _kNeonLime
                          : Colors.white.withValues(alpha: 0.65))),
            ] else if (!isSelected) ...[
              const SizedBox(width: 6),
              SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.30))),
            ],
          ],
        ),
      ),
    );
  }

  // ── Retro dark navigation bottom panel ────────────────────────────────────
  Widget _buildNavBottomPanel() {
    final info = _routeInfo!;
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.60),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${info.duration}  ·  ${info.distance}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Fastest route via current traffic',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kNeonLime.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _kNeonLime.withValues(alpha: 0.35), width: 1),
                ),
                child: const Text('FASTEST',
                    style: TextStyle(
                        color: _kNeonLime,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('START',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNeonLime,
                    foregroundColor: _kBlack,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _routeDest == null
                      ? null
                      : () {
                          final dest = _routeDest!;
                          final name =
                              _routeInfo?.destName ?? 'Destination';
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.sizeOf(context).height * 0.76,
                              ),
                              child: GoogleMapsPlaceSheet(
                                venue: MapBottomCardData(
                                  id: '',
                                  title: name,
                                  subtitle: '',
                                  locationLine: '',
                                  imageUrl: '',
                                  tags: const [],
                                  distanceKm: 0,
                                  openText: '',
                                  priceHint: '',
                                  lat: dest.latitude,
                                  lng: dest.longitude,
                                ),
                                onClose: () => Navigator.pop(context),
                                onDirections: () => Navigator.pop(context),
                                onStart: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('DETAILS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: _kBorder, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Web fallback (flutter_map) ────────────────────────────────────────────
  Widget _buildWebMap(BuildContext context) {
    final liveEvents = ref.watch(mapEventsProvider).asData?.value ?? [];
    final allEvents  = liveEvents.isNotEmpty ? liveEvents : kBottomCards;
    final List<MapBottomCardData> displayEvents =
        _selectedCategoryIndex == null
            ? allEvents
            : allEvents.where((e) {
                final label =
                    kMapCategories[_selectedCategoryIndex!].label;
                return e.tags.any((t) => matchesGenre(t, label)) ||
                    matchesGenre(e.subtitle, label);
              }).toList();

    return Scaffold(
      backgroundColor: _kBlack,
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
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              color: _kHotPink,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterPillRow(
                    labels: _kFilterLabels,
                    selectedIndex: _filterIndex,
                    onSelected: (i) => setState(() => _filterIndex = i),
                  ),
                ],
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

// ── Polaroid floating card (reference-style map overlay) ─────────────────
class _PolaroidCard extends StatelessWidget {
  const _PolaroidCard({required this.data, required this.onTap});

  final MapBottomCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color cream   = Color(0xFFF3EAD6);
    final bool isLive   = data.tags.any((t) => t == 'LIVE' || t == 'LIVE NOW');
    final String badge  = isLive
        ? 'LIVE NOW'
        : (data.tags.isNotEmpty ? data.tags.first : 'VENUE');
    final String distText = data.distanceKm > 0
        ? '${data.distanceKm.toStringAsFixed(1)} km away'
        : data.locationLine;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  child: data.imageUrl.isNotEmpty
                      ? Image.network(
                          data.imageUrl,
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLive
                          ? _kHotPink
                          : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Polaroid label
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: GoogleFonts.anton(
                      fontSize: 13,
                      color: const Color(0xFF1A1A1A),
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kHotPink,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      data.subtitle.isNotEmpty
                          ? data.subtitle.toUpperCase()
                          : 'VENUE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distText,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 150,
        height: 110,
        color: const Color(0xFF1A1A2E),
        child: const Icon(
          Icons.nightlife_rounded,
          color: Color(0xFF62D6C8),
          size: 36,
        ),
      );
}

// ── Filter pill row (ALL | CLUBS | BARS | EVENTS) ─────────────────────────
class _FilterPillRow extends StatelessWidget {
  const _FilterPillRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.mapChipHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemCount: labels.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: AppResponsive.gap(context, 8)),
        itemBuilder: (context, i) {
          final bool selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.gap(context, 16),
                vertical: AppResponsive.gap(context, 7),
              ),
              decoration: BoxDecoration(
                color: selected
                    ? _kNeonLime
                    : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _kNeonLime
                      : const Color(0xFF2A2A2A),
                  width: selected ? 1.5 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _kNeonLime.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: TextStyle(
                  color: selected ? _kBlack : Colors.white,
                  fontSize: AppResponsive.font(context, 12),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
