#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) KAYNAK ÖLÇÜMÜ — "yuttuğumuz veri hangi konuya soru basmamıza izin veriyor?"   16.09.2026  (bedel 0, MODEL ÇAĞRISI YOK)
#
#  NEDEN (Cem 16.09): "bizim yuttuğumuz veriler hangi soruları basmamıza izin veriyor" + "1.2.3 üçünü de yapalım" (GM 3).
#  Tahmin YOK: planın HER konusu için üreticinin KENDİ desen üretimi (DesenUret) ve ambar çekimi (AmbarCek) koşulur,
#  ambardan dönen paketin uzunluğu ölçülür. Ölçüt üreticinin kendi eşikleridir (motor/kalip-parti-uret.ps1):
#     paket < 300 kr  -> KAYNAK YOK  (üretici konuyu kaynak borcuna yazar, soru BASILMAZ)
#     300-999 kr      -> ZAYIF       (üretici dayanaksız ikinci arama dener)
#     >= 1000 kr      -> GÜÇLÜ       (12.09 ölçümü: 1.000 kr altında her üç sorudan biri "kaynak cevabı desteklemiyor" diye düşüyor)
#  16.09 İLGİ: eşikler paketin TAMAMINA değil, konu köklerini taşıyan bloklarına uygulanır; paket dolu ama ilgili kısım < 300 kr -> İLGİSİZ.
#  Fonksiyonlar üreticiden AST ile AYIKLANIR (kopya kod yok, üretici değişirse ölçüm de değişir); ödemeli hiçbir yol yüklenmez.
#  Kullanım:
#     powershell -NoProfile -File arac/smmm-kaynak-olcum.ps1 -Plan veri/sinav/plan-smmm-dalga1.json -Sinav SMMM -Parca 8 -Yaz
#  Çıktı: veri/sinav/<sinav>-kaynak-olcumu.json (-Yaz) + ekrana ders ders özet. -Parca paralel süreç sayısı (varsayılan 8).
#  ÜÇ SINAV (16.09): araç SGS ve KGK planlarını da ölçer (-Sinav). Dosya adı "smmm-" ile başlıyor ama iş üçü içindir;
#  ad değişimi SGS oturumunun koşan işini kırmasın diye ertelendi (92 ile mutabık kalınca arac/sinav-kaynak-olcum.ps1 olacak).
# ============================================================================
param([string]$Plan = 'veri/sinav/plan-smmm-dalga1.json', [int]$Parca = 8, [switch]$Yaz, [string]$Cikti = '',
  # 16.09 (Cem "1.2.3 üçünü de yap", GM 3): araç ÜÇ SINAVA da açıldı — SGS oturumu kendi kopyasını çıkarmıştı, iki kopya ayrışmasın diye
  # tek araç + -Sinav. Değişen yalnız: köprü süzgeci, konu-dayanak haritası (yalnız bitirmede var) ve çıktı dosyası adı. Ölçüm yolu aynı.
  [ValidateSet('SMMM', 'SGS', 'KGK')][string]$Sinav = 'SMMM',
  [string]$PaketDok = '',   # 16.09: doluysa her konunun paketi bu klasöre yazılır (ilgi ölçütünü ağsız ayarlamak için)
  [int]$Bastan = 0, [int]$Bitis = 0, [switch]$Ic, [switch]$OzSinav)   # -Ic: paralel alt süreç · -OzSinav: aracın kendisi sağlam mı (2 bilinen konu, plan okumaz, dosya yazmaz)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$planYol = $(if ([IO.Path]::IsPathRooted($Plan)) { $Plan } else { Join-Path $depoKok $Plan })
if (-not (Test-Path $planYol)) { throw "plan dosyası yok: $planYol" }

