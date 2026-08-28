# ============================================================================
#  ALACAK ILANI OKUYUCU - PILOT  (29.08.2026)
#
#  CEM'IN TESHISI (28.08 gecesi): "bu yazanlari tek tek okusak daha dogru karar
#  vermez miyiz - boyle parcali parcali bakiyorsun ve olmuyor."
#  HAKLI VE KANITI VAR: o gun regex hatti ALTI kez curudu, altisi da ayni
#  kokten - ilanin ANLAMINI kelime kalibindan cikarmaya calismak.
#    "kaldirilmasi + iflas"  -> iki ZIT olayi birden esledi
#    "reddini isteyebilecek" -> muhlet ilanini ret sandi (20.08'de de ayni)
#    Bursa yaziyor, Istanbul yazmiyor -> ayni olay iki ayri kovada
#  Bir insan bu basliklari okusa bir saniyede ayirir.
#
#  BU BETIK NE YAPAR: 4 tartismali kovadan ornek ilan alir, MODELE OKUTUR ve
#  regex damgasiyla KARSILASTIRIR. Amac etiketlemek degil, "okuma regex'ten
#  iyi mi, ne kadar iyi" sorusunu OLCMEK. Iyi cikarsa yon degisir; kotu
#  cikarsa bunu da olcmus oluruz ve regex'e serhle devam ederiz.
#
#  UC TASARIM KARARI:
#   1) DAR SORU. "Etiketle" demiyoruz; 6 secenekli tek soru soruyoruz.
#   2) ZORUNLU ALINTI. Model kararin gectigi cumleyi AYNEN yazmali. Kaynagini
#      gosteremeyen cevap SAYILMAZ - regex'i de ayni sinavdan gecirdik.
#   3) KISISEL VERI MASKESI. Ilan metni TCKN icerir. Dis servise gitmeden ONCE
#      11 haneli sayilar maskelenir. Bkz [[guvenlik-17-07-2026]]
#
#  HAT: once GEMINI (bedava kota, 0 maliyet) -> hata/kota olursa HAIKU.
#  Boylece pilot ANTHROPIC TAVANINA dokunmadan kosar (bkz api-tavan-engeli).
#
#  Env: SUPABASE_SERVICE_KEY (sart) · GEMINI_API_KEY ve/veya ANTHROPIC_API_KEY
#  Ayar: ADET (varsayilan 100)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$URL  = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'https://bjrleanjpyujtajmazxn.supabase.co' }
$KEY  = $env:SUPABASE_SERVICE_KEY
$ADET = if ($env:ADET) { [int]$env:ADET } else { 100 }

if (-not $KEY) { Write-Host "KOR: SUPABASE_SERVICE_KEY yok - pilot KOSULAMADI (sifir sonuc degil)."; exit 0 }
if (-not $env:GEMINI_API_KEY -and -not $env:ANTHROPIC_API_KEY) {
  Write-Host "KOR: ne GEMINI_API_KEY ne ANTHROPIC_API_KEY var - okuma hatti yok."; exit 0
}

# --- 4 tartismali kovadan dengeli ornek ------------------------------------
$KOVALAR = @('ret_kaldirma','ret_iflas','tasdik','iflas_kaldirma')
$perKova = [Math]::Max(1, [int]($ADET / $KOVALAR.Count))
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')

$ilanlar = @()
foreach ($k in $KOVALAR) {
  $u = "$URL/rest/v1/alacak_ilan?select=ilan_no,baslik,il,tur,karar_durumu,metin,tarih" +
       "&tarih=gte.$bas&karar_durumu=eq.$k&metin=not.is.null&order=tarih.desc&limit=$perKova"
  try { $ilanlar += @(Invoke-RestMethod -Method Get -Uri $u -Headers $H -TimeoutSec 90) }
  catch { Write-Host ("  '{0}' kovasi cekilemedi: {1}" -f $k, $_.Exception.Message) }
}
if (-not $ilanlar.Count) { Write-Host "KOR: 0 ilan cekildi - olcum guvenilmez."; exit 0 }
Write-Host ("Orneklem: {0} ilan ({1} kova)" -f $ilanlar.Count, $KOVALAR.Count)

