# ============================================================================
#  "DOGRUSU:" EKLEME — ESKI SORULAR (02.08.2026)
#  Cem: "bunu da her soruya, eski sorulara ekleyelim."
#
#  KURAL (SINAV-KURALLARI D2): her YANLIS sik aciklamasi, tuzagi adlandirdiktan
#  sonra "Dogrusu: <dayanaga dayali tek cumle>" ile biter. Ogretilmesi gereken
#  asil kisi YANLIS YAPANDIR; o sikki isaretleyen aday dogru kurali ayni
#  ekranda gormeli. Yeni uretimde makine kapisi var; ESKI sorularda yok.
#
#  IKI MOD:
#   -olcum  (VARSAYILAN, 0 USD): kac soruda var/yok, ders dagilimi, MALIYET
#           TAHMINI. Hicbir API cagrisi yapilmaz.
#   -uygula (PARALI): eksik olanlara Batch API ile "Dogrusu:" cumlesi yazdirir.
#           Cumle YALNIZCA dayanak metne dayanir (D4: olmayan kanun/oran yasak).
#           Yazim PATCH ile yalniz 'aciklama' kolonuna (kismi-upsert tuzagi).
#
#  ENV: SUPABASE_SERVICE_KEY (+ -uygula icin ANTHROPIC_API_KEY)
#  Cikti: veri/dogrusu-ekle-raporu.json
# ============================================================================
param([switch]$uygula, [int]$sinir = 0, [string]$model = 'claude-haiku-4-5-20251001')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$raporYol = Join-Path $kok 'veri/dogrusu-ekle-raporu.json'
$reDogrusu = [regex]'(?i)do[ğg]rusu\s*:'

# --- kasayi cek
$kasa = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  # 02.08: olcume TABLO/YEVMIYE de eklendi. Cem karari: calisma kagidi
  # ("senin kaydin / dogru kayit" karsilastirmasi) eski sorularda da calissin;
  # bunun icin sorunun DOGRU yevmiye/tablo verisi bulunmali. Ayni onarim
  # partisinde tamamlanacak - tek gonderim, tek odeme.
  $w = Invoke-WebRequest -Uri "${U}?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,tablo,yevmiye&order=id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){ $kasa.Add($s) }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- kimde var, kimde yok
$tam = 0; $eksik = 0; $okunamaz = 0
$eksikDers = @{}
$eksikListe = New-Object System.Collections.Generic.List[object]
# tablo/yevmiye sayimi (calisma kagidi karsilastirmasi icin gerekli)
$yevmiyeVar = 0; $tabloVar = 0; $hesapliSoru = 0; $hesapliAmaVerisiz = 0
$reHesapli = [regex]'(?i)kay[ıi]t|yevmiye|hesab[ıi]na|bor[cç]land|alacakland|tutar|maliyet bedeli|ne kadar|ka[cç] TL'
foreach($s in $kasa){
  if("$($s.yevmiye)".Trim().Length -gt 5){ $yevmiyeVar++ }
  if("$($s.tablo)".Trim().Length -gt 5){ $tabloVar++ }
  if($reHesapli.IsMatch("$($s.soru)")){
    $hesapliSoru++
    if("$($s.yevmiye)".Trim().Length -le 5 -and "$($s.tablo)".Trim().Length -le 5){ $hesapliAmaVerisiz++ }
  }
}
Write-Host ("yevmiye verisi olan: {0} | tablo verisi olan: {1}" -f $yevmiyeVar, $tabloVar)
Write-Host ("hesapli/kayitli soru: {0} | bunlardan tablo-yevmiye YOK: {1}" -f $hesapliSoru, $hesapliAmaVerisiz)
foreach($s in $kasa){
  $yanlisSik = @('A','B','C','D','E') | Where-Object { $_ -ne "$($s.dogru)" }
  $var = 0; $dolu = 0
  foreach($h in $yanlisSik){
    $a = "$($s.aciklama.$h)"
    if($a.Trim().Length -eq 0){ continue }
    $dolu++
    if($reDogrusu.IsMatch($a)){ $var++ }
  }
  if($dolu -eq 0){ $okunamaz++; continue }
  if($var -ge 3){ $tam++; continue }
  $eksik++
  $d = "$($s.ders)"; $eksikDers[$d] = 1 + [int]$eksikDers[$d]
  $eksikListe.Add($s)
}
Write-Host ("'Dogrusu:' TAM olan: {0} | EKSIK: {1} | aciklamasi okunamayan: {2}" -f $tam, $eksik, $okunamaz)

# --- maliyet tahmini (olculmus birim: ~3.000 giris + ~250 cikis token/soru,
#     Haiku batch fiyatiyla). Tahmindir; gercek fatura kosu sonunda yazilir.
$tahminUSD = [math]::Round($eksik * ((3000/1000000*0.40) + (250/1000000*2.00)) * 0.5, 2)

$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($uygula){'UYGULA'}else{'OLCUM (0 USD)'})
  kasa = $kasa.Count
  dogrusu_tam = $tam
  dogrusu_eksik = $eksik
  aciklama_okunamayan = $okunamaz
  eksik_ders_dagilimi = ($eksikDers.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { [ordered]@{ ders=$_.Key; adet=$_.Value } })
  yevmiye_verisi_olan = $yevmiyeVar
  tablo_verisi_olan = $tabloVar
  hesapli_soru = $hesapliSoru
  hesapli_ama_verisiz = $hesapliAmaVerisiz
  tahmini_maliyet_usd = $tahminUSD
  not = "Olcum modu API cagrisi YAPMAZ. -uygula ile eksik olanlara Batch API 'Dogrusu:' cumlesi yazar; cumle yalniz dayanak metne dayanir."
}
$j = ConvertTo-Json -InputObject $ozet -Depth 5
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $raporYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("TAHMINI MALIYET (eksikleri tamamlamak): ~{0} USD" -f $tahminUSD)
Write-Host ("-> {0}" -f $raporYol)
if(-not $uygula){ Write-Host "OLCUM MODU - hicbir istek atilmadi, 0 USD."; exit 0 }
Write-Host "UYGULA modu bu surumde henuz acik degil - once olcum Cem'e sunulacak."
