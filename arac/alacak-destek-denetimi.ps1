# ============================================================================
#  ALACAK DAMGA DESTEK DENETİMİ — "alıntı, damgayı gerçekten söylüyor mu?"
#
#  NEDEN VAR (30.08.2026): 29.08 yazma turunda destek kapısı YOKTU; yazılan
#  906 damganın bir kısmında alıntı kendi etiketini desteklemiyordu. En ağırı:
#  alıntı "konkordato isteminin REDDİNE" diyor, damga ret_iflas — metinde
#  iflas YOK. O damga yazıldı ve sitede "ret + iflas" olarak duruyor.
#  Alacaklı için bu TERS bilgi: firma iflas etmiş sanılıyor.
#
#  Kapı sonradan okuyucuya eklendi (motor/alacak-ilan-okuyucu-pilot.ps1,
#  AlintiDestekliyorMu) ve BUNDAN SONRASINI engelliyor. Ama CANLIDA DURAN
#  bozuk kayıtlar kendiliğinden düzelmiyor — bu betik onları listeler.
#
#  ⚠ RAPORDAKİ `alinti_karari_destekliyor` ALANINA GÜVENİLMEZ.
#  Ölçüldü: veri/alacak-supheli-damga.json'da 456 kaydın 456'sı "desteklemiyor"
#  diyor — oysa içlerinde alıntısı açıkça "İFLASINA" diyen kayıtlar var.
#  Sebep betikte de yazılı: PowerShell'in -match'i IgnoreCase için
#  CurrentCulture kullanır; tr-TR'de "İFLASINA" ile 'iflas' EŞLEŞMEZ (İ ile i
#  ayrı harftir). Rapor, Katla() düzeltmesinden ÖNCE üretilmiş. Bu betik
#  hesabı Katla() ile YENİDEN yapar.
#
#  ÇIKTI: veri/alacak-destek-denetimi.json + ekrana virgüllü ilan_no listesi.
#  O liste doğrudan okuma-pilotu.yml'nin `ilanlar` girdisine yapıştırılır;
#  yalnız o ilanlar yeniden okunur (tüm kovayı okumaya gerek yok).
#
#  CANLIYA DOKUNMAZ, hiçbir şey yazmaz. Yalnız ölçer ve listeler.
# ============================================================================
param(
  [string]$Rapor = '',          # varsayılan: veri/alacak-supheli-damga.json
  [switch]$Ayrinti              # her kusurlu kaydın alıntısını da bas
)

$ErrorActionPreference = 'Stop'
$KOK = Split-Path $PSScriptRoot -Parent
if(-not $Rapor){ $Rapor = Join-Path $KOK 'veri\alacak-supheli-damga.json' }

# --- okuyucudaki kapının BİREBİR aynısı (tek kaynak olmadığı için kopya;
#     ikisi ayrışırsa öz-sınav aşağıda patlar) ---------------------------
function Katla([string]$s) {
  if (-not $s) { return '' }
  return $s.Replace('İ','I').Replace('ı','i').Replace('Ş','S').Replace('ş','s').
           Replace('Ğ','G').Replace('ğ','g').Replace('Ü','U').Replace('ü','u').
           Replace('Ö','O').Replace('ö','o').Replace('Ç','C').Replace('ç','c').ToLowerInvariant()
}
$DESTEK = @{
  'RET'             = 'red|ret\b'
  'RET_IFLAS'       = 'iflas|m\.?\s*292|292\s*(ve|,|/)'
  'TASDIK'          = 'tasdik|kabul|onay'
  'IFLAS_KALDIRMA'  = 'iflas[a-z]*\s+kald|kaldirilmasina'
  'MUHLET_KALDIRMA' = 'muhlet|mehil|mehli'
  'FERAGAT'         = 'feragat|vazgec'
  'ALACAK_CAGRISI'  = 'alacak|bildir|kayd|kayit'
  'DURUSMA'         = 'durusma|gun|toplant|celse'
  'IFLAS_TASFIYE'   = 'sira cetvel|tasfiye|masa|kapan'
  'GECICI_MUHLET'   = 'muhlet|mehil|mehli'
  'KESIN_MUHLET'    = 'muhlet|mehil|mehli'
  'UZATMA'          = 'uzat'
  'MUHLET_BELIRSIZ' = 'muhlet|mehil|mehli'
}
function AlintiDestekliyorMu([string]$etiket, [string]$alinti) {
  if (-not $alinti) { return $false }
  $k = $DESTEK[$etiket]
  if (-not $k) { return $false }
  return [bool]((Katla $alinti) -match $k)
}

