# ============================================================================
#  CANLI DAMGA ÖLÇÜMÜ — "kasadaki damgayı ilanın kendi metni destekliyor mu?"
#
#  NEDEN VAR (30.08.2026): O sabah ölçüldü, 32 ilanda okuma alıntısı kendi
#  etiketini desteklemiyordu. Ama o ölçüm OKUMA TURUNUN çıktısıydı; "bu 32
#  kayıt CANLIDA da yanlış damgalı mı?" sorusu cevapsız kaldı — çünkü o an
#  kasa anahtarı olmadığı sanılıyordu. Anahtar meğer varmış.
#
#  BU BETİK O BOŞLUĞU KAPATIR: verilen ilan_no'ların kasadaki karar_durumu
#  damgasını çeker ve İLANIN KENDİ METNİNİ o damgaya karşı sınar.
#    damga ret_iflas  -> metinde "iflas" geçiyor mu?
#    damga tasdik     -> metinde "tasdik/kabul/onay" geçiyor mu?
#  Metin desteklemiyorsa damga şüphelidir: site o firmayı yanlış gösteriyor.
#
#  ⚠ Türkçe harf tuzağı: metin BÜYÜK HARFLE gelir ("İFLASINA"). Katla() ile
#  ASCII'ye katlanıp ToLowerInvariant yapılmadan aranırsa hiçbir şey bulunmaz
#  ve kapı "hepsi desteksiz" der — 30.08'de tam bu yaşandı (456/456 yanlış).
#
#  CANLIYA YAZMAZ. Yalnız okur ve rapor üretir.
#  Kullanım: ... -IlanListesi "ILN...,ILN..."   ya da  -Dosya <json>
# ============================================================================
param(
  [string]$IlanListesi = '',
  [string]$Dosya = '',          # veri/alacak-destek-denetimi.json biçimi
  [switch]$Ayrinti
)

$ErrorActionPreference = 'Continue'
# 01.09 kimlik-denetimi bulgusu: Supabase kimliksiz istegi 401 ile reddeder (16.08 dersi)
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$KOK = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')   # icerik degismediyse dosyaya dokunma
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'

function Katla([string]$s) {
  if (-not $s) { return '' }
  return $s.Replace([char]0x0130,'I').Replace([char]0x0131,'i').Replace([char]0x015E,'S').Replace([char]0x015F,'s').
           Replace([char]0x011E,'G').Replace([char]0x011F,'g').Replace([char]0x00DC,'U').Replace([char]0x00FC,'u').
           Replace([char]0x00D6,'O').Replace([char]0x00F6,'o').Replace([char]0x00C7,'C').Replace([char]0x00E7,'c').ToLowerInvariant()
}
# Kasadaki damga (karar_durumu) -> metinde aranacak kalıp
$DESTEK = @{
  'ret_iflas'       = 'iflas|m\.?\s*292|292\s*(ve|,|/)'
  'ret_kaldirma'    = 'red|ret\b|kaldir'
  'tasdik'          = 'tasdik|kabul|onay'
  'iflas_kaldirma'  = 'iflas[a-z]*\s+kald|kaldirilmasina'
  'kesin_muhlet'    = 'muhlet|mehil|mehli'
  'gecici_muhlet'   = 'muhlet|mehil|mehli'
  'muhlet_kaldirma' = 'muhlet|mehil|mehli'
  'feragat'         = 'feragat|vazgec'
  'alacak_cagrisi'  = 'alacak|bildir|kayd|kayit'
  'durusma'         = 'durusma|gun|toplant|celse'
  'iflas_tasfiye'   = 'sira cetvel|tasfiye|masa|kapan'
  'uzatma'          = 'uzat'
}
function MetinDestekliyorMu([string]$damga, [string]$metin) {
  if(-not $metin){ return $false }
  $k = $DESTEK["$damga"]
  if(-not $k){ return $null }        # bilinmeyen damga: ölçülemedi (yok DEĞİL)
  return [bool]((Katla $metin) -match $k)
}

