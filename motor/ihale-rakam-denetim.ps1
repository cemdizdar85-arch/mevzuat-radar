# ============================================================================
#  IHALE RAKAM DENETIMI - kaynak <-> JSON birebir dogrulama (14.08.2026)
#
#  Cem: "yanlis olmasin diye tekrar kontrol... rakamlar isimler dogru geliyor mu"
#       + "bu denetlemeyi aklimiza yazalim, her isten sonra bir kere kontrol."
#
#  NE YAPAR: bugunun bulten SONUC metnini taze indirir, JSON'daki (ihale-sonuc.json)
#  kayitlarla RASTGELE ornekleme birebir karsilastirir:
#    - Yaklasik Maliyet · Sozlesme Bedeli · Yuklenici adi · Teklif Sayisi
#    - Kirim orani (iki yazili tutardan ELLE yeniden hesaplanip karsilastirilir)
#  Ayrica firma normalize'inin FARKLI firmalari yanlis birlestirip birlestirmedigini
#  olcer. Uyusmazlik varsa KIRMIZI biter (exit 1).
#
#  NEDEN: doluluk orani "%100 dolu" demek DEGERIN dogru oldugunu gostermez. Parser
#  yanlis sayi cikarabilir. Bu betik, "raporu degil kaynagi oku" dersinin ihale
#  tarafindaki uygulamasidir. Her ihale/veri isinden sonra kosulur.
# ============================================================================
param([int]$Ornek = 15, [switch]$TazeIndir)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kls  = Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten"

