#requires -Version 5.1
<#
================================================================================
  DERS SÖZLÜĞÜ — ders adının TEK doğru karşılığı (10.09.2026)
  Cem: "Ders adı eşlemesi tam örtüştür"

  SORUN (ölçüldü): aynı ders dört yerde dört farklı yazılıyor ve ölçümler
  birbirine bağlanamıyor.

    resmî liste (veri/ders-profili.json, TESMER Yönergesi m.6.2)
      "Ataturk Ilkeleri ve Inkilap Tarihi" · "Is ve Sosyal Guvenlik Hukuku"
      "Ticaret Hukuku" ve "Borclar Hukuku"  -> AYRI İKİ DERS (6+6 soru)
    anatomi (veri/sinav-anatomisi-sgs.json)
      "Ataturk Ilkeleri" · "Is ve Sosyal Guvenlik"
      "Ticaret ve Borclar"                  -> BİRLEŞİK TEK DERS
    KGK profili
      "a) Türkiye Muhasebe Standartları"    -> harf ön ekli
    SMMM profili
      "Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093)" -> künye ekli

  🔴 EN ÖNEMLİ AYRIŞMA: SGS'de Ticaret Hukuku ve Borçlar Hukuku AYRI derslerdir
  (TESMER Yönergesi m.6.2: 6 + 6 soru). Anatomi ölçümü ikisini birleştirmiş.
  Bu, "Ticaret ve Borclar medyan 136 krk" gibi bir sayının aslında İKİ DERSİN
  KARIŞIMI olduğu anlamına gelir — ders bazlı uzunluk tavanı bu yüzden iki
  ders için de yanlış kalibre olur. Sözlük bunu GİZLEMEZ, işaretler.

  ÇIKTI: veri/ders-sozlugu.json
    her ders için: resmi_ad · sinav · takma_adlar[] · uyari

  KURAL: Bundan sonra ders adı karşılaştıran her ölçüm bu sözlükten geçer.
  Ham metin karşılaştırması YAPILMAZ - "Ataturk Ilkeleri" ile
  "Ataturk Ilkeleri ve Inkilap Tarihi" ayni derstir, string olarak değildir.
================================================================================
#>
param([string]$Hedef = 'veri\ders-sozlugu.json')
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
# Ad normalizasyonu: harf on eki ("a) "), kunye parantezi, kisaltma eki atilir.
function Sadelestir([string]$ad){
  $t = $ad -replace '^\s*[a-zçğıöşü]\)\s*',''      # "a) " on eki
  $t = $t -replace '\s*\(Ek:[^)]*\)\s*',''          # "(Ek: RG-...)" kunyesi
  $t = $t -replace '\s*\[\d{4}\]\s*',''             # SPL "[1001]" modul kodu
  $t = $t -replace '\s+',' '
  return $t.Trim()
}

