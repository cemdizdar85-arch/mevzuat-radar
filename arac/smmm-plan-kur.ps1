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
  [switch]$YalnizHicYok,
  # ⭐ 23.09.2026 (Cem "1 yap"): bir konuya bu dalgada en çok kaç soru yazılsın.
  #   Üretici bir partide aynı konudan TEK soru çıkarır (konu listesini tekilleştirir,
  #   motor/kalip-parti-uret.ps1 ~1391) — bu yüzden `adet`i büyütmek işe yaramaz, daha çok
  #   KONU seçtirir. Çoklu soru ZORLUK dilimleriyle alınır: tavan 3 = zor + çok zor + kolay.
  #   Daha fazlası ayrı tur (tur=2) ister.
  [int]$KonuBasiTavan = 3,
  # 23.09: kapsama tablosu bu kadar saatten eskiyse plan KURULMAZ (bkz. BAYAT TABLO KAPISI).
  [int]$TabloTazelikSaat = 12,
  [switch]$Zorla,
  # ⭐ 23.09.2026 KOŞAN DALGA REZERVİ (Cem "hızlı yap"): kapsama tablosu yalnız BİTMİŞ partileri görür.
  #   Bulutta koşan bir dalganın konuları tabloda hâlâ "açık" görünür; o sırada kurulan ikinci plan AYNI
  #   konuları yeniden seçer → paralel dalga = aynı konuya ikinci ödeme (22.09 ölçümü: 1.388 fazla sorunun
  #   303'ü tam böyle, tek gecede r1..r10 turlarıyla). Bu parametre koşan dalgaların konu dosyalarını okur
  #   (veri/sinav/konu/smmm-<etiket>-*.json) ve her konu satırını 1 soruluk REZERV sayıp açıktan düşer.
  #   Örnek: -RezerveEtiket 'w7,w8'
  #   🚫 GÖRMEZ: koşan dalgada soru ÜRETİLEMEZSE (kapıdan düşerse) rezerv boşa tutulmuş olur; bir sonraki
  #     tablo tazelemesinde konu yine açık görünür ve bir sonraki dalgaya girer (kayıp değil, gecikme).
  [string]$RezerveEtiket = '',
  # 23.09: bir planın en fazla satır sayısı (bulut işi paralel=8 → 8 satır TEK SIRA koşar). Bkz. SATIR TAVANI.
  [int]$SatirTavan = 8,
  # 23.09: dalga soruları derslere AÇIKLA orantılı paylaştırılır (aşağıda "DERS PAYI"); bu anahtar eski tek-liste seçimine döner
  [switch]$DersPayiYok
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
  # Önce İ/ı katlanır, SONRA küçültülür (Linux/ICU'da 'İ'.ToLowerInvariant() = 'i'+U+0307; 23.09 dalga öz-sınavı yakaladı).
  $t = "$s".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant() -replace 'ı', 'i' -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}

