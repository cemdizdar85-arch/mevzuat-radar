# ============================================================================
#  DAYANAK YENIDEN BAGLAMA — alakasiz kanuna baglanmis sorulari duzeltir
#
#  DOGUSU (16.08.2026): ders<->kanun kapisi 5018 m.3'e (kamu idarelerinin
#  tanim cetveli) bagli 1.089 soru buldu. Icerik: "cari oran", "finansal oran
#  analizi", "net isletme sermayesi" - yani TEKNIK/TEORI konulari. Hicbir
#  kanun maddesi "cari oran = donen varliklar / KVYK" demez; bu sorularin
#  dayanagi mevzuat DEGIL teori notudur.
#
#  Ambarda dogru kaynaklar ZATEN VAR:
#     "Teori Notu - finansal analiz oranlari"
#     "Teori Notu - oran analizi likidite"
#
#  YONTEM: her soru icin cozucu KENDI konusuyla calistirilir (KaynakCoz
#  kaynak+konu alir). Cikan sonuca gore:
#     cozuldu-teori     -> kanun_no='TEORI', madde_no=not adi, damga=metin damgasi
#     cozuldu-standart  -> STD  (ornek: "tms 40 yatirim amacli gayrimenkul")
#     cozuldu-hesapplani-> THP
#     cozuldu (kanun)   -> o kanun (gercekten mevzuata dayaniyorsa)
#     hicbiri           -> DOKUNULMAZ, "kaynak bulunamadi" diye raporlanir
#
#  UYDURMA YOK: cozucu bir kaynak bulamazsa soru OLDUGU GIBI BIRAKILIR ve
#  listeye yazilir; yanlis kaynagi baska bir yanlis kaynakla degistirmeyiz.
#
#  VARSAYILAN OLCUM. Yazmak icin -uygula. Yazma sonrasi GERI OKUMA zorunlu.
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/dayanak-yeniden-baglama.json
# ============================================================================
param(
  [string]$kanun = '5018',
  [string]$madde = '3',
  [switch]$uygula,
  [int]$sinir = 0
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$ANAHTAR = $env:SUPABASE_SERVICE_KEY
if([string]::IsNullOrWhiteSpace($ANAHTAR)){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$BASLIK = @{ apikey=$ANAHTAR; Authorization=("Bearer "+$ANAHTAR) }
$raporYol = Join-Path $kok 'veri/dayanak-yeniden-baglama.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
. (Join-Path $here 'madde-coz.ps1') -kutuphane

function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '\s+', ' '
  return $x.Trim()
}
function DamgaSade([string]$t){
  $sha = [Security.Cryptography.SHA256]::Create()
  return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((Sadelestir $t)))) -replace '-','').Substring(0,16).ToLowerInvariant()
}

# --- acik konu -> teori notu tablosu (varsa)
$ESLESME = @()
$eslesmeYol = Join-Path $kok 'veri/konu-teori-eslesme.json'
if(Test-Path $eslesmeYol){
  $eh = Get-Content $eslesmeYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($e in $eh.eslesmeler){ $ESLESME += $e }
  Write-Host ("Acik eslesme tablosu: {0} desen" -f $ESLESME.Count)
}
# Teori notunu ADIYLA getirir (tablo icin). Ambarda yoksa $null -> uydurma baglama olmaz.
$script:teoriOnbellek = @{}
function TeoriNotuAdiyla([string]$ad){
  if($script:teoriOnbellek.ContainsKey($ad)){ return $script:teoriOnbellek[$ad] }
  $metin = $null
  try {
    $adres = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=eq.' + [uri]::EscapeDataString($ad) + '&limit=5'
    $rr = Invoke-WebRequest -Uri $adres -Headers $BASLIK -UseBasicParsing -TimeoutSec 60
    $dd = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($rr.RawContentStream.ToArray()))
    $par = New-Object System.Collections.Generic.List[string]
    foreach($x in $dd){ [void]$par.Add("$($x.metin)") }
    if($par.Count -gt 0){ $metin = ($par -join ' ') }
  } catch {}
  $script:teoriOnbellek[$ad] = $metin
  return $metin
}

