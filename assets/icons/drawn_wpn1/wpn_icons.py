# WPN.1 shop icons in the same drawn style as assets/icons/svg/icons.py (its helpers are reused, its icon table is not)
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, "icons.py"), encoding="utf-8").read()
exec(src.split("ICONS = {")[0])  # PAL, S, T, hi, svg, lantern, ...

def link(cx, cy, rot):
    return [S("ellipse", None, cx=cx, cy=cy, rx=20, ry=12, transform=f"rotate({rot} {cx} {cy})", stroke=NAVY, stroke_width=17),
            S("ellipse", None, cx=cx, cy=cy, rx=20, ry=12, transform=f"rotate({rot} {cx} {cy})", stroke="#cfdbe8", stroke_width=7)]

chain = []
for i, (x, y) in enumerate(((84, 176), (106, 152), (128, 128), (150, 104))):
    chain += link(x, y, -45 if i % 2 == 0 else 45)

ICONS = {
 "ChainHook": T([S("rect", "wood", x=-22, y=-11, width=60, height=22, rx=10), S("rect", "red", line=5, x=-30, y=-14, width=12, height=28, rx=4),
                 hi("rect", 0.4, x=-14, y=-7, width=44, height=5, rx=2)], "translate(58,202) rotate(-45)")
              + chain
              + [S("path", None, d="M164,92 L182,74 C206,50 238,74 222,104 C212,124 188,128 176,114", stroke=NAVY, stroke_width=32),
                 S("path", None, d="M164,92 L182,74 C206,50 238,74 222,104 C212,124 188,128 176,114", stroke="#8f99a6", stroke_width=16),
                 S("path", None, d="M186,72 C202,60 222,66 226,84", stroke="#ffffff", stroke_width=5, opacity=0.7),
                 S("path", "steel", d="M166,118 L194,124 L176,138 Z")],
 "NetLauncher": [S("circle", "url(#r_cream)", out=False, cx=176, cy=78, r=78),
                 S("circle", "canvas", cx=176, cy=78, r=50),
                 S("path", None, d="M140,58 L212,58 M134,78 L218,78 M140,98 L212,98 M156,36 L156,120 M176,30 L176,126 M196,36 L196,120", stroke="#8a6d3b", stroke_width=5),
                 S("circle", "brass", line=4, cx=136, cy=46, r=7), S("circle", "brass", line=4, cx=218, cy=56, r=7), S("circle", "brass", line=4, cx=214, cy=112, r=7), S("circle", "brass", line=4, cx=140, cy=114, r=7)]
                + T([S("rect", "wood", x=-96, y=-14, width=70, height=28, rx=10),
                     S("rect", "navy", x=-30, y=-24, width=96, height=48, rx=12),
                     S("rect", "brass", line=5, x=-14, y=-28, width=14, height=56, rx=4), S("rect", "brass", line=5, x=26, y=-28, width=14, height=56, rx=4),
                     S("rect", "brass", x=60, y=-32, width=18, height=64, rx=6),
                     hi("rect", 0.4, x=-24, y=-18, width=84, height=8, rx=4)], "translate(96,170) rotate(-40)"),
 "LanternBomb": [S("circle", "url(#r_fire)", out=False, cx=128, cy=140, r=112)] + lantern("orange", "fire")[1:]
                + [S("path", None, d="M156,54 C176,40 176,24 196,22", stroke=NAVY, stroke_width=14),
                   S("path", None, d="M156,54 C176,40 176,24 196,22", stroke="#f2deb0", stroke_width=6),
                   S("path", "yellow", line=5, d="M204,4 L210,16 L224,14 L214,24 L222,36 L208,32 L202,44 L198,30 L184,28 L196,20 Z"),
                   S("rect", "red", line=5, x=96, y=118, width=64, height=20, rx=6)],
}
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
for k, v in ICONS.items():
    open(os.path.join(out, k + ".svg"), "w", encoding="utf-8").write(svg(v, 512))
print(len(ICONS))
