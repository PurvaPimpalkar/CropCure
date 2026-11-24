import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization.dart';

class ChatbotScreen extends StatefulWidget {
  final Function(int) onNavTap;
  const ChatbotScreen({super.key, required this.onNavTap});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  // Greeting is set on first build based on language
  String? _greetingLang;
  final List<Map<String, String>> _messages = [];

  // Suggestion keys — labels are localized in build(), matching stays English
  final List<String> _suggestionKeys = [
    "How to prevent blight?",
    "How to manage rust disease?",
    "Best fertilizer for rice?",
    "How to improve wheat yield?",
    "How to prevent bacterial infection?",
  ];

  void _ensureGreeting(String lang) {
    if (_greetingLang != lang) {
      _greetingLang = lang;
      _messages.clear();
      _messages.add({'sender': 'bot', 'text': Localized.tr(lang, 'Chatbot greeting')});
    }
  }

  void _sendMessage([String? predefinedText]) {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });

    _messageController.clear();

    // Match against English keywords regardless of display language
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      String response = "I'm still learning! For specific crop diseases, try scanning the leaf or ask me about blight, rust, or bacterial infections.";

      final lowerText = text.toLowerCase();
      if (lowerText.contains('blight') || lowerText.contains('ब्लाइट') || lowerText.contains('करपा')) {
        response = "For blight:\n- Avoid overhead irrigation.\n- Ensure proper crop spacing for airflow.\n- Promptly remove and destroy infected leaves.\n- Apply appropriate fungicides early.";
      } else if (lowerText.contains('rust') || lowerText.contains('रस्ट')) {
        response = "For rust:\n- Use rust-resistant crop varieties.\n- Apply protective fungicide early.\n- Monitor humidity and prevent dense canopies.";
      } else if (lowerText.contains('bacterial') || lowerText.contains('bacteria') || lowerText.contains('बैक्टीरियल') || lowerText.contains('जिवाणू')) {
        response = "For bacterial diseases:\n- Use certified disease-free seeds.\n- Avoid leaf wetness and overhead watering.\n- Disinfect tools frequently.\n- Copper-based sprays can reduce spread.";
      } else if (lowerText.contains('fertilizer') || lowerText.contains('खाद') || lowerText.contains('खत') || lowerText.contains('npk')) {
        response = "Fertilizer Advice:\nAlways test your soil first! A balanced N-P-K fertilizer is generally safe, but avoid excessive Nitrogen as it increases disease susceptibility.";
      } else if (lowerText.contains('irrigation') || lowerText.contains('water') || lowerText.contains('सिंचाई') || lowerText.contains('पाणी')) {
        response = "Irrigation Tips:\nWater plants at their base, not overhead, to keep leaves dry. Drip irrigation is recommended to prevent fungal and bacterial spread.";
      } else if (lowerText.contains('rice') || lowerText.contains('चावल') || lowerText.contains('भात')) {
        response = "Rice Care Tips:\nMaintain proper water levels. Monitor for brown spot and rice blast. Nitrogen management is crucial.";
      } else if (lowerText.contains('tomato') || lowerText.contains('टमाटर') || lowerText.contains('टोमॅटो')) {
        response = "Tomato Care Tips:\nProvide steady moisture to prevent blossom end rot, prune suckers for airflow, and watch for early blight signs.";
      } else if (lowerText.contains('wheat') || lowerText.contains('गेहूं') || lowerText.contains('गहू') || lowerText.contains('उपज') || lowerText.contains('yield')) {
        response = "Wheat Yield Tips:\nPlant at the right depth, ensure adequate phosphorus during sowing, and monitor for rust and aphids.";
      } else if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('नमस्') || lowerText.contains('नमस्कार')) {
        response = "Hello farmer! Ask me about crop diseases, fertilizers, or prevention tips.";
      }

      setState(() {
        _messages.add({'sender': 'bot', 'text': response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.appLanguage;
    _ensureGreeting(lang);   // reset greeting when language changes
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(Localized.tr(lang, 'Chatbot')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _suggestionKeys.map((key) {
                  final label = Localized.tr(lang, key);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(label),
                      onPressed: () => _sendMessage(key), // always match English key
                      backgroundColor: AppTheme.surfaceLight,
                      labelStyle: AppTheme.labelMedium.copyWith(color: AppTheme.textPrimary),
                      side: BorderSide(color: AppTheme.divider),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final isBot = _messages[index]['sender'] == 'bot';
                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isBot ? AppTheme.surfaceLight : AppTheme.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isBot ? 4 : 16),
                          bottomRight: Radius.circular(isBot ? 16 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Text(
                        _messages[index]['text']!,
                        style: AppTheme.bodyLarge.copyWith(color: isBot ? AppTheme.textPrimary : Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: Localized.tr(lang, 'Type your query...'),
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: Localized.tr(lang, 'Home'), active: false, onTap: () => widget.onNavTap(0)),
                _NavItem(icon: Icons.camera_alt_rounded, label: Localized.tr(lang, 'Scan'), active: false, onTap: () => widget.onNavTap(1)),
                _NavItem(icon: Icons.chat_bubble_rounded, label: Localized.tr(lang, 'Chatbot'), active: true, onTap: () {}),
                _NavItem(icon: Icons.person_rounded, label: Localized.tr(lang, 'Profile'), active: false, onTap: () => widget.onNavTap(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppTheme.primary : AppTheme.textMuted, size: 26),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.bodySmall.copyWith(color: active ? AppTheme.primary : AppTheme.textMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}
