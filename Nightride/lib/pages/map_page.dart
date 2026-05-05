import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide MapOptions;
import 'package:permission_handler/permission_handler.dart';

import 'package:nightride/components/category_chips_row.dart';
import 'package:nightride/components/map_top_search_bar.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/components/venue_card.dart';
import 'package:nightride/components/venue_modal.dart';
import 'package:nightride/components/venue_search_sheet.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/pages/events_grid_page.dart';
import 'package:nightride/pages/venue_details_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    implements OnPointAnnotationClickListener {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  int _topTabIndex = 0;
  final PageController _bottomCardsController = PageController(viewportFraction: 0.94);

  MapBottomCardData? _selectedVenue;
  PointAnnotation? _searchedVenueMarker;

  List<MapBottomCardData> _currentEvents = [];
  bool _eventMarkersAdded = false;
  int? _selectedCategoryIndex;

  @override
  void dispose() {
    _bottomCardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebMap(context);
    }
    // Fly to event location when tapped from detail page
    ref.listen<MapFocus?>(mapFocusProvider, (_, focus) {
      if (focus == null) return;
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(focus.lng, focus.lat)),
          zoom: 14.0,
          pitch: 0.0,
        ),
        MapAnimationOptions(duration: 900),
      );
      _dropRedPin(focus.lat, focus.lng);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapFocusProvider.notifier).state = null;
      });
    });

    // Keep _currentEvents in sync for use in non-build callbacks
    ref.listen<AsyncValue<List<MapBottomCardData>>>(mapEventsProvider, (_, next) {
      next.whenData((events) {
        _currentEvents = events;
        if (_pointAnnotationManager != null && !_eventMarkersAdded) {
          _addEventMarkers(events);
          _eventMarkersAdded = true;
        }
      });
    });

    // Drive UI directly from the provider so it always reflects current state
    final liveEvents = ref.watch(mapEventsProvider).asData?.value ?? [];
    if (liveEvents.isNotEmpty) _currentEvents = liveEvents;
    if (liveEvents.isNotEmpty && _pointAnnotationManager != null && !_eventMarkersAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_eventMarkersAdded) {
          _addEventMarkers(liveEvents);
          _eventMarkersAdded = true;
        }
      });
    }

    final l = AppLocalizations.of(context)!;

    // Only use dummy cards when Firestore has returned nothing at all
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
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedVenue = null);
                _polylineAnnotationManager?.deleteAll();
                if (_searchedVenueMarker != null) {
                  _pointAnnotationManager?.delete(_searchedVenueMarker!);
                  _searchedVenueMarker = null;
                }
              },
              child: MapWidget(
                onMapCreated: _onMapCreated,
                styleUri: MapboxStyles.MAPBOX_STREETS,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(79.8500, 7.2200)),
                  zoom: 14.0,
                  pitch: 0.0,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
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
                        });
                        _polylineAnnotationManager?.deleteAll();
                        if (_searchedVenueMarker != null) {
                          _pointAnnotationManager?.delete(_searchedVenueMarker!);
                          _searchedVenueMarker = null;
                        }
                        if (i == 0) _goToMyLocation();
                      },
                      onSearchTap: () => _showSearchSheet(context),
                      onGridTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EventsGridPage()),
                      ),
                    ),
                    Gap(10.h),
                    CategoryChipsRow(
                      items: kMapCategories,
                      selectedIndex: _selectedCategoryIndex,
                      onSelected: (int? idx) {
                        setState(() {
                          _selectedCategoryIndex = idx;
                          _eventMarkersAdded = false;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_pointAnnotationManager != null) {
                            _addEventMarkers(displayEvents);
                            _eventMarkersAdded = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── World view button ──────────────────────────────────────────
          Positioned(
            right: 14.w,
            bottom: 190.h,
            child: GestureDetector(
              onTap: () => _mapboxMap?.flyTo(
                CameraOptions(
                  center: Point(coordinates: Position(0, 20)),
                  zoom: 1.5,
                  pitch: 0.0,
                ),
                MapAnimationOptions(duration: 900),
              ),
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.public_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22.sp),
              ),
            ),
          ),

          if (_selectedVenue != null)
            Positioned(
              left: 14.w,
              right: 14.w,
              bottom: 50.h,
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
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 50.h,
              child: SizedBox(
                height: 122.h,
                child: PageView.builder(
                  controller: _bottomCardsController,
                  itemCount: displayEvents.length,
                  physics: const BouncingScrollPhysics(),
                  padEnds: false,
                  itemBuilder: (BuildContext context, int index) {
                    final item = displayEvents[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 12.w : 6.w,
                        right: 6.w,
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

  Future<void> _dropRedPin(double lat, double lng) async {
    // Remove previous highlight pin if any
    if (_searchedVenueMarker != null) {
      await _pointAnnotationManager?.delete(_searchedVenueMarker!);
      _searchedVenueMarker = null;
    }
    final bytes = await _buildRedPinImage();
    _searchedVenueMarker = await _pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        image: bytes,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
  }

  Future<Uint8List> _buildRedPinImage() async {
    const double w = 48, h = 60;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Shadow
    canvas.drawCircle(
      const Offset(w / 2, w / 2 + 2),
      16,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Red circle
    canvas.drawCircle(const Offset(w / 2, w / 2), 16, Paint()..color = const Color(0xFFE53935));
    // White ring
    canvas.drawCircle(
      const Offset(w / 2, w / 2),
      16,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // White centre dot
    canvas.drawCircle(const Offset(w / 2, w / 2), 5, Paint()..color = Colors.white);
    // Tail
    final path = Path()
      ..moveTo(w / 2 - 6, w / 2 + 12)
      ..lineTo(w / 2, h - 2)
      ..lineTo(w / 2 + 6, w / 2 + 12)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE53935));

    final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _addEventMarkers(List<MapBottomCardData> events) async {
    await _pointAnnotationManager?.deleteAll();
    _searchedVenueMarker = null;
    if (events.isEmpty) return;

    final annotations = events
        .where((v) => v.lat != 0 && v.lng != 0)
        .map((v) => PointAnnotationOptions(
              geometry: Point(coordinates: Position(v.lng, v.lat)),
              iconImage: 'marker-15',
              iconSize: 2.5,
            ))
        .toList();
    if (annotations.isNotEmpty) {
      await _pointAnnotationManager?.createMulti(annotations);
    }
  }

  Future<void> _goToMyLocation() async {
    final PermissionStatus permission = await Permission.locationWhenInUse.status;
    if (!permission.isGranted) {
      await Permission.locationWhenInUse.request();
    }
    try {
      final geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      _zoomToLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _zoomToLocation(double lat, double lng, {double zoom = 16.5}) async {
    await _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: 0.0,
      ),
    );
  }

  Future<void> _onVenueSelected(MapBottomCardData venue) async {
    setState(() => _selectedVenue = venue);

    // If it's a Mapbox geocode search result (not a Firestore event), pin it
    if (venue.tags.contains('Search Result')) {
      if (_searchedVenueMarker != null) {
        await _pointAnnotationManager?.delete(_searchedVenueMarker!);
        _searchedVenueMarker = null;
      }
      _searchedVenueMarker = await _pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(venue.lng, venue.lat)),
          iconImage: 'custom-pin',
          iconSize: 1.0,
        ),
      );
    }

    _drawRouteToVenue(venue);
  }

  Future<void> _drawRouteToVenue(MapBottomCardData venue) async {
    final PermissionStatus permission = await Permission.locationWhenInUse.status;
    if (!permission.isGranted) return;
    if (venue.lat == 0 || venue.lng == 0) return;

    try {
      final geo.Position position = await geo.Geolocator.getCurrentPosition();
      if (position.latitude == 0 || position.longitude == 0) return;

      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(venue.lng, venue.lat)),
          zoom: 17.5,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 800),
      );

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
    final String token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (token.isEmpty) return;

    final Uri uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat'
      '?geometries=geojson&access_token=$token',
    );

    try {
      final http.Response response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['routes'] as List).isEmpty) return;

        final route = data['routes'][0];
        final coordinates = route['geometry']['coordinates'] as List;
        final double distanceMeters = (route['distance'] as num).toDouble();

        if (_selectedVenue != null) {
          setState(() {
            _selectedVenue = _selectedVenue!.copyWith(
              distanceKm: double.parse((distanceMeters / 1000).toStringAsFixed(1)),
            );
          });
        }

        final List<Position> points =
            coordinates.map((c) => Position(c[0], c[1])).toList();

        await _polylineAnnotationManager?.deleteAll();
        await _polylineAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: points),
            lineColor: Colors.redAccent.value,
            lineWidth: 6.0,
            lineBlur: 0.8,
            lineOpacity: 1.0,
            lineJoin: LineJoin.ROUND,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapboxMap = controller;
    _pointAnnotationManager =
        await controller.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await controller.annotations.createPolylineAnnotationManager();

    // Load custom logo pin
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo.png');
      final Uint8List list = bytes.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(list);
      final frame = await codec.getNextFrame();
      final image = MbxImage(
        width: frame.image.width,
        height: frame.image.height,
        data: list,
      );
      await controller.style.addStyleImage('custom-pin', 4.0, image, false, [], [], null);
      await controller.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
          locationPuck: LocationPuck(
            locationPuck2D: LocationPuck2D(topImage: list, scaleExpression: "0.15"),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error loading custom pin: $e");
      await controller.location.updateSettings(
        LocationComponentSettings(enabled: true, puckBearingEnabled: true),
      );
    }

    // Add markers: use live events if already loaded, else fall back to static
    if (_currentEvents.isNotEmpty && !_eventMarkersAdded) {
      await _addEventMarkers(_currentEvents);
      _eventMarkersAdded = true;
    } else if (!_eventMarkersAdded) {
      final fallback = kBottomCards
          .map((v) => PointAnnotationOptions(
                geometry: Point(coordinates: Position(v.lng, v.lat)),
                iconImage: 'marker-15',
                iconSize: 2.5,
              ))
          .toList();
      await _pointAnnotationManager?.createMulti(fallback);
    }

    final PermissionStatus permission =
        await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      _zoomToLocation(7.2200, 79.8500, zoom: 14.0);
      return;
    }

    final geo.Position position = await geo.Geolocator.getCurrentPosition(
      locationSettings:
          const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
    );

    await controller.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 16.5,
        pitch: 0.0,
      ),
    );

    await controller.location.updateSettings(
      LocationComponentSettings(enabled: true, puckBearingEnabled: true),
    );

    await controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await controller.compass.updateSettings(CompassSettings(enabled: false));
    await controller.logo.updateSettings(LogoSettings(enabled: false));
    await controller.attribution
        .updateSettings(AttributionSettings(clickable: false));

    _pointAnnotationManager?.addOnPointAnnotationClickListener(this);
  }

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final lat = annotation.geometry.coordinates.lat.toDouble();
    final lng = annotation.geometry.coordinates.lng.toDouble();

    final candidates = _currentEvents.isNotEmpty ? _currentEvents : kBottomCards;
    try {
      final venue = candidates.firstWhere(
        (v) => (v.lat - lat).abs() < 0.0001 && (v.lng - lng).abs() < 0.0001,
      );
      _onVenueSelected(venue);
    } catch (_) {}
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
          FlutterMap(
            options: MapOptions(
              initialCenter: const ll.LatLng(20.0, 0.0),
              initialZoom: 2.0,
              onTap: (_, __) => setState(() => _selectedVenue = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.therisetechvillage.nightride',
              ),
              MarkerLayer(
                markers: displayEvents
                    .where((e) => e.lat != 0 && e.lng != 0)
                    .map((e) => Marker(
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
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
              child: CategoryChipsRow(
                items: kMapCategories,
                selectedIndex: _selectedCategoryIndex,
                onSelected: (int? idx) => setState(() => _selectedCategoryIndex = idx),
              ),
            ),
          ),
          if (_selectedVenue != null)
            Positioned(
              left: 14.w,
              right: 14.w,
              bottom: 50.h,
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
