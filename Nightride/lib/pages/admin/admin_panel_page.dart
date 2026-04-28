import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/services/firestore_service.dart';
import 'admin_add_event_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  String _filterStatus = 'All';
  static const _filters = ['All', 'Published', 'Draft', 'Cancelled', 'Completed'];

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream =>
      firestoreService.streamEvents(
        status: _filterStatus == 'All' ? null : _filterStatus,
      );

  Future<void> _deleteEvent(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "$name"? This cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestoreService.deleteEvent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted')),
        );
      }
    }
  }

  void _openAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminAddEventPage()),
    );
  }

  void _openEdit(String id, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAddEventPage(eventId: id, existingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppTheme.accent, size: 28),
            tooltip: 'Add Event',
            onPressed: _openAdd,
          ),
          Gap(8.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _filterStatus,
            filters: _filters,
            onSelect: (f) => setState(() => _filterStatus = f),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading events',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(onAdd: _openAdd);
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Gap(10.h),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    return _EventTile(
                      id: doc.id,
                      data: doc.data(),
                      onEdit: () => _openEdit(doc.id, doc.data()),
                      onDelete: () => _deleteEvent(doc.id, doc.data()['name'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  final String selected;
  final List<String> filters;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: SizedBox(
        height: 36.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => Gap(8.w),
          itemBuilder: (_, i) {
            final f = filters[i];
            final active = f == selected;
            return GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.accent
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(
                    color: active
                        ? AppTheme.accent
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _statusColor(String? s) {
    switch (s) {
      case 'Published': return Colors.greenAccent;
      case 'Draft': return Colors.orangeAccent;
      case 'Cancelled': return Colors.redAccent;
      case 'Completed': return Colors.blueAccent;
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Untitled';
    final city = data['city'] as String? ?? '';
    final country = data['country'] as String? ?? '';
    final date = data['date'] as String? ?? '';
    final genre = data['genre'] as String? ?? '';
    final status = data['status'] as String? ?? 'Draft';
    final cover = data['cover_image'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cover.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                child: Image.network(
                  cover,
                  width: 90.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90.w,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white24,
                      size: 28.sp,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 90.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                ),
                child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 28.sp),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(
                              color: _statusColor(status).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(5.h),
                    if (genre.isNotEmpty)
                      Text(
                        genre.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.accent.withValues(alpha: 0.8),
                        ),
                      ),
                    Gap(4.h),
                    if (city.isNotEmpty || country.isNotEmpty)
                      _MetaRow(
                        icon: Icons.location_on_rounded,
                        text: [city, country].where((s) => s.isNotEmpty).join(', '),
                      ),
                    if (date.isNotEmpty) ...[
                      Gap(3.h),
                      _MetaRow(icon: Icons.calendar_today_rounded, text: date),
                    ],
                    Gap(8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: Colors.white70,
                          onTap: onEdit,
                        ),
                        Gap(8.w),
                        _ActionButton(
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          color: Colors.redAccent,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12.sp, color: Colors.white38),
        Gap(4.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.sp, color: color),
            Gap(4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64.sp,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Gap(16.h),
          Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Gap(8.h),
          Text(
            'Tap the button below to add your first event',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Gap(24.h),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Event',
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