$profil = Get-Content (Join-Path $depoKok 'veri\ders-profili.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$sozluk = New-Object System.Collections.ArrayList
foreach($s in $profil.sinavlar.PSObject.Properties){
  foreach($ad in $s.Value.PSObject.Properties.Name){
    $resmi = Sadelestir $ad
    [void]$sozluk.Add([pscustomobject]@{
      sinav       = $s.Name
      resmi_ad    = $resmi
      ham_ad      = $ad
      anahtar     = Katla $resmi
      takma_adlar = New-Object System.Collections.ArrayList
      uyari       = $null
    })
  }
}

# --- TAKMA ADLAR: olculmus kaynaklardaki farkli yazimlar -------------------
# Sol taraf takma ad, sag taraf RESMI ad (sadelestirilmis).
$TAKMA = @(
  @{ takma='Ataturk Ilkeleri';            resmi='Ataturk Ilkeleri ve Inkilap Tarihi'; nereden='sinav-anatomisi-sgs.json' },
  @{ takma='Is ve Sosyal Guvenlik';       resmi='Is ve Sosyal Guvenlik Hukuku';       nereden='sinav-anatomisi-sgs.json' },
  @{ takma='Kurumsal Yonetim';            resmi='Kurumsal Yönetim İlkeleri ve Finansal Yönetim'; nereden='kart-adaylari.json' },
  @{ takma='Turkiye Muhasebe Standartlari';resmi='Türkiye Muhasebe Standartları';     nereden='kart-adaylari.json' },
  @{ takma='Turkiye Denetim Standartlari';resmi='Türkiye Denetim Standartları';       nereden='kart-adaylari.json' },
  @{ takma='Sermaye Piyasasi Mevzuati';   resmi='Sermaye Piyasası Mevzuatı';          nereden='kart-adaylari.json' },
  @{ takma='Bankacilik';                  resmi='Bankacılık Mevzuatı';                nereden='kart-adaylari.json' },
  @{ takma='Sigortacilik';                resmi='Sigortacılık ve Özel Emeklilik Mevzuatı'; nereden='kart-adaylari.json' },
  @{ takma='Surdurulebilirlik';           resmi='Kurumsal Sürdürülebilirlik Raporlaması';  nereden='kart-adaylari.json' },
  @{ takma='Muhasebe Denetimi';           resmi='Muhasebe Denetimi';                  nereden='kart-adaylari.json' },
  @{ takma='Hukuk';                       resmi='Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.)'; nereden='kart-adaylari.json' },
  @{ takma='Vergi Mevzuatı ve Uygulaması';resmi='Vergi Mevzuatı ve Uygulaması';       nereden='rag.konu_madde' }
)
$baglanan = 0; $baglanamayan = New-Object System.Collections.ArrayList
foreach($t in $TAKMA){
  $hedefKayit = $sozluk | Where-Object { $_.anahtar -eq (Katla $t.resmi) } | Select-Object -First 1
  if($hedefKayit){ [void]$hedefKayit.takma_adlar.Add(@{ ad=$t.takma; nereden=$t.nereden }); $baglanan++ }
  else { [void]$baglanamayan.Add($t) }
}

# --- 🔴 AYRISMA UYARISI: SGS Ticaret / Borclar --------------------------------
foreach($ad in @('Ticaret Hukuku','Borclar Hukuku')){
  $k = $sozluk | Where-Object { $_.sinav -like 'STAJA*' -and $_.anahtar -eq (Katla $ad) } | Select-Object -First 1
  if($k){
    $k.uyari = 'AYRISMA: sinav-anatomisi-sgs.json bu dersi "Ticaret ve Borclar" adiyla BORCLAR HUKUKU ile BIRLESTIRMIS. TESMER Yonergesi m.6.2 ikisini AYRI sayar (6+6 soru). Bu dersin anatomi rakamlari (medyan uzunluk, zorluk, negatif oran) IKI DERSIN KARISIMIDIR - ders bazli tavan kalibrasyonu bu iki ders icin GUVENILMEZ.'
  }
}

# --- EKRAN ADI: urunde gorunecek TURKCE yazim -------------------------------
# 11.09.2026, Cem'in 2. kurali (Turkce karakter ve dogal dil hassasiyeti).
# NEDEN AYRI KATMAN: `resmi_ad` kaynagin yazimini birebir tasir ve o kaynak
# (SINAV-KONU-DAYANAK-HARITASI-31082026.xlsx / 2-DERSLER sayfasi) SGS ders
# adlarini ASCII yazmis - olculdu: sharedStrings icinde "Turkce",
# "Borclar Hukuku", "Is ve Sosyal Guvenlik Hukuku" gecer; ayni dosyanin KGK ve
# SPL sayfalari ise Turkce ("Turkiye Muhasebe Standartlari" degil
# "Türkiye Muhasebe Standartları"). Yani katlama bizim betigimizde degil,
# tabloda yapilmis. `resmi_ad`i duzeltmek kaynagi tahrif etmek olurdu; eslesme
# zaten `anahtar` (katlanmis) uzerinden yapiliyor. Bu yuzden yalnizca EKRANA
# basilan ad ayri tutulur.
# KAYNAK: TESMER Yonergesi m.6.2'deki ders adlarinin standart Turkce yazimi.
# ⚠ Cem onayina acik: asagidaki 6 satir disindaki adlarda Turkce harf yoktur.
$EKRAN = @{
  'Turkce'                             = 'Türkçe'
  'Ataturk Ilkeleri ve Inkilap Tarihi' = 'Atatürk İlkeleri ve İnkılap Tarihi'
  'Yabanci Dil'                        = 'Yabancı Dil'
  'Is ve Sosyal Guvenlik Hukuku'       = 'İş ve Sosyal Güvenlik Hukuku'
  'Borclar Hukuku'                     = 'Borçlar Hukuku'
}
$ekranSayaci = 0
foreach($k in $sozluk){
  $ad = if($EKRAN.ContainsKey("$($k.resmi_ad)")){ $ekranSayaci++; $EKRAN["$($k.resmi_ad)"] } else { "$($k.resmi_ad)" }
  $k | Add-Member -NotePropertyName ekran_ad -NotePropertyValue $ad -Force
}
Write-Host ("EKRAN ADI TURKCELESTI: {0} ders (kalan {1} ders adinda Turkce harf yok)" -f $ekranSayaci, ($sozluk.Count-$ekranSayaci))

Write-Host ("RESMI DERS KAYDI : {0}" -f $sozluk.Count)
$sozluk | Group-Object sinav | ForEach-Object { Write-Host ("  {0,-34} {1,3} ders" -f $_.Name,$_.Count) }
Write-Host ("`nTAKMA AD BAGLANDI: {0}/{1}" -f $baglanan, $TAKMA.Count)
if($baglanamayan.Count){
  Write-Host "BAGLANAMAYAN (resmi listede karsiligi YOK):" -ForegroundColor Yellow
  $baglanamayan | ForEach-Object { Write-Host ("  '{0}' -> aranan resmi ad: '{1}'" -f $_.takma,$_.resmi) }
}
$uyarili = @($sozluk | Where-Object { $_.uyari })
Write-Host ("`nAYRISMA UYARISI OLAN DERS: {0}" -f $uyarili.Count) -ForegroundColor Yellow
$uyarili | ForEach-Object { Write-Host ("  [{0}] {1}" -f $_.sinav,$_.resmi_ad) }

$rapor = [ordered]@{
  olcum   = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak  = 'veri/ders-profili.json (TESMER Yonergesi m.6.2 / KGK ilani / SPL)'
  kural   = 'Ders adi karsilastiran HER olcum bu sozlukten gecer. Ham metin karsilastirmasi YAPILMAZ.'
  ekran_kurali = 'ESLESME `anahtar` ile, EKRANA BASIM `ekran_ad` ile yapilir. `resmi_ad` kaynagin yazimidir, urunde gosterilmez (kaynak SGS derslerini ASCII yazmis).'
  ders_sayisi = $sozluk.Count
  dersler = $sozluk
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Hedef) -Nesne $rapor
Write-Host ("`n-> {0}" -f $Hedef)
