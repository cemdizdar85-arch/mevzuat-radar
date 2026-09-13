# ============================================================================
#  YURURLUK KONTROLU - SMMM YETERLILIK KLASIK ARSIVI   13.09.2026 (BEDAVA)
#
#  NEDEN (Cem 13.09 "3 yap"): SMMM 2026/1'de teste gecti; soru hazirlarken
#  2008-2025 klasik arsivden KONU alinacak. Eski kitapciklarin bir kismi
#  yururlukten kalkmis kanunlara dayanir. Konu alinabilir, HUKUM/RAKAM alinamaz.
#  Bu arac hangi (donem|ders) kitapciginin eski mevzuat baglaminda oldugunu
#  ve analizden gelen hangi konunun YALNIZ o eski kitapciklarda gorundugunu
#  isaretler -> konu plani bu konulari "guncel mevzuatta dogrula" diye tasir.
#
#  IKI ISARET:
#   (a) METIN: kitapcik metninde mulga kanun numarasi/teblig atfi geciyor
#       (veri/smmm-arsiv/txt - yalniz yerelde, gitignore)
#   (b) DONEM: dersin dayandigi kanun o sinavdan SONRA degisti
#  Degisim tarihleri kanunlarin RG/yururluk tarihidir; her satirda yazili.
#  CIKTI: veri/yururluk-kontrolu-smmm.json + veri/YURURLUK-KONTROLU-SMMM.md
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$txtKlasor = Join-Path $depoKok 'veri\smmm-arsiv\txt'
if(-not (Test-Path $txtKlasor)){ Write-Host 'KOR: veri/smmm-arsiv/txt yok (yalniz yerelde). Dosyaya dokunulmadi.'; exit 0 }

# sinav sirasi: yil*10+donem. "once" = bu siradan KUCUK sinavlar eski mevzuatla.
# Sinir secimi: degisiklik tarihinden SONRA yapilan ilk sinav yeni mevzuatla sayilir.
$MULGA = @(
  @{ kod='6762-TTK';   desen='(?<!\d)6762(?!\d)';  yeni='6102 sayili TTK';  tarih='01.07.2012'; ilkYeniSinav=20122; dersler=@('06') },
  @{ kod='818-BK';     desen='(?<!\d)818\s*(sayi|say\u0131|s\.|B\.?K)'; yeni='6098 sayili TBK'; tarih='01.07.2012'; ilkYeniSinav=20122; dersler=@('06') },
  @{ kod='2499-SPKn';  desen='(?<!\d)2499(?!\d)';  yeni='6362 sayili SPKn'; tarih='30.12.2012'; ilkYeniSinav=20131; dersler=@('08') },
  @{ kod='506-SSK';    desen='(?<!\d)506\s*(sayi|say\u0131|s\.)'; yeni='5510 sayili SSGSSK'; tarih='01.10.2008'; ilkYeniSinav=20083; dersler=@('06') },
  @{ kod='1479-BagKur';desen='(?<!\d)1479(?!\d)';  yeni='5510 sayili SSGSSK'; tarih='01.10.2008'; ilkYeniSinav=20083; dersler=@('06') },
  @{ kod='5422-KVK';   desen='(?<!\d)5422(?!\d)';  yeni='5520 sayili KVK';  tarih='21.06.2006'; ilkYeniSinav=20063; dersler=@() },
  # eski SPK teblig serileri (Seri: I/IV/V/VIII/X/XI ... No: n) 6362 sonrasi II-/III-/V-/VI-/VII- serileriyle yenilendi;
  # tek tarih yok -> donem kurali yok, yalniz METIN isareti (2016/1-08 hala 'Seri: XI, No:1' atfi tasiyor - 13.09 olculdu)
  @{ kod='SPK-eski-seri'; desen='Seri\s*:?\s*[IVXL]{1,5}\s*,?\s*No\s*:?\s*\d+'; yeni='6362 sonrasi SPK teblig serileri (II-/III-/V-/VI-/VII-)'; tarih='2013-2014'; ilkYeniSinav=0; dersler=@() }
)

$analizYolu = Join-Path $depoKok 'veri\smmm-analiz.json'
$analiz = if(Test-Path $analizYolu){ [IO.File]::ReadAllText($analizYolu, [Text.Encoding]::UTF8) | ConvertFrom-Json } else { $null }
$analizHarita = @{}
if($analiz){ foreach($r in @($analiz.donemler)){ $kd = [regex]::Match("$($r.kaynakUrl)", '_(\d{2})\.pdf$').Groups[1].Value; $analizHarita["$($r.donem)|$kd"] = $r } }

$kitapciklar = New-Object System.Collections.Generic.List[object]
foreach($f in (Get-ChildItem $txtKlasor -Filter 'smmm_*.txt' | Where-Object { $_.Name -match '^smmm_(\d{4})_(\d)_(\d{2})\.txt$' } | Sort-Object Name)){
  $parca = [regex]::Match($f.Name, '^smmm_(\d{4})_(\d)_(\d{2})\.txt$')
  $yilN = [int]$parca.Groups[1].Value; $donemN = [int]$parca.Groups[2].Value; $dersKod = $parca.Groups[3].Value
  if($yilN -ge 2026){ continue }   # test donemi guncel
  $sira = $yilN * 10 + $donemN
  $metinTxt = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $isaretler = New-Object System.Collections.Generic.List[object]
  foreach($m in $MULGA){
    $adetMetin = [regex]::Matches($metinTxt, $m.desen, 'IgnoreCase').Count
    $donemEski = ($m.dersler -contains $dersKod) -and ($sira -lt $m.ilkYeniSinav)
    if($adetMetin -gt 0 -or $donemEski){
      $isaretler.Add([ordered]@{ mulga = $m.kod; yeni = $m.yeni; degisim = $m.tarih; metinde_atif = $adetMetin; donem_kurali = $donemEski })
    }
  }
  if($isaretler.Count -eq 0){ continue }
  $anh = "$yilN/$donemN|$dersKod"
  $konular = @()
  if($analizHarita.ContainsKey($anh)){ $konular = @($analizHarita[$anh].konuSayim.PSObject.Properties.Name) }
  $kitapciklar.Add([pscustomobject]@{ anahtar = $anh; sira = $sira; isaret = $isaretler.ToArray(); etiketli = $analizHarita.ContainsKey($anh); konu = $konular })
}

