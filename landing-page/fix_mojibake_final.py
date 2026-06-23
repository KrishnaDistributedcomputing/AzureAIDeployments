#!/usr/bin/env python3
import os

fpath = 'modules.html'
print(f"Current size: {os.path.getsize(fpath)} bytes")

with open(fpath, 'rb') as f:
    content = f.read()

# These are the EXACT UTF-8 byte sequences from the file
# Format: (corrupted_bytes, correct_emoji_bytes)
fixes = [
    # Disk emoji (💾): corrupted as ðŸ'¾
    (b'\xce\xb8\xce\x98\xef\xbc\x87', b'\xf0\x9f\x92\xbe'),
    # Data icon variants
    (ord('ðŸ'¾').to_bytes(1, 'big'), '💾'.encode('utf-8')),
]

# Actually, let's use a string-based approach
content_str = content.decode('utf-8', errors='replace')
print("Decoded with errors=replace")

# Now do the replacements using string operations
replacements = {
    'ðŸ'¾': '💾',
    'ðŸ"': '🔒',
    'ðŸ"Š': '📊',
    'ðŸ"'': '🔑',
    'ðŸ"ˆ': '📈',
    'ðŸ"¬': '📬',
    'ðŸ''¤': '👤',  
    'ðŸŌ': '🌐',
    'ðŸ"¦': '📦',
    'ðŸ›¡ï¸': '🛡️',
    'ðŸ–¥ï¸': '🖥️',
    'ðŸ—„ï¸': '🗄️',
    'â˜ï¸': '☁️',
    'â˜¸ï¸': '☸️',
}

count = 0
for mojibake, emoji in replacements.items():
    c = content_str.count(mojibake)
    if c > 0:
        content_str = content_str.replace(mojibake, emoji)
        count += c
        print(f"✓ Replaced {c}x: {mojibake[:20]} -> {emoji}")

with open(fpath, 'w', encoding='utf-8') as f:
    f.write(content_str)

print(f"\nNew size: {os.path.getsize(fpath)} bytes")
print(f"Total replacements: {count}")
