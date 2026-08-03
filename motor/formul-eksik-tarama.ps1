# ============================================================================
#  FORMUL EKSIK TARAMASI (03.08.2026 gece) — 0 USD, API YOK, KASAYA YAZMAZ
#
#  NEDEN: Cem "Aktif Devir Hizi ve Oz Kaynak Kaldiraci" sorusunda Kural kisminda
#  GENEL/SEMBOLIK formul olmadigini gosterdi ("Bu olayda" kisminda sayilarla
#  islem var ama ogrenci transfer edilebilir formulu goremiyor). D13-ek zaten
#  bunu istiyordu ("Kural once yontemi tanimlar, SONRA FORMULU AYRI SATIRDA
#  verir") ama onarim-motoru.ps1'in yontem-adi listesi "kaldirac" gibi bazi
#  yaygin oran adlarini icermiyordu - bu gece listeye eklendi.
#
#  "28 bin sorunun hepsini duzeltelim" demeden once GERCEK SAYIYI olcuyoruz:
#  kasadaki HANGI sorularda yontem adi var AMA Kural'da formul (=, /, ÷ gibi
#  bir islem izi) yok. Bu, D13-ek'in onarim-motoru.ps1 icindeki AYNI tetik
#  mantigidir - fark: burada TUM kasaya (pilot degil) uygulanir, 0 USD.
#
#  CIKTI: veri/formul-eksik-taramasi.json (tam liste, id+ders+konu) ·
#  veri/formul-eksik-taramasi-raporu.json (sayilar, ders dagilimi, ilk 10 ornek)
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/formul-eksik-taramasi.json'
$raporYol = Join-Path $kok 'veri/formul-eksik-taramasi-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"
    sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,dogru,aciklama,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# onarim-motoru.ps1 D13-ek ile AYNI regex (03.08 gece genisletildi: kaldirac,
# degisim/artis/azalis/buyume orani, cari oran, likidite, asit test, karsilik
# orani, karlilik orani, stok/alacak devir, borc orani, oz kaynak orani).
$reYontem = [regex]'(?i)dikey\s*y[üu]zde|yatay\s*y[üu]zde|y[üu]zde\s*analiz|dikey\s*analiz|yatay\s*analiz|devir\s*h[ıi]z|oran\s*analiz|rasyo|maliyetleme\s*y[öo]ntem|de[ğg]i[şs]ken\s*maliyet|tam\s*maliyet|k[ıi]st\s*amortisman|reeskont|e[şs]de[ğg]er\s*[üu]r[üu]n|trend\s*analiz|de[ğg]i[şs]im\s*oran|art[ıi][şs]\s*oran|azal[ıi][şs]\s*oran|b[üu]y[üu]me\s*oran|kar[şs][ıi]la[şs]t[ıi]rmal[ıi]\s*(tablo|analiz)|kald[ıi]ra[çc]|cari\s*oran|likidite\s*oran|asit\s*test|kar[şs][ıi]l[ıi]k\s*oran|k[aâ]rl[ıi]l[ıi]k\s*oran|stok\s*devir|alacak\s*devir|bor[çc]\s*oran|[öo]z\s*kaynak\s*oran'
$reFormul = [regex]'(?i)[A-Za-zÇĞİÖŞÜçğıöşü\)]\s*[=÷]\s*|[A-Za-zÇĞİÖŞÜçğıöşü]\s*/\s*[A-Za-zÇĞİÖŞÜçğıöşü]'

$eksik = New-Object System.Collections.Generic.List[object]
$dersDagilimi = @{}
$taranan = 0

foreach($s in $kasa){
  $metin = "$($s.soru) $($s.konu)"
  if(-not $reYontem.IsMatch($metin)){ continue }
  $taranan++
  $dhy = "$($s.dogru)".Trim().ToUpper()
  $mevcutY = ''
  try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dhy]){ $mevcutY = "$($s.aciklama.$dhy)" } } catch {}
  if($mevcutY.Trim().Length -lt 20){ continue }   # aciklama hic yoksa bu ayri konu (D2 kapisi), formul-eksik degil
  if($reFormul.IsMatch($mevcutY)){ continue }     # formul izi var - tamam
  $eksik.Add([ordered]@{ id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)"; yayinda=[bool]$s.yayin })
  if(-not $dersDagilimi.ContainsKey("$($s.ders)")){ $dersDagilimi["$($s.ders)"] = 0 }
  $dersDagilimi["$($s.ders)"]++
}

$dersListe = New-Object System.Collections.Generic.List[object]
foreach($d in ($dersDagilimi.Keys | Sort-Object { -$dersDagilimi[$_] })){ $dersListe.Add([ordered]@{ ders=$d; adet=$dersDagilimi[$d] }) }

Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama='Yontem/oran adi gecen AMA Kural aciklamasinda sembolik formul (=, /, ÷) izi olmayan sorularin listesi. Duzeltme AI cagrisi gerektirir (0 USD degil) - bu yalniz OLCUM.'
  sorular=$eksik.ToArray()
})) -Encoding UTF8 -NoNewline

Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  kasa=$kasa.Count
  yontem_adi_gecen_soru=$taranan
  formul_eksik=$eksik.Count
  ders_dagilimi=$dersListe.ToArray()
  ilk_10_ornek=@($eksik | Select-Object -First 10)
  not='Kasaya HICBIR SEY YAZILMADI - bu yalniz olcum. Duzeltme (AI ile Kural yeniden yazma) AYRI ve PARALI bir adim, once bu sayiya bakilir.'
}))
Write-Host "`n=== FORMUL EKSIK TARAMASI ==="
Write-Host ("  Yontem adi gecen soru   : {0}" -f $taranan)
Write-Host ("  Formul eksik            : {0}" -f $eksik.Count)
$dersListe | ForEach-Object { Write-Host ("    {0,-30} {1,5}" -f $_.ders, $_.adet) }
