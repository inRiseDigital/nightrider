import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/pages/organizer/verify/organizer_capture_screen.dart';
import 'package:nightride/services/organizer_service.dart';
import 'package:nightride/services/organizer_verification_service.dart';

/// The real evidence steps, in the order the checklist shows them.
/// `venueAddress` gates `gps` — an admin must accept it before the on-site
/// GPS check unlocks (see FIRESTORE_SCHEMA.md's ReviewStep docs) — so it
/// leads the list.
enum _StepId { venueAddress, nic, selfie, gps, video }

extension on _StepId {
  String get key => switch (this) {
        _StepId.venueAddress => 'venueAddress',
        _StepId.nic => 'nic',
        _StepId.selfie => 'selfie',
        _StepId.gps => 'gps',
        _StepId.video => 'video',
      };
  String get label => switch (this) {
        _StepId.venueAddress => 'Venue address',
        _StepId.nic => 'ID scan',
        _StepId.selfie => 'Live selfie',
        _StepId.gps => 'On-site GPS check',
        _StepId.video => 'Video walkthrough',
      };
  String get sub => switch (this) {
        _StepId.venueAddress => 'Street address, city, and a pinned location',
        _StepId.nic => 'Front and back of your government ID',
        _StepId.selfie => 'Match your face to your ID',
        _StepId.gps => "Confirm you're at the venue",
        _StepId.video => 'Entrance, bar, and POS terminal',
      };
  IconData get icon => switch (this) {
        _StepId.venueAddress => Icons.storefront_outlined,
        _StepId.nic => Icons.badge_outlined,
        _StepId.selfie => Icons.face_retouching_natural_rounded,
        _StepId.gps => Icons.my_location_rounded,
        _StepId.video => Icons.videocam_outlined,
      };
}

enum _RowStatus { locked, todo, action, submitted, accepted }

/// The organizer verification checklist — reached after applying (or when a
/// returning applicant with a pending/needs_info application logs back in).
/// Real capture + real Storage uploads for nic/selfie/video, real GPS for
/// gps; the "done" state itself is inferred client-side by combining the
/// admin-owned review status with the applicant's own upload claim, since
/// only an admin can ever flip `organizerReview`.
class OrganizerVerifyPage extends ConsumerStatefulWidget {
  const OrganizerVerifyPage({super.key});

  @override
  ConsumerState<OrganizerVerifyPage> createState() => _OrganizerVerifyPageState();
}

class _OrganizerVerifyPageState extends ConsumerState<OrganizerVerifyPage> {
  final Set<String> _busy = {};

