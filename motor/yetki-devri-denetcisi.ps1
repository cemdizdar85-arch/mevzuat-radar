# ============================================================================
#  YETKI DEVRI DENETCISI (13.08.2026) — 0 USD, API YOK
#
#  CEM: "sitede boyle hatalar varsa ben nasil kontrol edeyim, sen kontrol kur."
#
#  YAKALADIGI HATA SINIFI: sayfadaki rakam KANUN metniyle uyumlu, ama kanun o
#  rakami belirleme yetkisini CB/Bakanlik/teblige DEVRETMIS ve ikincil duzenleme
#  rakami degistirmis. Iki yasanmis vaka: 5746 esigi (kanun 50 -> 2016/9093 ile 15),
#  SGK tavani (kanun 7,5 kat -> 7566 ile 9 kat). Kanun-uyumu kapilari bunu GOREMEZ;
#  cunku kanun metni de "50" der. Tek care: yetki-devri kaliplarini tarayip
#  o maddeye dayanan her sayisal iddiayi RISKLI saymak.
#
#  IKI TARAMA:
#   A) AMBAR: veri/mevzuat/*.json maddelerinde yetki-devri kalibi ara
#      -> "riskli madde" envanteri (kanun + madde + kalip kesiti)
#   B) SITE: kok dizindeki *.html'lerde sayisal iddia (%X, N yil/kat/kisi/TL,
#      "en az N") + ayni cumlede/yakininda madde atifi -> iddia envanteri
#   KESISIM: iddianin atif ettigi madde riskli listede ise -> KIRMIZI ADAY.
#   Atifsiz sayisal iddialar ayrica "dayanaksiz rakam" listesine duser.
#
#  KARAR INSANIN: bu betik aday uretir, hukum vermez (uretim-hatti dersi:
#  "kapilar bicimi denetler" — buradaki kapi RISKI isaretler, dogrulugu degil).
#  CIKTI: veri/yetki-devri-riskleri.json + ozet ekrana.
#  Parametre: -SayfaDetay (aday satirlarini tam yazdirir)
# ============================================================================
param([switch]$SayfaDetay)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/yetki-devri-riskleri.json'

# --- yetki-devri kaliplari (iki vakadan + m.4/6 tipi maddelerden turetildi) ---
$reYetki = [regex]'(?i)(Cumhurba[şs]kan[ıi]|Bakanlar Kurulu)[^.]{0,160}?(yetkili|belirle|art[ıi]rmaya|indirmeye)|tebli[ğg]\s*ile\s*belirlen|y[öo]netmelik(le| ile)\s*belirlen|yeniden de[ğg]erleme oran[ıi]nda\s*art[ıi]r|her (takvim )?y[ıi]l[^.]{0,60}g[üu]ncellen|kat[ıi]na kadar art[ıi]rmaya|yar[ıi]s[ıi]na kadar indirmeye|s[ıi]f[ıi]ra kadar indirmeye'

