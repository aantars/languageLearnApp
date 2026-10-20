# Generates audio/ (numbers, letters, words) from the N, L and WORDS data in index.html,
# using Piper with the German Thorsten voice, then ffmpeg to trim silence and encode MP3.
param(
  [string]$Piper  = "C:\personal\tools\piper\piper.exe",
  [string]$Voice  = "C:\personal\tools\piper\voices\de_DE-thorsten-high.onnx",
  [string]$Ffmpeg = "C:\personal\tools\ffmpeg\bin\ffmpeg.exe",
  [double]$LengthScale = 1.1,        # a little slower than natural, clearer for learners
  [double]$LetterLengthScale = 1.6,  # letter names come out clipped at the normal pace
  [double]$NoiseW = 0.3              # lower = steadier durations from run to run (Piper default 0.8)
)
$ErrorActionPreference = "Stop"
$utf8 = New-Object Text.UTF8Encoding $false
$html = [IO.File]::ReadAllText("$PSScriptRoot\index.html", $utf8)

function Grab($name){
  $m = [regex]::Match($html, "const $name = (\[[\s\S]*?\n\]);")
  if(!$m.Success){ throw "const $name not found in index.html" }
  $m.Groups[1].Value | ConvertFrom-Json
}
# Same as slug() in index.html. Umlauts as char codes so this file stays ASCII.
function Slug([string]$s){
  $s.ToLowerInvariant().Replace([string][char]0xE4,"ae").Replace([string][char]0xF6,"oe").Replace([string][char]0xFC,"ue").Replace([string][char]0xDF,"ss")
}
# Words whose spelling Piper misreads: German word -> text to synthesize.
$SAY = @{ "Blume" = "Bluhme" }

$jobs = @()
# Kept as strings: "$x" formats with a dot whatever the system culture, as Piper expects.
$ls = "$LengthScale"; $lls = "$LetterLengthScale"
$i = 0; foreach($n in (Grab "N")){ $jobs += @{text=$n[0]; out="numbers\$i.mp3"; ls=$ls}; $i++ }
foreach($l in (Grab "L")){ $jobs += @{text=$l[4]; out="letters\$(Slug $l[0]).mp3"; ls=$lls} }
foreach($w in (Grab "WORDS")){ $t = if($SAY.ContainsKey($w[0])){ $SAY[$w[0]] } else { $w[0] }; $jobs += @{text=$t; out="words\$(Slug $w[0]).mp3"; ls=$ls} }
$dupes = $jobs | Group-Object { $_.out } | Where-Object Count -gt 1
if($dupes){ throw "Duplicate clip names: $($dupes.Name -join ', ')" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("llapp-audio-" + [guid]::NewGuid())
New-Item -ItemType Directory $tmp | Out-Null
try{
  # One Piper run per length scale. The input goes through a BOM-less file because
  # piping a string from PowerShell 5.1 prepends a BOM that Piper would read as text.
  $k = 0
  foreach($g in ($jobs | Group-Object { $_.ls })){
    $lines = $g.Group | ForEach-Object { $_.wav = Join-Path $tmp "$k.wav"; $k++; @{text=$_.text; output_file=$_.wav} | ConvertTo-Json -Compress }
    [IO.File]::WriteAllLines("$tmp\in.jsonl", $lines, $utf8)
    cmd /c "`"$Piper`" -m `"$Voice`" --json-input --length_scale $($g.Name) --noise_w $NoiseW --sentence_silence 0 -q < `"$tmp\in.jsonl`" > nul"
    if($LASTEXITCODE){ throw "piper failed" }
  }

  $audio = Join-Path $PSScriptRoot "audio"
  # Delete old clips but keep the folders, which Explorer or a player may hold open.
  if(Test-Path $audio){ Get-ChildItem -Recurse -File $audio -Filter *.mp3 | Remove-Item -Force }
  "numbers","letters","words" | ForEach-Object { New-Item -ItemType Directory -Force (Join-Path $audio $_) | Out-Null }
  $trim = "silenceremove=start_periods=1:start_threshold=-50dB"
  foreach($j in $jobs){
    & $Ffmpeg -y -loglevel error -i $j.wav -af "$trim,areverse,$trim,areverse" -ac 1 -b:a 48k (Join-Path $audio $j.out)
    if($LASTEXITCODE){ throw "ffmpeg failed on $($j.out)" }
  }
  $kb = [math]::Round(((Get-ChildItem -Recurse $audio -File | Measure-Object Length -Sum).Sum) / 1KB)
  "audio/ written: $($jobs.Count) clips, $kb KB"
} finally { Remove-Item -Recurse -Force $tmp }
