import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang     = provider.appLanguage;
    final history  = provider.history;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(Localized.tr(lang, 'Scan History'), style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surface,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: !provider.historyLoaded
            ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : history.isEmpty
                ? _buildEmpty(context, lang)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return _HistoryCard(item: history[index], lang: lang);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            Localized.tr(lang, 'No scans yet'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            Localized.tr(lang, 'Your scan history will appear here'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(Localized.tr(lang, 'Start Scanning')),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String lang;
  const _HistoryCard({required this.item, required this.lang});

  /// Format the raw UTC date string from SQLite into local time
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return Localized.tr(lang, 'Date unknown');
    try {
      // SQLite CURRENT_TIMESTAMP = "YYYY-MM-DD HH:MM:SS" in UTC
      final isoString = raw.trim().replaceFirst(' ', 'T') + 'Z';
      final dt = DateTime.parse(isoString).toLocal();
      final date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date  $time';
    } catch (_) {
      return raw;
    }
  }

  String _formatConfidence(dynamic raw) {
    if (raw == null) return '';
    final val = double.tryParse(raw.toString()) ?? 0.0;
    final pct = val > 1 ? val : val * 100;
    return '${pct.toStringAsFixed(1)}%';
  }

  Color _badgeColor(dynamic raw) {
    final val = double.tryParse(raw?.toString() ?? '0') ?? 0.0;
    final pct = val > 1 ? val : val * 100;
    if (pct >= 75) return AppTheme.success;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final crop       = (item['crop']       ?? '').toString();
    final disease    = (item['disease']    ?? 'Unknown Disease').toString();
    final confidence = item['confidence'];
    final scanDate   = item['scan_date']?.toString();

    final confStr = _formatConfidence(confidence);
    final dateStr = _formatDate(scanDate);
    final color   = _badgeColor(confidence);

    // Translate crop and disease names from English (DB value) to selected language
    final cropLabel    = Localized.tr(lang, crop);
    final diseaseLabel = Localized.tr(lang, disease);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.eco_rounded, color: AppTheme.primaryLight, size: 26),
            ),
            const SizedBox(width: 14),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop label
                  if (crop.isNotEmpty)
                    Text(
                      cropLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight, letterSpacing: 0.3),
                    ),
                  const SizedBox(height: 2),

                  // Disease name
                  Text(
                    diseaseLabel,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date & Time
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Confidence badge
            if (confStr.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  confStr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
