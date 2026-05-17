// lib/pages/live_hub_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/providers/live_hub_providers.dart';

class LiveHubPage extends ConsumerStatefulWidget {
  const LiveHubPage({super.key});

  @override
  ConsumerState<LiveHubPage> createState() => _LiveHubPageState();
}

class _LiveHubPageState extends ConsumerState<LiveHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCountryFilter(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ClubUpdatesTab(),
                  _UserReportsTab(),
                  _SocialTrackingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Gap(12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Hub',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                Text('Real-time nightlife updates',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.7),
                        blurRadius: 4)],
                  ),
                ),
                const Gap(6),
                const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryFilter() {
    final countries = ref.watch(liveHubAvailableCountriesProvider);
    final selected = ref.watch(liveHubCountryProvider);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'ALL',
            active: selected == 'ALL',
            onTap: () =>
                ref.read(liveHubCountryProvider.notifier).state = 'ALL',
          ),
          ...countries.map((country) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: country,
                  active: selected == country,
                  onTap: () =>
                      ref.read(liveHubCountryProvider.notifier).state = country,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.45), width: 1),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.nightlife_rounded, size: 16), text: 'Clubs'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 16), text: 'Reports'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 16), text: 'Social'),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Club Updates ────────────────────────────────────────────────────────

class _ClubUpdatesTab extends ConsumerWidget {
  const _ClubUpdatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clubUpdatesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No club updates yet', style: TextStyle(color: Colors.white38)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Gap(14),
          itemBuilder: (context, i) => _ClubCard(club: items[i]),
        );
      },
    );
  }
}

