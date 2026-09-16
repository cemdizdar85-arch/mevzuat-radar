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
#  Fonksiyonlar üreticiden AST ile AYIKLANIR (kopya kod yok, üretici değişirse ölçüm de değişir); ödemeli hiçbir yol yüklenmez.
#  Kullanım:
#     powershell -NoProfile -File arac/smmm-kaynak-olcum.ps1 -Plan veri/sinav/plan-smmm-dalga1.json -Parca 8 -Yaz
#  Çıktı: veri/sinav/smmm-kaynak-olcumu.json (-Yaz) + ekrana ders ders özet. -Parca paralel süreç sayısı (varsayılan 8).
# ============================================================================
param([string]$Plan = 'veri/sinav/plan-smmm-dalga1.json', [int]$Parca = 8, [switch]$Yaz, [string]$Cikti = '',
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
if ($OzSinav) { $hedefler = @('Vergi Mevzuatı ve Uygulaması|amortisman ayirma', 'Maliyet Muhasebesi|satilan mamul maliyeti'); $konuSay = @{}; foreach ($h in $hedefler) { $konuSay[$h] = 1 } }
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
    $arg = @('-NoProfile', '-File', ('"' + $PSCommandPath + '"'), '-Plan', ('"' + $planYol + '"'), '-Ic', '-Bastan', "$b", '-Bitis', "$e", '-Cikti', ('"' + $cikYol + '"'))
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
  $Sinav = 'SMMM'
  $hd = @{}; foreach ($z in @((Get-Content (Join-Path $depoKok 'veri\sinav\smmm-konu-dayanak.json') -Raw -Encoding UTF8 | ConvertFrom-Json).konular)) { if ("$($z.durum)" -eq 'MADDE OKUNDU' -and "$($z.dayanak)".Trim()) { $hd[(Katla2 "$($z.konu)")] = "$($z.dayanak)".Trim() } }
  $kopru = @{}; foreach ($x in (Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { if ($x.sinav -eq 'SMMM' -and -not $kopru.ContainsKey((Katla2 $x.konu))) { $kopru[(Katla2 $x.konu)] = $x } }
  $sonuc = New-Object System.Collections.Generic.List[object]
  $i = 0
  foreach ($anahtar in $hedefler) {
    $i++; if ($i -le $Bastan) { continue }; if ($Bitis -gt 0 -and $i -gt $Bitis) { break }
    $parcali = $anahtar -split '\|', 2; $ders = $parcali[0]; $ad = $parcali[1]
    $DersRegex = $ders
    $ky = $(if ($kopru.ContainsKey((Katla2 $ad))) { $kopru[(Katla2 $ad)].PSObject.Copy() } else { [pscustomobject]@{ sinav = 'SMMM'; konu = $ad; bizim_ders = ''; arsiv_ders = ''; dayanak = ''; cikmis_dayanak = ''; guc = ''; donem = 1 } })
    $kopruVar = $kopru.ContainsKey((Katla2 $ad))
    if ($hd.ContainsKey((Katla2 $ad)) -and -not "$($ky.dayanak)".Trim() -and -not "$($ky.cikmis_dayanak)".Trim()) { $ky.dayanak = $hd[(Katla2 $ad)]; $ky.guc = 'SMMM KONU-DAYANAK HARITASI (okunmus madde)' }
    $paket = ''; $adlar = @(); $hata = ''; $desen = @()
    try { $desen = @(DesenUret $ky); $script:AMBAR_AG_HATASI = $null; $amb = AmbarCek $desen; $paket = "$($amb.metin)"; $adlar = @($amb.adlar); if ($amb.agHatasi) { $hata = 'AG' } }
    catch { $hata = "HATA: $($_.Exception.Message)" }
    $durum = $(if ($hata -eq 'AG') { 'OLCULEMEDI-AG' } elseif ($hata) { 'OLCULEMEDI' } elseif ($paket.Length -ge 1000) { 'GUCLU' } elseif ($paket.Length -ge 300) { 'ZAYIF' } else { 'KAYNAK YOK' })
    $kayit = [ordered]@{ ders = $ders; konu = $ad; soru = [int]$konuSay[$anahtar]; durum = $durum; paketBoy = $paket.Length; kaynakSayi = $adlar.Count
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
  $y = @($g.Group | Where-Object { $_.durum -eq 'KAYNAK YOK' }); $z = @($g.Group | Where-Object { $_.durum -eq 'ZAYIF' }); $gu = @($g.Group | Where-Object { $_.durum -eq 'GUCLU' })
  "  {0,-46} güçlü {1,4} · zayıf {2,3} · KAYNAK YOK {3,3} ({4} soru)" -f $g.Name.Substring(0, [math]::Min(46, $g.Name.Length)), $gu.Count, $z.Count, $y.Count, (($y | Measure-Object soru -Sum).Sum)
}
if ($Yaz) {
  . (Join-Path $depoKok 'arac\rapor-yaz.ps1')
  $hedefYol = $(if ($Cikti -and -not $Ic) { $Cikti } else { Join-Path $depoKok 'veri\sinav\smmm-kaynak-olcumu.json' })
  $nesne = [ordered]@{
    aciklama = 'BİTİRME (SMMM) kaynak ölçümü: planın her konusu için üreticinin DesenUret + AmbarCek yolu koşuldu, ambardan dönen paketin uzunluğu ölçüldü. GUCLU >= 1000 kr · ZAYIF 300-999 · KAYNAK YOK < 300 (üretici bu eşikte konuyu kaynak borcuna yazar). Model çağrısı yok.'
    plan     = $Plan; olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); konu = $sonucDizi.Count
    ozet     = [ordered]@{}; konular = $sonucDizi
  }
  foreach ($g in @($sonucDizi | Group-Object durum)) { $nesne.ozet[$g.Name] = $g.Count }
  RaporYaz -Hedef $hedefYol -Nesne $nesne
}
