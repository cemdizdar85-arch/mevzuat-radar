#requires -Version 5.1
<#
================================================================================
  KGK ANALIZ - ETIKETTEN DONEM EKLE   (19.09.2026, Cem "2 ve 3 yap")

  NEDEN: veri/kgk-analiz.json 19.08'den beri "donemler[].konuSayim" bicimindedir ve
  ELLE etiketten kuruldu. motor/kgk-siklik-derle.ps1 bu bicimi URETMEZ (kendi 06.08
  bicimini ayri dosyaya yazar - korumali). Yani yeni bir sinav etiketlendiginde
  haritaya girmesinin yolu yoktu; 11 Kasim 2018 (8166) bu yuzden haritaya girmiyordu.

  NE YAPAR (bedel 0, API yok): veri/kgk-arsiv/etiket/*.json okur; haritada KARSILIGI
  OLMAYAN her etiket dosyasi icin donemler[] kaydi kurar:
    donem  = etiketteki donem · kitapcik = etiketteki kitapcik · toplamSoru = soru adedi
    konuSayim["<modul>|<konu>"] = o konudan kac soru · yontem/analizTarihi = iz
  MEVCUT KAYITLARA DOKUNMAZ (-Yenile verilirse ayni donem+kitapcik kaydini tazeler).
  Varsayilan KURU PROVA; yazmak icin -Yaz.

  KULLANIM
    powershell -NoProfile -File arac/kgk-analiz-donem-ekle.ps1            # olc
    powershell -NoProfile -File arac/kgk-analiz-donem-ekle.ps1 -Yaz       # yaz
  Sonra: powershell -NoProfile -File motor/siklik-kunyesi.ps1 -Sinav KGK  (kunye)
================================================================================
#>
param(
  [switch]$Yaz,
  [switch]$Yenile,
  [string]$Kod = ''      # yalniz bu etiket dosyasi (dosya adi, ornek: 8166)
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$analizYolu = Join-Path $depoKok 'veri\kgk-analiz.json'
$etiketKlasoru = Join-Path $depoKok 'veri\kgk-arsiv\etiket'
if(-not (Test-Path $analizYolu)){ Write-Host 'KOR: veri/kgk-analiz.json yok.'; exit 1 }
if(-not (Test-Path $etiketKlasoru)){ Write-Host 'KOR: veri/kgk-arsiv/etiket yok.'; exit 1 }

$analiz = Get-Content $analizYolu -Raw -Encoding UTF8 | ConvertFrom-Json
$mevcut = @{}
foreach($d in @($analiz.donemler)){ $mevcut["$($d.donem)|$($d.kitapcik)"] = $d }
Write-Host ("Haritada donem kaydi: {0}" -f @($analiz.donemler).Count)

$eklenecek = New-Object System.Collections.Generic.List[object]
$dosyalar = @(Get-ChildItem $etiketKlasoru -Filter '*.json')
if($Kod){ $dosyalar = @($dosyalar | Where-Object { $_.BaseName -eq $Kod }) }
foreach($ed in $dosyalar){
  $etk = Get-Content $ed.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  $anah = "$($etk.donem)|$($etk.kitapcik)"
  $tekrar = $mevcut.ContainsKey($anah)
  # ayni donem baska kitapcik adiyla zaten varsa da atla (elle kurulan kayitlarin kitapcik alani bos olabilir)
  $donemVar = @(@($analiz.donemler) | Where-Object { "$($_.donem)" -eq "$($etk.donem)" }).Count -gt 0
  if(($tekrar -or $donemVar) -and -not $Yenile){ continue }
  $sayim = [ordered]@{}
  foreach($s in @($etk.sorular)){
    $k = "$($s.modul)|$($s.konu)"
    if($sayim.Contains($k)){ $sayim[$k] = [int]$sayim[$k] + 1 } else { $sayim[$k] = 1 }
  }
  $eklenecek.Add([pscustomobject]@{
    dosya = $ed.Name
    kayit = [ordered]@{
      donem        = "$($etk.donem)"
      kitapcik     = "$($etk.kitapcik)"
      toplamSoru   = @($etk.sorular).Count
      konuSayim    = $sayim
      yontem       = "etiket dosyasi: veri/kgk-arsiv/etiket/$($ed.Name)"
      analizTarihi = (Get-Date -Format 'dd.MM.yyyy')
    }
  })
}
if(-not $eklenecek.Count){ Write-Host 'Eklenecek donem yok (harita etiketlerle ortusuyor).'; exit 0 }
foreach($e in $eklenecek){ Write-Host ("  EKLENECEK: {0} · {1} soru · {2} tekil konu" -f $e.kayit.donem, $e.kayit.toplamSoru, @($e.kayit.konuSayim.Keys).Count) }
if(-not $Yaz){ Write-Host "`nKURU PROVA - yazmak icin -Yaz"; exit 0 }

$liste = New-Object System.Collections.Generic.List[object]
foreach($d in @($analiz.donemler)){ if($Yenile -and @($eklenecek | Where-Object { $_.kayit.donem -eq "$($d.donem)" }).Count){ continue }; $liste.Add($d) }
foreach($e in $eklenecek){ $liste.Add([pscustomobject]$e.kayit) }
$yeni = [ordered]@{
  aciklama   = "$($analiz.aciklama)"
  guncelleme = (Get-Date -Format 'dd.MM.yyyy') + ' (etiketten donem eklendi: ' + (@($eklenecek | ForEach-Object { $_.kayit.donem }) -join ', ') + ')'
  donemler   = $liste.ToArray()   # K3: @(List) + -InputObject ArgumentException atar
}
[IO.File]::WriteAllText($analizYolu, [string](ConvertTo-Json -InputObject $yeni -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("YAZILDI: donem {0} -> {1} · {2}" -f @($analiz.donemler).Count, $liste.Count, $analizYolu)
