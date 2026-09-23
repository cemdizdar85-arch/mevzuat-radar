#requires -Version 5.1
<#
================================================================================
  SMMM ÜCRETSİZ SORU SEÇİMİ — her dersten N soru   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): bitirme ERKEN ERİŞİMLE açılıyor; kasadaki 2.702 SMMM sorusunun ücretsiz
  işaretlisi 0'dı (motor/kasa-smmm-yukle.js sabit false) → ücretsiz deneme/seviye testi boş gelirdi.
  Karar: her dersten 5, toplam 40.

  KAYNAK: rastgele DEĞİL — site oturumunun ELLE OKUDUĞU vitrin seçimi (veri/sinav/kaydir-secim/vitrin-smmm-secim.json),
  onun hariç listesi (arac/vitrin-haric.json: etiketi soruyla uyuşmayan / kökü bozuk) çıkarılarak. Ders içinde
  çıkmış dönem sayısı yüksek olan önce, konu tekrarsız. Vitrinde yetmeyen ders -Ek ile elle okunmuş kimlikle tamamlanır.
  ÇIKTI: veri/sinav/smmm-ucretsiz.json (yalnız kimlik + ders + konu adı; soru metni YOK).
  Ücretsiz satır herkese açık `ucretsiz_soru` görünümünden DOĞRU ŞIK OLMADAN okunur; cevap sunucuda (seviye_kontrol).

  🚫 GÖRMEZ: vitrin seçiminin kendisinin doğruluğunu (elle okuma site oturumunda); kimliğin kasada olup olmadığını
     (yükleyici kasaya yazarken bulunamayanı SAYAR).
  KULLANIM: powershell -NoProfile -File arac/smmm-ucretsiz-sec.ps1 [-DersBasi 5] [-Ek 'etiket/kp-XX|Ders|konu;etiket/kp-YY|Ders|konu'] [-Yaz]
================================================================================
#>
param([int]$DersBasi = 5, [string[]]$Ek = @(), [switch]$Yaz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-ders-adi.ps1')
$vitrin = @((Get-Content (Join-Path $kok 'veri\sinav\kaydir-secim\vitrin-smmm-secim.json') -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })
$haric = @{}
$hy = Join-Path $kok 'arac\vitrin-haric.json'
if (Test-Path $hy) { foreach ($p in (Get-Content $hy -Raw -Encoding UTF8 | ConvertFrom-Json).haric.PSObject.Properties) { $haric[$p.Name] = "$($p.Value)" } }
$secilen = New-Object System.Collections.Generic.List[object]; $dersSay = @{}
foreach ($g in ($vitrin | Group-Object ders | Sort-Object Name)) {
  $konuGorulen = @{}
  foreach ($s in ($g.Group | Sort-Object @{e = { [int]$_.donem }; Descending = $true }, etiket, id)) {
    $an = "$($s.etiket)/$($s.id)"
    if ($haric.ContainsKey($an) -or $konuGorulen.ContainsKey("$($s.konu)")) { continue }
    if ([int]$dersSay[$g.Name] -ge $DersBasi) { break }
    $konuGorulen["$($s.konu)"] = 1; $dersSay[$g.Name] = 1 + [int]$dersSay[$g.Name]
    $secilen.Add([pscustomobject][ordered]@{ id = $an; ders = $g.Name; konu = "$($s.konu)"; kaynak = 'vitrin (elle okundu)' })
  }
}
# -File ile çağrılınca dizi tek metin gelir: girdiler ';' ile de ayrılabilir
foreach ($e in @($Ek | ForEach-Object { "$_" -split ';' } | Where-Object { "$_".Trim() })) {
  $par = "$e" -split '\|', 3   # 'etiket/kp-XX|Ders|konu'
  if ($haric.ContainsKey($par[0])) { throw "ek kimlik hariç listesinde: $($par[0])" }
  if (@($secilen | Where-Object { $_.id -eq $par[0] }).Count) { continue }
  $ders = $(if ($par.Count -gt 1 -and $par[1]) { $par[1] } else { SmmmDersAdi (($par[0] -split '/')[0]) $null })
  $secilen.Add([pscustomobject][ordered]@{ id = $par[0]; ders = $ders; konu = $(if ($par.Count -gt 2) { $par[2] } else { '' }); kaynak = 'ek (GM elle okudu)' })
  $dersSay[$ders] = 1 + [int]$dersSay[$ders]
}
"ÜCRETSİZ SEÇİM: $($secilen.Count) soru · " + (($dersSay.Keys | Sort-Object | ForEach-Object { "$_ $($dersSay[$_])" }) -join ' · ')
foreach ($d in ($dersSay.Keys | Where-Object { $dersSay[$_] -lt $DersBasi })) { "  EKSİK: $d $($dersSay[$d])/$DersBasi (vitrinde yetmedi — -Ek ile tamamla)" }
if ($Yaz) {
  $nesne = [ordered]@{ aciklama = 'SMMM ücretsiz katman: her dersten ' + $DersBasi + ' soru (Cem 23.09). Üreten arac/smmm-ucretsiz-sec.ps1; motor/kasa-smmm-yukle.js bu kimlikleri ucretsiz işaretler. Soru metni YOK.'; kimlikler = $secilen.ToArray() }
  [IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\smmm-ucretsiz.json'), (ConvertTo-Json -InputObject $nesne -Depth 4), (New-Object Text.UTF8Encoding $false))
  'yazıldı: veri/sinav/smmm-ucretsiz.json'
}
