#requires -Version 5.1
<#
================================================================================
  KISIR KONU ÖLÇÜMÜ — "parayı yiyip soru vermeyen konu" listesi   18.09.2026
  Bedel 0 (yalnız yerel parti dosyaları + ret kütüğü okunur).

  NİYE VAR (Cem 17.09, para harcayan soru basımı kuralı md. 5: "ilgi hakeminden
  geçmemiş konu basılmaz"): kural YAZILIYDI, mekanik karşılığı YOKTU. 18.09'da
  ölçüldü — bitirmede 3.176 üretilen taslağın 1.929'u yayına girdi (%60,7), ama
  32 konuda en az 3 soru denendi ve HİÇBİRİ yayına girmedi (180 taslak,
  üretilenin %5,7; üretilen soru başı 0,077 USD ile ≈14 USD). Bu konular her
  turda yeniden plana giriyor ve aynı parayı yeniden yakıyor.

  ⚠ NE DEĞİL: bu bir kalite kısıtı değil. Listeye giren konudan bugüne kadar
  TEK soru çıkmadı; yani kapı yayına giren hiçbir soruyu düşürmez. Konunun
  kaynağı ambara yutulduğunda liste yeniden ölçülür ve konu kendiliğinden
  geri döner (dosya türetilmiştir, elle düzenlenmez).

  ⚠ ÖLÇÜM SMMM'YE ÖZEL: geçme ölçütü arac/smmm-yayin-sarti.ps1. SGS/KGK için
  kendi yayın şartlarıyla ayrı ölçüm gerekir; dosya yoksa kapı çalışmaz.

  ⭐ 21.09.2026 — İKİNCİ KURAL: KAYNAK BORCU (Cem "1 ve 2 yap").
  Ölçüldü: SMMM dalgalarında hakem reddinin 151/242'si (%62) "paket, cevabı
  destekleyen HÜKMÜ taşımıyor" gerekçesiyle geldi. Teşhis edildi — bu bir
  kırpma/montaj kusuru DEĞİL: reddedilen soruların paketi yayına girenlerle
  aynı boyda (medyan 10.133 ↔ 10.538 karakter) ve konuyu aynı oranda taşıyor
  (%89,4 ↔ %94,0). Yani kaynak ambarda GERÇEKTEN eksik; aynı konuya ikinci kez
  para vermek aynı reddi satın almaktır.

  Yeni kural: bir konu KAYNAK-EKSIK/KESIK gerekçesiyle en az `-KaynakRedEsik`
  kez reddedilmiş VE bugüne kadar hiç yayına girmemişse plana alınmaz.
  ⚠ EŞİK NEDEN "VE yayına giren = 0" ŞARTLI: yalnız "kaynak reddi ≥ 2" deseydik
  120 konu düşerdi ve bunların 215 YAYINA GİRMİŞ sorusu vardı — kapı çalışan
  konuları da keserdi. Şartlı hâlde yanlış alarm bedeli ÖLÇÜLEN 0 sorudur.

  Bu konular `veri/KAYNAK-BORCU.md`'ye iş emri olarak yazılır: kaynağı yutulan
  konu bir sonraki ölçümde listeden kendiliğinden düşer.

  KULLANIM
    powershell -NoProfile -File arac/kisir-konu-olc.ps1            # ölç + yaz
    powershell -NoProfile -File arac/kisir-konu-olc.ps1 -EnAzDeneme 5
  ÖZ-SINAV
    powershell -NoProfile -File arac/kisir-konu-sinavi.ps1
================================================================================
#>
param(
  [int]$EnAzDeneme = 3,          # bu kadar soru denenmiş olmalı (altı "ölçülmedi")
  [int]$KaynakRedEsik = 2,       # 21.09: bu kadar KAYNAK-EKSIK/KESIK reddi + hiç yayın yoksa da düşer
  [string]$Sinav = 'SMMM'
)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
if ($Sinav -ne 'SMMM') { throw "Bu ölçüm bugün yalnız SMMM için var (yayın şartı SMMM'ye özel). İstenen: $Sinav" }
. (Join-Path $depoKok 'arac\smmm-yayin-sarti.ps1')

$durum = @{}
$dosyaSay = 0
foreach ($f in (Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json' -ErrorAction SilentlyContinue)) {
  $dosyaSay++
  $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($p in $j.PSObject.Properties) {
    $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $k = "$($v.konu)".Trim().ToLowerInvariant(); if (-not $k) { continue }
    if (-not $durum.ContainsKey($k)) { $durum[$k] = [pscustomobject]@{ konu = $k; denenen = 0; gecen = 0; ke = 0 } }
    $durum[$k].denenen++
    if ((SmmmYayinSarti "$($f.Name)/$($p.Name)" $v @{}).gecer) { $durum[$k].gecen++ }
  }
}
if ($dosyaSay -lt 50) { throw "parti dosyası az ($dosyaSay) — ambardan indirilmemiş olabilir; ölçüm yazılmadı (arac/parti-senkron.ps1 -Indir -Yaz -Sinav SMMM -OnEk 'smmm-')" }

$retYol = Join-Path $depoKok 'veri\ret-kutugu.json'
$gerekce = @{}
if (Test-Path $retYol) {
  foreach ($kay in @((Get-Content $retYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar | ForEach-Object { $_ })) {
    # 21.09: KESIK de sayılır — "paket ortadan kesik" de kaynak borcudur (11.09 ret ölçümü).
    if ("$($kay.etiket)" -notlike 'smmm-*' -or "$($kay.sinif)" -notin 'KAYNAK-EKSIK', 'KAYNAK-KESIK') { continue }
    $k = "$($kay.konu)".Trim().ToLowerInvariant()
    if ($k -and $durum.ContainsKey($k)) {
      $durum[$k].ke++
      if (-not $gerekce.ContainsKey($k)) { $gerekce[$k] = "$($kay.gerekce)" }
    }
  }
}

# ⭐ SEÇİM KURALI AYRI FONKSİYONDA: öz-sınav bunu AST ile çıkarıp KOŞAR (replika yasak —
#   20.09 dersi: KAPI-Ç replikası %99,8 dedi, gerçek fonksiyon %0,6).
# 🚫 BU SEÇİM ŞUNU GÖRMEZ: (a) konu adının farklı yazımlarını — "sebepsiz zenginleşme" ile
#   "sebepsiz zenginleşme davası" iki ayrı konu sayılır, biri düşerken öteki kalabilir;
#   (b) kaynağın ambara YENİ yutulmuş olmasını — ret kütüğü geçmişi taşır, konu bir sonraki
#   ölçüme kadar düşük kalır; (c) hakemin gerekçesinin DOĞRU olup olmadığını.
function KisirSecimi($kayitlar, [int]$enAzDeneme, [int]$kaynakRedEsik) {
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($x in @($kayitlar)) {
    if ([int]$x.gecen -gt 0) { continue }          # yayına giren varsa ASLA düşmez
    $neden = ''
    if ([int]$x.denenen -ge $enAzDeneme) { $neden = 'KISIR' }
    elseif ($kaynakRedEsik -gt 0 -and [int]$x.ke -ge $kaynakRedEsik) { $neden = 'KAYNAK-BORCU' }
    if (-not $neden) { continue }
    if ([int]$x.denenen -ge $enAzDeneme -and [int]$x.ke -ge $kaynakRedEsik -and $kaynakRedEsik -gt 0) { $neden = 'KISIR+KAYNAK-BORCU' }
    $out.Add([pscustomobject]@{ konu = $x.konu; denenen = [int]$x.denenen; ke = [int]$x.ke; neden = $neden })
  }
  return @($out.ToArray())
}

$hepsi = @($durum.Values)
$toplamD = ($hepsi | Measure-Object denenen -Sum).Sum
$toplamG = ($hepsi | Measure-Object gecen -Sum).Sum
$kisir = @(KisirSecimi $hepsi $EnAzDeneme $KaynakRedEsik | Sort-Object denenen -Descending)
$kisirD = ($kisir | Measure-Object denenen -Sum).Sum
$borcluSay = @($kisir | Where-Object { $_.neden -like '*KAYNAK-BORCU*' }).Count

Write-Host ("konu {0:N0} · denenen taslak {1:N0} · yayına giren {2:N0} (%{3})" -f $hepsi.Count, $toplamD, $toplamG, [math]::Round(100 * $toplamG / [double][math]::Max(1, $toplamD), 1)) -ForegroundColor Cyan
Write-Host ("DÜŞEN konu {0} (kaynak borçlusu {1}) · boşa giden taslak {2} (üretilenin %{3}) · KAYNAK-EKSIK/KESIK reti {4}" -f `
    $kisir.Count, $borcluSay, $kisirD, [math]::Round(100 * $kisirD / [double][math]::Max(1, $toplamD), 1), ($kisir | Measure-Object ke -Sum).Sum) -ForegroundColor Yellow
foreach ($x in ($kisir | Select-Object -First 12)) { Write-Host ("  {0,-42} denendi {1,3} · kaynak reddi {2,2} · {3}" -f $x.konu.Substring(0, [math]::Min(42, $x.konu.Length)), $x.denenen, $x.ke, $x.neden) }
if ($kisir.Count -gt 12) { Write-Host ("  ... ve {0} konu daha" -f ($kisir.Count - 12)) }

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
# ⛔ RaporYaz $true/$false DONER: yakalanmazsa ekrana "True" sizar ve betik dokunmadigi
#   dosya icin de "yazildi" der (CLAUDE.md: kendi 'yazildi' mesajini basmak yasak).
$yazildiJson = RaporYaz -Hedef (Join-Path $depoKok 'veri\sinav\kisir-konu-smmm.json') -Nesne ([ordered]@{
    olcum        = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    aciklama     = "Plana ALINMAYAN konular. İki kural: (1) KISIR = en az $EnAzDeneme soru denenmiş, hiçbiri yayın şartını geçmemiş; (2) KAYNAK-BORCU = hakem en az $KaynakRedEsik kez 'paket cevabı destekleyen hükmü taşımıyor' demiş ve konu hiç yayına girmemiş. İkisinde de ORTAK ŞART: yayına giren = 0 — kapı çalışan hiçbir konuyu düşürmez. motor/plandan-parti-kur.ps1 bu listeyi okur. Türetilmiştir, elle düzenlenmez; kaynağı yutulan konu yeniden ölçümde listeden düşer. İş emri: veri/KAYNAK-BORCU.md"
    kural        = "(denenen >= $EnAzDeneme VEYA kaynakReddi >= $KaynakRedEsik) VE yayına giren = 0"
    olculen      = [ordered]@{ konu = $hepsi.Count; denenen = $toplamD; gecen = $toplamG; partiDosyasi = $dosyaSay }
    kisirKonu    = $kisir.Count
    kaynakBorclu = $borcluSay
    kisirTaslak  = $kisirD
    konular      = @($kisir | ForEach-Object { [ordered]@{ konu = $_.konu; denenen = $_.denenen; kaynakEksik = $_.ke; neden = $_.neden } })
  })
if (-not $yazildiJson) { Write-Host "veri/sinav/kisir-konu-smmm.json: icerik ayni, dosyaya dokunulmadi" -ForegroundColor DarkGray }

# --- İŞ EMRİ: kaynağı yutulunca geri dönecek konular (para ile çözülmez, yutma ile çözülür) ---
$borclu = @($kisir | Where-Object { $_.neden -like '*KAYNAK-BORCU*' } | Sort-Object ke -Descending)
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# KAYNAK BORCU — yutulacak mevzuat iş emri')
$md.Add('')
$md.Add("> Türetilmiştir (``arac/kisir-konu-olc.ps1``), elle düzenlenmez. Ölçüm: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$md.Add('')
$md.Add('Buradaki konular **para ile çözülmez**. Hakem bu konularda "paket, cevabı destekleyen hükmü')
$md.Add('taşımıyor" dedi; teşhis edildi ki paket kırpılmıyor, boyu da yayına giren sorularınkiyle aynı —')
$md.Add('kaynak ambarda gerçekten yok. Aynı konuya ikinci kez soru bastırmak aynı reddi satın almaktır.')
$md.Add('Kaynağı yutulan konu bir sonraki ölçümde bu listeden **kendiliğinden düşer** ve plana geri döner.')
$md.Add('')
$md.Add("**Toplam: $($borclu.Count) konu · bu konularda bugüne kadar $(($borclu | Measure-Object denenen -Sum).Sum) taslak denendi, $(($borclu | Measure-Object ke -Sum).Sum) kaynak reddi alındı, yayına giren 0.**")
$md.Add('')
$md.Add('| konu | denenen | kaynak reddi | hakemin söylediği eksik (ilk gerekçe) |')
$md.Add('|---|---:|---:|---|')
foreach ($b in $borclu) {
  $g = "$($gerekce[$b.konu])" -replace '\s+', ' '
  if ($g.Length -gt 180) { $g = $g.Substring(0, 180) + '…' }
  $g = $g -replace '\|', '/'
  $md.Add(("| {0} | {1} | {2} | {3} |" -f $b.konu, $b.denenen, $b.ke, $g))
}
$md.Add('')
[IO.File]::WriteAllText((Join-Path $depoKok 'veri\KAYNAK-BORCU.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
Write-Host "yazildi: veri/KAYNAK-BORCU.md ($($borclu.Count) konu)" -ForegroundColor Green
