# ============================================================================
#  SPL CIKMIS SINAV ARSIVI - KARNE ("yarim yutmadik" kapisi)
#
#  Cem: "hepsini yuttugumuza emin olalim, yarim yutmayalim."
#  Bu betik o cumlenin OLCUM karsiligidir. Tek soruyu sorar ve zinciri
#  ADIM ADIM gosterir - hangi adimda kac belge dustugu gorulmeden
#  "tamam" denmez:
#
#     SPL'nin kendi sayfasinda LISTELENEN
#       -> arsivde KAYDI OLAN
#         -> INEN (dort kapiyi gecen)
#           -> METNI CIKAN
#             -> AYRISTIRILAN (soru uretilen)
#
#  Her adimda dusen belgeler ADIYLA yazilir. "Sessiz daraltma yok" kurali:
#  bir belge elendiyse hangi adimda ve neden elendigi bu karnede durur.
#
#  ONEMLI: bu karne "eksik yok" DEMEZ. Yalnizca SPL'nin listesiyle elimizdekini
#  kiyaslar. SPL listesi de eksik olabilir (19-20 Aralik 2014 ve sonrasi icin
#  SPL soru/cevap YAYIMLAMIYOR) - o sinir ayrica yazilir.
#
#  KULLANIM: pwsh -File motor/spl-cikmis-karne.ps1
# ============================================================================
param([switch]$Sessiz)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
function Yaz($m, $renk='Gray'){ if(-not $Sessiz){ Write-Host $m -ForegroundColor $renk } }

function OkuJson([string]$yol){
  $t = Join-Path $kok $yol
  if(-not (Test-Path $t)){ return $null }
  return (Get-Content $t -Raw -Encoding UTF8 | ConvertFrom-Json)
}

$kesif   = OkuJson 'veri/spl-cikmis-envanteri.json'
$indirme = OkuJson 'veri/spl-cikmis-indirme.json'
$ayrisma = OkuJson 'veri/cikmis-soru-ayrisma.json'
if(-not $kesif){ throw 'veri/spl-cikmis-envanteri.json yok - once motor/spl-cikmis-kesif.ps1' }

# --- DONEM/DERS COZUMU ------------------------------------------------------
# SPL'nin arsiv sayfasinda dosya adi GUID'dir; anlam sayfadaki BAGLAMDA durur:
#   "... 31 MAYIS - 1 HAZIRAN 2014 ... Temel Duzey ... A KITAPCIGI"
# Bu yuzden donem ve ders, baglantinin ONUNDEKI metinden okunur. Okunamazsa
# UYDURULMAZ - "?" yazilir ve karnede ayri satirda sayilir.
$AYLAR = 'ocak|subat|şubat|mart|nisan|mayis|mayıs|haziran|temmuz|agustos|ağustos|eylul|eylül|ekim|kasim|kasım|aralik|aralık'
function DonemCoz([string]$ipucu, [string]$metin){
  if($ipucu){ return $ipucu }
  if(-not $metin){ return '?' }
  $m = [regex]::Match($metin, "(?i)($AYLAR)\s+(\d{4})")
  if($m.Success){ return ('{0} {1}' -f $m.Groups[1].Value, $m.Groups[2].Value) }
  $m = [regex]::Match($metin, '(?<!\d)(20\d{2})(?!\d)')
  if($m.Success){ return $m.Groups[1].Value }
  return '?'
}
function GrupCoz([string]$etiket){
  if($etiket -match '(?i)a-b'){ return 'A-B' }
  if($etiket -match '(?i)^\s*a\b'){ return 'A' }
  if($etiket -match '(?i)^\s*b\b'){ return 'B' }
  return '?'
}
function DersCoz([string]$metin, [string]$donem){
  if(-not $metin){ return '?' }
  # Baglantinin hemen onundeki en son anlamli parca ders adidir. Donem basligi
  # ve "A/B KITAPCIGI" etiketleri temizlenir.
  $t = $metin
  if($donem -ne '?'){ $t = $t -replace [regex]::Escape($donem), ' ' }
  $t = $t -replace '(?i)(a-b|a|b)\s*kitap[cç]i[gğ]i', ' '
  $t = $t -replace '(?i)cevap anahtar[iı]', ' '
  $t = ($t -replace '\s+', ' ').Trim()
  if($t.Length -gt 70){ $t = $t.Substring($t.Length - 70).Trim() }
  if(-not $t){ return '?' }
  return $t
}