  // Local-only mock extra steps (no backing schema — see
  // FIRESTORE_SCHEMA.md:220, "no extraSteps, no postcard or video-call step
  // type"). Debug-only triggers simulate an admin asking for one.
  final List<_ExtraStep> _extraSteps = [];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _run(String stepKey, Future<void> Function() action) async {
    setState(() => _busy.add(stepKey));
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(stepKey));
    }
  }

  Future<void> _handleNic(int attempt) => _run('nic', () async {
        final front = await captureOrganizerPhoto(
          context,
          title: 'ID scan — front',
          prompt: 'Align the front of your ID inside the frame',
          lens: CameraLensDirection.back,
          guide: OrganizerCaptureGuide.corners,
        );
        if (front == null || !mounted) return;
        final back = await captureOrganizerPhoto(
          context,
          title: 'ID scan — back',
          prompt: 'Now the back of your ID',
          lens: CameraLensDirection.back,
          guide: OrganizerCaptureGuide.corners,
        );
        if (back == null) return;

        await ref.read(organizerVerificationServiceProvider).uploadNic(
              uid: _uid,
              attempt: attempt,
              front: front,
              back: back,
            );
        await ref.read(organizerServiceProvider).markStepUploaded(_uid, 'nic');
      });

  Future<void> _handleSelfie(int attempt) => _run('selfie', () async {
        final selfie = await captureOrganizerPhoto(
          context,
          title: 'Live selfie',
          prompt: 'Center your face in the oval',
          lens: CameraLensDirection.front,
          guide: OrganizerCaptureGuide.oval,
        );
        if (selfie == null) return;

        await ref.read(organizerVerificationServiceProvider).uploadSelfie(
              uid: _uid,
              attempt: attempt,
              capture: selfie,
            );
        await ref.read(organizerServiceProvider).markStepUploaded(_uid, 'selfie');
      });

  Future<void> _handleVideo(int attempt) => _run('video', () async {
        final video = await captureOrganizerVideo(
          context,
          title: 'Walkthrough',
          prompt: 'Frame the entrance, the bar, and the POS terminal',
          maxSeconds: 60,
        );
        if (video == null) return;

        await ref.read(organizerVerificationServiceProvider).uploadWalkthrough(
              uid: _uid,
              attempt: attempt,
              video: video,
            );
        await ref.read(organizerServiceProvider).markStepUploaded(_uid, 'video');
      });

  void _handleVenueAddress(Map<String, dynamic>? draft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _VenueAddressSheet(
        draft: draft,
        onSubmit: (address, city, countryCode, geo) => _run('venueAddress', () async {
          await ref.read(organizerServiceProvider).submitVenueAddress(
                _uid,
                address: address,
                city: city,
                countryCode: countryCode,
                geo: geo,
              );
        }),
      ),
    );
  }

  Future<void> _handleGps(int attempt) => _run('gps', () async {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw 'location permission denied';
        }
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw 'turn on location services and try again';
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );

        await ref.read(organizerServiceProvider).appendGpsObservation(
              _uid,
              point: GeoPoint(position.latitude, position.longitude),
              accuracyM: position.accuracy,
              mocked: position.isMocked,
              attempt: attempt,
            );
      });

  void _openExtraStep(_ExtraStep step) {
    switch (step.type) {
      case _ExtraType.moreInfo:
        _showExtraPhotoSheet(step);
      case _ExtraType.postcard:
        _showPostcardSheet(step);
      case _ExtraType.videoCall:
        _showVideoCallSheet(step);
    }
  }

  void _showExtraPhotoSheet(_ExtraStep step) async {
    final photo = await captureOrganizerPhoto(
      context,
      title: 'Business license',
      prompt: 'Photograph your business license',
      lens: CameraLensDirection.back,
      guide: OrganizerCaptureGuide.corners,
    );
    if (photo == null || !mounted) return;
    setState(() => step.status = _ExtraStatus.done);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business license photo sent for review.')),
    );
  }

  void _showPostcardSheet(_ExtraStep step) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mailed code', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Enter the six-digit code from the postcard mailed to your venue.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 20, letterSpacing: 6),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppTheme.darkGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().length != 6) return;
                Navigator.of(sheetContext).pop();
                setState(() => step.status = _ExtraStatus.done);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Mailed code verified.')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Verify code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoCallSheet(_ExtraStep step) {
    const slots = ['Tue 2:00pm', 'Wed 11:00am', 'Thu 4:00pm'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Live video call', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Pick a time for your call with an admin.', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            ...slots.map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: AppTheme.darkGray,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(slot, style: const TextStyle(color: Colors.white)),
                    trailing: const Text('30 min', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        step.status = _ExtraStatus.scheduled;
                        step.scheduledSlot = slot;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Video call scheduled for $slot.')),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _addExtraStep(_ExtraType type) {
    if (_extraSteps.any((s) => s.type == type)) return;
    setState(() => _extraSteps.add(_ExtraStep(type: type)));
    const messages = {
      _ExtraType.moreInfo: 'An admin requested a clearer business license photo.',
      _ExtraType.postcard: 'A verification postcard is on its way to your venue.',
      _ExtraType.videoCall: 'An admin asked for a live video call instead.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messages[type]!)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final organizerService = ref.watch(organizerServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: organizerService.watchReviewSteps(uid),
        builder: (context, reviewSnap) {
          final review = reviewSnap.data ?? const {};
          return StreamBuilder<Map<String, dynamic>>(
            stream: organizerService.watchApplicationSteps(uid),
            builder: (context, appSnap) {
              final applied = appSnap.data ?? const {};
              return _buildBody(context, review, applied);
            },
          );
        },
      ),
    );
  }

  _RowStatus _statusFor(_StepId id, Map<String, dynamic> review, Map<String, dynamic> applied) {
    final reviewStep = (review[id.key] as Map?) ?? const {};
    final status = reviewStep['status'] as String? ?? 'active';
    if (status == 'accepted') return _RowStatus.accepted;
    if (status == 'pending') return _RowStatus.locked;
    if (status == 'needs_info') return _RowStatus.action;

    if (id == _StepId.gps) {
      final attempts = (applied['gps'] as Map?)?['attempts'];
      final currentAttempt = reviewStep['attempt'] as int? ?? 0;
      final hasCurrent = attempts is List &&
          attempts.any((a) => a is Map && a['attempt'] == currentAttempt);
      return hasCurrent ? _RowStatus.submitted : _RowStatus.todo;
    }

    if (id == _StepId.venueAddress) {
      final address = (applied['venueAddress'] as Map?)?['address'] as String?;
      return (address != null && address.isNotEmpty) ? _RowStatus.submitted : _RowStatus.todo;
    }

    final uploaded = (applied[id.key] as Map?)?['uploaded'] == true;
    return uploaded ? _RowStatus.submitted : _RowStatus.todo;
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> review,
    Map<String, dynamic> applied,
  ) {
    final rows = _StepId.values.map((id) {
      final reviewStep = (review[id.key] as Map?) ?? const {};
      return (
        id: id,
        status: _statusFor(id, review, applied),
        attempt: reviewStep['attempt'] as int? ?? 0,
        note: reviewStep['note'] as String? ?? '',
      );
    }).toList();

    final doneCount = rows.where((r) => r.status == _RowStatus.accepted || r.status == _RowStatus.submitted).length +
        _extraSteps.where((s) => s.status != _ExtraStatus.active).length;
    final totalCount = rows.length + _extraSteps.length;
    final pct = totalCount == 0 ? 0 : ((doneCount / totalCount) * 100).round();

    final next = rows.firstWhere(
      (r) => r.status == _RowStatus.todo || r.status == _RowStatus.action,
      orElse: () => rows.first,
    );
    final allRealDone = rows.every((r) => r.status == _RowStatus.accepted || r.status == _RowStatus.submitted);
    final anyExtraActive = _extraSteps.any((s) => s.status == _ExtraStatus.active);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$doneCount of $totalCount steps complete',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('$pct%', style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: totalCount == 0 ? 0 : doneCount / totalCount,
                minHeight: 4,
                backgroundColor: AppTheme.darkGray,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            ...rows.map((r) => _StepRow(
                  icon: r.id.icon,
                  label: r.id.label,
                  sub: r.note.isNotEmpty ? r.note : r.id.sub,
                  status: r.status,
                  busy: _busy.contains(r.id.key),
                  onTap: r.status == _RowStatus.locked
                      ? null
                      : () => switch (r.id) {
                            _StepId.venueAddress => _handleVenueAddress(
                                applied['venueAddress'] as Map<String, dynamic>?,
                              ),
                            _StepId.nic => _handleNic(r.attempt),
                            _StepId.selfie => _handleSelfie(r.attempt),
                            _StepId.gps => _handleGps(r.attempt),
                            _StepId.video => _handleVideo(r.attempt),
                          },
                )),
            ..._extraSteps.map((s) => _StepRow(
                  icon: switch (s.type) {
                    _ExtraType.moreInfo => Icons.priority_high_rounded,
                    _ExtraType.postcard => Icons.mail_outline_rounded,
                    _ExtraType.videoCall => Icons.call_outlined,
                  },
                  label: switch (s.type) {
                    _ExtraType.moreInfo => 'Business license',
                    _ExtraType.postcard => 'Mailed code',
                    _ExtraType.videoCall => 'Live video call',
                  },
                  sub: s.status == _ExtraStatus.scheduled
                      ? 'Scheduled for ${s.scheduledSlot}'
                      : switch (s.type) {
                          _ExtraType.moreInfo => 'An admin asked for a clearer photo',
                          _ExtraType.postcard => 'Enter the code from your postcard',
                          _ExtraType.videoCall => 'Schedule a call with an admin',
                        },
                  status: switch (s.status) {
                    _ExtraStatus.active => _RowStatus.action,
                    _ExtraStatus.scheduled => _RowStatus.submitted,
                    _ExtraStatus.done => _RowStatus.accepted,
                  },
                  busy: false,
                  onTap: s.status == _ExtraStatus.done ? null : () => _openExtraStep(s),
                )),
            const SizedBox(height: 16),
            _OverallBanner(
              allDone: allRealDone && !anyExtraActive,
              actionNeeded: anyExtraActive || rows.any((r) => r.status == _RowStatus.action),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderGray),
              const SizedBox(height: 8),
              const Text('DEBUG — SIMULATE ADMIN REQUEST',
                  style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _DebugChip(label: 'more info', onTap: () => _addExtraStep(_ExtraType.moreInfo)),
                _DebugChip(label: 'postcard', onTap: () => _addExtraStep(_ExtraType.postcard)),
                _DebugChip(label: 'video call', onTap: () => _addExtraStep(_ExtraType.videoCall)),
              ]),
            ],
          ],
        ),
        if (!allRealDone || anyExtraActive)
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(doneCount == 0 ? 'Start verifying' : 'Continue: ${next.id.label}'),
              onPressed: () => switch (next.id) {
                _StepId.venueAddress => _handleVenueAddress(
                    applied['venueAddress'] as Map<String, dynamic>?,
                  ),
                _StepId.nic => _handleNic(next.attempt),
                _StepId.selfie => _handleSelfie(next.attempt),
                _StepId.gps => _handleGps(next.attempt),
                _StepId.video => _handleVideo(next.attempt),
              },
            ),
          )
        else
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OrganizerShellPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGray,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text("I'll finish this later", style: TextStyle(color: Colors.white70)),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.status,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final _RowStatus status;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg, chipLabel) = switch (status) {
      _RowStatus.accepted => (const Color(0xFF0F4F31), const Color(0xFFC8EBD5), 'Done'),
      _RowStatus.submitted => (const Color(0xFF005046), const Color(0xFF9EF2E4), 'Submitted'),
      _RowStatus.action => (const Color(0xFF6B3E00), const Color(0xFFFFDDB3), 'Action'),
      _RowStatus.locked => (AppTheme.darkGray, Colors.white38, 'Locked'),
      _RowStatus.todo => (AppTheme.darkGray, Colors.white60, 'To do'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(status == _RowStatus.accepted ? Icons.check_rounded : icon, color: chipFg, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(chipLabel.toUpperCase(),
                      style: TextStyle(color: chipFg, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.allDone, required this.actionNeeded});
  final bool allDone;
  final bool actionNeeded;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, title, detail) = actionNeeded
        ? (const Color(0xFF6B3E00), const Color(0xFFFFDDB3), 'Action required',
            'An admin needs more from you before approving your venue.')
        : allDone
            ? (const Color(0xFF005046), const Color(0xFF9EF2E4), 'Under review',
                "You're all set. We'll notify you as soon as an admin approves your venue.")
            : (const Color(0xFF8C0035), const Color(0xFFFFD9DF), 'Verification in progress',
                'Finish the remaining steps to submit your application.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderGray, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ),
    );
  }
}

