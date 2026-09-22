#requires -Version 5.1
<#
================================================================================
  SMMM (BİTİRME) KONU / BASIM EXCEL'İ — 22.09.2026 · bedel 0 (model yok, ağ yok)

  Cem 22.09: "exceli yap ve ona göre soru çıkaralım · ben böyle biliyordum,
  bunu kural olarak yazalım."

  NİYE VAR: SGS'nin ve KGK'nın basım Excel'i vardı, BİTİRMENİN YOKTU. Bitirme
  planları bugüne kadar bu tablo olmadan kuruldu ve sonuç 22.09'da ölçüldü:
  kapsam genişliğe gitmiş, SIKLIĞA gitmemişti — çıkmış sınavlarda 43 kez görülen
  "amortisman ayırma" konusunda 7 sorumuz, 31 kez görülen "bilanço düzenleme"de
  ve 25 kez görülen "şüpheli alacak karşılığı"nda SIFIR sorumuz vardı.

  GİRDİ : veri/fabrika/smmm-kapsama.csv  (arac/smmm-kapsama-tablosu.ps1 üretir)
  ÇIKTI : 1) <Masaüstü>\SMMM-Bitirme-Konu-Basim-Plani.xlsx   (Excel COM ile)
          2) veri/fabrika/SMMM-KAPSAMA-excel.csv             (BOM + ';' — Excel'de çift tıkla açılır)
  Excel kurulu değilse ya da -ExcelYok verilirse yalnız CSV yazılır, iş düşmez.

  SAYFALAR
    1 Özet          : ders ders konu / çıkmış / bizde / hedef / açık / engelli
    2 Konular       : bütün konular (süzgeçli) — asıl tablo
    3 Sıradaki basım: engelsiz, açığı olan konular çıkmış sırasına göre
    4 Engelliler    : kısır / kaynak borcu — bunlar PARA ile değil YUTMA ile çözülür
    5 Nasıl okunur  : sütunların anlamı ve körlükler

  🚫 BU TABLO ŞUNU GÖRMEZ: konu adının farklı yazımlarını tek konuya indirmez ·
    "çıkmış" köprüden gelir, köprü yanlışsa hedef de yanlıştır · ikiz süzgecinin
    yayında eleyeceğini görmez (yayinlanabilir = yayın şartı, ikiz kapısı değil).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/smmm-basim-excel.ps1
    ... -ExcelYok          (yalnız CSV)
    ... -Cikti <yol.xlsx>
================================================================================
#>
param(
  [string]$Cikti = 'C:\Users\cemdi\OneDrive\Masaüstü\SMMM-Bitirme-Konu-Basim-Plani.xlsx',
  [switch]$ExcelYok,
  [switch]$TabloYenile   # önce arac/smmm-kapsama-tablosu.ps1 koşar
)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$csvYol = Join-Path $depoKok 'veri\fabrika\smmm-kapsama.csv'

if ($TabloYenile -or -not (Test-Path $csvYol)) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'smmm-kapsama-tablosu.ps1') -Sessiz
  if ($LASTEXITCODE) { throw "kapsama tablosu üretilemedi ($LASTEXITCODE)" }
}
$satir = @(Import-Csv $csvYol -Encoding UTF8)
if ($satir.Count -lt 100) { throw "kapsama tablosu şüpheli küçük ($($satir.Count) satır) — ölçüm yazılmadı" }
foreach ($r in $satir) {
  $r | Add-Member -NotePropertyName cikmisN -NotePropertyValue ([int]$r.cikmis) -Force
  $r | Add-Member -NotePropertyName yayinN -NotePropertyValue ([int]$r.yayinlanabilir) -Force
  $r | Add-Member -NotePropertyName yazdikN -NotePropertyValue ([int]$r.yazdik) -Force
  $r | Add-Member -NotePropertyName hedefN -NotePropertyValue ([int]$r.hedef) -Force
  $r | Add-Member -NotePropertyName acikN -NotePropertyValue ([int]$r.acik) -Force
}
$engelsiz = @($satir | Where-Object { -not $_.engel })
$engelli = @($satir | Where-Object { $_.engel })
$siradaki = @($engelsiz | Where-Object { $_.acikN -gt 0 } | Sort-Object cikmisN, acikN -Descending)

