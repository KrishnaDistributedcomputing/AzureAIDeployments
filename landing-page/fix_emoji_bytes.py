#!/usr/bin/env python3
"""Fix UTF-8 mojibake in modules.html by reading and replacing byte patterns"""
import os

file_path = 'modules.html'

# Read as bytes to avoid encoding issues during file reading
with open(file_path, 'rb') as f:
    content = f.read()

# Convert common mojibake byte sequences to emojis
# These byte patterns were identified in the existing file
replacements = [
    # Format: (byte_pattern, emoji_bytes)
    (b'\xc3\xb0\xc2\x9f\xc2\x92\x27\xc2\xbe', '💾'.encode('utf-8')),         # ðŸ'¾ -> 💾
    (b'\xc3\xb0\xc2\x9f\xc2\x93', '🔒'.encode('utf-8')),                     # ðŸ" -> 🔒
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\x8a', '📊'.encode('utf-8')),             # ðŸ"Š -> 📊
    (b'\xc3\xb0\xc2\x9f\xc2\x8c', '🌐'.encode('utf-8')),                    # ðŸŌ -> 🌐
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\xa6', '📦'.encode('utf-8')),             # ðŸ"¦ -> 📦
    (b'\xc3\xb0\xc2\x9f\xc2\x93\x27', '🔑'.encode('utf-8')),                 # ðŸ"' -> 🔑
    (b'\xc3\xb0\xc2\x9f\xc2\x9b\xc2\xa1\xc3\xaf\xc2\xb8\xc2\x8f', '🛡️'.encode('utf-8')),  # Shield
    (b'\xc3\xb0\xc2\x9f\xc2\x92\xc2\xa4', '👤'.encode('utf-8')),             # ðŸ'¤ -> 👤
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\x86', '📈'.encode('utf-8')),             # ðŸ"ˆ -> 📈
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\xac', '📬'.encode('utf-8')),             # ðŸ"¬ -> 📬
    (b'\xc3\xb0\xc2\x9f\xc2\x97\xc2\x84\xc3\xaf\xc2\xb8\xc2\x8f', '🗄️'.encode('utf-8')),   # Filing cabinet
    (b'\xc3\xb0\xc2\x9f\xc2\x96\xc2\xa5\xc3\xaf\xc2\xb8\xc2\x8f', '🖥️'.encode('utf-8')),   # Desktop
    (b'\xc3\xa2\xc2\x98\xc3\xaf\xc2\xb8\xc2\x8f', '☁️'.encode('utf-8')),     # Cloud
    (b'\xc3\xa2\xc2\x98\xc2\xb8\xc3\xaf\xc2\xb8\xc2\x8f', '☸️'.encode('utf-8')),  # Steering wheel
]

count = 0
for old_bytes, new_bytes in replacements:
    count += content.count(old_bytes)
    content = content.replace(old_bytes, new_bytes)

# Write back as UTF-8
with open(file_path, 'wb') as f:
    f.write(content)

print(f'✓ Fixed {count} mojibake emoji sequences')
