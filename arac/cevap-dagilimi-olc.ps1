#requires -Version 5.1
<#
================================================================================
  CEVAP DAGILIMI OLCUMU — ders ders dogru sik harfi  (12.09.2026)

  Cem: "bundan sonraki duzgun yapalim kural koyalim bundan sonra kacmasin"
       "birde bunu ders ders bakmak lazim ortalamasina sinav sinav degilde"

  NIYE VAR: 1.817 basili soruda dogru cevap harfi DENGESIZ olcuIdu
  (A %22,2 B %21,8 C %25,3 D %18,1 E %12,5 · ki-kare 87,8 · p<0,001).
  GERCEK SGS ise neredeyse kusursuz duzgun (595 cevap, ki-kare 0,6):
  A %21,0 B %20,2 C %19,5 D %20,2 E %19,2. Yani sapma SADAKAT DEGIL KUSUR.

  DERS DERS bakinca kusur UC DERSTE toplaniyor - hesap agirlikli olanlar:
      finansal-muhasebe      E %9,0   ki-kare 63,4
      maliyet-muhasebesi     E %5,6   ki-kare 49,0
      mali-tablolar-analizi  E %2,1   ki-kare 42,2
  Kalan 6 ders ZATEN DENGELI (ki-kare 2,2-7,3, gercek sinavin 0,6'sina yakin).
  Bu yuzden duzeltme KOR OLAMAZ: dengeli derste E'yi fazla basmak onlari BOZAR.

  BU BETIK NE YAPAR: basili sayfalardan ders ders harf sayimi cikarir ve
  veri/cevap-dagilimi.json'a yazar. Uretici (motor/kalip-parti-uret.ps1) bu
  dosyayi okuyup yeni partiyi DERSIN KUMULATIF ortalamasina dogru dengeler -
  eksigi olan derste eksik harfi fazla basar, dengeli derste %20'de tutar.

  ⛔ ESKI SORULAR DEGISTIRILMEZ (Cem sarti). Duzeltme yalniz yeni sorularla.
     Hesap: yeni sorular TAM DENGELI (%20) basilirsa ortalama %20'ye ASLA
     varmaz, yalnizca yaklasir (E'yi %19'a cekmek 11.823 yeni soru ister).
     Eksik harfi FAZLA basarsak ~700-1.000 yeni soru yeter. Uretici bu yuzden
     "kumulatif eksige gore" dengeler, "parti icinde %20" diye degil.

  KULLANIM
    powershell -NoProfile -File arac/cevap-dagilimi-olc.ps1
    powershell -NoProfile -File arac/cevap-dagilimi-olc.ps1 -Yaz
  BEDEL 0 — yalniz yerel dosya okur.
================================================================================
#>
param(
  [switch]$Yaz,
  [switch]$Kapi,              # CIRCIR KAPISI: bir ders TABANINDAN kotuye giderse 1 doner
  [switch]$TabanTazele,       # TEK SEFERLIK ISTISNA: tabani o anki degere esitler (asagi DA yukari DA)
  [string]$Gerekce = '',      # -TabanTazele ile ZORUNLU: niye istisna yapildigi
  [double]$Tolerans = 3.0,    # ki-kare olcum gurultusu payi
  [string]$Hedef = ''
)
# ⛔⭐ CIRCIR KAPISI (12.09, Cem "kural koyalim bundan sonra kacmasin")
#   Sorun: bugun UC ders DENGESIZ (fmuh 63,4 · maliyet 49,0 · mta 42,2).
#   "ki-kare 18,47'yi gecerse dus" diyen bir kapi ILK GUN KIRMIZI olur, kimse
#   bakmaz - kapali kapi. (Artifact nobetcisinde yasandi, K6/CI kapisinda da
#   ayni tuzaktan kacildi.)
#   Cozum CIRCIR: her dersin o anki ki-karesi TABAN olarak kaydedilir. Kapi
#   yalnizca bir ders TABANINDAN DAHA KOTUYE giderse duser. Yani:
#     - mevcut birikim kapiyi bloke etmez
#     - yeni bozulma iceri giremez
#     - ders duzeldikce taban KENDILIGINDEN asagi ciekilir (geri donus yok)
#   Boylece "bundan sonra kacmasin" mekanik olur, temenni olmaz.
$ErrorActionPreference='Stop'
$BU_DIZIN=Split-Path -Parent $MyInvocation.MyCommand.Path
$DEPO_KOK=Split-Path -Parent $BU_DIZIN

if(-not $Hedef){ $Hedef=Join-Path $DEPO_KOK 'veri\cevap-dagilimi.json' }

# Basili sayfalar ders ders ayri dosyada: kaydir/sgs/<ders>.html
$SAYFA_DIZIN=Join-Path $DEPO_KOK 'kaydir\sgs'
if(-not (Test-Path $SAYFA_DIZIN)){ throw "basili sayfa dizini yok: $SAYFA_DIZIN" }

# ders dosya adi -> resmi ders adi (uretici -DersRegex ile bu adi kullanir)
$DERS_ADI=@{
  'finansal-muhasebe'            = 'Finansal Muhasebe'
  'maliyet-muhasebesi'           = 'Maliyet Muhasebesi'
  'mali-tablolar-analizi'        = 'Mali Tablolar Analizi'
  'denetim'                      = 'Denetim'
  'ekonomi'                      = 'Ekonomi'
  'maliye'                       = 'Maliye'
  'vergi-hukuku'                 = 'Vergi Hukuku'
  'ticaret-hukuku'               = 'Ticaret Hukuku'
  'borclar-hukuku'               = 'Borclar Hukuku'
  'meslek-hukuku'                = 'Meslek Hukuku'
  'is-ve-sosyal-guvenlik-hukuku' = 'Is ve Sosyal Guvenlik Hukuku'
# ⛔⭐ 13.09.2026 — SOZEL HAT ACILDI, KAPI DA GORMELI.
#   arac/havuz-kur.ps1'e dort ders eklendi. Bu tabloya eklenmeseydi asagidaki
#   `if(-not $DERS_ADI.ContainsKey($ANAHTAR)){ continue }` satiri yeni sayfalari
#   SESSIZCE ATLARDI: sorular siteye cikar ama cevap dagilimlari HIC olculmez,
#   circir kapisi o dort derste KOR kalirdi.
#   Sayfa adlari TAHMIN EDILMEDI: motor/kaydir-yayin.ps1'deki Slug fonksiyonunun
#   kendisi calistirilarak uretildi (mevcut 'is-ve-sosyal-guvenlik-hukuku' ile tutarli).
#   ILK KOSUDA DUSMEZ: tabani olmayan ders icin satir ~144 TABAN = ilk olcum.
#   ⚠ Kucuk ornek (49-102 soru): ki-kare gurultusu yuksektir; sonraki eklemelerde
#     tolerans (3,0) asilabilir. Oyle olursa once n buyusun, taban hemen tazelenmesin.
'yabanci-dil'                        = 'Yabanci Dil'
'matematik'                          = 'Matematik'
'turkce'                             = 'Turkce'
'ataturk-ilkeleri-ve-inkilap-tarihi' = 'Ataturk Ilkeleri ve Inkilap Tarihi'
}

$DERSLER=[ordered]@{}
$GENEL=@{}
foreach($H in @('A','B','C','D','E')){ $GENEL[$H]=0 }

foreach($DOSYA in (Get-ChildItem $SAYFA_DIZIN -Filter '*.html' | Sort-Object Name)){
  $ANAHTAR=$DOSYA.BaseName
  if(-not $DERS_ADI.ContainsKey($ANAHTAR)){ continue }   # index, muhur, kapituru vb.
  $METIN=[IO.File]::ReadAllText($DOSYA.FullName,[Text.UTF8Encoding]::new($true))
  # ⛔ '"dogru"' HEM harf HEM serbest metin icin kullaniliyor (sade.dogru).
  #    Bu yuzden desen HARF SINIRLI: "dogru":"<A-E>"
  $ESLESME=[regex]::Matches($METIN,'"dogru"\s*:\s*"([A-E])"')
  if($ESLESME.Count -lt 10){ continue }
  $SAY=[ordered]@{}
  foreach($H in @('A','B','C','D','E')){ $SAY[$H]=0 }
  foreach($X in $ESLESME){ $H=$X.Groups[1].Value; $SAY[$H]=[int]$SAY[$H]+1; $GENEL[$H]=[int]$GENEL[$H]+1 }
  $N=$ESLESME.Count
  $BEKLENEN=$N/5.0
  $KI=0.0
  foreach($H in @('A','B','C','D','E')){ $KI+=[Math]::Pow([int]$SAY[$H]-$BEKLENEN,2)/$BEKLENEN }
  $DERSLER[$DERS_ADI[$ANAHTAR]]=[ordered]@{
    n=$N; say=$SAY; kikare=[Math]::Round($KI,1)
    hukum=$(if($KI -gt 18.47){'DENGESIZ'}elseif($KI -gt 9.49){'sapma'}else{'dengeli'})
  }
}

$GN=0; foreach($V in $GENEL.Values){ $GN+=$V }
$GB=$(if($GN -gt 0){ $GN/5.0 }else{ 1 })
$GKI=0.0
foreach($H in @('A','B','C','D','E')){ $GKI+=[Math]::Pow([int]$GENEL[$H]-$GB,2)/$GB }

$CIKTI=[ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak='kaydir/sgs/*.html (basili sayfalar)'
  hedef_pay=0.20
  gercek_sgs_kiyas=[ordered]@{ n=595; A=0.210; B=0.202; C=0.195; D=0.202; E=0.192; kikare=0.6
                               not='veri/sgs-arsiv kitapciklarinin sonundaki anahtar tablosu (5 kitapcik)' }
  genel=[ordered]@{ n=$GN; say=$GENEL; kikare=[Math]::Round($GKI,1) }
  dersler=$DERSLER
}

Write-Host ""
Write-Host ("CEVAP DAGILIMI · {0:N0} soru · ki-kare {1:N1}" -f $GN,$GKI) -ForegroundColor Cyan
Write-Host ("{0,-30} {1,5} {2,6} {3,6} {4,6} {5,6} {6,6} {7,7} {8}" -f 'ders','n','A','B','C','D','E','ki-kare','hukum')
foreach($AD in $DERSLER.Keys){
  $D=$DERSLER[$AD]
  $P=@(); foreach($H in @('A','B','C','D','E')){ $P+=("{0,5:N1}" -f (100*[int]$D.say[$H]/[double]$D.n)) }
  $RENK=switch($D.hukum){ 'DENGESIZ' {'Red'} 'sapma' {'Yellow'} default {'Green'} }
  Write-Host ("{0,-30} {1,5} {2} {3} {4} {5} {6} {7,7:N1} {8}" -f $AD,$D.n,$P[0],$P[1],$P[2],$P[3],$P[4],$D.kikare,$D.hukum) -ForegroundColor $RENK
}

# --- CIRCIR: eski tabanlari oku, kiyasla, gerekirse asagi cek ---------------
$ESKI=$null
if(Test-Path $Hedef){
  try{ $ESKI=Get-Content $Hedef -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ $ESKI=$null }
}
$BOZULAN=New-Object System.Collections.Generic.List[string]
$TAZELENEN=New-Object System.Collections.Generic.List[string]
if($TabanTazele -and -not "$Gerekce".Trim()){
  throw '-TabanTazele GEREKCE ister. Istisna gerekcesiz yapilmaz - "niye kotulesmeyi kabul ettik" kayda gecer.'
}
foreach($AD in $DERSLER.Keys){
  $SIMDI=[double]$DERSLER[$AD].kikare
  $TABAN=$SIMDI
  if($ESKI -and $ESKI.PSObject.Properties['dersler'] -and $ESKI.dersler.PSObject.Properties[$AD]){
    $E=$ESKI.dersler.$AD
    if($E.PSObject.Properties['taban']){ $TABAN=[double]$E.taban }
    elseif($E.PSObject.Properties['kikare']){ $TABAN=[double]$E.kikare }
  }
  if($SIMDI -gt ($TABAN+$Tolerans) -and -not $TabanTazele){
    $BOZULAN.Add(("{0}: ki-kare {1:N1} -> {2:N1} (taban+{3} asildi)" -f $AD,$TABAN,$SIMDI,$Tolerans))
  }
  if($TabanTazele){
    # ⛔⭐ TEK SEFERLIK ISTISNA (12.09, Cem "Benim onerim A, bunu yapalim")
    #   CIRCIR normalde tabani YALNIZ asagi ceker. -TabanTazele o kurali BIR KEZ
    #   askiya alir ve tabani o anki degere esitler - yani KOTULESMEYI kabul eder.
    #   NIYE GEREKTI: 12.09 yayin akisi kirmizi dustu (Denetim 10,5->19,9,
    #   Maliyet 49,0->76,8) ve 428 soruyu tuttu. OLCULDU, sebep yeni uretim DEGIL:
    #     havuza yeni giren 331 ESKI parti sorusu -> ki-kare 18,2 · E %13,9
    #     havuza yeni giren  97 B kosusu sorusu   -> ki-kare  5,7 · E %20,6
    #   Yani dengeleyici CALISIYOR (B neredeyse kusursuz); bozulmayi dengeleyici
    #   YOKKEN basilmis, odenmis ve hic yayinlanmamis eski sorular yapti.
    #   Onlari rafta tutmak odenmis isi cope atmak olurdu; kapiyi gevsetmek ise
    #   gelecegi korumasiz birakirdi. Cozum: tabani BIR KEZ, GEREKCESIYLE tazele.
    if($SIMDI -ne $TABAN){ $TAZELENEN.Add(("{0}: taban {1:N1} -> {2:N1}" -f $AD,$TABAN,$SIMDI)) }
    $DERSLER[$AD]['taban']=[Math]::Round($SIMDI,1)
    $DERSLER[$AD]['taban_gerekce']=$Gerekce
    $DERSLER[$AD]['taban_tarih']=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  } else {
    # CIRCIR: duzeldiyse taban asagi cekilir, geri yukselmez
    $DERSLER[$AD]['taban']=[Math]::Round([Math]::Min($TABAN,$SIMDI),1)
  }
}
$CIKTI.dersler=$DERSLER

# ---------------------------------------------------------------------------
# HAVUZA YENI GIRENLER — "kim kotulestirdi?" sorusunun AYRISTIRILMIS cevabi
# ---------------------------------------------------------------------------
# ⛔⭐ 12.09, Cem "Kapinin mesajini ayristiralim, bunu yapalim".
#   Ilk surum duz bir cumle yaziyordu: "yeni basilan sorular o dersin
#   dagilimini kotulestirdi." O cumle BUGUN BENI YANLIS YERE BAKTIRDI.
#   Gercek olcum: bozulmayi YENI URETIM yapmadi -
#     havuza yeni giren 331 ESKI parti sorusu -> ki-kare 18,2 · E %13,9
#     havuza yeni giren  97 B kosusu sorusu   -> ki-kare  5,7 · E %20,6
#   Yani "yeni basilan" ile "ilk kez yayinlanan ESKI soru" AYRI SEYLER ve
#   kapi ikisini ayirmadan dogru teshis veremez.
#   Olcut: yayin secim dosyasinin GIT'TEKI hali ile simdiki hali karsilastirilir;
#   fark = havuza YENI GIREN sorular. Onlarin kendi dagilimi ayrica yazilir.
$YENI_OZET=$null
try{
  $SECIM_GOR='veri/sinav/kaydir-secim/sgs-650-secim.json'
  # ⛔ git stderr'i EAP=Stop altinda betigi oldurur (K6) -> EAP dusurulur
  $ESKI_EAP=$ErrorActionPreference; $ErrorActionPreference='SilentlyContinue'
  $ESKI_SECIM_HAM=$null
  try{ $ESKI_SECIM_HAM=(& git -C $DEPO_KOK show "HEAD:$SECIM_GOR" 2>$null) -join "`n" } finally{ $ErrorActionPreference=$ESKI_EAP }
  if("$ESKI_SECIM_HAM".Trim()){
    $ESKI_OBJ=$ESKI_SECIM_HAM | ConvertFrom-Json          # ONCE DEGISKENE (K2)
    $ESKI_LISTE=@($ESKI_OBJ)
    $ESKI_ANAHTAR=@{}
    foreach($X in $ESKI_LISTE){ $ESKI_ANAHTAR[("$($X.etiket)/$($X.id)")]=$true }
    $YENI=@($SECIM | Where-Object{ -not $ESKI_ANAHTAR.ContainsKey(("$($_.etiket)/$($_.id)")) })
    if($YENI.Count){
      # bu soruların harfini basili sayfalardan degil PARTI ONBELLEGINDEN alamayiz
      # (kosucuda onbellek olmayabilir) - bu yuzden yalniz SAYI ve ETIKET dokumu.
      $YENI_ETIKET=@($YENI | Group-Object etiket | Sort-Object Count -Descending)
      $YENI_OZET=[ordered]@{
        soru=$YENI.Count
        etiket=$YENI_ETIKET.Count
        ilk10=@($YENI_ETIKET | Select-Object -First 10 | ForEach-Object{ "$($_.Name) ($($_.Count))" })
      }
    }
  }
}catch{ }

if($BOZULAN.Count){
  Write-Host ""
  Write-Host "⛔ CEVAP DAGILIMI BOZULDU (circir kapisi):" -ForegroundColor Red
  foreach($X in $BOZULAN.ToArray()){ Write-Host "   - $X" -ForegroundColor Red }
  Write-Host ""
  if($YENI_OZET){
    Write-Host ("   HAVUZA YENI GIREN: {0} soru · {1} parti" -f $YENI_OZET.soru,$YENI_OZET.etiket) -ForegroundColor Yellow
    Write-Host  "   En cok katki veren partiler (etiket adindan kaynagini oku):" -ForegroundColor Yellow
    foreach($X in $YENI_OZET.ilk10){ Write-Host "     - $X" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host  "   ⚠ TESHIS AYRIMI: 'yeni URETIM' ile 'ilk kez YAYINLANAN eski soru'" -ForegroundColor Yellow
    Write-Host  "     ayri seylerdir. Yukaridaki etiketler bu kosuda uretilen partilere" -ForegroundColor Yellow
    Write-Host  "     ait degilse, bozulma dengeleyiciden DEGIL eski birikimden gelir." -ForegroundColor Yellow
    Write-Host  "     12.09'da tam bu oldu: 331 eski soru (ki-kare 18,2) + 97 yeni soru" -ForegroundColor Yellow
    Write-Host  "     (ki-kare 5,7). Dengeleyici calisiyordu, bozan eski birikimdi." -ForegroundColor Yellow
  } else {
    Write-Host  "   (havuza yeni giren soru tespit edilemedi - secim dosyasinin git'teki hali okunamadi)" -ForegroundColor DarkGray
  }
  Write-Host ""
  Write-Host  "   NE YAPILIR:" -ForegroundColor Red
  Write-Host  "     yeni URETIM bozduysa -> motor/kalip-parti-uret.ps1 > SIK DENGESI blogu" -ForegroundColor Red
  Write-Host  "     eski BIRIKIM bozduysa -> bilincli istisna: -TabanTazele -Gerekce '...'" -ForegroundColor Red
} elseif($TAZELENEN.Count){
  Write-Host ""
  Write-Host ("⚠ TABAN TAZELENDI (tek seferlik istisna) · gerekce: {0}" -f $Gerekce) -ForegroundColor Yellow
  foreach($X in $TAZELENEN.ToArray()){ Write-Host "   - $X" -ForegroundColor Yellow }
} elseif($ESKI) {
  Write-Host "`ncircir kapisi YESIL - hicbir ders tabanindan kotuye gitmedi" -ForegroundColor Green
}

if($Yaz){
  # ⛔ Rapor JSON'u dogrudan yazilmaz - zaman damgasi her kosuda "degismis"
  #    gosterir, kapanis denetimi takilir (CLAUDE.md). RaporYaz zaman
  #    alanlarini haric tutarak kiyaslar; ayni ise DOKUNMAZ.
  . (Join-Path $BU_DIZIN 'rapor-yaz.ps1')
  RaporYaz -Hedef $Hedef -Nesne $CIKTI
} else {
  Write-Host "`n(-Yaz verilmedi: dosyaya yazilmadi)" -ForegroundColor DarkGray
}

if($Kapi -and $BOZULAN.Count){ exit 1 }
exit 0
