import sys

# Read raw bytes
with open('modules.html', 'rb') as f:
    content = f.read().decode('utf-8')

# Define replacements as tuples (mojibake, emoji)
# These will be passed in properly
replacements = [
    ('ðŸ¤–', '🤖'),
    ('ðŸ'¾', '💾'),
    ('ðŸ"Š', '📊'),
    ('ðŸ"', '🔒'),
    ('ðŸŌ', '🌐'),
    ('ðŸ"¦', '📦'),
    ('ðŸ"'', '🔑'),
    ('ðŸ›¡ï¸', '🛡️'),
    ('ðŸ'¤', '👤'),
    ('ðŸ"ˆ', '📈'),
    ('ðŸ"¬', '📬'),
    ('ðŸ—„ï¸', '🗄️'),
    ('ðŸ–¥ï¸', '🖥️'),
    ('âš™ï¸', '⚙️'),
    ('â˜ï¸', '☁️'),
    ('âš¡', '⚡'),
    ('â˜¸ï¸', '☸️'),
    ('ðŸ—ï¸', '🗂️'),
    ('ðŸšŒ', '🚌'),
]

total = 0
for mojibake, emoji in replacements:
    cnt = content.count(mojibake)
    if cnt > 0:
        content = content.replace(mojibake, emoji)
        total += cnt
        print(f"Replaced {cnt} occurrence(s)")

with open('modules.html', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\nTotal replacements: {total}")
