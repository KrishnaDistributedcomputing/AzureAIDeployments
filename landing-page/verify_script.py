import os
fpath = 'modules.html'
size = os.path.getsize(fpath)
print(f'File: modules.html')
print(f'Size: {size} bytes')
with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()
print(f'Lines: {len(lines)}')
print(f'First 10 lines valid: {len(lines) > 10}')
if len(lines) >= 80:
    for i in range(75, min(90, len(lines))):
        print(f'Line {i+1}: {lines[i][:80]}...' if len(lines[i]) > 80 else f'Line {i+1}: {lines[i]}')
