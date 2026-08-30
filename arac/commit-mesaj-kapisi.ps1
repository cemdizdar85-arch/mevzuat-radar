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
#  ÖZ-SINAV: powershell -NoProfile -File arac/commit-mesaj-kapisi.ps1 -Sinav
#  (93 kapı kuralı: karar veren betik kendini sınar. Hook yolunda koşmaz,
#   her çağrıyı yavaşlatmasın diye ayrı bayrakla çağrılır.)
param([switch]$Sinav)

$ErrorActionPreference = 'Stop'

if($Sinav){
  $vakalar = @(
    @{ ad='tek satir -m';                             k='git -C /x commit -q -m "kisa ozet"';                b=$false },
    # 30.08: ILK SURUM TAM BURADA YANLIS POZITIF VERDI ve kendi yazarini durdurdu.
    @{ ad='tek satir -m + sonrasinda baska komutlar'; k="git add a`ngit commit -q -m `"kisa`"`ngit push";    b=$false },
    @{ ad='-F ile';                                   k='git -C /x commit -q -F /tmp/m.txt';                 b=$false },
    @{ ad='git commit degil';                         k='git add . ; git push origin HEAD:main';             b=$false },
    @{ ad='here-string -m';                           k="git commit -q -m @'`nsatir1`nsatir2`n'@";           b=$true  },
    @{ ad='cok satirli -m (cift tirnak)';             k="git commit -m `"basli`nikinci satir`"";             b=$true  },
    @{ ad='cok satirli -m (tek tirnak) + sonrasi';    k="git commit -m 'basli`nikinci'`ngit push";           b=$true  }
  )
  $kotu = 0
  foreach($v in $vakalar){
    $komut = $v.k
    $engel = $false
    if($komut -match 'git\s+(-C\s+\S+\s+)?commit' -and $komut -notmatch '\s-F\s|\s--file[=\s]' -and ($komut -match '\s-m\b|\s--message[=\s]')){
      if($komut -match "-m\s+@['`"]"){ $engel = $true }
      else {
        foreach($d in @('(?s)-m\s+"([^"]*)"', "(?s)-m\s+'([^']*)'", '(?s)--message[= ]\s*"([^"]*)"', "(?s)--message[= ]\s*'([^']*)'")){
          $mm = [regex]::Match($komut, $d)
          if($mm.Success -and $mm.Groups[1].Value -match "`n"){ $engel = $true; break }
        }
      }
    }
    $ok = ($engel -eq $v.b); if(-not $ok){ $kotu++ }
    Write-Host ("  {0,-44} engel={1,-5} beklenen={2,-5} {3}" -f $v.ad, $engel, $v.b, $(if($ok){'OK'}else{'HATA'}))
  }
  Write-Host ""
  if($kotu){ Write-Host ("  $kotu vaka DUSTU - kapi bozuk") -ForegroundColor Red; exit 2 }
  Write-Host ("  {0}/{0} GECTI" -f $vakalar.Count) -ForegroundColor Green
  exit 0
}

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

# --- TEHLİKELİ KALIP: -m sonrası here-string ya da çok satırlı MESAJ -------
# 30.08 İLK SÜRÜM FAZLA GENİŞTİ ve kendi yazarını yanlış yere durdurdu:
# "-m'den sonra satır sonu var mı" diye bakıyordu, oysa çağrının DEVAMINDA
# başka komutlar olması normaldir (git add ; git commit -m "kısa" ; git push).
# Ölçülmesi gereken şey MESAJIN KENDİSİ - yani tırnakla sınırlanmış metin.
$hereString = ($komut -match "-m\s+@['`"]")

$cokSatir = $false
if(-not $hereString){
  # -m / --message sonrası TIRNAKLA SINIRLI mesajı çıkar, içinde satır sonu ara.
  # Tek ve çift tırnak ayrı ayrı denenir; kaçışlı tırnak bu bağlamda olmuyor.
  foreach($desen in @('(?s)-m\s+"([^"]*)"', "(?s)-m\s+'([^']*)'",
                      '(?s)--message[= ]\s*"([^"]*)"', "(?s)--message[= ]\s*'([^']*)'")){
    $m = [regex]::Match($komut, $desen)
    if($m.Success -and $m.Groups[1].Value -match "`n"){ $cokSatir = $true; break }
  }
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
