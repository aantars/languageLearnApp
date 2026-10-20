# LanguageLearnApp

German for Spanish speakers. A single-file web app (`index.html`, no build, no server) with two sections:

- **Numbers** (0–20): Learn cards, 4 practice modes and 2 dictations. Audio clips are embedded.
- **Alphabet** (A–Z plus Ä, Ö, Ü, ß): Learn cards, 4 practice modes and a spelling dictation with 100 everyday words. Audio uses the device's German voice (`speechSynthesis`).

Live: https://aantars.github.io/languageLearnApp/

## Files

- `index.html`: the app, ready to open or publish (GitHub Pages).
- `index.template.html`: the same app without the embedded audio. `build_audio.py` fills in the number clips (needs espeak-ng and ffmpeg).
- `GLOSSARY.md`: project vocabulary (Section, Range, Mode, Item, Dictation).