# --- 1) CSV (Excel dostu: BOM + ';') ---
$csvExcel = Join-Path $depoKok 'veri\fabrika\SMMM-KAPSAMA-excel.csv'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('"ders";"konu";"sinavda_cikti";"yazdik";"yayinlanabilir";"hedef";"acik";"durum";"engel"')
foreach ($r in ($satir | Sort-Object @{e = { $_.ders } }, @{e = { $_.cikmisN }; Descending = $true })) {
  [void]$sb.AppendLine(('"{0}";"{1}";"{2}";"{3}";"{4}";"{5}";"{6}";"{7}";"{8}"' -f `
      ("$($r.ders)" -replace '"', ''''), ("$($r.konu)" -replace '"', ''''), $r.cikmisN, $r.yazdikN, $r.yayinN, $r.hedefN, $r.acikN, $r.durum, $r.engel))
}
[IO.File]::WriteAllText($csvExcel, $sb.ToString(), (New-Object Text.UTF8Encoding $true))
"CSV: veri/fabrika/SMMM-KAPSAMA-excel.csv ({0} satır)" -f $satir.Count

# --- 2) XLSX ---
if ($ExcelYok) { 'Excel atlandı (-ExcelYok)'; exit 0 }
$xl = $null
try { $xl = New-Object -ComObject Excel.Application } catch { Write-Host "Excel COM yok — yalnız CSV yazıldı: $($_.Exception.Message)" -ForegroundColor Yellow; exit 0 }
$xl.Visible = $false; $xl.DisplayAlerts = $false
function Tablo($sayfa, [string[]]$basliklar, $satirlarDizi, [scriptblock]$degerler, [int]$basSatir = 1) {
  $n = @($satirlarDizi).Count; $c = $basliklar.Count
  $dizi = New-Object 'object[,]' ($n + 1), $c
  for ($j = 0; $j -lt $c; $j++) { $dizi[0, $j] = $basliklar[$j] }
  $i = 1; foreach ($r in $satirlarDizi) { $v = @(& $degerler $r); for ($j = 0; $j -lt $c; $j++) { $dizi[$i, $j] = $v[$j] }; $i++ }
  $alan = $sayfa.Range($sayfa.Cells($basSatir, 1), $sayfa.Cells($basSatir + $n, $c)); $alan.Value2 = $dizi
  $bas = $sayfa.Range($sayfa.Cells($basSatir, 1), $sayfa.Cells($basSatir, $c)); $bas.Font.Bold = $true; $bas.Interior.Color = 0x5E3A1F; $bas.Font.Color = 0xFFFFFF; $bas.WrapText = $true
  [void]$alan.AutoFilter()
  [void]$sayfa.Columns.AutoFit()
  return $alan
}
try {
  $wb = $xl.Workbooks.Add()
  while ($wb.Worksheets.Count -lt 5) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
  $s1 = $wb.Worksheets.Item(1); $s1.Name = '1 Özet'
  $s2 = $wb.Worksheets.Item(2); $s2.Name = '2 Konular'
  $s3 = $wb.Worksheets.Item(3); $s3.Name = '3 Sıradaki basım'
  $s4 = $wb.Worksheets.Item(4); $s4.Name = '4 Engelliler'
  $s5 = $wb.Worksheets.Item(5); $s5.Name = '5 Nasıl okunur'

  $ozet = @($satir | Group-Object ders | Sort-Object { ($_.Group | Where-Object { -not $_.engel } | Measure-Object acikN -Sum).Sum } -Descending)
  [void](Tablo $s1 @('ders', 'konu', 'sınavda çıktı', 'yazdık', 'yayınlanabilir', 'hedef', 'açık (basılabilir)', 'açık ama engelli') $ozet {
      param($g)
      @($(if ($g.Name) { $g.Name } else { '(ders yok)' }), $g.Count,
        ($g.Group | Measure-Object cikmisN -Sum).Sum, ($g.Group | Measure-Object yazdikN -Sum).Sum,
        ($g.Group | Measure-Object yayinN -Sum).Sum, ($g.Group | Measure-Object hedefN -Sum).Sum,
        (($g.Group | Where-Object { -not $_.engel } | Measure-Object acikN -Sum).Sum),
        (($g.Group | Where-Object { $_.engel } | Measure-Object acikN -Sum).Sum))
    })
  $s1.Cells(($ozet.Count + 3), 1).Value2 = "Ölçüm: $(Get-Date -Format 'dd.MM.yyyy HH:mm') · üretici: arac/smmm-basim-excel.ps1 · hedef = sınavda çıktığı sayı × kat"
  $s1.Cells(($ozet.Count + 4), 1).Value2 = 'Bu dosya ELLE DÜZENLENMEZ; her koşuda yeniden yazılır.'

  [void](Tablo $s2 @('ders', 'konu', 'sınavda çıktı', 'yazdık', 'yayınlanabilir', 'hedef', 'açık', 'durum', 'engel') `
    (@($satir | Sort-Object @{e = { $_.ders } }, @{e = { $_.cikmisN }; Descending = $true })) {
      param($r) @($r.ders, $r.konu, $r.cikmisN, $r.yazdikN, $r.yayinN, $r.hedefN, $r.acikN, $r.durum, $r.engel)
    })
  [void](Tablo $s3 @('sıra', 'ders', 'konu', 'sınavda çıktı', 'yayınlanabilir', 'açık') `
    (@($siradaki | Select-Object -First 500)) {
      param($r) @(0, $r.ders, $r.konu, $r.cikmisN, $r.yayinN, $r.acikN)
    })
  for ($i = 2; $i -le ([Math]::Min(501, $siradaki.Count + 1)); $i++) { $s3.Cells($i, 1).Value2 = $i - 1 }
  [void](Tablo $s4 @('ders', 'konu', 'sınavda çıktı', 'yazdık', 'yayınlanabilir', 'engel nedeni') $engelli {
      param($r) @($r.ders, $r.konu, $r.cikmisN, $r.yazdikN, $r.yayinN, $r.engel)
    })

  $aciklama = @(
    @('sınavda çıktı', 'Konunun çıkmış SMMM/yeterlilik sınavlarında kaç kez göründüğü (konu köprüsü).'),
    @('yazdık', 'Parti dosyalarında o konuya yazılmış TASLAK sayısı (geçsin geçmesin).'),
    @('yayınlanabilir', 'Bu taslakların kaçı SMMM yayın şartını geçti (hakem + kör + hakem2 + simülasyon).'),
    @('hedef', 'sınavda çıktığı sayı × kat (varsayılan 3). Kat tartışmaya açıktır.'),
    @('açık', 'hedef − yayınlanabilir. Basılacak soru sayısı budur.'),
    @('engel', 'KISIR = en az 3 soru denendi, hiçbiri geçmedi. KAYNAK-BORCU = hakem en az 2 kez "paket hükmü taşımıyor" dedi. İkisi de PARA ile değil KAYNAK YUTMA ile çözülür.'),
    @('GÖRMEZ 1', 'Konu adının farklı yazımlarını tek konuya indirmez; aynı konu iki satırda görünebilir.'),
    @('GÖRMEZ 2', '"sınavda çıktı" köprüden gelir; köprü yanlışsa hedef de yanlıştır.'),
    @('GÖRMEZ 3', 'İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.'),
    @('KURAL', 'Basım planı BU TABLODAN kurulur: sıklık önce. Üretici: arac/smmm-plan-kur.ps1')
  )
  [void](Tablo $s5 @('sütun / not', 'anlamı') $aciklama { param($r) @($r[0], $r[1]) })

  if (Test-Path $Cikti) { Remove-Item $Cikti -Force -ErrorAction SilentlyContinue }
  $wb.SaveAs($Cikti, 51); $wb.Close($false)
  "EXCEL: $Cikti"
}
finally { if ($xl) { $xl.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl) } }
