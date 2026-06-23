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

# Convert all smart typography and special chars to HTML numeric entities
replacements = [
    # Smart quotes to entities
    ('\u2018', '&#8216;'),  # left single quote
    ('\u2019', '&#8217;'),  # right single quote
    ('\u201c', '&#8220;'),  # left double quote
    ('\u201d', '&#8221;'),  # right double quote
    
    # Dashes to entities
    ('\u2013', '&#8211;'),  # en-dash
    ('\u2014', '&#8212;'),  # em-dash
    ('\u2015', '&#8213;'),  # horizontal bar
    
    # Other special chars to entities
    ('\u00a9', '&copy;'),   # copyright
    ('\u00ae', '&reg;'),    # registered
    ('\u2122', '&trade;'),  # trademark
    ('\u00d7', '&times;'),  # multiplication
    ('\u00f7', '&divide;'), # division
    ('\u00ab', '&laquo;'),  # left guillemet
    ('\u00bb', '&raquo;'),  # right guillemet
    ('\u2022', '&bull;'),   # bullet
    ('\u2026', '&hellip;'), # ellipsis
    
    # Emoji to HTML entities (preserved but as entities)
    ('\U0001f4cb', '&#128203;'),  # clipboard emoji
    ('\U0001f4cc', '&#128204;'),  # pin emoji
    ('\U0001f4c8', '&#128200;'),  # chart up emoji
    ('\U0001f4ca', '&#128202;'),  # chart emoji
    ('\U0001f4b0', '&#128176;'),  # money emoji
    ('\U0001f6a8', '&#129448;'),  # alarm emoji
    ('\U0001f6e1', '&#129505;'),  # shield emoji
    ('\U0001f4e7', '&#128231;'),  # email emoji
    ('\U0001f4e5', '&#128229;'),  # inbox emoji
    ('\U0001f31f', '&#127775;'),  # star emoji
    ('\U0001f4bb', '&#128187;'),  # laptop emoji
    ('\U0001f919', '&#129305;'),  # hand emoji
    ('\U0001f4d1', '&#128209;'),  # bookmark emoji
]

total_replacements = 0
files_modified = []

for file_path in files:
    if not os.path.exists(file_path):
        continue
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        file_replacements = 0
        
        for old, new in replacements:
            if old in content:
                count = content.count(old)
                content = content.replace(old, new)
                file_replacements += count
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_modified.append((file_path, file_replacements))
            total_replacements += file_replacements
            print("FIXED: {} ({} replacements)".format(file_path, file_replacements))
        else:
            print("CLEAN: {}".format(file_path))
    except Exception as e:
        print("ERROR: {} - {}".format(file_path, str(e)))

print("\n=== HTML ENTITY CONVERSION COMPLETE ===")
print("Files modified: {}".format(len(files_modified)))
print("Total replacements: {}".format(total_replacements))
