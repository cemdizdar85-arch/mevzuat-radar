# Tam yutma kosusunda yukleme hatasi alan 3 kanunu YEREL JSON'dan canli ambara geri yukler.
# Iki duzeltme: (1) her belge AYNI anahtar kumesine normalize edilir (PGRST102 sebebi),
# (2) parti boyu 500 -> 200 (500 Ic Sunucu Hatasi sebebi muhtemelen buydu).
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$k = $env:SUPABASE_SERVICE_KEY
if (-not $k) { Write-Output "ANAHTAR YOK - durduruldu"; exit 1 }
$H = @{ apikey = $k; Authorization = "Bearer $k"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$U = "https://bjrleanjpyujtajmazxn.supabase.co"
# DIKKAT: bu .ps1 BOM'suz UTF-8; Windows PowerShell 5.1 boyle dosyalari ANSI okur ve
# yoldaki Turkce harfleri bozar. Kok dizin bu yuzden ARGUMAN olarak geliyor.
$kok = if($args[0]){ $args[0] } else { Split-Path -Parent $PSScriptRoot }
if (-not $kok) { Write-Output "KOK DIZIN ARGUMANI YOK - durduruldu"; exit 1 }

$isler = @(
  @{ slug = "vuk";    ad = "VUK (213 s.K.)" },
  @{ slug = "hmk";    ad = "HMK (6100 s.K.)" },
  @{ slug = "khk660"; ad = "KGK Kurulus KHK (660 s.)" }
)

foreach ($is in $isler) {
  $yol = Join-Path $kok ("veri\mevzuat\" + $is.slug + ".json")
  if (-not (Test-Path $yol)) { Write-Output ("ATLANDI (json yok): " + $is.slug); continue }
  $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $ham = @($j.belgeler)

  # --- ANAHTAR NORMALIZASYONU: PostgREST toplu eklemede butun nesneler ayni anahtarlari ister
  $docs = foreach ($d in $ham) {
    [pscustomobject]@{
      tur           = if ($d.tur) { "$($d.tur)" } else { "kanun-madde" }
      kaynak_ad     = "$($d.kaynak_ad)"
      baslik        = if ($null -ne $d.baslik) { "$($d.baslik)" } else { "" }
      metin         = "$($d.metin)"
      kaynak_url    = if ($null -ne $d.kaynak_url) { "$($d.kaynak_url)" } else { "" }
      belge_tarihi  = if ($null -ne $d.belge_tarihi) { "$($d.belge_tarihi)" } else { "" }
    }
  }
  $docs = @($docs)

  $q = [uri]::EscapeDataString("$($is.ad)*")
  try {
    Invoke-RestMethod -Method Delete -Uri "$U/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer = "return=minimal" }) -TimeoutSec 180 | Out-Null
  } catch { Write-Output ("  sil UYARI (" + $is.slug + "): " + $_.Exception.Message) }

  $hata = 0
  for ($i = 0; $i -lt $docs.Count; $i += 200) {
    $son = [Math]::Min($i + 200, $docs.Count) - 1
    $dilim = @($docs[$i..$son])
    $bj = ($dilim | ConvertTo-Json -Depth 5)
    if ($dilim.Count -eq 1) { $bj = "[$bj]" }
    $gonder = [Text.Encoding]::UTF8.GetBytes($bj)
    try {
      Invoke-RestMethod -Method Post -Uri "$U/rest/v1/dokumanlar" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 300 | Out-Null
    } catch { $hata++; Write-Output ("  ekle HATA " + $is.slug + " batch " + $i + ": " + $_.Exception.Message) }
  }

  # --- GERI OKU
  $Hc = $H + @{ Prefer = 'count=exact' }
  $r = Invoke-WebRequest -Method Get -Uri "$U/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q&select=id&limit=1" -Headers $Hc -UseBasicParsing -TimeoutSec 60
  $cr = "$($r.Headers['Content-Range'])"
  $canli = ($cr -split '/')[-1]
  $durum = if ("$canli" -eq "$($docs.Count)") { "TAM" } else { "EKSIK" }
  Write-Output ("{0,-26} yerel {1,4} -> canli {2,4}  parti-hatasi {3}  [{4}]" -f $is.ad, $docs.Count, $canli, $hata, $durum)
}