# --- 1) LISTELENEN ----------------------------------------------------------
$ETIKET_BELGE = '(?i)(kitap[cç]i[gğ]i|kitapcigi|cevap anahtari|cevap anahtarı)'
$listelenen = New-Object System.Collections.ArrayList
foreach($p in @($kesif.sayfadan_pdf)){
  if("$($p.etiket)" -notmatch $ETIKET_BELGE){ continue }
  $ad = [uri]::UnescapeDataString((($p.url -split '\?')[0] -split '/')[-1])
  $don = DonemCoz "$($p.donem_ipucu)" "$($p.onceki_metin)"
  [void]$listelenen.Add([pscustomobject]@{
    ad     = $ad
    dosya  = ($ad -replace '[^\w\.\-]', '_')
    url    = $p.url
    etiket = "$($p.etiket)"
    grup   = GrupCoz "$($p.etiket)"
    donem  = $don
    ders   = DersCoz "$($p.onceki_metin)" $don
    tur    = if("$($p.etiket)" -match '(?i)cevap'){ 'cevap-anahtari' } else { 'soru-kitapcigi' }
  })
}
$listelenen = @($listelenen)

# --- 2) ARSIVDE KAYDI OLAN --------------------------------------------------
$arsivde = @{}
foreach($d in @($kesif.domain_pdf)){ $arsivde[$d.url.ToLower()] = $d.damga }
foreach($l in $listelenen){
  $l | Add-Member -NotePropertyName arsiv_kaydi -NotePropertyValue ($arsivde.ContainsKey($l.url.ToLower())) -Force
}

# --- 3/4) INEN + METNI CIKAN ------------------------------------------------
# Eslestirme ADLA DEGIL ADRESLE yapilir: indirici GUID adini anlamli adla
# degistiriyor (spk-2010_kasim-temel_duzey_a_soru.pdf), ada bakan eslestirme
# hepsini "INDIRILMEDI" gosterirdi.
$inen = @{}
if($indirme){ foreach($f in @($indirme.dosyalar)){ $inen["$($f.url)".ToLower()] = $f } }
foreach($l in $listelenen){
  $f = $inen[$l.url.ToLower()]
  if($f){ $l | Add-Member -NotePropertyName dosya -NotePropertyValue "$($f.dosya)" -Force }
  $l | Add-Member -NotePropertyName indi      -NotePropertyValue ($null -ne $f -and $f.durum -ne 'KIRMIZI') -Force
  $l | Add-Member -NotePropertyName metin_krk -NotePropertyValue $(if($f){ [int]$f.metin_krk } else { 0 }) -Force
  $l | Add-Member -NotePropertyName durum     -NotePropertyValue $(if($f){ "$($f.durum)" } else { 'INDIRILMEDI' }) -Force
}

# --- 5) AYRISTIRILAN --------------------------------------------------------
# Ayrisma raporunun alan adlari surumden surume degisebiliyor; bu yuzden
# dosya adini TASIYAN alan aranir, varsayilmaz.
$soruSayisi = @{}
if($ayrisma){
  foreach($k in @($ayrisma.PSObject.Properties)){
    if($k.Value -is [array]){
      foreach($x in $k.Value){
        $adAlani = @($x.PSObject.Properties | Where-Object { "$($_.Value)" -match '(?i)\.pdf$' -or "$($_.Name)" -match '(?i)dosya|kitapcik' }) | Select-Object -First 1
        if(-not $adAlani){ continue }
        $sayiAlani = @($x.PSObject.Properties | Where-Object { "$($_.Name)" -match '(?i)^soru|sayi|adet|yazilan|bulunan' -and $_.Value -is [int] }) | Select-Object -First 1
        if(-not $sayiAlani){ continue }
        $ad = ("$($adAlani.Value)" -split '[\\/]')[-1]
        $soruSayisi[$ad] = [int]$sayiAlani.Value
      }
    }
  }
}
foreach($l in $listelenen){
  $s = 0
  foreach($k in $soruSayisi.Keys){ if($k -eq $l.dosya -or $k -eq $l.ad){ $s = $soruSayisi[$k]; break } }
  $l | Add-Member -NotePropertyName soru -NotePropertyValue $s -Force
}