# --- ÖZ-SINAV -------------------------------------------------------------
$SINAV = @(
  @{ d='ret_iflas'; m='KONKORDATONUN REDDİNE VE BORÇLUNUN İFLASINA';        b=$true  },
  @{ d='ret_iflas'; m='konkordato isteminin REDDİNE karar verilmiştir';     b=$false },
  @{ d='tasdik';    m='KONKORDATO PROJESİNİN TASDİKİNE';                    b=$true  },
  @{ d='kesin_muhlet'; m='1 YILLIK KESİN MÜHLET VERİLMESİNE';               b=$true  }
)
$kotu = @($SINAV | Where-Object { (MetinDestekliyorMu $_.d $_.m) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  [{0}] {1}" -f $_.d, $_.m) -ForegroundColor Red }
  exit 2
}

# --- ilan listesi ---------------------------------------------------------
$ilanlar = @()
if($IlanListesi){ $ilanlar = @($IlanListesi -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
elseif($Dosya){
  if(-not (Test-Path $Dosya)){ Write-Host "Dosya yok: $Dosya" -ForegroundColor Red; exit 1 }
  $d = Get-Content $Dosya -Raw -Encoding UTF8 | ConvertFrom-Json
  $ilanlar = @($d.kayitlar | ForEach-Object { $_.ilan_no } | Where-Object { $_ })
}
if(-not $ilanlar.Count){ Write-Host "Ilan listesi bos. -IlanListesi ya da -Dosya ver." -ForegroundColor Yellow; exit 1 }

$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $anahtar){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa okunamaz." -ForegroundColor Yellow; exit 1 }
$H = @{ apikey = $anahtar; Authorization = "Bearer $anahtar"; Accept = 'application/json' }

# --- kasadan çek (50'lik dilimler) ---------------------------------------
$kayitlar = @()
$dilimSayisi = [Math]::Ceiling($ilanlar.Count / 50.0)
for($p=0; $p -lt $dilimSayisi; $p++){
  $dilim = @($ilanlar | Select-Object -Skip ($p*50) -First 50)
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  $u = "$SB_URL/rest/v1/alacak_ilan?select=ilan_no,baslik,il,karar_durumu,metin,tarih&ilan_no=in.($liste)"
  try { $kayitlar += @(Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 90) }
  catch { Write-Host ("  dilim {0} okunamadi: {1}" -f $p, $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host ("CANLI DAMGA OLCUMU: {0} ilan soruldu, {1} kayit geldi." -f $ilanlar.Count, $kayitlar.Count)

# 30.08: ILK SURUM BURADA SESSIZ YALAN SOYLUYORDU. Kasa 401 dondugunde
# $kayitlar bos kaliyor, asagidaki sayimlar "0 destekli / 0 desteksiz"
# yaziyor ve rapor TEMIZ gibi okunuyordu. Hicbir sey olculmemisken
# "kusur yok" demek, olcemedigine kusur dememenin tersi kadar kotudur.
# Kasadan HIC kayit gelmediyse olcum YAPILMAMISTIR: kirmizi don, rapor yazma.
if(-not $kayitlar.Count){
  Write-Host ""
  Write-Host "  OLCUM YAPILAMADI - kasadan hic kayit gelmedi." -ForegroundColor Red
  Write-Host "  Muhtemel sebep: anahtar alacak_ilan ucuna yetkili degil (401)." -ForegroundColor Yellow
  Write-Host "  Bu olcum service_role ister; CI'da kosar (alacak-damga-denetimi.yml)." -ForegroundColor Yellow
  Write-Host "  Rapor YAZILMADI - 'olculmedi' ile 'temiz' birbirine karismasin." -ForegroundColor Yellow
  exit 1
}

$bulunmayan = @($ilanlar | Where-Object { $i=$_; -not ($kayitlar | Where-Object { $_.ilan_no -eq $i }) })
if($bulunmayan.Count){ Write-Host ("  kasada BULUNMAYAN: {0}" -f $bulunmayan.Count) -ForegroundColor Yellow }

$destekli = @(); $desteksiz = @(); $olculemeyen = @()
foreach($k in $kayitlar){
  $s = MetinDestekliyorMu $k.karar_durumu $k.metin
  if($null -eq $s){ $olculemeyen += $k; continue }
  if($s){ $destekli += $k } else { $desteksiz += $k }
}
Write-Host ""
Write-Host ("  metin damgayi DESTEKLIYOR   : {0}" -f $destekli.Count)   -ForegroundColor Green
Write-Host ("  metin damgayi DESTEKLEMIYOR : {0}" -f $desteksiz.Count)  -ForegroundColor $(if($desteksiz.Count){'Red'}else{'Green'})
if($olculemeyen.Count){ Write-Host ("  olculemedi (bilinmeyen damga): {0}" -f $olculemeyen.Count) -ForegroundColor DarkGray }

if($desteksiz.Count){
  Write-Host ""
  Write-Host "  CANLIDA SUPHELI DAMGALAR:" -ForegroundColor Red
  $desteksiz | Select-Object -First 12 | ForEach-Object {
    $m = (Katla "$($_.metin)"); if($m.Length -gt 90){ $m = $m.Substring(0,90) }
    Write-Host ("    {0}  [{1}]  {2}" -f $_.ilan_no, $_.karar_durumu, $_.il)
    if($Ayrinti){ Write-Host ("        {0}..." -f $m) -ForegroundColor DarkGray }
  }
}

$cikti = [pscustomobject]@{
  aciklama = "Kasadaki karar_durumu damgasi ILANIN KENDI METNI ile sinandi. 'Desteklemiyor' = damga suphelidir, site o firmayi yanlis gosteriyor olabilir. Turkce harf katlamasi (Katla) uygulanmistir."
  kaynak = "alacak_ilan (Supabase kasasi)"
  sorulan = $ilanlar.Count
  gelen = $kayitlar.Count
  kasada_bulunmayan = $bulunmayan.Count
  destekli = $destekli.Count
  desteksiz = $desteksiz.Count
  olculemeyen = $olculemeyen.Count
  supheli_kayitlar = @($desteksiz | ForEach-Object {
    [pscustomobject]@{ ilan_no=$_.ilan_no; damga=$_.karar_durumu; il=$_.il; tarih=$_.tarih
                       baslik=$_.baslik; metin_bas=("$($_.metin)".Substring(0,[Math]::Min(300,"$($_.metin)".Length))) }
  })
}
$hedef = Join-Path $KOK 'veri\alacak-canli-damga-olcum.json'
RaporYaz -Hedef $hedef -Nesne $cikti | Out-Null
Write-Host ""
exit 0
