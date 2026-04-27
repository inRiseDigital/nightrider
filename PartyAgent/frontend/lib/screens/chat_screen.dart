import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:geolocator/geolocator.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Location tracking
  double? _userLatitude;
  double? _userLongitude;

  // Nightride Theme Colors
  static const kPrimary = Color(0xFF9F7AEA);
  static const kBackground = Color(0xFF0F0B1A);
  static const kSurface = Color(0xFF1A1428);
  static const kAccent = Color(0xFFED64A6);

  // Dynamic suggestions from AI
  List<String> _suggestions = [
    "What's happening tonight?",
    "Find Techno parties",
    "Show me rave parties",
    "Weekend schedule"
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the 
        // App to enable the location services.
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, next time you could try
          // requesting permissions again (this is also where
          // Android's shouldShowRequestPermissionRationale 
          // returned true. According to Android guidelines
          // your App should show an explanatory UI now.
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately. 
        return;
      } 

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      // Get position (with timeout to avoid hanging)
      Position position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
      
      // Store location in state
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Text("Location On! 📍 ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}"),
              ],
            ),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    if (_isLoading) return;

    setState(() {
      _messages.add(ChatMessage(content: messageText, role: 'user'));
      _isLoading = true;
      if (text == null) _controller.clear();
    });
    _scrollToBottom();

    try {
      final responseData = await _chatService.sendMessage(
        messageText, 
        _messages.sublist(0, _messages.length - 1),
        latitude: _userLatitude,
        longitude: _userLongitude,
      );
      
      setState(() {
        _messages.add(ChatMessage(content: responseData['response'], role: 'assistant'));
        _isLoading = false;
        
        // Update suggestions from AI
        final aiSuggestions = responseData['suggestions'] as List<String>;
        if (aiSuggestions.isNotEmpty) {
          _suggestions = aiSuggestions;
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(content: "Sorry, I'm having trouble connecting right now. 😅", role: 'assistant'));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _handleInteraction(ChatMessage message, String type) {
    setState(() {
      if (type == 'like') {
        message.isLiked = !message.isLiked;
        _chatService.sendInteraction(message.id, 'like', message.isLiked);
      } else if (type == 'heart') {
        message.isFavorited = !message.isFavorited;
        _chatService.sendInteraction(message.id, 'heart', message.isFavorited);
      }
    });
  }

  void _openImageGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryPage(images: images, initialIndex: initialIndex),
      ),
    );
  }

  List<String> _extractImages(String content) {
    final RegExp exp = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = exp.allMatches(content);
    return matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Nightride AI',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageRow(message);
                    },
                  ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
              valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 48, color: kPrimary),
            const SizedBox(height: 24),
            Text(
              "How can I help you tonight?",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    bool isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        content,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAssistantText(ChatMessage message) {
    final allImages = _extractImages(message.content);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 20),
      child: MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            height: 1.6,
          ),
          strong: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          listBullet: GoogleFonts.outfit(
            color: kPrimary,
          ),
        ),
        imageBuilder: (uri, title, alt) {
          final imageUrl = uri.toString();
          final index = allImages.indexOf(imageUrl);
          
          return GestureDetector(
            onTap: () => _openImageGallery(context, allImages, index != -1 ? index : 0),
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
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
                      );
                    },
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
            icon: message.isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            color: message.isLiked ? kPrimary : Colors.white24,
            isActive: message.isLiked,
            onTap: () => _handleInteraction(message, 'like'),
          ),
          const SizedBox(width: 8),
          _buildInteractionButton(
            icon: message.isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: message.isFavorited ? kAccent : Colors.white24,
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
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : Colors.white10,
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
      decoration: const BoxDecoration(color: kBackground),
      child: SafeArea(
        child: Column(
          children: [
            if (_messages.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: _suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSuggestionChip(s),
                  )).toList(),
                ),
              ),
            KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent && 
                    event.logicalKey == LogicalKeyboardKey.enter && 
                    !HardwareKeyboard.instance.isShiftPressed) {
                  if (event is KeyDownEvent) {
                    _handleSend();
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        onChanged: (text) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Message Nightride...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white24),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _controller.text.trim().isEmpty ? null : _handleSend,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: _controller.text.trim().isNotEmpty ? kPrimary : Colors.transparent,
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

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({super.key, required this.child, required this.onTap});

  @override
  _BouncingButtonState createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.2, // Bounce strength
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class ImageGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryPage({super.key, required this.images, required this.initialIndex});

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
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
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.images[index]),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9F7AEA)),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
