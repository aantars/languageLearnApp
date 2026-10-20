# Handoff: reproducir la app «Zahlen 0–20» (curso de números en alemán)

Este documento contiene todo lo necesario para que Claude Code (u otra persona) reconstruya **exactamente** la aplicación. El código fuente completo está en la sección 6 y el script de audio en la sección 7. Si se siguen los pasos de la sección 2, el `index.html` resultante es idéntico byte a byte al original.

## 1. Qué es

- Mini-curso para **hispanohablantes** que aprenden los números del 0 al 20 en alemán. La interfaz está en **inglés** (botones, instrucciones, consejos); las ayudas de pronunciación usan ortografía española (por ejemplo `zwei → tsvai`).
- **Un único archivo** `index.html` (HTML + CSS + JS), sin frameworks, sin build de JS y sin servidor. Pensado sobre todo para móvil (Android Chrome), con modo claro y oscuro automático.
- El audio (21 clips MP3, de *null* a *zwanzig*) va **incrustado como data URIs base64** dentro del JS (`const AUDIO = [...]`, unos 154 KB). Tamaño final: unos 183 KB.
- Única dependencia externa: la fuente **Bricolage Grotesque** de Google Fonts (con fuentes del sistema como alternativa).
- Todo se almacena en el navegador del usuario (`localStorage`, siempre dentro de try/catch): mejores puntuaciones (`zahlen-best`) y velocidad de dictado por modo (`zahlen-speed`). No hay backend ni llamadas a ninguna API.

## 2. Cómo reconstruirla (pasos para Claude Code)

1. Crea una carpeta de proyecto, por ejemplo `zahlen/`.
2. Copia el contenido de la sección 6 a `zahlen/index.template.html` (tal cual, sin modificar nada; la línea `const AUDIO = [/* 21 data URIs */];` es un marcador).
3. Copia la sección 7 a `zahlen/build_audio.py`.
4. Instala las herramientas de audio:
   - macOS: `brew install espeak-ng ffmpeg`
   - Ubuntu/Debian: `sudo apt-get install espeak-ng ffmpeg`
   - Windows: instala `espeak-ng` y `ffmpeg` y añádelos al PATH (o usa WSL).
5. Ejecuta `python3 build_audio.py`. Genera `index.html` (≈183 KB) con el audio incrustado.
6. Abre `index.html` en el navegador (doble clic o `python3 -m http.server`). No hace falta nada más.

Notas:
- Si la versión de `espeak-ng` es distinta de la original (1.51), la voz puede sonar ligeramente diferente. Todo lo demás es idéntico.
- Si no se pueden instalar `espeak-ng`/`ffmpeg`, la app sigue funcionando sin los clips: cada función de audio tiene como alternativa la voz del sistema (`speechSynthesis`, `de-DE`) en las tarjetas y el modo Listen. Los dictados necesitan los clips.

## 3. Comportamiento funcional (resumen)

**Estructura de pantalla:** título «Zahlen 0–20» y frase de introducción; pestañas **Learn** / **Practice**; chips de rango; una línea de estado de audio; y la vista activa.

**Rangos (chips):** `0–20` (id `all`), `0–6` (`a`), `7–12` (`b2`), `13–20` (`c2`). Afectan a Learn y a los modos de Practice (excepto a los dictados). Los ids `b2`/`c2` se renombraron a propósito para no heredar puntuaciones de rangos antiguos.

**Learn:** cuadrícula de 2 columnas (`repeat(2,minmax(0,1fr))`) con tarjetas: cifra grande, palabra alemana y pronunciación escrita. Al tocar una tarjeta suena el clip. Debajo, dos consejos de pronunciación por rango y el botón «Practice this range».

**Practice (menú de modos):** cada modo muestra su mejor puntuación («Best: x/N») si existe.
1. **Number → word:** se ve la cifra y se elige entre 4 palabras. 10 preguntas.
2. **Word → number:** se ve la palabra y se elige entre 4 cifras. 10 preguntas.
3. **Listen:** suena el número y se elige la cifra (4 opciones). 10 preguntas. Reproduce solo al empezar y en cada pregunta nueva.
4. **Type the word:** se ve la cifra y se escribe la palabra con un **teclado en pantalla propio** (QWERTZ: `qwertzuiop` / `asdfghjkl` / `yxcvbnmüö` + ⌫) y un botón Check. Se acepta `ue`/`oe` por `ü`/`ö` y `u`/`o` sin diéresis (función `norm`). Con teclado físico también se puede escribir, con Enter para comprobar y pasar a la siguiente. 10 preguntas.
5. **Dictation: 9 digits:** la voz dicta un número de 9 dígitos, uno a uno, con pausa; el usuario lo escribe en un teclado numérico en pantalla (3 columnas: 1–9, ⌫, 0, Check). 5 números por ronda. Velocidad por defecto: *Very fast*.
6. **Dictation: 5 numbers:** la voz dicta 5 números al azar entre 0 y 20 (palabras completas). El usuario rellena 5 casillas con un teclado de 4 columnas (1 2 3 ⌫ / 4 5 6 › / 7 8 9 0 / Check). Las casillas avanzan solas salvo tras un 1 o un 2 (puede ser un número de una o dos cifras): ahí se pulsa `›`. Se puede tocar cualquier casilla para volver a ella. 3 dictados por ronda (15 números). Velocidad por defecto: *Normal*.

**Selector de velocidad de dictado** (desplegable junto al botón Listen, uno por modo, guardado en `localStorage`): Slow (rate 0.85, pausa ×1.5), Normal (1, ×1), Fast (1.25, ×0.55), Very fast (1.5, ×0.22), Ultra fast (1.7, ×0.12). Pausa base: 900 ms en 9 dígitos y 1000 ms en 5 números. Al cambiar la velocidad, el dictado se reinicia.

