#!/usr/bin/env python3
"""Build a macOS ICNS file with legacy and Retina PNG representations."""

from __future__ import annotations

import io
import struct
import sys
from pathlib import Path

from PIL import Image


ICON_TYPES = (
    (b"icp4", 16),
    (b"icp5", 32),
    (b"icp6", 64),
    (b"ic07", 128),
    (b"ic08", 256),
    (b"ic09", 512),
    (b"ic10", 1024),
    (b"ic11", 32),
    (b"ic12", 64),
    (b"ic13", 256),
    (b"ic14", 512),
)


def png_bytes(image: Image.Image, size: int) -> bytes:
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    output = io.BytesIO()
    resized.save(output, format="PNG", optimize=True)
    return output.getvalue()


def build(source: Path, destination: Path) -> None:
    with Image.open(source) as opened:
        image = opened.convert("RGBA")

    encoded = {size: png_bytes(image, size) for _, size in ICON_TYPES}
    chunks = []
    for icon_type, size in ICON_TYPES:
        payload = encoded[size]
        chunks.append(icon_type + struct.pack(">I", len(payload) + 8) + payload)

    toc_payload = b"".join(chunk[:8] for chunk in chunks)
    toc = b"TOC " + struct.pack(">I", len(toc_payload) + 8) + toc_payload
    body = toc + b"".join(chunks)
    destination.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: make_icns.py SOURCE.png DESTINATION.icns")
    build(Path(sys.argv[1]), Path(sys.argv[2]))
