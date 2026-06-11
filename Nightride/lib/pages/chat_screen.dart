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
import '../core/theme/app_theme.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_session.dart';
import '../data/services/chat_service.dart' show ChatService, ChatStreamHandle;
import '../data/services/chat_history_service.dart';
import '../providers/app_nav_provider.dart';

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

  static const kPrimary = Color(0xFFf15991);     // hot pink
  static const kBackground = Color(0xFF000000);  // pure black
  static const kSurface = Color(0xFF111111);      // near-black surface
  static const kAccent = Color(0xFF2ec4b6);       // teal
  static const kTextMuted = Color(0xFF9EAFA0);    // muted gray
  static const kTextDark = Color(0xFFfafafa);     // off-white

  List<String> _suggestions = [
    "What's happening tonight?",
    "Find Techno parties",
    "Show me rave parties",
    "Weekend schedule",
  ];

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
    // Re-fetch location when the user returns to the app (e.g. after granting permission).
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: 8),
          Text("Location On! 📍 ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}"),
        ]),
        backgroundColor: kPrimary,
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
    // Fire-and-forget save so current session persists when switching tabs
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
    await _autoSave();
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

  Future<void> _loadSession(ChatSession session) async {
    await _autoSave();
    if (!mounted) return;
    setState(() {
      _currentSessionId = session.id;
      _messages
        ..clear()
        ..addAll(session.messages);
    });
    Navigator.of(context).pop();
    _scrollToBottom();
  }

  Future<void> _deleteSession(String id) async {
    await _historyService.deleteSession(id);
    // If the deleted session is currently open, clear the screen
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
      if (mounted) Navigator.of(context).pop(); // close drawer
    }
  }

  Future<void> _clearCurrentChat() async {
    if (_messages.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear chat?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('This will save the current chat to history and start fresh.',
            style: GoogleFonts.poppins(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.poppins(color: kAccent, fontWeight: FontWeight.w700)),
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

    // Always try to get GPS before sending, with longer wait if user explicitly asked.
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

    // Replace the "Share my location" chip text with a real message that
    // embeds coordinates so the agent can't miss them even if the request
    // field is somehow dropped.
    if (isLocationRequest && _userLatitude != null) {
      messageText =
          'My GPS location: lat=${_userLatitude!.toStringAsFixed(5)}, '
          'lon=${_userLongitude!.toStringAsFixed(5)}. '
          'Find parties near me tonight.';
    } else if (isLocationRequest && _userLatitude == null) {
      messageText = 'I want to share my location but GPS is unavailable right now. '
          'What city should I tell you?';
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
          // Handle suggestions bundled in the 'text' event
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
                content: "Sorry, I'm having trouble connecting right now. 😅",
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
        .replaceAll(RegExp(r'<br\s*/?>',      caseSensitive: false), '\n')
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
        sb.write(
            '  - ${images.map((img) => '![thumbnail]($img)').join(' ')}\n');
      }
      sb.write(
          '  - **Location**: ${party['location']}, **${party['country']}**\n');
      sb.write('  - **Time**: ${party['time']}\n');
    }
    return sb.toString();
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
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => ImageGalleryPage(images: images, initialIndex: initialIndex)));
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _autoSave();
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          primaryColor: kPrimary,
          scaffoldBackgroundColor: kBackground,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: kBackground,
          drawer: _buildHistoryDrawer(),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageRow(_messages[index]),
                      ),
              ),
              _buildLoadingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kBackground,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: kTextDark, size: 22),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Chat history',
      ),
      title: Text(
        'NIGHT RITE AI',
        style: GoogleFonts.anton(
            fontWeight: FontWeight.w400, fontSize: 20, color: kPrimary, letterSpacing: 1.5),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: kPrimary, size: 22),
          onPressed: _clearCurrentChat,
          tooltip: 'New chat',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      backgroundColor: kBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: kPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text('Chat History',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: kTextMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('New Chat',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 4),
            Expanded(
              child: _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: kTextMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No past chats yet',
                              style: GoogleFonts.poppins(color: kTextMuted, fontSize: 14)),
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
              Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear all history?',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      content: Text('All past chats will be permanently deleted.',
                          style: GoogleFonts.poppins(color: kTextMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(color: kTextMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete all',
                              style: GoogleFonts.poppins(
                                  color: Colors.red, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await _historyService.clearAll();
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                label: Text('Clear all history',
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 13)),
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
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
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
            color: kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: kPrimary, size: 18),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
        ),
        subtitle: Text(
          '${session.messages.length} messages · ${_formatSessionDate(session.updatedAt)}',
          style: GoogleFonts.poppins(fontSize: 12, color: kTextMuted),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: kTextMuted.withValues(alpha: 0.5), size: 18),
          onPressed: () => _deleteSession(session.id),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // Only shown while waiting for first token (statusText is set)
    if (_statusText == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary)),
          ),
          const SizedBox(width: 12),
          Text(_statusText!,
              style: GoogleFonts.poppins(color: kTextMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.auto_awesome_rounded, size: 48, color: kPrimary),
          const SizedBox(height: 24),
          Text(
            "HOW CAN I HELP YOU TONIGHT?",
            textAlign: TextAlign.center,
            style: GoogleFonts.anton(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: kPrimary,
                letterSpacing: 1.0),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _handleSend(text: text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.30)),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
                    : _buildAssistantText(message),
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

  Widget _buildUserBubble(String content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration:
          BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(28)),
      child: Text(content,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildAssistantText(ChatMessage message) {
    final isTyping = message.id == _typingMessageId;
    final visibleContent = isTyping
        ? message.content.substring(0, _typedLength.clamp(0, message.content.length))
        : message.content;
    final cleaned = _stripHtml(visibleContent);
    final allImages = _extractImages(cleaned);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 20),
      child: MarkdownBody(
        data: cleaned,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.poppins(
              color: kTextDark.withValues(alpha: 0.85), fontSize: 16, height: 1.6),
          strong:
              GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.w800),
          listBullet: GoogleFonts.poppins(color: kPrimary),
          a: GoogleFonts.poppins(
              color: kPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline),
        ),
        onTapLink: (text, href, title) async {
          if (href == null) return;
          final uri = Uri.tryParse(href);
          if (uri == null) return;

          // Google Maps links → open the in-app map instead of external browser
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
            container.read(appNavProvider.notifier).setIndex(1);
            return;
          }

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        // ignore: deprecated_member_use
        imageBuilder: (uri, title, alt) {
          final imageUrl = uri.toString();
          // Skip empty or non-HTTP URIs (e.g. file:/// from empty cover_image)
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
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                          height: 200,
                          color: kSurface,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimary)));
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
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
            color: message.isLiked ? kPrimary : Colors.grey.shade400,
            isActive: message.isLiked,
            onTap: () => _handleInteraction(message, 'like'),
          ),
          const SizedBox(width: 8),
          _buildInteractionButton(
            icon: message.isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: message.isFavorited ? kAccent : Colors.grey.shade400,
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
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(top: BorderSide(color: kPrimary.withValues(alpha: 0.14))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_messages.isNotEmpty && !_isLoading)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: _suggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSuggestionChip(s),
                          ))
                      .toList(),
                ),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: kPrimary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: kPrimary.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(color: kTextDark, fontSize: 15),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        onChanged: (text) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Message Nightride...',
                          hintStyle: GoogleFonts.poppins(
                              color: kTextMuted.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isLoading)
                      IconButton(
                        onPressed: () {
                          _streamHandle?.cancel();
                          _streamHandle = null;
                          setState(() {
                            _isLoading = false;
                            _statusText = null;
                          });
                        },
                        icon: const Icon(Icons.stop_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: kAccent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                      )
                    else
                      IconButton(
                        onPressed:
                            _controller.text.trim().isEmpty ? null : _handleSend,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: _controller.text.trim().isNotEmpty
                              ? kPrimary
                              : Colors.transparent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          disabledForegroundColor: Colors.white24,
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
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
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
            onPressed: () => Navigator.pop(context)),
        title: Text("${_currentIndex + 1} / ${widget.images.length}",
            style: GoogleFonts.poppins(color: Colors.white)),
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
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF9F7AEA)),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
