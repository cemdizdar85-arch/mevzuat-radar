# ============================================================================
#  KONU ETIKET HIZALAMASI (02.08.2026) — 0 USD, API YOK
#
#  SORUN: Siklik kunyesi (D9) calisiyor ama vitrin bankasinin 150 sorusundan
#  yalnizca 15'inde gorunuyor (%10). Sebep: kasadaki konu etiketi ("kamu
#  gelirleri turleri") kitapcik sayimindaki etiketle birebir yazilmiyor.
#
#  COZUM: Kasadaki etiketleri DEGISTIRMIYORUZ (riskli, geri alinamaz).
#  Bunun yerine bir ESLESME SOZLUGU uretiyoruz: kasa etiketi -> kitapcik
#  etiketi. deneme.html once birebir bakar, tutmazsa sozluge bakar.
#
#  ESLESME YONTEMI (deterministik, yapay zeka YOK):
#   - Iki taraf da normalize edilir, durak kelimeler atilir
#   - Kelime kumesi ortakligi (Jaccard) hesaplanir
#   - AYNI DERS AILESI sarti + esik >= 0.55 -> kabul
#   - Altindakiler REDDEDILIR. Yanlis kunye, kunye yoklugundan KOTUDUR (D9).
#
#  KAYNAK: SUPABASE_SERVICE_KEY varsa kasa; yoksa vitrin bankasi (yerel test).
#  Cikti: veri/konu-eslesme.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$cikti = Join-Path $kok 'veri/konu-eslesme.json'

function Norm([string]$t){
  $s = "$t".ToLower()
  $s = $s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİ]','i' -replace '[öÖ]','o' -replace '[şŞ]','s' -replace '[üÜ]','u'
  $s = $s -replace '[^a-z0-9| ]',' ' -replace '\s+',' '
  return $s.Trim()
}
$DURAK = @('ve','ile','icin','olan','bir','bu','da','de','nin','nin','uzerine','iliskin','dair','gore','hakkinda','turleri','turu','kurallari','kurali','ilkesi','ilkeleri','esaslari','hukumleri')
function Kelime([string]$t){
  $p = (Norm $t).Split(' ') | Where-Object { $_.Length -ge 3 -and $DURAK -notcontains $_ }
  return @($p | Select-Object -Unique)
}
# Ders ailesi: kasada "Vergi Hukuku", kitapcikta "Hukuk" olabilir - kaba aile
function Aile([string]$ders){
  $d = Norm $ders
  if($d -match 'muhasebe|maliyet|tablo|analiz|standart|denetim'){ return 'muhasebe' }
  if($d -match 'hukuk|ticaret|borclar|is ve|sosyal|vergi|meslek|icra|iflas'){ return 'hukuk' }
  if($d -match 'ekonomi|maliye|iktisat'){ return 'iktisat' }
  if($d -match 'turkce|matematik|tarih|inkilap|ataturk|genel'){ return 'genel' }
  if($d -match 'yabanci|ingiliz|dil'){ return 'dil' }
  return 'diger'
}

# --- siklik tablosu ---
$sikYol = Join-Path $kok 'veri/siklik-kunyesi.json'
if(-not (Test-Path $sikYol)){ Write-Host "siklik-kunyesi.json yok - once motor/siklik-kunyesi.ps1 kosulmali."; exit 1 }
$sik = Get-Content $sikYol -Raw -Encoding UTF8 | ConvertFrom-Json
$hedefler = @()
foreach($p in $sik.konular.PSObject.Properties){
  $ad = $p.Value.ad; $par = "$ad".Split('|')
  $hedefler += [pscustomobject]@{ anahtar=$p.Name; ders=$par[0]; konu=$(if($par.Count -gt 1){ $par[1] } else { '' }); aile=(Aile $par[0]); kelime=(Kelime $(if($par.Count -gt 1){ $par[1] } else { '' })); d=$p.Value.d; s=$p.Value.s }
}
Write-Host ("Kitapcik konusu: {0}" -f $hedefler.Count)

