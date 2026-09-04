import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/domain/event.dart';
import 'package:nightride/providers/settings_providers.dart';
import 'package:nightride/services/firestore_service.dart';

class OrganizerHomePage extends ConsumerWidget {
  const OrganizerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrganizer = ref.watch(isOrganizerProvider).asData?.value ?? false;
    if (!isOrganizer) {
      return Scaffold(
        backgroundColor: AppTheme.scaffold,
        appBar: AppBar(backgroundColor: AppTheme.scaffold, title: const Text('My Events', style: TextStyle(color: Colors.white))),
        body: const Center(
          child: Text('Access denied. Organizer account required.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: const Text('My Events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text('ORGANIZER', style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 10), fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Event', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showCreateEventSheet(context, uid),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white54)))
          // organizerUid == uid, ordered by createdAt desc.
          // Index: events(organizerUid ASC, createdAt DESC)
          : StreamBuilder<List<Event>>(
              stream: firestoreService.streamOrganizerEvents(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final events = snapshot.data ?? const <Event>[];
                if (events.isEmpty) {
                  return _EmptyState(onTap: () => _showCreateEventSheet(context, uid));
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, AppResponsive.gap(context, 16).clamp(12, 22), 16, AppResponsive.gap(context, 100).clamp(80, 120)),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => Gap(AppResponsive.gap(context, 12).clamp(8, 16)),
                  itemBuilder: (context, i) {
                    final event = events[i];
                    return _EventCard(
                      event: event,
                      onEdit: () => _showCreateEventSheet(context, uid, existing: event),
                      onDelete: () => _confirmDelete(context, event.id),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showCreateEventSheet(BuildContext context, String? uid, {Event? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateEventSheet(uid: uid, existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete the event.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              firestoreService.deleteEvent(docId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 72, color: AppTheme.primary.withValues(alpha: 0.3)),
          Gap(AppResponsive.gap(context, 16).clamp(12, 22)),
          Text('No events yet', style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 18), fontWeight: FontWeight.w700)),
          Gap(AppResponsive.gap(context, 8).clamp(6, 12)),
          Text('Tap + to create your first event', style: TextStyle(color: Colors.white38, fontSize: AppResponsive.font(context, 13))),
          Gap(AppResponsive.gap(context, 24).clamp(18, 32)),
          ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary.withValues(alpha: 0.2), foregroundColor: Colors.white),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Event'),
          ),
        ],
      ),
    );
  }
}

/// The organizer publish toggle only ever moves between these states; every
/// other status (`scheduled`, `cancelled`, `archived`) disables the toggle
/// rather than writing anything.
String? _nextToggleStatus(String status) {
  switch (status) {
    case 'draft':
    case 'in_review':
      return 'published';
    case 'published':
      return 'draft';
    default:
      return null;
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onEdit, required this.onDelete});
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = event.name.isEmpty ? 'Untitled' : event.name;
    final dt = event.startDateTime;
    final dateText = dt == null ? '' : DateFormat('MMM d, yyyy · h:mm a').format(dt);
    final venue = event.venueName;
    final isPublished = event.isPublished;
    final nextStatus = _nextToggleStatus(event.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 15), fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPublished ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(event.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: isPublished ? Colors.greenAccent : Colors.orangeAccent, fontSize: AppResponsive.font(context, 9), fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (dateText.isNotEmpty || venue.isNotEmpty) ...[
            Gap(AppResponsive.gap(context, 6).clamp(4, 10)),
            if (dateText.isNotEmpty)
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: AppResponsive.icon(context, 12), color: Colors.white38),
                Gap(4),
                Text(dateText, style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12))),
              ]),
            if (venue.isNotEmpty) ...[
              Gap(3),
              Row(children: [
                Icon(Icons.location_on_rounded, size: AppResponsive.icon(context, 12), color: Colors.white38),
                Gap(4),
                Text(venue, style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12))),
              ]),
            ],
          ],
          Gap(AppResponsive.gap(context, 12).clamp(8, 16)),
          Row(
            children: [
              _ActionBtn(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
              Gap(8),
              if (nextStatus != null)
                _ActionBtn(
                  icon: isPublished ? Icons.visibility_off_outlined : Icons.publish_rounded,
                  label: isPublished ? 'Unpublish' : 'Publish',
                  // Narrow status-only patch — never touches interestedCount/popularityScore.
                  onTap: () => firestoreService.patchEventFields(
                    event.id,
                    {'status': nextStatus},
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.7), size: AppResponsive.icon(context, 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, size: AppResponsive.icon(context, 13), color: AppTheme.primaryLight),
          const Gap(4),
          Text(label, style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 11), fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Create / Edit Event Sheet ─────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({this.uid, this.existing});
  final String? uid;
  final Event? existing;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

/// The four countries the product covers today (see CLAUDE.md) — ISO-3166
/// alpha-2, uppercase, matching what `shapeOk()` in firestore.rules requires.
const Map<String, String> kOrganizerCountries = {
  'AE': 'UAE — Dubai',
  'JP': 'Japan — Tokyo',
  'GB': 'UK — London',
  'AU': 'Australia — Melbourne',
};

class _CreateEventSheetState extends State<_CreateEventSheet> {
  late final TextEditingController _title;
  late final TextEditingController _venue;
  late final TextEditingController _city;
  late final TextEditingController _dateTimeText;
  late final TextEditingController _description;
  late final TextEditingController _price;
  DateTime? _selectedDateTime;
  String _countryCode = 'AE';
  bool _saving = false;
  String? _dateError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title        = TextEditingController(text: e?.name ?? '');
    _venue        = TextEditingController(text: e?.venueName ?? '');
    _city         = TextEditingController(text: e?.city ?? '');
    _description  = TextEditingController(text: e?.description ?? '');
    _price        = TextEditingController(text: e != null ? e.price.hintText : '');
    _selectedDateTime = e?.startDateTime;
    _dateTimeText = TextEditingController(
      text: _selectedDateTime != null
          ? DateFormat('MMM d, yyyy · h:mm a').format(_selectedDateTime!)
          : '',
    );
    _countryCode = kOrganizerCountries.containsKey(e?.countryCode) ? e!.countryCode : 'AE';

    // Prefill city/country from the organizer's own profile so the common
    // case — creating an event in the organizer's home city — is one tap.
    // Only for a brand-new event: editing an existing one keeps its own
    // (already-illegal-to-omit) city/countryCode.
    if (e == null && widget.uid != null) {
      _prefillFromProfile(widget.uid!);
    }
  }

  Future<void> _prefillFromProfile(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      if (data == null || !mounted) return;
      final profileCity = data['city'] as String? ?? '';
      final profileCountry = (data['countryCode'] as String? ?? '').toUpperCase();
      setState(() {
        if (_city.text.isEmpty && profileCity.isNotEmpty) _city.text = profileCity;
        if (kOrganizerCountries.containsKey(profileCountry)) _countryCode = profileCountry;
      });
    } catch (_) {
      // Best-effort prefill only — the organizer can still fill both fields
      // in by hand.
    }
  }

  @override
  void dispose() {
    _title.dispose(); _venue.dispose(); _city.dispose(); _dateTimeText.dispose();
    _description.dispose(); _price.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDateTime ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateTimeText.text = DateFormat('MMM d, yyyy · h:mm a').format(_selectedDateTime!);
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    if (_selectedDateTime == null) {
      setState(() => _dateError = 'Pick a date & time');
      return;
    }
    if (_city.text.trim().isEmpty) {
      setState(() => _cityError = 'Required');
      return;
    }
    setState(() => _saving = true);
    try {
      final startAt = Timestamp.fromDate(_selectedDateTime!);
      final price = EventPrice.parseInput(_price.text.trim());
      final existing = widget.existing;
      if (existing != null) {
        final updated = existing.copyWith(
          name: _title.text.trim(),
          venueName: _venue.text.trim(),
          city: _city.text.trim(),
          countryCode: _countryCode,
          startAt: startAt,
          description: _description.text.trim(),
          price: price,
        );
        await firestoreService.updateOrganizerEvent(existing.id, updated);
      } else {
        final event = Event(
          name: _title.text.trim(),
          venueName: _venue.text.trim(),
          city: _city.text.trim(),
          countryCode: _countryCode,
          startAt: startAt,
          description: _description.text.trim(),
          price: price,
          organizerUid: widget.uid,
          source: 'organizer',
          status: 'draft',
        );
        await firestoreService.createOrganizerEvent(event);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: ListView(controller: controller, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          Gap(AppResponsive.gap(context, 16).clamp(12, 22)),
          Text(widget.existing != null ? 'Edit Event' : 'Create Event',
              style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18), fontWeight: FontWeight.w800)),
          Gap(AppResponsive.gap(context, 20).clamp(14, 28)),
          _SheetField(controller: _title, label: 'Event Title *', hint: 'e.g. Neon Night Festival', icon: Icons.title_rounded),
          Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
          _SheetField(controller: _venue, label: 'Venue', hint: 'e.g. Skyline Rooftop, Colombo', icon: Icons.location_on_outlined),
          Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SheetField(
                  controller: _city,
                  label: 'City *',
                  hint: 'e.g. Dubai',
                  icon: Icons.location_city_rounded,
                  errorText: _cityError,
                  onChanged: (_) {
                    if (_cityError != null) setState(() => _cityError = null);
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: _SheetCountryDropdown(
                  value: _countryCode,
                  onChanged: (v) => setState(() => _countryCode = v),
                ),
              ),
            ],
          ),
          Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
          _SheetField(
            controller: _dateTimeText,
            label: 'Date & Time *',
            hint: 'Tap to pick a date & time',
            icon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: _pickDateTime,
            errorText: _dateError,
          ),
          Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
          _SheetField(controller: _price, label: 'Ticket Price', hint: 'e.g. \$15 or Free', icon: Icons.confirmation_number_outlined),
          Gap(AppResponsive.gap(context, 14).clamp(10, 18)),
          _SheetField(controller: _description, label: 'Description', hint: 'Tell people about the event...', icon: Icons.notes_rounded, maxLines: 4),
          Gap(AppResponsive.gap(context, 24).clamp(18, 32)),
          SizedBox(
            width: double.infinity,
            height: AppResponsive.gap(context, 52).clamp(44, 60),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.existing != null ? 'Save Changes' : 'Create Event',
                      style: TextStyle(fontSize: AppResponsive.font(context, 15), fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.errorText,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 12), fontWeight: FontWeight.w700)),
      Gap(AppResponsive.gap(context, 6).clamp(4, 10)),
      TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14)),
        cursorColor: AppTheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: AppResponsive.font(context, 13)),
          errorText: errorText,
          prefixIcon: maxLines == 1 ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: AppTheme.primaryLight.withValues(alpha: 0.6), size: AppResponsive.icon(context, 18)),
          ) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: EdgeInsets.symmetric(vertical: AppResponsive.gap(context, 14).clamp(10, 18), horizontal: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5)),
        ),
      ),
    ]);
  }
}

/// Same visual language as [_SheetField] but for the fixed four-country list
/// the product covers — see [kOrganizerCountries].
class _SheetCountryDropdown extends StatelessWidget {
  const _SheetCountryDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Country *', style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 12), fontWeight: FontWeight.w700)),
      Gap(AppResponsive.gap(context, 6).clamp(4, 10)),
      DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppTheme.surface,
        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 13)),
        onChanged: (v) { if (v != null) onChanged(v); },
        items: kOrganizerCountries.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.key, overflow: TextOverflow.ellipsis)))
            .toList(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: EdgeInsets.symmetric(vertical: AppResponsive.gap(context, 14).clamp(10, 18), horizontal: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5)),
        ),
      ),
    ]);
  }
}
