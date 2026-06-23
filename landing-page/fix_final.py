#!/usr/bin/env python3
"""Fix mojibake with exact repr sequences identified"""

file_path = 'modules.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Exact patterns from repr() analysis
replacements = [
    ('ðŸ'¾', '💾'),      # Data & Storage
    ('ðŸ"\x90', '🔒'),   # Security & Access (exact \x90 byte)
    ('ðŸ"Š', '📊'),      # Operations
    ('ðŸŌ', '🌐'),       # Globe
    ('ðŸ"¦', '📦'),      # Package  
    ('ðŸ"\'', '🔑'),     # Key
    ('ðŸ›¡ï¸', '🛡️'),   # Shield
    ('ðŸ\'¤', '👤'),     # Person
    ('ðŸ"ˆ', '📈'),      # Chart up
    ('ðŸ"¬', '📬'),      # Mailbox
    ('ðŸ—„ï¸', '🗄️'),   # Filing cabinet
    ('ðŸ–¥ï¸', '🖥️'),   # Desktop
    ('â˜ï¸', '☁️'),      # Cloud
    ('â˜¸ï¸', '☸️'),     # Steering wheel
]

total = 0
for mojibake, emoji in replacements:
    count = content.count(mojibake)
    if count > 0:
        content = content.replace(mojibake, emoji)
        total += count
        print(f'✓ Replaced {count:2d}x {mojibake[:20]:20s} -> {emoji}')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'\nTotal replacements: {total}')
