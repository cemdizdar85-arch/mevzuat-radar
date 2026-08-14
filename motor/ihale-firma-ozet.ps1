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
  $bedeller = @($ihaleler | Where-Object { $_.sozlesmeBedeli } | ForEach-Object { [double]$_.sozlesmeBedeli })
  $kirimlar = @($ihaleler | Where-Object { $null -ne $_.kirimYuzde } | ForEach-Object { [double]$_.kirimYuzde })
  $kurumlar = @($ihaleler | Where-Object { $_.idare } | ForEach-Object { "$($_.idare)".Trim() } | Select-Object -Unique)
  $ihListe = New-Object Collections.ArrayList
  foreach($ih in ($ihaleler | Sort-Object { "$($_.sozlesmeTarih)" } -Descending)){
    # KOZMETIK: bazi sonuc ilanlarinda is adi "...İlaç Alımı Alımı" gibi ARDISIK
    # kelime tekrariyla geliyor (kaynak metninde baslik iki kez akiyor). Ardisik
    # ayni kelime tekilleştirilir - anlam degismez, gorunum duzelir.
    $isAd = ("$($ih.isAdi)".Trim()) -replace '\b(\p{L}{3,})\s+\1\b', '$1'
    [void]$ihListe.Add([ordered]@{
      ikn = $ih.ikn; tur = $ih.tur
      isAdi = $isAd
      idare = "$($ih.idare)".Trim()
      tarih = $ih.sozlesmeTarih
      bedel = $ih.sozlesmeBedeli
      yaklasik = $ih.yaklasikMaliyet
      kirim = $ih.kirimYuzde
      teklif = $ih.teklifSayisi
    })
  }
  [void]$firmalar.Add([ordered]@{
    ad = $gorunenAd
    ihaleSayisi = $ihaleler.Count
    toplamBedel = $(if($bedeller.Count){ [math]::Round(($bedeller | Measure-Object -Sum).Sum, 2) } else { $null })
    ortKirim = $(if($kirimlar.Count){ [math]::Round(($kirimlar | Measure-Object -Average).Average, 1) } else { $null })
    kirimOlculen = $kirimlar.Count
    kurumSayisi = $kurumlar.Count
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
