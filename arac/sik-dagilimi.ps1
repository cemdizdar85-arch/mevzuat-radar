#requires -Version 5.1
# ASCII-only (PS 5.1 BOM trap).
# SIK DAGILIMI - "bu soruyu cozenlerin %X'i su sikki secti" cumlesinin TEK kaynagi (24.09.2026, Cem "1.2.3 ucunu de yap").
# Amac: pazarlama videosunda "en cok denen bu" gibi OLCULMEMIS iddia yerine gercek oran. Bedel 0 (yalniz okuma).
#
# KAYNAKLAR
#   1) cevap_kayit (Supabase)  : seviye-testi.html + kaydir/* her cevapta 1 satir; secim = ASIL harf (ekran karisikligi cozulmus).
#   2) canli_sonuc.cevaplar    : canli-deneme.html, kisi basi 1 satir, paket sirasiyla 'A-E' / '-' dizisi.
#      Paket sifreli (.enc.json) -> sira->soru_id icin SIFRESIZ paket yolu -CanliPaket ile verilir. Verilmezse bu kaynak KOR.
# KARAR: soru basina gecerli cevap sayisi n >= -AltSinir ise KULLANILIR, degilse AZ VERI (videoda yuzde soylenmez).
#
# BU ARAC SUNLARI GORMEZ (yazili korluk):
#   - Prova/test satirlarini gercek adaydan AYIRAMAZ. Site acilmadan onceki satirlar buyuk olasilikla prova -> -Baslangic ile disla.
#   - seviye-testi.html "Bilmiyorum" cevabini secim=null gonderir; tablo secim NOT NULL -> o satirlar hic yazilmiyor (24.09 okundu).
#     Yani oran "sik secenler" icindedir; "bilmiyorum" diyenleri icermez.
#   - Ayni kisinin ayni soruyu tekrar cozmesini tekillestirmez (oturum alani var ama cihaz degisirse ayri sayilir).
#   - canli_sonuc.cevaplar sutunu basilmadiysa (2026-09-24-canli-sonuc-cevaplar.sql) canli kaynak bos doner -> KOR yazar.
#
# Kullanim:
#   powershell -NoProfile -File arac/sik-dagilimi.ps1                         # tum sorular, esik 50
#   powershell -NoProfile -File arac/sik-dagilimi.ps1 -SoruId 'sgs-t1-meslek-kolay/kp-01' -Baslangic 2026-10-01
#   powershell -NoProfile -File arac/sik-dagilimi.ps1 -CanliKod SGS-0410 -CanliPaket <sifresiz paket.json>
#   powershell -NoProfile -File arac/sik-dagilimi.ps1 -Sinav                  # oz-sinav (ag yok). Mutasyon: $env:SD_MUTASYON=esik|yuzde|gecersiz|canli
param(
  [string]$SoruId = '',
  [int]$AltSinir = 50,
  [string]$Baslangic = '',
  [string]$CanliKod = '',
  [string]$CanliPaket = '',
  [switch]$Sinav
)
$ErrorActionPreference = 'Stop'
$mutasyonAdi = "$($env:SD_MUTASYON)"

function Get-SikSayim {
  # $kayitlar: @{ soru_id; secim; dogru } listesi. Donus: soru_id -> ozet.
  param($kayitlar, [int]$sinirDegeri)
  $tablo = @{}
  foreach ($k in $kayitlar) {
    $sid = "$($k.soru_id)"
    if (-not $tablo.ContainsKey($sid)) {
      $tablo[$sid] = [ordered]@{ soru_id = $sid; A = 0; B = 0; C = 0; D = 0; E = 0; n = 0; gecersiz = 0; dogru = '' }
    }
    $oz = $tablo[$sid]
    if ($k.dogru -and -not $oz.dogru) { $oz.dogru = "$($k.dogru)" }
    $harf = "$($k.secim)".Trim().ToUpper()
    $gecerliMi = $harf -match '^[A-E]$'
    if ($mutasyonAdi -eq 'gecersiz') { $gecerliMi = $true; if (-not ($harf -match '^[A-E]$')) { $harf = 'A' } }
    if ($gecerliMi) { $oz[$harf] = $oz[$harf] + 1; $oz.n = $oz.n + 1 } else { $oz.gecersiz = $oz.gecersiz + 1 }
  }
  foreach ($oz in $tablo.Values) {
    $payda = if ($mutasyonAdi -eq 'yuzde') { [math]::Max(1, $oz.n + $oz.gecersiz + 1) } else { [math]::Max(1, $oz.n) }
    $yuzdeler = [ordered]@{}
    foreach ($h in 'A','B','C','D','E') { $yuzdeler[$h] = [math]::Round(100.0 * $oz[$h] / $payda) }
    $oz.yuzde = $yuzdeler
    $enYanlis = ''; $enYanlisSayi = -1
    foreach ($h in 'A','B','C','D','E') { if ($h -ne $oz.dogru -and $oz[$h] -gt $enYanlisSayi) { $enYanlis = $h; $enYanlisSayi = $oz[$h] } }
    $oz.en_cok_yanlis = $enYanlis
    $yeterli = $oz.n -ge $sinirDegeri
    if ($mutasyonAdi -eq 'esik') { $yeterli = $true }
    $oz.karar = if ($yeterli) { 'KULLANILIR' } else { 'AZ VERI' }
  }
  return $tablo
}