# --- KISISEL VERI MASKESI (dis servise gitmeden once) -----------------------
# 11 haneli sayi = TCKN adayi. VKN 10 hanedir, o KALIR (tuzel kisi, kamuya acik).
function Maskele([string]$m) {
  if (-not $m) { return '' }
  $m = [regex]::Replace($m, '(?<!\d)\d{11}(?!\d)', '[TCKN]')
  if ($m.Length -gt 6000) { $m = $m.Substring(0, 6000) }   # jeton freni
  return $m
}

$SORU = @'
Asagida Turkiye'de bir mahkeme/daire tarafindan yayimlanmis resmi ilanin metni var.
TEK SORU: Bu ilanda mahkeme NE KARAR VERDI?

Secenekler:
a) Konkordato muhleti verdi (gecici, kesin ya da uzatma)
b) Konkordato talebini REDDETTI - iflas karari YOK
c) Konkordato talebini reddetti VE borclunun IFLASINA karar verdi
d) Daha once verilmis IFLASI KALDIRDI (borclu iflastan cikiyor)
e) Konkordatoyu TASDIK etti
f) Yukaridakilerden hicbiri

Yalniz su iki satiri yaz, baska hicbir sey yazma:
KARAR: <tek harf>
ALINTI: <karari gecen cumleyi metinden AYNEN kopyala; bulamazsan YOK yaz>

--- ILAN BASLIGI ---
{BASLIK}
--- ILAN METNI ---
{METIN}
'@

$script:gkey = $env:GEMINI_API_KEY
$script:sayacGemini = 0; $script:sayacHaiku = 0; $script:sayacHata = 0

