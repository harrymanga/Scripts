import re

def protect_placeholders(text):
    patterns = [
        r"<[^>]+>",
        r"\\n",
        r"%[sd]",
        r"\{[^}]+\}"
    ]
    matches = []
    for pattern in patterns:
        matches.extend(re.findall(pattern, text))
    return text, matches
