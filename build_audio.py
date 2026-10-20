#!/usr/bin/env python3
"""Builds index.html from index.template.html by embedding 21 German MP3 clips (0-20)
as base64 data URIs. Requires: espeak-ng and ffmpeg on PATH."""
import base64, json, subprocess, tempfile, pathlib

WORDS = ["null","eins","zwei","drei","vier","fünf","sechs","sieben","acht","neun","zehn",
         "elf","zwölf","dreizehn","vierzehn","fünfzehn","sechzehn","siebzehn","achtzehn",
         "neunzehn","zwanzig"]
PLACEHOLDER = "const AUDIO = [/* 21 data URIs */];"

here = pathlib.Path(__file__).parent
template = (here / "index.template.html").read_text(encoding="utf-8")
assert PLACEHOLDER in template, "placeholder not found"

uris = []
with tempfile.TemporaryDirectory() as tmp:
    tmp = pathlib.Path(tmp)
    for i, word in enumerate(WORDS):
        wav, mp3 = tmp / f"{i}.wav", tmp / f"{i}.mp3"
        subprocess.run(["espeak-ng", "-v", "de", "-s", "110", "-p", "45", "-w", str(wav), word], check=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                        "-af", "silenceremove=start_periods=1:start_threshold=-50dB,volume=2.0",
                        "-ac", "1", "-ar", "22050", "-b:a", "32k", str(mp3)], check=True)
        uris.append("data:audio/mpeg;base64," + base64.b64encode(mp3.read_bytes()).decode())

out = template.replace(PLACEHOLDER, "const AUDIO = " + json.dumps(uris) + ";")
(here / "index.html").write_text(out, encoding="utf-8")
print(f"index.html written ({len(out)//1024} KB)")

