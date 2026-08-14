# ============================================================================
#  RAKIP FIRMA ANALIZI - firma bazli ihale gecmisi ozeti (14.08.2026)
#
#  Cem: "rakip aldigimiz firmalar ihaleler ile ilgili farkli bir sey yapan bizde
#        olmayan bir sey var mi" -> inceleme: ihalepro'nun ANA ozelligi "firma adi
#        ara -> kazandigi ihaleler, bedeller, calistigi kurumlar". Bizde bu VERI
#        zaten var (sonuc ilanlari yuklenici alani), arayuz eksikti.
#
#  Kaynak: veri/ihale-sonuc.json (sonuc ilanlari ambar).
#  Cikti : veri/ihale-firma-ozet.json (firma-analizi.html icin).
#
#  USTUNLUK: rakip yalniz "firma bu isi X TL'ye aldi" der. Biz sonuc ilanindaki
#  YAKLASIK MALIYET ve KIRIM oranini da tasidigimiz icin "X TL'ye, %Y kirimla,
#  Z teklif arasindan aldi" diyebiliyoruz.
#
#  RAKAM DISIPLINI: her sayi sonuc ilaninda YAZAN degerden gelir. Kirim yalniz
#  tek-sozlesmeli, ayni para birimli ihalelerde hesaplanmis (kisimli/dovizli
#  null). Firma toplam bedeli SADECE yazili bedellerin toplamidir.
#  -Yaz verilmedikce dosya yazmaz.
# ============================================================================
param([switch]$Yaz, [int]$AsgariGoster = 1)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kaynak = Join-Path $kok "veri\ihale-sonuc.json"
if(-not (Test-Path $kaynak)){ Write-Host "ihale-sonuc.json yok - once motor/ihale-sonuc-ayristir.ps1"; if($Yaz){ exit 1 }; return }
$s = @((Get-Content $kaynak -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
Write-Host ("kaynak: {0} sonuc ilani" -f $s.Count)

# Firma adi normalize: buyuk harf + tek bosluk + noktalama sadelesir. Ayni firma
# farkli yazimlarda gelebilir ("Ltd. Şti." / "Limited Şirketi"); bunlari da esitle.
function FirmaAnahtar([string]$ad){
  $a = "$ad".ToUpper()
  $a = $a -replace 'LİMİTED ŞİRKETİ','LTD ŞTİ' -replace 'ANONİM ŞİRKETİ','A Ş'
  $a = $a -replace 'LTD\.?\s*ŞTİ\.?','LTD ŞTİ' -replace 'A\.?\s*Ş\.?','A Ş'
  $a = $a -replace '[^A-ZÇĞİÖŞÜ0-9 ]',' ' -replace '\s+',' '
  return $a.Trim()
}

$grup = @{}
foreach($x in $s){
  if(-not $x.yuklenici){ continue }
  $k = FirmaAnahtar $x.yuklenici
  if($k.Length -lt 5){ continue }
  if(-not $grup.ContainsKey($k)){ $grup[$k] = New-Object Collections.ArrayList }
  [void]$grup[$k].Add($x)
}
Write-Host ("benzersiz firma: {0} · 2+ ihale: {1}" -f $grup.Count, @($grup.GetEnumerator() | Where-Object { $_.Value.Count -ge 2 }).Count)

$firmalar = New-Object Collections.ArrayList
foreach($k in $grup.Keys){
  $ihaleler = @($grup[$k])
  if($ihaleler.Count -lt $AsgariGoster){ continue }
  # gorunen ad: en uzun/tam yazim (normalize kayipsiz olsun diye orijinali tut)
  $gorunenAd = ($ihaleler | Sort-Object { "$($_.yuklenici)".Length } -Descending | Select-Object -First 1).yuklenici

  # ==== KISIMLI IHALE DUZELTMESI (14.08 Cem, ekranda gorundu) ================
  # Sonuc ilanlarinin %78'i kismi teklife acik: bir ihale kisimlara bolunup her
  # kisim AYRI sozlesme olarak yayimlaniyor (ayni IKN, ayni yaklasik maliyet).
  # Onceden her kisim ayri "is" sayiliyordu; FMB Hirdavat "8 is aldi" diyordu ama
  # 5'i AYNI Eskisehir ihalesinin kisimlariydi. Ustelik her kisimda tam ihalenin
  # yaklasik maliyeti (92 M) gosterilince "kisim bedeli / tam maliyet = %98 kirim"
  # gibi yaniltici gorunuyordu.
  # DOGRUSU: firma icinde IKN bazinda grupla. Ayni IKN'nin kisimlari TEK ihale;
  # firmanin o ihaleden aldigi is = kisim bedellerinin TOPLAMI. Kisimliysa
  # yaklasik maliyet GOSTERILMEZ (kisim toplami tam maliyeti vermez) ve kirim
  # hesaplanmaz.
  $iknGrup = [ordered]@{}
  foreach($ih in $ihaleler){ $ik = "$($ih.ikn)"; if(-not $iknGrup.Contains($ik)){ $iknGrup[$ik] = New-Object Collections.ArrayList }; [void]$iknGrup[$ik].Add($ih) }

  $ihListe = New-Object Collections.ArrayList
  $bedeller = @(); $kirimlar = @(); $kurumSet = @{}
  foreach($ik in $iknGrup.Keys){
    $kisimlar = @($iknGrup[$ik])
    $ilk = $kisimlar[0]
    $kisimBedel = @($kisimlar | Where-Object { $_.sozlesmeBedeli } | ForEach-Object { [double]$_.sozlesmeBedeli })
    $toplamKisimBedel = $(if($kisimBedel.Count){ [math]::Round(($kisimBedel | Measure-Object -Sum).Sum, 2) } else { $null })
    $cokKisim = $kisimlar.Count -gt 1
    # KOZMETIK: ardisik kelime tekrari ("İlaç Alımı Alımı") tekillestirilir
    $isAd = ("$($ilk.isAdi)".Trim()) -replace '\b(\p{L}{3,})\s+\1\b', '$1'
    if("$($ilk.idare)".Trim()){ $kurumSet["$($ilk.idare)".Trim()] = 1 }
    if($toplamKisimBedel){ $bedeller += $toplamKisimBedel }
    # kirim: yalniz TEK kisimli ihalede (kismiliyse tam maliyet guvenilir degil)
    $ihKirim = $(if(-not $cokKisim -and $null -ne $ilk.kirimYuzde){ [double]$ilk.kirimYuzde } else { $null })
    if($null -ne $ihKirim){ $kirimlar += $ihKirim }
    [void]$ihListe.Add([ordered]@{
      ikn = $ilk.ikn; tur = $ilk.tur
      isAdi = $isAd
      idare = "$($ilk.idare)".Trim()
      tarih = $ilk.sozlesmeTarih
      bedel = $toplamKisimBedel
      yaklasik = $(if($cokKisim){ $null } else { $ilk.yaklasikMaliyet })   # kisimliysa gizle
      kirim = $ihKirim
      teklif = $ilk.teklifSayisi
      kisimSayisi = $kisimlar.Count
    })
  }
  # en yeni sozlesme once
  $ihListe = @($ihListe | Sort-Object { "$($_.tarih)" } -Descending)

  [void]$firmalar.Add([ordered]@{
    ad = $gorunenAd
    ihaleSayisi = $iknGrup.Count              # benzersiz IKN = gercek ihale sayisi
    kisimliKayit = $ihaleler.Count            # ham kayit (kisimlar dahil) - seffaflik
    toplamBedel = $(if($bedeller.Count){ [math]::Round(($bedeller | Measure-Object -Sum).Sum, 2) } else { $null })
    ortKirim = $(if($kirimlar.Count){ [math]::Round(($kirimlar | Measure-Object -Average).Average, 1) } else { $null })
    kirimOlculen = $kirimlar.Count
    kurumSayisi = $kurumSet.Count
    ihaleler = @($ihListe)
  })
}
# en cok ihale kazanana gore sirala
# TUZAK: [ordered]@{} bir OrderedDictionary; Sort-Object -Property onu siralamiyor
# (hepsi ayni sirada kaliyordu). Scriptblock ile siralanir.
$firmalar = @($firmalar | Sort-Object { [int]$_.ihaleSayisi } -Descending)
Write-Host ("`nyazilacak firma: {0}" -f $firmalar.Count)
Write-Host "--- en cok kazanan 5 ---"
$firmalar | Select-Object -First 5 | ForEach-Object {
  Write-Host ("  {0,3} ihale · {1,15:N0} TL · kirim {2} · {3}" -f $_.ihaleSayisi, $(if($_.toplamBedel){$_.toplamBedel}else{0}), $(if($null -ne $_.ortKirim){"%$($_.ortKirim)"}else{'-'}), "$($_.ad)".Substring(0,[math]::Min(45,"$($_.ad)".Length)))
}

if($Yaz){
  $yol = Join-Path $kok "veri\ihale-firma-ozet.json"
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni — Sonuç İlanları (KİK). Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    not = "Firma başına ihale sayısı, toplam sözleşme bedeli ve çalıştığı kurumlar, sonuç ilanlarında idarece AÇIKLANAN verilerden ölçülmüştür. Kırım oranı yalnız tek sözleşmeli, aynı para birimli ihalelerde hesaplanır; kısımlı/dövizli ihaleler ortalamaya dahil değildir."
    kayitSayisi = $s.Count
    firmaSayisi = $firmalar.Count
    firmalar = $firmalar
  }
  ($cikti | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("`n-> {0} · {1:N0} KB · geri okuma: {2} firma" -f $yol, ((Get-Item $yol).Length/1KB), @($geri.firmalar).Count)
} else { Write-Host "`n(olcum modu - yazmak icin -Yaz)" }
