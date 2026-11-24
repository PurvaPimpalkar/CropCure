import os
import re

dir_path = "d:/cropcure_final/mobile/lib/screens/"

for filename in os.listdir(dir_path):
    if filename.endswith(".dart"):
        filepath = os.path.join(dir_path, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # We will replace `const Something(..., AppTheme..., ...)` with `Something(..., AppTheme..., ...)`
        # Specifically, we know the elements: BoxDecoration, BorderRadius is not one, Icon, TextStyle, BorderSide, Center, IconThemeData

        lines = content.split('\n')
        new_lines = []
        for line in lines:
            if 'AppTheme.' in line and 'const ' in line:
                # Remove `const ` if it precedes a constructor using AppTheme
                # It's safest to just drop `const ` on lines combining const and AppTheme.
                # However, this might break if there's multiple consts. Let's do simple regex.
                line = re.sub(r'const\s+(BoxDecoration|Icon|TextStyle|BorderSide|Center|IconThemeData|LinearGradient)\b', r'\1', line)
            new_lines.append(line)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        
        print(f"Patched {filename}")
