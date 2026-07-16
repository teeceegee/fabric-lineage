import re

with open(r'c:\Users\TCAGR\vscode\mapping\pipeline-dashboard-combined.html', 'r') as f:
    content = f.read()

# Find the script tag
script_start = content.find('<script>')
script_end = content.find('</script>')

if script_start >= 0 and script_end >= 0:
    script_content = content[script_start + 8:script_end]
    
    # Trace through and find where braces become unbalanced
    open_count = 0
    close_count = 0
    lines = script_content.split('\n')
    
    for i, line in enumerate(lines, 1):
        line_open = line.count('{')
        line_close = line.count('}')
        open_count += line_open
        close_count += line_close
        
        if open_count != close_count and (line_open > 0 or line_close > 0):
            print(f"Line {i}: {line_open} open, {line_close} close. Total: {open_count} vs {close_count}")
            if abs(open_count - close_count) <= 3:
                print(f"  Content: {line.strip()[:100]}")
    
    print(f"\nFinal: {open_count} open braces vs {close_count} close braces")
    if open_count < close_count:
        print(f"Extra closing braces: {close_count - open_count}")