**Reglas comunes de los ejercicios:**
- Cabecera con «Question n of 10» (en dictados «Number n of 5» / «Dictation n of 3») y «Correct: n»; barra de progreso amarilla.
- Tras responder: las opciones se colorean (verde/rojo) y aparece un recuadro de feedback con «Correct!» o «Not quite. The answer is:» más la respuesta y su pronunciación, con el botón **Next** (o **Result** en la última) **dentro del mismo recuadro, a la derecha** (para evitar scroll en móvil).
- Pantalla de resultado: «n/total», mensaje (Perfect!, Very good!, You are on the right track., Review and try again.), lista de fallos y botones «Another round», «Change mode», «Review cards». Se guarda la mejor puntuación por modo y rango.
- En dictados el botón Listen muestra «▶ Listen», «Playing…» y «↻ Listen again», y una fila de puntos se ilumina al avanzar por cada dígito. Empieza a sonar automáticamente al llegar a cada dictado.
- Hay un botón «Quit round» (borde fino, ancho completo) al final de cada ejercicio.

**Diseño:** tonos azul tinta (`#14213D`) sobre fondo azulado claro, acento amarillo (`#FFC93C`), verde/rojo para acierto/fallo; todo definido en variables CSS con valores de modo oscuro (`prefers-color-scheme`). Fuente Bricolage Grotesque (400/600/800). Contenedor central `max-width:560px`. Cifras grandes en peso 800. Respeta `prefers-reduced-motion` y las áreas seguras (`env(safe-area-inset-*)`).

## 4. Decisiones importantes y trampas ya resueltas (no deshacer)

1. **No usar el teclado nativo del móvil para escribir** (modo Type the word y dictados). Con `<input>` nativo la página se quedaba sin responder de forma intermitente en Android Chrome tras responder. Por eso hay teclados propios en pantalla. En el modo de escribir y en los dictados, al comprobar **no se vuelve a pintar toda la vista**: se actualiza en el sitio (quitar teclado, rellenar `#fbslot`).
2. **Audio de los dictados:** se reutiliza **un único elemento `Audio`** (`dAudio`) cambiando `src` en cada dígito, y se espera a `ended` con un tiempo máximo de seguridad. Así los navegadores móviles (sobre todo iOS) no bloquean los clips posteriores al primer toque del usuario. Hay un contador `dTok` que cancela reproducciones antiguas al salir o reiniciar.
3. **Velocidad del audio:** se fija `defaultPlaybackRate` antes de asignar `src` y `playbackRate` después.
4. **Cuadrícula de Learn:** usar `minmax(0,1fr)` y `min-width:0` en las tarjetas; con `1fr` a secas, las tarjetas con palabras largas se salían por la derecha.
5. **Botón Next dentro del recuadro de feedback**, junto al mensaje, y espacios algo reducidos (cifra grande 76 px en ejercicios) para que no haga falta scroll en pantallas de ~360×700.
6. La capa fija `body::before` (zona segura superior) lleva `pointer-events:none` para no interceptar toques.
7. **Todo acceso a `localStorage` va dentro de `try/catch`**, y la app debe funcionar si falla.
8. Los textos visibles deben usar tipografía correcta (apóstrofo `’`, comillas `“ ”`) y la interfaz debe permanecer **en inglés**.
9. Sin dependencias de red salvo la fuente de Google Fonts.

## 5. Lista de comprobación

- [ ] `index.html` abre sin errores en consola y pesa ≈183 KB.
- [ ] Learn: 2 columnas completas, sin recortes en un móvil de ~360 px; tocar una tarjeta reproduce el clip.
- [ ] Cambiar de rango actualiza tarjetas y consejos (0–6, 7–12, 13–20).
- [ ] Los 6 modos de Practice funcionan de principio a fin (ronda completa y pantalla de resultado).
- [ ] En el modo Type the word y en los dictados no aparece el teclado del sistema.
- [ ] El botón Next es visible sin scroll tras responder (móvil ~360×700).
- [ ] El desplegable de velocidad cambia el ritmo del dictado y se recuerda al recargar.
- [ ] Modo oscuro correcto al cambiar el tema del sistema.

## 6. Código fuente completo: `index.template.html`

