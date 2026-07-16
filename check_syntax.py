import re

with open(r'c:\Users\TCAGR\vscode\mapping\pipeline-dashboard-combined.html', 'r') as f:
    content = f.read()

# Find the script tag
script_start = content.find('<script>')
script_end = content.find('</script>')

if script_start >= 0 and script_end >= 0:
    script_content = content[script_start + 8:script_end]
    
    # Count braces
    open_braces = script_content.count('{')
    close_braces = script_content.count('}')
    
    # Count quotes
    single_quotes = script_content.count("'")
    double_quotes = script_content.count('"')
    
    print(f'Open braces: {open_braces}, Close braces: {close_braces}')
    print(f'Single quotes: {single_quotes}, Double quotes: {double_quotes}')
    print(f'Braces balanced: {open_braces == close_braces}')
    print(f'Double quotes even: {double_quotes % 2 == 0}')
    print(f'Single quotes even: {single_quotes % 2 == 0}')
    
    # Look for specific error patterns
    if 'aria-label="' in script_content and script_content.count('aria-label="') != script_content.count('"'):
        print("\nPossible unclosed quote in aria-label")
        
    # Find all aria-label lines
    aria_lines = [line for line in script_content.split('\n') if 'aria-label' in line]
    for i, line in enumerate(aria_lines):
        print(f"Line {i}: {line.strip()}")
