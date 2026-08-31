"""Bundle the app's Google Fonts instead of fetching them at first launch.

Pulls the exact TTFs google_fonts would fetch at runtime, using the sha256
hashes baked into the installed package, and verifies hash + length before
writing — so the bundled bytes are identical to what the package would have
downloaded, and a silent CDN substitution can't slip through.

    python3 tool/fetch_fonts.py assets/google_fonts

WANT below must stay in step with the weights WgnText actually asks for
(lib/core/theme/wgn_theme.dart); main.dart sets allowRuntimeFetching = false,
so a weight that isn't listed here throws instead of quietly hitting the
network.
"""
import glob
import hashlib
import os
import re
import sys
import urllib.request

_pkgs = sorted(glob.glob(os.path.expanduser(
    "~/.pub-cache/hosted/pub.dev/google_fonts-*/lib/src/google_fonts_parts")))
if not _pkgs:
    sys.exit("google_fonts not in ~/.pub-cache — run `flutter pub get` first")
PKG = _pkgs[-1]
OUT = sys.argv[1]

# family fn name -> (part file, output family prefix, [(weight, style, filename part)])
WANT = {
    "sora": ("part_s.g.dart", "Sora", [
        ("w400", "normal", "Regular"),
        ("w500", "normal", "Medium"),
        ("w600", "normal", "SemiBold"),
        ("w700", "normal", "Bold"),
        ("w800", "normal", "ExtraBold"),
    ]),
    "newsreader": ("part_n.g.dart", "Newsreader", [
        ("w400", "normal", "Regular"),
        ("w500", "normal", "Medium"),
        ("w400", "italic", "Italic"),
    ]),
    "spaceMono": ("part_s.g.dart", "SpaceMono", [
        ("w400", "normal", "Regular"),
    ]),
}

ENTRY = re.compile(
    r"const GoogleFontsVariant\(\s*fontWeight:\s*FontWeight\.(w\d+),\s*"
    r"fontStyle:\s*FontStyle\.(\w+),\s*\):\s*GoogleFontsFile\(\s*'([0-9a-f]{64})',\s*(\d+),",
    re.S,
)


def variants_for(fn, part):
    src = open(os.path.join(PKG, part), encoding="utf-8").read()
    start = src.index(f"static TextStyle {fn}({{")
    body = src[start:src.index("final fonts = <GoogleFontsVariant, GoogleFontsFile>{", start)]
    body_start = start + len(body)
    end = src.index("};", body_start)
    return {(m[1], m[2]): (m[3], int(m[4])) for m in ENTRY.finditer(src[body_start:end])}


os.makedirs(OUT, exist_ok=True)
for fn, (part, family, wanted) in WANT.items():
    table = variants_for(fn, part)
    for weight, style, name in wanted:
        digest, length = table[(weight, style)]
        url = f"https://fonts.gstatic.com/s/a/{digest}.ttf"
        data = urllib.request.urlopen(url, timeout=60).read()
        actual = hashlib.sha256(data).hexdigest()
        if actual != digest or len(data) != length:
            sys.exit(f"MISMATCH {family}-{name}: got {actual} len {len(data)}, "
                     f"expected {digest} len {length}")
        path = os.path.join(OUT, f"{family}-{name}.ttf")
        with open(path, "wb") as f:
            f.write(data)
        print(f"ok  {family}-{name}.ttf  {length:>7} bytes")
