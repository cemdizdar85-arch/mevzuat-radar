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
# 29.08 OLCULDU: 4 kovada metinli ilan 746, ortalama 1.227 karakter, toplam
# 916 bin karakter (~305 bin token girdi). Gemini bedava kotasiyla 0 TL, Haiku'ya
# duserse 1 dolardan az. Yani MALIYET KARAR VERICI DEGIL - orneklemi kucuk
# tutmanin bir sebebi yok. HEPSI=1 ile 4 kovanin TAMAMI okunur.
$KOVALAR = @('ret_kaldirma','ret_iflas','tasdik','iflas_kaldirma')
$perKova = if ($env:HEPSI -eq '1') { 1000 } else { [Math]::Max(1, [int]($ADET / $KOVALAR.Count)) }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')

$ilanlar = @()
foreach ($k in $KOVALAR) {
  $u = "$URL/rest/v1/alacak_ilan?select=ilan_no,baslik,il,tur,karar_durumu,metin,tarih" +
       "&tarih=gte.$bas&karar_durumu=eq.$k&metin=not.is.null&order=tarih.desc&limit=$perKova"
  # 29.08 KUSUR: burada Invoke-RestMethod kullaniliyordu ve donen JSON dizisi
  # DUZLESMIYORDU - her kova TEK nesneye sarilip alanlari dizi oluyordu
  # ("Orneklem: 4 ilan", regex_damgasi = 644 elemanli dizi). Sonuc: modele 644
  # ilanin metni BIRLESIK gitti ve karsilastirma dizi-ile-metin kiyasi yapip
  # uyumu %0 gosterdi. Invoke-WebRequest + ConvertFrom-Json + @() ile garanti
  # altina alindi; ayrica kova basina KAC satir geldigi BASILIR (sessiz
  # kucultme bir daha fark edilmeden gecmesin).
  try {
    $ham  = Invoke-WebRequest -Method Get -Uri $u -Headers $H -TimeoutSec 90
    $rows = @($ham.Content | ConvertFrom-Json)
    foreach ($row in $rows) { $ilanlar += $row }
    Write-Host ("  {0,-16} {1,4} ilan" -f $k, $rows.Count)
  }
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
a) Konkordato MUHLETI VERDI (gecici, kesin ya da uzatma)
b) Konkordato talebini REDDETTI - iflas karari YOK
c) Konkordato talebini reddetti VE borclunun IFLASINA karar verdi
   (IIK m.292 ile kesin muhlet icinde iflasin acilmasi da buraya girer)
d) Daha once verilmis IFLASI KALDIRDI - borclu iflastan CIKIYOR (IIK m.182)
e) Konkordatoyu TASDIK etti (basarili sonuclandi)
g) Konkordato MUHLETINI kaldirdi / sonlandirdi - ret de iflas da tasdik de DEGIL
f) Yukaridakilerden hicbiri

DIKKAT - en sik karistirilan ayrim: konkordato MUHLETININ kaldirilmasi (g),
IFLASIN kaldirilmasi (d) DEGILDIR. Muhlet konkordato surecine aittir, iflas
ayri bir hukumdur. Muhlet kaldirilmasinin SEBEBI tasdik ise cevap (e)'dir.

Yalniz su iki satiri yaz, baska hicbir sey yazma:
KARAR: <tek harf>
ALINTI: <karari gecen cumleyi metinden AYNEN kopyala>

ALINTI ZORUNLUDUR. Metinde karari acikca soyleyen bir cumle BULAMIYORSAN
karar harfi olarak (f) yaz ve ALINTI satirina YOK yaz. Kararini metne
dayandiramadigin bir harf SECME.

--- ILAN BASLIGI ---
{BASLIK}
--- ILAN METNI ---
{METIN}
'@

$script:gkey = $env:GEMINI_API_KEY
$script:sayacGemini = 0; $script:sayacHaiku = 0; $script:sayacHata = 0
$script:geminiSebep = $(if ($env:GEMINI_API_KEY) { '' } else { 'GEMINI_API_KEY tanimli degil' })

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
      # 29.08 KUSUR: eski kod YALNIZ 429'da mesaj basiyordu; baska hatada Gemini
      # SESSIZCE dusuyordu. Ilk kosuda "gemini 0 · haiku 746" cikti ve NEDEN
      # oldugunu bilemedik - kendi kor kalma kuralimi kendi betigimde ihlal
      # etmisim. Artik hata NE OLURSA OLSUN bir kez ACIKCA basilir ve sebebi
      # ozette de tekrarlanir.
      $m = "$($_.Exception.Message)"
      $script:geminiSebep = $m.Substring(0, [Math]::Min(160, $m.Length))
      Write-Host ("  GEMINI DUSTU -> Haiku'ya donuluyor. Sebep: {0}" -f $script:geminiSebep)
      $script:gkey = $null   # 746 kez bosuna denemeyiz
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
              'd' = @('iflas_kaldirma'); 'e' = @('tasdik')
              # 29.08: (g) muhletin kaldirilmasi. Ilk kosuda okuma bunu UC KEZ
              # (d) iflasin kaldirilmasi sandi - iki ayri hukum. Kendi secenegi
              # verildi; regex tarafinda ikisi de ret_kaldirma kovasinda durur.
              'g' = @('ret_kaldirma') }