# --- ÖZ-SINAV (93 kapı kuralı): karar veren betik önce kendini sınar -------
# Vakalar okuyucudaki DESTEK_SINAVI ile aynı; ikisi ayrışırsa burada patlar.
$SINAV = @(
  @{e='RET_IFLAS'; a='konkordato isteminin REDDINE';                        b=$false},
  @{e='RET_IFLAS'; a='REDDINE ve borclunun IFLASINA';                       b=$true },
  @{e='RET_IFLAS'; a="IIK'nun 292 ve 308. maddeleri geregince REDDINE";     b=$true },
  @{e='TASDIK';    a='konkordato projesinin TASDIKINE';                     b=$true },
  @{e='DURUSMA';   a='durusma 12.09.2026 gunu saat 10:00';                  b=$true },
  @{e='HICBIRI';   a='herhangi bir cumle';                                  b=$false},
  # Türkçe büyük harf tuzağı - raporu bozan tam bu vakaydı:
  @{e='RET_IFLAS'; a='"İFLASINA, Mahkememizce verilen kesin mühlet kararının"'; b=$true }
)
$kotu = @($SINAV | Where-Object { (AlintiDestekliyorMu $_.e $_.a) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - kapi bozuk, olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  [{0}] {1}" -f $_.e, $_.a) -ForegroundColor Red }
  exit 2
}

# --- ölçüm ----------------------------------------------------------------
if(-not (Test-Path $Rapor)){ Write-Host "Rapor yok: $Rapor" -ForegroundColor Red; exit 1 }
$j = Get-Content $Rapor -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($j.kayitlar)

$kusurlu = @(); $duzelen = 0
foreach($k in $kayitlar){
  $gercek = AlintiDestekliyorMu $k.okuma_karari $k.alinti
  if($gercek){ if(-not $k.alinti_karari_destekliyor){ $duzelen++ }; continue }
  $kusurlu += [pscustomobject]@{
    ilan_no = $k.ilan_no; tarih = $k.tarih; il = $k.il
    regex_damgasi = $k.regex_damgasi; okuma_karari = $k.okuma_karari
    alinti = $k.alinti
  }
}

Write-Host ("KAYNAK : {0}" -f (Split-Path $Rapor -Leaf))
Write-Host ("Olcum  : {0}" -f $j.olcum)
Write-Host ("Kayit  : {0}" -f $kayitlar.Count)
Write-Host ""
Write-Host ("RAPORUN dedigi desteksiz : {0}" -f @($kayitlar | Where-Object { -not $_.alinti_karari_destekliyor }).Count)
Write-Host ("YENIDEN hesapla desteksiz: {0}" -f $kusurlu.Count) -ForegroundColor Cyan
Write-Host ("Turkce harf yuzunden yanlis 'desteksiz' sayilan: {0}" -f $duzelen) -ForegroundColor Yellow
Write-Host ""
if($kusurlu.Count){
  Write-Host "ETIKETE GORE:" -ForegroundColor Cyan
  $kusurlu | Group-Object okuma_karari | Sort-Object Count -Descending |
    ForEach-Object { Write-Host ("  {0,-18} {1,4}" -f $_.Name, $_.Count) }
  if($Ayrinti){
    Write-Host ""
    Write-Host "AYRINTI:" -ForegroundColor Cyan
    $kusurlu | ForEach-Object {
      $a = "" + $_.alinti; if($a.Length -gt 92){ $a = $a.Substring(0,92) + '...' }
      Write-Host ("  {0} [{1}] {2}" -f $_.ilan_no, $_.okuma_karari, $a)
    }
  }
}

$cikti = [pscustomobject]@{
  olcum_kaynagi = (Split-Path $Rapor -Leaf)
  kaynak_olcum_zamani = $j.olcum
  aciklama = "Alinti kendi etiketini desteklemiyor. Hesap Katla() ile YENIDEN yapildi - rapordaki alinti_karari_destekliyor alani Turkce buyuk harf tuzagi yuzunden guvenilmez."
  taranan = $kayitlar.Count
  desteksiz = $kusurlu.Count
  raporun_dedigi_desteksiz = @($kayitlar | Where-Object { -not $_.alinti_karari_destekliyor }).Count
  turkce_harf_yuzunden_yanlis = $duzelen
  ilanlar_girdisi = (($kusurlu | ForEach-Object { $_.ilan_no }) -join ',')
  kayitlar = $kusurlu
}
$hedef = Join-Path $KOK 'veri\alacak-destek-denetimi.json'
($cikti | ConvertTo-Json -Depth 6) | Set-Content $hedef -Encoding UTF8
Write-Host ""
Write-Host ("yazildi: veri/alacak-destek-denetimi.json" ) -ForegroundColor Green
if($kusurlu.Count){
  Write-Host ""
  Write-Host "okuma-pilotu.yml > ilanlar girdisine yapistirilacak liste:" -ForegroundColor Cyan
  Write-Host (($kusurlu | ForEach-Object { $_.ilan_no }) -join ',')
}