````html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Zahlen 0–20: German numbers mini-course</title>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,800&display=swap" rel="stylesheet">
<style>
:root{
  box-sizing:border-box;
  padding-top:env(safe-area-inset-top,0px);
  padding-bottom:env(safe-area-inset-bottom,0px);
  --bg:#F2F5FA; --surface:#FFFFFF; --ink:#14213D; --muted:#5B6783; --line:#D5DCEA;
  --accent:#FFC93C; --on-accent:#14213D; --good:#1B7F4B; --good-bg:#DDF3E6; --bad:#B3261E; --bad-bg:#FBE1DE;
  --chip:#E4E9F4;
  color-scheme:light;
}
@media (prefers-color-scheme:dark){
  :root:not([data-theme="light"]){
    --bg:#0E1526; --surface:#18223A; --ink:#EEF1F8; --muted:#A3AEC7; --line:#2C3956;
    --accent:#FFC93C; --on-accent:#14213D; --good:#6FD39A; --good-bg:#17382A; --bad:#FF9A92; --bad-bg:#43211F;
    --chip:#222E4B; color-scheme:dark;
  }
}
:root[data-theme="dark"]{
  --bg:#0E1526; --surface:#18223A; --ink:#EEF1F8; --muted:#A3AEC7; --line:#2C3956;
  --accent:#FFC93C; --on-accent:#14213D; --good:#6FD39A; --good-bg:#17382A; --bad:#FF9A92; --bad-bg:#43211F;
  --chip:#222E4B; color-scheme:dark;
}
html{scroll-padding-top:env(safe-area-inset-top,0px)}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:"Bricolage Grotesque",system-ui,-apple-system,"Segoe UI",sans-serif;font-size:17px;line-height:1.45}
body::before{content:"";position:fixed;inset:0 0 auto;height:env(safe-area-inset-top,0px);background:var(--bg);z-index:10;pointer-events:none}
main{max-width:560px;margin:0 auto;padding:18px 16px 40px}
h1{font-size:30px;line-height:1.1;margin:6px 0 4px;font-weight:800;letter-spacing:-.02em}
.sub{color:var(--muted);margin:0 0 16px}
.tabs{display:flex;gap:6px;background:var(--chip);padding:4px;border-radius:14px;margin-bottom:14px}
.tabs button{flex:1;border:0;background:transparent;color:var(--muted);font:inherit;font-weight:600;padding:10px;border-radius:10px;cursor:pointer}
.tabs button[aria-selected="true"]{background:var(--surface);color:var(--ink);box-shadow:0 1px 0 var(--line)}
.chips{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px}
.chip{border:1.5px solid var(--line);background:transparent;color:var(--ink);font:inherit;font-weight:600;font-size:15px;padding:7px 14px;border-radius:999px;cursor:pointer}
.chip[aria-pressed="true"]{background:var(--ink);color:var(--bg);border-color:var(--ink)}
button:focus-visible,input:focus-visible{outline:3px solid var(--accent);outline-offset:2px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.num{background:var(--surface);border:1.5px solid var(--line);border-radius:16px;padding:12px 14px;text-align:left;font:inherit;color:var(--ink);cursor:pointer;display:flex;align-items:center;gap:12px}
.num .d{font-size:40px;font-weight:800;line-height:1;min-width:2ch;letter-spacing:-.03em}
.num .w{font-weight:600;font-size:19px;line-height:1.15}
.num .p{color:var(--muted);font-size:14px}
.num:active{border-color:var(--accent)}
.tip{background:var(--surface);border-left:6px solid var(--accent);border-radius:8px 14px 14px 8px;padding:12px 14px;margin:14px 0;font-size:16px}
.tip strong{display:block;margin-bottom:2px}
.hint{color:var(--muted);font-size:14px;margin:8px 0 0}
.modes{display:grid;gap:10px;margin-top:4px}
.mode{background:var(--surface);border:1.5px solid var(--line);border-radius:16px;padding:14px 16px;font:inherit;color:var(--ink);text-align:left;cursor:pointer}
.mode b{display:block;font-size:18px}
.mode span{color:var(--muted);font-size:15px}
.mode:active{border-color:var(--accent)}
.bar{height:8px;background:var(--chip);border-radius:99px;overflow:hidden;margin:2px 0 18px}
.bar i{display:block;height:100%;background:var(--accent);transition:width .25s}
.meta{display:flex;justify-content:space-between;color:var(--muted);font-size:14px}
.prompt{text-align:center;margin:18px 0}
.big{font-size:96px;font-weight:800;line-height:1;letter-spacing:-.04em}
.bigw{font-size:44px;font-weight:800;line-height:1.1;letter-spacing:-.02em;overflow-wrap:anywhere}
.q{color:var(--muted);margin:0 0 8px}
.opts{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.opt{background:var(--surface);border:1.5px solid var(--line);border-radius:14px;padding:16px 8px;font:inherit;font-size:22px;font-weight:600;color:var(--ink);cursor:pointer}
.opt:disabled{cursor:default}
.opt.ok{background:var(--good-bg);border-color:var(--good);color:var(--good)}
.opt.no{background:var(--bad-bg);border-color:var(--bad);color:var(--bad)}
.play{display:inline-flex;align-items:center;gap:8px;border:0;background:var(--accent);color:var(--on-accent);font:inherit;font-weight:700;font-size:18px;padding:14px 22px;border-radius:999px;cursor:pointer}
.field{width:100%;font:inherit;font-size:26px;font-weight:600;text-align:center;padding:14px;border-radius:14px;border:1.5px solid var(--line);background:var(--surface);color:var(--ink)}
.cta{width:100%;margin-top:12px;border:0;background:var(--ink);color:var(--bg);font:inherit;font-weight:700;font-size:18px;padding:14px;border-radius:14px;cursor:pointer}
.cta.alt{background:transparent;color:var(--ink);border:1.5px solid var(--line)}
.fb{margin-top:14px;padding:12px 14px;border-radius:14px;font-weight:600}
.fb.ok{background:var(--good-bg);color:var(--good)}
.fb.no{background:var(--bad-bg);color:var(--bad)}
.fb small{display:block;font-weight:400;color:var(--ink)}
.result{text-align:center;padding:20px 0}
.result .big{color:var(--ink)}
.result p{color:var(--muted)}
.miss{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-top:8px}
.miss span{background:var(--chip);border-radius:999px;padding:6px 12px;font-weight:600;font-size:15px}
body.quiz .bar{margin:2px 0 10px}
body.quiz .prompt{margin:8px 0 12px}
body.quiz .big{font-size:76px}
.fb{display:flex;align-items:center;justify-content:space-between;gap:12px}
.fb .cta{width:auto;margin:0;padding:12px 20px;flex:none}
div.field{min-height:66px;display:flex;align-items:center;justify-content:center;overflow-wrap:anywhere}
div.field .ph{color:var(--muted);font-weight:400}
div.field.ok{border-color:var(--good);color:var(--good);background:var(--good-bg)}
div.field.no{border-color:var(--bad);color:var(--bad);background:var(--bad-bg)}
.kb{margin-top:10px;display:grid;gap:6px}
.kr{display:flex;gap:4px;justify-content:center}
.key{flex:1;min-width:0;height:44px;border:1.5px solid var(--line);border-radius:9px;background:var(--surface);color:var(--ink);font:inherit;font-weight:600;font-size:19px;padding:0;touch-action:manipulation;cursor:pointer;-webkit-user-select:none;user-select:none}
.key.wide{flex:1.5}
.key:active{background:var(--accent);color:var(--on-accent);border-color:var(--accent)}
.slots{display:flex;gap:6px;justify-content:center;margin:8px 0}
.slot{flex:1;max-width:52px;height:56px;border:1.5px solid var(--line);border-radius:12px;background:var(--surface);display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:800}
.slot.ok{border-color:var(--good);color:var(--good);background:var(--good-bg)}
.slot.no{border-color:var(--bad);color:var(--bad);background:var(--bad-bg)}
.dots{display:flex;gap:7px;justify-content:center;margin:10px 0 0}
.dots i{width:10px;height:10px;border-radius:50%;background:var(--chip);display:block}
.dots i.on{background:var(--accent)}
.pad{display:grid;grid-template-columns:repeat(3,1fr);gap:6px;margin-top:6px}
.pad .key{height:46px;font-size:22px}
.key.go{background:var(--ink);color:var(--bg);border-color:var(--ink);font-size:17px}
.slots.nine{gap:4px}
.slots.nine .slot{height:48px;font-size:22px;border-radius:9px}
.slot.act{border-color:var(--accent);box-shadow:0 0 0 2px var(--accent)}
.slots.five .slot{cursor:pointer}
.pad.n{grid-template-columns:repeat(4,1fr)}
.pad.n .go{grid-column:1 / -1}
.prow{display:flex;gap:10px;justify-content:center;align-items:center;flex-wrap:wrap}
.spd{display:inline-flex;align-items:center;gap:6px;color:var(--muted);font-size:15px}
.spd select{font:inherit;font-weight:600;font-size:16px;color:var(--ink);background:var(--surface);border:1.5px solid var(--line);border-radius:12px;padding:10px 8px}
.grid{grid-template-columns:repeat(2,minmax(0,1fr))}
.num{min-width:0;padding:10px 12px;gap:8px}
.num .d{font-size:34px;min-width:1.5ch;flex:none}
.num>span:last-child{min-width:0}
.num .w{font-size:17px;overflow-wrap:anywhere}
.num .p{overflow-wrap:anywhere}
@media (prefers-reduced-motion:reduce){.bar i{transition:none}}
</style>
</head>
<body>
<main>
  <h1>Zahlen 0–20</h1>
  <p class="sub">Learn the German numbers and practice them.</p>
  <div class="tabs" role="tablist">
    <button role="tab" id="tab-learn" aria-selected="true">Learn</button>
    <button role="tab" id="tab-practice" aria-selected="false">Practice</button>
  </div>
  <div class="chips" id="scope" role="group" aria-label="Number range"></div>
  <p class="hint" id="audiomsg" role="status" style="margin:0 0 12px"></p>
  <div id="view"></div>
</main>

<script>
const N = [
 ["null","nul"],["eins","ains"],["zwei","tsvai"],["drei","drai"],["vier","fiir"],["fünf","fünf"],["sechs","sex"],
 ["sieben","siiben"],["acht","ajt"],["neun","noin"],["zehn","tsen"],["elf","elf"],["zwölf","tsvölf"],
 ["dreizehn","drai-tsen"],["vierzehn","fiir-tsen"],["fünfzehn","fünf-tsen"],["sechzehn","sej-tsen"],
 ["siebzehn","siip-tsen"],["achtzehn","ajt-tsen"],["neunzehn","noin-tsen"],["zwanzig","tsvan-tsij"]
];
const SCOPES = [
  {id:"all", label:"0–20", from:0, to:20},
  {id:"a", label:"0–6", from:0, to:6},
  {id:"b2", label:"7–12", from:7, to:12},
  {id:"c2", label:"13–20", from:13, to:20}
];
const TIPS = {
  all:[
    ["Two rules to remember","From 13 to 19 the pattern is unit + zehn (drei + zehn = dreizehn). 11 and 12 are special: learn them by heart."],
    ["Key sounds","z sounds like the ts in Spanish “tsunami”, the v in vier sounds like f, and ü is a u said with your lips as if you were saying i."]
  ],
  a:[["The ü in fünf","Say a Spanish “i” and, without moving your tongue, round your lips as if saying “u”. That is ü."],
     ["Watch out for zwei","Read it tsvai: z sounds like ts and w is a soft Spanish v."]],
  b2:[["Elf and zwölf","They follow no pattern. They are the only two in this stretch you must memorize."],
     ["The ch in acht","After a it sounds like a soft Spanish j, like in “ajo” but lighter."]],
  c2:[["The -zehn pattern","Unit + zehn: drei + zehn, vier + zehn, fünf + zehn, acht + zehn, neun + zehn."],
     ["Two exceptions","Sechzehn drops the s of sechs, and siebzehn drops the en of sieben. And 20 is zwanzig, ending in -zig."]]
};
const AUDIO = [/* 21 data URIs */];
const st = {tab:"learn", scope:"all", quiz:null, best:{}};
try{ st.best = JSON.parse(localStorage.getItem("zahlen-best")||"{}"); }catch(e){}

const $ = s => document.querySelector(s);
const pool = () => { const s = SCOPES.find(x=>x.id===st.scope); return Array.from({length:s.to-s.from+1},(_,i)=>s.from+i); };
const shuffle = a => { a=a.slice(); for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];} return a; };
const esc = s => String(s).replace(/&/g,"&amp;").replace(/"/g,"&quot;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
const norm = s => s.toLowerCase().trim().replace(/ü/g,"u").replace(/ö/g,"o").replace(/ue/g,"u").replace(/oe/g,"o").replace(/\s+/g,"");

const isDict = m => m==="dict9" || m==="dictn";
const roundLen = m => m==="dictn" ? 3 : isDict(m) ? 5 : 10;
const canSpeak = "speechSynthesis" in window;
let voice = null;
function loadVoice(){ if(!canSpeak) return; const v = speechSynthesis.getVoices().find(v=>/^de/i.test(v.lang)); if(v) voice=v; }
if(canSpeak){ loadVoice(); speechSynthesis.onvoiceschanged = loadVoice; }
let lastU = null;
function audioMsg(t){ const el=document.getElementById("audiomsg"); if(el) el.textContent=t; }
let clip = null;
function say(n){
  audioMsg("");
  try{
    if(clip){ clip.pause(); }
    clip = new Audio(AUDIO[n]);
    clip.volume = 1;
    const pr = clip.play();
    if(pr && pr.catch) pr.catch(() => sayTTS(n));
    return;
  }catch(e){}
  sayTTS(n);
}
function sayTTS(n){
  if(!canSpeak){ audioMsg("This browser does not support audio. Use the written pronunciation."); return; }
  try{
    const synth = window.speechSynthesis;
    loadVoice();
    const all = synth.getVoices();
    if(all.length && !voice){ audioMsg("Your device has no German voice installed. You can add one in your system language or voice settings."); }
    synth.cancel();
    const u = new SpeechSynthesisUtterance(N[n][0]);
    u.lang = "de-DE"; u.rate = .85; u.volume = 1;
    if(voice) u.voice = voice;
    let started = false;
    u.onstart = () => { started = true; };
    u.onerror = () => { audioMsg("Audio could not be played on this device."); };
    lastU = u;
    setTimeout(() => {
      synth.resume();
      synth.speak(u);
      setTimeout(() => { if(!started && !document.getElementById("audiomsg").textContent) audioMsg("No sound played. Check your volume and, on iPhone, that silent mode is off. If it still fails, use the written pronunciation."); }, 1800);
    }, 80);
  }catch(e){ audioMsg("Audio could not be played on this device."); }
}

function renderScope(){
  $("#scope").innerHTML = SCOPES.map(s=>`<button class="chip" data-s="${s.id}" aria-pressed="${s.id===st.scope}">${s.label}</button>`).join("");
  $("#scope").querySelectorAll("button").forEach(b=>b.onclick=()=>{st.scope=b.dataset.s; st.quiz=null; render();});
}

function renderLearn(){
  const nums = pool();
  const tips = TIPS[st.scope];
  $("#view").innerHTML = `
    <div class="grid">${nums.map(n=>`
      <button class="num" data-n="${n}" aria-label="${n}, ${N[n][0]}. Tap to listen">
        <span class="d">${n}</span>
        <span><span class="w">${N[n][0]}</span><br><span class="p">${N[n][1]}</span></span>
      </button>`).join("")}
    </div>
    <p class="hint">Tap a card to hear the pronunciation. The audio is a synthetic voice, so it sounds a bit robotic. The written pronunciation is approximate and uses Spanish spelling, for Spanish speakers.</p>
    ${tips.map(t=>`<div class="tip"><strong>${t[0]}</strong>${t[1]}</div>`).join("")}
    <button class="cta" id="go">Practice this range</button>`;
  document.querySelectorAll(".num").forEach(b=>b.onclick=()=>say(+b.dataset.n));
  $("#go").onclick=()=>setTab("practice");
}

const MODES = [
  {id:"n2w", title:"Number → word", desc:"You see the digits and pick the German word."},
  {id:"w2n", title:"Word → number", desc:"You see the word and pick the digits."},
  {id:"hear", title:"Listen", desc:"You hear the number and pick the digits."},
  {id:"type", title:"Type the word", desc:"You see the digits and type the German word."},
  {id:"dict9", title:"Dictation: 9 digits", desc:"You hear a 9-digit number, one digit at a time, like a phone number. Type it in. You can change the speed. 5 numbers per round."},
  {id:"dictn", title:"Dictation: 5 numbers", desc:"You hear 5 random numbers from 0 to 20 and type them in order. 3 dictations per round."}
];

function renderMenu(){
  const modes = MODES;
  const sc = SCOPES.find(x=>x.id===st.scope).label;
  $("#view").innerHTML = `<p class="q">Range: ${sc}. Each round has 10 questions.</p>
  <div class="modes">${modes.map(m=>`<button class="mode" data-m="${m.id}"><b>${m.title}</b><span>${m.desc}</span>${st.best[m.id+st.scope]!=null?`<span> Best: ${st.best[m.id+st.scope]}/${roundLen(m.id)}</span>`:""}</button>`).join("")}</div>`;
  document.querySelectorAll(".mode").forEach(b=>b.onclick=()=>startQuiz(b.dataset.m));
}

function startQuiz(mode){
  let p = shuffle(pool());
  while(p.length<10) p = p.concat(shuffle(pool()));
  st.quiz = {mode, qs:p.slice(0,10), i:0, score:0, done:false, picked:null, missed:[], typed:""};
  if(isDict(mode)){
    const len = mode==="dict9" ? 9 : 6;
    st.quiz.qs = Array.from({length:roundLen(mode)},()=> mode==="dictn"
      ? Array.from({length:5},()=>Math.floor(Math.random()*21))
      : Array.from({length:len},()=>Math.floor(Math.random()*10)).join(""));
  }
  document.body.classList.add("quiz");
  renderQuiz();
  if(mode==="hear") say(st.quiz.qs[0]);
  if(isDict(mode)) dictPlay();
}

function options(n){
  const others = shuffle(pool().filter(x=>x!==n)).slice(0,3);
  return shuffle([n,...others]);
}

function renderQuiz(){
  const q = st.quiz;
  if(q.i>=q.qs.length) return renderResult();
  if(isDict(q.mode)) return renderDict();
  const n = q.qs[q.i];
  const m = q.mode;
  let prompt="", body="";
  if(m==="n2w"){
    prompt = `<p class="q">How do you say it in German?</p><div class="big">${n}</div>`;
    q.opts = q.opts && q.optsFor===q.i ? q.opts : options(n);
    body = `<div class="opts">${q.opts.map(o=>optBtn(o,N[o][0],n)).join("")}</div>`;
  } else if(m==="w2n"){
    prompt = `<p class="q">Which number is it?</p><div class="bigw">${N[n][0]}</div>`;
    q.opts = q.opts && q.optsFor===q.i ? q.opts : options(n);
    body = `<div class="opts">${q.opts.map(o=>optBtn(o,o,n)).join("")}</div>`;
  } else if(m==="hear"){
    prompt = `<p class="q">Listen and pick the number</p><button class="play" id="play">▶ Listen</button>`;
    q.opts = q.opts && q.optsFor===q.i ? q.opts : options(n);
    body = `<div class="opts" style="margin-top:18px">${q.opts.map(o=>optBtn(o,o,n)).join("")}</div>`;
  } else {
    prompt = `<p class="q">Write it in German</p><div class="big">${n}</div>`;
    const rows = ["qwertzuiop","asdfghjkl","yxcvbnmüö"];
    const kb = rows.map((r,ri)=>`<div class="kr">${[...r].map(c=>`<button type="button" class="key" data-k="${c}">${c}</button>`).join("")}${ri===2?`<button type="button" class="key wide" data-k="back" aria-label="Delete">⌫</button>`:""}</div>`).join("");
    body = `<div class="field ${q.done?(q.ok?"ok":"no"):""}" id="ans" aria-live="polite">${q.typed?esc(q.typed):'<span class="ph">…</span>'}</div>
            ${q.done?"":`<div class="kb" id="kb">${kb}</div><button type="button" class="cta" id="check">Check</button>`}`;
  }
  q.optsFor = q.i;
  const fb = q.done ? fbHTML(q,n) : "";
  $("#view").innerHTML = `
    <div class="meta"><span>Question ${q.i+1} of ${q.qs.length}</span><span>Correct: <span id="scoreval">${q.score}</span></span></div>
    <div class="bar"><i style="width:${(q.i/q.qs.length)*100}%"></i></div>
    <div class="prompt">${prompt}</div>${body}<div id="fbslot">${fb}</div>
    <button class="cta alt" id="quit">Quit round</button>`;
  document.querySelectorAll(".opt").forEach(b=>b.onclick=()=>answer(+b.dataset.o));
  if($("#play")) $("#play").onclick=()=>say(n);
  document.querySelectorAll(".key").forEach(k=>k.onclick=()=>press(k.dataset.k));
  if($("#check")) $("#check").onclick=checkTyped;
  wireNext();
  $("#quit").onclick=()=>{ st.quiz=null; render(); };
}

function fbHTML(q,n){
  return `<div class="fb ${q.ok?"ok":"no"}"><div>${q.ok?"Correct!":"Not quite. The answer is:"}
      <small>${n} = ${N[n][0]} (${N[n][1]})</small></div>
      <button type="button" class="cta" id="next">${q.i===q.qs.length-1?"Result":"Next"}</button></div>`;
}
function wireNext(){
  const q = st.quiz, b = $("#next");
  if(!b) return;
  b.onclick=()=>{ q.i++; q.done=false; q.typed=""; q.vals=null; q.cur=0; renderQuiz(); if(q.mode==="hear"&&q.i<q.qs.length) say(q.qs[q.i]); if(isDict(q.mode)&&q.i<q.qs.length) dictPlay(); };
}
function optBtn(o,label,n){
  const q = st.quiz;
  let cls="opt", dis="";
  if(q.done){ dis="disabled"; if(o===n) cls+=" ok"; else if(o===q.picked) cls+=" no"; }
  return `<button class="${cls}" ${dis} data-o="${o}">${label}</button>`;
}

function finish(ok,n){
  const q = st.quiz;
  q.done=true; q.ok=ok; if(ok) q.score++; else q.missed.push(n);
}
function answer(o){
  const q = st.quiz; if(q.done) return;
  q.picked=o; finish(o===q.qs[q.i], q.qs[q.i]);
  renderQuiz();
}
function showTyped(){
  const q = st.quiz, el = $("#ans"); if(!el) return;
  el.innerHTML = q.typed ? esc(q.typed) : '<span class="ph">…</span>';
}
function press(k){
  const q = st.quiz; if(!q || q.mode!=="type" || q.done) return;
  q.typed = q.typed || "";
  if(k==="back") q.typed = q.typed.slice(0,-1);
  else if(q.typed.length<14) q.typed += k;
  showTyped();
}
function checkTyped(){
  const q = st.quiz; if(!q || q.done) return;
  const v = q.typed || ""; if(!v.trim()) return;
  const n = q.qs[q.i];
  finish(norm(v)===norm(N[n][0]), n);
  const ans = $("#ans"); ans.classList.add(q.ok?"ok":"no");
  const kb = $("#kb"); if(kb) kb.remove();
  const chk = $("#check"); if(chk) chk.remove();
  $("#scoreval").textContent = q.score;
  $("#fbslot").innerHTML = fbHTML(q,n);
  wireNext();
}
document.addEventListener("keydown", e=>{
  const q = st.quiz;
  if(!q || st.tab!=="practice" || e.ctrlKey || e.metaKey || e.altKey) return;
  if(q.mode==="type"){
    if(e.key==="Enter"){ e.preventDefault(); if(q.done){ const b=$("#next"); if(b) b.click(); } else checkTyped(); return; }
    if(q.done) return;
    if(e.key==="Backspace"){ e.preventDefault(); press("back"); }
    else if(/^[a-zöü]$/i.test(e.key)){ e.preventDefault(); press(e.key.toLowerCase()); }
  } else if(isDict(q.mode)){
    if(e.key==="Enter"){ e.preventDefault(); if(q.done){ const b=$("#next"); if(b) b.click(); } else dpress("go"); return; }
    if(q.done) return;
    if(e.key==="Backspace"){ e.preventDefault(); dpress("back"); }
    else if(q.mode==="dictn" && (e.key===" " || e.key==="," || e.key==="ArrowRight")){ e.preventDefault(); dpress("next"); }
    else if(/^[0-9]$/.test(e.key)){ e.preventDefault(); dpress(e.key); }
  }
});

// ---------- Dictation modes ----------
const DCFG = {
  dict9: {len:9, gap:900,  title:"Listen and type the 9-digit number"},
  dictn: {len:5, gap:1000, title:"Listen and type the 5 numbers"}
};
const SPEEDS = {
  slow:  {label:"Slow",      rate:.85, gap:1.5},
  normal:{label:"Normal",    rate:1,   gap:1},
  fast:  {label:"Fast",      rate:1.25,gap:.55},
  vfast: {label:"Very fast", rate:1.5, gap:.22},
  ufast: {label:"Ultra fast", rate:1.7, gap:.12}
};
const DEFSPEED = {dict9:"vfast", dictn:"normal"};
let spdPref = {};
try{ spdPref = JSON.parse(localStorage.getItem("zahlen-speed")||"{}"); }catch(e){}
const getSpeed = m => SPEEDS[spdPref[m]] ? spdPref[m] : DEFSPEED[m];
let dAudio = null, dTok = 0;
const wait = ms => new Promise(r=>setTimeout(r,ms));
function setDots(k){ document.querySelectorAll("#dots i").forEach((el,i)=>el.classList.toggle("on", i<k)); }
function stopDict(){ dTok++; if(dAudio){ try{ dAudio.pause(); }catch(e){} } setDots(0); }
function playClip(el,d,rate){
  return new Promise(res=>{
    let fin_=false;
    const fin=()=>{ if(!fin_){ fin_=true; el.onended=null; el.onerror=null; res(); } };
    el.onended=fin; el.onerror=fin;
    try{ el.defaultPlaybackRate=rate; el.src=AUDIO[d]; el.playbackRate=rate; const pr=el.play(); if(pr && pr.catch) pr.catch(fin); }catch(e){ fin(); }
    setTimeout(fin,3000);
  });
}
async function dictPlay(){
  const q = st.quiz; if(!q || !isDict(q.mode) || q.i>=q.qs.length) return;
  stopDict();
  const my = dTok, cfg = DCFG[q.mode], sp = SPEEDS[getSpeed(q.mode)], n = q.qs[q.i];
  const items = q.mode==="dictn" ? n : [...n].map(Number);
  if(!dAudio) dAudio = new Audio();
  const btn = $("#dplay"); if(btn) btn.textContent = "Playing…";
  await wait(250);
  for(let i=0;i<items.length;i++){
    if(my!==dTok) return;
    setDots(i+1);
    await playClip(dAudio, items[i], sp.rate);
    if(my!==dTok) return;
    await wait(Math.round(cfg.gap*sp.gap));
  }
  if(my!==dTok) return;
  setDots(0);
  const b2 = $("#dplay"); if(b2) b2.textContent = "↻ Listen again";
}
function showSlots(){
  const q = st.quiz, n = q.qs[q.i];
  const five = q.mode==="dictn";
  const t = five ? (q.vals||[]) : [...(q.typed||"")];
  document.querySelectorAll("#slots .slot").forEach((el,i)=>{
    el.textContent = t[i]||"";
    let cls = "slot";
    if(q.done){ const good = five ? (t[i]!==undefined && t[i]!=="" && Number(t[i])===n[i]) : t[i]===n[i]; cls += good ? " ok" : " no"; }
    else if(five && i===q.cur) cls += " act";
    el.className = cls;
  });
}
function dpress(k){
  const q = st.quiz; if(!q || !isDict(q.mode) || q.done) return;
  if(k==="go"){ dcheck(); return; }
  if(q.mode==="dictn"){
    const v = q.vals; let c = q.cur;
    const adv = () => { if(c<4) q.cur = c+1; };
    if(k==="back"){
      if(v[c]) v[c] = v[c].slice(0,-1);
      else if(c>0){ q.cur = c-1; v[c-1] = v[c-1].slice(0,-1); }
    } else if(k==="next"){
      if(v[c]) adv();
    } else {
      let cur = v[c];
      if(cur==="2" && k!=="0"){ if(c<4){ c = q.cur = c+1; cur = v[c]; } else return; }
      if(cur==="1"){ v[c] = "1"+k; adv(); }
      else if(cur==="2"){ v[c] = "20"; adv(); }
      else { v[c] = k; if(k==="0" || +k>=3) adv(); }
    }
    showSlots(); return;
  }
  q.typed = q.typed||"";
  const len = DCFG[q.mode].len;
  if(k==="back") q.typed = q.typed.slice(0,-1);
  else if(q.typed.length<len) q.typed += k;
  showSlots();
}
function dcheck(){
  const q = st.quiz; if(!q || q.done) return;
  const n = q.qs[q.i], five = q.mode==="dictn";
  let ok, shown;
  if(five){
    if(!q.vals.every(x=>x!=="")) return;
    ok = q.vals.every((x,i)=>Number(x)===n[i]);
    shown = n.map(x=>x+" "+N[x][0]).join(" · ");
  } else {
    if((q.typed||"").length<DCFG[q.mode].len) return;
    ok = q.typed===n;
    shown = n+" = "+[...n].map(d=>N[+d][0]).join(" · ");
  }
  finish(ok, n);
  stopDict();
  const pad = $("#pad"); if(pad) pad.remove();
  showSlots();
  $("#scoreval").textContent = q.score;
  $("#fbslot").innerHTML = `<div class="fb ${q.ok?"ok":"no"}"><div>${q.ok?"Correct!":"Not quite. It was:"}
      <small>${shown}</small></div>
      <button type="button" class="cta" id="next">${q.i===q.qs.length-1?"Result":"Next"}</button></div>`;
  wireNext();
}
function renderDict(){
  const q = st.quiz, cfg = DCFG[q.mode], five = q.mode==="dictn";
  if(five && !q.vals){ q.vals = ["","","","",""]; q.cur = 0; }
  const keys = five ? ["1","2","3","back","4","5","6","next","7","8","9","0","go"]
                    : ["1","2","3","4","5","6","7","8","9","back","0","go"];
  const pad = q.done ? "" : `<div class="pad ${five?"n":""}" id="pad">${keys.map(k=>
      k==="back" ? `<button type="button" class="key" data-d="back" aria-label="Delete">⌫</button>`
    : k==="next" ? `<button type="button" class="key" data-d="next" aria-label="Next box">›</button>`
    : k==="go" ? `<button type="button" class="key go" data-d="go">Check</button>`
    : `<button type="button" class="key" data-d="${k}">${k}</button>`).join("")}</div>`;
  const slotCls = five ? "slots five" : cfg.len>6 ? "slots nine" : "slots";
  $("#view").innerHTML = `
    <div class="meta"><span>${five?"Dictation":"Number"} ${q.i+1} of ${q.qs.length}</span><span>Correct: <span id="scoreval">${q.score}</span></span></div>
    <div class="bar"><i style="width:${(q.i/q.qs.length)*100}%"></i></div>
    <div class="prompt" style="margin:10px 0 6px">
      <p class="q">${cfg.title}</p>
      <div class="prow"><button type="button" class="play" id="dplay">▶ Listen</button>
        <label class="spd">Speed <select id="spd" aria-label="Dictation speed">${Object.entries(SPEEDS).map(([k,v])=>`<option value="${k}" ${k===getSpeed(q.mode)?"selected":""}>${v.label}</option>`).join("")}</select></label></div>
      <div class="dots" id="dots" aria-hidden="true">${"<i></i>".repeat(cfg.len)}</div>
    </div>
    <div class="${slotCls}" id="slots">${"<span class=\"slot\"></span>".repeat(cfg.len)}</div>
    ${five?'<p class="hint" style="text-align:center;margin:0 0 4px;font-size:13px">Boxes move on by themselves. After a 1 or 2, tap › to move on.</p>':""}
    ${pad}<div id="fbslot"></div>
    <button class="cta alt" id="quit">Quit round</button>`;
  document.querySelectorAll("#pad .key").forEach(k=>k.onclick=()=>dpress(k.dataset.d));
  if(five) document.querySelectorAll("#slots .slot").forEach((el,i)=>el.onclick=()=>{ if(!q.done){ q.cur=i; showSlots(); } });
  $("#dplay").onclick = dictPlay;
  $("#spd").onchange = e => {
    spdPref[q.mode] = e.target.value;
    try{ localStorage.setItem("zahlen-speed", JSON.stringify(spdPref)); }catch(err){}
    e.target.blur();
    dictPlay();
  };
  $("#quit").onclick = ()=>{ st.quiz=null; render(); };
  showSlots();
}

function renderResult(){
  const q = st.quiz;
  stopDict();
  const key = q.mode+st.scope;
  if(st.best[key]==null || q.score>st.best[key]){
    st.best[key]=q.score;
    try{ localStorage.setItem("zahlen-best",JSON.stringify(st.best)); }catch(e){}
  }
  const r = q.score/q.qs.length;
  const msg = r===1?"Perfect!":r>=.7?"Very good!":r>=.4?"You are on the right track.":"Review and try again.";
  const missed = [...new Set(q.missed)].sort((a,b)=>a-b);
  $("#view").innerHTML = `<div class="result">
    <div class="big">${q.score}/${q.qs.length}</div><p>${msg}</p>
    ${missed.length?`<p>To review:</p><div class="miss">${missed.map(n=>`<span>${isDict(q.mode)?(Array.isArray(n)?n.join(" · "):n):n+" = "+N[n][0]}</span>`).join("")}</div>`:""}
    </div>
    <button class="cta" id="again">Another round</button>
    <button class="cta alt" id="menu">Change mode</button>
    <button class="cta alt" id="review">Review cards</button>`;
  $("#again").onclick=()=>startQuiz(q.mode);
  $("#menu").onclick=()=>{st.quiz=null;render();};
  $("#review").onclick=()=>{st.quiz=null;setTab("learn");};
}

function setTab(t){ st.tab=t; if(t==="learn") st.quiz=null; render(); window.scrollTo(0,0); }
function render(){
  if(!(st.quiz && isDict(st.quiz.mode) && st.tab==="practice")) stopDict();
  document.body.classList.toggle("quiz", st.tab==="practice" && !!st.quiz);
  $("#tab-learn").setAttribute("aria-selected", st.tab==="learn");
  $("#tab-practice").setAttribute("aria-selected", st.tab==="practice");
  renderScope();
  if(st.tab==="learn") renderLearn();
  else if(st.quiz) renderQuiz();
  else renderMenu();
}
$("#tab-learn").onclick=()=>setTab("learn");
$("#tab-practice").onclick=()=>setTab("practice");
render();
</script>
</body>
</html>

````

## 7. Script de audio: `build_audio.py`

````python
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

````
