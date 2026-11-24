import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/localization.dart';
import '../models/blog_model.dart';
import '../services/blog_api_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final int blogId;
  const BlogDetailScreen({super.key, required this.blogId});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _blog;
  bool _isLoading = true;
  List<BlogComment> _comments = [];
  bool _commentsLoading = true;

  int _myRating = 0;
  bool _ratingLoading = false;

  final _commentNameCtrl = TextEditingController();
  final _commentTextCtrl = TextEditingController();
  bool _postingComment = false;

  VideoPlayerController? _videoCtrl;
  bool _videoInitialized = false;

  String get _userIdentifier {
    final user = context.read<AppProvider>().currentUser;
    if (user != null) return 'user_${user['id']}';
    return 'guest_${widget.blogId}';
  }

  @override
  void initState() {
    super.initState();
    _loadBlog();
    _loadComments();
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _commentNameCtrl.dispose();
    _commentTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlog() async {
    final lang = context.read<AppProvider>().appLanguage;
    final blog = await BlogApiService.getBlogById(widget.blogId, lang: lang);
    if (!mounted) return;
    setState(() { _blog = blog; _isLoading = false; });

    if (blog != null) {
      _loadMyRating();
      if (blog.videoPath.isNotEmpty) _initVideo(blog.videoPath);
    }
  }

  Future<void> _loadMyRating() async {
    final rating = await BlogApiService.getMyRating(
        blogId: widget.blogId, userIdentifier: _userIdentifier);
    if (mounted) setState(() => _myRating = rating);
  }

  Future<void> _loadComments() async {
    final comments = await BlogApiService.getComments(widget.blogId);
    if (mounted) setState(() { _comments = comments; _commentsLoading = false; });
  }

  Future<void> _initVideo(String filename) async {
    final uri = Uri.parse(BlogApiService.videoUrl(filename));
    _videoCtrl = VideoPlayerController.networkUrl(uri);
    try {
      await _videoCtrl!.initialize();
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      // Video failed to load; gracefully ignore
    }
  }

  Future<void> _submitRating(int rating) async {
    setState(() { _ratingLoading = true; });
    final result = await BlogApiService.rateBlog(
      blogId: widget.blogId,
      userIdentifier: _userIdentifier,
      rating: rating,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _myRating = rating;
        _blog = _blog == null
            ? null
            : BlogPost(
                id: _blog!.id,
                title: _blog!.title,
                cropName: _blog!.cropName,
                description: _blog!.description,
                farmerName: _blog!.farmerName,
                imagePaths: _blog!.imagePaths,
                videoPath: _blog!.videoPath,
                createdAt: _blog!.createdAt,
                averageRating:
                    (result['average_rating'] as num?)?.toDouble() ??
                        _blog!.averageRating,
                ratingCount:
                    (result['rating_count'] as int?) ?? _blog!.ratingCount,
              );
        _ratingLoading = false;
      });
      final lang = context.read<AppProvider>().appLanguage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localized.tr(lang, 'Rating submitted!'),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() => _ratingLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentTextCtrl.text.trim().isEmpty) return;
    final name = _commentNameCtrl.text.trim().isEmpty
        ? (context.read<AppProvider>().currentUser?['name']?.toString() ??
            'Farmer')
        : _commentNameCtrl.text.trim();

    setState(() => _postingComment = true);
    final success = await BlogApiService.addComment(
      blogId: widget.blogId,
      farmerName: name,
      comment: _commentTextCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      _commentTextCtrl.clear();
      await _loadComments();
    }
    setState(() => _postingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().appLanguage;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      );
    }

    if (_blog == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 60, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(Localized.tr(lang, 'Blog not found'),
                    style: AppTheme.headlineSmall),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(Localized.tr(lang, 'Go Back'))),
              ],
            ),
          ),
        ),
      );
    }

    final blog = _blog!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SliverAppBar with image ──────────────────────────────────
              SliverAppBar(
                expandedHeight: blog.imagePaths.isNotEmpty ? 250 : 80,
                pinned: true,
                backgroundColor: AppTheme.primary,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: blog.imagePaths.isNotEmpty
                    ? FlexibleSpaceBar(
                        background: _ImageGallery(
                            imagePaths: blog.imagePaths),
                      )
                    : const FlexibleSpaceBar(
                        centerTitle: true,
                        title: Icon(Icons.eco_rounded,
                            color: Colors.white60, size: 40),
                      ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Crop chip ──────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('🌱 ${blog.cropName}',
                              style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 10),

                        // ── Title ──────────────────────────────────────────
                        Text(blog.title,
                            style: AppTheme.headlineLarge
                                .copyWith(color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),

                        // ── Meta row ───────────────────────────────────────
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                size: 16, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(blog.farmerName,
                                style: AppTheme.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(blog.formattedDate,
                                style: AppTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Average Rating ─────────────────────────────────
                        _RatingDisplay(
                          averageRating: blog.averageRating,
                          ratingCount: blog.ratingCount,
                        ),
                        const SizedBox(height: 20),

                        // ── Description ────────────────────────────────────
                        _SectionHeader(
                            title: Localized.tr(lang, 'Farmer Experience')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Text(blog.description,
                              style: AppTheme.bodyLarge),
                        ),
                        const SizedBox(height: 24),

                        // ── Video Player ───────────────────────────────────
                        if (blog.videoPath.isNotEmpty) ...[
                          _SectionHeader(
                              title: Localized.tr(lang, 'Crop Video')),
                          const SizedBox(height: 8),
                          _VideoPlayer(
                              ctrl: _videoCtrl,
                              initialized: _videoInitialized),
                          const SizedBox(height: 24),
                        ],

                        // ── Rate this blog ─────────────────────────────────
                        _SectionHeader(
                            title: Localized.tr(lang, 'Rate This Blog')),
                        const SizedBox(height: 12),
                        _RatingWidget(
                          currentRating: _myRating,
                          isLoading: _ratingLoading,
                          onRate: _submitRating,
                        ),
                        const SizedBox(height: 28),

                        // ── Comments ───────────────────────────────────────
                        _SectionHeader(
                            title: Localized.tr(lang, 'Comments'),
                            trailing: Text(
                                '(${_comments.length})',
                                style: AppTheme.bodyMedium)),
                        const SizedBox(height: 12),

                        // Comment input box
                        _CommentInputBox(
                          nameCtrl: _commentNameCtrl,
                          textCtrl: _commentTextCtrl,
                          isPosting: _postingComment,
                          onPost: _postComment,
                          lang: lang,
                        ),
                        const SizedBox(height: 16),

                        // Comments list
                        if (_commentsLoading)
                          Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary),
                          )
                        else if (_comments.isEmpty)
                          Center(
                            child: Text(
                                Localized.tr(lang, 'No comments yet'),
                                style: AppTheme.bodyMedium),
                          )
                        else
                          ..._comments.map((c) => _CommentCard(comment: c)),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ImageGallery extends StatefulWidget {
  final List<String> imagePaths;
  const _ImageGallery({required this.imagePaths});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.imagePaths.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _openFullscreen(context, i),
            child: Image.network(
              BlogApiService.imageUrl(widget.imagePaths[i]),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.primary,
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white38, size: 60),
              ),
            ),
          ),
        ),
        if (widget.imagePaths.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imagePaths.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentPage == i ? 18 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, int initial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
            imagePaths: widget.imagePaths, initialIndex: initial),
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  final List<String> imagePaths;
  final int initialIndex;
  const _FullscreenGallery(
      {required this.imagePaths, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imagePaths.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Image.network(
            BlogApiService.imageUrl(imagePaths[i]),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white60, size: 60),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final VideoPlayerController? ctrl;
  final bool initialized;
  const _VideoPlayer({this.ctrl, required this.initialized});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.initialized || widget.ctrl == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: widget.initialized
              ? const Icon(Icons.play_circle_outline,
                  color: Colors.white70, size: 60)
              : CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.ctrl!.value.aspectRatio,
            child: VideoPlayer(widget.ctrl!),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _playing = !_playing;
                _playing ? widget.ctrl!.play() : widget.ctrl!.pause();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _playing
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 36),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              widget.ctrl!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppTheme.primary,
                backgroundColor: Colors.white30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int ratingCount;
  const _RatingDisplay({required this.averageRating, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFA726),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StarRowLarge(rating: averageRating),
              const SizedBox(height: 4),
              Text('$ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'}',
                  style: AppTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRowLarge extends StatelessWidget {
  final double rating;
  const _StarRowLarge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half ? Icons.star_half_rounded : Icons.star_rounded,
          size: 22,
          color: filled || half ? const Color(0xFFFFA726) : AppTheme.divider,
        );
      }),
    );
  }
}