Write-Host ("Hedef: kanun_no={0} madde_no={1} olan sorular" -f $kanun, $madde)
$hedefler = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $adres = "$U`?select=id,ders,konu,kaynak,kanun_no,madde_no&kanun_no=eq.$kanun&madde_no=eq.$madde&order=id&limit=1000&offset=$bas"
  $r = Invoke-WebRequest -Uri $adres -Headers $BASLIK -UseBasicParsing -TimeoutSec 300
  $cozulmus = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))
  $adet = 0
  foreach($satir in $cozulmus){ [void]$hedefler.Add($satir); $adet++ }
  if($adet -eq 0){ break }
  $bas += 1000
  if($adet -lt 1000){ break }
}
Write-Host ("Bulunan soru: {0}" -f $hedefler.Count)
$parti = $hedefler.ToArray()
if($sinir -gt 0 -and $sinir -lt $parti.Count){ $parti = $parti[0..($sinir-1)] }

$plan = New-Object System.Collections.Generic.List[object]
$kova = [ordered]@{ teori=0; standart=0; hesapplani=0; kanun=0; bulunamadi=0 }
$sebep = @{}
$n = 0
foreach($s in $parti){
  $n++
  if(($n % 200) -eq 0){ Write-Host ("  ...{0}/{1}" -f $n, $parti.Count) }
  # 1) ACIK TABLO once: otomatik eslestirici 5 harften kisa kelimeleri atiyor
  #    ("cari", "oran"), o yuzden en buyuk konu gruplari otomatik eslesmiyor.
  #    Tablo ambarda ADI DOGRULANMIS notlara baglar; tutmazsa cozucuye duser.
  $c = $null
  $konuMetni = "$($s.konu)"
  foreach($e in $ESLESME){
    if($konuMetni -match $e.desen){
      $notMetni = TeoriNotuAdiyla $e.teori_notu
      if($notMetni){ $c = [ordered]@{ durum='cozuldu-teori'; ad=$e.teori_notu; metin=$notMetni }; }
      break
    }
  }
  # 2) tablo tutmadiysa SORUNUN KENDI KONUSUYLA cozucu - yanlis 'kaynak' alanina guvenilmez
  if(-not $c){ try { $c = KaynakCoz $konuMetni $konuMetni } catch {} }
  if(-not $c -or -not $c.metin){
    $kova.bulunamadi++
    $sb = if($c){ "$($c.durum)" } else { 'cagri-hatasi' }
    if($sebep.ContainsKey($sb)){ $sebep[$sb]++ } else { $sebep[$sb] = 1 }
    continue
  }
  $yeniKanun = $null; $yeniMadde = $null
  switch("$($c.durum)"){
    'cozuldu-teori'      { $yeniKanun='TEORI'; $yeniMadde="$($c.ad)"; $kova.teori++ }
    'cozuldu-standart'   { $yeniKanun='STD';   $yeniMadde="$($c.standart)"; $kova.standart++ }
    'cozuldu-hesapplani' { $yeniKanun='THP';   $yeniMadde="$($c.hesap)"; $kova.hesapplani++ }
    'cozuldu'            { $yeniKanun="$($c.kanun)"; $yeniMadde="$($c.madde)"; $kova.kanun++ }
    default              { $kova.bulunamadi++ }
  }
  if(-not $yeniKanun){ continue }
  if($yeniMadde.Length -gt 120){ $yeniMadde = $yeniMadde.Substring(0,120) }
  $plan.Add([pscustomobject]@{
    id="$($s.id)"; konu="$($s.konu)"; eski=("$kanun|$madde")
    yeni_kanun=$yeniKanun; yeni_madde=$yeniMadde; damga=(DamgaSade $c.metin); kaynak_ad="$($c.ad)"
  })
}
$toplamKova = 0; foreach($x in $kova.Keys){ $toplamKova += $kova[$x] }

Write-Host ''
Write-Host '======== DAYANAK YENIDEN BAGLAMA ========'
foreach($x in $kova.Keys){ Write-Host ("  {0,-12}: {1}" -f $x, $kova[$x]) }
Write-Host ("  {0,-12}: {1} / {2}  {3}" -f 'KOVA TOPLAMI', $toplamKova, $parti.Count, $(if($toplamKova -eq $parti.Count){'(tutuyor)'}else{'(TUTMUYOR)'}))
if($sebep.Count){
  Write-Host '  bulunamadi sebepleri:'
  foreach($sb in ($sebep.Keys | Sort-Object { -$sebep[$_] } | Select-Object -First 5)){ Write-Host ("     {0,-22} {1}" -f $sb, $sebep[$sb]) }
}
if($plan.Count){
  $ozet = @{}
  foreach($p in $plan){ $a = $p.yeni_kanun + ' :: ' + $p.kaynak_ad; if($ozet.ContainsKey($a)){ $ozet[$a]++ } else { $ozet[$a] = 1 } }
  Write-Host ''
  Write-Host '  YENI DAYANAK DAGILIMI:'
  foreach($a in ($ozet.Keys | Sort-Object { -$ozet[$_] } | Select-Object -First 10)){ Write-Host ("     {0,5}  {1}" -f $ozet[$a], $a) }
}

