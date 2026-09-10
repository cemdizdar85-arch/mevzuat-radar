#requires -Version 5.1
<#
================================================================================
  MÜFREDAT EKSİK RAPORU — sınavda sorulan ama RAG ambarında olmayan mevzuat
  (10.09.2026 · Cem: "sınavda sorulan ama yutmadığımız tek bir kanun kalmasın")

  YÖNTEM
  ------
  Kaynak: `veri/ders-profili.json` -> her dersin `dayanak_ailesi` alanı.
  Bu alan ÇIKMIŞ SORULARDAN ÖLÇÜLMÜŞ atıflardır ("VUK (213 S.K.) (94)" =
  o dersin çıkmış sorularında VUK'a 94 kez atıf yapılmış). Yani "müfredatta
  ne gerekiyor" sorusunun cevabı TAHMİN değil, SAYIM.

  Karşı taraf: `rag.kaynak` -> ambardaki kaynak adları ve kodları.

  ⚠️ EŞLEŞTİRME BİR ADI DEĞİL, KİMLİĞİ ARAR
  Ad karşılaştırması bu depoda üç kez denendi, üçü de yanlış cevap verdi
  (bkz. dayanak-ad-koprusu: "bulunmayanların çoğu ad farkı"). Bu yüzden
  eşleştirme sırayla üç kimlik üzerinden yapılır:
    1) KANUN NUMARASI  ("213", "6102", "3568") - en güvenilir
    2) STANDART KODU   ("BDS 700", "TMS 1", "SERI: X, NO: 22")
    3) KISALTMA        ("VUK", "TTK", "MSUGT", "THP")
  Hiçbiri tutmazsa "ÖLÇÜLEMEDİ" denir - "YOK" DENMEZ.

  ÜÇ KOVA:
    VAR        -> ambarda karşılığı bulundu
    EKSİK      -> kimlik eşleşti ama ambarda karşılığı YOK -> YUTULACAK
    OLCULEMEDI -> kimlik çıkarılamadı, elle bakılmalı

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/mufredat-eksik-raporu.ps1
================================================================================
#>
param([string]$Hedef = 'veri\mufredat-eksik-raporu.json')
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}

# --- 1) AMBARDAKI KAYNAKLAR -------------------------------------------------
Write-Host "== Ambardaki kaynaklar okunuyor ==" -ForegroundColor Cyan
$ham = & (Join-Path $depoKok 'rag-motor\motor.ps1') olc "select kod, ad, tur from rag.kaynak order by kod" 2>&1
$ambar = New-Object System.Collections.ArrayList
foreach($sat in $ham){
  $t = "$sat"
  if($t -match '^\s*(info|CANLI|kod\s)') { continue }
  $p = $t -split "`t"
  if($p.Count -lt 2){ continue }
  [void]$ambar.Add([pscustomobject]@{ kod=$p[0].Trim(); ad=$p[1].Trim(); katli=(Katla ($p[0]+' '+$p[1])) })
}
Write-Host ("  ambar kaynagi: {0}" -f $ambar.Count)
if($ambar.Count -lt 100){ throw "Ambar kaynak listesi BOS/EKSIK geldi ($($ambar.Count)). Olcum durduruldu - yanlis 'EKSIK' raporu uretmektense hic uretme." }

# Ambardaki kanun numaralarini ve standart kodlarini onceden cikar
$ambarNo   = @{}   # "213" -> kaynak
$ambarKod  = @{}   # "bds 700" -> kaynak
foreach($k in $ambar){
  foreach($m in [regex]::Matches($k.katli, '\b(\d{3,5})\b')){ $ambarNo[$m.Groups[1].Value] = $k }
  foreach($m in [regex]::Matches($k.katli, '\b(bds|tms|tfrs|kks)\s*(\d+[a-z]?)\b')){ $ambarKod[($m.Groups[1].Value + ' ' + $m.Groups[2].Value)] = $k }
}

