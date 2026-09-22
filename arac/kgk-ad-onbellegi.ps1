#requires -Version 5.1
<#
================================================================================
  KGK AMBAR ADI ÖNBELLEĞİ — ortak yardımcı (22.09.2026)

  NEDEN VAR (21.09 ölçüldü, Kâr Payı Tebliği II-19.1 vakası): dört betik ambarın
  ad listesini CANLI değil, veri/fabrika/kosucu-log/kgk-kaynak-adlar.json
  önbelleğinden okuyor. Önbellek 16.09'dan kalmıştı (119 saat); m.19 ambara
  yazıldığı hâlde tamlık raporu "ambar 18 · EKSİK" diyordu — kapı BAYAT VERİDEN
  kırmızı veriyordu. Ad listesini okuyan her betik artık bu yardımcıyı çağırır.

  KULLANIM
    . (Join-Path $PSScriptRoot 'kgk-ad-onbellegi.ps1')
    $adlar = KgkAdListesi -DepoKok $depoKok -Baslik $H [-EnCokSaat 24] [-Tazele]

  DÖNÜŞ: kaynak_ad alanı taşıyan nesne dizisi (önbellek dosyasının içeriği).
  Ekrana her çağrıda önbelleğin YAŞI yazılır; tazeleme düşerse "ÖNBELLEK BAYAT"
  der ve eski listeyle devam eder — sessiz yeşil yoktur.

  BU YARDIMCI ŞUNU GÖRMEZ: önbellekteki adların ambardaki metinle uyumu
  (ad var, metin bozuk olabilir — o ölçüm arac/ambar-metin-kusuru.ps1'de).
  Öz-sınav: powershell -NoProfile -File arac/kgk-ad-onbellegi.ps1 -OzSinav
================================================================================
#>
param([switch]$OzSinav)

function KgkAdListesi {
  param(
    [Parameter(Mandatory=$true)][string]$DepoKok,
    $Baslik = $null,                       # verilmezse ortam değişkeninden kurulur (bu betikleri çağıranların çoğunda ambar başlığı yok)
    [int]$EnCokSaat = 24,
    [switch]$Tazele,
    [string]$SbUrl = 'https://bjrleanjpyujtajmazxn.supabase.co'
  )
  if(-not $Baslik){
    $an = "$($env:SUPABASE_SERVICE_KEY)".Trim()
    if(-not $an){ $an = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
    if($an){ $Baslik = @{ apikey=$an; Authorization="Bearer $an"; 'User-Agent'='mevzuat-radar-robot/1.0' } }
  }
  $yol = Join-Path $DepoKok 'veri\fabrika\kosucu-log\kgk-kaynak-adlar.json'
  $klasor = Split-Path -Parent $yol
  if(-not (Test-Path $klasor)){ [void](New-Item -ItemType Directory -Force $klasor) }
  $yasSaat = if(Test-Path $yol){ [Math]::Round(((Get-Date) - (Get-Item $yol).LastWriteTime).TotalHours,1) } else { 9999 }
  if(-not $Baslik -and ($yasSaat -gt $EnCokSaat)){ Write-Host ("ÖNBELLEK BAYAT ({0} saat) ve ambar anahtarı YOK — tazelenemedi (KÖR)" -f $yasSaat) -ForegroundColor Yellow }
  if($Baslik -and ($yasSaat -gt $EnCokSaat -or $Tazele)){
    Write-Host ("ambar adı önbelleği {0} saatlik — tazeleniyor..." -f $yasSaat)
    try {
      $tum = New-Object System.Collections.Generic.List[object]
      $adim = 1000; $ofs = 0
      while($true){
        $sayfa = @(); foreach($x in (Invoke-RestMethod -Uri "$SbUrl/rest/v1/dokumanlar?select=kaynak_ad&order=id&limit=$adim&offset=$ofs" -Headers $Baslik -TimeoutSec 180)){ $sayfa += $x }
        if(-not $sayfa.Count){ break }
        foreach($x in $sayfa){ $tum.Add([pscustomobject]@{ kaynak_ad = "$($x.kaynak_ad)" }) }
        $ofs += $adim
        if($sayfa.Count -lt $adim){ break }
      }
      if($tum.Count -ge 1000){
        [IO.File]::WriteAllText($yol, [string](ConvertTo-Json -InputObject $tum.ToArray() -Depth 3), (New-Object Text.UTF8Encoding($false)))
        Write-Host ("  ambar adı önbelleği tazelendi: {0} kayıt" -f $tum.Count)
        $yasSaat = 0
      } else { Write-Host ("  TAZELEME KÖR: ambardan {0} kayıt geldi (<1000) — eski önbellek korundu" -f $tum.Count) -ForegroundColor Yellow }
    } catch { Write-Host ("  TAZELEME DÜŞTÜ: {0} — ÖNBELLEK BAYAT ({1} saat) ile devam" -f $_.Exception.Message, $yasSaat) -ForegroundColor Yellow }
  }
  Write-Host ("ambar adı önbelleği: {0} saatlik" -f $yasSaat)
  if(-not (Test-Path $yol)){ Write-Host 'ÖNBELLEK YOK — ad listesi okunamadı (KÖR)' -ForegroundColor Red; return @() }
  return (Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json)
}

if($OzSinav){
  # Kapı kurma kuralı 2: yakalaması gerekeni yakalar, yanlış alarm vermez.
  #  1) taze önbellek -> ağ isteği YAPILMAZ (sahte başlıkla çağrılır; istek gitseydi patlardı)
  #  2) önbellek yoksa -> boş dizi + KÖR uyarısı (sessiz yeşil yok)
  $gecici = Join-Path ([IO.Path]::GetTempPath()) ("adonb-" + [Guid]::NewGuid().ToString('N').Substring(0,8))
  [void](New-Item -ItemType Directory -Force (Join-Path $gecici 'veri\fabrika\kosucu-log'))
  $gecti = 0; $kaldi = 0
  $sahteYol = Join-Path $gecici 'veri\fabrika\kosucu-log\kgk-kaynak-adlar.json'
  [IO.File]::WriteAllText($sahteYol, '[{"kaynak_ad":"BDS 200 p.1 - Kapsam"}]', (New-Object Text.UTF8Encoding($false)))
  $liste = KgkAdListesi -DepoKok $gecici -Baslik @{ apikey='SINAV'; Authorization='Bearer SINAV' } -EnCokSaat 24
  if(@($liste).Count -eq 1){ $gecti++; Write-Host '  OK    taze önbellek okundu, ağa gidilmedi' } else { $kaldi++; Write-Host "  KALDI taze önbellek: beklenen 1 kayıt, gelen $(@($liste).Count)" -ForegroundColor Red }
  [IO.File]::Delete($sahteYol)
  $bos = KgkAdListesi -DepoKok $gecici -Baslik @{ apikey='SINAV'; Authorization='Bearer SINAV' } -EnCokSaat 24
  if(@($bos).Count -eq 0){ $gecti++; Write-Host '  OK    önbellek yok -> KÖR, boş liste' } else { $kaldi++; Write-Host '  KALDI önbellek yokken boş dönmedi' -ForegroundColor Red }
  Remove-Item $gecici -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host ("ÖZ-SINAV: geçti {0} · kaldı {1}" -f $gecti,$kaldi)
  exit $(if($kaldi){ 1 } else { 0 })
}
