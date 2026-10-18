#!/usr/bin/env python3
"""Chạy lệnh trên máy thật (Ubuntu) và lưu output thành ảnh kiểu terminal.
termshot.py <out.png> '<lệnh shell>' ['<lệnh 2>' ...]"""
import subprocess, sys, datetime, getpass, socket
from PIL import Image, ImageDraw, ImageFont

out, cmds = sys.argv[1], sys.argv[2:]
prompt = f"{getpass.getuser()}@{socket.gethostname()}:~$ "
lines = [f"# {datetime.datetime.now():%d/%m/%Y %H:%M:%S} (+07) - Ubuntu host"]
for c in cmds:
    lines.append(prompt + c)
    r = subprocess.run(c, shell=True, capture_output=True, text=True, timeout=180)
    lines += (r.stdout + r.stderr).rstrip("\n").split("\n")
lines.append(prompt)

font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 15)
w = max(80, max(len(l) for l in lines)) * 9 + 30
h = len(lines) * 19 + 50
img = Image.new("RGB", (w, h), "#300a24")
d = ImageDraw.Draw(img)
d.rectangle([0, 0, w, 24], fill="#2c2c2c")
d.text((10, 4), f"{getpass.getuser()}@{socket.gethostname()}: ~", fill="#dddddd", font=font)
y = 34
for l in lines:
    color = "#8ae234" if l.startswith(prompt) else "#ffffff"
    d.text((12, y), l, fill=color, font=font)
    y += 19
img.save(out)
print("\n".join(lines))
