#!/usr/bin/env python3
"""Fix mojibake by matching actual Unicode characters in file"""

file_path = 'c:\\Users\\kvenk\\Downloads\\AzureAIDeployments\\landing-page\\modules.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# The mojibake prefix (corrupted emoji start)
prefix = 'ðŸ'  # This is U+00F0 U+009F

# Find and replace patterns - match prefix + following chars
replacements = [
    (prefix + "'¾", '💾'),     # Data/Storage
    (prefix + '"', '🔒'),      # Lock/Security  
    (prefix + '"Š', '📊'),     # Chart/Operations
    (prefix + 'Ō', '🌐'),      # Globe
    (prefix + '"¦', '📦'),     # Package
    (prefix + '"\'', '🔑'),    # Key
    (prefix + '›¡ï¸', '🛡️'),  # Shield
    (prefix + "'¤", '👤'),     # Person
    (prefix + '"ˆ', '📈'),     # Chart up
    (prefix + '"¬', '📬'),     # Mailbox
    (prefix + '—„ï¸', '🗄️'),  # Filing cabinet
    (prefix + '–¥ï¸', '🖥️'),  # Desktop
    ('â˜ï¸', '☁️'),            # Cloud
    ('â˜¸ï¸', '☸️'),           # Steering wheel
]

total = 0
for mojibake, emoji in replacements:
    count = content.count(mojibake)
    if count > 0:
        content = content.replace(mojibake, emoji)
        total += count
        print(f'Replaced {count}x: {repr(mojibake)[:30]}... -> {emoji}')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'\nTotal: {total} replacements')
