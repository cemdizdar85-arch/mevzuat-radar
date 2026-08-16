# ============================================================================
#  SORU DAMGA DENETIMI — "dayandigi mevzuat metni degismis mi?"  (16.08.2026)
#
#  Cem'in sorusu: "tebligleri okumustuk sanki; sinav icin okumaz isek cikan
#  sinavlarda yanlis olmaz mi?" Cevabin olculmesi gereken yer burasi.
#
#  YONTEM: her sorunun kaynagi, soru hattinin KENDI cozucusuyle (madde-coz.ps1
#  / KaynakCoz) bugunku ambardan cozulur, metnin damgasi YENIDEN hesaplanir ve
#  soruda SAKLI damgayla kiyaslanir.
#     ayni  -> dayanak metni degismemis
#     farkli-> metin o gunden beri DEGISMIS (ya da damga baska formulle yazilmis)
#
#  ONEMLI (16.08 olcumu): kasadaki damgalarin bir kismi HAM metin uzerinden
#  (Sadelestir uygulanmadan) yazilmis. Bu yuzden IKI formul de denenir ve
#  hangisinin tuttugu ayri ayri sayilir. Formul karmasasi giderilmeden
#  "degisti" demek YANLIS OLUR - bu betik once o karmasayi OLCER.
#
#  HICBIR SORU SESSIZCE ATLANMAZ: her kayit tam olarak bir kovaya duser ve
#  kovalarin toplami taranan sayisina esittir (rapor bunu dogrular).
#
#  VARSAYILAN: OLCUM - kasaya HICBIR SEY yazilmaz. Yazmak icin -uygula.
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/soru-damga-denetimi.json
# ============================================================================
param(
  [switch]$uygula,
  [int]$sinir = 0            # yalniz ilk N soru (deneme partisi icin)
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
# Supabase gizli anahtarli istek KIMLIKSIZ gelirse 401 doner - iki satir sart.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY = $env:SUPABASE_SERVICE_KEY
if([string]::IsNullOrWhiteSpace($KEY)){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY; Authorization=("Bearer "+$KEY) }
$raporYol = Join-Path $kok 'veri/soru-damga-denetimi.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# cozucu kutuphanesi (kasa-bag.ps1 ile ayni yol)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- IKI FORMUL: kasadaki damgalar ikisinden biriyle yazilmis olabilir
function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '\s+', ' '
  return $x.Trim()
}
function Hash16([string]$t){
  $sha = [Security.Cryptography.SHA256]::Create()
  return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))) -replace '-','').Substring(0,16).ToLowerInvariant()
}
function DamgaSade([string]$t){ return Hash16 (Sadelestir $t) }   # madde-damga.ps1 / bugunku kasa-bag
function DamgaHam([string]$t){ return Hash16 $t }                 # kasadaki eski damgalarin bir kismi

# --- kasayi cek
Write-Host 'Kasa cekiliyor...'
$kasaSatirlari = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  # soru + siklar da cekilir: atif dogrulugu ancak sorunun KENDI metnine
  # bakarak olculebilir (THP 380 <-> 180 vakasi soyle yakalandi).
  $sayfa = "$U`?select=id,ders,kaynak,kanun_no,madde_no,madde_damga,yayin,yayin_notu,soru,siklar&order=id&limit=1000&offset=$bas"
  $r = Invoke-WebRequest -Uri $sayfa -Headers $H -UseBasicParsing -TimeoutSec 300
  # PS 5.1 TUZAGI (16.08 olculdu): @($metin | ConvertFrom-Json) bir JSON DIZISINI
  # TEK nesne sayar -> 1000 kayit "1 kayit" gorunur ve dongu ilk sayfada biter.
  # -InputObject ile cagrilip SONRA @() ile sarilmali. Sessiz veri kaybi sinifi.
  # DIKKAT: bu kapsamda @(...) sarmalayicisi guvenilmez davraniyor (1000 kayitlik
  # diziyi 1 sayiyor, List uzerinde ArgumentException firlatiyor). Bu yuzden
  # HIC @() kullanilmiyor; kayitlar dogrudan sayilarak ekleniyor.
  $sayfaGovdesi = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  $cozulmus = ConvertFrom-Json -InputObject $sayfaGovdesi
  $sayfaAdet = 0
  foreach($satir in $cozulmus){ [void]$kasaSatirlari.Add($satir); $sayfaAdet++ }
  Write-Host ("  sayfa offset={0}: govde {1} bayt, {2} kayit" -f $bas, $sayfaGovdesi.Length, $sayfaAdet)
  if($sayfaAdet -eq 0){ break }
  $bas += 1000
  if($sayfaAdet -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasaSatirlari.Count)
