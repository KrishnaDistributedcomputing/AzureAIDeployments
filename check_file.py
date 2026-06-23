with open('pattern2.html', 'rb') as f:
    content = f.read()

# Find "D4s_v5" and show the next 10 bytes
idx = content.find(b'D4s_v5')
if idx > 0:
    snippet = content[idx:idx+20]
    print("Bytes around D4s_v5:")
    print("Hex:", snippet.hex())
    print("Decoded as UTF-8:", snippet.decode('utf-8', errors='replace'))
    print()
    # Check if it has 'x' character (0x78)
    if b'x' in snippet:
        print("✓ Contains ASCII 'x' character")
    if b'\xc3\x97' in snippet:
        print("⚠️ Contains UTF-8 multiplication symbol")
    if b'\xe2\x80' in snippet:
        print("⚠️ Contains UTF-8 smart dash/quote prefix")
