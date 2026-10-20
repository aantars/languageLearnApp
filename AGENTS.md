# LanguageLearnApp

Web app for Spanish speakers learning German. One static file, `index.html` (HTML + CSS + JS, no framework, no build step, no backend), published with GitHub Pages at https://aantars.github.io/languageLearnApp/ from `main`. Vocabulary is in `GLOSSARY.md`: use Section, Range, Mode, Item, Dictation, Spelling dictation.

**Keep this file current.** After any change to behaviour, structure, decisions or tooling, update the matching section in the same commit.

## Conversation and UI language

- Talk to the user in Spanish.
- Write all UI text, code and comments in English. Pronunciation hints use Spanish spelling (`zwei → tsvai`, `G → gue`). Use typographic quotes and apostrophes (`“ ” ’`).

## Structure

- `index.template.html`: the source, with `const AUDIO = [/* 21 data URIs */];` as a placeholder.
- `index.html`: the template plus the 21 base64 MP3 clips for the numbers 0–20 (~195 KB). The only difference is that `AUDIO` line.
- `build_audio.py`: generates the clips with espeak-ng + ffmpeg and writes `index.html`. This machine has neither (nor Python). To change the app, apply the same edit to both HTML files with an exact-match replace, and confirm each target matches once.
- Data lives at the top of the script: `N` (numbers), `L` (26 letters + Ä Ö Ü ß: upper, lower, name, Spanish pronunciation, text for the system voice), `WORDS` (100 words for Spelling dictation: German, Spanish), `SECS` (per-Section ranges, tips, mode list, prompts).
- The UI is data-driven: `st.sec` is the active Section (`null` = home), and `disp/name/pron` of that Section feed every generic Mode. Add a Section by adding an entry to `SECS`.

## Decisions to keep

- **On-screen keyboards only** (QWERTZ with ä ö ü ß, numeric pads). The native mobile keyboard froze the page intermittently on Android Chrome. Checking an answer updates the DOM in place (`#fbslot`, remove keyboard), never a full re-render.
- **Dictation audio**: one reused `Audio` element (`dAudio`) with `src` swapped per clip, so iOS lets later clips play; `dTok` cancels stale playback. Number clips set `defaultPlaybackRate` before `src`.
- **Alphabet and Spelling dictation use `speechSynthesis` (de-DE)** with the `L[i][4]` text. No letter or word clips exist because the user declined installing audio tools for now.
- **No scores are saved.** `localStorage` holds only dictation speed (`zahlen-speed`) and last Section (`llapp-section`). Wrap every storage access in `try/catch`.
- `norm()` makes typed answers forgiving: ä/ae→a, ö/oe→o, ü/ue→u, ß→ss. Spelling dictation ignores the Range.
- Learn grid uses `minmax(0,1fr)` and `min-width:0` (long words overflowed otherwise). Next/Result sits inside the feedback box so it shows without scrolling at ~360×700. `body::before` keeps `pointer-events:none`.
- Colours are CSS variables with a `prefers-color-scheme` dark set.

## Verify a change

No test suite. Use headless Chrome (`C:\Program Files\Google\Chrome\Application\chrome.exe --headless=new --virtual-time-budget=30000 --dump-dom file:///…`) on a copy of `index.html` with an extra `<script>` appended before `</body>`. That script stubs audio, loops every Section × Range × Mode through a full round, collects `window.onerror`, and writes `{errs, log}` into the DOM. Expect `errs: []`. Headless Chrome imposes a minimum window width above 360 px, so judge mobile layout by loading the page in a 360 px `<iframe>` and taking a `--screenshot`.

## Git

- Work on `main`; a push to `main` republishes the site.
- End commit messages with the `Co-Authored-By` line the session provides.
- Git warns about LF→CRLF on Windows; it is harmless.

## Open ideas

- Natural-sounding fixed audio for letters, words and numbers (Piper with a German voice is the favoured option) once the user allows installing tools.
- The 100 words and the letter pronunciations were chosen by the assistant; the user may still adjust them.
