#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

os.chdir(r'c:\Users\kvenk\Downloads\AzureAIDeployments\landing-page')

# Files to process
files = [
    'module-spec-guide.html',
    'help.html',
    'monitoring.html',
    'pattern1.html',
    'pattern2.html',
    'pattern3.html',
    'pattern4.html',
    'pattern5.html',
    'pattern6.html',
    'pattern7.html',
    'pattern8.html',
    'pattern9.html',
    'pattern10.html',
    'landing-zone.html',
    'csi-education.html'
]

# Add module files
try:
    module_dir = 'modules'
    if os.path.exists(module_dir):
        for f in os.listdir(module_dir):
            if f.endswith('.html'):
                files.append(os.path.join(module_dir, f))
except:
    pass

# Replacement map using Unicode escapes
replacements = [
    ('\u00e2\u0080\u0094', '\u2013'),  # â€" to en-dash
    ('\u00e2\u0080\u0096', '\u2013'),  # â€– to en-dash
    ('\u00e2\u0080\u0099', '\u0027'),  # â€™ to apostrophe
    ('\u00e2\u0086\u0091', '\u2192'),  # â†' to right arrow
    ('\u00e2\u0086\u0099', '\u2199'),  # â†™ to down-left arrow
    ('\u00c3\u0097', '\u00d7'),         # Ã— to multiplication
    ('\u00e2\u009c\u0094', '\u2713'),  # âœ" to checkmark
    ('\u00e2\u009c\u0085', '\u2705'),  # âœ… to checkmark emoji
    ('\u00e2\u009a\u00a1', '\u26a1'),  # âš¡ to lightning
    ('\u00e2\u0080\u00a2', '\u2022'),  # â€¢ to bullet
    ('\u00f0\u009f\u0093\u008a', '\U0001f4ca'),  # ðŸ"Š to 📊
    ('\u00f0\u009f\u0092\u00b0', '\U0001f4b0'),  # ðŸ'° to 💰
    ('\u00f0\u009f\u0093\u0088', '\U0001f4c8'),  # ðŸ"ˆ to 📈
    ('\u00f0\u009f\u0093\u0091', '\U0001f4d1'),  # ðŸ"' to 📑
    ('\u00f0\u009f\u0093\u0093', '\U0001f4d3'),  # ðŸ"" to 📓
    ('\u00f0\u009f\u0093\u0085', '\U0001f4c5'),  # ðŸ"… to 📅
    ('\u00f0\u009f\u009b\u00a1', '\U0001f6e1'),  # ðŸ›¡ to 🛡
    ('\u00f0\u009f\u0093\u00a7', '\U0001f4e7'),  # ðŸ"§ to 📧
    ('\u00f0\u009f\u0093\u00a5', '\U0001f4e5'),  # ðŸ"¥ to 📥
    ('\u00f0\u009f\u0093\u008c', '\U0001f4cc'),  # ðŸ"Œ to 📌
    ('\u00f0\u009f\u0093\u008b', '\U0001f4cb'),  # ðŸ"‹ to 📋
    ('\u00f0\u009f\u0093\u0097', '\U0001f4d7'),  # ðŸ"— to 📗
    ('\u00f0\u009f\u0092\u00bb', '\U0001f4bb'),  # ðŸ'» to 💻
    ('\u00f0\u009f\u0099\u00a8', '\U0001f6a8'),  # ðŸš¨ to 🚨
    ('\u00e2\u00a0\u00a2', '\u2022'),  # â  ¢ to bullet
]

total_replacements = 0
files_modified = []

for file_path in files:
    if not os.path.exists(file_path):
        continue
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        file_replacements = 0
        
        for old, new in replacements:
            count = content.count(old)
            if count > 0:
                content = content.replace(old, new)
                file_replacements += count
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_modified.append((file_path, file_replacements))
            total_replacements += file_replacements
            print("FIXED: {} ({} changes)".format(file_path, file_replacements))
        else:
            print("CLEAN: {}".format(file_path))
    except Exception as e:
        print("ERROR: {} - {}".format(file_path, str(e)))

print("\n=== CLEANUP COMPLETE ===")
print("Files modified: {}".format(len(files_modified)))
print("Total replacements: {}".format(total_replacements))
