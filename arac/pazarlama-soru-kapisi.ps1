#requires -Version 5.1
<#
  PAZARLAMA SORU KAPISI
  20.09.2026 — Cem: "bunu kalıcı olarak kapat, bir daha böyle bir hata olmasın".

  OLAY: İlk Instagram gönderisi için vitrinden bir soru seçildi (sgs-t1-fmuh-kolay/kp-06,
  yazılım itfası). Tuzağın çarpıcılığına ve rakam farkına bakıldı, DAYANAĞIN HANGİ ÇERÇEVEDEN
  geldiği okunmadı. Soru TMS 38 p.97'ye göre doğruydu (4 ay → 16.000), ama VUK m.320'ye göre
  varsayılan TAM YIL'dır (48.000). Yani videoda "48 bin dedin, yanlış" demek, VUK'u düşünen
  meslek mensubunu haksız gösterirdi. 3,71 USD'lik klip yayınlanamadı.

  KAPI: Pazarlamada (video, kart, reklam) kullanılacak her soru ÖNCE buradan geçer.
    YEŞİL   = tek çerçeve, pazarlamada kullanılabilir
    SARI    = çatallı konu ama dayanak yazılı → video metninde ÇERÇEVE AÇIKÇA SÖYLENMELİ
    KIRMIZI = çatallı konu, dayanakta çerçeve yok → PAZARLAMADA KULLANMA

  Kullanım:
    powershell -NoProfile -File arac\pazarlama-soru-kapisi.ps1 -SoruId "fmuh-kolay/kp-06"
    powershell -NoProfile -File arac\pazarlama-soru-kapisi.ps1 -Hepsi
    powershell -NoProfile -File arac\pazarlama-soru-kapisi.ps1 -Sinav      # öz-sınav
#>
param(
  [string]$SoruId = '',
  [string]$VitrinYolu = '',
  [switch]$Hepsi,
  [switch]$Sinav
)
$ErrorActionPreference = 'Stop'

# --- catalli konular: ayni olaya iki cerceve iki farkli cevap verir ---
$CATALLAR = @(
  @{ ad = 'Amortisman / itfa'
     kelime = @('amortisman ayr','amortisman hesap','amortisman tutar','itfa pay','itfa ed','kıst amortisman','faydalı ömür','yararlı ömür')
     not = 'VUK m.320: aktife girdigi YILDAN tam yil (kist yalniz binek otoda; 2021den beri IHTIYARI gun esasi). TMS 16/38: kullanima hazir olunca baslar. Ayni soruya iki farkli rakam cikar.' },
  @{ ad = 'Supheli alacak / karsilik / reeskont'
     kelime = @('şüpheli alacak','şüpheli ticari','karşılık ayr','reeskont')
     not = 'VUK m.323 (dava/icra sarti) ve m.281/285 reeskont ↔ TMS 37 / TFRS 9 beklenen kredi zarari. Tutar ve zamanlama farkli.' },
  @{ ad = 'Stok degerleme'
     kelime = @('stok değerleme','net gerçekleşebilir','emsal bedel','maliyet bedeli ile değer')
     not = 'VUK m.274 maliyet bedeli ↔ TMS 2 maliyet ile net gerceklesebilir degerin dusugu.' },
  @{ ad = 'Kur farki'
     kelime = @('kur farkı değerleme','dönem sonu kur','yabancı para değerleme','döviz değerleme','kur farkını maliyete')
     not = 'Maliyete mi gidere mi yazilacagi cerceveye gore degisir (VUK m.280 ↔ TMS 21).' },
  @{ ad = 'Kiralama'
     kelime = @('finansal kiralama','kullanım hakkı varlığı','kiralama işlemi')
     not = 'VUK mük. m.290 ↔ TFRS 16 kiraci muhasebesi; TFRS 16 tum kiralamalari bilancoya alir.' },
  @{ ad = 'Hasilat'
     kelime = @('hasılatın kayd','edim yükümlülüğü','hasılat ölçüm')
     not = 'TFRS 15 edim yukumlulugu ↔ VUK teslim/fatura esasi.' },
  @{ ad = 'Calisan haklari / kidem'
     kelime = @('kıdem tazminatı karşılığı','çalışanlara sağlanan fayda','izin karşılığı')
     not = 'TMS 19 karsilik ayrilir; VUKta odenmeden gider yazilmaz.' },
  @{ ad = 'Yeniden degerleme / enflasyon'
     kelime = @('yeniden değerleme','enflasyon düzeltmesi')
     not = 'VUK mük. m.298 ↔ TMS 16 yeniden degerleme modeli.' },
  @{ ad = 'Yatirim amacli gayrimenkul'
     kelime = @('yatırım amaçlı gayrimenkul')
     not = 'TMS 40 gercege uygun deger modelinin VUKta karsiligi yok.' }
)