# --- 1b) KARA LISTE (10.09.2026) --------------------------------------------
# veri/YUTULMAYACAK-MEVZUAT.md: cikmis sinavda gecen ama BUGUN soru
# uretilemeyecek mevzuat. Bu liste okunmazsa denetim TMS 18'i (40 atif) "EKSIK"
# diye raporlar, biri de iyi niyetle yutar ve motor MULGA standarttan soru
# uretmeye baslar. Ayni tuzak 6111 sayili Kanun'da da yasandi: ilk raporda
# "tek gercek aday" denmisti, baglami okununca sureye bagli gecici hukum
# oldugu cikti.
# Liste dosyadan OKUNUR, koda GOMULMEZ - yeni kalem eklemek kod degistirmeyi
# gerektirmesin.
$karaYol = Join-Path $depoKok 'veri\YUTULMAYACAK-MEVZUAT.md'
$KARA = New-Object System.Collections.Generic.HashSet[string]
if(Test-Path $karaYol){
  $karaMetin = Get-Content $karaYol -Raw -Encoding UTF8
  # ⚠️ SERBEST METINDEN REGEX ILE KIMLIK CIKARMA - DENENDI, YANLIS CALISTI.
  # 10.09: desen "Halefi (ambarda)" sutunundaki TFRS 15 / TFRS 16'yi da yakaladi
  # ve onlari kara listeye aldi. Yani YUTULMASI GEREKEN iki standart "bilerek
  # yutulmadi" diye isaretlendi - gercegin tam tersi. Bir denetim aracinin
  # kendi kaynagini yanlis okumasi, olcmemekten daha tehlikelidir.
  # Cozum: kimlik TAHMIN EDILMEZ, dosyada ACIKCA yazar (KARA: <kimlik>).
  foreach($m in [regex]::Matches($karaMetin, '(?m)^\s*KARA:\s*(.+?)\s*$')){
    [void]$KARA.Add((Katla $m.Groups[1].Value))
  }
  Write-Host ("  kara liste kalemi: {0}  ({1})" -f $KARA.Count, (($KARA | Sort-Object) -join ', ')) -ForegroundColor DarkYellow
} else {
  Write-Host "  ! veri/YUTULMAYACAK-MEVZUAT.md YOK - mulga mevzuat 'EKSIK' gorunecek" -ForegroundColor Yellow
}
function KaradaMi([string]$kat){
  foreach($k in $KARA){ if($kat -match "(^|[^a-z0-9])$([regex]::Escape($k))([^a-z0-9]|$)"){ return $true } }
  return $false
}

# --- 2) MUFREDAT DAYANAKLARI ------------------------------------------------
$profil = Get-Content (Join-Path $depoKok 'veri\ders-profili.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$KISALTMA = @{
  'vuk'='213'; 'ttk'='6102'; 'tbk'='6098'; 'gvk'='193'; 'kvk'='5520'; 'kdv'='3065'
  'smmm k'='3568'; 'aatuhk'='6183'; 'is k'='4857'; 'spk'='6362'; 'iik'='2004'
}
$satirlar = New-Object System.Collections.ArrayList
foreach($s in $profil.sinavlar.PSObject.Properties){
  foreach($ders in $s.Value.PSObject.Properties){
    foreach($dy in @($ders.Value.dayanak_ailesi | ForEach-Object { $_ })){
      if(-not $dy){ continue }
      $metin = "$dy"
      $atif = 0
      if($metin -match '\((\d+)\)\s*$'){ $atif = [int]$Matches[1]; $metin = $metin -replace '\s*\(\d+\)\s*$','' }
      $kat = Katla $metin

      $bulundu = $null; $yol = $null
      # 1) kanun numarasi
      foreach($m in [regex]::Matches($kat, '\b(\d{3,5})\b')){
        $no = $m.Groups[1].Value
        if($ambarNo.ContainsKey($no)){ $bulundu = $ambarNo[$no]; $yol = "kanun no $no"; break }
      }
      # 2) standart kodu
      if(-not $bulundu){
        foreach($m in [regex]::Matches($kat, '\b(bds|tms|tfrs|kks)\s*(\d+[a-z]?)\b')){
          $kk = $m.Groups[1].Value + ' ' + $m.Groups[2].Value
          if($ambarKod.ContainsKey($kk)){ $bulundu = $ambarKod[$kk]; $yol = "standart $kk"; break }
        }
      }
      # 3) kisaltma -> kanun no
      if(-not $bulundu){
        foreach($ks in $KISALTMA.Keys){
          if($kat -match "(^|[^a-z])$ks([^a-z]|$)"){
            $no = $KISALTMA[$ks]
            if($ambarNo.ContainsKey($no)){ $bulundu = $ambarNo[$no]; $yol = "kisaltma $ks -> $no"; break }
          }
        }
      }
      # 4) serbest ad eslesmesi (en zayif - yalniz uzun adlarda)
      if(-not $bulundu -and $kat.Length -ge 10){
        $aday = $ambar | Where-Object { $_.katli -like "*$kat*" } | Select-Object -First 1
        if($aday){ $bulundu = $aday; $yol = 'ad benzerligi' }
      }

      $kimlikVar = ($kat -match '\b\d{3,5}\b') -or ($kat -match '\b(bds|tms|tfrs|kks)\s*\d') -or
                   (@($KISALTMA.Keys | Where-Object { $kat -match "(^|[^a-z])$_([^a-z]|$)" }).Count -gt 0)

      [void]$satirlar.Add([pscustomobject]@{
        sinav   = $s.Name
        ders    = $ders.Name
        dayanak = $metin
        atif    = $atif
        # KARA LISTE 'EKSIK'in ONUNDE: mulga/suresi dolmus mevzuat eksik DEGILDIR,
        # bilerek yutulmamistir. Yoksa her denetim onu yeniden "yutulacak" sanir.
        durum   = if($bulundu){ 'VAR' } elseif(KaradaMi $kat){ 'KARA-LISTE' } elseif($kimlikVar){ 'EKSIK' } else { 'OLCULEMEDI' }
        ambar_kod = if($bulundu){ $bulundu.kod } else { $null }
        eslesme_yolu = $yol
      })
    }
  }
}

