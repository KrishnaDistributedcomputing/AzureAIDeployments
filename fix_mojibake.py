#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys

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

# Replacement map (UTF-8 mojibake → correct character)
replacements = {
    'â€"': '–',      # em-dash
    'â€–': '–',      # en-dash
    'â€™': '\u0027',  # right single quote
    'â†'': '→',     # right arrow
    'â†™': '↙',     # down-left arrow
    'Ã—': '×',       # multiplication
    'âœ"': '✓',     # checkmark
    'âœ…': '✅',    # checkmark emoji
    'âš¡': '⚡',    # lightning
    'â€¢': '•',     # bullet
    'ðŸ"Š': '📊',    # chart emoji
    'ðŸ'°': '💰',    # money emoji
    'ðŸ"ˆ': '📈',    # chart up emoji
    'ðŸ"': '📝',    # memo emoji
    'ðŸ›¡': '🛡️',   # shield emoji
    'ðŸ"§': '📧',    # email emoji
    'ðŸ"¥': '📥',    # inbox emoji
    'ðŸ"Œ': '📌',    # pin emoji
    'ðŸ"‹': '📋',    # clipboard emoji
    'ðŸ"—': '📗',    # book emoji
    'ðŸ'»': '💻',    # laptop emoji
    'ðŸš¨': '🚨',    # alarm emoji
    'ðŸ'': '🎯',     # target emoji
    'ðŸ›"': '🚴',    # biker emoji
    'ðŸ"„': '📄',    # document emoji
    'ðŸŸ¢': '🟢',    # green circle
    'ðŸŸ ': '🟠',    # orange circle
    'ðŸŸ£': '🟣',    # purple circle
    'ðŸŽ¯': '🎯',    # target emoji variant
    'âš™': '⚙',     # gear emoji (partial)
    'â„¢': '™',      # trademark
}

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
        
        for old, new in replacements.items():
            count = content.count(old)
            if count > 0:
                content = content.replace(old, new)
                file_replacements += count
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_modified.append((file_path, file_replacements))
            total_replacements += file_replacements
            print(f"✓ {file_path}: {file_replacements} replacements")
        else:
            print(f"- {file_path}: no mojibake found")
    except Exception as e:
        print(f"✗ {file_path}: Error - {e}")

print(f"\n=== CLEANUP COMPLETE ===")
print(f"Files modified: {len(files_modified)}")
print(f"Total replacements: {total_replacements}")
