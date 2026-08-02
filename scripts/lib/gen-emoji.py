#!/usr/bin/env python3
"""Regenerates scripts/lib/emoji.txt from the running Python's unicodedata."""
import unicodedata

# Main emoji blocks; unicodedata has no emoji property, so the blocks are the filter
RANGES = [(0x1F300, 0x1F5FF), (0x1F600, 0x1F64F), (0x1F680, 0x1F6FF), (0x1F900, 0x1F9FF),
          (0x1FA70, 0x1FAFF), (0x2600, 0x26FF), (0x2700, 0x27BF), (0x2B00, 0x2BFF), (0x1F0A0, 0x1F0FF)]

rows = []
for lo, hi in RANGES:
    for cp in range(lo, hi + 1):
        ch = chr(cp)
        try:
            name = unicodedata.name(ch)
        except ValueError:
            continue  # unassigned codepoint
        rows.append(f"{ch} {name.title()}")

header = (f"# Generated from Python's unicodedata (Unicode {unicodedata.unidata_version}) by scripts/lib/gen-emoji.py.\n"
          f"# One '<emoji> <Name>' per line; regenerate rather than hand-editing.\n")
with open("scripts/lib/emoji.txt", "w", encoding="utf-8") as f:
    f.write(header + "\n".join(rows) + "\n")
print(f"wrote {len(rows)} entries")
