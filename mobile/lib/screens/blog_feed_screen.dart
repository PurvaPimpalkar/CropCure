import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/localization.dart';
import '../models/blog_model.dart';
import '../services/blog_api_service.dart';
import 'blog_detail_screen.dart';
import 'add_blog_screen.dart';

class BlogFeedScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BlogFeedScreen({super.key, this.onBack});

  @override
  State<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends State<BlogFeedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BlogPost> _blogs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs({String? cropFilter}) async {
    setState(() => _isLoading = true);
    final lang = context.read<AppProvider>().appLanguage;
    final blogs = await BlogApiService.getAllBlogs(
      cropFilter: cropFilter,
      lang: lang,
    );
    if (mounted) setState(() { _blogs = blogs; _isLoading = false; });
  }

  void _onSearch(String query) {
    _searchQuery = query.trim();
    _loadBlogs(cropFilter: _searchQuery.isEmpty ? null : _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().appLanguage;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: AppTheme.primary),
                        ),
                      ),
                    if (widget.onBack != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Localized.tr(lang, 'Community Blog'),
                            style: AppTheme.headlineLarge
                                .copyWith(color: AppTheme.primary),
                          ),
                          Text(
                            Localized.tr(lang, 'blog_subtitle'),
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Add blog button
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddBlogScreen()),
                        );
                        _loadBlogs(
                            cropFilter: _searchQuery.isEmpty
                                ? null
                                : _searchQuery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              Localized.tr(lang, 'Add Blog'),
                              style: AppTheme.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Search Bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          Localized.tr(lang, 'Search by crop name...'),
                      hintStyle: AppTheme.bodyMedium,
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppTheme.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: AppTheme.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              // ── Crop filter chips ─────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _quickCrops.map((crop) {
                    final isActive = _searchQuery.toLowerCase() ==
                        crop.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        final q = isActive ? '' : crop;
                        _searchCtrl.text = q;
                        _onSearch(q);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.divider),
                        ),
                        child: Text(
                          crop,
                          style: AppTheme.bodySmall.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ── Blog List ────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildShimmer()
                    : _blogs.isEmpty
                        ? _buildEmpty(lang)
                        : RefreshIndicator(
                            onRefresh: () => _loadBlogs(
                                cropFilter: _searchQuery.isEmpty
                                    ? null
                                    : _searchQuery),
                            color: AppTheme.primary,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _blogs.length,
                              itemBuilder: (ctx, i) => _BlogCard(
                                blog: _blogs[i],
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlogDetailScreen(
                                          blogId: _blogs[i].id),
                                    ),
                                  );
                                  _loadBlogs(
                                      cropFilter: _searchQuery.isEmpty
                                          ? null
                                          : _searchQuery);
                                },
                              ).animate(delay: (50 * i).ms).fadeIn().slideY(begin: 0.15),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  Widget _buildEmpty(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined,
              size: 72, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(Localized.tr(lang, 'No blogs yet'),
              style: AppTheme.headlineSmall.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text(Localized.tr(lang, 'Be the first to share your experience!'),
              style: AppTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  static const List<String> _quickCrops = [
    'Tomato', 'Potato', 'Wheat', 'Rice', 'Cotton', 'Soybean', 'Corn',
  ];
}

// ── Blog Card ────────────────────────────────────────────────────────────────

class _BlogCard extends StatelessWidget {
  final BlogPost blog;
  final VoidCallback onTap;
  const _BlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            if (blog.imagePaths.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  BlogApiService.imageUrl(blog.imagePaths.first),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _noImagePlaceholder(),
                ),
              )
            else
              _noImagePlaceholder(topRadius: true),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop chip + rating row
                  Row(
                    children: [
                      _cropChip(blog.cropName),
                      const Spacer(),
                      _StarRow(rating: blog.averageRating, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        blog.averageRating.toStringAsFixed(1),
                        style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      if (blog.ratingCount > 0) ...[
                        Text(' (${blog.ratingCount})',
                            style: AppTheme.bodySmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(blog.title,
                      style: AppTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(blog.shortDescription,
                      style: AppTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(blog.farmerName,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textMuted)),
                      const Spacer(),
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(blog.formattedDate, style: AppTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cropChip(String crop) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '🌱 $crop',
          style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primary, fontWeight: FontWeight.w600),
        ),
      );

  static Widget _noImagePlaceholder({bool topRadius = false}) => Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: topRadius
              ? const BorderRadius.vertical(top: Radius.circular(18))
              : null,
        ),
        child: const Icon(Icons.eco_rounded, size: 48, color: Colors.white54),
      );
}

// ── Star Row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half ? Icons.star_half_rounded : Icons.star_rounded,
          size: size,
          color: filled || half
              ? const Color(0xFFFFA726)
              : AppTheme.divider,
        );
      }),
    );
  }
}

// ── Shimmer Card ──────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(_ctrl);
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
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.divider,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
