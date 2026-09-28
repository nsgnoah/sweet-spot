#!/usr/bin/env python3
"""Validate Overlap puzzle files, and optionally build the app's bundled Puzzles.json.

Usage:
  python3 puzzles/validate.py puzzles/some.json [...]        # check files
  python3 puzzles/validate.py --build                         # check everything, write Overlap/Puzzles.json

Puzzle format (one object per puzzle, files hold a JSON array):
  {
    "categories": ["A name", "B name", "C name"],
    "answers": [{"word": "PIANO", "region": "ABC", "why": "Keys, pedals, and strings"}, ...7 total],
    "obscure": ["NETMAN"]   # optional: dictionary hits we've judged too obscure to count
  }

Mechanical checks:
  - structure: 3 categories, 7 answers, regions A B C AB AC BC ABC each used once
  - letter rules ("Five letters", "Has a double letter", "Starts with a vowel", ...) checked exactly
  - compound rules ("___BALL", "FIRE___") checked against /usr/share/dict: a word placed OUTSIDE a
    compound circle must not form a dictionary word with it (unless listed in "obscure")
"""
import json, re, sys, os, glob
from collections import Counter

ROOT = os.path.dirname(os.path.abspath(__file__))
REGIONS = ["A", "B", "C", "AB", "AC", "BC", "ABC"]
NUMS = {w: i for i, w in enumerate("zero one two three four five six seven eight nine ten eleven twelve".split())}

def load_dict():
    words, phrases = set(), set()
    try:
        with open("/usr/share/dict/web2") as f:
            words = {l.strip().lower() for l in f}
        with open("/usr/share/dict/web2a") as f:
            phrases = {l.strip().lower().replace("-", " ") for l in f}
    except OSError:
        pass
    return words, phrases

WORDS, PHRASES = load_dict()

def in_dict(s):
    s = s.lower()
    return s.replace(" ", "") in WORDS or s in PHRASES

def letters(w):
    return re.sub(r"[^A-Z]", "", w.upper())

def rule(cat):
    """Return (kind, fn) where fn(word) -> bool for mechanically checkable categories, else None."""
    c = cat.strip()
    m = re.fullmatch(r"(\w+) letters", c, re.I)
    if m and (m.group(1).lower() in NUMS or m.group(1).isdigit()):
        n = NUMS.get(m.group(1).lower()) or int(m.group(1))
        return ("letters", lambda w: len(letters(w)) == n)
    if re.fullmatch(r"has a double letter", c, re.I):
        return ("letters", lambda w: re.search(r"([A-Z])\1", letters(w)) is not None)
    if re.fullmatch(r"no repeated letters", c, re.I):
        return ("letters", lambda w: len(set(letters(w))) == len(letters(w)))
    if re.fullmatch(r"starts with a vowel", c, re.I):
        return ("letters", lambda w: letters(w)[:1] in "AEIOU")
    if re.fullmatch(r"ends with a vowel", c, re.I):
        return ("letters", lambda w: letters(w)[-1:] in "AEIOU")
    m = re.fullmatch(r"starts with (?:the letter )?([A-Z]+)", c, re.I)
    if m:
        p = m.group(1).upper()
        return ("letters", lambda w: letters(w).startswith(p))
    m = re.fullmatch(r"ends with (?:the letter )?([A-Z]+)", c, re.I)
    if m:
        p = m.group(1).upper()
        return ("letters", lambda w: letters(w).endswith(p))
    m = re.fullmatch(r"contains (?:an? |the letter )?([A-Z])", c, re.I)
    if m:
        p = m.group(1).upper()
        return ("letters", lambda w: p in letters(w))
    m = re.fullmatch(r"_{2,}\s*([A-Z]+)", c)
    if m:
        s = m.group(1)
        return ("suffix", lambda w: in_dict(w + s) or in_dict(w + " " + s), s)
    m = re.fullmatch(r"([A-Z]+)\s*_{2,}", c)
    if m:
        p = m.group(1)
        return ("prefix", lambda w: in_dict(p + w) or in_dict(p + " " + w), p)
    return None