# --- HUKUM ------------------------------------------------------------------
$kitapcik = @($listelenen | Where-Object { $_.tur -eq 'soru-kitapcigi' })
$zincir = [ordered]@{
  listelenen_toplam   = $listelenen.Count
  soru_kitapcigi      = $kitapcik.Count
  cevap_anahtari      = @($listelenen | Where-Object { $_.tur -eq 'cevap-anahtari' }).Count
  arsivde_kaydi_olan  = @($listelenen | Where-Object { $_.arsiv_kaydi }).Count
  inen                = @($listelenen | Where-Object { $_.indi }).Count
  metni_cikan         = @($listelenen | Where-Object { $_.metin_krk -ge 500 }).Count
  soru_uretilen_belge = @($listelenen | Where-Object { $_.soru -gt 0 }).Count
  toplam_soru         = (@($listelenen | Measure-Object soru -Sum).Sum)
  donemi_okunamayan   = @($listelenen | Where-Object { $_.donem -eq '?' }).Count
}

$rapor = [ordered]@{
  olcum   = (Get-Date).ToString('s')
  kaynak  = 'SPL resmi arsiv sayfasinin arsivlenmis kopyasi (sayfa canli sitede 404)'
  sinir   = '19-20 Aralik 2014 ve SONRASI kagit sinavlar icin SPL soru/cevap YAYIMLAMIYOR; elektronik sinavlar hic yayimlanmadi. Bu karne yalniz SPL"nin yayimladigi donemleri kapsar.'
  zincir  = $zincir
  belgeler = @($listelenen | Sort-Object donem, ders, grup)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/spl-cikmis-karne.json'),
  (ConvertTo-Json -InputObject $rapor -Depth 6), [Text.UTF8Encoding]::new($false))

# --- MD ---------------------------------------------------------------------
$md = New-Object System.Collections.ArrayList
[void]$md.Add('# SPL CIKMIS SINAV ARSIVI - KARNE')
[void]$md.Add('')
[void]$md.Add(('> Olcum: **{0}** · MAKINE CIKTISI (motor/spl-cikmis-karne.ps1) - elle duzenlenmez.' -f $rapor.olcum))
[void]$md.Add('>')
[void]$md.Add(('> {0}' -f $rapor.sinir))
[void]$md.Add('')
[void]$md.Add('## Zincir - hangi adimda kac belge dustu')
[void]$md.Add('')
[void]$md.Add('| Adim | Belge |')
[void]$md.Add('|---|---:|')
foreach($k in $zincir.Keys){ [void]$md.Add(('| {0} | {1} |' -f ($k -replace '_',' '), $zincir[$k])) }
[void]$md.Add('')
[void]$md.Add('## Donem x ders dokumu')
[void]$md.Add('')
[void]$md.Add('| Donem | Ders | Grup | Tur | Durum | Metin (krk) | Soru |')
[void]$md.Add('|---|---|---|---|---|---:|---:|')
foreach($l in ($listelenen | Sort-Object donem, ders, grup)){
  [void]$md.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $l.donem, $l.ders, $l.grup, $l.tur, $l.durum, $l.metin_krk, $l.soru))
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/SPL-CIKMIS-KARNE.md'), (($md -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))

Yaz ''
foreach($k in $zincir.Keys){ Yaz ("  {0,-22} {1}" -f $k, $zincir[$k]) }
Yaz '  -> veri/SPL-CIKMIS-KARNE.md · veri/spl-cikmis-karne.json'
exit 0
