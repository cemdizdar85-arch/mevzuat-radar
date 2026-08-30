# ============================================================================
#  ALACAK VITRIN SAGLIK NOBETI  (30.08.2026)
#
#  NEDEN VAR: 30.08 aksami POST 5'in rakamlarini yayin oncesi dogrularken
#  alacak_vitrin RPC'si HTTP 500 dondu:
#      {"code":"57014","message":"canceling statement due to statement timeout"}
#  Ikinci denemede gecti. Yani kusur ARALIKLI - tek olcum yakalamaz, ve tam da
#  bu yuzden bugune kadar fark edilmemis.
#
#  NEDEN ONEMLI: bu, alacak-radari.html'in ACILIS cagrisidir. Kullaniciya
#  "Canli akis su an yuklenemedi" yaziliyor (sayfa durust davraniyor, sessiz
#  bos kalmiyor) - ama akis yuklenmiyorsa sayfa da is gormuyor.
#
#  NE OLCER: RPC'yi dort farkli govdeyle N kez cagirir; SURE dagilimini ve
#  HATA oranini raporlar. Aralikli kusuru yakalamanin tek yolu tekrardir.
#
#  UC SONUC (kalici sigorta kurali):
#    YESIL   - olculdu, hata yok ve sureler esigin altinda
#    KIRMIZI - olculdu, hata var ya da sure esigi asildi
#    KOR     - OLCULEMEDI (ag yok / anahtar yok). Sifir hata DEGIL.
#
#  Env: TEKRAR (varsayilan 4) · SURE_ESIGI_MS (varsayilan 3000)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$URL  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/alacak_vitrin'
# Sayfanin kendi ACIK anahtari - kasa RLS'te, bu anahtar yalniz RPC cagirir.
$KEY  = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg'

$TEKRAR = if ($env:TEKRAR) { [int]$env:TEKRAR } else { 4 }
$ESIK   = if ($env:SURE_ESIGI_MS) { [int]$env:SURE_ESIGI_MS } else { 3000 }

# Sayfanin gercekte kullandigi dort cagri (alacak-radari.html: aiGovde)
$GOVDELER = @(
  @{ ad = 'acilis (bos govde)'; g = @{} }
  @{ ad = 'tur=konkordato';     g = @{ p_tur = 'konkordato' } }
  @{ ad = 'tur=iflas';          g = @{ p_tur = 'iflas' } }
  @{ ad = 'durum=tasdik';       g = @{ p_durum = 'tasdik' } }
)

$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'Content-Type' = 'application/json' }
$sonuc = @(); $korMu = $true

foreach ($t in $GOVDELER) {
  $govde = ($t.g | ConvertTo-Json -Compress)
  if ($govde -eq 'null' -or -not $govde) { $govde = '{}' }
  for ($i = 1; $i -le $TEKRAR; $i++) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $kod = 0; $hata = ''
    try {
      # -UseBasicParsing ZORUNLU: PS 5.1'de Invoke-WebRequest varsayilan olarak
      # IE DOM ayristiricisini cagirir ve bu makinede NullReferenceException
      # atiyor. Ilk kosuda 16/16 cagri "HTTP 0 · Nesne basvurusu..." dondu ve
      # nobetci YANLIS ALARM verdi - oysa ayni cagrilar node ile 200 donuyordu.
      # DERS: olcum aracinin kendisi de olculur; nobetcinin kirmizisi once
      # NOBETCIDEN suphelenmeyi gerektirir.
      $c = Invoke-WebRequest -Method Post -Uri $URL -Headers $H -Body $govde -TimeoutSec 30 -UseBasicParsing
      $kod = [int]$c.StatusCode
      $korMu = $false
    } catch {
      $kod = 0
      if ($_.Exception.Response) { $kod = [int]$_.Exception.Response.StatusCode; $korMu = $false }
      $hata = "$($_.Exception.Message)"
      # PostgREST hata govdesini oku - "statement timeout" mu yoksa baska mi?
      try {
        $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
        $govdeHata = $sr.ReadToEnd()
        if ($govdeHata -match '"message"\s*:\s*"([^"]+)"') { $hata = $Matches[1] }
      } catch { }
    }
    $sw.Stop()
    $sonuc += [pscustomobject]@{ cagri = $t.ad; deneme = $i; ms = [int]$sw.ElapsedMilliseconds
                                kod = $kod; hata = $hata }
    Start-Sleep -Milliseconds 700
  }
}