$sonucYol = Join-Path $kok "veri\ihale-sonuc.json"
if(-not (Test-Path $sonucYol)){ Write-Host "ihale-sonuc.json yok"; exit 1 }
$s = @((Get-Content $sonucYol -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)

# JSON hangi bulten gununden? Kayitta bulten tarihi yok; taze indirip AYNI gun
# metniyle karsilastirmak en guvenlisi. -TazeIndir verilirse bugunun bulteni cekilir.
if($TazeIndir){
  Write-Host "Bugunun mal bulteni taze indiriliyor (JSON kaynagiyla ayni gun icin)..."
  & (Join-Path $here "ihale-bulten-hasat.ps1") -Turler Mal 2>&1 | Out-Null
}

$metinYol = Join-Path $kls "sonuc-mal.txt"
if(-not (Test-Path $metinYol)){ Write-Host "sonuc-mal.txt yok - -TazeIndir ile calistir"; exit 1 }
$duz = ([IO.File]::ReadAllText($metinYol,[Text.Encoding]::UTF8) -replace '\s+',' ')
$bultenGun = [regex]::Match($duz, '\d{1,2}\s+[A-ZÇĞİÖŞÜ]+\s+\d{4}\s*[–—-]\s*Sayı\s*\d+').Value
Write-Host ("Kaynak metin: {0}" -f $bultenGun)

function Sayi([string]$s){ if(-not $s){ return $null }; $x=($s -replace '\.','') -replace ',','.'; $d=0.0; if([double]::TryParse($x,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$d)){return $d}; return $null }

$bas = [regex]::Matches($duz, 'İhale kayıt numarası\s*:\s*(\d{4}/\d+)')
if(-not $bas.Count){ Write-Host "Metinde sonuc ilani bulunamadi"; exit 1 }
$sira = 0..($bas.Count-1) | Sort-Object { Get-Random }
$kontrol=0; $dogru=0; $hata=New-Object Collections.ArrayList
foreach($i in $sira){
  if($kontrol -ge $Ornek){ break }
  $ikn = $bas[$i].Groups[1].Value
  $bit = if($i+1 -lt $bas.Count){$bas[$i+1].Index}else{$duz.Length}
  $blok = $duz.Substring($bas[$i].Index, [math]::Min($bit-$bas[$i].Index, 1500))
  if($blok -match 'Sözleşmeye Esas Kısımlarının'){ continue }   # kisimli: kirim/maliyet karsilastirmasi guvenilmez
  $hYM  = Sayi ([regex]::Match($blok,'Yaklaşık Maliyeti\s*:\s*([\d.,]+)').Groups[1].Value)
  $hSB  = Sayi ([regex]::Match($blok,'b\)\s*Bedeli\s*:\s*([\d.,]+)').Groups[1].Value)
  $hYuk = ([regex]::Match($blok,'d\)\s*Yüklenicisi?\s*:\s*(.{5,90}?)\s*e\)').Groups[1].Value -replace '\s+',' ').Trim()
  $hTek = [regex]::Match($blok,'Toplam Teklif Sayısı\s*:?\s*(\d+)').Groups[1].Value
  if($null -eq $hSB){ continue }
  $kontrol++
  $jm = @($s | Where-Object { $_.ikn -eq $ikn -and $null -ne $_.sozlesmeBedeli -and [math]::Abs([double]$_.sozlesmeBedeli - $hSB) -lt 1 })
  if(-not $jm){ [void]$hata.Add("${ikn}: JSON'da bu bedelle kayit yok (ham SB=$hSB)"); continue }
  $j = $jm[0]
  $sorun = @()
  if($null -ne $hYM -and [math]::Abs([double]$j.yaklasikMaliyet - $hYM) -ge 1){ $sorun += "YM(json=$($j.yaklasikMaliyet) ham=$hYM)" }
  $jYuk = ("$($j.yuklenici)" -replace '\s+',' ').Trim()
  if(-not $jYuk.StartsWith($hYuk.Substring(0,[math]::Min(18,$hYuk.Length)))){ $sorun += "YUK(json=[$jYuk] ham=[$hYuk])" }
  if($hTek -and "$($j.teklifSayisi)" -ne $hTek){ $sorun += "TEKLIF(json=$($j.teklifSayisi) ham=$hTek)" }
  if($null -ne $j.kirimYuzde -and $hYM -and $hYM -gt 0){
    $elle = [math]::Round((1 - $hSB/$hYM)*100, 1)
    if([math]::Abs($elle - [double]$j.kirimYuzde) -ge 0.15){ $sorun += "KIRIM(json=$($j.kirimYuzde) elle=$elle)" }
  }
  if($sorun.Count){ [void]$hata.Add("${ikn}: " + ($sorun -join ' ')) } else { $dogru++ }
}

# firma normalize: ayni anahtara dusen FARKLI orijinal ad = yanlis birlestirme riski
function FA([string]$ad){ $a="$ad".ToUpper() -replace 'LİMİTED ŞİRKETİ','LTD ŞTİ' -replace 'ANONİM ŞİRKETİ','A Ş' -replace 'LTD\.?\s*ŞTİ\.?','LTD ŞTİ' -replace 'A\.?\s*Ş\.?','A Ş' -replace '[^A-ZÇĞİÖŞÜ0-9 ]',' ' -replace '\s+',' '; return $a.Trim() }
$ng=@{}; foreach($x in $s){ if($x.yuklenici){ $k=FA $x.yuklenici; if(-not $ng[$k]){$ng[$k]=@{}}; $ng[$k]["$($x.yuklenici)"]=1 } }
$yanlisBirlesme = @($ng.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }).Count

Write-Host ("`n=== RAKAM DENETIMI ===")
Write-Host ("  {0} ilan rastgele karsilastirildi · {1} DOGRU · {2} uyusmazlik" -f $kontrol, $dogru, $hata.Count)
Write-Host ("  firma normalize yanlis birlestirme: {0}" -f $yanlisBirlesme)
$hata | ForEach-Object { Write-Host ("  ! " + $_) }
if($hata.Count -gt 0 -or $yanlisBirlesme -gt 0){
  Write-Host "`nKIRMIZI: kaynak ile JSON arasinda uyusmazlik var - INCELE."
  exit 1
}
Write-Host "`nYESIL: ornekteki rakamlar/isimler kaynakla birebir ayni."
exit 0