# --- plandaki konular: ders + ad + kaç soru ---
$planSatir = @(foreach ($r in (Get-Content $planYol -Raw -Encoding UTF8 | ConvertFrom-Json)) { $r })
$konuSay = [ordered]@{}
foreach ($r in $planSatir) {
  $kd = $(if ([IO.Path]::IsPathRooted("$($r.konuDosya)")) { "$($r.konuDosya)" } else { Join-Path $depoKok "$($r.konuDosya)" })
  if (-not (Test-Path $kd)) { continue }
  foreach ($k in @((Get-Content $kd -Raw -Encoding UTF8 | ConvertFrom-Json))) {
    $ad = $(if ($k -is [string]) { "$k" } else { "$($k.konu)" }); if (-not $ad) { continue }
    $anahtar = "$($r.ders)|$ad"
    if (-not $konuSay.Contains($anahtar)) { $konuSay[$anahtar] = 0 }
    $konuSay[$anahtar] = $konuSay[$anahtar] + [int]1
  }
}
$hedefler = @($konuSay.Keys)
# 16.09 ÖZ-SINAV (Cem "1.2.3 üçünü de yap", GM 3): araç bugün iki kez SESSİZCE boş sonuç verdi (paralel çağrıda boşluklu yol tırnaklanmamıştı).
# Bu kip iki BİLİNEN konuyu ölçer ve paketin dolu gelmesini şart koşar: biri kanun dayanaklı (VUK m.315), biri THP dayanaklı.
# Ambar ya da desen yolu bozulduysa ilk koşuda anlaşılır; dosyaya hiçbir şey yazılmaz.
if ($OzSinav) {
  # bitirmede kanun dayanaklı konu "Vergi", SGS/KGK'da aynı konu "Finansal Muhasebe" dersinde duruyor
  $hedefler = $(if ($Sinav -eq 'SMMM') { @('Vergi Mevzuatı ve Uygulaması|amortisman ayirma', 'Maliyet Muhasebesi|satilan mamul maliyeti') } else { @('Finansal Muhasebe|amortisman ayirma', 'Maliyet Muhasebesi|satilan mamul maliyeti') })
  $konuSay = @{}; foreach ($h in $hedefler) { $konuSay[$h] = 1 }
}
if (-not $Ic -and -not $OzSinav -and $Parca -gt 1) {
  # --- paralel: kendini $Parca alt süreçle çağır, sonra birleştir ---
  $gecici = Join-Path $env:TEMP "smmm-kaynak-olcum-$(Get-Date -Format yyyyMMdd-HHmmss)"
  New-Item -ItemType Directory -Force $gecici | Out-Null
  $boy = [math]::Ceiling($hedefler.Count / $Parca)
  "KAYNAK ÖLÇÜMÜ: $($hedefler.Count) konu · $Parca paralel süreç · plan $Plan (model çağrısı yok, bedel 0)"
  $isler = @()
  foreach ($p in 1..$Parca) {
    $b = ($p - 1) * $boy; $e = [math]::Min($p * $boy, $hedefler.Count); if ($b -ge $e) { continue }
    # yol BOŞLUK içerebilir (OneDrive\Masaüstü\mevzuat işi): Start-Process argümanları kendimiz tırnaklarız, yoksa alt süreç sessizce ölür ve sonuç BOŞ döner (16.09 ölçüldü)
    $cikYol = Join-Path $gecici "p$p.jsonl"
    $arg = @('-NoProfile', '-File', ('"' + $PSCommandPath + '"'), '-Plan', ('"' + $planYol + '"'), '-Sinav', $Sinav, '-PaketDok', ('"' + $PaketDok + '"'), '-Ic', '-Bastan', "$b", '-Bitis', "$e", '-Cikti', ('"' + $cikYol + '"'))
    $isler += Start-Process powershell -PassThru -WindowStyle Hidden -ArgumentList $arg
  }
  foreach ($is in $isler) { $is.WaitForExit() }
  $sonuc = New-Object System.Collections.Generic.List[object]
  foreach ($f in (Get-ChildItem $gecici -Filter '*.jsonl')) { foreach ($l in (Get-Content $f.FullName -Encoding UTF8)) { if ($l) { $sonuc.Add(($l | ConvertFrom-Json)) } } }
  if ($sonuc.Count -eq 0) { throw "PARALEL KOŞU BOŞ DÖNDÜ ($gecici) — ölçüm dosyası EZİLMEDİ. Alt süreçler başlamamış olabilir; -Parca 1 ile tek süreçte koşun." }
  if ($sonuc.Count -lt [math]::Floor($hedefler.Count * 0.9)) { throw "PARALEL KOŞU EKSİK: $($sonuc.Count) / $($hedefler.Count) — ölçüm dosyası EZİLMEDİ." }
}
else {
  # --- ölçüm: üreticinin fonksiyonlarını AST ile ayıkla, ambarı oku ---
  $metin = [IO.File]::ReadAllText((Join-Path $depoKok 'motor\kalip-parti-uret.ps1'), [Text.Encoding]::UTF8)
  $tk = $null; $er = $null; $ast = [Management.Automation.Language.Parser]::ParseInput($metin, [ref]$tk, [ref]$er)
  if ($er.Count) { throw "üretici ayrıştırılamadı: $($er[0].Message)" }
  $istenenF = @('Katla2', 'PaketTavani', 'PaketKirp', 'AmbarCek', 'KaraMi', 'HalefStandart', 'DersKanunAnahtari', 'DesenUret')
  $parcaKod = New-Object System.Collections.Generic.List[string]
  foreach ($st in $ast.EndBlock.Statements) {
    $t = $st.Extent.Text
    if ($st -is [Management.Automation.Language.FunctionDefinitionAst] -and $istenenF -contains $st.Name) { $parcaKod.Add($t); continue }
    if ($t -match '^\$(DERS_KANUN|STANDART_HALEF|KANUN|KARA_DAYANAK|klYol|OZEL_DESEN)\s*=' -or $t -match '^if\(Test-Path \$klYol\)') { $parcaKod.Add($t) }
  }
  $kok = $depoKok; $EskiPaketTavani = $false
  $KEY = $env:SUPABASE_SERVICE_KEY; if (-not $KEY) { throw 'SUPABASE_SERVICE_KEY yok' }
  $SB = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
  . ([scriptblock]::Create(($parcaKod -join "`n")))
  function Write-Host { }   # ayıklanan fonksiyonların ekran çıktısı susturulur
  $hd = @{}
  $hdYol = Join-Path $depoKok 'veri\sinav\smmm-konu-dayanak.json'   # elle okunmuş madde haritası YALNIZ bitirmede var; öteki sınavlarda boş kalır (üretici de öyle davranır)
  if ($Sinav -eq 'SMMM' -and (Test-Path $hdYol)) { foreach ($z in @((Get-Content $hdYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular)) { if ("$($z.durum)" -eq 'MADDE OKUNDU' -and "$($z.dayanak)".Trim()) { $hd[(Katla2 "$($z.konu)")] = @("$($z.dayanak)".Trim(), "$($z.dayanak2)".Trim()) } } }
  $kopru = @{}; foreach ($x in (Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { if ($x.sinav -eq $Sinav -and -not $kopru.ContainsKey((Katla2 $x.konu))) { $kopru[(Katla2 $x.konu)] = $x } }
  # ilgi ölçütünün dolgu kelimeleri: konuyu ayırt etmeyen, her kaynakta geçebilecek sözcükler (katlanmış yazımla)
  $ILGI_DUR = @('icin', 'veya', 'gore', 'olan', 'sartlari', 'sartlar', 'sureleri', 'suresi', 'turleri', 'turu', 'tanimi', 'tanimlari', 'tanimlar', 'kavrami', 'kavram', 'hesabi', 'hesaplama', 'hesaplanmasi', 'kaydi', 'kayit', 'kayitlari', 'uygulamasi', 'uygulama', 'esaslari', 'genel', 'halleri', 'hukumleri', 'ornekleri', 'islemleri', 'islemi', 'yontemi', 'sistemi', 'ttk', 'vuk', 'tbk', 'ozellikleri', 'ozellikler', 'ozellik', 'haklari', 'hakki', 'unsuru', 'unsurlari', 'ile', 'olarak', 'bir', 'her', 'dis', 'ici')
  function IlgiKatla([string]$s) { (Katla2 $s) -replace 'â', 'a' -replace 'î', 'i' -replace 'û', 'u' }
  $sonuc = New-Object System.Collections.Generic.List[object]
  $i = 0
  foreach ($anahtar in $hedefler) {
    $i++; if ($i -le $Bastan) { continue }; if ($Bitis -gt 0 -and $i -gt $Bitis) { break }
    $bol = $anahtar.LastIndexOf('|'); $ders = $anahtar.Substring(0, $bol); $ad = $anahtar.Substring($bol + 1)   # 16.09 (92 bildirdi): ders regexi 'A|B' olabilir → SON '|'tan böl; konu adında '|' yok
    $DersRegex = $ders
    $ky = $(if ($kopru.ContainsKey((Katla2 $ad))) { $kopru[(Katla2 $ad)].PSObject.Copy() } else { [pscustomobject]@{ sinav = $Sinav; konu = $ad; bizim_ders = ''; arsiv_ders = ''; dayanak = ''; cikmis_dayanak = ''; guc = ''; donem = 1 } })
    $kopruVar = $kopru.ContainsKey((Katla2 $ad))
    # 16.09: üreticiyle aynı — okunmuş harita köprünün dolu dayanağını da ezer, 'dayanak2' çıkmış dayanağın yerine geçer (motor/kalip-parti-uret.ps1)
    if ($hd.ContainsKey((Katla2 $ad))) { $hdIki = $hd[(Katla2 $ad)]; $ky.dayanak = $hdIki[0]; $ky.cikmis_dayanak = $hdIki[1]; $ky.guc = 'SMMM KONU-DAYANAK HARITASI (okunmus madde)' }
    $paket = ''; $adlar = @(); $hata = ''; $desen = @()
    try { $desen = @(DesenUret $ky); $script:AMBAR_AG_HATASI = $null; $amb = AmbarCek $desen; $paket = "$($amb.metin)"; $adlar = @($amb.adlar); if ($amb.agHatasi) { $hata = 'AG' } }
    catch { $hata = "HATA: $($_.Exception.Message)" }
    # 16.09 İLGİ ÖLÇÜTÜ (Cem "1.2.3 üçünü de yap", GM 1; ölçüt SGS oturumu 92 ile ortak): boy tek başına yalan söylüyordu —
    # "otv ilk iktisap" paketi 16.715 kr klasik iktisat notuydu, "cari oran" TMS 2 (stoklar), "idari yargi sureleri" TTK maddeleri; hepsi GÜÇLÜ yazılıyordu.
    # Paket bloklara ayrılır ("[ad] metin", "---" ile birleşik); blok, konu köklerini BAŞLIĞINDA ya da metninin İLK 400 karakterinde taşıyorsa ilgilidir.
    # Kök = anlamlı kelimenin (≥3 harf: çek, KDV, SPK kök sayılır) ilk 5 harfi (katlanmış), yalnız kelime başında eşleşir ('cek' 'gercek'te sayılmaz). En çok 3 kök varsa hepsi, daha çoksa en az 3 kök geçmeli. Durum İLGİLİ boydan çıkar.
    $kokler = @((IlgiKatla $ad) -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 3 -and $ILGI_DUR -notcontains $_ } | ForEach-Object { $_.Substring(0, [math]::Min(5, $_.Length)) } | Select-Object -Unique)
    $gerek = [math]::Min($kokler.Count, 3)   # 16.09 sıkılaştı: "yarısı" kuralı genel köklerle (bolge, gorev, serma, vergi) yanlış GÜÇLÜ veriyordu — "bölge idare mahkemesi görevleri" TTK maddeleriyle geçmişti
    $ilgiliBoy = 0; $ilgiliSay = 0; $ilgisizAd = New-Object System.Collections.Generic.List[string]; $ilgiliAd = New-Object System.Collections.Generic.List[string]
    foreach ($blok in @($paket -split "`n---`n")) {
      if (-not $blok) { continue }
      $bas = IlgiKatla ($blok.Substring(0, [math]::Min($blok.Length, 400 + ($blok.IndexOf(']') + 1))))
      $tut = @($kokler | Where-Object { $bas -match ('(?<![a-z0-9])' + [regex]::Escape($_)) }).Count   # yalnız KELİME BAŞINDA: 'cek' 'gercek'te sayılmaz (16.09 ölçüldü)
      if ($kokler.Count -eq 0 -or $tut -ge $gerek) { $ilgiliBoy += $blok.Length; $ilgiliSay++; if ($blok -match '^\[([^\]]+)\]') { $ilgiliAd.Add($matches[1]) } }
      elseif ($blok -match '^\[([^\]]+)\]') { $ilgisizAd.Add($matches[1]) }
    }
    if ($PaketDok) { $pdAd = ((($ders.Substring(0, [math]::Min(12, $ders.Length))) + '__' + $ad) -replace '[^\w\-]', '_') + '.txt'; [IO.File]::WriteAllText((Join-Path $PaketDok $pdAd), $paket, [Text.UTF8Encoding]::new($false)) }
    $durum = $(if ($hata -eq 'AG') { 'OLCULEMEDI-AG' } elseif ($hata) { 'OLCULEMEDI' } elseif ($paket.Length -lt 300) { 'KAYNAK YOK' } elseif ($ilgiliBoy -ge 1000) { 'GUCLU' } elseif ($ilgiliBoy -ge 300) { 'ZAYIF' } else { 'ILGISIZ' })
    $kayit = [ordered]@{ ders = $ders; konu = $ad; soru = [int]$konuSay[$anahtar]; durum = $durum; paketBoy = $paket.Length; ilgiliBoy = $ilgiliBoy; ilgiliKaynak = $ilgiliSay; kokler = ($kokler -join ' '); ilgisizKaynak = (@($ilgisizAd | Select-Object -First 4) -join ' ; '); ilgiliKaynakAd = (@($ilgiliAd | Select-Object -First 4) -join ' ; '); kaynakSayi = $adlar.Count
      kopruKaydi = $kopruVar; dayanak = "$($ky.dayanak)"; cikmisDayanak = "$($ky.cikmis_dayanak)"; desenSayi = $desen.Count
      ilkDesen = (@($desen | Select-Object -First 3) -join ' ; '); kaynaklar = (@($adlar | Select-Object -First 3) -join ' ; ') }
    $sonuc.Add([pscustomobject]$kayit)
    if ($Cikti) { [IO.File]::AppendAllText($Cikti, (($kayit | ConvertTo-Json -Depth 4 -Compress) + "`r`n"), [Text.UTF8Encoding]::new($false)) }
  }
  if ($Ic) { return }
}

# --- öz-sınav: ölçüm yolu çalışıyor mu? ---
if ($OzSinav) {
  $bos = @($sonuc | Where-Object { [int]$_.paketBoy -lt 300 })
  foreach ($s in $sonuc) { "  {0,-42} paket {1,6} kr · kaynak {2} · {3}" -f $s.konu, $s.paketBoy, $s.kaynakSayi, $s.durum }
  if ($bos.Count) { throw "ÖZ-SINAV DÜŞTÜ: $($bos.Count)/$($sonuc.Count) bilinen konuda paket 300 kr altında — desen üretimi ya da ambar yolu bozuk. Ölçüm KOŞULMASIN." }
  "ÖZ-SINAV TAMAM: $($sonuc.Count)/$($sonuc.Count) bilinen konuda paket dolu geldi (araç sağlam)."; exit 0
}
# --- özet ---
$sonucDizi = $sonuc.ToArray()   # K3: @(List[object]) tr-TR PS 5.1'de ArgumentException atar; her iki kip de List döndürür
"ÖLÇÜLEN KONU: $($sonucDizi.Count) · plan: $Plan"
foreach ($g in @($sonucDizi | Group-Object durum | Sort-Object Count -Descending)) { "  {0,-14} {1,5} konu · {2,5} soru" -f $g.Name, $g.Count, (($g.Group | Measure-Object soru -Sum).Sum) }
""
"DERS DERS (konu sayısı):"
foreach ($g in @($sonucDizi | Group-Object ders | Sort-Object Name)) {
  $y = @($g.Group | Where-Object { $_.durum -eq 'KAYNAK YOK' }); $z = @($g.Group | Where-Object { $_.durum -eq 'ZAYIF' }); $gu = @($g.Group | Where-Object { $_.durum -eq 'GUCLU' }); $ilg = @($g.Group | Where-Object { $_.durum -eq 'ILGISIZ' })
  "  {0,-46} güçlü {1,4} · zayıf {2,3} · İLGİSİZ {5,3} · KAYNAK YOK {3,3} ({4} soru)" -f $g.Name.Substring(0, [math]::Min(46, $g.Name.Length)), $gu.Count, $z.Count, $y.Count, (($y | Measure-Object soru -Sum).Sum), $ilg.Count
}
if ($Yaz -or ($Cikti -and -not $Ic)) {   # 16.09 (92 bildirdi): -Cikti tek başına verilince dosya YAZILMIYORDU; -Cikti yazma isteğidir
  . (Join-Path $depoKok 'arac\rapor-yaz.ps1')
  $hedefYol = $(if ($Cikti -and -not $Ic) { $Cikti } else { Join-Path $depoKok "veri\sinav\$($Sinav.ToLowerInvariant())-kaynak-olcumu.json" })
  # 16.09 ÖLÇÜLDÜ: dar bir planı ölçmek kütüğü BUDUYORDU — 2.095 konuluk dosya 880'e düştü ve içinde plan süzgecinin dayandığı
  # 14 "KAYNAK YOK" kaydı da silindi (süzgeç körleşir, elenen konu bir sonraki planda geri girerdi). Artık kütük BİRLEŞTİRİLİR:
  # eski kayıtlar korunur, bu koşudaki konular üzerine yazılır. Ayrı bir dosyaya (-Cikti) yazarken birleştirme YAPILMAZ.
  $birlesik = [ordered]@{}
  $eskiSay = 0
  if (-not $Cikti -and (Test-Path $hedefYol)) {
    foreach ($z in @((Get-Content $hedefYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular)) { $birlesik["$($z.ders)|$($z.konu)"] = $z; $eskiSay++ }
  }
  foreach ($z in $sonucDizi) { $birlesik["$($z.ders)|$($z.konu)"] = $z }
  $tumu = @($birlesik.Values)
  if ($eskiSay) { "  kütük birleştirildi: eski $eskiSay + bu koşu $($sonucDizi.Count) -> $($tumu.Count) konu" }
  $nesne = [ordered]@{
    aciklama = "$Sinav kaynak ölçümü: planın her konusu için üreticinin DesenUret + AmbarCek yolu koşuldu, ambardan dönen paketin uzunluğu ölçüldü. GUCLU >= 1000 kr · ZAYIF 300-999 · KAYNAK YOK < 300 (üretici bu eşikte konuyu kaynak borcuna yazar). Model çağrısı yok. Dosya BİRİKİMLİDİR: her koşu yalnız kendi planının konularını tazeler."
    sinav    = $Sinav; plan = $Plan; olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); konu = $tumu.Count; sonKosuKonu = $sonucDizi.Count
    ozet     = [ordered]@{}; konular = $tumu
  }
  foreach ($g in @($tumu | Group-Object durum)) { $nesne.ozet[$g.Name] = $g.Count }
  RaporYaz -Hedef $hedefYol -Nesne $nesne
}
