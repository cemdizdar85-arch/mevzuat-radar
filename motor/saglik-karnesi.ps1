# ============================================================================
#  VERİ SAĞLIĞI KARNESİ — MÜŞTERİ-YÜZLÜ (28.08 gece, Cem: "1 ve 2 yap")
#  Kaynak: ambar envanteri + sürüm karnesi -> KAMU-GÜVENLİ özet json.
#  GİZLİLİK SÜZGECİ: yalnız mevzuat/standart/kasa boyut metrikleri çıkar;
#  alacak/ihale/üye/lead SAYILARI BİLE ÇIKMAZ (gizli katman kuralı).
#  Sayfa: saglik.html bu json'u okur. Günlük görev 4. halka.
# ============================================================================
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$env=Get-Content (Join-Path $kok 'veri\fabrika\ambar-envanteri.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$srm=Get-Content (Join-Path $kok 'veri\fabrika\surum-tazeligi-karnesi.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$srmSat=@($srm.satirlar | % { $_ })
$tutarli=@($srmSat | ? { $_.durum -eq 'TUTARLI' }).Count
$olculen=@($srmSat | ? { $_.durum -notmatch 'ISTISNA' }).Count
$cikti=[ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  mevzuat_parca=[int]$env.toplam_parca
  kaynak_sayisi=[int]$env.tekil_kaynak
  standart_olculen=$olculen
  standart_birebir=$tutarli
  surum_olcum_tarihi="$($srm.tarih)"
  butunluk_olculen=[int]$env.butunluk_olculen
  aciklama='Bu sayilar her sabah 06:45''te insan eli degmeden, makine tarafindan yeniden olculur. UC SORU sorariz: VAR MI (canli sayim) - TAM MI (butunluk kapisi) - GUNCEL MI (resmi kaynak PDF''iyle birebir kiyas).'
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\saglik-karnesi.json'),(ConvertTo-Json -InputObject $cikti -Depth 3),[Text.UTF8Encoding]::new($false))
"saglik karnesi: mevzuat $($cikti.mevzuat_parca) parca | $($cikti.kaynak_sayisi) kaynak | standart $tutarli/$olculen birebir -> veri/saglik-karnesi.json"
