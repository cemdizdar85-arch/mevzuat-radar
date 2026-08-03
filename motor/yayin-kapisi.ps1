# ============================================================================
#  YAYIN KAPISI (03.08.2026) — 0 USD, API YOK
#
#  CEM: "böyle bir hata ile bir daha karşılaşmamak için ne yapacaksan yap."
#
#  EKSIK OLAN YAPISAL PARCA BUYDU: kurallarimiz vardi, sayaclarimiz olmaya
#  basladi, ama KIRMIZI BIR SAYAC VARKEN YAYINI DURDURAN HICBIR SEY YOKTU.
#  Bir kural ancak yayini durdurabiliyorsa kuraldir; durduramiyorsa temennidir.
#
#  KAPSAM: yalniz YAYINDA olan sorular (yayin=true). Yayindan cekilmis soru
#  onarim kuyrugundadir, onu suclamak anlamsiz. Yayindakinde SIFIR TOLERANS.
#
#  ALTI KAPI:
#    K1 D3  - "bu sik yanlis cunku dogru cevap X" (ogretmeyen aciklama)
#    K2 D12 - kanun kopyasi dili (bilumum, muteferri, munasebetiyle...)
#    K3 D12 - yapay zeka doldurma kaliplari
#    K4 D14 - hesap kodu THP'nin resmi adiyla uyusmuyor
#    K5 D2  - yanlis siklarda "Dogrusu:" hic yok
#    K6 D10 - ayni cumle birden fazla sikka yazilmis
#
#  KARAR: hepsi 0 ise GECER, degilse DURDU. Karar dosyaya yazilir; yayin
#  akisindaki her adim once bu dosyaya bakar.
#
#  ONEMLI: bu script KASAYA DOKUNMAZ. Yalniz olcer ve karar verir. Kirmizi
#  soruyu yayindan indirmek AYRI bir adimdir (-uygula), cunku toplu yayindan
#  indirme Cem'in gorup onaylamasi gereken bir karardir.
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/yayin-kapisi.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/yayin-kapisi.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 5
  if($j.Length -gt 60000){ $j = ConvertTo-Json -Depth 2 -InputObject @{ karar='DURDU'; sebep='rapor sismis - icerik sizmis olabilir'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  # Kapi COKERSE de GECER demez - olculemeyen sey guvenli sayilmaz.
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); karar='DURDU'
    sebep='kapi kosarken hata aldi - olculemeyen sey guvenli sayilmaz'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- Turkce duyarsiz sadelestirme: KARAKTER KARAKTER (regex degil).
# 03.08 dersi: -replace ile Turkce harf donusturmek "TAŞITLAR"i "TAS TLAR" yapip
# sahte uyusmazlik uretmisti. Acik esleme gizli surpriz birakmaz.
$HARF = @{
  [char]0x0130='I'; [char]0x0131='I'; [char]'i'='I'; [char]'I'='I'
  [char]0x015E='S'; [char]0x015F='S'; [char]0x011E='G'; [char]0x011F='G'
  [char]0x00DC='U'; [char]0x00FC='U'; [char]0x00D6='O'; [char]0x00F6='O'
  [char]0x00C7='C'; [char]0x00E7='C'
}
function Sade([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}

# --- THP resmi kod->ad ---
$RESMI = @{}
$thpYol = Join-Path $kok 'veri/mevzuat/msugt-thp-tam.json'
if(Test-Path $thpYol){
  $thp = Get-Content $thpYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($b in @($thp.belgeler)){
    $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
    if($m.Success){ $RESMI[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() }
  }
}
if($RESMI.Count -lt 50){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); karar='DURDU'
    sebep="THP resmi listesi okunamadi (okunan: $($RESMI.Count)) - hesap kodu kapisi calisamaz" })
  Write-Host "DURDU: THP listesi okunamadi."; exit 1
}

# --- YAYINDA olan sorular ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak&yayin=eq.true&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Yayinda olan soru: {0}" -f $kasa.Count)

# --- desenler ---
# K1 (D3): "X yanlis CUNKU dogru cevap Y" kalibi - ogretmez, sadece isaret eder
$reD3 = [regex]'(?i)(yanl[ıi][şs]t[ıi]r|yanl[ıi][şs]\s+olup|do[ğg]ru\s+de[ğg]ildir)[^.]{0,60}\b[çc][üu]nk[üu]\b[^.]{0,60}(do[ğg]ru\s+(cevap|se[çc]enek|[şs][ıi]k)|as[ıi]l\s+cevap)'
$reD3b = [regex]'(?i)\bdo[ğg]ru\s+(cevap|se[çc]enek|[şs][ıi]k)\s*[:\(]?\s*[A-E]\b[^.]{0,30}(oldu[ğg]u\s+i[çc]in|olmas[ıi]\s+nedeniyle)'
$reKanun = [regex]'(?i)bil[üu]mum|m[üu]teferri|m[üu]nasebetiyle|i[şs]bu\b|mezk[üu]r|mutazamm[ıi]n|keyfiyet'
$reYZ    = [regex]'(?i)[öo]nemli bir husus|dikkat edilmesi gereken nokta|sonu[çc] olarak|[öo]zetle\s*,|bu ba[ğg]lamda|unutulmamal[ıi]d[ıi]r'
$reDogrusu = [regex]'(?i)do[ğg]rusu\s*:'
$BIRIM = @('TL','LIRA','USD','EUR','ADET','GUN','AY','YIL','SAAT','KG','TON','M2','MT','PUAN','KURUS','TANE','KISI','TAKSIT')
$reHesap = [regex]'(?<![\d.,])\b([1-8]\d{2})\s+([A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})'
function AdUyuyorMu([string]$iddia, [string]$resmi){
  $a = @((Sade $iddia) -split ' ' | Where-Object { $_.Length -ge 4 })
  $b = @((Sade $resmi) -split ' ' | Where-Object { $_.Length -ge 4 })
  if($a.Count -eq 0 -or $b.Count -eq 0){ return $true }
  foreach($k in $a){ if($b -contains $k){ return $true } }
  return $false
}