/// Street address/city/country typed form + a "use current location" GPS
/// pin — the mobile counterpart of the webpanel's venue-address step. Text
/// stays manual (matches web); only the lat/long comes from the device,
/// since a manually-typed pin can't be checked against
/// `Position.isMocked` the way a live GPS fix can.
class _VenueAddressSheet extends StatefulWidget {
  const _VenueAddressSheet({required this.draft, required this.onSubmit});

  final Map<String, dynamic>? draft;
  final void Function(String address, String city, String countryCode, GeoPoint? geo) onSubmit;

  @override
  State<_VenueAddressSheet> createState() => _VenueAddressSheetState();
}

class _VenueAddressSheetState extends State<_VenueAddressSheet> {
  late final _addressCtrl = TextEditingController(text: widget.draft?['address'] as String? ?? '');
  late final _cityCtrl = TextEditingController(text: widget.draft?['city'] as String? ?? '');
  late final _countryCtrl = TextEditingController(text: widget.draft?['countryCode'] as String? ?? '');
  GeoPoint? _geo;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.draft?['geo'];
    if (existing is GeoPoint) _geo = existing;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission denied.';
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Turn on location services and try again.';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      if (!mounted) return;
      setState(() => _geo = GeoPoint(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() {
    final address = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final countryCode = _countryCtrl.text.trim().toUpperCase();
    if (address.isEmpty) {
      setState(() => _error = "Enter the venue's street address.");
      return;
    }
    if (city.isEmpty) {
      setState(() => _error = "Enter the venue's city.");
      return;
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      setState(() => _error = 'Enter a 2-letter country code, for example AE.');
      return;
    }
    widget.onSubmit(address, city, countryCode, _geo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Venue address', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _sheetField('Street address', _addressCtrl),
          const SizedBox(height: 12),
          _sheetField('City', _cityCtrl),
          const SizedBox(height: 12),
          _sheetField('Country code (ISO-2)', _countryCtrl, maxLength: 2),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(_geo == null
                ? 'Use current location'
                : 'Pinned: ${_geo!.latitude.toStringAsFixed(5)}, ${_geo!.longitude.toStringAsFixed(5)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: AppTheme.borderGray),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Save address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController controller, {int? maxLength}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppTheme.darkGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}

enum _ExtraType { moreInfo, postcard, videoCall }
enum _ExtraStatus { active, scheduled, done }

class _ExtraStep {
  _ExtraStep({required this.type, this.status = _ExtraStatus.active, this.scheduledSlot});
  final _ExtraType type;
  _ExtraStatus status;
  String? scheduledSlot;
}
