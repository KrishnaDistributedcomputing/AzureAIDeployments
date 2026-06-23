#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

os.chdir(r'c:\Users\kvenk\Downloads\AzureAIDeployments\landing-page')

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

# Convert corrupted UTF-8 mojibake to plain ASCII or HTML entities
replacements = [
    # HTML entity replacements for emoji (keep emoji but as entities)
    ('\U0001f4cb', '📋'),  # clipboard emoji
    ('\U0001f4cc', '📌'),  # pin emoji  
    ('\U0001f4c8', '📈'),  # chart up emoji
    ('\U0001f4ca', '📊'),  # chart emoji
    ('\U0001f4b0', '💰'),  # money emoji
    ('\U0001f6a8', '🚨'),  # alarm emoji
    ('\U0001f6e1', '🛡️'),  # shield emoji
    ('\U0001f4e7', '📧'),  # email emoji
    ('\U0001f4e5', '📥'),  # inbox emoji
    ('\U0001f4d1', '📑'),  # page emoji
    ('\U0001f4d3', '📓'),  # notebook emoji
    ('\U0001f4c5', '📅'),  # calendar emoji
    ('\U0001f4d7', '📗'),  # book emoji
    ('\U0001f4bb', '💻'),  # laptop emoji
    ('\U0001f1f5', '🎯'),  # target
    ('\U0001f9ef', '🧯'),  # extinguisher
    ('\U0001f6f9', '🛹'),  # skateboard  
    ('\U0001f31e', '🌞'),  # sun
    ('\U0001f506', '🔆'),  # bright
    ('\U0001f30b', '🌋'),  # volcano
]

total_replacements = 0
files_modified = []

for file_path in files:
    if not os.path.exists(file_path):
        continue
    
    try:
        with open(file_path, 'rb') as f:
            content_bytes = f.read()
        
        # Decode as utf-8
        try:
            content = content_bytes.decode('utf-8')
        except:
            print("SKIP: {} - encoding error".format(file_path))
            continue
        
        original_content = content
        
        # Replace problematic mojibake patterns by replacing them with simple dashes
        # This targets the actual UTF-8 byte representations found in the files
        file_replacements = 0
        
        # Replace em-dashes with simple hyphen
        if '\u2013' in content or '\u2014' in content:
            content = content.replace('\u2013', '-')
            content = content.replace('\u2014', '-')
            file_replacements += 1
            
        # Replace all smart quotes with simple double quotes or single quotes
        content = content.replace('\u2018', "'")
        content = content.replace('\u2019', "'")
        content = content.replace('\u201c', '"')
        content = content.replace('\u201d', '"')       
        file_replacements += 1
        
        # Replace multiplication symbol
        if '\u00d7' in content:
            content = content.replace('\u00d7', 'x')
            file_replacements += 1
        
        if content != original_content:
            # Write back as UTF-8
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_modified.append(file_path)
            total_replacements += file_replacements
            print("FIXED: {}".format(file_path))
        else:
            print("CLEAN: {}".format(file_path))
    except Exception as e:
        print("ERROR: {} - {}".format(file_path, str(e)))

print("\n=== MOJIBAKE NORMALIZATION COMPLETE ===")
print("Files modified: {}".format(len(files_modified)))
print("Replacement operations: {}".format(total_replacements))
