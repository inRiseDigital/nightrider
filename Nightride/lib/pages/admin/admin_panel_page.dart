import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/services/firestore_service.dart';
import 'admin_add_event_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}


class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _filterStatus = 'All';
  static const _filters = ['All', 'Published', 'Draft', 'Cancelled', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
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
          const Gap(8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'Approvals'),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _openAdd,
                backgroundColor: AppTheme.accent,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventsTab(
            stream: _stream,
            filterStatus: _filterStatus,
            filters: _filters,
            onFilterSelect: (f) => setState(() => _filterStatus = f),
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _deleteEvent,
          ),
          const _ApprovalsTab(),
        ],
      ),
    );
  }
}

// ── Events tab ────────────────────────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.stream,
    required this.filterStatus,
    required this.filters,
    required this.onFilterSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String filterStatus;
  final List<String> filters;
  final ValueChanged<String> onFilterSelect;
  final VoidCallback onAdd;
  final void Function(String id, Map<String, dynamic> data) onEdit;
  final void Function(String id, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(selected: filterStatus, filters: filters, onSelect: onFilterSelect),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
              }
              if (snap.hasError) {
                return Center(
                  child: Text('Error loading events', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _EmptyState(onAdd: onAdd);
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16, AppResponsive.gap(context, 12).clamp(8, 18), 16, AppResponsive.gap(context, 100).clamp(80, 120)),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Gap(AppResponsive.gap(context, 10).clamp(6, 14)),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  return _EventTile(
                    id: doc.id,
                    data: doc.data(),
                    onEdit: () => onEdit(doc.id, doc.data()),
                    onDelete: () => onDelete(doc.id, doc.data()['name'] ?? ''),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Approvals tab ─────────────────────────────────────────────────────────────

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _pendingStream =>
      FirebaseFirestore.instance
          .collection('organizer_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .snapshots();

  Future<void> _approve(BuildContext context, String uid) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.update(db.collection('users').doc(uid), {'isOrganizer': true});
    batch.update(db.collection('organizer_requests').doc(uid), {'status': 'approved'});
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizer approved')),
      );
    }
  }

  Future<void> _reject(BuildContext context, String uid) async {
    await FirebaseFirestore.instance
        .collection('organizer_requests')
        .doc(uid)
        .update({'status': 'rejected'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pendingStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error loading requests', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: AppResponsive.icon(context, 56), color: Colors.white.withValues(alpha: 0.15)),
                Gap(AppResponsive.gap(context, 16).clamp(12, 22)),
                Text(
                  'No pending applications',
                  style: TextStyle(fontSize: AppResponsive.font(context, 16), fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.35)),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(AppResponsive.gap(context, 16).clamp(12, 20)),
          itemCount: docs.length,
          separatorBuilder: (_, __) => Gap(AppResponsive.gap(context, 12).clamp(8, 16)),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final uid = data['uid'] as String? ?? doc.id;
            return _ApprovalCard(
              data: data,
              uid: uid,
              onApprove: () => _approve(context, uid),
              onReject: () => _reject(context, uid),
            );
          },
        );
      },
    );
  }
}

// ── Approval card ─────────────────────────────────────────────────────────────

class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    required this.data,
    required this.uid,
    required this.onApprove,
    required this.onReject,
  });
  final Map<String, dynamic> data;
  final String uid;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data['displayName'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? '';
    final orgName = data['orgName'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final eventTypes = (data['eventTypes'] as List?)?.cast<String>() ?? [];
    final eventsPerMonth = data['eventsPerMonth'] as String? ?? '';
    final instagram = data['instagram'] as String? ?? '';
    final website = data['website'] as String? ?? '';
    final bio = data['bio'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — always visible
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, color: AppTheme.accent, size: AppResponsive.icon(context, 22)),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14), fontWeight: FontWeight.w700),
                      ),
                      if (orgName.isNotEmpty)
                        Text(
                          orgName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.accent, fontSize: AppResponsive.font(context, 12), fontWeight: FontWeight.w600),
                        ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white38, fontSize: AppResponsive.font(context, 11)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),

          // Expandable details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                  const Gap(12),
                  if (city.isNotEmpty) _DetailRow(Icons.location_on_rounded, city),
                  if (phone.isNotEmpty) _DetailRow(Icons.phone_outlined, phone),
                  if (instagram.isNotEmpty) _DetailRow(Icons.link_rounded, instagram),
                  if (website.isNotEmpty) _DetailRow(Icons.language_rounded, website),
                  if (eventsPerMonth.isNotEmpty) _DetailRow(Icons.bar_chart_rounded, '$eventsPerMonth events/month'),
                  if (eventTypes.isNotEmpty) ...[
                    const Gap(8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: eventTypes.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(t, style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 11), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const Gap(10),
                    Text(
                      bio,
                      style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12), height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close_rounded,
                    label: 'Reject',
                    color: Colors.redAccent,
                    onTap: widget.onReject,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_rounded,
                    label: 'Approve',
                    color: Colors.greenAccent,
                    onTap: widget.onApprove,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white38),
          const Gap(6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white60, fontSize: AppResponsive.font(context, 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

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
      padding: EdgeInsets.fromLTRB(16, AppResponsive.gap(context, 8).clamp(6, 12), 16, AppResponsive.gap(context, 12).clamp(8, 16)),
      child: SizedBox(
        height: AppResponsive.gap(context, 36).clamp(30, 44),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (_, i) {
            final f = filters[i];
            final active = f == selected;
            return GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.accent
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active
                        ? AppTheme.accent
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 12),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cover.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: Image.network(
                  cover,
                  width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white24,
                      size: AppResponsive.icon(context, 28),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                child: Icon(Icons.music_note_rounded, color: Colors.white24, size: AppResponsive.icon(context, 28)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                              fontSize: AppResponsive.font(context, 14),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _statusColor(status).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: AppResponsive.font(context, 10),
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(AppResponsive.gap(context, 5).clamp(3, 8)),
                    if (genre.isNotEmpty)
                      Text(
                        genre.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppResponsive.font(context, 10),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.accent.withValues(alpha: 0.8),
                        ),
                      ),
                    Gap(4),
                    if (city.isNotEmpty || country.isNotEmpty)
                      _MetaRow(
                        icon: Icons.location_on_rounded,
                        text: [city, country].where((s) => s.isNotEmpty).join(', '),
                      ),
                    if (date.isNotEmpty) ...[
                      Gap(3),
                      _MetaRow(icon: Icons.calendar_today_rounded, text: date),
                    ],
                    Gap(AppResponsive.gap(context, 8).clamp(6, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: Colors.white70,
                          onTap: onEdit,
                        ),
                        Gap(8),
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
        Icon(icon, size: AppResponsive.icon(context, 12), color: Colors.white38),
        const Gap(4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppResponsive.font(context, 11.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppResponsive.icon(context, 13), color: color),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppResponsive.font(context, 11.5),
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
            size: AppResponsive.icon(context, 64),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Gap(AppResponsive.gap(context, 16).clamp(12, 22)),
          Text(
            'No events yet',
            style: TextStyle(
              fontSize: AppResponsive.font(context, 18),
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Gap(AppResponsive.gap(context, 8).clamp(6, 12)),
          Text(
            'Tap the button below to add your first event',
            style: TextStyle(
              fontSize: AppResponsive.font(context, 13),
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Gap(AppResponsive.gap(context, 24).clamp(18, 32)),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
