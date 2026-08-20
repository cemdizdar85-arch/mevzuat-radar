# ============================================================================
#  IDARE BAZLI ANALIZ - kurum bazli ihale gecmisi ozeti (14.08.2026)
#
#  Cem: idare bazli analiz (rakip firma analizinin tersi). "Bir kurum ara ->
#  gecmiste hangi isleri acmis, kaca kapanmis, hangi firmalarla calismis,
#  ortalama kac teklif aliyor." ihalepro'nun "ayni kurum daha once hangi
#  firmalarla calisti" vaadinin tam karsiligi.
#
#  Kaynak: veri/ihale-sonuc.json.  Cikti: veri/ihale-idare-ozet.json.
#
#  TEKLIF VERECEK ICIN DEGER: bir kuruma girmeden once "buraya ortalama kac
#  kisi giriyor (rekabet), ne kadar kirimla veriyor (fiyat baskisi), hangi
#  firmalar yerlesik" gorulur.
#
#  RAKAM DISIPLINI: her sayi sonuc ilaninda YAZAN degerden. Kirim yalniz tek
#  sozlesmeli/ayni para birimli ihalede. Kisimli ihale IKN bazinda TEK sayilir
#  (firma ozetindeki ayni tuzak). -Yaz verilmedikce dosya yazmaz.
# ============================================================================
param([switch]$Yaz, [int]$DetayTavan = 400, [int]$IhaleTavan = 10)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
# AMBAR ARTIK DEPODA DEGIL (20.08.2026): veri/ihale-sonuc.json 28,2 MB'lik ACIK
# dosyaydi ve public depoda duruyordu - 24.043 sonuc ilani, 6.844 firma, kirim
# gecmisi. Ham kayit Supabase kasasinda (RLS acik, policy YOK); buraya yalniz
# service_role ile, ihale_dokum ucundan gelir. Donen sekil eskisinin AYNISI,
# bu yuzden asagidaki hesap kismina hic dokunulmadi.
. (Join-Path $here 'ihale-ambar-oku.ps1')
$s = @(Ihale-AmbarOku -Kok $kok)
if(-not $s.Count){ Write-Host 'ambar bos/okunamadi - cikiliyor'; if($Yaz){ exit 1 }; return }
Write-Host ("kaynak: {0} sonuc ilani" -f $s.Count)

function IdareAnahtar([string]$ad){ ("$ad".ToUpper() -replace '[^A-ZÇĞİÖŞÜ0-9 ]',' ' -replace '\s+',' ').Trim() }
function FirmaAd([string]$ad){ ("$ad" -replace '\s+',' ').Trim() }

$grup = @{}
foreach($x in $s){
  if(-not $x.idare){ continue }
  $k = IdareAnahtar $x.idare
  if($k.Length -lt 8){ continue }
  if(-not $grup.ContainsKey($k)){ $grup[$k] = New-Object Collections.ArrayList }
  [void]$grup[$k].Add($x)
}
Write-Host ("benzersiz idare: {0} · 2+ ihale: {1}" -f $grup.Count, @($grup.GetEnumerator() | Where-Object { $_.Value.Count -ge 2 }).Count)