# --- A) ambar taramasi ---
$riskliMaddeler = New-Object System.Collections.Generic.List[object]
$ambarDir = Join-Path $kok 'veri/mevzuat'
$dosyaSay = 0
foreach($f in Get-ChildItem $ambarDir -Filter '*.json' | Where-Object { $_.Name -notmatch '^_' }){
  $dosyaSay++
  try { $d = (Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { continue }
  $belgeler = if($d.belgeler){ $d.belgeler } else { continue }
  foreach($b in $belgeler){
    if(-not $b.metin){ continue }
    $m = $reYetki.Match($b.metin)
    if($m.Success){
      $kes = $b.metin.Substring([Math]::Max(0,$m.Index-40), [Math]::Min(200, $b.metin.Length-[Math]::Max(0,$m.Index-40))) -replace '\s+',' '
      $riskliMaddeler.Add([pscustomobject]@{ dosya=$f.BaseName; kaynak_ad="$($b.kaynak_ad)"; kesit="...$kes..." })
    }
  }
}

# --- B) site taramasi ---
# sayisal iddia: %X | N yil/ay/gun/kat/puan/kisi/kat[ıi] | "en az N" | N TL (binlik ayracli)
$reIddia = [regex]'(?i)%\s?\d+[\d,\.]*|en az\s+\d+|\b\d+\s*(y[ıi]l|ay\b|g[üu]n|kat[ıi]?\b|puan|ki[şs]i|saat|dekar|oda|adet)|\b[\d\.]{4,}\s*TL'
$reAtif  = [regex]'(?i)m\.\s?\d+|madde\s+\d+|ge[çc]\.?\s*m\.|say[ıi]l[ıi]\s+(Kanun|Karar|CB|BKK)|\b\d{4}\/\d+\b|\b(5746|4691|5510|4447|9903|5973|5986|6102|213|193|5520|3065|6769|6183|4857)\b'
$iddialar = New-Object System.Collections.Generic.List[object]
$dayanaksiz = New-Object System.Collections.Generic.List[object]
$sayfaSay = 0
foreach($f in Get-ChildItem $kok -Filter '*.html' | Where-Object { $_.Name -notmatch '^(arsiv|_)' }){
  $sayfaSay++
  $satirlar = Get-Content $f.FullName -Encoding UTF8
  for($i=0; $i -lt $satirlar.Count; $i++){
    $s = $satirlar[$i]
    if($s -match '<script|<style|href=|src=|var\s|const\s|function|data-vs'){ continue }  # kod/veri-baglantili satirlar disari
    $mI = $reIddia.Match($s)
    if(-not $mI.Success){ continue }
    # yakin baglam: ayni satir +-2 satirda atif var mi
    $bas=[Math]::Max(0,$i-2); $son=[Math]::Min($satirlar.Count-1,$i+2)
    $baglam = ($satirlar[$bas..$son] -join ' ')
    $temiz = ($s -replace '<[^>]+>',' ' -replace '\s+',' ').Trim()
    if($temiz.Length -lt 15){ continue }
    $kayit = [pscustomobject]@{ sayfa=$f.Name; satir=$i+1; iddia=$mI.Value; metin=$temiz.Substring(0,[Math]::Min(180,$temiz.Length)) }
    if($reAtif.IsMatch($baglam)){ $iddialar.Add($kayit) } else { $dayanaksiz.Add($kayit) }
  }
}

# --- kesisim: iddia baglaminda gecen kanun numarasi, riskli-madde dosyalariyla esles ---
# kaba anahtar: dosya adindaki rakamlar (arge5746 -> 5746) iddia metninde geciyor mu
$dosyaKanun = @{}
foreach($r in $riskliMaddeler){ if($r.dosya -match '(\d{3,5})'){ $dosyaKanun[$Matches[1]] = $true } }
$kirmizi = New-Object System.Collections.Generic.List[object]
foreach($x in $iddialar){
  foreach($no in $dosyaKanun.Keys){
    if($x.metin -match "\b$no\b"){ $kirmizi.Add([pscustomobject]@{ sayfa=$x.sayfa; satir=$x.satir; iddia=$x.iddia; kanun=$no; metin=$x.metin }); break }
  }
}

# --- okundu listesi: elle okunup karara baglanmis adaylar tekrar KIRMIZI cikmaz ---
# anahtar: sayfa|kanun|iddia (satir numarasi OYNAR, anahtara girmez)
$okunduYol = Join-Path $kok 'veri/yetki-devri-okundu.json'
$okundu = @{}
if(Test-Path $okunduYol){ try { foreach($o in (Get-Content $okunduYol -Raw -Encoding UTF8 | ConvertFrom-Json)){ $okundu["$($o.anahtar)"]=$true } } catch {} }
$yeni = New-Object System.Collections.Generic.List[object]
foreach($k in $kirmizi){ $a="$($k.sayfa)|$($k.kanun)|$($k.iddia)"; if(-not $okundu.ContainsKey($a)){ $yeni.Add($k) } }

$rapor = [ordered]@{
  tarih = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama = 'Yetki-devri denetimi: KIRMIZI = sayisal iddia, yetki-devri kalibi tasiyan bir kanuna atifla ayni baglamda. Her aday ELLE okunur - kapi karar vermez. Iki yasanmis vaka bu siniftandi: 5746 esik 50->15 (2016/9093), 5510 tavan 7,5->9 kat (7566).'
  ambar_dosya = $dosyaSay; riskli_madde = $riskliMaddeler.Count
  sayfa = $sayfaSay; atifli_iddia = $iddialar.Count; dayanaksiz_iddia = $dayanaksiz.Count
  kirmizi_aday = $kirmizi.Count
  yeni_aday = $yeni.Count
  yeni = $yeni.ToArray()
  kirmizi = $kirmizi.ToArray()
  dayanaksiz = $dayanaksiz.ToArray()
  riskli_maddeler = $riskliMaddeler.ToArray()
}
$json = ConvertTo-Json $rapor -Depth 6
[IO.File]::WriteAllText($ciktiYol, $json, (New-Object Text.UTF8Encoding($false)))

Write-Host "=== YETKI DEVRI DENETCISI ==="
Write-Host ("ambar: {0} dosya tarandi -> {1} maddede yetki-devri kalibi" -f $dosyaSay, $riskliMaddeler.Count)
Write-Host ("site : {0} sayfa -> {1} atifli sayisal iddia + {2} dayanaksiz rakam" -f $sayfaSay, $iddialar.Count, $dayanaksiz.Count)
Write-Host ("KIRMIZI ADAY: {0} (okunmus: {1}, YENI: {2})  -> {3}" -f $kirmizi.Count, ($kirmizi.Count-$yeni.Count), $yeni.Count, $ciktiYol)
if($SayfaDetay){ foreach($k in $kirmizi){ Write-Host ("  [{0}:{1}] ({2}) {3} | {4}" -f $k.sayfa,$k.satir,$k.kanun,$k.iddia,$k.metin) } }
foreach($k in $yeni){ Write-Host ("  YENI: [{0}:{1}] ({2}) {3}" -f $k.sayfa,$k.satir,$k.kanun,$k.iddia) }
# CI kapisi: YENI aday varsa kirmizi cik — okunup karara baglanmadan yesile donmez
if($yeni.Count -gt 0){ exit 1 }