function Split-CanliDizi {
  # canli_sonuc.cevaplar dizisini paket sirasiyla soru satirina acar. '-' = bos (gecersiz sayilir).
  param([string]$cevapDizisi, $paketSoruIdleri)
  $satirlar = New-Object System.Collections.ArrayList
  if (-not $cevapDizisi) { return ,$satirlar }
  $adet = [math]::Min($cevapDizisi.Length, @($paketSoruIdleri).Count)
  for ($i = 0; $i -lt $adet; $i++) {
    $harfCanli = $cevapDizisi.Substring($i, 1)
    if ($mutasyonAdi -eq 'canli') { $harfCanli = $cevapDizisi.Substring([math]::Min($i + 1, $cevapDizisi.Length - 1), 1) }
    [void]$satirlar.Add(@{ soru_id = $paketSoruIdleri[$i].id; secim = $harfCanli; dogru = $paketSoruIdleri[$i].dogru })
  }
  return ,$satirlar
}

if ($Sinav) {
  $hatalar = New-Object System.Collections.ArrayList
  $vakalar = New-Object System.Collections.ArrayList
  # V1: yuzde + en cok secilen yanlis
  foreach ($x in 1..6) { [void]$vakalar.Add(@{ soru_id = 'q1'; secim = 'C'; dogru = 'E' }) }
  foreach ($x in 1..3) { [void]$vakalar.Add(@{ soru_id = 'q1'; secim = 'E'; dogru = 'E' }) }
  [void]$vakalar.Add(@{ soru_id = 'q1'; secim = 'A'; dogru = 'E' })
  # V2: gecersiz secim (null/bos/'-'/'X') n'e girmez
  foreach ($bozuk in @($null, '', '-', 'X')) { [void]$vakalar.Add(@{ soru_id = 'q1'; secim = $bozuk; dogru = 'E' }) }
  # V3: esik tam sinirda (n=10 -> esik 10 KULLANILIR), altinda AZ VERI
  foreach ($x in 1..9) { [void]$vakalar.Add(@{ soru_id = 'q2'; secim = 'B'; dogru = 'B' }) }
  $sonuc = Get-SikSayim -kayitlar $vakalar -sinirDegeri 10
  $q1 = $sonuc['q1']; $q2 = $sonuc['q2']
  if ($q1.n -ne 10) { [void]$hatalar.Add("V2 gecersiz secim n'e girdi: n=$($q1.n) (beklenen 10)") }
  if ($q1.gecersiz -ne 4) { [void]$hatalar.Add("V2 gecersiz sayisi $($q1.gecersiz) (beklenen 4)") }
  if ($q1.yuzde.C -ne 60 -or $q1.yuzde.E -ne 30) { [void]$hatalar.Add("V1 yuzde yanlis: C=$($q1.yuzde.C) E=$($q1.yuzde.E) (beklenen 60/30)") }
  if ($q1.en_cok_yanlis -ne 'C') { [void]$hatalar.Add("V1 en cok yanlis $($q1.en_cok_yanlis) (beklenen C)") }
  if ($q1.karar -ne 'KULLANILIR') { [void]$hatalar.Add("V3 n=10 esik=10 -> KULLANILIR olmali, $($q1.karar)") }
  if ($q2.karar -ne 'AZ VERI') { [void]$hatalar.Add("V3 n=9 esik=10 -> AZ VERI olmali, $($q2.karar)") }
  # V4: canli dizi paket sirasiyla acilir, '-' bos
  $paket = @(@{ id = 'p1'; dogru = 'A' }, @{ id = 'p2'; dogru = 'B' }, @{ id = 'p3'; dogru = 'C' })
  $acik = Split-CanliDizi -cevapDizisi 'C-A' -paketSoruIdleri $paket
  $canliSonuc = Get-SikSayim -kayitlar $acik -sinirDegeri 1
  if ($canliSonuc['p1'].C -ne 1 -or $canliSonuc['p2'].n -ne 0 -or $canliSonuc['p3'].A -ne 1) {
    [void]$hatalar.Add("V4 canli dizi yanlis acildi: p1.C=$($canliSonuc['p1'].C) p2.n=$($canliSonuc['p2'].n) p3.A=$($canliSonuc['p3'].A)")
  }
  $mutasyonYazi = if ($mutasyonAdi) { " (MUTASYON: $mutasyonAdi)" } else { '' }
  if ($hatalar.Count -gt 0) { Write-Host "OZ-SINAV DUSTU$mutasyonYazi"; $hatalar | ForEach-Object { Write-Host "  - $_" }; exit 1 }
  Write-Host "OZ-SINAV TEMIZ: 4 vaka (yuzde, gecersiz secim, esik siniri, canli dizi)$mutasyonYazi"; exit 0
}

