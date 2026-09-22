#requires -Version 5.1
<#
================================================================================
  SMMM (BİTİRME) BASIM PLANI KURUCU — KAPSAMA TABLOSUNDAN   22.09.2026 · bedel 0

  Cem 22.09: "exceli yap ve ona göre soru çıkaralım · ben böyle biliyordum,
  bunu kural olarak yazalım."

  NİYE VAR: bitirme planları bugüne kadar elde kuruldu ve sonuç 22.09'da ölçüldü —
  kapsam GENİŞLİĞE gitmiş, SIKLIĞA gitmemişti: çıkmış sınavlarda 43 kez görülen
  "amortisman ayırma"da 7, 31 kez görülen "bilanço düzenleme"de ve 25 kez görülen
  "şüpheli alacak karşılığı"nda SIFIR sorumuz vardı. Plan artık elden değil,
  kapsama tablosundan kurulur.

  GİRDİ  : veri/fabrika/smmm-kapsama.csv   (arac/smmm-kapsama-tablosu.ps1)
  ÇIKTI  : veri/sinav/plan-smmm-<etiket>-<n>.json + veri/sinav/konu/*.json

  SEÇİM  : çıkmış >= -CikmisEsik · açık > 0 · ENGEL yok (kısır/kaynak borcu) ·
           tek ders · çıkmış sırasına göre azalan (SIKLIK ÖNCE)
  ZORLUK : kolay %25 · zor %50 · çok zor %25 — banka sınavdan ZOR olacak (Cem 21.09)

  ⛔ AYNI KONU YASAK DEĞİLDİR. Önceki dalgalarda geçen konu da alınır, çünkü en çok
    çıkan konularda AÇIK zaten vardır (amortisman ayırma 122 açık). Kopya olmasını
    ikiz kapısı engeller (arac/ikiz-olcusu.ps1 — 22.09'dan beri üretimde de koşuyor).
    İlk kurulumda bu konular elenmişti ve havuz 239'dan 39 konuya düşmüştü.

  🚫 BU KURUCU ŞUNU GÖRMEZ: konu adı yazım farklarını (aynı konu iki satır olabilir) ·
    kaynak yeterliliğini (onu hakem söyler) · bütçeyi (o bulut işinin kapısı).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/smmm-plan-kur.ps1 -PlanSayisi 2 -PlanBasinaSoru 45 -Etiket w7
================================================================================
#>
param(
  [int]$PlanSayisi = 2, [int]$PlanBasinaSoru = 45, [string]$Etiket = 'w7', [int]$CikmisEsik = 3,
  # ⭐ 22.09.2026 (Cem "1 yap"): açığın EN PAHALI kısmı, hiç sorusu olmayan YÜKSEK SIKLIKLI konular.
  #   Ölçüldü: 4.000'lik bankaya göre açık 3.338 soru; bunun 3.051'i HİÇ SORUSU OLMAYAN 2.537 konuda.
  #   Sınavda 31 kez çıkan "bilanço düzenleme"de ve 25 kez çıkan "şüpheli alacak karşılığı"nda
  #   sıfır sorumuz vardı. Bu anahtar planı yalnız o konulardan kurar.
  #   ⚠ KÖRLÜK: "hiç yok" sayısı konu adı yazım farkından ŞİŞİKTİR — 2.537'nin 594'ü aslında
  #     adı farklı yazılmış dolu bir konunun alt/üst kümesi ("şüpheli alacak karşılığı" ~
  #     "şüpheli alacak karşılığı ayırma"). Bu plana o ikizler de girebilir; kopyayı üretimdeki
  #     ikiz kapısı (arac/ikiz-olcusu.ps1) eler, ama parası ödenir. Konu adı tekilleştirmesi ayrı iş.
  [switch]$YalnizHicYok
)
$kok = Split-Path -Parent $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $kok 'arac\smmm-ders-adi.ps1')   # ders adı TEK haritadan (etiket -> kanonik ders adı)
$ErrorActionPreference = 'Stop'
# (sabit yol kaldırıldı — $kok yukarıda betiğin kendi konumundan çözülüyor)

$KISA = @{
  'Finansal Muhasebe' = 'fmuh'; 'Finansal Tablolar ve Analizi' = 'yfta'; 'Maliyet Muhasebesi' = 'maliyet'
  'Muhasebe Denetimi' = 'ydenetim'; 'Sermaye Piyasası Mevzuatı' = 'yspk'; 'Vergi Mevzuatı ve Uygulaması' = 'yvergi'
  'Hukuk' = 'yhukuk'; 'Muh. ve Mali Müş. Meslek Hukuku' = 'ymeslek'
}
function Nrm([string]$s) {
  $t = "$s".ToLowerInvariant() -replace 'ı', 'i' -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}

# onceki dalgalarin konulari
$eski = @{}
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\sinav\konu') -Filter 'smmm-w*.json' -ErrorAction SilentlyContinue)) {
  foreach ($k in @((Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) { $eski[(Nrm "$k")] = 1 }
}
"onceki dalga konusu: {0}" -f $eski.Count

$c = @(Import-Csv (Join-Path $kok 'veri\fabrika\smmm-kapsama.csv') -Encoding UTF8)
$havuz = @($c | Where-Object {
    [int]$_.cikmis -ge $CikmisEsik -and [int]$_.acik -gt 0 -and -not $_.engel -and
    $_.ders -notmatch '/' -and $KISA.ContainsKey($_.ders) -and
    ($(if ($YalnizHicYok) { [int]$_.yayinlanabilir -eq 0 } else { $true }))
  } | Sort-Object { [int]$_.cikmis } -Descending)
if ($YalnizHicYok) { "MOD: YALNIZ HIC SORUSU OLMAYAN KONULAR (yayinlanabilir = 0)" }
# ⛔ 22.09 DUZELTME: once "onceki dalgalarda gecen konuyu al" diye elemistim; oyle yapinca
#   havuz 39 konuya dusuyordu. YANLIS: en cok cikan konularda ACIK ZATEN VAR (amortisman
#   ayirma cikmis 43, bizde 7 -> 122 acik). Amac ayni konuya IKINCI SORU yazmak; kopya
#   olmasini ikiz kapisi engelliyor (arac/ikiz-olcusu.ps1, uretimde de kosuyor artik).
$eskiDe = @($havuz | Where-Object { $eski.ContainsKey((Nrm $_.konu)) }).Count
"secilebilir konu (cikmis>=$CikmisEsik, acik>0, engelsiz): {0} · bunlarin {1}'i onceki dalgalarda da vardi (acik oldugu icin ALINIYOR)" -f $havuz.Count, $eskiDe

$gerekli = $PlanSayisi * $PlanBasinaSoru
if ($havuz.Count -lt $gerekli) { Write-Host "  UYARI: havuz $($havuz.Count) konu, istenen $gerekli — plan kucuk kurulacak" -ForegroundColor Yellow }
$sec = @($havuz | Select-Object -First $gerekli)
"alinan konu: {0} · cikmis araligi {1}..{2}" -f $sec.Count, ([int]$sec[0].cikmis), ([int]$sec[-1].cikmis)

# planlara serpistir (round-robin: her plan ayni siklik profilini alsin)
# ⚠ PS 5.1 TUZAGI: hem hashtable hem dizi indekslemesi bu baglamda ArgumentException verdi.
#   Care: indeks tasima yok - her konuya plan numarasi OZELLIK olarak yazilir, sonra suzulur.
for ($i = 0; $i -lt $sec.Count; $i++) { $sec[$i] | Add-Member -NotePropertyName planNo -NotePropertyValue (($i % $PlanSayisi) + 1) -Force }

$ZORLUK = @(@('kolay', 0.25), @('zor', 0.50), @('cokzor', 0.25))
$konuDizin = Join-Path $kok 'veri\sinav\konu'
New-Item -ItemType Directory -Force $konuDizin | Out-Null

for ($p = 1; $p -le $PlanSayisi; $p++) {
  $liste = @($sec | Where-Object { [int]$_.planNo -eq $p })
  if (-not $liste.Count) { continue }
  $satirlar = New-Object System.Collections.Generic.List[object]
  foreach ($g in ($liste | Group-Object ders)) {
    $kk = @($g.Group)
    $ders = $g.Name; $dersKisaAd = $KISA[$ders]   # K1: $kisa yazilirsa $KISA haritasini EZER (PS harf ayirmaz)
    # dersin konularini zorluklara bol
    $baslangic = 0
    for ($z = 0; $z -lt $ZORLUK.Count; $z++) {
      $adet = $(if ($z -eq $ZORLUK.Count - 1) { $kk.Count - $baslangic } else { [int][Math]::Round($kk.Count * $ZORLUK[$z][1]) })
      if ($adet -le 0) { continue }
      $dilim = @($kk[$baslangic..($baslangic + $adet - 1)])
      $baslangic += $adet
      $et = "smmm-$Etiket-$p-$dersKisaAd-$($ZORLUK[$z][0])"
      $kd = "veri/sinav/konu/$et.json"
      $konuJson = ConvertTo-Json -InputObject ([string[]]@($dilim | ForEach-Object { "$($_.konu)" })) -Depth 3
      if ($konuJson -isnot [string]) { $konuJson = ($konuJson -join "`n") }
      [IO.File]::WriteAllText([string](Join-Path $kok ($kd -replace '/', '\')), [string]$konuJson, (New-Object Text.UTF8Encoding $false))
      # ⛔ 22.09: plandaki DERS ADI kaynak seçimini belirler (üreticinin DERS_KANUN haritası).
      #   Köprü "Muh. ve Mali Müş. Meslek Hukuku" diyor, kaynak haritası "Meslek Hukuku" biliyor;
      #   liste dışı ad yazılınca ders kanunu hiç aranmıyor ve hakem "kaynak yok" diyor (07.09 dersi).
      #   Bu yüzden ad, etiketten çözülen KANONİK ada çevrilir.
      $dersKanonik = SmmmDersAdi $et $null
      if (-not $dersKanonik) { throw "etiket '$et' ders haritasında çözülemedi — plan kurulmadı (arac/smmm-ders-adi.ps1'e satır eklenmeli)" }
      $satirlar.Add([ordered]@{
          ders = $dersKanonik; dersAd = $dersKanonik; etiket = $et; adet = $dilim.Count
          zorluk = $(if ($ZORLUK[$z][0] -eq 'cokzor') { 'çok zor' } else { $ZORLUK[$z][0] })
          sinav = 'SMMM'; konuDosya = $kd; toplu = $true; disla = ''; tur = 1
        })
    }
  }
  $planYol = Join-Path $kok "veri\sinav\plan-smmm-$Etiket-$p.json"
  $planJson = ConvertTo-Json -InputObject @($satirlar.ToArray()) -Depth 5
  if ($planJson -isnot [string]) { $planJson = ($planJson -join "`n") }
  [IO.File]::WriteAllText([string]$planYol, [string]$planJson, (New-Object Text.UTF8Encoding $false))
  $top = 0; foreach ($s in $satirlar) { $top += [int]$s.adet }
  "plan-smmm-$Etiket-$p.json : {0} satir · {1} soru · dersler: {2}" -f $satirlar.Count, $top, ((@($satirlar | ForEach-Object { $_.ders }) | Select-Object -Unique) -join ', ')
}