$K = [ordered]@{ K1_d3=0; K2_kanun_kopyasi=0; K3_yz_kokusu=0; K4_hesap_kodu=0; K5_dogrusu_yok=0; K6_ayni_cumle=0 }
$kirmiziId = @{}
$ornek = New-Object System.Collections.Generic.List[object]
function Isaretle($kapi, $s, $detay){
  $script:K[$kapi]++
  $script:kirmiziId["$($s.id)"] = 1
  if($script:ornek.Count -lt 30){
    $script:ornek.Add([ordered]@{ kapi=$kapi; soru_id="$($s.id)"; ders="$($s.ders)"; detay=$detay })
  }
}

foreach($s in $kasa){
  $dh = "$($s.dogru)".Trim().ToUpper()
  $yanlisMetin = ''
  $dogrusuVar = 0; $yanlisSik = 0
  $gorulen = @{}
  foreach($h in 'A','B','C','D','E'){
    $m=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$h]){ $m="$($s.aciklama.$h)" } } catch {}
    if($m.Trim().Length -lt 5){ continue }
    if($h -eq $dh){ continue }
    $yanlisSik++; $yanlisMetin += ' ' + $m
    if($reDogrusu.IsMatch($m)){ $dogrusuVar++ }
    $anah = Sade $m
    if($anah.Length -gt 20){ if($gorulen.ContainsKey($anah)){ Isaretle 'K6_ayni_cumle' $s "iki sikta ayni metin" }; $gorulen[$anah]=1 }
  }
  $tumAciklama = $yanlisMetin
  try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $tumAciklama += ' ' + "$($s.aciklama.$dh)" } } catch {}

  if($reD3.IsMatch($tumAciklama) -or $reD3b.IsMatch($tumAciklama)){ Isaretle 'K1_d3' $s 'ogretmeyen kalip: "yanlis cunku dogru cevap X"' }
  if($reKanun.IsMatch($tumAciklama)){ Isaretle 'K2_kanun_kopyasi' $s 'kanun kopyasi dili' }
  if($reYZ.IsMatch($tumAciklama)){ Isaretle 'K3_yz_kokusu' $s 'yapay zeka doldurma kalibi' }
  if($yanlisSik -ge 3 -and $dogrusuVar -eq 0){ Isaretle 'K5_dogrusu_yok' $s "yanlis sik $yanlisSik, Dogrusu 0" }

  $tum = "$($s.soru) $tumAciklama"
  foreach($mm in $reHesap.Matches($tum)){
    $kod = $mm.Groups[1].Value; $ad = $mm.Groups[2].Value.Trim()
    if($ad.Length -lt 4){ continue }
    $ilk = (Sade $ad) -split ' ' | Select-Object -First 1
    if($BIRIM -contains $ilk){ continue }
    if(-not $RESMI.ContainsKey($kod)){ continue }      # THP disi kod: ayri denetimin isi
    if(-not (AdUyuyorMu $ad $RESMI[$kod])){ Isaretle 'K4_hesap_kodu' $s "$kod yazilan '$ad' resmi '$($RESMI[$kod])'" }
  }
}

$toplam = 0; foreach($v in $K.Values){ $toplam += $v }
$karar = if($toplam -eq 0){ 'GECER' } else { 'DURDU' }
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  karar=$karar
  yayinda_soru=$kasa.Count
  kirmizi_soru=$kirmiziId.Count
  kapilar=$K
  toplam_ihlal=$toplam
  ornekler=$ornek.ToArray()
  kural='Yayindaki soruda SIFIR TOLERANS. Kapi cokerse de GECER demez - olculemeyen sey guvenli sayilmaz.'
  not='Bu kapi kasaya DOKUNMAZ, yalniz olcer. Kirmizi sorulari yayindan indirmek ayri ve Cem onayli bir adimdir.'
}
RaporYaz $rapor
Write-Host "`n=== YAYIN KAPISI: $karar ==="
foreach($k in $K.Keys){ Write-Host ("  {0,-20} {1}" -f $k, $K[$k]) }
Write-Host ("  Kirmizi soru: {0} / {1}" -f $kirmiziId.Count, $kasa.Count)
if($karar -eq 'DURDU'){ exit 1 }