# Konu bazinda: konu YALNIZ isaretli kitapciklarda mi goruldu?
$yalnizEski = New-Object System.Collections.Generic.List[object]
$isaretliAnahtar = @{}; foreach($k in $kitapciklar){ $isaretliAnahtar[$k.anahtar] = $k }
if($analiz){
  $konuYer = @{}
  foreach($anh in $analizHarita.Keys){ foreach($kn in @($analizHarita[$anh].konuSayim.PSObject.Properties.Name)){ if(-not $konuYer.ContainsKey($kn)){ $konuYer[$kn] = New-Object System.Collections.Generic.List[string] }; $konuYer[$kn].Add($anh) } }
  foreach($kn in ($konuYer.Keys | Sort-Object)){
    $yerler = @($konuYer[$kn])
    $eskiYer = @($yerler | Where-Object { $isaretliAnahtar.ContainsKey($_) })
    if($eskiYer.Count -gt 0 -and $eskiYer.Count -eq $yerler.Count){
      $mulgalar = @($eskiYer | ForEach-Object { $isaretliAnahtar[$_].isaret | ForEach-Object { $_.mulga } } | Sort-Object -Unique)
      $yalnizEski.Add([ordered]@{ konu = $kn; donem = $yerler.Count; kitapcik = $yerler; mulga = $mulgalar })
    }
  }
}

$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  aciklama = 'SMMM klasik arsivinde yururlukten kalkmis mevzuat baglami. metinde_atif: kitapcik metninde mulga kanun/teblig numarasi gecme adedi; donem_kurali: dersin dayandigi kanun sinavdan sonra degisti. yalniz_eski_konular: analizde YALNIZ isaretli kitapciklarda gorulen konu -> konu planinda "guncel mevzuatta dogrula" isaretiyle tasinir, hukum/rakam eski kitapciktan alinmaz.'
  mulga_listesi = @($MULGA | ForEach-Object { [ordered]@{ kod = $_.kod; yeni = $_.yeni; degisim = $_.tarih; donem_kurali_dersleri = $_.dersler } })
  isaretli_kitapcik = $kitapciklar.Count
  etiketli_isaretli_kitapcik = @($kitapciklar | Where-Object { $_.etiketli }).Count
  yalniz_eski_konu_sayisi = $yalnizEski.Count
  kitapciklar = @($kitapciklar | ForEach-Object { [ordered]@{ anahtar = $_.anahtar; etiketli = $_.etiketli; isaret = $_.isaret; konu = $_.konu } })
  yalniz_eski_konular = $yalnizEski.ToArray()
}
$null = RaporYaz -Hedef (Join-Path $depoKok 'veri\yururluk-kontrolu-smmm.json') -Nesne $cikti -Derinlik 8 -Sessiz:$Sessiz

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# YURURLUK KONTROLU - SMMM klasik arsiv ($($cikti.olcum))")
[void]$md.AppendLine('')
[void]$md.AppendLine("Uretici: arac/yururluk-kontrolu-smmm.ps1 (0 USD). Isaretli kitapcik: **$($kitapciklar.Count)** (etiketli $($cikti.etiketli_isaretli_kitapcik)) - yalniz eski kitapciklarda gorulen konu: **$($yalnizEski.Count)**.")
[void]$md.AppendLine('')
[void]$md.AppendLine('| Mulga | Yerine | Degisim | Metinde atif olan kitapcik | Donem kuraliyla isaretli |')
[void]$md.AppendLine('|---|---|---|---:|---:|')
foreach($m in $MULGA){
  $metinli = @($kitapciklar | Where-Object { $_.isaret | Where-Object { $_.mulga -eq $m.kod -and $_.metinde_atif -gt 0 } }).Count
  $donemli = @($kitapciklar | Where-Object { $_.isaret | Where-Object { $_.mulga -eq $m.kod -and $_.donem_kurali } }).Count
  [void]$md.AppendLine("| $($m.kod) | $($m.yeni) | $($m.tarih) | $metinli | $donemli |")
}
[void]$md.AppendLine('')
[void]$md.AppendLine('## Yalniz eski kitapciklarda gorulen konular (plana "guncel mevzuatta dogrula" isaretiyle girer)')
[void]$md.AppendLine('')
if($yalnizEski.Count -eq 0){ [void]$md.AppendLine('- yok (ya da ilgili kitapciklar henuz etiketlenmedi)') }
foreach($y in $yalnizEski){ [void]$md.AppendLine("- $($y.konu) - $($y.donem) kitapcik ($(($y.kitapcik) -join ', ')) - $(($y.mulga) -join ', ')") }
[IO.File]::WriteAllText((Join-Path $depoKok 'veri\YURURLUK-KONTROLU-SMMM.md'), $md.ToString(), (New-Object Text.UTF8Encoding($false)))
if(-not $Sessiz){ Write-Host ("yururluk kontrolu: isaretli kitapcik {0} (etiketli {1}) - yalniz eski konu {2}" -f $kitapciklar.Count, $cikti.etiketli_isaretli_kitapcik, $yalnizEski.Count) }