# onceki dalgalarin konulari
$eski = @{}
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\sinav\konu') -Filter 'smmm-w*.json' -ErrorAction SilentlyContinue)) {
  foreach ($k in @((Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) { $eski[(Nrm "$k")] = 1 }
}
"onceki dalga konusu: {0}" -f $eski.Count

# ⛔⭐ 23.09.2026 BAYAT TABLO KAPISI — "fazla 1.388" ölçümünün doğurduğu kapı.
#   ÖLÇÜLDÜ: hedefin üstüne yazılmış 1.388 sorunun sahibi 325 konunun 323'ü BİRDEN ÇOK
#   partiden geldi; "dikey yüzde analizi" 23 ayrı partiden 49 soru almış (hedefi 13).
#   303'ünün payı tek bir dalgada: smmm-4k (16–17.09'un 400 USD'lik gecesi), çünkü o plan
#   r1..r10 turlarıyla AYNI konu listesini tekrar tekrar bastı. Üreticinin tekilleştirmesi
#   parti İÇİNDE çalışır, partiler ARASINDA çalışmaz.
#   Bugünkü koruma: plan kapsama tablosundan kurulur ve "açık > 0" şartı doluyu eler. Ama bu
#   koruma tablonun TAZE olmasına bağlıdır — bayat tabloyla kurulan plan, o gece basılmış
#   konuyu yeniden basar. Bu yüzden tablo yaşı ölçülür.
#   🚫 GÖRMEZ: tablo taze ama parti dosyaları ambardan inmemişse tablo yine eksiktir
#     (kapsama betiği bunu ayrıca kontrol eder: parti dosyası < 50 ise durur).
$csvYol = Join-Path $kok 'veri\fabrika\smmm-kapsama.csv'
if (-not (Test-Path $csvYol)) { throw "kapsama tablosu yok: $csvYol — once arac/smmm-kapsama-tablosu.ps1 kosulur (CLAUDE.md: plan TABLODAN kurulur)" }
$yas = [int]((Get-Date) - (Get-Item $csvYol).LastWriteTime).TotalHours
if ($yas -gt $TabloTazelikSaat -and -not $Zorla) {
  throw "kapsama tablosu BAYAT ($yas saat, tavan $TabloTazelikSaat) — bayat tabloyla plan kurulursa dolu konu yeniden basilir (22.09 olcumu: 1.388 fazla soru). Once: powershell -File arac/smmm-kapsama-tablosu.ps1   (bilerek gecmek icin -Zorla)"
}
"kapsama tablosu yasi: $yas saat"
$c = @(Import-Csv $csvYol -Encoding UTF8)
if (-not ($c[0].PSObject.Properties.Name -contains 'son10')) { throw "kapsama tablosunda son10 (yenilik) sütunu yok — tablo 23.09 öncesi sürüm; önce arac/smmm-kapsama-tablosu.ps1 koşulur" }
# --- KOŞAN DALGA REZERVİ: koşan dalgaların konuları açıktan düşülür ---
if ($RezerveEtiket) {
  $rezerv = @{}; $rezDosya = 0
  foreach ($rz in @($RezerveEtiket -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\sinav\konu') -Filter "smmm-$rz-*.json" -ErrorAction SilentlyContinue)) {
      $rezDosya++
      foreach ($k in @((Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) { $n0 = Nrm "$k"; $rezerv[$n0] = 1 + [int]$rezerv[$n0] }
    }
  }
  if (-not $rezDosya) { throw "rezerv etiketi '$RezerveEtiket' için konu dosyası bulunamadı — yanlış etiket yazılırsa paralel dalga AYNI konuları basar; plan kurulmadı" }
  $rezSoru = 0; foreach ($v0 in $rezerv.Values) { $rezSoru += $v0 }
  $dusen = 0
  foreach ($r in $c) {
    $n0 = Nrm "$($r.konu)"
    if ($rezerv.ContainsKey($n0)) { $yeni = [Math]::Max(0, [int]$r.acik - [int]$rezerv[$n0]); $dusen += ([int]$r.acik - $yeni); $r.acik = "$yeni" }
  }
  "KOŞAN DALGA REZERVİ ($RezerveEtiket): $rezDosya konu dosyası · $rezSoru soru rezerv · açıktan düşülen $dusen"
}
$havuz = @($c | Where-Object {
    # ⛔ 23.09 YENİLİK KURALI (Cem "10 yıldır sorulmayan konuya soru basmayalım"): eşik ve sıra artık SON 10 YIL
    #   sıklığıyla (son10). Tüm zamanlar sayısı yanıltıyordu: "şüpheli alacak karşılığı" 25 kez çıkmış ama
    #   son 10 yılda 1 kez (son 2020/2); eski kuralla 3 soru basılacaktı. son10 sütunu yoksa tablo eskidir → durur.
    [int]$_.son10 -ge $CikmisEsik -and [int]$_.acik -gt 0 -and -not $_.engel -and
    $_.ders -notmatch '/' -and $KISA.ContainsKey($_.ders) -and
    ($(if ($YalnizHicYok) { [int]$_.yayinlanabilir -eq 0 } else { $true }))
  } | Sort-Object { [int]$_.son10 }, { [int]$_.acik } -Descending)
if ($YalnizHicYok) { "MOD: YALNIZ HIC SORUSU OLMAYAN KONULAR (yayinlanabilir = 0)" }
# ⛔ 22.09 DUZELTME: once "onceki dalgalarda gecen konuyu al" diye elemistim; oyle yapinca
#   havuz 39 konuya dusuyordu. YANLIS: en cok cikan konularda ACIK ZATEN VAR (amortisman
#   ayirma cikmis 43, bizde 7 -> 122 acik). Amac ayni konuya IKINCI SORU yazmak; kopya
#   olmasini ikiz kapisi engelliyor (arac/ikiz-olcusu.ps1, uretimde de kosuyor artik).
$eskiDe = @($havuz | Where-Object { $eski.ContainsKey((Nrm $_.konu)) }).Count
"secilebilir konu (SON 10 YIL cikmis>=$CikmisEsik, acik>0, engelsiz): {0} · bunlarin {1}'i onceki dalgalarda da vardi (acik oldugu icin ALINIYOR)" -f $havuz.Count, $eskiDe

# ⭐ 23.09.2026 KONU BAŞINA ADET (Cem "1 yap"): eskiden her konuya 1 soru yazılıyordu.
#   ÖLÇÜLDÜ: "bilanço düzenleme" sınavda 31 kez çıkmış, 4.000'lik bankadaki hedefi 27 soru —
#   1 soru yazmak açığı kapatmıyor, konuyu yalnız "açıyor".
#   ⛔ MEKANİK SINIR (ölçüldü, motor/kalip-parti-uret.ps1 satır ~1391): üretici konu listesini
#     TEKİLLEŞTİRİYOR ($gorulen) — bir partide bir konudan yalnız BİR soru çıkar. `adet`i
#     büyütmek daha çok soru değil, daha çok KONU seçtirir. Bu yüzden çoklu soru, konuyu
#     BİRDEN ÇOK ZORLUK diliminde açarak alınır (aynı konu kolay + zor + çok zor = 3 soru).
#     Tavan bu yüzden 3'tür; daha fazlası ayrı tur (tur=2) ister.
$ZORLUK_SIRA = @('zor', 'cokzor', 'kolay')   # banka sınavdan zor: önce zor dilimler dolar
$hedefSoru = $PlanSayisi * $PlanBasinaSoru
# ⭐ 23.09.2026 DERS PAYI (Cem "1.2.3 üçünü de yap"): havuz tek liste halinde son10'a göre sıralanınca dalga
#   hep Finansal Muhasebe'ye gidiyordu (FM konu sayımları yevmiye kaydı başına, doğal olarak yüksek). Artık
#   dalganın soruları önce DERSLERE, her dersin (engelsiz, havuzdaki) AÇIĞIYLA orantılı paylaştırılır; ders
#   içinde sıra yine son10. Bir dersin havuzu payını dolduramazsa artan, ikinci geçişte kalan havuza gider.
#   -DersPayiYok: eski davranış (tek liste). Tablo tarafında ders tabanı: arac/smmm-kapsama-tablosu.ps1 -DersTaban.
$dersAcik = @{}; foreach ($h in $havuz) { $dersAcik["$($h.ders)"] = [int]$dersAcik["$($h.ders)"] + [int]$h.acik }
$dersKota = @{}
if (-not $DersPayiYok) {
  $wTop = 0.0; foreach ($k in $dersAcik.Keys) { $wTop += $dersAcik[$k] }
  $kes = New-Object System.Collections.Generic.List[object]; $dag = 0
  foreach ($k in $dersAcik.Keys) { $tam = $hedefSoru * $dersAcik[$k] / $wTop; $tb = [int][Math]::Floor($tam); $dersKota[$k] = $tb; $dag += $tb; $kes.Add([pscustomobject]@{ n = $k; k = $tam - $tb }) }
  foreach ($x in ($kes | Sort-Object k -Descending | Select-Object -First ($hedefSoru - $dag))) { $dersKota[$x.n]++ }
}
$sec = New-Object System.Collections.Generic.List[object]
$soruSay = 0; $dersSay = @{}; $alinan = @{}
foreach ($gecis in 1, 2) {
  if ($gecis -eq 2 -and ($DersPayiYok -or $soruSay -ge $hedefSoru)) { break }
  foreach ($h in $havuz) {
    if ($soruSay -ge $hedefSoru) { break }
    $hk = "$($h.ders)|$($h.konu)"; if ($alinan.ContainsKey($hk)) { continue }
    $kac = [Math]::Max(1, [Math]::Min([int]$h.acik, [Math]::Min($KonuBasiTavan, $ZORLUK_SIRA.Count)))
    if ($gecis -eq 1 -and -not $DersPayiYok) { $kac = [Math]::Min($kac, [int]$dersKota["$($h.ders)"] - [int]$dersSay["$($h.ders)"]) }
    if ($soruSay + $kac -gt $hedefSoru) { $kac = $hedefSoru - $soruSay }
    if ($kac -le 0) { continue }
    $h | Add-Member -NotePropertyName kacSoru -NotePropertyValue $kac -Force
    $sec.Add($h); $soruSay += $kac; $alinan[$hk] = 1; $dersSay["$($h.ders)"] = [int]$dersSay["$($h.ders)"] + $kac
  }
}
if (-not $DersPayiYok) { "DERS PAYI (dalga, acikla orantili): " + (($dersKota.Keys | Sort-Object { -$dersKota[$_] } | ForEach-Object { "{0} {1}/{2}" -f $_, [int]$dersSay[$_], $dersKota[$_] }) -join ' · ') }
$sec = [System.Collections.Generic.List[object]]@($sec | Sort-Object { [int]$_.son10 }, { [int]$_.acik } -Descending)
if ($soruSay -lt $hedefSoru) { Write-Host "  UYARI: havuz yetmedi — $soruSay soru kuruldu (istenen $hedefSoru)" -ForegroundColor Yellow }
"alinan konu: {0} · soru {1} · SON 10 YIL cikmis araligi {2}..{3} · konu basi tavan {4}" -f $sec.Count, $soruSay, ([int]$sec[0].son10), ([int]$sec[$sec.Count - 1].son10), $KonuBasiTavan

# planlara serpistir (round-robin: her plan ayni siklik profilini alsin)
# ⚠ PS 5.1 TUZAGI: hem hashtable hem dizi indekslemesi bu baglamda ArgumentException verdi.
#   Care: indeks tasima yok - her konuya plan numarasi OZELLIK olarak yazilir, sonra suzulur.
for ($i = 0; $i -lt $sec.Count; $i++) { $sec[$i] | Add-Member -NotePropertyName planNo -NotePropertyValue (($i % $PlanSayisi) + 1) -Force }

$konuDizin = Join-Path $kok 'veri\sinav\konu'
New-Item -ItemType Directory -Force $konuDizin | Out-Null

$tumSatir = New-Object System.Collections.Generic.List[object]   # 23.09 SATIR TAVANI: satırlar havuzda toplanır, sonda eşit bölünür
for ($p = 1; $p -le $PlanSayisi; $p++) {
  $liste = @($sec | Where-Object { [int]$_.planNo -eq $p })
  if (-not $liste.Count) { continue }
  $satirlar = New-Object System.Collections.Generic.List[object]
  foreach ($g in ($liste | Group-Object ders)) {
    $kk = @($g.Group)
    $ders = $g.Name; $dersKisaAd = $KISA[$ders]   # K1: $kisa yazilirsa $KISA haritasini EZER (PS harf ayirmaz)
    # Konu, kacSoru kadar ZORLUK dilimine girer (zor -> cok zor -> kolay).
    for ($z = 0; $z -lt $ZORLUK_SIRA.Count; $z++) {
      $dilim = @($kk | Where-Object { [int]$_.kacSoru -gt $z })
      if (-not $dilim.Count) { continue }
      $et = "smmm-$Etiket-$p-$dersKisaAd-$($ZORLUK_SIRA[$z])"
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
          zorluk = $(if ($ZORLUK_SIRA[$z] -eq 'cokzor') { 'çok zor' } else { $ZORLUK_SIRA[$z] })
          sinav = 'SMMM'; konuDosya = $kd; toplu = $true; disla = ''; tur = 1
        })
    }
  }
  # ⭐ 23.09.2026 SATIR TAVANI (Cem "1 yap"): bir plan en fazla -SatirTavan satır taşır, fazlası ayrı plana bölünür.
  #   ÖLÇÜLDÜ (arac/toplu-kuyruk-hizi.ps1, 5.923 parti): Anthropic kuyruğunda bekleme her saatte medyan 2–3 dk —
  #   kuyruk darboğaz DEĞİL. Dalganın 3–5 saat sürmesinin sebebi: her satır ~12 fazdan SIRAYLA geçiyor ve bulut
  #   işi aynı anda en çok `paralel` (8) satır koşturuyor; 9–15 satırlı plan İKİ SIRA koşuyordu. Tavan 8 = tek sıra.
  #   Bölünen planlar ayrı dosyadır (plan-smmm-<etiket>-<n>a/b.json) ve ayrı bulut işinde, AYNI ANDA koşar.
  #   Satır etiketleri ve konu dosyaları DEĞİŞMEZ (bölme yalnız hangi planda koşacaklarını ayırır).
  #   🚫 GÖRMEZ: GitHub'ın aynı anda koşturabildiği iş sayısını (depo başına sınır) — çok plan açılırsa bazıları
  #     sırada bekler; dalga yine kısalır ama "yarıya iner" garantisi yoktur.
  #   ⚠ İlk sürüm her planı AYRI bölüyordu: 1 satır / 1 soruluk minik planlar çıktı (her biri ayrı makine
  #     açıp partileri baştan indiriyor). Artık bütün satırlar havuzda toplanır, EŞİT dağıtılır (aşağıda).
  foreach ($s in $satirlar) { $tumSatir.Add($s) }
}
# --- DALGANIN BÜTÜN SATIRLARI eşit paylarla ≤ SatirTavan'lık planlara (round-robin: ağır ve hafif satırlar karışır) ---
$planSayi = [Math]::Max(1, [int][Math]::Ceiling($tumSatir.Count / [double]$SatirTavan))
$kova = @(); for ($q = 0; $q -lt $planSayi; $q++) { $kova += , (New-Object System.Collections.Generic.List[object]) }
# ağır satır önce: her plana ağır/hafif karışsın, soru yükü dengelensin
$sirali = @($tumSatir | Sort-Object { [int]$_.adet } -Descending)
for ($q = 0; $q -lt $sirali.Count; $q++) { $kova[$q % $planSayi].Add($sirali[$q]) }
for ($q = 0; $q -lt $planSayi; $q++) {
  $dilimSatir = @($kova[$q].ToArray())
  $planYol = Join-Path $kok "veri\sinav\plan-smmm-$Etiket-$($q + 1).json"
  $planJson = ConvertTo-Json -InputObject @($dilimSatir) -Depth 5
  if ($planJson -isnot [string]) { $planJson = ($planJson -join "`n") }
  [IO.File]::WriteAllText([string]$planYol, [string]$planJson, (New-Object Text.UTF8Encoding $false))
  $top = 0; foreach ($s in $dilimSatir) { $top += [int]$s.adet }
  "plan-smmm-$Etiket-$($q + 1).json : {0} satir · {1} soru · dersler: {2}" -f $dilimSatir.Count, $top, ((@($dilimSatir | ForEach-Object { $_.ders }) | Select-Object -Unique) -join ', ')
}
"PLAN SAYISI: $planSayi (satır tavanı $SatirTavan, toplam satır $($tumSatir.Count))"