class _ClubCard extends StatelessWidget {
  final ClubUpdate club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: club.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: Colors.white.withValues(alpha: 0.04)),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.white.withValues(alpha: 0.04),
                    child: const Icon(Icons.image_not_supported_rounded,
                        color: Colors.white24),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(top: 10, left: 12, child: _StatusBadge(status: club.status)),
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('🕐 ${club.lastUpdated}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 12, right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(club.clubName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const Gap(8),
                      Text('📍 ${club.city}, ${club.country}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.people_rounded,
                        label: _crowdLabel(club.crowdLevel),
                        color: _crowdColor(club.crowdLevel)),
                    const Gap(8),
                    _InfoChip(
                        icon: Icons.queue_rounded,
                        label: _queueLabel(club.queueStatus),
                        color: _queueColor(club.queueStatus)),
                    const Gap(8),
                    _InfoChip(
                        icon: Icons.confirmation_number_rounded,
                        label: club.ticketsAvailable ? 'Tickets' : 'Sold Out',
                        color: club.ticketsAvailable
                            ? Colors.greenAccent
                            : Colors.redAccent),
                  ],
                ),
                if (club.tonightDj != null) ...[
                  const Gap(10),
                  Row(
                    children: [
                      const Icon(Icons.headphones_rounded,
                          color: AppTheme.accent, size: 14),
                      const Gap(6),
                      Expanded(
                        child: Text('Tonight: ${club.tonightDj}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
                if (club.offer != null) ...[
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer_rounded,
                            color: AppTheme.primary, size: 13),
                        const Gap(6),
                        Flexible(
                          child: Text(club.offer!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
                const Gap(10),
                _CrowdBar(level: club.crowdLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _crowdLabel(CrowdLevel l) => switch (l) {
        CrowdLevel.empty => 'Empty',
        CrowdLevel.quiet => 'Quiet',
        CrowdLevel.moderate => 'Moderate',
        CrowdLevel.busy => 'Busy',
        CrowdLevel.packed => 'Packed',
      };

  Color _crowdColor(CrowdLevel l) => switch (l) {
        CrowdLevel.empty => Colors.white38,
        CrowdLevel.quiet => Colors.lightBlueAccent,
        CrowdLevel.moderate => Colors.yellowAccent,
        CrowdLevel.busy => Colors.orangeAccent,
        CrowdLevel.packed => Colors.redAccent,
      };

  String _queueLabel(QueueStatus q) => switch (q) {
        QueueStatus.noQueue => 'No Queue',
        QueueStatus.short => 'Short Queue',
        QueueStatus.moderate => 'Queue',
        QueueStatus.long => 'Long Queue',
        QueueStatus.closed => 'Closed',
      };

  Color _queueColor(QueueStatus q) => switch (q) {
        QueueStatus.noQueue => Colors.greenAccent,
        QueueStatus.short => Colors.lightGreenAccent,
        QueueStatus.moderate => Colors.yellowAccent,
        QueueStatus.long => Colors.orangeAccent,
        QueueStatus.closed => Colors.redAccent,
      };
}

// ── Tab 2: User Reports ────────────────────────────────────────────────────────

class _UserReportsTab extends ConsumerStatefulWidget {
  const _UserReportsTab();

  @override
  ConsumerState<_UserReportsTab> createState() => _UserReportsTabState();
}

class _UserReportsTabState extends ConsumerState<_UserReportsTab> {
  final List<String> _tags = [
    '🔥 Fire', '😤 Packed', '😎 Chill', '🎵 Music Good', '🚨 Avoid',
  ];
  String? _selectedTag;
  int _vibeRating = 0;
  bool _submitting = false;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedTag == null || _vibeRating == 0) return;
    setState(() => _submitting = true);
    try {
      await ref.read(liveHubServiceProvider).submitReport(
        clubName: 'Your Club',
        city: 'Your City',
        country: 'Sri Lanka',
        username: 'You',
        avatarUrl: 'https://i.pravatar.cc/150?img=70',
        tag: _selectedTag!,
        vibeRating: _vibeRating,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      setState(() {
        _selectedTag = null;
        _vibeRating = 0;
        _commentCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Report submitted! 🙌'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(userReportsProvider);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit a Live Report',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              const Gap(10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final active = _selectedTag == tag;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTag = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppTheme.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
              const Gap(10),
              Row(
                children: [
                  const Text('Vibe:',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Gap(8),
                  ...List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _vibeRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i < _vibeRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < _vibeRating
                              ? Colors.amberAccent
                              : Colors.white24,
                          size: 22,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const Gap(10),
              TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const Gap(10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedTag != null && _vibeRating > 0 && !_submitting)
                      ? _submitReport
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Report',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const Gap(4),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.white54))),
            data: (reports) {
              if (reports.isEmpty) {
                return const Center(
                  child: Text('No reports yet. Be the first!',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (context, i) => _ReportCard(report: reports[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  final UserReport report;
  const _ReportCard({required this.report});

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _upvoted = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.report.avatarUrl),
                backgroundColor: Colors.white12,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.report.username,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${widget.report.clubName} · ${widget.report.city} · ${widget.report.timeAgo}',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (!_upvoted) {
                    ref
                        .read(liveHubServiceProvider)
                        .upvoteReport(widget.report.id);
                  }
                  setState(() => _upvoted = !_upvoted);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _upvoted
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _upvoted
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _upvoted
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        color: _upvoted ? AppTheme.primary : Colors.white38,
                        size: 13,
                      ),
                      const Gap(4),
                      Text(
                        '${widget.report.upvotes + (_upvoted ? 1 : 0)}',
                        style: TextStyle(
                            color: _upvoted ? AppTheme.primary : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Text(widget.report.tag,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const Gap(8),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < widget.report.vibeRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < widget.report.vibeRating
                        ? Colors.amberAccent
                        : Colors.white12,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (widget.report.comment != null) ...[
            const Gap(8),
            Text(widget.report.comment!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Tab 3: Social Tracking ─────────────────────────────────────────────────────

class _SocialTrackingTab extends ConsumerWidget {
  const _SocialTrackingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(socialEventsProvider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white54))),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No events yet',
                style: TextStyle(color: Colors.white38)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Gap(14),
          itemBuilder: (context, i) => _SocialEventCard(event: items[i]),
        );
      },
    );
  }
}

class _SocialEventCard extends StatelessWidget {
  final SocialEvent event;
  const _SocialEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.white.withValues(alpha: 0.04)),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  if (event.isTrending)
                    Positioned(
                      top: 10, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_rounded,
                                color: Colors.orangeAccent, size: 12),
                            Gap(4),
                            Text('TRENDING',
                                style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('📡 ${event.source}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const Gap(4),
                Text('${event.clubName} · ${event.city}, ${event.country}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Gap(10),
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: event.date,
                        color: AppTheme.primary),
                    const Gap(8),
                    _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: event.time,
                        color: Colors.white54),
                  ],
                ),
                if (event.djName != null) ...[
                  const Gap(8),
                  Row(
                    children: [
                      const Icon(Icons.headphones_rounded,
                          color: AppTheme.accent, size: 14),
                      const Gap(6),
                      Flexible(
                        child: Text(event.djName!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Popularity',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                          const Gap(4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.popularityScore / 100,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event.popularityScore > 85
                                    ? Colors.orangeAccent
                                    : AppTheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Text('${event.popularityScore}%',
                        style: TextStyle(
                            color: event.popularityScore > 85
                                ? Colors.orangeAccent
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ClubStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ClubStatus.open => ('OPEN', Colors.greenAccent),
      ClubStatus.closed => ('CLOSED', Colors.redAccent),
      ClubStatus.vipOnly => ('VIP ONLY', Colors.amberAccent),
      ClubStatus.soldOut => ('SOLD OUT', Colors.redAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const Gap(4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CrowdBar extends StatelessWidget {
  final CrowdLevel level;
  const _CrowdBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final filled = level.index + 1;
    final total = CrowdLevel.values.length;
    final color = switch (level) {
      CrowdLevel.empty => Colors.white24,
      CrowdLevel.quiet => Colors.lightBlueAccent,
      CrowdLevel.moderate => Colors.yellowAccent,
      CrowdLevel.busy => Colors.orangeAccent,
      CrowdLevel.packed => Colors.redAccent,
    };
    return Row(
      children: [
        const Text('Crowd',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const Gap(10),
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: i < filled
                        ? color
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
