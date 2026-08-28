#!/usr/bin/env python3
# filter_profanity.py
# One-time build tool. Run once, commit the output, never runs at app runtime.
# Usage: python3 filter_profanity.py enable1.txt ldnoobw-en.txt enable-clean.txt
import sys

def main(enable_path, blocklist_path, output_path):
    with open(blocklist_path, encoding="utf-8") as f:
        blocklist = {line.strip().lower() for line in f if line.strip()}
    with open(enable_path, encoding="utf-8") as f:
        words = [line.strip().lower() for line in f if line.strip()]
    cleaned = [w for w in words if w not in blocklist]
    print(f"Original: {len(words)} words")
    print(f"Removed:  {len(words) - len(cleaned)} words")
    print(f"Result:   {len(cleaned)} words")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(cleaned) + "\n")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
