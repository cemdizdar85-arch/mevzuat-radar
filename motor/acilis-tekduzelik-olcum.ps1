# ============================================================================
#  ACILIS TEKDUZELIK OLCUMU (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "aciklamalar hem ilk basa 'ne soruluyor' yaziyor, bu yapay zeka
#  derler mi?"
#
#  BASLIK sabit olmasi sorun degil (UWorld/Kaplan/Becker da boyle yapar;
#  kurumsal iz sayilir). GERCEK RISK, o basligin ALTINDAKI CUMLENIN her
#  soruda ayni kalipla acilmasidir - defterdeki kural: "iz DILDE, iskelette
#  degil; tekduzelik hatadan cok ele verir."
#
#  BU BETIK OLCER, TAHMIN ETMEZ:
#   - Kasadaki TUM aciklamalarda dort parcanin her bolumunun ILK KELIMELERINI
#     cikarir (Ne soruluyor / Kural / Bu olayda / Akilda kalsin ayri ayri).
#   - Ayni acilisin kac soruda tekrarladigini sayar.
#   - "Ilk 2 kelime" ve "ilk 3 kelime" olarak iki cozunurlukte bakar.
#   - En sik 25 acilisi ve yuzdesini raporlar.
#
#  YORUM OLCUTU (rapora yazilir, karar Cem'in):
#   - Bir acilis kalibi %5'i asiyorsa DIKKAT, %10'u asiyorsa TEKDUZE sayilir.
#   - Dogal dilde en sik kalip bile genelde %2-3'te kalir.
#
#  CIKTI: veri/acilis-tekduzelik-raporu.json
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/acilis-tekduzelik-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
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
  $r = CekListe "$U`?select=id,ders,dogru,aciklama&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# Dort parcayi bolumlere ayir (site ile ayni etiketler)
$reBol = [regex]'(?i)(Ne\s+sorul\w*|Kural|Bu\s+olayda|Bu\s+soruda|Ak[ıi]lda\s+kals[ıi]n)\s*:\s*'
$TR = [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
$KI = [Text.RegularExpressions.RegexOptions]::CultureInvariant

function AcilisAl([string]$metin, [int]$kacKelime){
  # noktalama at, ilk N anlamli kelimeyi kucuk harfe indirip birlestir
  $t = [regex]::Replace($metin, '[^\p{L}\p{Nd} ]', ' ', $KI)
  $k = @($t -split '\s+' | Where-Object { $_ -ne '' })
  if($k.Count -lt $kacKelime){ return '' }
  return (($k[0..($kacKelime-1)] | ForEach-Object { $_.ToLower($TR) }) -join ' ')
}

$bolumAdlari = @('NE SORULUYOR','KURAL','BU OLAYDA','AKILDA KALSIN')
function BolumAdiNormal([string]$e){
  $x = $e.ToLower($TR)
  if($x -like 'ne sorul*'){ return 'NE SORULUYOR' }
  if($x -eq 'kural'){ return 'KURAL' }
  if($x -like 'bu olayda' -or $x -like 'bu soruda'){ return 'BU OLAYDA' }
  return 'AKILDA KALSIN'
}

$sayac2 = @{}; $sayac3 = @{}; $bolumToplam = @{}
foreach($b in $bolumAdlari){ $sayac2[$b] = @{}; $sayac3[$b] = @{}; $bolumToplam[$b] = 0 }
$islenen = 0

foreach($s in $kasa){
  $dh = "$($s.dogru)".Trim().ToUpper()
  $m = ''
  try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $m = "$($s.aciklama.$dh)" } } catch {}
  if($m.Trim().Length -lt 30){ continue }
  $islenen++
  $par = $reBol.Split($m)
  # Split sonucu: [giris, etiket1, metin1, etiket2, metin2, ...]
  for($i=1; $i -lt $par.Count; $i+=2){
    $bol = BolumAdiNormal $par[$i]
    $govde = ''
    if(($i+1) -lt $par.Count){ $govde = "$($par[$i+1])".Trim() }
    if($govde.Length -lt 10){ continue }
    $bolumToplam[$bol]++
    $a2 = AcilisAl $govde 2
    $a3 = AcilisAl $govde 3
    if($a2 -ne ''){ if(-not $sayac2[$bol].ContainsKey($a2)){ $sayac2[$bol][$a2]=0 }; $sayac2[$bol][$a2]++ }
    if($a3 -ne ''){ if(-not $sayac3[$bol].ContainsKey($a3)){ $sayac3[$bol][$a3]=0 }; $sayac3[$bol][$a3]++ }
  }
}

function EnSik($tablo, $toplam, $adet){
  $l = New-Object System.Collections.Generic.List[object]
  foreach($k in ($tablo.Keys | Sort-Object { -$tablo[$_] } | Select-Object -First $adet)){
    $l.Add([ordered]@{ acilis=$k; adet=$tablo[$k]; yuzde=$(if($toplam -gt 0){ [Math]::Round(100.0*$tablo[$k]/$toplam,2) } else { 0 }) })
  }
  return $l.ToArray()
}

$bolumRapor = [ordered]@{}
$enYuksekYuzde = 0.0; $enYuksekNerede = ''
foreach($b in $bolumAdlari){
  $t = $bolumToplam[$b]
  $ilk2 = EnSik $sayac2[$b] $t 15
  $ilk3 = EnSik $sayac3[$b] $t 15
  $tepe = 0.0
  if($ilk2.Count -gt 0){ $tepe = [double]$ilk2[0].yuzde }
  if($tepe -gt $enYuksekYuzde){ $enYuksekYuzde = $tepe; $enYuksekNerede = $b }
  $bolumRapor[$b] = [ordered]@{
    bolum_toplam=$t
    farkli_acilis_2kelime=$sayac2[$b].Count
    farkli_acilis_3kelime=$sayac3[$b].Count
    en_sik_2kelime=$ilk2
    en_sik_3kelime=$ilk3
  }
}
$karar = if($enYuksekYuzde -ge 10){ 'TEKDUZE - istem ve kapi gerekir' } elseif($enYuksekYuzde -ge 5){ 'DIKKAT - sinirda' } else { 'DOGAL - tekduzelik yok' }

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count; aciklamasi_olan=$islenen
  olcut='Bir acilis kalibi %5 ustu DIKKAT, %10 ustu TEKDUZE. Dogal dilde en sik kalip genelde %2-3te kalir.'
  en_yuksek_tek_kalip_yuzde=$enYuksekYuzde; en_yuksek_bolum=$enYuksekNerede
  KARAR=$karar
  bolumler=$bolumRapor
  not='Yalniz OLCUM - kasaya dokunulmadi. Basligin kendisi (Ne soruluyor:) sabit olmasi sorun degil; olculen sey basligin ALTINDAKI cumlenin acilis kalibidir.'
})
Write-Host "`n=== ACILIS TEKDUZELIK OLCUMU ==="
Write-Host ("  Aciklamasi olan soru: {0}" -f $islenen)
foreach($b in $bolumAdlari){
  $r = $bolumRapor[$b]
  $ilk = if($r.en_sik_2kelime.Count -gt 0){ "{0} (%{1})" -f $r.en_sik_2kelime[0].acilis, $r.en_sik_2kelime[0].yuzde } else { '-' }
  Write-Host ("  {0,-14} bolum={1,6}  farkli acilis={2,5}  en sik: {3}" -f $b, $r.bolum_toplam, $r.farkli_acilis_2kelime, $ilk)
}
Write-Host ("`n  KARAR: {0}  (en yuksek tek kalip %{1}, {2})" -f $karar, $enYuksekYuzde, $enYuksekNerede)
