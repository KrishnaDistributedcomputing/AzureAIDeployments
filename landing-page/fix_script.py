import os
fpath = 'modules.html'
initial_size = os.path.getsize(fpath)
print(f'Initial file size: {initial_size} bytes')
with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()
count_dY = content.count('dY')
count_tilde = content.count('â~')
print(f'Found {count_dY} dY patterns')
print(f'Found {count_tilde} tilde patterns')
content = content.replace('dY', '')
content = content.replace('â~', '—')
with open(fpath, 'w', encoding='utf-8') as f:
    f.write(content)
final_size = os.path.getsize(fpath)
print(f'Final file size: {final_size} bytes')
print(f'Size change: {final_size - initial_size} bytes')
print('Complete')