# --- kaynak: kasa ya da vitrin ---
$sorular = @()
if($env:SUPABASE_SERVICE_KEY){
  $U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
  $SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
  for($o=0; $o -lt 60000; $o+=1000){
    $ham = Invoke-WebRequest -Uri "$U`?select=ders,konu&order=id&limit=1000&offset=$o" -Headers $SB -UseBasicParsing -TimeoutSec 180
    $mt = if($ham.RawContentStream){ [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray()) } else { "$($ham.Content)" }
    $r = @($mt | ConvertFrom-Json)
    if($r.Count -eq 0){ break }
    $sorular += $r
    if($r.Count -lt 1000){ break }
  }
  $kaynakAd = 'kasa'
} else {
  $vb = Get-Content (Join-Path $kok 'veri/soru-bankasi.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $sorular = @($vb.sorular); $kaynakAd = 'vitrin-bankasi (yerel test)'
}
Write-Host ("Kaynak: {0} | soru: {1}" -f $kaynakAd, $sorular.Count)

# --- benzersiz kasa etiketleri ---
$etiket = @{}
foreach($s in $sorular){
  if(-not $s.ders -or -not $s.konu){ continue }
  $a = Norm ("$($s.ders)|$($s.konu)")
  if(-not $etiket.ContainsKey($a)){ $etiket[$a] = [pscustomobject]@{ anahtar=$a; ders="$($s.ders)"; konu="$($s.konu)"; adet=0 } }
  $etiket[$a].adet++
}
Write-Host ("Benzersiz kasa etiketi: {0}" -f $etiket.Count)

# --- esleme ---
$hedefAnahtar = @{}; foreach($h in $hedefler){ $hedefAnahtar[$h.anahtar] = $h }
$sozluk = [ordered]@{}; $birebir = 0; $bulanik = 0; $redd = 0
foreach($e in ($etiket.Values | Sort-Object anahtar)){
  if($hedefAnahtar.ContainsKey($e.anahtar)){ $birebir++; continue }   # zaten tutuyor
  $ail = Aile $e.ders
  $kel = Kelime $e.konu
  if($kel.Count -eq 0){ $redd++; continue }
  $enIyi = $null; $enPuan = 0.0
  foreach($h in $hedefler){
    if($h.aile -ne $ail){ continue }
    if($h.kelime.Count -eq 0){ continue }
    $ortak = 0; foreach($k in $kel){ if($h.kelime -contains $k){ $ortak++ } }
    if($ortak -eq 0){ continue }
    $birlesim = ($kel.Count + $h.kelime.Count - $ortak)
    $puan = [math]::Round($ortak / [math]::Max(1,$birlesim), 3)
    if($puan -gt $enPuan){ $enPuan = $puan; $enIyi = $h }
  }
  if($enIyi -and $enPuan -ge 0.55){
    $sozluk[$e.anahtar] = [ordered]@{ hedef=$enIyi.anahtar; puan=$enPuan; kasa="$($e.ders)|$($e.konu)"; kitapcik="$($enIyi.ders)|$($enIyi.konu)"; d=$enIyi.d; s=$enIyi.s }
    $bulanik++
  } else { $redd++ }
}

$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynak=$kaynakAd
  kasa_etiketi=$etiket.Count; kitapcik_konusu=$hedefler.Count
  birebir_tutan=$birebir; sozlukle_eslesen=$bulanik; eslesmeyen=$redd
  esik=0.55
  not='Yanlis kunye, kunye yoklugundan KOTUDUR (D9). Esik 0.55 altindakiler REDDEDILIR ve o soruda kunye gosterilmez. Kasa etiketleri DEGISTIRILMEDI - bu yalniz bir arama sozlugudur, geri alinabilir.'
  sozluk=$sozluk
}
Set-Content -LiteralPath $cikti -Value (ConvertTo-Json -InputObject $rapor -Depth 6) -Encoding UTF8 -NoNewline
Write-Host ("`nbirebir tutan : {0}" -f $birebir)
Write-Host ("sozlukle eslesen: {0}" -f $bulanik)
Write-Host ("eslesmeyen    : {0}" -f $redd)
Write-Host ("kapsama       : %{0}" -f [math]::Round(100*($birebir+$bulanik)/[math]::Max(1,$etiket.Count),1))
Write-Host "`n=== ORNEK ESLESMELER (ilk 8) ==="
$i=0; foreach($k in $sozluk.Keys){ if($i -ge 8){ break }; $v=$sozluk[$k]; Write-Host ("  {0,-46} -> {1,-46} ({2})" -f $v.kasa, $v.kitapcik, $v.puan); $i++ }
Write-Host ("`n-> {0}" -f $cikti)
