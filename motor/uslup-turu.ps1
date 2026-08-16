# ============================================================================
#  USLUP TURU — 29.07.2026   (PARA HARCAR - tek kapisi veri/uslup-emir.json)
#
#  NIYE VAR: Cem'in sarti - "ogrenci bunlari yapay zeka yazmis demesin."
#  Kasa tarandi (7.519 soru): 331 soruda makine izi var (%4,4).
#     placeholder unvan (ABC Ticaret A.S. gibi) : 79
#     butun tutarlar yuvarlak                   : 251
#     sisirme klise                             : 13
#
#  EN ONEMLI KISIT: 251 soruda kusur TUTARLARIN YUVARLAKLIGI. Tutari degistirmek
#  butun siklari ve hesabi bozar - "sadece uslup duzeltmesi" diye bir sey yok.
#  Bu yuzden burada soru YENIDEN YAZILIR ve sonuc yayin=false duser: hakem
#  yeniden yargilar. Uslup ugruna dogruluk feda edilmez.
#
#  DEGISMEYECEK OLAN: hukuki oz, dogru cevabin HARFI, kaynak, konu.
#  DEGISECEK OLAN   : unvan, kisi adi, tutarlar (ve onlara bagli siklar/aciklama).
# ============================================================================
param(
  [switch]$calistir,
  [int]$sinir = 0,
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = ''
)
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
try { Start-Transcript -Path (Join-Path $kok 'veri/uslup-log.txt') -Force | Out-Null } catch {}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$AK = "$env:ANTHROPIC_API_KEY".Trim()
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

function HataGovde($e){
  if($e.ErrorDetails -and $e.ErrorDetails.Message){ return "$($e.ErrorDetails.Message)" }
  try { return (New-Object IO.StreamReader($e.Exception.Response.GetResponseStream())).ReadToEnd() } catch { return "" }
}
# PS7 Invoke-RestMethod diziyi tek parca donduruyor; kritik cekimlerde ham oku.
function SbGet($url){
  $r = Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $H -TimeoutSec 180
  $g = if($r.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($r.Content) } else { "$($r.Content)" }
  $l = New-Object System.Collections.Generic.List[object]
  foreach($x in (ConvertFrom-Json $g)){ $l.Add($x) }
  return $l
}

$idYol = Join-Path $kok "veri/koku-izli.json"
if(-not (Test-Path $idYol)){ Write-Host "veri/koku-izli.json yok - once kasa sayimi kossun."; exit 1 }
$idler = New-Object System.Collections.Generic.List[string]
foreach($x in (ConvertFrom-Json ([IO.File]::ReadAllText($idYol)))){ $idler.Add("$x") }
if($sinir -gt 0 -and $idler.Count -gt $sinir){ $idler = [System.Collections.Generic.List[string]]@($idler[0..($sinir-1)]) }
Write-Host ("Uslup turu: {0} soru" -f $idler.Count)

