import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/domain/event.dart';
import 'package:nightride/services/admin_actions_service.dart';
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
  // 'archived' replaces the legacy 'Cancelled'/'Completed' values, which
  // never existed in the schema.
  static const _filters = ['All', 'Published', 'Draft', 'Archived'];

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

  /// All events, newest first — client-filtered by status below rather than
  /// a second composite index, since the admin panel needs every status in
  /// one place. `isAdmin()` in firestore.rules authorises an unfiltered read
  /// of this collection regardless of each document's own status/owner.
  Stream<List<Event>> get _eventsStream => FirebaseFirestore.instance
      .collection('events')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(Event.fromFirestore).toList());

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

  void _openEdit(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAddEventPage(existing: event),
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
            stream: _eventsStream,
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

  final Stream<List<Event>> stream;
  final String filterStatus;
  final List<String> filters;
  final ValueChanged<String> onFilterSelect;
  final VoidCallback onAdd;
  final void Function(Event event) onEdit;
  final void Function(String id, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(selected: filterStatus, filters: filters, onSelect: onFilterSelect),
        Expanded(
          child: StreamBuilder<List<Event>>(
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
              final all = snap.data ?? const <Event>[];
              final docs = filterStatus == 'All'
                  ? all
                  : all.where((e) => e.status == filterStatus.toLowerCase()).toList();
              if (docs.isEmpty) return _EmptyState(onAdd: onAdd);
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16, AppResponsive.gap(context, 12).clamp(8, 18), 16, AppResponsive.gap(context, 100).clamp(80, 120)),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Gap(AppResponsive.gap(context, 10).clamp(6, 14)),
                itemBuilder: (context, i) {
                  final event = docs[i];
                  return _EventTile(
                    event: event,
                    onEdit: () => onEdit(event),
                    onDelete: () => onDelete(event.id, event.name),
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

class _ApprovalsTab extends StatefulWidget {
  const _ApprovalsTab();

  @override
  State<_ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<_ApprovalsTab> {
  bool _showOrganizers = false;

  // Untriaged applications: submitted, and not yet decided. organizerStatus
  // stays 'none' from document creation (see docs/FIRESTORE_SCHEMA.md) —
  // nothing ever flips it to 'pending' automatically, so both values mean
  // "not yet decided" for this queue.
  Stream<QuerySnapshot<Map<String, dynamic>>> get _pendingStream =>
      FirebaseFirestore.instance
          .collection('users')
          .where('organizerApplication.submitted', isEqualTo: true)
          .orderBy('organizerApplication.submittedAt')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _approvedStream =>
      FirebaseFirestore.instance
          .collection('users')
          .where('organizerStatus', isEqualTo: 'approved')
          .snapshots();

  Future<String?> _promptReason(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reject Application', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason (shown to the applicant)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmRevoke(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Revoke Organizer', style: TextStyle(color: Colors.white)),
        content: Text(
          'Revoke organizer access for "$name"? They will no longer be able to publish events.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return confirmed == true;
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null),
    );
  }

  Future<void> _approve(String uid, String name) async {
    try {
      await adminActionsService.approveOrganizer(uid, displayName: name);
      _notify('Organizer approved');
    } catch (e) {
      _notify('Error: $e', isError: true);
    }
  }

  Future<void> _reject(String uid, String name) async {
    final reason = await _promptReason(context);
    if (reason == null) return;
    try {
      await adminActionsService.rejectOrganizer(uid, reason, displayName: name);
      _notify('Request rejected');
    } catch (e) {
      _notify('Error: $e', isError: true);
    }
  }

  Future<void> _revoke(String uid, String name) async {
    if (!await _confirmRevoke(context, name)) return;
    try {
      await adminActionsService.revokeOrganizer(uid, displayName: name);
      _notify('Organizer revoked');
    } catch (e) {
      _notify('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(
          selected: _showOrganizers ? 'Organizers' : 'Pending',
          filters: const ['Pending', 'Organizers'],
          onSelect: (f) => setState(() => _showOrganizers = f == 'Organizers'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _showOrganizers ? _approvedStream : _pendingStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
              }
              if (snap.hasError) {
                return Center(
                  child: Text('Error loading requests', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                );
              }
              final docs = (snap.data?.docs ?? []).where((d) {
                if (_showOrganizers) return true;
                final status = d.data()['organizerStatus'] as String? ?? 'none';
                return status == 'none' || status == 'pending';
              }).toList();
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: AppResponsive.icon(context, 56), color: Colors.white.withValues(alpha: 0.15)),
                      Gap(AppResponsive.gap(context, 16).clamp(12, 22)),
                      Text(
                        _showOrganizers ? 'No approved organizers' : 'No pending applications',
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
                  final uid = doc.id;
                  final name = data['displayName'] as String? ?? 'Unknown';
                  return _ApprovalCard(
                    data: data,
                    isApproved: _showOrganizers,
                    onApprove: () => _approve(uid, name),
                    onReject: () => _reject(uid, name),
                    onRevoke: () => _revoke(uid, name),
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

// ── Approval card ─────────────────────────────────────────────────────────────

class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    required this.data,
    required this.isApproved,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
  });
  final Map<String, dynamic> data;
  final bool isApproved;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRevoke;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    // organizerApplication.profile — see docs/FIRESTORE_SCHEMA.md.
    final application = (data['organizerApplication'] as Map?) ?? const {};
    final profile = (application['profile'] as Map?) ?? const {};

    final name = data['displayName'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final orgName = profile['orgName'] as String? ?? '';
    final eventTypes = (profile['eventTypes'] as List?)?.cast<String>() ?? const [];
    final eventsPerMonth = profile['eventsPerMonth'];
    final instagram = profile['instagram'] as String? ?? '';
    final website = profile['website'] as String? ?? '';
    final bio = profile['bio'] as String? ?? '';

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
                  if (eventsPerMonth != null) _DetailRow(Icons.bar_chart_rounded, '$eventsPerMonth events/month'),
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
            child: widget.isApproved
                ? _ActionButton(
                    icon: Icons.block_rounded,
                    label: 'Revoke',
                    color: Colors.redAccent,
                    onTap: widget.onRevoke,
                  )
                : Row(
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
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _statusColor(String s) {
    switch (s) {
      case 'published': return Colors.greenAccent;
      case 'draft': return Colors.orangeAccent;
      case 'archived': return Colors.redAccent;
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = event.name.isEmpty ? 'Untitled' : event.name;
    final city = event.city;
    final country = event.countryCode;
    final date = event.isoDate;
    final genre = event.genre;
    final status = event.status;
    final cover = event.coverImage;

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
                            status.toUpperCase(),
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