# DIKKAT: @($list) bu ortamda ArgumentException firlatiyor; ToArray() kullan.
# Ayrica degisken adi UZUN ve BENZERSIZ - dot-source edilen madde-coz.ps1 ile
# ad cakismasi sessizce veri kaybettirir ([[ps-degisken-cakismasi]]).
$parti = $kasaSatirlari.ToArray()
if($sinir -gt 0 -and $sinir -lt $parti.Count){ $parti = $parti[0..($sinir-1)] }

# --- kovalar (toplamlari taranan sayisina ESIT olmali)
$k = [ordered]@{
  damgasiz      = 0   # soruda madde_damga yok -> kiyaslanamaz
  kaynaksiz     = 0   # kaynak alani bos
  cozulemedi    = 0   # cozucu ambarda bulamadi
  tutan_sade    = 0   # Sadelestir'li formulle tuttu -> metin DEGISMEMIS
  tutan_ham     = 0   # ham formulle tuttu -> metin DEGISMEMIS (eski formul)
  atif_supheli  = 0   # kaynagin gosterdigi KOD soruda hic gecmiyor -> ATIF YANLIS
  metin_degismis= 0   # kanun maddesi; iki formul de tutmadi -> METIN DEGISMIS
  yeniden_yutma = 0   # STD/THP; atif tutuyor ama damga tutmuyor -> parcalama/formul
}

# ============================================================================
#  ATIF DENETIMI (16.08 - elle okuma sonucu dogdu)
#  Okunan iki ornekten biri sunu gosterdi: soru "gelecek aylara ait GIDER"i
#  (180) anlatiyor, dayanagi ise "THP 380 - Gelecek Aylara Ait GELIRLER"
#  gosteriyor. Soru DOGRU, ATIF YANLIS. Bu, mevzuat degisikliginden bagimsiz
#  ve daha tehlikeli bir kusur: hakem yanlis metne bakip "destekliyor" der ve
#  hata DOGRULANMIS gibi gecer.
#
#  OLCUT (temkinli): yalniz KODU KESIN olan kaynaklarda calisir.
#   - THP <kod>  : kod soruda/siklarda hic gecmiyorsa supheli
#   - TMS/TFRS/BDS <no> : standart adi+no soruda/siklarda hic gecmiyorsa supheli
#  Kanun maddelerinde UYGULANMAZ - sorular madde numarasini cogu zaman
#  yazmaz, uygulanirsa yanlis alarm yagar. Emin olamadigina kusur demeyiz.
# ============================================================================
function AtifSupheliMi([string]$kaynak, [string]$soruMetni){
  if([string]::IsNullOrWhiteSpace($kaynak) -or [string]::IsNullOrWhiteSpace($soruMetni)){ return $false }
  $thp = [regex]::Match($kaynak, '(?i)\bTHP\s*(\d{3})\b')
  if($thp.Success){
    $kod = $thp.Groups[1].Value
    return (-not ($soruMetni -match ("(?<!\d)" + $kod + "(?!\d)")))
  }
  $std = [regex]::Match($kaynak, '(?i)\b(TMS|TFRS|BDS)\s*(\d{1,3})\b')
  if($std.Success){
    $ad = $std.Groups[1].Value; $no = $std.Groups[2].Value
    return (-not ($soruMetni -match ("(?i)" + $ad + "\s*" + $no + "(?!\d)")))
  }
  return $false
}
$dersDagilim = @{}; $kanunDagilim = @{}; $cozHata = @{}
$bayrakli = New-Object System.Collections.Generic.List[object]
$n = 0
foreach($s in $parti){
  $n++
  if(($n % 500) -eq 0){ Write-Host ("  ...{0}/{1}" -f $n, $parti.Count) }
  $damga = "$($s.madde_damga)"
  if([string]::IsNullOrWhiteSpace($damga)){ $k.damgasiz++; continue }
  $kay = "$($s.kaynak)"
  if([string]::IsNullOrWhiteSpace($kay)){ $k.kaynaksiz++; continue }
  $c = $null
  try { $c = KaynakCoz $kay } catch { }
  if(-not $c -or -not $c.metin){
    $k.cozulemedi++
    $sb = if($c){ "$($c.durum)" } else { 'cagri-hatasi' }
    if($cozHata.ContainsKey($sb)){ $cozHata[$sb]++ } else { $cozHata[$sb] = 1 }
    continue
  }
  if((DamgaSade $c.metin) -eq $damga){ $k.tutan_sade++; continue }
  if((DamgaHam  $c.metin) -eq $damga){ $k.tutan_ham++;  continue }

  # --- UC KOVAYA AYIR (tek "degismis" yorumlanamaz bir sayiydi)
  $ders = "$($s.ders)"; $kn = "$($s.kanun_no)"
  $soruMetni = "$($s.soru)"
  foreach($harf in @('A','B','C','D','E')){ try { $soruMetni += ' ' + "$($s.siklar.$harf)" } catch {} }
  $sinif = ''
  if(AtifSupheliMi $kay $soruMetni){ $sinif = 'atif_supheli'; $k.atif_supheli++ }
  elseif($kn -match '^\d+$'){        $sinif = 'metin_degismis'; $k.metin_degismis++ }
  else {                             $sinif = 'yeniden_yutma'; $k.yeniden_yutma++ }

  if($dersDagilim.ContainsKey($ders)){ $dersDagilim[$ders]++ } else { $dersDagilim[$ders] = 1 }
  if($kanunDagilim.ContainsKey($kn)){ $kanunDagilim[$kn]++ } else { $kanunDagilim[$kn] = 1 }
  $bayrakli.Add([pscustomobject]@{ id="$($s.id)"; sinif=$sinif; ders=$ders; kaynak=$kay; kanun_no=$kn; madde_no="$($s.madde_no)"; yayin_notu="$($s.yayin_notu)" })
}

