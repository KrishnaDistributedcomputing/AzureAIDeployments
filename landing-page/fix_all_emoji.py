#!/usr/bin/env python3
"""Complete emoji mojibake fix with comprehensive mapping"""
import sys

# Read the file
with open('modules.html', 'rb') as f:
    data = f.read()

# Comprehensive replacement map - using byte replacements where possible
replacements = [
    # Emoji mojibake patterns
    (b'\xc3\xb0\xc2\x9f\xc2\x92\x27\xc2\xbe', '💾'.encode()),  # Disk
    (b'\xc3\xb0\xc2\x9f\xc2\x93', '🔒'.encode()),              # Lock  
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\x8a', '📊'.encode()),      # Chart
    (b'\xc3\xb0\xc2\x9f\xc2\x93\x27', '🔑'.encode()),          # Key
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\x86', '📈'.encode()),      # Chart up
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\xac', '📬'.encode()),      # Mailbox
    (b'\xc3\xb0\xc2\x9f\xc2\x92\xc2\xa4', '👤'.encode()),      # Person
    (b'\xc3\xb0\xc2\x9f\xc2\x8c', '🌐'.encode()),             # Globe
    (b'\xc3\xb0\xc2\x9f\xc2\x93\xc2\xa6', '📦'.encode()),      # Package
    (b'\xc3\xb0\xc2\x9f\xc2\x9b\xc2\xa1\xc3\xaf\xc2\xb8\xc2\x8f', '🛡️'.encode()),  # Shield
    (b'\xc3\xb0\xc2\x9f\xc2\x96\xc2\xa5\xc3\xaf\xc2\xb8\xc2\x8f', '🖥️'.encode()),    # Desktop
    (b'\xc3\xb0\xc2\x9f\xc2\x97\xc2\x84\xc3\xaf\xc2\xb8\xc2\x8f', '🗄️'.encode()),    # Filing cabinet
]

count = 0
for old, new in replacements:
    c = data.count(old)
    if c > 0:
        data = data.replace(old, new)
        count += c
        print(f"✓ Replaced {c} instances")

# Write back
with open('modules.html', 'wb') as f:
    f.write(data)

print(f"\nTotal: {count} replacements completed")
