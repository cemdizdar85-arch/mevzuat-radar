# ============================================================================
#  YILLIK RAKAM NOBETI — 02.08.2026
#  Cem: "site yanlis soru cevap yanlis yonlendirme istemiyorum."
#
#  BOSLUK: H6 (Dayanak Bagi) kanun METNI degisince soruyu karantinaya aliyor.
#  Ama asgari ucret, SGK tavani, kidem tazminati tavani, yeniden degerleme
#  orani, amortisman/fatura haddi... bunlar kanun metni HIC DEGISMEDEN her yil
#  degisir. Kanun aynasi bunu goremez. (SGK 7,5 kat -> 9 kat dersi: kanuni
#  sabit eskir.) Bugun dogru olan "2026'da asgari ucret X TL" sorusu 1 Ocak'ta
#  sessizce yanlisa doner - sifir-yanlis sozunu asil tehdit eden budur.
#
#  NE YAPAR:
#   -olcum (VARSAYILAN): kasada YIL-BAGIMLI rakam iceren sorulari bulur,
#          yakalanan yila gore dokum cikarir. 0 USD, hicbir sey degistirmez.
#   -uygula: tespit yili GECMIS yil olan YAYINDAKI sorulari karantinaya ceker
#          (yayin=false + not). Ocak basinda cronla calisir; boylece yeni yila
#          eski rakamla soru tasinmaz. PATCH kullanir (kismi-upsert tuzagi).
#
#  YAKALAMA KURALI (acik, raporda da yazili):
#   Soru/siklar/aciklama icinde su kavramlardan biri VE bir yil (2020-2035)
#   ya da TL tutari geciyorsa soru yil-bagimlidir:
#     asgari ucret · SGK taban/tavan/prim · kidem tazminati tavani ·
#     yeniden degerleme · amortisman siniri/haddi · fatura duzenleme haddi ·
#     defter tutma haddi · beyanname siniri · istisna tutari · gecikme zammi orani
#
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY
#  Cikti: veri/yillik-rakam-nobeti.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$raporYol = Join-Path $kok 'veri/yillik-rakam-nobeti.json'
$buYil = [int](Get-Date -Format 'yyyy')

$reKavram = [regex]'(?i)asgari\s+[üu]cret|sgk\s+(taban|tavan|prim)|prime\s+esas\s+kazan[çc]|k[ıi]dem\s+tazminat[ıi]\s+tavan|yeniden\s+de[ğg]erleme|amortisman\s+(s[ıi]n[ıi]r|hadd)|fatura\s+(d[üu]zenleme\s+)?(s[ıi]n[ıi]r|hadd)|defter\s+tutma\s+hadd|beyanname\s+verme\s+s[ıi]n[ıi]r|istisna\s+tutar|gecikme\s+zamm[ıi]\s+oran'
$reYil    = [regex]'\b(20[2-3][0-9])\b'
$reTutar  = [regex]'\d{1,3}(?:\.\d{3})+(?:,\d+)?\s*TL'

# --- kasayi cek
$kasa = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,sinav,ders,konu,soru,siklar,aciklama,yayin&order=id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 180
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){ $kasa.Add($s) }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

$bagimli = New-Object System.Collections.Generic.List[object]
$eskiYilli = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $tam = "$($s.soru)"
  foreach($h in @('A','B','C','D','E')){ $tam += ' ' + "$($s.siklar.$h)" + ' ' + "$($s.aciklama.$h)" }
  if(-not $reKavram.IsMatch($tam)){ continue }
  if(-not ($reYil.IsMatch($tam) -or $reTutar.IsMatch($tam))){ continue }
  $yillar = @($reYil.Matches($tam) | ForEach-Object { [int]$_.Value } | Sort-Object -Unique)
  $enYeni = if($yillar.Count -gt 0){ ($yillar | Measure-Object -Maximum).Maximum } else { $null }
  $kavram = $reKavram.Match($tam).Value
  $kayit = [ordered]@{
    id="$($s.id)"; sinav="$($s.sinav)"; ders="$($s.ders)"; konu="$($s.konu)"
    kavram=$kavram; yil=$enYeni; yayinda=($s.yayin -eq $true)
  }
  $bagimli.Add($kayit)
  # eski yilli VE yayinda -> karantina adayi. Yili hic olmayan (yalniz tutarli)
  # sorular -uygula'da CEKILMEZ; yil ispati olmadan soru kapatilmaz (rakam
  # disiplini: suphe var diye degil, kanit var diye islem yapilir). Onlar
  # dokumde gorunur, GM okur.
  if($enYeni -and $enYeni -lt $buYil -and $s.yayin -eq $true){ $eskiYilli.Add($kayit) }
}
Write-Host ("Yil-bagimli soru: {0} | eski yilli + yayinda: {1}" -f $bagimli.Count, $eskiYilli.Count)

$cekilen = 0; $hata = 0
if($uygula -and $eskiYilli.Count -gt 0){
  foreach($e in $eskiYilli){
    $govde = @{ yayin = $false; yayin_notu = ("Yillik rakam nobeti: {0} yilina ait '{1}' rakami iceriyor, {2} yilinda eskimis olabilir - GM okuyacak ({3})" -f $e.yil, $e.kavram, $buYil, (Get-Date -Format 'dd.MM.yyyy')) } | ConvertTo-Json -Compress
    $w = Invoke-WebRequest -Uri ("${U}?id=eq." + [uri]::EscapeDataString($e.id)) -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
    if([int]$w.StatusCode -ge 400){ $hata++ } else { $cekilen++ }
  }
  Write-Host ("Karantinaya cekilen: {0} | hata: {1}" -f $cekilen, $hata)
}

$kavramOzet = $bagimli | Group-Object kavram | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ kavram=$_.Name; adet=$_.Count } }
$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($uygula){'UYGULA'}else{'OLCUM (0 USD)'})
  bu_yil = $buYil
  kasa = $kasa.Count
  yil_bagimli = $bagimli.Count
  eski_yilli_yayinda = $eskiYilli.Count
  karantinaya_cekilen = $cekilen
  hata = $hata
  kavram_dagilimi = @($kavramOzet)
  eski_yilli_liste = $eskiYilli.ToArray()
  yil_bagimli_liste = $bagimli.ToArray()
  kural = "Kavram (asgari ucret/SGK/kidem tavani/yeniden degerleme/amortisman-fatura-defter haddi/istisna/gecikme zammi) + yil ya da TL tutari = yil-bagimli. -uygula yalniz YIL ISPATI olan ve yili gecmis YAYINDAKI sorulari ceker."
}
$j = ConvertTo-Json -InputObject $ozet -Depth 5
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $raporYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("-> {0}" -f $raporYol)
