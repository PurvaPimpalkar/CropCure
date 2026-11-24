import os

replacements = {
    'd:/cropcure_final/mobile/lib/main.dart': [
        ('const SystemUiOverlayStyle(', 'SystemUiOverlayStyle('),
    ],
    'd:/cropcure_final/mobile/lib/screens/splash_screen.dart': [
        ('const LinearGradient(', 'LinearGradient('),
    ],
    'd:/cropcure_final/mobile/lib/screens/result_screen.dart': [
        ('const LinearProgressIndicator(', 'LinearProgressIndicator('),
        ('const Divider(height: 1, color: AppTheme.divider)', 'Divider(height: 1, color: AppTheme.divider)'),
        ('const Center(', 'Center('),
        ('const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 72)', 'Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 72)'),
    ],
    'd:/cropcure_final/mobile/lib/screens/treatment_screen.dart': [
        ('const Divider(height: 1, color: AppTheme.divider)', 'Divider(height: 1, color: AppTheme.divider)'),
        ('const Padding(', 'Padding('),
        ('const Icon(Icons.medication_liquid_rounded, color: AppTheme.accent, size: 22)', 'Icon(Icons.medication_liquid_rounded, color: AppTheme.accent, size: 22)'),
    ],
    'd:/cropcure_final/mobile/lib/screens/library_screen.dart': [
        ('const Icon(Icons.search_off_rounded,', 'Icon(Icons.search_off_rounded,'),
        ('const Icon(Icons.search_rounded, color: AppTheme.textMuted)', 'Icon(Icons.search_rounded, color: AppTheme.textMuted)'),
    ],
    'd:/cropcure_final/mobile/lib/screens/signup_screen.dart': [
        ('const Text("Create Account", style: TextStyle(color: AppTheme.textPrimary))', 'Text("Create Account", style: const TextStyle(color: AppTheme.textPrimary))'),
        ('const TextStyle(color: AppTheme.textPrimary)', 'TextStyle(color: AppTheme.textPrimary)'),
        ('const IconThemeData(color: AppTheme.primary)', 'IconThemeData(color: AppTheme.primary)'),
        ('const Icon(Icons.person_add_alt_1_rounded, size: 70, color: AppTheme.primary)', 'Icon(Icons.person_add_alt_1_rounded, size: 70, color: AppTheme.primary)'),
        ('const Icon(Icons.person_outline, color: AppTheme.primaryLight)', 'Icon(Icons.person_outline, color: AppTheme.primaryLight)'),
        ('const Icon(Icons.email_outlined, color: AppTheme.primaryLight)', 'Icon(Icons.email_outlined, color: AppTheme.primaryLight)'),
        ('const Icon(Icons.lock_outline, color: AppTheme.primaryLight)', 'Icon(Icons.lock_outline, color: AppTheme.primaryLight)'),
        ('const Center(child: CircularProgressIndicator(color: AppTheme.primary))', 'Center(child: CircularProgressIndicator(color: AppTheme.primary))'),
    ],
    'd:/cropcure_final/mobile/lib/screens/login_screen.dart': [
        ('const TextStyle(color: AppTheme.textPrimary)', 'TextStyle(color: AppTheme.textPrimary)'),
        ('const Icon(Icons.eco_rounded, size: 80, color: AppTheme.primary)', 'Icon(Icons.eco_rounded, size: 80, color: AppTheme.primary)'),
        ('const Icon(Icons.email_outlined, color: AppTheme.primaryLight)', 'Icon(Icons.email_outlined, color: AppTheme.primaryLight)'),
        ('const Icon(Icons.lock_outline, color: AppTheme.primaryLight)', 'Icon(Icons.lock_outline, color: AppTheme.primaryLight)'),
        ('const Center(child: CircularProgressIndicator(color: AppTheme.primary))', 'Center(child: CircularProgressIndicator(color: AppTheme.primary))'),
    ],
    'd:/cropcure_final/mobile/lib/screens/profile_screen.dart': [
        ('const Row(\n                            children: [\n                              Icon(Icons.language_rounded, color: AppTheme.primaryLight),\n                              SizedBox(width: 12),\n                              Text(\'Language / भाषा\'),\n                            ],\n                          ),', 'Row(\n                            children: const [\n                              Icon(Icons.language_rounded, color: AppTheme.primaryLight),\n                              SizedBox(width: 12),\n                              Text(\'Language / भाषा\'),\n                            ],\n                          ),'),
        ('const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryLight)', 'Icon(Icons.dark_mode_rounded, color: AppTheme.primaryLight)'),
        ('const Divider(color: AppTheme.divider)', 'Divider(color: AppTheme.divider)'),
        ('const Icon(Icons.language_rounded, color: AppTheme.primaryLight)', 'Icon(Icons.language_rounded, color: AppTheme.primaryLight)'),
        ('const Row(\n                            children: [', 'Row(\n                            children: ['),
        ('style: const TextStyle(color: AppTheme.textMuted)', 'style: TextStyle(color: AppTheme.textMuted)'),
    ],
}

for filepath, reps in replacements.items():
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        for old, new in reps:
            content = content.replace(old, new)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Patched {filepath}")