# dayanakta cerceve adi geciyor mu
$CERCEVE_DESEN = 'TMS\s*\d+|TFRS\s*\d+|BOBİ|BOBI|VUK|Vergi Usul|TTK|Türk Ticaret|KDVK|Katma Değer|GVK|Gelir Vergisi|KVK|Kurumlar Vergisi|THP|Tekdüzen|\d{3,4}\s*sayılı'

function Get-SoruListesi {
  param([string]$Yol)
  $ham = [IO.File]::ReadAllText($Yol, [Text.Encoding]::UTF8)
  $eslesme = [regex]::Match($ham, 'const\s+SORULAR\s*=\s*(\[[\s\S]*?\]);')
  if (-not $eslesme.Success) { throw ("SORULAR dizisi bulunamadi: " + $Yol) }
  # PS 5.1 tuzagi: @(... | ConvertFrom-Json) diziyi TEK ogeye sarar -> once degiskene al
  $cozulmus = $eslesme.Groups[1].Value | ConvertFrom-Json
  return $cozulmus
}

function Test-SoruCercevesi {
  param($Soru)
  $metin = (($Soru.soru), ($Soru.konu), ($Soru.taktik), ($Soru.hap)) -join ' '
  $dayanak = (($Soru.kural), ($Soru.hap)) -join ' '
  $bulunan = New-Object System.Collections.ArrayList
  foreach ($catal in $CATALLAR) {
    foreach ($kelime in $catal.kelime) {
      if ($metin -match [regex]::Escape($kelime)) { [void]$bulunan.Add($catal); break }
    }
  }
  if ($bulunan.Count -eq 0) {
    return @{ durum = 'YESIL'; catal = ''; gerekce = 'Catalli konu bulunmadi; tek cerceveden cevaplanir.' }
  }
  $adlar = ($bulunan | ForEach-Object { $_.ad }) -join ' + '
  $notlar = ($bulunan | ForEach-Object { $_.not }) -join ' || '
  if ($dayanak -match $CERCEVE_DESEN) {
    $cerceveAdi = ([regex]::Match($dayanak, $CERCEVE_DESEN)).Value
    return @{ durum = 'SARI'; catal = $adlar
              gerekce = ("Catalli konu ama dayanak yazili (" + $cerceveAdi + "). Video/kart metninde CERCEVE ACIKCA SOYLENMELI, yoksa diger cerceveye gore dusunen haksiz gosterilir. " + $notlar) }
  }
  return @{ durum = 'KIRMIZI'; catal = $adlar
            gerekce = ("Catalli konu ve dayanakta cerceve adi YOK. PAZARLAMADA KULLANMA. " + $notlar) }
}

function Get-VitrinYolu {
  param([string]$Verilen)
  if ($Verilen) { return $Verilen }
  $kok = Split-Path -Parent $PSScriptRoot
  return (Join-Path $kok 'kaydir\vitrin\sgs.html')
}

