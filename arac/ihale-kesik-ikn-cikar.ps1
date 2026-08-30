# ============================================================================
#  KESİK FİRMA ADI → TAM IKN LİSTESİ (onarım turunun girdisi)
#
#  NEDEN VAR (30.08.2026): arac/ihale-firma-adi-denetimi.ps1 kusurlu kayıtları
#  buluyor ama IKN'leri ÖZETTEN okuyor — ve özet `IhaleTavan: 10` ile kırpıyor.
#  Sonuç: "Ticaret Limited Şirketi" 295 ihaleye sahip ama elimizde 10 IKN var.
#  O 10'u onarsan 285 kayıt bozuk kalır; üstelik hangileri olduğu da bilinmez.
#
#  Bu betik ham kasadan (ihale_dokum) okur ve kusurlu her yüklenici adı için
#  TAM IKN listesini çıkarır. Denetim betiği "hangi kayıtlar bozuk" sorusunu,
#  bu betik "onarmak için hangi ilanları yeniden okumalı" sorusunu cevaplar.
#
#  ⚠ KASA ANAHTARI GEREKİR (SUPABASE_SERVICE_KEY) — Cem'in makinesinde yok,
#  CI'da var. Yerelde çalıştırılırsa anahtarsız düşer ve bunu söyler.
#
#  CANLIYA YAZMAZ. Yalnız okur ve veri/ihale-kesik-ikn.json üretir.
# ============================================================================
param([switch]$Ayrinti)

$ErrorActionPreference = 'Continue'
$KOK  = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')   # icerik degismediyse dosyaya dokunma
$MOTOR = Join-Path $KOK 'motor'

# Denetim betiğiyle AYNI ölçüt (tek kaynak olmadığı için kopya; ayrışırsa
# öz-sınav patlar). Ad jenerik bir şirket ekiyle BAŞLIYORSA özel ad kayıptır.
$JENERIK = @(
  'Ticaret','Sanayi','İhracat','İthalat','Ithalat','Limited','Anonim',
  'Turizm','İnşaat','Insaat','Nakliyat','Gıda','Tıbbi','Medikal','Otomotiv',
  'Elektrik','Temizlik','Danışmanlık','Mühendislik','Teknoloji','Bilgisayar',
  'Enerji','Tarım','Orman','Maden','Tekstil','Kimya','Metal','Makine',
  'Taahhüt','Hizmetleri','Pazarlama','Dağıtım','Lojistik','Yapı'
)
$desen = '^(' + (($JENERIK | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\b'

# --- ÖZ-SINAV: ölçüt denetim betiğiyle aynı mı? ---------------------------
$SINAV = @(
  @{ ad='Ticaret Limited Şirketi';                             b=$true  },
  @{ ad='Avcan Taşımacılık Sanayi ve Ticaret Limited Şirketi'; b=$false },
  @{ ad='Mehmet Yılmaz';                                       b=$false }
)
$kotu = @($SINAV | Where-Object { ($_.ad -match $desen) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - olcut denetim betiginden AYRISMIS, olcum YAPILMADI." -ForegroundColor Red
  exit 2
}

if(-not "$($env:SUPABASE_SERVICE_KEY)".Trim()){
  Write-Host "SUPABASE_SERVICE_KEY yok - kasa okunamaz." -ForegroundColor Yellow
  Write-Host "  Bu betik CI'da kosar (ihale-ozet-tazele.yml). Yerelde anahtar yoktur." -ForegroundColor Yellow
  exit 1
}

. (Join-Path $MOTOR 'ihale-ambar-oku.ps1')
$kayitlar = @(Ihale-AmbarOku -Kok $KOK)
if(-not $kayitlar.Count){ Write-Host "ambar bos/okunamadi" -ForegroundColor Red; exit 1 }

# --- kusurlu yüklenici adlarını grupla, TAM IKN listesini topla -----------
$grup = @{}
foreach($x in $kayitlar){
  $ad = "$($x.yuklenici)"
  if(-not $ad){ continue }
  if($ad -notmatch $desen){ continue }
  if(-not $grup.ContainsKey($ad)){ $grup[$ad] = New-Object System.Collections.Generic.List[string] }
  $ikn = "$($x.ikn)"
  if($ikn -and -not $grup[$ad].Contains($ikn)){ [void]$grup[$ad].Add($ikn) }
}

# Sınıflandırma (denetim betiğiyle aynı): onarım hedefi SADE KESİK olanlardır.
$kayit = @()
foreach($ad in $grup.Keys){
  $sinif = if($ad -match ','){ 'coklu_yuklenici' }
           elseif($ad -match 'Ortaklığı'){ 'is_ortakligi' }
           elseif($ad -cmatch '-[A-ZÇĞİÖŞÜ]'){ 'sahis_eki' }
           else { 'SADE_KESIK' }
  $kayit += [pscustomobject]@{ ad = $ad; sinif = $sinif; iknSayisi = $grup[$ad].Count; ikn = @($grup[$ad]) }
}
$kayit = @($kayit | Sort-Object iknSayisi -Descending)
$sade = @($kayit | Where-Object { $_.sinif -eq 'SADE_KESIK' })
$sadeIkn = ($sade | Measure-Object iknSayisi -Sum).Sum

Write-Host ("KESIK FIRMA ADI -> TAM IKN: {0} kasa kaydi tarandi." -f $kayitlar.Count)
Write-Host ("  kusurlu yuklenici adi : {0}" -f $kayit.Count)
Write-Host ("  bunlarin SADE KESIK'i : {0}  ->  ONARILACAK ILAN: {1}" -f $sade.Count, $sadeIkn) -ForegroundColor Cyan
Write-Host ""
Write-Host "  EN COK ILANI OLAN 8 (ozetteki 10'luk tavan ARTIK YOK):" -ForegroundColor Cyan
$sade | Select-Object -First 8 | ForEach-Object {
  Write-Host ("    {0,-40} {1,5} ilan" -f $_.ad.Substring(0,[Math]::Min(38,$_.ad.Length)), $_.iknSayisi)
}
if($Ayrinti){
  Write-Host ""
  $sade | Select-Object -First 3 | ForEach-Object {
    Write-Host ("    {0}" -f $_.ad)
    Write-Host ("      {0}" -f (($_.ikn | Select-Object -First 25) -join ', '))
  }
}

$cikti = [pscustomobject]@{
  olcum = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama = "Ozel adi kayip yuklenici adlari ve TAM IKN listeleri. Kaynak HAM KASADIR - ozet degil; ozetteki IhaleTavan(10) kirpmasi burada YOKTUR. Onarim: SADE_KESIK sinifindaki adlarin IKN'leri okuma-pilotu ya da sonuc ilani yeniden ayristirma turuna verilir."
  kaynak = "ihale_dokum (Supabase kasasi)"
  taranan_kasa_kaydi = $kayitlar.Count
  kusurlu_ad = $kayit.Count
  sade_kesik_ad = $sade.Count
  onarilacak_ilan = $sadeIkn
  kayitlar = $kayit
}
$hedef = Join-Path $KOK 'veri\ihale-kesik-ikn.json'
RaporYaz -Hedef $hedef -Nesne $cikti | Out-Null
Write-Host ""
exit 0
