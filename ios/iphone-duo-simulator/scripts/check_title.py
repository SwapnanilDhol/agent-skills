#!/usr/bin/env python3
"""Guard against clicking the wrong simulator in Device Hub.

check_title.py ref WORKDIR    save the title crop of the device Device Hub shows now
check_title.py check WORKDIR  exit 0 only if the title still matches the saved crop

Other sessions on the same Mac switch Device Hub's selected device, sometimes without
honouring the shared lock. Compare before every click on device content.
"""
import os
import subprocess
import sys

from PIL import Image, ImageChops

mode, work = sys.argv[1], sys.argv[2]
rect = [float(v) for v in os.environ.get("DUO_TITLE_RECT", "366 108 560 127").split()]
shot = os.path.join(work, "title-check.png")
ref = os.path.join(work, "title-ref.png")

subprocess.run(["screencapture", "-x", shot], check=True)
image = Image.open(shot).convert("RGB")
scale = image.width / float(os.environ.get("DUO_SCREEN_WIDTH_PT", "1470"))
crop = image.crop(tuple(int(v * scale) for v in rect))

if mode == "ref":
    crop.save(ref)
    print(f"saved reference title crop to {ref}")
    sys.exit(0)

if not os.path.exists(ref):
    print("no reference title; run `duo.sh ref-title` with your device selected", file=sys.stderr)
    sys.exit(3)

reference = Image.open(ref).convert("RGB")
if reference.size != crop.size:
    print("title crop size changed; re-run ref-title", file=sys.stderr)
    sys.exit(1)
diff = ImageChops.difference(crop, reference)
changed = sum(1 for px in diff.getdata() if max(px) > 40)
print(f"title diff px {changed}")
sys.exit(0 if changed < 50 else 1)