# ---------------- canli okuma ----------------
$servisAnahtari = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim()
if (-not $servisAnahtari) { $servisAnahtari = "$($env:SUPABASE_SERVICE_KEY)".Trim() }
if (-not $servisAnahtari) { throw 'SUPABASE_SERVICE_KEY yok.' }
$sbKok = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$sbBaslik = @{ apikey = $servisAnahtari; Authorization = "Bearer $servisAnahtari"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }

$tumKayit = New-Object System.Collections.ArrayList
$filtre = ''
if ($SoruId)    { $filtre += '&soru_id=in.(' + (($SoruId -split ',' | ForEach-Object { '"' + $_.Trim() + '"' }) -join ',') + ')' }
if ($Baslangic) { $filtre += '&olusturma=gte.' + $Baslangic }
$sayfaBoyu = 1000; $atla = 0
do {
  $adres = "$sbKok/cevap_kayit?select=id,soru_id,secim,dogru,kaynak&order=id.asc&limit=$sayfaBoyu&offset=$atla$filtre"
  # PS 5.1: @(Invoke-RestMethod ...) JSON dizisini TEK eleman sarar (24.09 olculdu: 95 satir -> 1). Boru acar.
  $sayfa = @(Invoke-RestMethod -Uri $adres -Headers $sbBaslik | ForEach-Object { $_ })
  foreach ($s in $sayfa) { [void]$tumKayit.Add($s) }
  $atla += $sayfaBoyu
} while ($sayfa.Count -eq $sayfaBoyu)
$kaynakOzeti = ($tumKayit | Group-Object kaynak | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' '
Write-Host ("KAPSAM cevap_kayit: alinan $($tumKayit.Count) satir [$kaynakOzeti]" + $(if ($Baslangic) { " (>= $Baslangic)" } else { ' (TUM ZAMAN - prova satirlari dahil olabilir, -Baslangic ver)' }))

if ($CanliKod) {
  if (-not $CanliPaket -or -not (Test-Path $CanliPaket)) {
    Write-Host "KAPSAM canli_sonuc: KOR - $CanliKod icin sifresiz paket (-CanliPaket) verilmedi; sira->soru_id cevrilemez."
  } else {
    $paketIcerik = [IO.File]::ReadAllText($CanliPaket, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $paketSorulari = @($paketIcerik.sorular | ForEach-Object { @{ id = $_.id; dogru = $_.dogru } })
    try {
      $canliSatirlar = @(Invoke-RestMethod -Uri "$sbKok/canli_sonuc?select=cevaplar&oturum=eq.$CanliKod&cevaplar=not.is.null&limit=20000" -Headers $sbBaslik | ForEach-Object { $_ })
      $canliAcilan = 0
      foreach ($cs in $canliSatirlar) { $parca = Split-CanliDizi -cevapDizisi "$($cs.cevaplar)" -paketSoruIdleri $paketSorulari; foreach ($p in $parca) { [void]$tumKayit.Add($p); $canliAcilan++ } }
      Write-Host "KAPSAM canli_sonuc: $CanliKod - $($canliSatirlar.Count) kisi, $canliAcilan cevap satiri acildi (paket $($paketSorulari.Count) soru)"
    } catch {
      Write-Host "KAPSAM canli_sonuc: KOR - okunamadi ($($_.Exception.Message)); cevaplar sutunu basilmamis olabilir."
    }
  }
} else {
  Write-Host 'KAPSAM canli_sonuc: bakilmadi (-CanliKod verilmedi)'
}

$ozet = Get-SikSayim -kayitlar $tumKayit -sinirDegeri $AltSinir
$sirali = @($ozet.Values | Sort-Object -Property @{ Expression = { $_.n }; Descending = $true })
$kullanilir = @($sirali | Where-Object { $_.karar -eq 'KULLANILIR' }).Count
foreach ($oz in $sirali) {
  $satir = ($('A','B','C','D','E') | ForEach-Object { $isaret = if ($_ -eq $oz.dogru) { '*' } else { '' }; "$_$isaret %$($oz.yuzde[$_])" }) -join '  '
  Write-Host ("[{0}] {1}  n={2} gecersiz={3}  dogru={4}" -f $oz.karar, $oz.soru_id, $oz.n, $oz.gecersiz, $oz.dogru)
  Write-Host ("    $satir")
  if ($oz.karar -eq 'KULLANILIR' -and $oz.en_cok_yanlis) {
    Write-Host ("    video: `"Bu soruyu cozenlerin %{0}'i {1} dedi.`" (n={2})" -f $oz.yuzde[$oz.en_cok_yanlis], $oz.en_cok_yanlis, $oz.n)
  }
}
Write-Host ("SONUC: {0} soru, {1} KULLANILIR (n >= {2}), {3} AZ VERI" -f $sirali.Count, $kullanilir, $AltSinir, ($sirali.Count - $kullanilir))
