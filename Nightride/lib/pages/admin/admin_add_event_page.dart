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
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _city, _country, _venueName,
      _coverImage, _priceHint, _date, _startTime, _endTime,
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