# ---------------- OZ-SINAV ----------------
if ($Sinav) {
  $basarisiz = 0
  # 1) gercek vaka: yazilim itfasi -> SARI (catalli + TMS 38 yazili)
  $vaka1 = [pscustomobject]@{ soru = 'kullanıma hazır hale gelen bir bilgisayar yazılımı için 240.000 TL'
                              konu = 'maddi olmayan duran varlık'; taktik = 'itfa payı hesabı'
                              kural = 'TMS 38 p.97 itfa kullanıma hazır olunca başlar'; hap = 'yararlı ömür' }
  $s1 = Test-SoruCercevesi -Soru $vaka1
  if ($s1.durum -ne 'SARI') { Write-Host ("SINAV 1 DUSTU: beklenen SARI, gelen " + $s1.durum) -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 1 GECTI (yazilim itfasi -> SARI)" -ForegroundColor Green }

  # 2) tek cerceve: KDV matrahi -> YESIL
  $vaka2 = [pscustomobject]@{ soru = 'mal bedeli, vade farkı ve taşıma gideri tahsil edilmiştir; KDV matrahı'
                              konu = 'kdv matrahı'; taktik = 'matraha dahil unsurları topla'
                              kural = 'KDVK m.24 matraha dahil unsurlar'; hap = 'vade farkı matraha dahildir' }
  $s2 = Test-SoruCercevesi -Soru $vaka2
  if ($s2.durum -ne 'YESIL') { Write-Host ("SINAV 2 DUSTU: beklenen YESIL, gelen " + $s2.durum) -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 2 GECTI (KDV matrahi -> YESIL)" -ForegroundColor Green }

  # 3) catalli ama dayanaksiz -> KIRMIZI
  $vaka3 = [pscustomobject]@{ soru = 'şüpheli alacak için karşılık ayrılmıştır'; konu = 'alacaklar'
                              taktik = 'karşılık tutarını bul'; kural = 'Karşılık, tahsil edilemeyeceği anlaşılan tutar kadar ayrılır'; hap = '' }
  $s3 = Test-SoruCercevesi -Soru $vaka3
  if ($s3.durum -ne 'KIRMIZI') { Write-Host ("SINAV 3 DUSTU: beklenen KIRMIZI, gelen " + $s3.durum) -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 3 GECTI (dayanaksiz supheli alacak -> KIRMIZI)" -ForegroundColor Green }

  if ($basarisiz -gt 0) { Write-Host ("OZ-SINAV DUSTU: " + $basarisiz + " vaka") -ForegroundColor Red; exit 1 }
  Write-Host "OZ-SINAV TEMIZ (3/3)" -ForegroundColor Green
  exit 0
}

# ---------------- TARAMA ----------------
$yol = Get-VitrinYolu -Verilen $VitrinYolu
if (-not (Test-Path $yol)) { throw ("vitrin dosyasi yok: " + $yol) }
$sorular = Get-SoruListesi -Yol $yol
Write-Host ("vitrin: " + (Split-Path -Leaf $yol) + " | soru sayisi: " + @($sorular).Count)

$hedefler = @()
if ($SoruId) {
  $hedefler = @($sorular | Where-Object { ("" + $_.id) -like ("*" + $SoruId + "*") })
  if ($hedefler.Count -eq 0) { throw ("soru bulunamadi: " + $SoruId) }
} elseif ($Hepsi) {
  $hedefler = @($sorular)
} else {
  Write-Host "-SoruId ya da -Hepsi ver." -ForegroundColor Yellow; exit 2
}

$sayim = @{ YESIL = 0; SARI = 0; KIRMIZI = 0 }
foreach ($soru in $hedefler) {
  $sonuc = Test-SoruCercevesi -Soru $soru
  $sayim[$sonuc.durum]++
  if ($Hepsi -and $sonuc.durum -eq 'YESIL') { continue }   # toplu taramada yalniz riskliler dokulur
  $renk = switch ($sonuc.durum) { 'YESIL' { 'Green' } 'SARI' { 'Yellow' } default { 'Red' } }
  Write-Host ""
  Write-Host ("[" + $sonuc.durum + "] " + $soru.id) -ForegroundColor $renk
  if ($sonuc.catal) { Write-Host ("  catal   : " + $sonuc.catal) }
  Write-Host ("  gerekce : " + $sonuc.gerekce)
  if ($soru.kural) { Write-Host ("  dayanak : " + $soru.kural) }
}

Write-Host ""
Write-Host ("SAYIM  YESIL=" + $sayim.YESIL + "  SARI=" + $sayim.SARI + "  KIRMIZI=" + $sayim.KIRMIZI)
if ($SoruId -and $sayim.KIRMIZI -gt 0) { exit 1 }
exit 0
