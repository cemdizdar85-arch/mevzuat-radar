# ============================================================================
#  SGS CEVAP ANAHTARI ÇIKARIMI (04.09.2026, Cem "2 yap" = cevap anahtarlarını yut)
#
#  ÖLÇÜLDÜ: 65 SGS kitapçığının 14'ünde cevap anahtarı kitapçığın SON SAYFASINDA basılı ("81 E A 82 B C …":
#  soru no, A kitapçığı cevabı, B kitapçığı cevabı). 51'inde yok; TESMER ayrı anahtar dosyası da yayımlamıyor
#  (04.09 sondaj: aday adların hepsi HTML döndü). Bu betik eldeki 14'ü ayıklar, KALANI "yok" diye işaretler.
#  ÇIKTI: veri/sgs-cevap-anahtari.json  {donemler:{ "2010/1": { kitapcik, a:{ "1":"E", … }, b:{…}, adet } }, yok:[…]}
#  SINIR (04.09 ölçüldü, 2010/1): anahtar sayfasında 1-60 (genel kültür/yetenek) blokta harfler TEK TEK satırda
#  ("A Grubu B Grubu" başlığı altında 120 harf) — A/B sırası PDF'ten belirsiz, ALINMAZ (ölçülmedi). 61-120 (alan
#  bilgisi) "N X Y" satır biçiminde → alınır. Alan soruları zaten bu blokta; ölçüm amacı için yeter.
#  KULLANIM: celdirici-olcum.ps1 "doğru şık en uzun mu / harf dağılımı" ölçüsü için; kalıp doğrulaması için
#  (bizim çıkmış soru kaydımızın 'dogru' alanıyla çapraz kontrol). Elle düzenlenmez; kitapçık gelince yeniden koşar.
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$dir=Join-Path $kok 'veri\sgs-arsiv'
$files=@(Get-ChildItem $dir -Recurse -Filter '*.duz.txt' -ErrorAction SilentlyContinue)
if(-not $files.Count){ Write-Host "KÖR: veri/sgs-arsiv yok (yalnız yerelde). Dosyaya dokunulmadı."; exit 0 }
$donemler=[ordered]@{}; $yok=@()
foreach($f in ($files | Sort-Object Name)){
  $t=[IO.File]::ReadAllText($f.FullName)
  $dm=[regex]::Match($f.Name,'sgs_(\d{4})_(\d)_'); if(-not $dm.Success){ continue }
  $donem="$($dm.Groups[1].Value)/$($dm.Groups[2].Value)"
  # iki sütunlu blok: "N X Y" dizileri (en az 15 ardışık); en uzun blok alınır
  # tablo PDF'te iki sütun grubuna bölünüyor (1-60 ve 61-120 ayrı bloklar) → TÜM bloklar birleştirilir (ilk koşuda yalnız en
  # uzun blok alınmıştı: 60/120 soru, "kesintisiz False")
  $bloklar=@([regex]::Matches($t,'(?:(?<![\d])\d{1,3}\s+[A-E]\s+[A-E](?=\s|$)\s*){15,}'))
  if(-not $bloklar.Count){ $yok+=$donem; continue }
  $a=[ordered]@{}; $b=[ordered]@{}
  foreach($bl in $bloklar){ foreach($m in [regex]::Matches($bl.Value,'(?<![\d])(\d{1,3})\s+([A-E])\s+([A-E])(?=\s|$)')){ $no=[int]$m.Groups[1].Value; if($no -lt 1 -or $no -gt 200){ continue }; if(-not $a.Contains("$no")){ $a["$no"]=$m.Groups[2].Value; $b["$no"]=$m.Groups[3].Value } } }
  # tutarlılık: soru numaraları 1..N aralığında kesintisiz mi?
  $nolar=@($a.Keys | ForEach-Object { [int]$_ } | Sort-Object); $kesintisiz=($nolar.Count -gt 0 -and $nolar[0] -eq 1 -and $nolar[-1] -eq $nolar.Count)
  $donemler[$donem]=[ordered]@{ kitapcik=$f.Name; adet=$a.Count; kesintisiz=$kesintisiz; a=$a; b=$b }
}
$cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak='kitapçık son sayfası (TESMER PDF); ayrı anahtar dosyası yok (04.09 sondaj)'; kitapcik=$files.Count; anahtarli=$donemler.Count; anahtarsiz=$yok.Count; yok=@($yok | Select-Object -Unique | Sort-Object); donemler=$donemler }
$hedef=Join-Path $kok 'veri\sgs-cevap-anahtari.json'
$null=RaporYaz -Hedef $hedef -Nesne $cikti -Derinlik 6 -Sessiz:$Sessiz
if(-not $Sessiz){ Write-Host ("cevap anahtarı: {0} kitapçık · anahtarlı {1} · anahtarsız {2}" -f $files.Count,$donemler.Count,$yok.Count); foreach($d in $donemler.Keys){ $x=$donemler[$d]; Write-Host ("  {0}: {1} soru · kesintisiz {2}" -f $d,$x.adet,$x.kesintisiz) } }