if(-not $uygula){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; hedef="$kanun|$madde"
    bulunan=$parti.Count; kovalar=$kova; kova_toplami=$toplamKova; hesap_tutuyor=($toplamKova -eq $parti.Count)
    bulunamadi_sebep=$sebep; ornek=$plan.ToArray() })
  Write-Host ''
  Write-Host 'OLCUM modu - kasaya hicbir sey yazilmadi. Yazmak icin: -uygula'
  exit 0
}
if($toplamKova -ne $parti.Count){ Write-Host 'KOVALAR TUTMUYOR - yazma yapilmadi.'; exit 1 }

$curlAd = if($env:OS -match 'Windows'){ 'curl.exe' } else { 'curl' }
$yazildi = 0; $hata = 0; $i = 0
foreach($p in $plan){
  $i++
  if(($i % 200) -eq 0){ Write-Host ("  yazilan {0}/{1}" -f $i, $plan.Count) }
  $gov = ConvertTo-Json -Compress -InputObject @{ kanun_no=$p.yeni_kanun; madde_no=$p.yeni_madde; madde_damga=$p.damga; kaynak=$p.kaynak_ad }
  $tmp = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($tmp,$gov,(New-Object Text.UTF8Encoding($false)))
  $kod = & $curlAd -s -o $(if($env:OS -match 'Windows'){'NUL'}else{'/dev/null'}) -w "%{http_code}" -X PATCH -H "apikey: $ANAHTAR" -H "Content-Type: application/json" -H "Prefer: return=minimal" -H "User-Agent: mevzuat-radar-robot/1.0" --data-binary "@$tmp" ("$U`?id=eq." + $p.id)
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  if("$kod" -eq '204'){ $yazildi++ } else { $hata++ }
  Start-Sleep -Milliseconds 90
}
Write-Host ("YAZILDI: {0} | hata: {1}" -f $yazildi, $hata)

$tutmayan = @()
$j = 0
foreach($p in $plan){
  $j++
  if(($j % 300) -eq 0){ Write-Host ("  geri okunan {0}/{1}" -f $j, $plan.Count) }
  # Uzun kosuda tek DNS/baglanti kopmasi geri okumayi dusurmesin (ilk kosuda oldu)
  $o = $null
  foreach($deneme in 1..3){
    try {
      $g = Invoke-WebRequest -Uri ("$U`?select=id,kanun_no,madde_no,madde_damga&id=eq." + $p.id) -Headers $BASLIK -UseBasicParsing -TimeoutSec 60
      $o = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($g.RawContentStream.ToArray())); break
    } catch { if($deneme -eq 3){ $tutmayan += ($p.id + ' (geri okunamadi)'); } else { Start-Sleep -Seconds (4*$deneme) } }
  }
  if($null -eq $o){ continue }
  $bulunan = $null; foreach($x in $o){ $bulunan = $x; break }
  if(-not $bulunan -or "$($bulunan.kanun_no)" -ne $p.yeni_kanun -or "$($bulunan.madde_damga)" -ne $p.damga){ $tutmayan += $p.id }
}
$durum = if($hata -eq 0 -and $tutmayan.Count -eq 0){ 'TAMAM' } else { 'KIRMIZI' }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mod='uygula'; hedef="$kanun|$madde"
  bulunan=$parti.Count; kovalar=$kova; baglanan=$plan.Count; yazildi=$yazildi; yazma_hatasi=$hata
  geri_okuma_tutmayan=$tutmayan.Count; tutmayan_ornek=@($tutmayan | Select-Object -First 20)
})
Write-Host ("GERI OKUMA: tutmayan {0}" -f $tutmayan.Count)
if($durum -eq 'KIRMIZI'){ exit 1 }
Write-Host 'TAMAM.'
