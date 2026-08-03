# ============================================================================
#  SIK HESAP KODU ONERISI (03.08.2026 gece) — 0 USD, API YOK, KASAYA YAZMAZ
#
#  NEDEN: Cem pilotta #194'te SIKKIN KENDI METNINDE ("500 ORTAKLARDAN ALACAKLAR")
#  bir hesap kodu hatasi buldu. hesap-kodu-denetimi.ps1 bu sinifi zaten OLCUYOR
#  (soru+siklar+aciklama - siklar dahil, ~3.075/5.377 soru) ama sadece SAYIYOR.
#  onarim-motoru.ps1'in D14-ek otomatik duzeltmesi ise YALNIZ kendi urettigi
#  YENI aciklama alanlarina dokunuyor - orijinal SIKLARA hic dokunmuyor (D11
#  "iyi olani bozma" kurali). Yani siklardaki hatalar olculuyor ama hicbir
#  arac onlari DUZELTMEYI TEKLIF etmiyordu.
#
#  BU SCRIPT NE YAPAR: hesap-kodu-denetimi.ps1'in "uymuyor" bulduğu her ciftte,
#  onarim-motoru.ps1'in D14-ek'te kullandigi AYNI GUVENLI mantikla (ResmiKodBul)
#  "yazilan AD, THP'de TEK BIR hesapla mi eslesiyor" diye arar:
#    - TEK eslesme varsa: "oneri" (kod X -> Y, guven=DETERMINISTIK)
#    - 0 ya da 2+ eslesme varsa: "supheli", dokunma teklifi YAPILMAZ
#  KASAYA HICBIR SEY YAZILMAZ - bu yalniz bir ONERI LISTESI. Cem'in kurali:
#  "ilk on ornegi gozle oku" - liste onun icin.
#
#  ONEMLI FARK: hesap-kodu-denetimi.ps1 soru+siklar+aciklamayi TEK METINDE
#  birlestirip tariyordu (konum bilgisi kayboluyordu). Bu script HER ALANI
#  AYRI tarar (soru, siklar.A..E, aciklama.A..E) - oneri "hangi sikta" diye
#  gosterebilsin diye.
#
#  CIKTI: veri/sik-hesap-kodu-onerisi.json (tam liste) ·
#  veri/sik-hesap-kodu-onerisi-raporu.json (sayilar + ilk 10 ornek)
#  ENV: SUPABASE_SERVICE_KEY
#
#  03.08.2026 20:30 - YUKSEK GUVEN SINIFI KASAYA UYGULANDI (Cem onayi):
#  105 soru / 344 alan yazildi, 105/105 geri okuma dogrulandi, yedek
#  ozel kovada yedek-sik-kod-0803-2030.json. Bu kosu BAGIMSIZ DOGRULAMADIR:
#  duzeltmeler gercekten oturduysa oneri sayisi 659'dan ~313'e dusmeli
#  (kalan = yon belirsiz olan tek-alanli cift sinifi, uygulanmadi).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/sik-hesap-kodu-onerisi.json'
$raporYol = Join-Path $kok 'veri/sik-hesap-kodu-onerisi-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"
    sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber; hat_metni="$($_.InvocationInfo.Line)".Trim() }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- RESMI KOD -> AD LISTESI (tum msugt*.json birlesir - 03.08 gece 230/231/232
#     kaymasi duzeltildi + ~39 eksik kod PDF ile eklendi) ---
$RESMI = @{}
foreach($f in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($j.belgeler)){
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $RESMI.ContainsKey($m.Groups[1].Value)){ $RESMI[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() }
    }
  } catch { Write-Host ("THP dosyasi okunamadi: {0}" -f $f.Name) }
}
Write-Host ("Resmi hesap kodu: {0}" -f $RESMI.Count)
if($RESMI.Count -lt 250){
  Write-Host "!! KIRMIZI: beklenenden az THP kodu - dosya okuma eksik olabilir."
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI'; sebep='THP referansi eksik'; okunan_kod=$RESMI.Count }))
  exit 1
}

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

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
function AdUyuyorMu([string]$iddia, [string]$resmi){
  $a = @((Sade $iddia) -split ' ' | Where-Object { $_.Length -ge 3 })
  $b = @((Sade $resmi) -split ' ' | Where-Object { $_.Length -ge 3 })
  if($a.Count -eq 0 -or $b.Count -eq 0){ return $true }
  foreach($k in $a){ foreach($r in $b){ if($k.StartsWith($r) -or $r.StartsWith($k)){ return $true } } }
  return $false
}
# D14-ek ile AYNI mantik (onarim-motoru.ps1): yazilan ad THP'de TEK bir hesapla
# mi eslesiyor - TAM kelime seti karsilastirmasi (AdUyuyorMu'dan daha SIKI,
# cunku burada rastgele "duzeltme" onerilecek - yanlisi baska yanlisla
# degistirmemek icin daha az toleransli).
function ResmiKodBul([string]$adMetni){
  $bulunan = @()
  $a = @((Sade $adMetni) -split ' ' | Where-Object { $_.Length -ge 4 })
  if($a.Count -eq 0){ return $bulunan }
  foreach($kk in $RESMI.Keys){
    $b = @((Sade $RESMI[$kk]) -split ' ' | Where-Object { $_.Length -ge 4 })
    if($b.Count -eq 0){ continue }
    $hepsiVar = $true
    foreach($x in $a){
      $var = $false
      foreach($y in $b){ if($x.StartsWith($y) -or $y.StartsWith($x)){ $var = $true; break } }
      if(-not $var){ $hepsiVar = $false; break }
    }
    if($hepsiVar){ $bulunan += $kk }
  }
  return $bulunan
}