# --- 3) RAPOR ---------------------------------------------------------------
$var = @($satirlar | Where-Object { $_.durum -eq 'VAR' })
$eksik = @($satirlar | Where-Object { $_.durum -eq 'EKSIK' })
$olcu = @($satirlar | Where-Object { $_.durum -eq 'OLCULEMEDI' })
$kara = @($satirlar | Where-Object { $_.durum -eq 'KARA-LISTE' })

Write-Host ""
Write-Host ("MUFREDAT DAYANAK KAYDI : {0}  ({1} ders)" -f $satirlar.Count, ($satirlar | Group-Object ders).Count)
Write-Host ("  VAR        {0,5}" -f $var.Count) -ForegroundColor Green
Write-Host ("  EKSIK      {0,5}   <- YUTULACAK" -f $eksik.Count) -ForegroundColor Red
Write-Host ("  KARA-LISTE {0,5}   <- bilerek yutulmadi (mulga/suresi dolmus)" -f $kara.Count) -ForegroundColor DarkYellow
Write-Host ("  OLCULEMEDI {0,5}   <- elle bakilmali ('YOK' DEGIL)" -f $olcu.Count) -ForegroundColor Yellow

if($eksik.Count){
  Write-Host "`n=== EKSIK DAYANAKLAR (atif sayisina gore) ===" -ForegroundColor Red
  $eksik | Sort-Object atif -Descending | Select-Object -First 40 | ForEach-Object {
    Write-Host ("  {0,4} atif · [{1}] {2}  ({3})" -f $_.atif, $_.ders, $_.dayanak, $_.sinav)
  }
}

$rapor = [ordered]@{
  olcum  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = 'veri/ders-profili.json dayanak_ailesi (cikmis sorulardan OLCULMUS atif) x rag.kaynak'
  kural  = 'Eslesme AD ile degil KIMLIK ile yapilir: kanun no > standart kodu > kisaltma. Kimlik cikmazsa OLCULEMEDI denir, YOK denmez.'
  ambar_kaynak_sayisi = $ambar.Count
  toplam = $satirlar.Count
  var = $var.Count; eksik = $eksik.Count; kara_liste = $kara.Count; olculemedi = $olcu.Count
  eksik_liste = @($eksik | Sort-Object atif -Descending)
  olculemedi_liste = @($olcu | Sort-Object atif -Descending)
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Hedef) -Nesne $rapor
Write-Host ("`n-> {0}" -f $Hedef)
