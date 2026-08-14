import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/venue_search_sheet.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/domain/event.dart';
import 'package:nightride/services/firestore_service.dart';

/// The four countries the product covers today (see CLAUDE.md) — ISO-3166
/// alpha-2, uppercase, matching what `shapeOk()` in firestore.rules requires.
const Map<String, String> kProductCountries = {
  'AE': 'UAE — Dubai',
  'JP': 'Japan — Tokyo',
  'GB': 'UK — London',
  'AU': 'Australia — Melbourne',
};

class AdminAddEventPage extends StatefulWidget {
  const AdminAddEventPage({super.key, this.existing});

  /// The event being edited, or null to create a new one.
  final Event? existing;

  @override
  State<AdminAddEventPage> createState() => _AdminAddEventPageState();
}

class _AdminAddEventPageState extends State<AdminAddEventPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _city;
  late final TextEditingController _venueName;
  late final TextEditingController _coverImage;

  // ── Price (events/{id}.price — a required map, not a free-text hint) ──────
  late final TextEditingController _priceMin;
  late final TextEditingController _priceMax;
  late final TextEditingController _priceCurrency;
  bool _isFree = true;

  String _countryCode = 'AE';
  String _category = 'Club';
  String _genre = 'EDM';
  String _vibe = 'Energetic';
  String _status = 'Draft';

  // ── Date & time (startAt/endAt are Timestamps, not free text) ─────────────
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late final TextEditingController _dateDisplay;
  late final TextEditingController _startTimeDisplay;
  late final TextEditingController _endTimeDisplay;

  // ── Location — geo is nullable, but a null geo renders a map pin at
  // (0,0), so a venue search sets it explicitly. ────────────────────────────
  GeoPoint? _geo;
  String _geoLabel = '';

  // Performers
  final List<Performer> _performers = [];

  // Policies
  final TextEditingController _ageRestriction = TextEditingController(text: '0');
  final TextEditingController _refundPolicy = TextEditingController();
  bool _reEntryAllowed = false;
  bool _wheelchairAccessible = false;
  bool _allowPets = false;

  static const _categories = [
    'Club', 'DJ', 'Techno', 'Rave', 'EDM', 'House', 'Live', 'Festival',
    'Comedy', 'Cultural', 'Lounge', 'Bass',
  ];
  static const _genres = [
    'EDM', 'Techno', 'House', 'Trance', 'Hip-Hop', 'R&B', 'Jazz', 'Drum & Bass',
    'Afrobeat', 'Indie', 'K-Pop', 'Reggaeton', 'Rock', 'Pop', 'Mixed',
  ];
  static const _vibes = [
    'Energetic', 'Chill', 'Relaxed', 'Wild', 'Romantic', 'Underground',
  ];
  // Only the two statuses this form is allowed to write — 'archived' is not
  // an authoring state and has no input here.
  static const _statuses = ['Draft', 'Published'];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _venueName = TextEditingController(text: e?.venueName ?? '');
    _coverImage = TextEditingController(text: e?.coverImage ?? '');

    _priceMin = TextEditingController(text: e != null ? _fmtNum(e.price.min) : '0');
    _priceMax = TextEditingController(text: e != null ? _fmtNum(e.price.max) : '0');
    _priceCurrency = TextEditingController(text: e?.price.currency ?? '');
    _isFree = e?.price.isFree ?? true;

    _countryCode = kProductCountries.containsKey(e?.countryCode) ? e!.countryCode : 'AE';
    _category = _categories.contains(e?.category) ? e!.category : 'Club';
    _genre = _genres.contains(e?.genre) ? e!.genre : 'EDM';
    _vibe = _vibes.contains(e?.vibe) ? e!.vibe : 'Energetic';
    _status = (e?.status == 'published') ? 'Published' : 'Draft';

    final startDt = e?.startDateTime;
    _startDate = startDt == null ? null : DateTime(startDt.year, startDt.month, startDt.day);
    _startTime = startDt == null ? null : TimeOfDay(hour: startDt.hour, minute: startDt.minute);
    final endDt = e?.endAt?.toDate();
    _endTime = endDt == null ? null : TimeOfDay(hour: endDt.hour, minute: endDt.minute);

    _dateDisplay = TextEditingController(text: _startDate == null ? '' : _fmtDate(_startDate!));
    _startTimeDisplay = TextEditingController(text: '');
    _endTimeDisplay = TextEditingController(text: '');

    _geo = e?.geo;
    _geoLabel = _geo == null ? '' : '${_geo!.latitude.toStringAsFixed(5)}, ${_geo!.longitude.toStringAsFixed(5)}';

    // Load existing performers
    for (final p in e?.performers ?? const <Performer>[]) {
      _performers.add(p);
    }

    // Load existing policies
    final pol = e?.policies;
    if (pol != null) {
      _ageRestriction.text = pol.ageRestriction.toString();
      _refundPolicy.text = pol.refundPolicy;
      _reEntryAllowed = pol.reEntryAllowed;
      _wheelchairAccessible = pol.wheelchairAccessible;
      _allowPets = pol.allowPets;
    }
  }

  static String _fmtNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    for (final c in [
      _name, _description, _city, _venueName, _coverImage,
      _priceMin, _priceMax, _priceCurrency,
      _dateDisplay, _startTimeDisplay, _endTimeDisplay,
      _ageRestriction, _refundPolicy,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start date and time'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);

    final startAt = Timestamp.fromDate(DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _startTime!.hour, _startTime!.minute,
    ));
    Timestamp? endAt;
    if (_endTime != null) {
      var endDt = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _endTime!.hour, _endTime!.minute,
      );
      // An end time earlier than the start time means the event runs past
      // midnight into the next day.
      if (!endDt.isAfter(startAt.toDate())) {
        endDt = endDt.add(const Duration(days: 1));
      }
      endAt = Timestamp.fromDate(endDt);
    }

    final min = num.tryParse(_priceMin.text.trim()) ?? 0;
    final max = num.tryParse(_priceMax.text.trim()) ?? 0;

    final event = Event(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      venueId: widget.existing?.venueId,
      venueName: _venueName.text.trim(),
      city: _city.text.trim(),
      countryCode: _countryCode,
      geo: _geo,
      startAt: startAt,
      endAt: endAt,
      price: EventPrice(
        min: _isFree ? 0 : min,
        max: _isFree ? 0 : max,
        currency: _isFree ? '' : _priceCurrency.text.trim(),
        isFree: _isFree,
      ),
      ticketUrl: widget.existing?.ticketUrl ?? '',
      coverImage: _coverImage.text.trim(),
      genre: _genre,
      category: _category,
      vibe: _vibe,
      language: widget.existing?.language ?? '',
      performers: _performers,
      policies: EventPolicies(
        ageRestriction: int.tryParse(_ageRestriction.text.trim()) ?? 0,
        refundPolicy: _refundPolicy.text.trim(),
        reEntryAllowed: _reEntryAllowed,
        wheelchairAccessible: _wheelchairAccessible,
        allowPets: _allowPets,
      ),
      status: _status.toLowerCase(),
      source: 'admin',
      organizerUid: widget.existing?.organizerUid,
    );

    try {
      if (_isEditing) {
        await firestoreService.updateOrganizerEvent(widget.existing!.id, event);
      } else {
        await firestoreService.createOrganizerEvent(event);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPerformer() async {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    String selectedType = 'DJ';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Performer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const Gap(20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _sheetInputDecoration('Name *'),
                ),
                const Gap(14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: _sheetInputDecoration('Type'),
                  onChanged: (v) => setModal(() => selectedType = v ?? 'DJ'),
                  items: kPerformerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
                const Gap(14),
                TextField(
                  controller: bioCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _sheetInputDecoration('Bio (optional)'),
                ),
                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() => _performers.add(Performer(
                        name: name,
                        type: selectedType,
                        bio: bioCtrl.text.trim(),
                      )));
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Add Performer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _sheetInputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _dateDisplay.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        _startTimeDisplay.text = picked.format(context);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _endTime = picked;
        _endTimeDisplay.text = picked.format(context);
      });
    }
  }

  Future<void> _pickLocation() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VenueSearchSheet(
        onVenueSelect: (MapBottomCardData venue) {
          setState(() {
            _geo = GeoPoint(venue.lat, venue.lng);
            _geoLabel = '${venue.lat.toStringAsFixed(5)}, ${venue.lng.toStringAsFixed(5)}';
            if (_venueName.text.trim().isEmpty) _venueName.text = venue.title;
          });
        },
      ),
    );
  }

  void _clearLocation() => setState(() { _geo = null; _geoLabel = ''; });

  @override
  Widget build(BuildContext context) {
    // Rebuild the start/end time display text lazily so it always reflects
    // widget.context (TimeOfDay.format needs a BuildContext for the current
    // 12h/24h locale preference).
    if (_startTime != null && _startTimeDisplay.text.isEmpty) {
      _startTimeDisplay.text = _startTime!.format(context);
    }
    if (_endTime != null && _endTimeDisplay.text.isEmpty) {
      _endTimeDisplay.text = _endTime!.format(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          _isEditing ? 'Edit Event' : 'Add New Event',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.accent,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                _isEditing ? 'Update' : 'Publish',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Event Info'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            _Field(controller: _name, label: 'Event Name *', required: true),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            _Field(
              controller: _description, label: 'Description',
              maxLines: 3,
            ),
            Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
            _SectionLabel('Location'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            _Field(controller: _venueName, label: 'Venue Name'),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            Row(children: [
              Expanded(child: _Field(controller: _city, label: 'City *', required: true)),
              const Gap(12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _countryCode,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Country *',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
                  ),
                  onChanged: (v) => setState(() => _countryCode = v ?? _countryCode),
                  items: kProductCountries.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                      .toList(),
                ),
              ),
            ]),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, color: _geo != null ? AppTheme.accent : Colors.white38, size: 18),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        _geo != null ? 'Map pin: $_geoLabel' : 'Tap to search & set map location',
                        style: TextStyle(color: _geo != null ? Colors.white : Colors.white38, fontSize: 13),
                      ),
                    ),
                    if (_geo != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                        onPressed: _clearLocation,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
            _SectionLabel('Date & Time'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: _Field(controller: _dateDisplay, label: 'Date (YYYY-MM-DD) *', required: true),
              ),
            ),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickStartTime,
                  child: AbsorbPointer(
                    child: _Field(controller: _startTimeDisplay, label: 'Start Time *', required: true),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickEndTime,
                  child: AbsorbPointer(
                    child: _Field(controller: _endTimeDisplay, label: 'End Time'),
                  ),
                ),
              ),
            ]),
            Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
            _SectionLabel('Classification'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            _Dropdown(
              label: 'Category',
              value: _category,
              items: _categories,
              onChanged: (v) => setState(() => _category = v!),
            ),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            _Dropdown(
              label: 'Genre',
              value: _genre,
              items: _genres,
              onChanged: (v) => setState(() => _genre = v!),
            ),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            _Dropdown(
              label: 'Vibe',
              value: _vibe,
              items: _vibes,
              onChanged: (v) => setState(() => _vibe = v!),
            ),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            _Dropdown(
              label: 'Status',
              value: _status,
              items: _statuses,
              onChanged: (v) => setState(() => _status = v!),
            ),
            Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
            _SectionLabel('Media & Pricing'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            _Field(controller: _coverImage, label: 'Cover Image URL'),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            _PolicySwitch(
              label: 'Free Entry',
              icon: Icons.money_off_rounded,
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            if (!_isFree) ...[
              Gap(AppResponsive.gap(context, 10).clamp(8, 14)),
              Row(children: [
                Expanded(child: _Field(controller: _priceMin, label: 'Min Price')),
                const Gap(12),
                Expanded(child: _Field(controller: _priceMax, label: 'Max Price')),
                const Gap(12),
                Expanded(child: _Field(controller: _priceCurrency, label: 'Currency (e.g. AED)')),
              ]),
            ],

            // ── Performers ──────────────────────────────────────────────────
            Gap(AppResponsive.gap(context, 28).clamp(20, 36)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Performers'),
                TextButton.icon(
                  onPressed: _addPerformer,
                  icon: const Icon(Icons.add_rounded, color: AppTheme.accent, size: 18),
                  label: const Text('Add', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
            Gap(AppResponsive.gap(context, 10).clamp(8, 14)),
            if (_performers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mic_none_rounded, color: Colors.white38, size: 20),
                    const Gap(10),
                    Text('No performers added yet', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              )
            else
              Column(
                children: List.generate(_performers.length, (i) {
                  final p = _performers[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p.type, style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              if (p.bio.isNotEmpty)
                                Text(p.bio, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => setState(() => _performers.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }),
              ),

            // ── Event Policies ───────────────────────────────────────────────
            Gap(AppResponsive.gap(context, 28).clamp(20, 36)),
            _SectionLabel('Event Policies'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            Row(children: [
              Expanded(child: _Field(controller: _ageRestriction, label: 'Min Age (0 = no limit)')),
              const Gap(12),
              Expanded(child: _Field(controller: _refundPolicy, label: 'Refund Policy')),
            ]),
            Gap(AppResponsive.gap(context, 12).clamp(8, 16)),
            _PolicySwitch(
              label: 'Re-entry Allowed',
              icon: Icons.loop_rounded,
              value: _reEntryAllowed,
              onChanged: (v) => setState(() => _reEntryAllowed = v),
            ),
            _PolicySwitch(
              label: 'Wheelchair Accessible',
              icon: Icons.accessible_rounded,
              value: _wheelchairAccessible,
              onChanged: (v) => setState(() => _wheelchairAccessible = v),
            ),
            _PolicySwitch(
              label: 'Pets Allowed',
              icon: Icons.pets_rounded,
              value: _allowPets,
              onChanged: (v) => setState(() => _allowPets = v),
            ),

            Gap(AppResponsive.gap(context, 40).clamp(30, 52)),
            SizedBox(
              width: double.infinity,
              height: AppResponsive.gap(context, 54).clamp(46, 62),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving...' : (_isEditing ? 'Update Event' : 'Add Event'),
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
              ),
            ),
            Gap(AppResponsive.gap(context, 30).clamp(22, 40)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppResponsive.font(context, 11),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: AppTheme.accent,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _PolicySwitch extends StatelessWidget {
  const _PolicySwitch({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(icon, color: value ? AppTheme.accent : Colors.white38, size: 18),
            const Gap(10),
            Text(label, style: TextStyle(color: value ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        value: value,
        activeThumbColor: AppTheme.accent,
        activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent),
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }
}