$sonuc = @(); $uyum = 0; $uyumsuz = 0; $alintisiz = 0; $cevapsiz = 0
$i = 0
foreach ($x in $ilanlar) {
  $i++
  $istem = $SORU.Replace('{BASLIK}', "$($x.baslik)").Replace('{METIN}', (Maskele "$($x.metin)"))
  $c = Sor $istem
  if (-not $c) { $cevapsiz++; continue }
  $harf = ''; $alinti = ''
  if ($c -match '(?im)^\s*KARAR\s*:\s*\(?([a-g])') { $harf = $Matches[1].ToLower() }
  if ($c -match '(?im)^\s*ALINTI\s*:\s*(.+)$')     { $alinti = $Matches[1].Trim() }
  if (-not $harf) { $cevapsiz++; continue }
  # 29.08 ASIL KUSUR: "alinti zorunlu" dedim ama ZORLAMADIM - ilk kosuda 290/746
  # (%39) cevap alintisiz geldi ve ben onlari yine de uyum oranina KATTIM.
  # Yani %72,8 olculmus bir sayi degildi. Artik alintisiz cevap AYRI tutulur ve
  # OLCULEBILIR UYUM yalniz alintililardan hesaplanir. Kaynagini gosteremeyen
  # cevap sayilmaz - regex'e uyguladigim kurali okumaya da uyguluyorum.
  $alintiVar = [bool]($alinti -and $alinti -notmatch '^\s*YOK\s*\.?\s*$' -and $alinti.Length -ge 12)
  if (-not $alintiVar) { $alintisiz++ }

  # ÖZ-SINAV (29.08 kusurundan sonra eklendi): karsilastirilan sey TEK bir damga
  # olmali. Dizi geldiyse cekim bozulmus demektir - sessizce %0 uyum uretmek
  # yerine ACIKCA durup soyler. "Supheli sifiri guvenilir sifira cevirme" kurali.
  $damga = "$($x.karar_durumu)"
  if ($damga -match '\s') {
    Write-Host "HATA: karar_durumu tek deger degil, DIZI geldi - cekim bozuk, olcum durduruldu."
    Write-Host ("  ornek: {0}" -f $damga.Substring(0, [Math]::Min(60, $damga.Length)))
    exit 1
  }
  $beklenen = $ESLESME[$harf]
  $tutuyor = ($beklenen -and ($beklenen -contains $damga))
  if ($tutuyor) { $uyum++ } else { $uyumsuz++ }

  $sonuc += [pscustomobject]@{
    ilan_no = $x.ilan_no; tarih = $x.tarih; il = $x.il
    baslik = "$($x.baslik)"; regex_damgasi = $damga
    okuma_karari = $harf; okuma_alintisi = $alinti; alinti_var = $alintiVar; uyuyor = $tutuyor
  }
  if ($i % 10 -eq 0) { Write-Host ("  {0}/{1} okundu (uyum {2} · uyumsuz {3})" -f $i, $ilanlar.Count, $uyum, $uyumsuz) }
  Start-Sleep -Milliseconds 350
}

$hedef = Join-Path $kok 'veri\alacak-okuma-pilot.json'
$cikti = [ordered]@{
  olcum      = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  orneklem   = $ilanlar.Count
  okunan     = $sonuc.Count
  uyum_ham          = $uyum
  alintili_adet     = @($sonuc | Where-Object { $_.alinti_var }).Count
  uyum_olculebilir  = @($sonuc | Where-Object { $_.alinti_var -and $_.uyuyor }).Count
  gemini_sebep      = $script:geminiSebep
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
  # OLCULEBILIR UYUM = yalniz ALINTILI cevaplar. Alintisiz cevap "okuma bildi"
  # sayilmaz; kaynagini gosteremeyen cevap olcume girmez.
  $alintili     = @($sonuc | Where-Object { $_.alinti_var })
  $uyumAlintili = @($alintili | Where-Object { $_.uyuyor }).Count
  Write-Host ("OKUNAN: {0} · cevapsiz: {1}" -f $sonuc.Count, $cevapsiz)
  Write-Host ("HAM UYUM (alintisizlar dahil - GUVENILMEZ): {0}/{1} (%{2:N1})" -f `
    $uyum, $sonuc.Count, (100.0 * $uyum / $sonuc.Count))
  if ($alintili.Count) {
    Write-Host ("OLCULEBILIR UYUM (yalniz alintili): {0}/{1} (%{2:N1})  <-- KARAR BU SAYIYA GORE VERILIR" -f `
      $uyumAlintili, $alintili.Count, (100.0 * $uyumAlintili / $alintili.Count))
  } else {
    Write-Host 'OLCULEBILIR UYUM: KOR - hicbir cevap alinti tasimiyor, olcum yapilamaz.'
  }
  Write-Host ("ALINTISIZ (olcume GIRMEDI): {0} (%{1:N1})" -f $alintisiz, (100.0 * $alintisiz / $sonuc.Count))
  Write-Host ("HAT: gemini {0} · haiku {1} · hata {2}{3}" -f $script:sayacGemini, $script:sayacHaiku, $script:sayacHata,
    $(if ($script:geminiSebep) { " · GEMINI KULLANILMADI: $($script:geminiSebep)" } else { '' }))
  Write-Host ''
  Write-Host 'KOVA BAZLI OLCULEBILIR UYUM (alintili cevaplar):'
  $alintili | Group-Object regex_damgasi | Sort-Object Name | ForEach-Object {
    $t = @($_.Group | Where-Object { $_.uyuyor }).Count
    Write-Host ("  {0,-16} {1,3}/{2,-3} (%{3:N0})" -f $_.Name, $t, $_.Count, (100.0 * $t / $_.Count))
  }
  Write-Host ''
  Write-Host 'ILK 12 UYUSMAZLIK - YALNIZ ALINTILI (ELLE BAKILACAK: regex mi okuma mi hakli?):'
  $alintili | Where-Object { -not $_.uyuyor } | Select-Object -First 12 | ForEach-Object {
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