class _RatingWidget extends StatelessWidget {
  final int currentRating;
  final bool isLoading;
  final void Function(int) onRate;
  const _RatingWidget(
      {required this.currentRating,
      required this.isLoading,
      required this.onRate});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppProvider>().appLanguage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            currentRating > 0
                ? Localized.tr(lang, 'Your rating: $currentRating ⭐')
                : Localized.tr(lang, 'Tap a star to rate'),
            style: AppTheme.bodyMedium
                .copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          isLoading
              ? CircularProgressIndicator(color: AppTheme.primary)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => onRate(i + 1),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < currentRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 40,
                          color: i < currentRating
                              ? const Color(0xFFFFA726)
                              : AppTheme.divider,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTheme.headlineSmall.copyWith(color: AppTheme.primary)),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

class _CommentInputBox extends StatelessWidget {
  final TextEditingController nameCtrl, textCtrl;
  final bool isPosting;
  final VoidCallback onPost;
  final String lang;

  const _CommentInputBox({
    required this.nameCtrl,
    required this.textCtrl,
    required this.isPosting,
    required this.onPost,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: Localized.tr(lang, 'Your name (optional)'),
              prefixIcon: Icon(Icons.person_rounded,
                  color: AppTheme.primary, size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          Divider(color: AppTheme.divider, height: 16),
          TextField(
            controller: textCtrl,
            maxLines: 3,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: Localized.tr(lang, 'Write your comment...'),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isPosting ? null : onPost,
              icon: isPosting
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(Localized.tr(lang, 'Post Comment')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: AppTheme.labelMedium
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final BlogComment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  comment.farmerName.isNotEmpty
                      ? comment.farmerName[0].toUpperCase()
                      : 'F',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.farmerName,
                        style: AppTheme.labelMedium
                            .copyWith(color: AppTheme.textPrimary)),
                    Text(comment.formattedDate,
                        style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment.comment, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}
