# LanguageLearnApp

Web app for Spanish speakers learning German. One static page, `index.html` (HTML + CSS + JS, no framework, no build step, no backend), plus MP3 clips in `audio/`, published with GitHub Pages at https://aantars.github.io/languageLearnApp/ from `main`. Vocabulary is in `GLOSSARY.md`: use Section, Range, Mode, Item, Dictation, Spelling dictation.

**Keep this file current.** After any change to behaviour, structure, decisions or tooling, update the matching section in the same commit.

## Conversation and UI language

- Talk to the user in Spanish.
- Write all UI text, code and comments in English. Pronunciation hints use Spanish spelling (`zwei → tsvai`, `G → gue`). Use typographic quotes and apostrophes (`“ ” ’`).

## Structure

- `index.html`: the whole app, edited directly.
- `audio/numbers/<0-20>.mp3`, `audio/letters/<slug>.mp3`, `audio/words/<slug>.mp3`: 151 clips (~410 KB). `slug()` lowercases and maps ä→ae, ö→oe, ü→ue, ß→ss (`ß` → `ss.mp3`).
- `build_audio.ps1`: regenerates all of `audio/` from `N`, `L` and `WORDS` in `index.html`, with Piper (`de_DE-thorsten-high`) and ffmpeg installed outside the repo in `C:\personal\tools`. Run it after changing those arrays: `powershell -NoProfile -ExecutionPolicy Bypass -File build_audio.ps1`. Its `$SAY` map overrides the text for words Piper misreads (`Blume` → `Bluhme`). Before adding words, check Piper’s phonemes with `--debug`.
- Data lives at the top of the script: `N` (numbers), `L` (26 letters + Ä Ö Ü ß: upper, lower, name, Spanish pronunciation, text to synthesize), `WORDS` (100 words for Spelling dictation: German, Spanish), `SECS` (per-Section ranges, tips, mode list, prompts, `clip`/`tts` per item).
- The UI is data-driven: `st.sec` is the active Section (`null` = home), and `disp/name/pron/clip/tts` of that Section feed every generic Mode. Add a Section by adding an entry to `SECS`.

## Decisions to keep

- **On-screen keyboards only** (QWERTZ with ä ö ü ß, numeric pads). The native mobile keyboard froze the page intermittently on Android Chrome. Checking an answer updates the DOM in place (`#fbslot`, remove keyboard), never a full re-render.
- **Fixed clips first, system voice as fallback.** Every sound (cards, Listen, both Dictations, Spelling dictation, the ▶ word button in Spelling dictation feedback) plays a clip from `audio/`; if the clip cannot play, `speechSynthesis` (de-DE) says the `tts` text instead. The user chose Thorsten over Kerstin (Kerstin is low quality and clips short words).
- **Dictation audio**: one reused `Audio` element (`dAudio`) with `src` swapped per clip, so iOS lets later clips play; `dTok` cancels stale playback. Clips set `defaultPlaybackRate` before `src`. `startQuiz` warms the round’s clips with `fetch` so dictations do not stall on the network.
- **Piper settings**: `length_scale` 1.1 for numbers and words, 1.6 for letters (letter names came out clipped), `noise_w` 0.3 for steady durations. Letter texts in `L[i][4]` are tuned for Piper: C is `Zeh` (`Tse` gets spelled out), ß is `Eszett`. Isolated vowels (U, Ü, E) are still short (~0.2 s); that is the model.
- Spelling dictation spells the word as written, so ß is spelled “Eszett”, not “S S”.
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

- Pronunciation improvements proposed but not done: rank system voices (prefer de-DE “Natural/Neural” ones) for the fallback, a slow-replay button, stressed syllables in the hints (`TSVAN-tsij`), Spanish-spelling hints for the 100 words, short tips on sounds Spanish lacks, and a “listen and repeat” Mode that records the user with `MediaRecorder`.
- The 100 words and the letter pronunciations were chosen by the assistant; the user may still adjust them.