def check(p, label):
    errors, warnings = [], []
    cats = p.get("categories", [])
    ans = p.get("answers", [])
    obscure = {o.upper().replace(" ", "") for o in p.get("obscure", [])}
    if len(cats) != 3:
        errors.append("needs exactly 3 categories")
    if len(ans) != 7:
        errors.append(f"needs exactly 7 answers, has {len(ans)}")
    regions = [a.get("region") for a in ans]
    if sorted(regions, key=REGIONS.index if all(r in REGIONS for r in regions) else str) != REGIONS:
        errors.append(f"regions must be exactly {REGIONS}, got {regions}")
    words = [a.get("word", "") for a in ans]
    if len(set(words)) != len(words):
        errors.append("duplicate words")
    for a in ans:
        w = a.get("word", "")
        if w != w.upper() or not re.fullmatch(r"[A-Z][A-Z '\-]*", w):
            errors.append(f"{w!r}: words must be uppercase letters")
        if len(w) > 12:
            errors.append(f"{w}: longer than 12 characters")
        if not a.get("why"):
            errors.append(f"{w}: missing 'why'")
    if errors or len(cats) != 3:
        return errors, warnings

    for i, cat in enumerate(cats):
        r = rule(cat)
        if not r:
            continue
        kind, fn = r[0], r[1]
        letter = "ABC"[i]
        for a in ans:
            w, member = a["word"], letter in a["region"]
            ok = fn(w)
            if kind == "letters":
                if ok != member:
                    errors.append(f"{w}: {'should' if member else 'should NOT'} satisfy '{cat}'")
            else:
                joined = (r[2] + w) if kind == "prefix" else (w + r[2])
                if member and not ok:
                    warnings.append(f"{w}: '{joined}' not in dictionary (fine if it's a common phrase)")
                if not member and ok and joined.replace(" ", "") not in obscure:
                    errors.append(f"{w}: '{joined}' IS in the dictionary but {w} is outside '{cat}'. "
                                  f"Swap the word, or add '{joined}' to \"obscure\" if nobody would think of it")
    return errors, warnings

def load(path):
    with open(path) as f:
        data = json.load(f)
    return data if isinstance(data, list) else [data]

def main(args):
    build = "--build" in args
    files = [a for a in args if not a.startswith("--")]
    if build or not files:
        files = [os.path.join(ROOT, "core.json")] + sorted(
            f for f in glob.glob(os.path.join(ROOT, "*.json")) if not f.endswith("core.json") and "draft" not in os.path.basename(f))
    total_err = 0
    everything = []
    for path in files:
        puzzles = load(path)
        for i, p in enumerate(puzzles):
            label = f"{os.path.basename(path)}[{i}] {' / '.join(p.get('categories', []))}"
            errs, warns = check(p, label)
            total_err += len(errs)
            if errs or warns:
                print(label)
                for e in errs: print("   ERROR  ", e)
                for w in warns: print("   warn   ", w)
            everything.append((path, p))

    # Cross-puzzle checks
    triples = Counter(tuple(sorted(c.upper() for c in p["categories"])) for _, p in everything)
    for t, n in triples.items():
        if n > 1:
            print(f"ERROR   category set used {n} times: {t}"); total_err += 1
    uses = Counter(a["word"] for _, p in everything for a in p["answers"])
    heavy = {w: n for w, n in uses.items() if n > 2}
    if heavy:
        print("warn    words used in 3+ puzzles:", ", ".join(f"{w}×{n}" for w, n in sorted(heavy.items(), key=lambda x: -x[1])))
    print(f"\n{len(everything)} puzzles, {total_err} errors")

    if build:
        if total_err:
            print("Not building: fix errors first."); sys.exit(1)
        out = os.path.join(ROOT, "..", "Overlap", "Puzzles.json")
        ordered = order([p for _, p in everything], [path for path, _ in everything])
        with open(out, "w") as f:
            json.dump(ordered, f, indent=1, ensure_ascii=False)
        print(f"Wrote {len(ordered)} puzzles to Overlap/Puzzles.json")
    sys.exit(1 if total_err else 0)

def order(puzzles, paths):
    """Core puzzles first, then round-robin across files so styles alternate day to day."""
    by_file = {}
    for path, p in zip(paths, puzzles):
        by_file.setdefault(path, []).append(p)
    core = by_file.pop(os.path.join(ROOT, "core.json"), [])
    queues = [list(v) for _, v in sorted(by_file.items())]
    out = list(core)
    while any(queues):
        for q in queues:
            if q: out.append(q.pop(0))
    return [{"categories": p["categories"], "answers": [{k: a[k] for k in ("word", "region", "why")} for a in p["answers"]]} for p in out]

if __name__ == "__main__":
    main(sys.argv[1:])