# --- sorulari cek (100'luk dilimler; id=in.(...) uzun URL yapmasin)
$sorular = New-Object System.Collections.Generic.List[object]
for($i=0; $i -lt $idler.Count; $i += 100){
  $dilim = @($idler[$i..([Math]::Min($i+99,$idler.Count-1))])
  $liste = (($dilim | ForEach-Object { '"' + $_ + '"' }) -join ',')
  foreach($q in (SbGet "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak&id=in.($liste)")){ $sorular.Add($q) }
}
Write-Host ("  cekilen: {0}" -f $sorular.Count)
if($sorular.Count -eq 0){ Write-Host "Cekilecek soru yok."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
if(-not $calistir){ Write-Host "OLCUM modu - para harcanmadi."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

function IstemKur($q){
  $sik = ""
  foreach($h in @('A','B','C','D','E')){ $sik += "$h) $($q.siklar.$h)`n" }
  return @"
Asagidaki SMMM sinav sorusu icerik olarak dogru ama YAPAY ZEKA YAZMIS gibi
duruyor. Gorevin onu GERCEK BIR SINAV SORUSU gibi yeniden yazmak.

=== MEVCUT SORU ===
$($q.soru)
$sik
DOGRU SIK: $($q.dogru)
KAYNAK: $($q.kaynak)
=== BITTI ===

DEGISMEYECEK OLAN (buna dokunursan is bozulur):
- Sorunun HUKUKI OZU ve olctugu kural. Ayni maddeyi ayni acidan olcecek.
- DOGRU CEVABIN HARFI: yine $($q.dogru) olacak.
- Kaynak ve konu.

DEGISECEK OLAN - yapay zeka izleri:
1. "ABC Ticaret A.S.", "XYZ A.S.", "X Isletmesi" gibi HARF PLACEHOLDER unvanlar.
   Gercek unvan yaz: "Ozdemir Tekstil Ltd. Sti.", "Karadeniz Gida A.S.",
   "Bayrak Ins. San. Tic. A.S." gibi. Kisi adi gerekiyorsa yaygin Turk adi.
2. BUTUN TUTARLARIN YUVARLAK olmasi. Gercek hayatta rakam 47.350 TL, 6.812 TL,
   129.470 TL'dir. En az bir tutar yuvarlak OLMASIN.
   *** TUTARI DEGISTIRIRSEN BUTUN SIKLARI VE ACIKLAMAYI YENIDEN HESAPLA. ***
   Yeni tutarlarla dogru cevap yine $($q.dogru) sikkinda cikmali - hesabi once
   sen yap, sonra sonucu $($q.dogru) sikkina yaz, digerlerine makul yanlislar.
   Hesap tutmuyorsa tutarlari degistirme, oldugu gibi birak.
3. Sisirme kliseler: "onem arz etmektedir", "unutulmamalidir ki", "dikkat
   edilmelidir", "bu baglamda", "ilgili mevzuat uyarinca". Sade konus.

ACIKLAMA - dogru sik icin DORT PARCA, bu basliklarla:
Ne soruluyor: <tek cumle, hic muhasebe bilmeyene>
Kural: <maddeye dayali, gunluk dille>
Bu olayda: <kuralin uygulanisi, adim adim, YENI tutarlarla>
Akilda kalsin: <tek cumle>
400-700 karakter.

YANLIS SIKLARDA tuzagi adlandir ama DORT SIKTA AYNI KALIBI KURMA - birinde
"karistiriyor", birinde "sanilan sey", birinde "gozden kacan nokta" de.

SADECE gecerli JSON dondur:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","tutar_degisti":true}
"@
}

# --- Batch API (%50 indirim - indirimsiz kosu yok)
$satirlar = New-Object System.Collections.Generic.List[string]
foreach($q in $sorular){
  $istek = [ordered]@{
    custom_id = "$($q.id)"
    params = [ordered]@{
      model = $model; max_tokens = 3000
      messages = @(@{ role='user'; content=(IstemKur $q) })
    }
  }
  $satirlar.Add((ConvertTo-Json -InputObject $istek -Depth 8 -Compress))
}
Write-Host ("  batch istegi: {0} satir" -f $satirlar.Count)

$govde = @{ requests = @($satirlar | ForEach-Object { ConvertFrom-Json $_ }) }
try {
  $bt = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches" -Headers $HDR `
        -ContentType "application/json" -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 10))) -TimeoutSec 300
} catch { Write-Host ("BATCH ACILAMADI: {0}" -f (HataGovde $_)); try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$bid = $bt.id
Write-Host ("  batch: {0}" -f $bid)

$bekle = 0
while($true){
  Start-Sleep -Seconds 30; $bekle += 30
  try { $d = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$bid" -Headers $HDR -TimeoutSec 120 } catch { continue }
  if("$($d.processing_status)" -eq 'ended'){ break }
  if($bekle % 300 -eq 0){ Write-Host ("  ...{0} dk" -f ($bekle/60)) }
  if($bekle -gt 16000){ Write-Host "BATCH ZAMAN ASIMI - id: $bid"; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
}
$rr = Invoke-WebRequest -UseBasicParsing -Uri $d.results_url -Headers $HDR -TimeoutSec 600
# PS7 JSONL'i byte[] dondurur - once UTF8'e cevir, yoksa her karakter satir sanilir
$metin = if($rr.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($rr.Content) } else { "$($rr.Content)" }
$sonuc = @{}
foreach($sat in ($metin -split "`r?`n")){
  if("$sat".Trim().Length -lt 5){ continue }
  try { $o = ConvertFrom-Json $sat } catch { continue }
  if("$($o.result.type)" -ne 'succeeded'){ continue }
  $tx = "$($o.result.message.content[0].text)"
  $m = [regex]::Match($tx, '(?s)\{.*\}')
  if(-not $m.Success){ continue }
  try { $sonuc["$($o.custom_id)"] = ConvertFrom-Json $m.Value } catch { }
}
Write-Host ("  cozulen cevap: {0}" -f $sonuc.Count)

# --- KAPILAR + yazma
$ozet = [ordered]@{ bakilan=0; cevapsiz=0; sikRed=0; kokuRed=0; sablonRed=0; yazildi=0; yazmaHatasi=0 }
$red = New-Object System.Collections.Generic.List[object]
$KLISE = @('önem arz et','unutulmamalıdır','dikkat edilmelidir','bu bağlamda','ilgili mevzuat uyarınca')
foreach($q in $sorular){
  $ozet.bakilan++
  $y = $sonuc["$($q.id)"]
  if(-not $y -or -not $y.soru -or -not $y.siklar){ $ozet.cevapsiz++; continue }
  $dolu=0; foreach($h in @('A','B','C','D','E')){ if("$($y.siklar.$h)".Trim().Length -gt 2){ $dolu++ } }
  if($dolu -ne 5){ $ozet.sikRed++; $red.Add([pscustomobject]@{ id="$($q.id)"; sebep='sik-eksik' }); continue }
  $dt = "$($y.aciklama.($q.dogru))"
  if($dt.Trim().Length -lt 300){ $ozet.sablonRed++; $red.Add([pscustomobject]@{ id="$($q.id)"; sebep='aciklama-kisa' }); continue }
  $eksik = @(); foreach($par in @('Ne soruluyor','Kural','Bu olayda','Ak[ıi]lda kals[ıi]n')){ if($dt -notmatch $par){ $eksik += $par } }
  if($eksik.Count){ $ozet.sablonRed++; $red.Add([pscustomobject]@{ id="$($q.id)"; sebep='sablon'; deger=($eksik -join ', ') }); continue }

  # ayni kokuyu tekrar uretmediginden emin ol - yoksa parayi bosa harcamis oluruz
  $tum = "$($y.soru)"; foreach($h in @('A','B','C','D','E')){ $tum += " $($y.siklar.$h) $($y.aciklama.$h)" }
  $koku = @()
  if($y.soru -match '(?i)\b(ABC|XYZ|ABCD)\s*(ticaret|gıda|tekstil|a\.?ş|ltd|işletme|şirket)' -or
     $y.soru -match '(?i)\b(X|Y|Z)\s+(A\.?Ş\.?|İşletmesi|Ltd)'){ $koku += 'placeholder' }
  $tutar = @([regex]::Matches("$($y.soru)", '(\d{1,3}(?:\.\d{3})+)\s*(?:TL|lira)') | ForEach-Object { $_.Groups[1].Value })
  if($tutar.Count -ge 3 -and (@($tutar | Where-Object { $_ -match '\.000$' }).Count -eq $tutar.Count)){ $koku += 'hepsi-yuvarlak' }
  foreach($kl in $KLISE){ if($tum -match [regex]::Escape($kl)){ $koku += 'klise'; break } }
  if($koku.Count){ $ozet.kokuRed++; $red.Add([pscustomobject]@{ id="$($q.id)"; sebep='koku-devam'; deger=($koku -join ', ') }); continue }

  # YAZ: yayin=false - tutar degistiyse hesap da degisti, hakem YENIDEN yargilar.
  # Uslup ugruna dogruluk feda edilmez.
  $govde2 = [ordered]@{
    soru="$($y.soru)"; siklar=$y.siklar; aciklama=$y.aciklama
    yayin=$false
    yayin_notu='USLUP TURU 29.07 - senaryo yuzeyi (unvan/tutar) yenilendi, hesap degisti. Hakem yeniden yargilamadan yayina cikmaz.'
  }
  if("$($y.hap)".Trim().Length -ge 5){ $govde2['hap'] = "$($y.hap)".Trim() }
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($q.id)" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde2 -Depth 6))) -TimeoutSec 60 | Out-Null
    $ozet.yazildi++
  } catch {
    $ozet.yazmaHatasi++
    $red.Add([pscustomobject]@{ id="$($q.id)"; sebep='yazilamadi'; deger=(HataGovde $_) })
  }
}

Write-Host ""
Write-Host "======== USLUP TURU ========"
foreach($k in $ozet.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ozet[$k]) }
if($red.Count){ Write-Host "--- redler:"; $red | Group-Object sebep | Sort-Object Count -Desc | ForEach-Object { Write-Host ("     {0,-16} {1}" -f $_.Name, $_.Count) } }
Write-Host "  NOT: degistirilen sorularin HEPSI yayin=false. Hakem yeniden yargilayacak."
if($cikti){
  [IO.File]::WriteAllText((Join-Path $kok $cikti), ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; batch=$bid; ozet=$ozet; red=$red
  } | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host "-> $cikti"
}
try{Stop-Transcript|Out-Null}catch{}
exit 0
