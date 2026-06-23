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

# Replacement map - Smart typography to regular ASCII
# These are UTF-8 characters that should be replaced with simple ASCII
replacements = [
    ('\u2013', '-'),           # en-dash to hyphen
    ('\u2014', '-'),           # em-dash to hyphen  
    ('\u2015', '-'),           # horizontal bar to hyphen
    ('\u2018', "'"),           # left single quote to apostrophe
    ('\u2019', "'"),           # right single quote to apostrophe
    ('\u201c', '"'),           # left double quote to ASCII quote
    ('\u201d', '"'),           # right double quote to ASCII quote
    ('\u201a', ','),           # single low quote to comma
    ('\u201e', ',,'),          # double low quote
    ('\u2026', '...'),         # ellipsis to three dots
    ('\u2022', '*'),           # bullet to asterisk
    ('\u2070', '^0'),          # superscript 0
    ('\u00ab', '<<'),          # left guillemet
    ('\u00bb', '>>'),          # right guillemet
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
            count = content.count(old)
            if count > 0:
                content = content.replace(old, new)
                file_replacements += count
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_modified.append((file_path, file_replacements))
            total_replacements += file_replacements
            print("FIXED: {} ({} changes)".format(file_path, file_replacements))
        else:
            print("CLEAN: {}".format(file_path))
    except Exception as e:
        print("ERROR: {} - {}".format(file_path, str(e)))

print("\n=== TYPOGRAPHY NORMALIZATION COMPLETE ===")
print("Files modified: {}".format(len(files_modified)))
print("Total replacements: {}".format(total_replacements))
