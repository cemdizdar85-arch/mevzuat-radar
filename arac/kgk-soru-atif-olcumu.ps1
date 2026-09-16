# ============================================================================
#  KGK ÇIKMIŞ SORU — METİNDEKİ AÇIK KAYNAK ATIFI ÖLÇÜMÜ   16.09.2026
#  Cem "1.2.3 üçünüde yap" (3): basım Excel'inde 1.426 soru "ders varsayılanı" ile bağlıydı (en zayıf bağ).
#
#  NEDEN: veri/kgk-analiz.json yalnız KONU ETİKETİ tutuyor, soru metnini değil; etikette kanun/standart adı yoksa
#  bağ dersin ana kanununa düşüyordu. Oysa sorunun KENDİ METNİ çoğu zaman kaynağı açıkça söylüyor
#  ("TMS 16'ya göre…", "5411 sayılı Kanun uyarınca…", "BDS 530 kapsamında…").
#
#  NE YAPAR: ambardaki KGK çıkmış soru kitapçıklarını (tur='cikmis-soru', 108 belge) okur, "SORU N:" ile böler,
#  her sorunun metninde AÇIK atıf arar (standart numarası, kanun numarası, tebliğ kodu) ve sayar.
#  Etikete DEĞİL, sorunun kendi metnine bakar → bağımsız ikinci ölçüdür.
#
#  Yazma yok (ambar/depo), model yok, bedel 0. Çıktı: veri/kgk-soru-atif.json
#  Kullanım: powershell -NoProfile -File arac/kgk-soru-atif-olcumu.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$H = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }

# kitapçık adındaki dosya kodundan YIL (kgk-analiz'deki kitapcik alanıyla eşleşir)
$arsiv = Get-Content (Join-Path $depoKok 'veri\kgk-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kodYil = @{}
foreach($d in $arsiv.donemler){
  $yil = [int]([regex]::Match("$($d.donem)",'(\d{4})').Groups[1].Value)
  foreach($kt in ("$($d.kitapcik)" -split '\|')){
    $kod = [regex]::Match($kt.Trim(),'^(\d{4,5})').Groups[1].Value
    if($kod){ $kodYil[$kod] = $yil }
  }
}

# --- açık atıf desenleri: sorunun metninde kaynağı ADIYLA söyleyen ifadeler
$desenler = @(
  @{ ad='standart'; desen='\b(TMS|TFRS|BDS|GDS|TSRS|SBDS|İHS|IHS|KYS|BOBİ FRS|KÜMİ FRS)\s*(\d{1,4})?' }
  @{ ad='kanun';    desen='\b(\d{4})\s*say[ıi]l[ıi]' }
  @{ ad='teblig';   desen='\(?\b(I{1,3}V?|VI{1,3}|V)\s*-\s*(\d{1,3}(?:\.\d+)?(?:/[A-Z]\.?\d*)?)\b' }
)
function AtifCikar([string]$metin){
  $bulunan = New-Object System.Collections.Generic.HashSet[string]
  foreach($m in [regex]::Matches($metin,'\b(TMS|TFRS|BDS|GDS|TSRS|SBDS|KYS)\s*(\d{1,4})')){ [void]$bulunan.Add(($m.Groups[1].Value + ' ' + $m.Groups[2].Value)) }
  foreach($m in [regex]::Matches($metin,'\b([İI]HS)\s*(\d{3,4})')){ [void]$bulunan.Add('İHS ' + $m.Groups[2].Value) }
  foreach($m in [regex]::Matches($metin,'\b(BOB[İI] FRS|K[ÜU]M[İI] FRS)')){ [void]$bulunan.Add(($m.Groups[1].Value -replace 'I','İ' -replace 'U','Ü')) }
  foreach($m in [regex]::Matches($metin,'\b(\d{4})\s*say[ıi]l[ıi]')){ [void]$bulunan.Add($m.Groups[1].Value + ' s.K.') }
  foreach($m in [regex]::Matches($metin,'\(((?:I{1,3}V?|VI{1,3}|V))-(\d{1,3}(?:\.\d+)?(?:/[A-Z]\.?\d*)?)\)')){ [void]$bulunan.Add($m.Groups[1].Value + '-' + $m.Groups[2].Value) }
  foreach($m in [regex]::Matches($metin,'Kavramsal\s+[ÇC]er[çc]eve')){ [void]$bulunan.Add('Kavramsal Çerçeve') }
  return $bulunan
}

# --- kitapçıkları çek
$belgeler = New-Object System.Collections.Generic.List[object]
$adres = "$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&kaynak_ad=like." + [uri]::EscapeDataString('%KGK%') + "&limit=200"
foreach($x in (Invoke-RestMethod -Uri $adres -Headers $H -TimeoutSec 300)){ $belgeler.Add($x) }
Write-Host "kitapçık: $($belgeler.Count)"

$soruSayisi = 0; $atifliSoru = 0; $yilsiz = 0
$sayim = @{}       # kaynak -> @{ toplam; s2022 }
$kitapcikOzet = New-Object System.Collections.Generic.List[object]
foreach($b in $belgeler){
  $ad = "$($b.kaynak_ad)"; $metin = "$($b.metin)"
  $kod = [regex]::Match($ad,'\((\d{4,5})').Groups[1].Value
  $yil = if($kod -and $kodYil.ContainsKey($kod)){ $kodYil[$kod] } else { 0 }
  if(-not $yil){ $yilsiz++ }
  # "SORU 12:" / "SORU 12 -" ile böl
  $parcalar = [regex]::Split($metin,'(?=\bSORU\s+\d{1,3}\s*[:.\-–])')
  $kAtif = 0; $kSoru = 0
  foreach($p in $parcalar){
    if($p -notmatch '\bSORU\s+\d{1,3}'){ continue }
    $kSoru++; $soruSayisi++
    $atif = AtifCikar $p
    if($atif.Count){ $atifliSoru++; $kAtif++ }
    foreach($a in $atif){
      if(-not $sayim.ContainsKey($a)){ $sayim[$a] = [ordered]@{ kaynak=$a; toplam=0; s2022=0 } }
      $sayim[$a].toplam++
      if($yil -ge 2022){ $sayim[$a].s2022++ }
    }
  }
  $kitapcikOzet.Add([pscustomobject]@{ kitapcik=$ad; yil=$yil; soru=$kSoru; atifli=$kAtif })
}
$sirali = @($sayim.Values | Sort-Object { -$_.toplam })
$sonuc = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'Sorunun KENDİ METNİNDE geçen açık atıf sayılır (TMS/TFRS/BDS/GDS/TSRS/İHS/KYS numarası, "NNNN sayılı" kanun, (II-17.1) tebliğ kodu, Kavramsal Çerçeve). Etikete bakılmaz. Bir soruda birden çok atıf varsa her biri sayılır.'
  kitapcik = $belgeler.Count
  soru = $soruSayisi
  atifli_soru = $atifliSoru
  atifli_oran = $(if($soruSayisi){ [math]::Round(100.0*$atifliSoru/$soruSayisi,1) } else { 0 })
  yili_bilinmeyen_kitapcik = $yilsiz
  kaynaklar = @($sirali | ForEach-Object { [ordered]@{ kaynak=$_.kaynak; toplam=$_.toplam; s2022=$_.s2022 } })
  kitapciklar = $kitapcikOzet.ToArray()
}
[void](RaporYaz -Hedef (Join-Path $depoKok 'veri\kgk-soru-atif.json') -Nesne $sonuc -Sessiz)
"soru {0} · açık atıflı {1} (%{2}) · tekil kaynak {3}" -f $soruSayisi,$atifliSoru,$sonuc.atifli_oran,$sirali.Count
foreach($k in ($sirali | Select-Object -First 25)){ "  {0,-18} toplam {1,4} · 2022+ {2,3}" -f $k.kaynak,$k.toplam,$k.s2022 }