$toplamKova = 0; foreach($x in $k.Keys){ $toplamKova += $k[$x] }
$hesapTutuyor = ($toplamKova -eq $parti.Count)

Write-Host ''
Write-Host '======== SORU DAMGA DENETIMI ========'
foreach($x in $k.Keys){ Write-Host ("  {0,-14}: {1}" -f $x, $k[$x]) }
Write-Host ("  {0,-14}: {1} / {2}  {3}" -f 'KOVA TOPLAMI', $toplamKova, $parti.Count, $(if($hesapTutuyor){'(tutuyor)'}else{'(TUTMUYOR - kovalar eksik!)'}))
$bayrakToplam = $k.atif_supheli + $k.metin_degismis + $k.yeniden_yutma
$kiyaslanan = $k.tutan_sade + $k.tutan_ham + $bayrakToplam
if($kiyaslanan -gt 0){
  Write-Host ("  kiyaslanabilen : {0} | BAYRAKLI: {1} (%{2})" -f $kiyaslanan, $bayrakToplam, [math]::Round(100*$bayrakToplam/$kiyaslanan,1))
  Write-Host ("     atif_supheli  : {0}  <-- EN DEGERLI: soru dogru olabilir ama DAYANAGI yanlis" -f $k.atif_supheli)
  Write-Host ("     metin_degismis: {0}  <-- kanun metni gercekten degismis, insan okumali" -f $k.metin_degismis)
  Write-Host ("     yeniden_yutma : {0}  <-- metin ayni, damga bayat; tazelenir, soruya dokunulmaz" -f $k.yeniden_yutma)
}
if($cozHata.Count){
  Write-Host '  cozulemedi sebepleri:'
  foreach($sb in ($cozHata.Keys | Sort-Object { -$cozHata[$_] } | Select-Object -First 6)){ Write-Host ("     {0,-24} {1}" -f $sb, $cozHata[$sb]) }
}