$idareler = New-Object Collections.ArrayList
foreach($k in $grup.Keys){
  $kayitlar = @($grup[$k])
  $gorunenAd = ($kayitlar | Sort-Object { "$($_.idare)".Length } -Descending | Select-Object -First 1).idare

  # KISIMLI IHALE: ayni IKN'nin kisimlari TEK ihale (firma ozetiyle ayni kural)
  $iknGrup = [ordered]@{}
  foreach($ih in $kayitlar){ $ik = "$($ih.ikn)"; if(-not $iknGrup.Contains($ik)){ $iknGrup[$ik] = New-Object Collections.ArrayList }; [void]$iknGrup[$ik].Add($ih) }

  $ihListe = New-Object Collections.ArrayList
  $bedeller=@(); $kirimlar=@(); $teklifler=@(); $firmaSet=@{}
  foreach($ik in $iknGrup.Keys){
    $kisimlar = @($iknGrup[$ik]); $ilk = $kisimlar[0]; $cokKisim = $kisimlar.Count -gt 1
    $kisimBedel = @($kisimlar | Where-Object { $_.sozlesmeBedeli } | ForEach-Object { [double]$_.sozlesmeBedeli })
    $topBedel = $(if($kisimBedel.Count){ [math]::Round(($kisimBedel | Measure-Object -Sum).Sum,2) } else { $null })
    $isAd = ("$($ilk.isAdi)".Trim()) -replace '\b(\p{L}{3,})\s+\1\b','$1'
    # bu ihalede calisilan firma(lar)
    foreach($ks in $kisimlar){ if($ks.yuklenici){ $firmaSet[(FirmaAd $ks.yuklenici)] = 1 } }
    if($topBedel){ $bedeller += $topBedel }
    if($ilk.teklifSayisi){ $teklifler += [int]$ilk.teklifSayisi }
    $ihKirim = $(if(-not $cokKisim -and $null -ne $ilk.kirimYuzde){ [double]$ilk.kirimYuzde } else { $null })
    if($null -ne $ihKirim){ $kirimlar += $ihKirim }
    [void]$ihListe.Add([ordered]@{
      ikn=$ilk.ikn; tur=$ilk.tur; isAdi=$isAd
      tarih=$ilk.sozlesmeTarih; bedel=$topBedel
      yaklasik=$(if($cokKisim){$null}else{$ilk.yaklasikMaliyet})
      kirim=$ihKirim; teklif=$ilk.teklifSayisi
      yuklenici=$(FirmaAd $ilk.yuklenici); kisimSayisi=$kisimlar.Count
    })
  }
  $ihListe = @($ihListe | Sort-Object { "$($_.tarih)" } -Descending)
  [void]$idareler.Add([ordered]@{
    ad=$gorunenAd
    ihaleSayisi=$iknGrup.Count
    kisimliKayit=$kayitlar.Count
    toplamBedel=$(if($bedeller.Count){ [math]::Round(($bedeller|Measure-Object -Sum).Sum,2) } else { $null })
    ortKirim=$(if($kirimlar.Count){ [math]::Round(($kirimlar|Measure-Object -Average).Average,1) } else { $null })
    kirimOlculen=$kirimlar.Count
    ortTeklif=$(if($teklifler.Count){ [math]::Round(($teklifler|Measure-Object -Average).Average,1) } else { $null })
    firmaSayisi=$firmaSet.Count
    ihaleler=@($ihListe)
  })
}
$idareler = @($idareler | Sort-Object { [int]$_.ihaleSayisi } -Descending)
Write-Host ("`nyazilacak idare: {0}" -f $idareler.Count)
Write-Host "--- en cok ihale acan 5 ---"
$idareler | Select-Object -First 5 | ForEach-Object {
  Write-Host ("  {0,3} ihale · {1,3} firma · ort {2} teklif · kirim {3} · {4}" -f $_.ihaleSayisi, $_.firmaSayisi, $(if($_.ortTeklif){$_.ortTeklif}else{'-'}), $(if($null -ne $_.ortKirim){"%$($_.ortKirim)"}else{'-'}), "$($_.ad)".Substring(0,[math]::Min(42,"$($_.ad)".Length)))
}

if($Yaz){
  # site dosyasi buyume siniri
  # NOT: yerel adi $yaz KOYMA - switch param $Yaz ile ayni degisken (PS harf duyarsiz)
  # 20.08 (3 aylik derinlik): eskiden yalniz en cok ihale acan 400 idare
  # yaziliyordu - 6.659 idare arananamaz haldeydi. Firma ozetindeki ayrimin
  # aynisi: idare LISTESI kirpilmaz (ozet rakamlari herkes icin durur),
  # kirpilan sey her idarenin icine gomulu IHALE LISTESI. Sessiz kirpma yok.
  $cikanlar = @($idareler)
  $detaysiz = 0; $kirpilanIhale = 0
  for($ii=0; $ii -lt $cikanlar.Count; $ii++){
    $it = $cikanlar[$ii]
    $l = @($it.ihaleler)
    if($ii -ge $DetayTavan){ if($l.Count){ $detaysiz++ }; $it.ihaleler = @(); continue }
    if($l.Count -gt $IhaleTavan){ $kirpilanIhale += ($l.Count - $IhaleTavan); $it.ihaleler = @($l | Select-Object -First $IhaleTavan) }
  }
  if($detaysiz){ Write-Host ("   not: {0} idarenin ihale listesi yazilmadi (ozet rakamlari duruyor, en cok ihale acan {1} idarede detay var)" -f $detaysiz, $DetayTavan) }
  if($kirpilanIhale){ Write-Host ("   not: {0} ihale satiri idare basina {1} tavaniyla kirpildi" -f $kirpilanIhale, $IhaleTavan) }
  $yol = Join-Path $kok "veri\ihale-idare-ozet.json"
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni — Sonuç İlanları (KİK). Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    not = "Kurum başına ihale sayısı, toplam sözleşme bedeli, çalıştığı firmalar ve ortalama teklif sayısı sonuç ilanlarında idarece AÇIKLANAN verilerden ölçülmüştür. Kırım yalnız tek sözleşmeli, aynı para birimli ihalelerde; kısımlı ihaleler tek ihale sayılır."
    idareSayisi = $idareler.Count
    idareler = $cikanlar
  }
  ($cikti | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("`n-> {0} · {1:N0} KB · {2}/{3} idare (detay tavani {4})" -f $yol, ((Get-Item $yol).Length/1KB), @($geri.idareler).Count, $idareler.Count, $DetayTavan)
} else { Write-Host "`n(olcum modu - yazmak icin -Yaz)" }