if ($korMu) {
  Write-Host 'KOR: hicbir cagri tamamlanamadi (ag ya da uc nokta erisilemez).'
  Write-Host '  Bu "hata yok" DEMEK DEGIL - olcum YAPILAMADI.'
  exit 0
}

Write-Host ("Olcum: {0} cagri ({1} govde x {2} tekrar) · sure esigi {3} ms" -f `
  $sonuc.Count, $GOVDELER.Count, $TEKRAR, $ESIK)
Write-Host ''
Write-Host ("{0,-22} {1,6} {2,6} {3,6}  {4}" -f 'cagri','en hizli','ortan','en yavas','sonuc')
Write-Host ('-' * 66)

$kotu = @()
foreach ($grup in ($sonuc | Group-Object cagri)) {
  $sr  = @($grup.Group | ForEach-Object { $_.ms } | Sort-Object)
  $hat = @($grup.Group | Where-Object { $_.kod -ne 200 })
  $orta = $sr[[int]($sr.Count / 2)]
  $dur = 'ok'
  if ($hat.Count)          { $dur = "$($hat.Count)/$($grup.Count) HATA"; $kotu += $grup.Group }
  elseif ($sr[-1] -gt $ESIK) { $dur = 'YAVAS'; $kotu += ($grup.Group | Where-Object { $_.ms -gt $ESIK }) }
  Write-Host ("{0,-22} {1,6} {2,6} {3,6}  {4}" -f $grup.Name, $sr[0], $orta, $sr[-1], $dur)
}

if ($kotu.Count) {
  Write-Host ''
  Write-Host 'SORUNLU CAGRILAR:'
  $kotu | ForEach-Object {
    Write-Host ("  [{0}] deneme {1} · {2} ms · HTTP {3}{4}" -f $_.cagri, $_.deneme, $_.ms, $_.kod,
      $(if ($_.hata) { " · $($_.hata)" } else { '' }))
  }
}

$hedef = Join-Path $kok 'veri\alacak-vitrin-saglik.json'
$cikti = [ordered]@{
  olcum    = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama = 'alacak-radari.html acilis cagrisinin saglik olcumu. 30.08 aksami HTTP 500 "statement timeout" alindi, ikinci denemede gecti - kusur ARALIKLI, tek olcum yakalamaz.'
  kaynak   = 'arac/alacak-vitrin-nobeti.ps1'
  tekrar   = $TEKRAR
  esik_ms  = $ESIK
  cagri    = $sonuc.Count
  hatali   = @($sonuc | Where-Object { $_.kod -ne 200 }).Count
  yavas    = @($sonuc | Where-Object { $_.kod -eq 200 -and $_.ms -gt $ESIK }).Count
  en_yavas = ($sonuc | Measure-Object ms -Maximum).Maximum
  kayitlar = @($sonuc | ForEach-Object { [ordered]@{ cagri=$_.cagri; deneme=$_.deneme; ms=$_.ms; kod=$_.kod; hata=$_.hata } })
}
[IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
Write-Host ''
Write-Host ("Rapor: {0}" -f $hedef)

$hatali = $cikti.hatali
if ($hatali -gt 0) {
  Write-Host ''
  Write-Host ("KIRMIZI: {0}/{1} cagri HATA verdi - sayfanin acilis akisi guvenilir degil." -f $hatali, $sonuc.Count)
  Write-Host '  "statement timeout" ise sorgu agirlasmis demektir: arsiv buyudukce'
  Write-Host '  alacak_vitrin her cagride tum dagilimi sayiyor.'
  exit 1
}
if ($cikti.yavas -gt 0) {
  Write-Host ''
  Write-Host ("KIRMIZI: hata yok ama {0} cagri {1} ms esigini asti (en yavas {2} ms)." -f `
    $cikti.yavas, $ESIK, $cikti.en_yavas)
  exit 1
}
Write-Host ''
Write-Host ("YESIL: {0} cagrinin hepsi 200 dondu, en yavasi {1} ms." -f $sonuc.Count, $cikti.en_yavas)
exit 0
