# ============================================================================
#  DERS PROFİLİ KURUCU (01.09.2026 gece — Cem: "PROFİLLERİ KUR")
#  Her sınav×ders için "GERÇEK ders" tanımını ÜÇ AYAKTAN derler (LLM'siz):
#   1) RESMÎ : 2-DERSLER dayanakları + SPL resmî alt-konu listesi
#   2) ÇIKMIŞ: köprüden o dersin en çok çıkan konuları (fiilî müfredat)
#   3) DAYANAK PARMAK İZİ: dersin tipik mevzuat ailesi (köprü anahtarlarından)
#  Çıktı: veri/ders-profili.json zenginleşir (FMuh'un ONAYLI tarifi korunur;
#  diğer derslere TASLAK oto-tarif, _onay=BEKLIYOR) + Cem okuması için
#  sql-yerel/DERS-PROFILLERI-TASLAK.md. KAPI C her partide bu profili okur.
# ============================================================================
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\dayanak-normalize.ps1')
$profYol=Join-Path $kok 'veri\ders-profili.json'
$prof=Get-Content $profYol -Raw -Encoding UTF8 | ConvertFrom-Json
$tam=Get-Content (Join-Path $kok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$scr='C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\91e7f169-5d28-4e43-8ef7-85757545867c\scratchpad'

function Katla([string]$s){
  ("$s" -creplace 'İ','I' -creplace 'ı','i' -creplace 'Ğ','G' -creplace 'ğ','g' `
        -creplace 'Ü','U' -creplace 'ü','u' -creplace 'Ş','S' -creplace 'ş','s' `
        -creplace 'Ö','O' -creplace 'ö','o' -creplace 'Ç','C' -creplace 'ç','c').ToUpperInvariant().Trim()
}
# sinav kisa-ad esleme (kopru 'SGS/SMMM/KGK' kullanir)
function SinavKisa([string]$tamAd){
  $k=Katla $tamAd   # Turkce G/I katlamasi sart ('BAGIMSIZ' ASCII, ad 'BAĞIMSIZ')
  if($k -match 'SGS|STAJA'){ return 'SGS' }
  if($k -match 'YETERLILIK|SMMM'){ return 'SMMM' }
  if($k -match 'BAGIMSIZ|KGK'){ return 'KGK' }
  return ''
}
# SPL resmî alt-konu listesi (3-SPL ALT KONU cekimi scratchpad'te)
$splAlt=@{}
$sekYol=Join-Path $scr 'harita-sekmeler.json'
if(Test-Path $sekYol){
  $paket=Get-Content $sekYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($r in ($paket.'3-SPL ALT KONU' | Select-Object -Skip 1)){
    $ders="$($r[1])".Trim()
    if(-not $splAlt.ContainsKey($ders)){ $splAlt[$ders]=New-Object System.Collections.Generic.List[string] }
    $splAlt[$ders].Add("$($r[3])".Trim())
  }
}

$md=[Text.StringBuilder]::new()
[void]$md.AppendLine("# DERS PROFİLLERİ — TASLAK (Cem onayına)")
[void]$md.AppendLine("*(01.09.2026 — üç ayak: resmî dayanak · çıkmış konular · dayanak parmak izi. Her derse ✅ ver ya da tarifi düzelt; FMuh zaten ONAYLI.)*`n")
$dolan=0
foreach($svAd in @($prof.sinavlar.PSObject.Properties.Name)){
  $kisa=SinavKisa $svAd
  [void]$md.AppendLine("`n## $svAd`n")
  foreach($dAd in @($prof.sinavlar.$svAd.PSObject.Properties.Name)){
    $dp=$prof.sinavlar.$svAd.$dAd
    # 'd) Bankacilik Mevzuati' gibi madde-onekleri eslesmeyi bozar - cekirdegi al
    $dCek=($dAd -replace '^[a-zA-ZçğıöşüÇĞİÖŞÜ]\)\s*','' -replace '\s*\[\d+\]\s*$','').Trim()
    $dKat=Katla $dCek
    # 2) cikmis konular + 3) dayanak parmak izi (kopruden)
    $tipik=@(); $aile=@()
    if($kisa){
      # 03.09 KUSUR (bosluk partisi hakemi yakaladi): -match ALT DIZI eslestiriyordu - 'maliye'
      # 'maliyetmuhasebesi'nin icinde gectigi icin MALIYE profiline maliyet muhasebesi konulari
      # doldu ("ortak maliyet dagitimi" Maliye'nin tipik konusu sanildi; gercek Maliye sorusu
      # DERS-DISI diye reddedildi). Ders adi ' / ' ile birlesik arsiv etiketlerinde parca parca
      # TAM ESITLIK ile aranir.
      # (KGK f/g: arsiv etiketi "Kurumsal Surdurulebilirlik Raporlamasi VE Denetimi" iki dersi
      #  birden kapsar -> etiket dKat ile baslayip 'VE' ile devam ediyorsa da esler; 'MALIYE'+'T...' eslemez)
      $kayitlar=@($tam | Where-Object { $_.sinav -eq $kisa -and $_.donem -ge 1 -and ( ((Katla "$($_.bizim_ders)") -eq $dKat) -or (@(("$($_.arsiv_ders)" -split ' / ') | ForEach-Object { Katla $_ } | Where-Object { $_ -eq $dKat -or $_.StartsWith($dKat+' VE ') -or $_.EndsWith(' VE '+$dKat) -or $_.Contains(' VE '+$dKat+' VE ') }).Count -gt 0) ) })
      $tipik=@($kayitlar | Sort-Object donem -Descending | Select-Object -First 20 | ForEach-Object { "$($_.konu) ($($_.donem)d)" })
      $aile=@($kayitlar | Where-Object { $_.cikmis_dayanak_anahtar } | Group-Object cikmis_dayanak_anahtar | Sort-Object Count -Descending | Select-Object -First 8 | ForEach-Object { "$($_.Name) ($($_.Count))" })
    }
    # 1) SPL resmi alt-konu (varsa tarif icin hazir malzeme)
    $resmiAlt=@()
    foreach($sk in $splAlt.Keys){ if((Katla $sk) -eq $dKat){ $resmiAlt=@($splAlt[$sk]) } }
    $dp | Add-Member -NotePropertyName cikmis_tipik_konular -NotePropertyValue $tipik -Force
    $dp | Add-Member -NotePropertyName dayanak_ailesi -NotePropertyValue $aile -Force
    if($resmiAlt.Count){ $dp | Add-Member -NotePropertyName resmi_alt_konular -NotePropertyValue $resmiAlt -Force }
    # taslak tarif (ONAYLI olana el degmez; BEKLIYOR taslagi taze veriyle yeniden kurulur)
    if($dp.PSObject.Properties['_onay'] -and "$($dp._onay)" -match 'BEKLIYOR'){ $dp.kapsam_tarifi='' }
    # 03.09: OTOMATIK kurulmus tarif ("Resmi ders: ..." ile baslar) yanlis tipik konu tasiyorsa
    # (Maliye <- maliyet muhasebesi) yeniden kurulur; Cem'in ELLE yazdigi tarif (bu onekle
    # baslamaz) korunur. Onay etiketi korunur, duzeltme notu eklenir.
    $eskiOnay=$(if($dp.PSObject.Properties['_onay']){ "$($dp._onay)" } else { '' })
    $otoTarif=("$($dp.kapsam_tarifi)" -match '^Resmi ders: ')
    if($otoTarif -and $tipik.Count){ $dp.kapsam_tarifi='' }
    if(-not $dp.kapsam_tarifi){
      $parca=New-Object System.Collections.Generic.List[string]
      $parca.Add("Resmi ders: $dAd ($svAd). Liste dayanagi: $($dp.liste_dayanagi).")
      if($resmiAlt.Count){ $parca.Add("RESMI ALT-KONULAR: "+(@($resmiAlt | Select-Object -First 12) -join '; ')+".") }
      if($tipik.Count){ $parca.Add("SINAVDA TIPIK CIKANLAR: "+(@($tipik | Select-Object -First 12 | ForEach-Object { ($_ -replace ' \(\d+d\)','') }) -join '; ')+".") }
      if($aile.Count){ $parca.Add("TIPIK DAYANAK AILESI: "+(@($aile | Select-Object -First 5 | ForEach-Object { ($_ -replace ' \(\d+\)','') }) -join '; ')+".") }
      $dp | Add-Member -NotePropertyName kapsam_tarifi -NotePropertyValue ($parca -join ' ') -Force
      $yeniOnay=$(if($eskiOnay -match 'ONAYLI'){ ($eskiOnay -replace ' · tipik konular 03\.09 düzeltildi','') + ' · tipik konular 03.09 düzeltildi' } else { 'BEKLIYOR' })
      $dp | Add-Member -NotePropertyName _onay -NotePropertyValue $yeniOnay -Force
      $dolan++
    } else {
      $dp | Add-Member -NotePropertyName _onay -NotePropertyValue 'ONAYLI (Cem 01.09)' -Force
    }
    # MD blok
    [void]$md.AppendLine("### $dAd  —  [$($dp._onay)]")
    [void]$md.AppendLine("- Soru sayısı: $($dp.soru_sayisi) · Hukuki dayanak: $($dp.hukuki_dayanak)")
    if($resmiAlt.Count){ [void]$md.AppendLine("- **Resmî alt-konu ($($resmiAlt.Count)):** "+(@($resmiAlt | Select-Object -First 8) -join ' · ')) }
    if($tipik.Count){ [void]$md.AppendLine("- **Çıkmışta tipik:** "+(@($tipik | Select-Object -First 10) -join ' · ')) }
    if($aile.Count){ [void]$md.AppendLine("- **Dayanak ailesi:** "+($aile -join ' · ')) }
    [void]$md.AppendLine("- **Tarif:** $($dp.kapsam_tarifi)")
    [void]$md.AppendLine("")
  }
}
[IO.File]::WriteAllText($profYol,(ConvertTo-Json -InputObject $prof -Depth 6),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $kok 'sql-yerel\DERS-PROFILLERI-TASLAK.md'),$md.ToString(),[Text.UTF8Encoding]::new($false))
"profil zenginlesti: $dolan derse taslak tarif | MD: sql-yerel/DERS-PROFILLERI-TASLAK.md"
