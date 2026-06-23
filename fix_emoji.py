#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix emoji mojibake in modules.html"""

file_path = 'landing-page/modules.html'

# Read file with UTF-8 encoding
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Dictionary of mojibake sequences to correct emojis
replacements = {
    'ðŸ\'¾': '💾',     # disk
    'ðŸ"': '🔒',       # lock
    'ðŸ"Š': '📊',      # chart
    'ðŸŌ': '🌐',       # globe
    'ðŸ"¦': '📦',      # package
    'ðŸ"\'': '🔑',     # key
    'ðŸ›¡ï¸': '🛡️',   # shield
    'ðŸ\'¤': '👤',     # person
    'ðŸ"ˆ': '📈',      # chart up
    'ðŸ"¬': '📬',      # mailbox
    'ðŸ—„ï¸': '🗄️',   # filing cabinet
    'ðŸ–¥ï¸': '🖥️',   # desktop
    'â˜ï¸': '☁️',      # cloud
    'â˜¸ï¸': '☸️',     # steering wheel
}

# Apply replacements
for mojibake, emoji in replacements.items():
    content = content.replace(mojibake, emoji)

# Write back with UTF-8 encoding
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('✓ All emoji mojibake sequences fixed successfully')
