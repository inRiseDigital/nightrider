import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_session.dart';
import '../data/services/chat_service.dart' show ChatService, ChatStreamHandle;
import '../data/services/chat_history_service.dart';
import '../providers/app_nav_provider.dart';
import 'venue_search_detail_page.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const _kBlack    = Color(0xFF070707);
const _kCream    = Color(0xFFF3EAD6);
const _kNeonLime = Color(0xFFDFFF2F);
const _kHotPink  = Color(0xFFFF3D73);
const _kSurface  = Color(0xFF151515);
const _kBorderGray = Color(0xFF333333);
const _kMuted    = Color(0xFF9EAFA0);
const _kWhite    = Color(0xFFfafafa);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  final ChatHistoryService _historyService = ChatHistoryService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  String? _statusText;
  ChatStreamHandle? _streamHandle;

  // Typing animation
  Timer? _typingTimer;
  String _typingTarget = '';
  int _typedLength = 0;
  String? _typingMessageId;
  double? _userLatitude;
  double? _userLongitude;
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  StreamSubscription<List<ChatSession>>? _sessionsSub;

  // When the user browses a past session while the live response is running,
  // we park the past session here without cancelling the stream.
  List<ChatMessage>? _viewingMessages;

  List<ChatMessage> get _displayMessages => _viewingMessages ?? _messages;
  bool get _isViewingLive => _viewingMessages == null;

  void _returnToLiveSession() {
    setState(() {
      _viewingMessages = null;
    });
    _scrollToBottom();
  }

  List<String> _suggestions = [
    "What's happening tonight?",
    "Find Techno parties",
    "Show me rave parties",
    "Weekend schedule",
  ];

  String get _currentUserName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first.toUpperCase();
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email!.split('@').first.toUpperCase();
    }
    return 'YOU';
  }

  // Whether the last assistant message looks like a plan (has multiple items / itinerary markers)
  bool get _hasPlan {
    if (_messages.isEmpty) return false;
    final lastAssistant = _messages.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => ChatMessage(content: '', role: 'assistant'),
    );
    final c = lastAssistant.content;
    return c.contains('**') && (c.contains('\n-') || c.contains('\n1.') || c.contains('##'));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationStatus();
    _sessionsSub = _historyService.sessionsStream().listen((sessions) {
      if (mounted) setState(() => _sessions = sessions);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userLatitude == null) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.location_on, color: _kBlack),
          const SizedBox(width: 8),
          Text(
            "Location on! ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(color: _kBlack, fontWeight: FontWeight.w600),
          ),
        ]),
        backgroundColor: _kNeonLime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_messages.isNotEmpty) {
      _historyService.upsertSession(_currentSessionId, List.from(_messages));
    }
    _sessionsSub?.cancel();
    _typingTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    if (_messages.isEmpty) return;
    _currentSessionId = await _historyService.upsertSession(_currentSessionId, _messages);
  }

  Future<void> _startNewChat() async {
    _streamHandle?.cancel();
    _streamHandle = null;
    _typingTimer?.cancel();
    await _autoSave();
    if (!mounted) return;
    setState(() {
      _viewingMessages = null;
      _messages.clear();
      _currentSessionId = null;
      _isLoading = false;
      _statusText = null;
      _typingMessageId = null;
      _suggestions = [
        "What's happening tonight?",
        "Find Techno parties",
        "Show me rave parties",
        "Weekend schedule",
      ];
    });
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _loadSession(ChatSession session) async {
    if (_isLoading) {
      if (!mounted) return;
      setState(() {
        _viewingMessages = List<ChatMessage>.from(session.messages);
      });
      Navigator.of(context).pop();
      return;
    }
    _typingTimer?.cancel();
    await _autoSave();
    if (!mounted) return;
    setState(() {
      _viewingMessages = null;
      _currentSessionId = session.id;
      _messages
        ..clear()
        ..addAll(session.messages);
      _isLoading = false;
      _statusText = null;
      _typingMessageId = null;
    });
    Navigator.of(context).pop();
    _scrollToBottom();
  }

  Future<void> _deleteSession(String id) async {
    await _historyService.deleteSession(id);
    if (id == _currentSessionId) {
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _currentSessionId = null;
        _suggestions = [
          "What's happening tonight?",
          "Find Techno parties",
          "Show me rave parties",
          "Weekend schedule",
        ];
      });
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _clearCurrentChat() async {
    if (_messages.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorderGray),
        ),
        title: Text('Clear chat?',
            style: GoogleFonts.anton(color: _kWhite, fontSize: 20)),
        content: Text(
          'This will save the current chat to history and start fresh.',
          style: GoogleFonts.poppins(color: _kMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.poppins(
                    color: _kNeonLime, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _startNewChat();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({String? text}) async {
    String messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    final isLocationRequest = messageText.toLowerCase().contains('location') ||
        messageText.toLowerCase().contains('near me') ||
        messageText.toLowerCase().contains('share my');
    final gpsTimeout = isLocationRequest ? 8 : 3;

    if (_userLatitude == null || isLocationRequest) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(Duration(seconds: gpsTimeout));
        if (mounted) {
          setState(() {
            _userLatitude = pos.latitude;
            _userLongitude = pos.longitude;
          });
        }
      } catch (_) {}
    }

    final historySnapshot = List<ChatMessage>.from(_messages);
    setState(() {
      _messages.add(ChatMessage(content: messageText, role: 'user'));
      _isLoading = true;
      _statusText = 'Thinking...';
      if (text == null) _controller.clear();
    });
    _scrollToBottom();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final handle = _chatService.streamMessage(
      messageText,
      historySnapshot,
      latitude: _userLatitude,
      longitude: _userLongitude,
      userId: uid,
      threadId: _currentSessionId ?? uid,
    );
    _streamHandle = handle;

    ChatMessage? assistantMsg;

    try {
      await for (final event in handle.events) {
        if (!mounted) break;
        final type = event['type'] as String? ?? '';

        if (type == 'status') {
          setState(() => _statusText = event['text'] as String?);
        } else if (type == 'token' || type == 'text') {
          final token = event['text'] as String? ?? '';
          if (assistantMsg == null) {
            final msg = ChatMessage(content: token, role: 'assistant');
            assistantMsg = msg;
            setState(() {
              _messages.add(msg);
            });
            _typingTarget = token;
            _startTypingAnimation(msg.id);
          } else {
            assistantMsg.content += token;
            _typingTarget = assistantMsg.content;
          }
          if (type == 'text') {
            final suggestions =
                ((event['suggestions'] as List<dynamic>?) ?? []).cast<String>();
            if (suggestions.isNotEmpty) setState(() => _suggestions = suggestions);
          }
          _scrollToBottom();
        } else if (type == 'done') {
          final recs = (event['recommendations'] as List<dynamic>?) ?? [];
          final suggestions =
              ((event['suggestions'] as List<dynamic>?) ?? []).cast<String>();
          if (recs.isNotEmpty && assistantMsg != null) {
            setState(() {
              assistantMsg!.content += _buildRecsMarkdown(recs);
              if (suggestions.isNotEmpty) _suggestions = suggestions;
            });
          } else if (suggestions.isNotEmpty) {
            setState(() => _suggestions = suggestions);
          }
        } else if (type == 'error') {
          if (assistantMsg == null) {
            setState(() {
              _messages.add(ChatMessage(
                content: "Sorry, I'm having trouble connecting right now.",
                role: 'assistant',
              ));
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusText = null;
        _viewingMessages = null;
      });
    }
    _streamHandle = null;
    _scrollToBottom();
    _autoSave();
  }

  void _startTypingAnimation(String messageId) {
    _typingTimer?.cancel();
    _typingMessageId = messageId;
    _typedLength = 0;
    _typingTarget = '';
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_typedLength < _typingTarget.length) {
        setState(() => _typedLength++);
        _scrollToBottom();
      } else if (!_isLoading) {
        timer.cancel();
        _typingTimer = null;
        setState(() => _typingMessageId = null);
      }
    });
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>',       caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>\s*<p[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<p[^>]*>',        caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>',            caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'),        '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;',  '&')
        .replaceAll('&lt;',   '<')
        .replaceAll('&gt;',   '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _buildRecsMarkdown(List<dynamic> recs) {
    final sb = StringBuffer('\n\n');
    for (final raw in recs) {
      final party = raw as Map<String, dynamic>;
      sb.write('- **${party['title']}**\n');
      final images = ((party['images'] as List<dynamic>?) ?? [])
          .cast<String>()
          .where((img) => img.isNotEmpty && img.startsWith('http'))
          .toList();
      if (images.isNotEmpty) {
        sb.write('  - ${images.map((img) => '![thumbnail]($img)').join(' ')}\n');
      }
      sb.write('  - **Location**: ${party['location']}, **${party['country']}**\n');
      sb.write('  - **Time**: ${party['time']}\n');
    }
    return sb.toString();
  }

  // Converts **VenueName** — (and **VenueName** *(Location)* —) patterns
  // into tappable nightride://venue/ links.
  // Group 1 = venue name, Group 2 = optional italic location e.g. *(Colombo 2)*
  static final _venueRegex = RegExp(
    r'\*\*([A-Z][^\*\[\n]{0,58})\*\*(\s*\*\([^\)\n]*\)\*)?(?=\s*[—–])',
  );
  // Bold items that match these words are categories/events, not venues.
  static final _nonVenueWords = RegExp(
    r'\b(pop.?ups?|raves?|poya|concerts?|festivals?|scenes?|periods?|holidays?|ban\b)',
    caseSensitive: false,
  );

  static String _linkifyVenues(String markdown) {
    return markdown.replaceAllMapped(_venueRegex, (m) {
      final name     = m.group(1)!.trim();
      final location = m.group(2) ?? '';
      // Skip non-venue category descriptions
      if (_nonVenueWords.hasMatch(name) || name.split(' ').length > 8) {
        return m.group(0)!;
      }
      final encoded = Uri.encodeComponent(name);
      return '**[$name](nightride://venue/$encoded)**$location';
    });
  }

  void _handleInteraction(ChatMessage message, String type) {
    setState(() {
      if (type == 'like') {
        message.isLiked = !message.isLiked;
      } else if (type == 'heart') {
        message.isFavorited = !message.isFavorited;
      }
    });
  }

  void _openImageGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageGalleryPage(images: images, initialIndex: initialIndex),
      ),
    );
  }

  List<String> _extractImages(String content) {
    final exp = RegExp(r'!\[.*?\]\((.*?)\)');
    return exp
        .allMatches(content)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _formatSessionDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatSessionTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  // ── Lock It In ──────────────────────────────────────────────────────────────
  void _lockItIn() {
    // TODO: connect to save/favorite plan functionality when available
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Plan saved to your Night Rite!',
        style: GoogleFonts.poppins(color: _kBlack, fontWeight: FontWeight.w700),
      ),
      backgroundColor: _kNeonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _autoSave();
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _kBlack,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _kBlack,
          drawer: _buildHistoryDrawer(),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Live-response banner shown when browsing past chats during a stream
              if (!_isViewingLive && _isLoading)
                GestureDetector(
                  onTap: _returnToLiveSession,
                  child: Container(
                    width: double.infinity,
                    color: _kNeonLime.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_kNeonLime),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI is still responding — tap to return to live chat',
                            style: GoogleFonts.poppins(
                                color: _kNeonLime, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: _kNeonLime, size: 14),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: _displayMessages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: _displayMessages.length +
                            (_isViewingLive && _statusText != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayMessages.length) {
                            return _buildLoadingIndicator();
                          }
                          return _buildMessageRow(_displayMessages[index]);
                        },
                      ),
              ),
              // "LOCK IT IN" CTA — shown after AI has produced a plan
              if (_messages.isNotEmpty && !_isLoading && _isViewingLive && _hasPlan)
                _buildLockItInBar(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kBlack,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _kWhite, size: 22),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Chat history',
      ),
      title: Text(
        'NIGHT RITE AI ✦',
        style: GoogleFonts.anton(
          fontWeight: FontWeight.w400,
          fontSize: 22,
          color: _kNeonLime,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: _kNeonLime, size: 22),
          onPressed: _clearCurrentChat,
          tooltip: 'New chat',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorderGray),
      ),
    );
  }

  // ── History Drawer ─────────────────────────────────────────────────────────

  Widget _buildHistoryDrawer() {
    return Drawer(
      backgroundColor: _kSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorderGray)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: _kNeonLime, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'CHAT HISTORY',
                    style: GoogleFonts.anton(
                        fontSize: 18, color: _kWhite, letterSpacing: 1.5),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // New Chat button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add_rounded, size: 18, color: _kBlack),
                  label: Text(
                    'NEW CHAT',
                    style: GoogleFonts.anton(
                        color: _kBlack, fontSize: 15, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNeonLime,
                    foregroundColor: _kBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: _kMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No past chats yet',
                              style: GoogleFonts.poppins(color: _kMuted, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) =>
                          _buildSessionTile(_sessions[index]),
                    ),
            ),
            if (_sessions.isNotEmpty) ...[
              Container(height: 1, color: _kBorderGray),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _kSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _kBorderGray),
                      ),
                      title: Text('Clear all history?',
                          style: GoogleFonts.anton(color: _kWhite, fontSize: 20)),
                      content: Text(
                        'All past chats will be permanently deleted.',
                        style: GoogleFonts.poppins(color: _kMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(color: _kMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete all',
                              style: GoogleFonts.poppins(
                                  color: _kHotPink,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await _historyService.clearAll();
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: _kHotPink, size: 18),
                label: Text('Clear all history',
                    style: GoogleFonts.poppins(color: _kHotPink, fontSize: 13)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(ChatSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _kHotPink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _kHotPink, size: 22),
      ),
      onDismissed: (_) => _deleteSession(session.id),
      child: ListTile(
        onTap: () => _loadSession(session),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kNeonLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: _kNeonLime, size: 18),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: _kWhite),
        ),
        subtitle: Text(
          '${session.messages.length} messages · ${_formatSessionDate(session.createdAt)} · ${_formatSessionTime(session.createdAt)}',
          style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: _kMuted.withValues(alpha: 0.5), size: 18),
          onPressed: () => _deleteSession(session.id),
        ),
      ),
    );
  }

  // ── Loading indicator ──────────────────────────────────────────────────────

  Widget _buildLoadingIndicator() {
    if (_statusText == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(_kNeonLime),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _statusText!,
            style: GoogleFonts.poppins(color: _kMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Mascot (animated float)
          const _FloatingMascot(assetPath: 'assets/images/vinyl_mascot_1.png', size: 140),
          const SizedBox(height: 24),
          // Speech bubble
          _buildSpeechBubble(
            child: Text(
              'YO $_currentUserName! I GOT THE PLAN.\nYOU JUST BRING THE ENERGY.',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 18,
                color: _kBlack,
                letterSpacing: 0.8,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // START PLANNING CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _controller.text = "What's happening tonight?";
                _handleSend(text: "What's happening tonight?");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNeonLime,
                foregroundColor: _kBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'START PLANNING',
                style: GoogleFonts.anton(
                    fontSize: 18, color: _kBlack, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Quick suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble({required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
        // Tail pointing upward (toward mascot)
        Positioned(
          top: -12,
          child: CustomPaint(
            size: const Size(24, 14),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _handleSend(text: text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _kBorderGray),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              color: _kWhite, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Message row ────────────────────────────────────────────────────────────

  Widget _buildMessageRow(ChatMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: isUser
                    ? _buildUserBubble(message.content)
                    : _buildAssistantBubble(message),
              ),
            ],
          ),
          if (!isUser) ...[
            const SizedBox(height: 8),
            _buildInteractionRow(message),
          ],
        ],
      ),
    );
  }

  // User message: dark card with neonLime left border
  Widget _buildUserBubble(String content) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: const Border(
          left: BorderSide(color: _kNeonLime, width: 3),
        ),
      ),
      child: Text(
        content,
        style: GoogleFonts.poppins(
            color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  // AI message: cream/dark speech-bubble style card
  Widget _buildAssistantBubble(ChatMessage message) {
    final isTyping = message.id == _typingMessageId;
    final visibleContent = isTyping
        ? message.content
            .substring(0, _typedLength.clamp(0, message.content.length))
        : message.content;
    final cleaned   = _linkifyVenues(_stripHtml(visibleContent));
    final allImages = _extractImages(cleaned);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.88,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: _kBorderGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI label tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: _kNeonLime,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Text(
              'NIGHT RITE AI',
              style: GoogleFonts.anton(
                  fontSize: 10, color: _kBlack, letterSpacing: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: MarkdownBody(
              data: cleaned,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.poppins(
                    color: _kWhite.withValues(alpha: 0.90),
                    fontSize: 15,
                    height: 1.65),
                strong: GoogleFonts.poppins(
                    color: _kCream, fontWeight: FontWeight.w800),
                h1: GoogleFonts.anton(
                    color: _kNeonLime, fontSize: 20, letterSpacing: 1.0),
                h2: GoogleFonts.anton(
                    color: _kNeonLime, fontSize: 17, letterSpacing: 0.8),
                h3: GoogleFonts.poppins(
                    color: _kCream,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
                listBullet: GoogleFonts.poppins(color: _kNeonLime),
                a: GoogleFonts.poppins(
                    color: _kNeonLime,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline),
                blockquoteDecoration: BoxDecoration(
                  color: _kNeonLime.withValues(alpha: 0.08),
                  border: const Border(
                    left: BorderSide(color: _kNeonLime, width: 3),
                  ),
                ),
                blockquote: GoogleFonts.poppins(
                    color: _kMuted, fontSize: 14, fontStyle: FontStyle.italic),
                code: GoogleFonts.sourceCodePro(
                    color: _kNeonLime,
                    backgroundColor: _kSurface,
                    fontSize: 13),
              ),
              onTapLink: (text, href, title) async {
                if (href == null) return;
                final uri = Uri.tryParse(href);
                if (uri == null) return;

                // Venue detail page — tapped a club/bar name in AI chat
                if (uri.scheme == 'nightride' && uri.host == 'venue') {
                  // Use the full path (minus leading '/') so names with
                  // special chars survive encoding/decoding correctly.
                  final rawPath = uri.path.replaceFirst('/', '');
                  final rawName = rawPath.isNotEmpty ? rawPath : text;
                  final venueName = Uri.decodeComponent(rawName);
                  if (venueName.isNotEmpty && mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VenueSearchDetailPage(venueName: venueName),
                    ));
                  }
                  return;
                }

                // Night Rite in-app navigation
                if (uri.scheme == 'nightride' && uri.host == 'map') {
                  final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
                  final lng = double.tryParse(uri.queryParameters['lng'] ?? '');
                  final rawName = uri.queryParameters['name'] ?? 'Destination';
                  final name = Uri.decodeComponent(rawName.replaceAll('+', ' '));
                  final placeId = uri.queryParameters['placeId'];
                  final container = ProviderScope.containerOf(context, listen: false);
                  if (lat != null && lng != null) {
                    container.read(mapFocusProvider.notifier).state =
                        MapFocus(lat, lng, label: name, placeId: placeId);
                  }
                  container.read(appNavProvider.notifier).setIndex(0);
                  return;
                }

                // Legacy: google.com/maps links → open in-app map
                if (uri.host.contains('google.com') && uri.path.contains('map')) {
                  double? lat, lng;
                  final dest = uri.queryParameters['destination'];
                  if (dest != null) {
                    final parts = dest.split(',');
                    if (parts.length == 2) {
                      lat = double.tryParse(parts[0].trim());
                      lng = double.tryParse(parts[1].trim());
                    }
                  }
                  final container = ProviderScope.containerOf(context, listen: false);
                  if (lat != null && lng != null) {
                    container.read(mapFocusProvider.notifier).state =
                        MapFocus(lat, lng, label: text);
                  }
                  container.read(appNavProvider.notifier).setIndex(0);
                  return;
                }

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              // ignore: deprecated_member_use
              imageBuilder: (uri, title, alt) {
                final imageUrl = uri.toString();
                if (!imageUrl.startsWith('http')) return const SizedBox.shrink();
                final index = allImages.indexOf(imageUrl);
                return GestureDetector(
                  onTap: () =>
                      _openImageGallery(context, allImages, index != -1 ? index : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Hero(
                      tag: imageUrl,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              color: _kSurface,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _kNeonLime),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionRow(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          _buildInteractionButton(
            icon: message.isLiked
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            color: message.isLiked ? _kNeonLime : _kMuted,
            isActive: message.isLiked,
            onTap: () => _handleInteraction(message, 'like'),
          ),
          const SizedBox(width: 8),
          _buildInteractionButton(
            icon: message.isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: message.isFavorited ? _kHotPink : _kMuted,
            isActive: message.isFavorited,
            onTap: () => _handleInteraction(message, 'heart'),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : _kBorderGray.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ── Lock It In bar ─────────────────────────────────────────────────────────

  Widget _buildLockItInBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _lockItIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kNeonLime,
            foregroundColor: _kBlack,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            'LOCK IT IN 🔒',
            style: GoogleFonts.anton(
                fontSize: 17, color: _kBlack, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Input area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _kBlack,
        border: Border(top: BorderSide(color: _kBorderGray)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Horizontal suggestion chips (only when messages exist and not loading)
            if (_messages.isNotEmpty && !_isLoading)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: _suggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSuggestionChip(s),
                          ))
                      .toList(),
                ),
              ),
            // Text input row
            KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _handleSend();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _kBorderGray),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(color: _kWhite, fontSize: 15),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        onChanged: (text) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Ask Night Rite AI...',
                          hintStyle: GoogleFonts.poppins(
                              color: _kMuted.withValues(alpha: 0.6),
                              fontSize: 15),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isLoading)
                      // Stop button
                      GestureDetector(
                        onTap: () {
                          _streamHandle?.cancel();
                          _streamHandle = null;
                          setState(() {
                            _isLoading = false;
                            _statusText = null;
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _kHotPink,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Icon(Icons.stop_rounded,
                              color: Colors.white, size: 20),
                        ),
                      )
                    else
                      // Send button
                      GestureDetector(
                        onTap: _controller.text.trim().isEmpty
                            ? null
                            : _handleSend,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _controller.text.trim().isNotEmpty
                                ? _kNeonLime
                                : _kBorderGray,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: _controller.text.trim().isNotEmpty
                                ? _kBlack
                                : _kMuted,
                            size: 20,
                          ),
                        ),
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

// ── Speech bubble tail painter ────────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kCream;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bouncing tap animation ────────────────────────────────────────────────────

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const BouncingButton({super.key, required this.child, required this.onTap});

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.0,
        upperBound: 0.2);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// ── Image gallery ─────────────────────────────────────────────────────────────

class ImageGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const ImageGalleryPage(
      {super.key, required this.images, required this.initialIndex});

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${_currentIndex + 1} / ${widget.images.length}",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(widget.images[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: PhotoViewHeroAttributes(tag: widget.images[index]),
        ),
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded /
                    (event.expectedTotalBytes ?? 1),
            valueColor: const AlwaysStoppedAnimation<Color>(_kNeonLime),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ── Floating mascot with bob animation ───────────────────────────────────────
class _FloatingMascot extends StatefulWidget {
  const _FloatingMascot({required this.assetPath, required this.size});
  final String assetPath;
  final double size;

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: child,
      ),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: Image.asset(
          widget.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.nightlife, size: 100, color: _kNeonLime),
        ),
      ),
    );
  }
}
