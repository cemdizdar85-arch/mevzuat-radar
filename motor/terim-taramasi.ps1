# ============================================================================
#  TERIM TARAMASI (03.08.2026) — 0 USD, API YOK
#
#  CEM: "sadece bu degil, buna benzer her sey degisecek. Sen boyle yaparsan
#        ben 17 bin soruya bakmak zorunda kalirim."
#
#  HAKLI VE BU BENIM SUREC HATAM: o buluyor, ben O ORNEGE regex yaziyorum.
#  "genel imal gideri" duzeldi ama AYNI SINIFTAN kac terim var - bilmiyoruz.
#  Boyle giderse kusurlari Cem'in gozu bulacak; 27.478 soru bir insanin isi degil.
#
#  BU ROBOT SINIFIN TAMAMINI TARAR: kasadaki tum aciklamalarin kelime dagilimini
#  cikarir ve ESKI DIL ADAYLARINI listeler. Cikti tek bir LISTE - Cem 17 bin
#  soruya degil, o listeye bakar.
#
#  UC SINYAL (hicbiri tek basina karar vermez, birlikte aday uretir):
#   1) SAPKALI HARF (â î û) - Osmanlica kokenli hukuk/muhasebe dilinin izi
#   2) TOHUM LISTE - bilinen eski terimler ve bilinen guncel karsiliklari
#   3) THP'DE OLMAYAN muhasebe terimi - resmi hesap adlarinda gecmeyen ama
#      kasada sik gecen kelimeler (ornek: "imal" THP'de yok, "uretim" var)
#
#  CIKTI: veri/terim-adaylari.json - kelime, kac soruda gectigi, ornek 3 soru ID,
#  varsa onerilen guncel karsiligi. KARAR INSANIN: liste onerir, degistirmez.
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/terim-adaylari.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/terim-adaylari.json'
$raporYol = Join-Path $kok 'veri/terim-taramasi-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g }))
  Write-Host ("HATA: {0}" -f $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- TOHUM: bilinen eski terim -> guncel karsiligi ---
# Kucuk baslar, tarama sonucu buyur. Karsiligi bilinmiyorsa bos birakilir -
# uydurma karsilik YAZILMAZ, "incele" denir.
$TOHUM = [ordered]@{
  'imal gideri'      = 'uretim gideri (THP 730)'
  'genel imal'       = 'genel uretim'
  'mubayaa'          = 'satin alma'
  'muhammen'         = 'tahmini'
  'bilumum'          = 'tum/butun'
  'muteferri'        = 'baglantili/ilgili'
  'munasebetiyle'    = 'nedeniyle'
  'mezkur'           = 'anilan/soz konusu'
  'isbu'             = 'bu'
  'tanzim'           = 'duzenleme'
  'keyfiyet'         = 'durum'
  'mutazammin'       = 'iceren'
  'ita'              = ''
  'tediye'           = ''      # tediye HALA gecerli muhasebe terimi - incele
  'zayi'             = 'kayip'
  'tahakkuk'         = ''      # tahakkuk GUNCEL terim - dokunma
  'mahsup'           = ''      # mahsup GUNCEL terim - dokunma
  'iktisadi kiymet'  = 'varlik (VUK lafzi korunabilir)'
  'emtia'            = 'stok/mal (VUK lafzi korunabilir)'
}

# --- MODERN SOZLUK: THP resmi hesap adlari (guncel muhasebe dili) ---
$modern = @{}
$thpYol = Join-Path $kok 'veri/mevzuat/msugt-thp-tam.json'
if(Test-Path $thpYol){
  $thp = Get-Content $thpYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($b in @($thp.belgeler)){
    foreach($w in (("$($b.kaynak_ad)" + ' ' + "$($b.baslik)").ToLowerInvariant() -split '[^a-zçğıöşü]+')){
      if($w.Length -ge 4){ $modern[$w] = 1 }
    }
  }
}
Write-Host ("Modern sozluk (THP): {0} kelime" -f $modern.Count)

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,aciklama,hap&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu." }

$sapkali = @{}   # sapkali harf tasiyan kelimeler
$tohumHit = @{}  # tohum listedeki terimler
$kelime = @{}    # tum kelime sayaci (5+ harf)
$ornek = @{}     # kelime -> ilk 3 soru id
function Ekle($tablo, $anah, $sid){
  if(-not $tablo.ContainsKey($anah)){ $tablo[$anah] = 0 }
  $tablo[$anah]++
  if(-not $ornek.ContainsKey($anah)){ $ornek[$anah] = New-Object System.Collections.Generic.List[string] }
  if($ornek[$anah].Count -lt 3 -and -not $ornek[$anah].Contains($sid)){ $ornek[$anah].Add($sid) }
}

foreach($s in $kasa){
  $sid = "$($s.id)"
  $tum = "$($s.soru) $($s.hap)"
  if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }
  $kucuk = $tum.ToLowerInvariant()

  # 1) SAPKALI HARF
  foreach($mm in [regex]::Matches($tum, '(?i)\b[a-zçğıöşüâîû]*[âîû][a-zçğıöşüâîû]*\b')){
    $w = $mm.Value.ToLowerInvariant()
    if($w.Length -ge 4){ Ekle $sapkali $w $sid }
  }
  # 2) TOHUM LISTE
  foreach($t in $TOHUM.Keys){ if($kucuk.Contains($t)){ Ekle $tohumHit $t $sid } }
  # 3) GENEL KELIME SAYIMI (THP karsilastirmasi icin)
  foreach($w in ($kucuk -split '[^a-zçğıöşüâîû]+')){
    if($w.Length -ge 5){ Ekle $kelime $w $sid }
  }
}