function Sor([string]$istem) {
  if ($script:gkey) {
    try {
      $b = @{ contents = @(@{ parts = @(@{ text = $istem }) }) } | ConvertTo-Json -Depth 8 -Compress
      $r = Invoke-RestMethod -Method Post -TimeoutSec 90 `
           -Uri ("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + $script:gkey) `
           -Body ([Text.Encoding]::UTF8.GetBytes($b)) -ContentType 'application/json'
      $script:sayacGemini++
      return (@($r.candidates[0].content.parts) | ForEach-Object { $_.text }) -join ''
    } catch {
      if ("$($_.Exception.Message)" -match '429|quota|RESOURCE_EXHAUSTED|Too Many') {
        $script:gkey = $null; Write-Host "  Gemini kotasi doldu -> Haiku'ya donuluyor."
      }
    }
  }
  if ($env:ANTHROPIC_API_KEY) {
    try {
      $AH = @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' }
      $b = @{ model = 'claude-haiku-4-5-20251001'; max_tokens = 300
              messages = @(@{ role = 'user'; content = $istem }) } | ConvertTo-Json -Depth 6 -Compress
      $r = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $AH `
           -Body ([Text.Encoding]::UTF8.GetBytes($b)) -ContentType 'application/json' -TimeoutSec 90
      $script:sayacHaiku++
      return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ''
    } catch { $script:sayacHata++ }
  }
  return $null
}

# Regex damgasi ile okuma cevabinin KARSILIGI
$ESLESME = @{ 'a' = @('gecici_muhlet','kesin_muhlet','uzatma','muhlet')
              'b' = @('ret_kaldirma'); 'c' = @('ret_iflas')
              'd' = @('iflas_kaldirma'); 'e' = @('tasdik') }

$sonuc = @(); $uyum = 0; $uyumsuz = 0; $alintisiz = 0; $cevapsiz = 0
$i = 0
foreach ($x in $ilanlar) {
  $i++
  $istem = $SORU.Replace('{BASLIK}', "$($x.baslik)").Replace('{METIN}', (Maskele "$($x.metin)"))
  $c = Sor $istem
  if (-not $c) { $cevapsiz++; continue }
  $harf = ''; $alinti = ''
  if ($c -match '(?im)^\s*KARAR\s*:\s*\(?([a-f])') { $harf = $Matches[1].ToLower() }
  if ($c -match '(?im)^\s*ALINTI\s*:\s*(.+)$')     { $alinti = $Matches[1].Trim() }
  if (-not $harf) { $cevapsiz++; continue }
  if (-not $alinti -or $alinti -match '^\s*YOK\s*$') { $alintisiz++ }

  $beklenen = $ESLESME[$harf]
  $tutuyor = ($beklenen -and ($beklenen -contains "$($x.karar_durumu)"))
  if ($tutuyor) { $uyum++ } else { $uyumsuz++ }

  $sonuc += [pscustomobject]@{
    ilan_no = $x.ilan_no; tarih = $x.tarih; il = $x.il
    baslik = "$($x.baslik)"; regex_damgasi = "$($x.karar_durumu)"
    okuma_karari = $harf; okuma_alintisi = $alinti; uyuyor = $tutuyor
  }
  if ($i % 10 -eq 0) { Write-Host ("  {0}/{1} okundu (uyum {2} · uyumsuz {3})" -f $i, $ilanlar.Count, $uyum, $uyumsuz) }
  Start-Sleep -Milliseconds 350
}

$hedef = Join-Path $kok 'veri\alacak-okuma-pilot.json'
$cikti = [ordered]@{
  olcum      = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  orneklem   = $ilanlar.Count
  okunan     = $sonuc.Count
  uyum       = $uyum
  uyumsuz    = $uyumsuz
  alintisiz  = $alintisiz
  cevapsiz   = $cevapsiz
  hat        = @{ gemini = $script:sayacGemini; haiku = $script:sayacHaiku; hata = $script:sayacHata }
  kayitlar   = $sonuc
}
[IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))

Write-Host ''
Write-Host ('=' * 72)
if ($sonuc.Count) {
  Write-Host ("OKUNAN: {0} · UYUM: {1} (%{2:N1}) · UYUMSUZ: {3} · alintisiz: {4} · cevapsiz: {5}" -f `
    $sonuc.Count, $uyum, (100.0 * $uyum / $sonuc.Count), $uyumsuz, $alintisiz, $cevapsiz)
  Write-Host ("HAT: gemini {0} · haiku {1} · hata {2}" -f $script:sayacGemini, $script:sayacHaiku, $script:sayacHata)
  Write-Host ''
  Write-Host 'KOVA BAZLI UYUM:'
  $sonuc | Group-Object regex_damgasi | Sort-Object Name | ForEach-Object {
    $t = @($_.Group | Where-Object { $_.uyuyor }).Count
    Write-Host ("  {0,-16} {1,3}/{2,-3} (%{3:N0})" -f $_.Name, $t, $_.Count, (100.0 * $t / $_.Count))
  }
  Write-Host ''
  Write-Host 'ILK 10 UYUSMAZLIK (ELLE BAKILACAK - hangisi hakli, regex mi okuma mi?):'
  $sonuc | Where-Object { -not $_.uyuyor } | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  [{0}] regex={1} · okuma={2}" -f $_.il, $_.regex_damgasi, $_.okuma_karari)
    Write-Host ("     baslik : {0}" -f $_.baslik.Substring(0, [Math]::Min(66, $_.baslik.Length)))
    Write-Host ("     alinti : {0}" -f $(if ($_.okuma_alintisi) { $_.okuma_alintisi.Substring(0, [Math]::Min(90, $_.okuma_alintisi.Length)) } else { '-' }))
  }
} else {
  Write-Host 'KOR: hicbir ilan okunamadi.'
}
Write-Host ''
Write-Host ("Rapor: {0}" -f $hedef)
Write-Host 'UYARI: uyumsuzluk "okuma yanildi" DEMEK DEGILDIR. 28.08''de regex alti kez'
Write-Host 'yanildi. Her uyusmazliga ELLE bakilir; hangisinin hakli oldugu ORADA belli olur.'
