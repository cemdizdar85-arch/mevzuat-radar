# ============================================================================
#  COMMIT MESAJI KAPISI — Claude Code PreToolUse hook
#
#  NEDEN VAR (30.08.2026): PowerShell'de çok satırlı commit mesajı `-m` ile
#  verilince git mesajın bir kısmını PATHSPEC sanıyor ve commit'i SESSİZCE
#  atlıyor. Ekranda şu görünüyor:
#      error: pathspec 'son satır...' did not match any file(s) known to git
#  ama arkasından çalışan push "PUSH OK" diyor — çünkü itilecek yeni commit
#  yok, dal zaten güncel. Yani "iş bitti" sanılıyor, ortada commit YOK.
#
#  Bu 30.08'de DÖRT KEZ yaşandı. Kural repo CLAUDE.md'ye yazıldı ama yazılı
#  kural yetmedi; refleks `-m` olmaya devam etti. Bu yüzden kapı kondu:
#  artık yazılı kural değil, çalışan bir engel.
#
#  NE YAPAR: `git commit` çağrısında çok satırlı `-m` görürse tool çağrısını
#  ENGELLER (çıkış 2) ve doğrusunu söyler:
#      mesajı bir dosyaya yaz  ->  git commit -F <dosya>
#
#  NE YAPMAZ: tek satırlık `-m "..."` serbesttir — robotların ve küçük
#  commit'lerin yolunu kesmez. `-F` zaten serbesttir.
#
#  Hook protokolü: stdin'den JSON alır; çıkış 0 = devam, çıkış 2 = engelle
#  (stderr metni Claude'a geri gider).
# ============================================================================
$ErrorActionPreference = 'Stop'

try {
  $ham = [Console]::In.ReadToEnd()
  if(-not $ham){ exit 0 }
  $veri = $ham | ConvertFrom-Json
} catch { exit 0 }   # okunamadıysa yolu kapatma - kapı iş durdurmaz

$komut = ''
try { $komut = "$($veri.tool_input.command)" } catch { }
if(-not $komut){ exit 0 }

# git commit çağrısı değilse ilgilenmez
if($komut -notmatch 'git\s+(-C\s+\S+\s+)?commit'){ exit 0 }
# -F / --file kullanılıyorsa zaten doğrusu
if($komut -match '\s-F\s|\s--file[=\s]'){ exit 0 }
# -m yoksa (editör açılır ya da --amend --no-edit) ilgilenmez
if($komut -notmatch '\s-m\b|\s--message[=\s]'){ exit 0 }

# --- TEHLİKELİ KALIP: -m sonrası here-string ya da çok satırlı metin -------
$hereString = ($komut -match "-m\s+@['`"]")
# -m'den sonra gelen kısımda satır sonu var mı?
$cokSatir = $false
$mIdx = $komut.IndexOf(' -m ')
if($mIdx -lt 0){ $mIdx = $komut.IndexOf(' --message') }
if($mIdx -ge 0){
  $sonrasi = $komut.Substring($mIdx)
  if($sonrasi -match "`n"){ $cokSatir = $true }
}

if($hereString -or $cokSatir){
  $mesaj = @"
COMMIT MESAJI KAPISI — bu cagri ENGELLENDI.

Cok satirli commit mesaji "-m" ile veriliyor. PowerShell'de bu, mesajin bir
kismini git'e PATHSPEC olarak gecirir; git commit'i SESSIZCE atlar:
    error: pathspec '...' did not match any file(s) known to git
ve arkadan gelen push "PUSH OK" der (itilecek yeni commit olmadigi icin).
Sonuc: is bitti sanilir, ortada COMMIT YOKTUR. 30.08'de dort kez yasandi.

DOGRUSU - mesaji dosyaya yaz, -F ile ver:
    (Write tool ile) <scratchpad>/commit-mesaj.txt
    git -C <depo> add <dosyalar>
    git -C <depo> commit -q -F <scratchpad>/commit-mesaj.txt

Tek satirlik mesaj serbesttir:
    git commit -q -m "kisa ozet"
"@
  [Console]::Error.WriteLine($mesaj)
  exit 2
}

exit 0
