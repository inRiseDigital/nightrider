import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';

class OrganizerHomePage extends StatelessWidget {
  const OrganizerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: const Text('My Events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text('ORGANIZER', style: TextStyle(color: AppTheme.primaryLight, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('organizerUid', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(onTap: () => _showCreateEventSheet(context, uid));
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Gap(12.h),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _EventCard(
                      docId: docs[i].id,
                      data: data,
                      onEdit: () => _showCreateEventSheet(context, uid, docId: docs[i].id, existing: data),
                      onDelete: () => _confirmDelete(context, docs[i].id),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showCreateEventSheet(BuildContext context, String? uid, {String? docId, Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateEventSheet(uid: uid, docId: docId, existing: existing),
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
              FirebaseFirestore.instance.collection('events').doc(docId).delete();
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
          Gap(16.h),
          Text('No events yet', style: TextStyle(color: Colors.white70, fontSize: 18.sp, fontWeight: FontWeight.w700)),
          Gap(8.h),
          Text('Tap + to create your first event', style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
          Gap(24.h),
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.docId, required this.data, required this.onEdit, required this.onDelete});
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Untitled';
    final date = data['date'] as String? ?? '';
    final venue = data['venue'] as String? ?? '';
    final status = data['status'] as String? ?? 'draft';
    final isPublished = status == 'published';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isPublished ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(color: isPublished ? Colors.greenAccent : Colors.orangeAccent, fontSize: 9.sp, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (date.isNotEmpty || venue.isNotEmpty) ...[
            Gap(6.h),
            if (date.isNotEmpty)
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 12.sp, color: Colors.white38),
                Gap(4.w),
                Text(date, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              ]),
            if (venue.isNotEmpty) ...[
              Gap(3.h),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 12.sp, color: Colors.white38),
                Gap(4.w),
                Text(venue, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              ]),
            ],
          ],
          Gap(12.h),
          Row(
            children: [
              _ActionBtn(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
              Gap(8.w),
              _ActionBtn(
                icon: isPublished ? Icons.visibility_off_outlined : Icons.publish_rounded,
                label: isPublished ? 'Unpublish' : 'Publish',
                onTap: () => FirebaseFirestore.instance.collection('events').doc(docId)
                    .update({'status': isPublished ? 'draft' : 'published'}),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.7), size: 20.sp),
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, size: 13.sp, color: AppTheme.primaryLight),
          Gap(4.w),
          Text(label, style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Create / Edit Event Sheet ─────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({this.uid, this.docId, this.existing});
  final String? uid;
  final String? docId;
  final Map<String, dynamic>? existing;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  late final TextEditingController _title;
  late final TextEditingController _venue;
  late final TextEditingController _date;
  late final TextEditingController _description;
  late final TextEditingController _price;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title       = TextEditingController(text: e?['title'] as String? ?? '');
    _venue       = TextEditingController(text: e?['venue'] as String? ?? '');
    _date        = TextEditingController(text: e?['date'] as String? ?? '');
    _description = TextEditingController(text: e?['description'] as String? ?? '');
    _price       = TextEditingController(text: e?['price'] as String? ?? '');
  }

  @override
  void dispose() {
    _title.dispose(); _venue.dispose(); _date.dispose();
    _description.dispose(); _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final col = FirebaseFirestore.instance.collection('events');
    final payload = {
      'title': _title.text.trim(),
      'venue': _venue.text.trim(),
      'date': _date.text.trim(),
      'description': _description.text.trim(),
      'price': _price.text.trim(),
      'organizerUid': widget.uid,
      'status': widget.existing?['status'] ?? 'draft',
    };
    try {
      if (widget.docId != null) {
        await col.doc(widget.docId).update(payload);
      } else {
        await col.add({...payload, 'createdAt': FieldValue.serverTimestamp()});
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
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
        child: ListView(controller: controller, children: [
          Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.r)))),
          Gap(16.h),
          Text(widget.docId != null ? 'Edit Event' : 'Create Event',
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800)),
          Gap(20.h),
          _SheetField(controller: _title, label: 'Event Title *', hint: 'e.g. Neon Night Festival', icon: Icons.title_rounded),
          Gap(14.h),
          _SheetField(controller: _venue, label: 'Venue', hint: 'e.g. Skyline Rooftop, Colombo', icon: Icons.location_on_outlined),
          Gap(14.h),
          _SheetField(controller: _date, label: 'Date & Time', hint: 'e.g. May 10, 2026 · 9PM', icon: Icons.calendar_today_rounded),
          Gap(14.h),
          _SheetField(controller: _price, label: 'Ticket Price', hint: 'e.g. \$15 or Free', icon: Icons.confirmation_number_outlined),
          Gap(14.h),
          _SheetField(controller: _description, label: 'Description', hint: 'Tell people about the event...', icon: Icons.notes_rounded, maxLines: 4),
          Gap(24.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.docId != null ? 'Save Changes' : 'Create Event',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.controller, required this.label, required this.hint, required this.icon, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w700)),
      Gap(6.h),
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        cursorColor: AppTheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 13.sp),
          prefixIcon: maxLines == 1 ? Padding(
            padding: EdgeInsets.only(left: 12.w, right: 8.w),
            child: Icon(icon, color: AppTheme.primaryLight.withValues(alpha: 0.6), size: 18.sp),
          ) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5)),
        ),
      ),
    ]);
  }
}