$BIRIM = @('TL','LIRA','LİRA','USD','EUR','ADET','GUN','GÜN','AY','YIL','SAAT','KG','TON','M2','MT','PUAN','KURUS','KURUŞ','TANE','KISI','KİŞİ','TAKSIT','TAKSİT')
$reKod  = [regex]'(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*(?!numaral|no.?lu|say[ıi]l|adet|kalem|tane|hesab|hesap|kodlu|nolu)([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})'
$reKod2 = [regex]'([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})\s*\(\s*([1-8]\d{2})\s*\)'

$oneriler = New-Object System.Collections.Generic.List[object]
$supheliSayisi = 0; $uymuyorSayisi = 0; $taranan = 0

foreach($s in $kasa){
  # her ALAN ayri taranir - konum bilgisi (soru/siklar.X/aciklama.X) kaybolmasin
  $alanlar = New-Object System.Collections.Generic.List[object]
  $alanlar.Add(@{ ad='soru'; metin="$($s.soru)" })
  if($s.siklar){ foreach($p in $s.siklar.PSObject.Properties){ $alanlar.Add(@{ ad="siklar.$($p.Name)"; metin="$($p.Value)" }) } }
  if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $alanlar.Add(@{ ad="aciklama.$($p.Name)"; metin="$($p.Value)" }) } }

  foreach($al in $alanlar){
    $tum = $al.metin
    if([string]::IsNullOrWhiteSpace($tum)){ continue }
    $taranan++
    $ciftler = New-Object System.Collections.Generic.List[object]
    foreach($mm in $reKod.Matches($tum)){  $ciftler.Add(@{ kod=$mm.Groups[1].Value; ad=$mm.Groups[2].Value.Trim() }) }
    foreach($mm in $reKod2.Matches($tum)){ $ciftler.Add(@{ kod=$mm.Groups[2].Value; ad=$mm.Groups[1].Value.Trim() }) }
    foreach($cf in $ciftler){
      $kod = $cf.kod; $ad = $cf.ad
      if($ad.Length -lt 4){ continue }
      $ilkKelime = (Sade $ad) -split ' ' | Select-Object -First 1
      if($BIRIM -contains $ilkKelime){ continue }
      if(-not $RESMI.ContainsKey($kod)){ continue }   # kod hic yok - ayri konu, hesap-kodu-denetimi.ps1 zaten olcuyor
      $adIddiaMi = $false
      foreach($resmiAd in $RESMI.Values){ if(AdUyuyorMu $ad $resmiAd){ $adIddiaMi = $true; break } }
      if(-not $adIddiaMi){ continue }                  # hesap adi iddiasi degil (D24/beyaz liste mantigi)
      if(AdUyuyorMu $ad $RESMI[$kod]){ continue }       # zaten dogru
      $uymuyorSayisi++
      # 03.08 gece dersi: ResmiKodBul TEK eslesme donunce PowerShell donusu
      # skaler string'e "unwrap" ediyor - $aday[0] o zaman dizinin ilk
      # elemanini degil, STRING'IN ILK KARAKTERINI veriyordu ("159" -> "1").
      # @() ile CAGRI NOKTASINDA sarmak diziligi garanti eder.
      $aday = @(ResmiKodBul $ad)
      if($aday.Count -eq 1){
        $oneriler.Add([ordered]@{
          soru_id="$($s.id)"; ders="$($s.ders)"; alan=$al.ad; yayinda=[bool]$s.yayin
          yazili_kod=$kod; yazili_ad=$ad
          onerilen_kod=$aday[0]; onerilen_ad=$RESMI[$aday[0]]
          guven='DETERMINISTIK_TEK_ESLESME'
        })
      } else {
        $supheliSayisi++
      }
    }
  }
}

$detSayi = $oneriler.Count
Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -Depth 6 -InputObject ([ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama='Sadece ONERI - kasaya hicbir sey yazilmadi. guven=DETERMINISTIK_TEK_ESLESME olanlar D14-ek ile AYNI mantikla (yazilan ad THP''de TEK hesapla eslesiyor) bulundu. Uygulamadan once Cem ilk 10 ornegi gozle okur.'
  oneriler=$oneriler.ToArray()
})) -Encoding UTF8 -NoNewline

Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  kasa=$kasa.Count; taranan_alan=$taranan
  toplam_uymuyor_cift=$uymuyorSayisi
  deterministik_oneri=$detSayi
  supheli_dokunulmayan=$supheliSayisi
  ilk_10_ornek=@($oneriler | Select-Object -First 10)
  not='Kasaya HICBIR SEY YAZILMADI - bu yalniz oneri. Tam liste veri/sik-hesap-kodu-onerisi.json icinde.'
}))
Write-Host "`n=== SIK HESAP KODU ONERISI ==="
Write-Host ("  Taranan alan               : {0}" -f $taranan)
Write-Host ("  Uymayan cift (toplam)      : {0}" -f $uymuyorSayisi)
Write-Host ("  Deterministik oneri        : {0}" -f $detSayi)
Write-Host ("  Supheli (dokunulmadi)      : {0}" -f $supheliSayisi)
