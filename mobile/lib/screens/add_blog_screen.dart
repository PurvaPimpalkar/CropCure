import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/localization.dart';
import '../services/blog_api_service.dart';

class AddBlogScreen extends StatefulWidget {
  const AddBlogScreen({super.key});

  @override
  State<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Use XFile — works on both web and native
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;

  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppProvider>().currentUser;
      if (user != null) {
        _nameCtrl.text = user['name']?.toString() ?? '';
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cropCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null) {
      setState(() => _selectedVideo = picked);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final blog = await BlogApiService.createBlog(
        title: _titleCtrl.text.trim(),
        cropName: _cropCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        farmerName: _nameCtrl.text.trim(),
        images: _selectedImages.isEmpty ? null : _selectedImages,
        video: _selectedVideo,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (blog != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localized.tr(
                  context.read<AppProvider>().appLanguage, 'Blog posted!'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
              // ── AppBar ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                    const SizedBox(width: 12),
                    Text(Localized.tr(lang, 'Add Blog'),
                        style: AppTheme.headlineLarge
                            .copyWith(color: AppTheme.primary)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Form ─────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          label: Localized.tr(lang, 'Blog Title'),
                          controller: _titleCtrl,
                          hint: Localized.tr(lang, 'Enter blog title'),
                          icon: Icons.title_rounded,
                          maxLen: 200,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: Localized.tr(lang, 'Crop Name'),
                          controller: _cropCtrl,
                          hint: Localized.tr(lang, 'e.g. Tomato, Wheat, Rice'),
                          icon: Icons.eco_rounded,
                          maxLen: 100,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: Localized.tr(lang, 'Farmer Name'),
                          controller: _nameCtrl,
                          hint: Localized.tr(lang, 'Your name'),
                          icon: Icons.person_rounded,
                          maxLen: 100,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: Localized.tr(lang, 'Blog Description'),
                          controller: _descCtrl,
                          hint: Localized.tr(
                              lang, 'Share your crop experience...'),
                          icon: Icons.description_rounded,
                          maxLen: 5000,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 20),

                        // ── Images ────────────────────────────────────────
                        _SectionLabel(
                          label: Localized.tr(lang, 'Crop Images'),
                          icon: Icons.photo_library_rounded,
                        ),
                        const SizedBox(height: 10),

                        // Image previews — uses XFilePreview (web-safe)
                        if (_selectedImages.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppTheme.divider),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      // XFilePreview works on Web + Native
                                      child: _XFilePreview(
                                          xFile: _selectedImages[i]),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 14,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 12,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),
                        _MediaButton(
                          label: Localized.tr(lang, 'Add Images'),
                          icon: Icons.add_photo_alternate_rounded,
                          onTap: _pickImages,
                          sub: Localized.tr(lang, 'JPG, PNG supported'),
                        ),
                        const SizedBox(height: 16),

                        // ── Video ─────────────────────────────────────────
                        _SectionLabel(
                          label: Localized.tr(lang, 'Crop Video (optional)'),
                          icon: Icons.videocam_rounded,
                        ),
                        const SizedBox(height: 10),
                        if (_selectedVideo != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.success
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.success, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedVideo!.name,
                                    style: AppTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedVideo = null),
                                  child: Icon(Icons.close_rounded,
                                      color: AppTheme.error, size: 18),
                                ),
                              ],
                            ),
                          )
                        else
                          _MediaButton(
                            label: Localized.tr(lang, 'Add Video'),
                            icon: Icons.video_library_rounded,
                            onTap: _pickVideo,
                            sub: Localized.tr(lang, 'MP4, max 5 min'),
                          ),

                        const SizedBox(height: 24),

                        // ── Error message ─────────────────────────────────
                        if (_errorMsg != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_errorMsg!,
                                        style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.error))),
                              ],
                            ),
                          ),

                        // ── Submit ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : Text(
                                    Localized.tr(lang, 'Post Blog'),
                                    style: AppTheme.labelLarge
                                        .copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLen = 500,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.labelLarge
                .copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLength: maxLen,
          maxLines: maxLines,
          style:
              AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            counterText: '',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required field';
            return null;
          },
        ),
      ],
    );
  }
}

// ── Web-safe image preview ────────────────────────────────────────────────────
// Image.file() crashes on Flutter Web.
// This widget reads the raw bytes from XFile and uses Image.memory instead.

class _XFilePreview extends StatefulWidget {
  final XFile xFile;
  const _XFilePreview({required this.xFile});

  @override
  State<_XFilePreview> createState() => _XFilePreviewState();
}

class _XFilePreviewState extends State<_XFilePreview> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final bytes = await widget.xFile.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return Container(
        color: AppTheme.divider,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(label,
              style: AppTheme.labelLarge
                  .copyWith(color: AppTheme.textSecondary)),
        ],
      );
}

class _MediaButton extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final VoidCallback onTap;
  const _MediaButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.labelLarge
                        .copyWith(color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text(sub, style: AppTheme.bodySmall),
              ],
            ),
            const Spacer(),
            Icon(Icons.add_circle_rounded,
                color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
