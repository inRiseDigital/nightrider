import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/services/firestore_service.dart';

class AdminAddEventPage extends StatefulWidget {
  const AdminAddEventPage({super.key, this.eventId, this.existingData});

  final String? eventId;
  final Map<String, dynamic>? existingData;

  @override
  State<AdminAddEventPage> createState() => _AdminAddEventPageState();
}

class _AdminAddEventPageState extends State<AdminAddEventPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _venueName;
  late final TextEditingController _coverImage;
  late final TextEditingController _priceHint;
  late final TextEditingController _date;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;

  String _category = 'Club';
  String _genre = 'EDM';
  String _vibe = 'Energetic';
  String _status = 'Published';

  // Performers
  final List<Map<String, dynamic>> _performers = [];

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
  static const _statuses = ['Draft', 'Published', 'Cancelled', 'Completed'];

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData ?? {};
    _name = TextEditingController(text: d['name'] ?? '');
    _description = TextEditingController(text: d['description'] ?? '');
    _city = TextEditingController(text: d['city'] ?? '');
    _country = TextEditingController(text: d['country'] ?? '');
    _venueName = TextEditingController(text: d['venue_name'] ?? '');
    _coverImage = TextEditingController(text: d['cover_image'] ?? '');
    _priceHint = TextEditingController(text: d['price_hint'] ?? '');
    _date = TextEditingController(text: d['date'] ?? '');
    _startTime = TextEditingController(text: d['start_time'] ?? '');
    _endTime = TextEditingController(text: d['end_time'] ?? '');
    _category = _categories.contains(d['category']) ? d['category'] : 'Club';
    _genre = _genres.contains(d['genre']) ? d['genre'] : 'EDM';
    _vibe = _vibes.contains(d['vibe']) ? d['vibe'] : 'Energetic';
    _status = _statuses.contains(d['status']) ? d['status'] : 'Published';

    // Load existing performers
    final existingPerformers = d['performers'] as List<dynamic>?;
    if (existingPerformers != null) {
      for (final p in existingPerformers) {
        if (p is Map) {
          _performers.add({
            'name': p['name'] ?? '',
            'type': p['type'] ?? 'DJ',
            'bio': p['bio'] ?? '',
          });
        }
      }
    }

    // Load existing policies
    final pol = d['policies'] as Map<String, dynamic>?;
    if (pol != null) {
      _ageRestriction.text = (pol['age_restriction'] ?? 0).toString();
      _refundPolicy.text = pol['refund_policy'] ?? '';
      _reEntryAllowed = pol['re_entry_allowed'] == true;
      _wheelchairAccessible = pol['wheelchair_accessible'] == true;
      _allowPets = pol['allow_pets'] == true;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _city, _country, _venueName,
      _coverImage, _priceHint, _date, _startTime, _endTime,
      _ageRestriction, _refundPolicy,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'city': _city.text.trim(),
      'country': _country.text.trim(),
      'venue_name': _venueName.text.trim(),
      'cover_image': _coverImage.text.trim(),
      'price_hint': _priceHint.text.trim(),
      'date': _date.text.trim(),
      'start_time': _startTime.text.trim(),
      'end_time': _endTime.text.trim(),
      'category': _category,
      'genre': _genre,
      'vibe': _vibe,
      'status': _status,
      'interested_count': widget.existingData?['interested_count'] ?? 0,
      'watching_count': widget.existingData?['watching_count'] ?? 0,
      'performers': _performers,
      'policies': {
        'age_restriction': int.tryParse(_ageRestriction.text.trim()) ?? 0,
        'refund_policy': _refundPolicy.text.trim(),
        're_entry_allowed': _reEntryAllowed,
        'wheelchair_accessible': _wheelchairAccessible,
        'allow_pets': _allowPets,
      },
    };
    try {
      if (_isEditing) {
        await firestoreService.updateEvent(widget.eventId!, data);
      } else {
        await firestoreService.addEvent(data);
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

  static const _performerTypes = ['DJ', 'Band', 'Comedian', 'Live Act', 'Other'];

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
                  items: _performerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                      setState(() => _performers.add({
                        'name': name,
                        'type': selectedType,
                        'bio': bioCtrl.text.trim(),
                      }));
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
      initialDate: now,
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
      _date.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _Field(controller: _country, label: 'Country *', required: true)),
            ]),
            Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
            _SectionLabel('Date & Time'),
            Gap(AppResponsive.gap(context, 12).clamp(8, 18)),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: _Field(controller: _date, label: 'Date (YYYY-MM-DD) *', required: true),
              ),
            ),
            Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
            Row(children: [
              Expanded(child: _Field(controller: _startTime, label: 'Start Time (e.g. 09:00 PM)')),
              const Gap(12),
              Expanded(child: _Field(controller: _endTime, label: 'End Time')),
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
            _Field(controller: _priceHint, label: 'Price Hint (e.g. Free / \$20 / Tickets)'),

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
                          child: Text(p['type'] ?? 'DJ', style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              if ((p['bio'] as String? ?? '').isNotEmpty)
                                Text(p['bio'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