RaporYaz ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum = if($uygula){'UYGULA'}else{'OLCUM'}
  taranan = $parti.Count
  kovalar = $k
  kova_toplami = $toplamKova
  hesap_tutuyor = $hesapTutuyor
  bayrak_toplam = $bayrakToplam
  bayrak_orani = $(if($kiyaslanan -gt 0){ [math]::Round(100*$bayrakToplam/$kiyaslanan,1) } else { 0 })
  cozulemedi_sebep = $cozHata
  ders_dagilimi = $dersDagilim
  kanun_dagilimi = $kanunDagilim
  ornek = @($bayrakli | Select-Object -First 100)
  not = 'tutan_ham = damga eski (Sadelestir siz) formulle yazilmis ama METIN AYNI. atif_supheli = kaynagin gosterdigi kod soruda hic gecmiyor (THP 380 <-> 180 vakasi). metin_degismis = kanun metni degismis. yeniden_yutma = metin ayni, damga bayat.'
})
Write-Host ("-> veri/soru-damga-denetimi.json")

if(-not $uygula){
  Write-Host ''
  Write-Host 'OLCUM modu - kasaya hicbir sey yazilmadi. Yazmak icin: -uygula'
  exit 0
}

# --- UYGULA: bayrakli sorulari yayindan cek (mevcut nobetcinin kalibi)
if(-not $hesapTutuyor){ Write-Host 'KOVALAR TUTMUYOR - guvenli degil, yazma yapilmadi.'; exit 1 }
$curlAd = if($env:OS -match 'Windows'){ 'curl.exe' } else { 'curl' }
$yazildi = 0; $atlandi = 0; $hata = 0
foreach($b in $bayrakli){
  if("$($b.yayin_notu)" -match 'mevzuat-degisti'){ $atlandi++; continue }
  $yeniNot = if("$($b.yayin_notu)".Trim()){ "$($b.yayin_notu)" + ' | mevzuat-degisti: dayanak metni degismis' }
             else { 'mevzuat-degisti ' + (Get-Date -Format 'dd.MM.yyyy') + ': dayanak metni degismis - hakem+GM yeniden yargilamali' }
  $gov = ConvertTo-Json -Compress -InputObject @{ yayin=$false; yayin_notu=$yeniNot }
  $tmp = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($tmp,$gov,(New-Object Text.UTF8Encoding($false)))
  $kod = & $curlAd -s -o $(if($env:OS -match 'Windows'){'NUL'}else{'/dev/null'}) -w "%{http_code}" -X PATCH -H "apikey: $KEY" -H "Content-Type: application/json" -H "Prefer: return=minimal" -H "User-Agent: mevzuat-radar-robot/1.0" --data-binary "@$tmp" ("$U`?id=eq." + $b.id)
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  if("$kod" -eq '204'){ $yazildi++ } else { $hata++ }
  Start-Sleep -Milliseconds 300
}
Write-Host ("YAZILDI: {0} | zaten isaretli: {1} | hata: {2}" -f $yazildi, $atlandi, $hata)

# --- GERI OKUMA: yazilan her satir dogrulanir (yesil kosu != tam veri)
$tutmayan = @()
foreach($b in ($bayrakli | Where-Object { "$($_.yayin_notu)" -notmatch 'mevzuat-degisti' })){
  $g = Invoke-WebRequest -Uri ("$U`?select=id,yayin,yayin_notu&id=eq." + $b.id) -Headers $H -UseBasicParsing -TimeoutSec 60
  $oHam = [Text.Encoding]::UTF8.GetString($g.RawContentStream.ToArray())
  $o = @(ConvertFrom-Json -InputObject $oHam)
  if($o.Count -eq 0){ $tutmayan += "$($b.id): geri okunamadi"; continue }
  if($o[0].yayin -ne $false -or "$($o[0].yayin_notu)" -notmatch 'mevzuat-degisti'){ $tutmayan += "$($b.id)" }
}
$durum = if($hata -eq 0 -and $tutmayan.Count -eq 0){ 'TAMAM' } else { 'KIRMIZI' }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mod='uygula'
  taranan=$parti.Count; kovalar=$k; yazildi=$yazildi; zaten_isaretli=$atlandi; yazma_hatasi=$hata
  geri_okuma_tutmayan=$tutmayan.Count; tutmayan_ornek=@($tutmayan | Select-Object -First 20)
})
Write-Host ("GERI OKUMA: tutmayan {0}" -f $tutmayan.Count)
if($durum -eq 'KIRMIZI'){ exit 1 }