# 3'un sonucu: kasada SIK gecen ama THP sozlugunde HIC olmayan kelimeler.
# Bu tek basina "eski" demek degildir (hukuk terimi de olabilir) - ADAYDIR.
$thpDisi = New-Object System.Collections.Generic.List[object]
foreach($w in ($kelime.Keys | Sort-Object { -$kelime[$_] } | Select-Object -First 400)){
  if($modern.ContainsKey($w)){ continue }
  if($kelime[$w] -lt 30){ continue }
  $thpDisi.Add([ordered]@{ kelime=$w; soru=$kelime[$w]; ornek=@($ornek[$w]) })
}

function Sirala($tablo, $enFazla){
  $l = New-Object System.Collections.Generic.List[object]
  foreach($k in ($tablo.Keys | Sort-Object { -$tablo[$_] } | Select-Object -First $enFazla)){
    $l.Add([ordered]@{ terim=$k; soru=$tablo[$k]; onerilen=$(if($TOHUM.Contains($k)){ $TOHUM[$k] } else { '' }); ornek=@($ornek[$k]) })
  }
  return $l.ToArray()
}

$paket = [ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  kasa=$kasa.Count
  yontem='Uc sinyal: (1) sapkali harf tasiyan kelimeler, (2) bilinen eski terim tohum listesi, (3) kasada sik gecip THP sozlugunde hic gecmeyen kelimeler. Hicbiri tek basina karar vermez - ADAY uretir.'
  uyari='Bu liste ONERIDIR. "tahakkuk", "mahsup", "tediye" gibi terimler GUNCEL muhasebe dilidir - degistirilmez. Karar insanindir.'
  tohum_bulunan=Sirala $tohumHit 40
  sapkali_kelimeler=Sirala $sapkali 60
  thp_disi_sik_kelimeler=$thpDisi.ToArray()
}
Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -InputObject $paket -Depth 6) -Encoding UTF8 -NoNewline
Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  kasa=$kasa.Count; tohum_bulunan=$tohumHit.Count; sapkali=$sapkali.Count; thp_disi=$thpDisi.Count
  en_sik_tohum=@(($tohumHit.Keys | Sort-Object { -$tohumHit[$_] } | Select-Object -First 8) | ForEach-Object { [ordered]@{ terim=$_; soru=$tohumHit[$_] } })
  not='Liste veri/terim-adaylari.json icinde. Cem 27.478 soruya degil BU LISTEYE bakar.' }))
Write-Host "`n=== TERIM TARAMASI ==="
Write-Host ("  Tohum listeden bulunan : {0} terim" -f $tohumHit.Count)
Write-Host ("  Sapkali harfli kelime  : {0}" -f $sapkali.Count)
Write-Host ("  THP disi sik kelime    : {0}" -f $thpDisi.Count)
foreach($k in ($tohumHit.Keys | Sort-Object { -$tohumHit[$_] } | Select-Object -First 10)){
  Write-Host ("    {0,-22} {1,5} soruda" -f $k, $tohumHit[$k])
}
