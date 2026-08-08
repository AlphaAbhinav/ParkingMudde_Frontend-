import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../services/api_service.dart';

class ReelsScreen extends StatefulWidget {
  final List<dynamic> reels;
  final int initialIndex;

  const ReelsScreen({super.key, required this.reels, required this.initialIndex});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: const Center(child: Text("No Reels Available", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.reels.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ReelPlayer(
                reel: widget.reels[index],
                onReelUpdated: (updatedReel) {
                  setState(() {
                    widget.reels[index] = updatedReel;
                  });
                },
              );
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final dynamic reel;
  final ValueChanged<Map<String, dynamic>>? onReelUpdated;

  const ReelPlayer({super.key, required this.reel, this.onReelUpdated});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;
  late Map<String, dynamic> _reel;
  bool _initialized = false;
  bool _isLikeBusy = false;

  String get _reelId => _reel['id']?.toString() ?? '';
  int get _likes => int.tryParse(_reel['likes']?.toString() ?? '0') ?? 0;
  int get _comments => int.tryParse(_reel['comments']?.toString() ?? '0') ?? 0;
  bool get _isLiked => _reel['is_liked'] == true;

  @override
  void initState() {
    super.initState();
    _reel = Map<String, dynamic>.from(widget.reel as Map);
    final rawUrl = _reel['video_url'] ?? '';
    final url = rawUrl.startsWith('/') ? '${ApiService.baseUrl}$rawUrl' : rawUrl;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }).catchError((e) {
        print("Error loading video: $e");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLikeBusy || _reelId.isEmpty) return;
    setState(() => _isLikeBusy = true);

    final result = await ApiService.toggleReelLike(_reelId);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _reel['is_liked'] = result['liked'] == true;
        _reel['likes'] = result['likes'] ?? _likes;
        _isLikeBusy = false;
        widget.onReelUpdated?.call(Map<String, dynamic>.from(_reel));
      });
    } else {
      setState(() => _isLikeBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Could not update like.')),
      );
    }
  }

  void _showComments() {
    if (_reelId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ReelCommentsSheet(
        reelId: _reelId,
        onCommentAdded: () {
          setState(() {
            _reel['comments'] = _comments + 1;
            widget.onReelUpdated?.call(Map<String, dynamic>.from(_reel));
          });
        },
        onCommentDeleted: () {
          setState(() {
            _reel['comments'] = (_comments - 1).clamp(0, 1 << 30);
            widget.onReelUpdated?.call(Map<String, dynamic>.from(_reel));
          });
        },
      ),
    );
  }

  Future<void> _shareReel() async {
    final rawUrl = _reel['video_url']?.toString() ?? '';
    final url = rawUrl.startsWith('/') ? '${ApiService.baseUrl}$rawUrl' : rawUrl;
    final title = _reel['title']?.toString().trim();
    final message = [
      if (title != null && title.isNotEmpty) title,
      'Watch this Parking Prachaar reel on Parking Mudde',
      if (url.isNotEmpty) url,
    ].join('\n');
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_initialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        if (_initialized && !_controller.value.isPlaying)
          Center(
            child: Icon(Icons.play_arrow_rounded, color: Colors.white.withOpacity(0.5), size: 100),
          ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 40,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${_reel['author'] ?? 'unknown'}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _reel['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 40,
          right: 16,
          child: Column(
            children: [
              _buildActionIcon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                _likes.toString(),
                onTap: _toggleLike,
                color: _isLiked ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(height: 16),
              _buildActionIcon(Icons.comment_outlined, _comments.toString(), onTap: _showComments),
              const SizedBox(height: 16),
              _buildActionIcon(Icons.share, "Share", onTap: _shareReel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final VoidCallback onCommentAdded;
  final VoidCallback onCommentDeleted;

  const ReelCommentsSheet({super.key, required this.reelId, required this.onCommentAdded, required this.onCommentDeleted});

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await ApiService.getCurrentUserId();
    if (!mounted) return;
    setState(() => _currentUserId = userId);
  }

  Future<void> _loadComments() async {
    final comments = await ApiService.getReelComments(widget.reelId);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final result = await ApiService.createReelComment(widget.reelId, text);
    if (!mounted) return;

    if (result['success'] == true && result['comment'] != null) {
      setState(() {
        _comments = [..._comments, result['comment']];
        _controller.clear();
        _isSending = false;
      });
      widget.onCommentAdded();
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Could not add comment.')),
      );
    }
  }

  Future<void> _editComment(int index, Map<String, dynamic> comment) async {
    final commentId = int.tryParse(comment['id']?.toString() ?? '');
    if (commentId == null) return;

    final editController = TextEditingController(text: comment['text']?.toString() ?? '');
    final editedText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text('Edit comment', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Update your comment',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    editController.dispose();

    if (editedText == null || editedText.isEmpty || editedText == (comment['text']?.toString() ?? '')) return;

    final result = await ApiService.updateReelComment(widget.reelId, commentId, editedText);
    if (!mounted) return;

    if (result['success'] == true && result['comment'] != null) {
      setState(() {
        _comments[index] = result['comment'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Could not edit comment.')),
      );
    }
  }

  Future<void> _deleteComment(int index, Map<String, dynamic> comment) async {
    final commentId = int.tryParse(comment['id']?.toString() ?? '');
    if (commentId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text('Delete comment?', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove your comment from this reel.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final result = await ApiService.deleteReelComment(widget.reelId, commentId);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _comments.removeAt(index);
      });
      widget.onCommentDeleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Could not delete comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Text(
              'Comments',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final comment = Map<String, dynamic>.from(_comments[index] as Map);
                            final userName = comment['user_name']?.toString().trim();
                            final rawProfileImage = comment['profile_image']?.toString().trim() ?? '';
                            final profileImageUrl = rawProfileImage.startsWith('/') ? '${ApiService.baseUrl}$rawProfileImage' : rawProfileImage;
                            final hasProfileImage = profileImageUrl.isNotEmpty;
                            final isOwnComment = _currentUserId != null && comment['user_id']?.toString() == _currentUserId;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundColor: Colors.white12,
                                  backgroundImage: hasProfileImage ? NetworkImage(profileImageUrl) : null,
                                  child: hasProfileImage
                                      ? null
                                      : Text(
                                          (userName?.isNotEmpty == true ? userName![0] : 'U').toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName?.isNotEmpty == true ? userName! : 'Parking Mudde user',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        comment['text']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white70, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwnComment)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                                    color: const Color(0xFF242424),
                                    onSelected: (value) {
                                      if (value == 'edit') _editComment(index, comment);
                                      if (value == 'delete') _deleteComment(index, comment);
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                    ],
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 500,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Add a comment...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _isSending ? null : _sendComment,
                      style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
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

