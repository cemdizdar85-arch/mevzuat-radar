# ============================================================================
#  KESIK MADDE ONARIMI — 25.08.2026
#  Cem: "1-2-3 yap"
#
#  KOK SEBEP (25.08'de bulundu - YENIDEN YUTMAK COZMEZ):
#  mevzuat.gov.tr PDF'inde her maddenin KENAR BASLIGI, "Madde N -" ibaresinin
#  ONUNDE durur. Bolucu "Madde N" gorunce basligi geriye dogru topluyor ve
#  BIR ONCEKI MADDENIN SON BENDINI de basliga katiyor. Sonuc:
#
#    m.269 metni  : "...3. Gemiler ve diger tasitlar; 4."        <- bent yarim
#    m.270 basligi: "Gayrimaddi haklar. Gayrimenkullerde ..."     <- bent BURADA
#
#  Uc vakada da dogrulandi (m.269->270, m.224->225, m.309->310).
#  METIN KAYBOLMAMIS, YANLIS YERE YAZILMIS. Bu yuzden onarim = tasima.
#  Kaynagi yeniden indirmek AYNI bolucuden gectigi icin ayni sonucu verir.
#
#  ⚠ VARSAYILAN KURU PROVA: hicbir sey yazilmaz, yalniz ONERI uretilir.
#  Yazmak icin -uygula gerekir. Ambar bu projenin en degerli varligi; toptan
#  duzeltme yasagi burada da gecerli (hesap kodu dersi: 40 adayin 31'i
#  istisna cikmisti).
#
#  Cikti: veri/kesik-madde-onarim-onerisi.json
# ============================================================================
param([switch]$uygula, [int]$sinir = 0)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok.'; exit 1 }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtar   = $env:SUPABASE_SERVICE_KEY
$basliklar = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot' }
$ambarUcu  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function OM_Cek([string]$adres){
  # ⚠ IKI TUZAK BIRDEN (25.08 dersleri):
  #   1) ConvertFrom-Json BORU HATTINDA diziyi katlar -> -InputObject sart.
  #   2) Fonksiyon TEK kayit dondurse dizi ACILIR; cagiran @() ile SARMALAMALI.
  $yanit  = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $basliklar -TimeoutSec 180
  $govde  = [Text.Encoding]::UTF8.GetString($yanit.RawContentStream.ToArray())
  $cozulen = ConvertFrom-Json -InputObject $govde
  return ,@($cozulen)
}

function OM_MaddeNo([string]$ad){
  if("$ad" -match '(?i)\bm\.\s*(\d{1,4})(/[A-Za-z])?\b'){ return $Matches[1] }
  return ''
}

function OM_YutulanBent([string]$sonrakiBaslik){
  # Sonraki maddenin basligindan, ONCEKI maddeye ait olan on-parcayi ayirir.
  # Desen: "<yutulan bent>. <gercek baslik>"  -> ilk cumleyi al.
  # Guvenlik: on-parca cok uzunsa ('.' yok ya da 120 karakteri asiyor) DOKUNMA.
  $b = "$sonrakiBaslik".Trim()
  $nokta = $b.IndexOf('.')
  if($nokta -lt 3 -or $nokta -gt 120){ return '' }
  $on = $b.Substring(0,$nokta+1).Trim()
  $kalan = $b.Substring($nokta+1).Trim()
  if($kalan.Length -lt 5){ return '' }          # geriye gercek baslik kalmiyor
  if($on -match '^\d+$'){ return '' }           # yalniz sayi: bent metni degil
  return $on
}

function OM_Sinav {
  # KAPI KENDI SINAVINI GECMELI.
  # SINANMAYAN DALLAR (25.08 dersi - gecen sinav kapinin TAMAMINI korumaz,
  # yalniz SINADIGI dali korur): ambar sorgusu · PATCH yazimi · madde no
  # eslestirmesi. Burada yalniz METIN AYIRMA mantigi sinanir.
  $dusen = @()
  $vaka = @(
    @{ baslik='Gayrimaddi haklar. Gayrimenkullerde maliyet bedeline giren giderler'; bekle='Gayrimaddi haklar.' }
    @{ baslik='Tasdiki yapan makamin resmi muhur ve imzasi. Tasdik sekli';           bekle='Tasdiki yapan makamin resmi muhur ve imzasi.' }
    @{ baslik='Meskun yerlere, iskele ve istasyonlara yakinligi. Kiymet rayicleri';  bekle='Meskun yerlere, iskele ve istasyonlara yakinligi.' }
    @{ baslik='Isletme hesabi esasinda envanter';   bekle='' }   # tek cumle: yutulan bent YOK
    @{ baslik='Arazi kiymeti';                      bekle='' }   # nokta yok
    @{ baslik='4.';                                 bekle='' }   # yalniz sayi
  )
  foreach($v in $vaka){
    $cikan = OM_YutulanBent $v.baslik
    if("$cikan" -ne "$($v.bekle)"){ $dusen += ("AYIRMA YANLIS: '$($v.baslik)' -> beklenen '$($v.bekle)' cikan '$cikan'") }
  }
  return $dusen
}

$sinavDusen = @(OM_Sinav)
if($sinavDusen.Count){
  Write-Host '!! ONARIM KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $sinavDusen){ Write-Host "   $d" }
  exit 1
}
Write-Host 'Oz-sinav: 6/6 vaka gecti (3 yutulan bent bulundu, 3 temiz baslik rahat birakildi)'
Write-Host '  SINANMAYAN DALLAR: ambar sorgusu · PATCH yazimi · madde no eslestirmesi'
Write-Host ''

# --- kesik belgeleri nobetci raporundan al
$raporYolu = Join-Path $depoKok 'veri/kesik-metin-raporu.json'
if(-not (Test-Path $raporYolu)){ Write-Host 'Once motor\kesik-metin-nobeti.ps1 kosulmali.'; exit 1 }
$hamRapor = [IO.File]::ReadAllText($raporYolu,[Text.Encoding]::UTF8)
$cozRapor = ConvertFrom-Json -InputObject $hamRapor
$kesikler = @($cozRapor.belgeler)
Write-Host ("Kesik belge: {0}  (rapor {1})" -f $kesikler.Count, $cozRapor.tarih)

$oneriler = New-Object System.Collections.Generic.List[object]
$atlanan  = @{ 'madde no yok'=0; 'sonraki madde yok'=0; 'yutulan bent yok'=0 }
$sayac = 0
foreach($kesik in $kesikler){
  $sayac++
  if($sinir -gt 0 -and $oneriler.Count -ge $sinir){ break }
  $ad = "$($kesik.kaynak_ad)"
  $no = OM_MaddeNo $ad
  if(-not $no){ $atlanan['madde no yok']++; continue }
  # ayni kanunun bir sonraki maddesi: "... m.<no+1>" ile BASLAYAN kayit
  $onEk = $ad.Substring(0, $ad.IndexOf("m.$no")) + ('m.' + ([int]$no + 1))
  try {
    $sonraki = @(OM_Cek ("$ambarUcu`?select=id,kaynak_ad,metin&kaynak_ad=like." + [uri]::EscapeDataString("$onEk*") + "&limit=1"))
  } catch { $atlanan['sonraki madde yok']++; continue }
  if($sonraki.Count -lt 1 -or -not $sonraki[0].kaynak_ad){ $atlanan['sonraki madde yok']++; continue }
  $sonrakiAd = "$($sonraki[0].kaynak_ad)"
  # kaynak_ad'in "m.N - " sonrasi = baslik
  $bas = ''
  if($sonrakiAd -match '(?i)m\.\d+[A-Za-z/]*\s*-\s*(.+)$'){ $bas = $Matches[1] }
  if(-not $bas){ $atlanan['yutulan bent yok']++; continue }
  $yutulan = OM_YutulanBent $bas
  if(-not $yutulan){ $atlanan['yutulan bent yok']++; continue }
  $eskiMetin = "$($kesik.son_60)"
  $oneriler.Add([ordered]@{
    id           = "$($kesik.id)"
    kaynak_ad    = $ad
    biten        = $eskiMetin.Trim()
    sonraki_ad   = $sonrakiAd
    eklenecek    = $yutulan
    yeni_son     = ($eskiMetin.Trim() + ' ' + $yutulan)
  })
}

Write-Host ''
Write-Host ("ONERI URETILEN : {0}" -f $oneriler.Count)
foreach($a in $atlanan.GetEnumerator()){ Write-Host ("  atlandi ({0}): {1}" -f $a.Key,$a.Value) }
Write-Host ''
$g = 0
foreach($o in $oneriler){
  $g++; if($g -gt 12){ break }
  Write-Host ("  {0}" -f $o.kaynak_ad.Substring(0,[Math]::Min(52,$o.kaynak_ad.Length)))
  Write-Host ("     su an : ...{0}" -f $o.biten)
  Write-Host ("     ekle   : `"{0}`"" -f $o.eklenecek)
}
if($oneriler.Count -gt 12){ Write-Host ("  ... ve {0} oneri daha" -f ($oneriler.Count-12)) }

$duz=@(); foreach($o in $oneriler){ $duz += ,([pscustomobject]$o) }
[IO.File]::WriteAllText((Join-Path $depoKok 'veri/kesik-madde-onarim-onerisi.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kesik=$kesikler.Count
    oneri=$duz.Count; uygulandi=[bool]$uygula; oneriler=$duz }) -Depth 8),
  (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host '-> veri/kesik-madde-onarim-onerisi.json'
if(-not $uygula){
  Write-Host ''
  Write-Host 'KURU PROVA — hicbir sey yazilmadi. Onerileri OKU, sonra -uygula ile kos.'
  exit 0
}

# --- UYGULA
Write-Host ''
Write-Host 'UYGULANIYOR...'
$yazilan=0; $hata=0
foreach($o in $oneriler){
  try {
    $mevcut = @(OM_Cek ("$ambarUcu`?select=metin&id=eq." + $o.id))
    if($mevcut.Count -lt 1){ $hata++; continue }
    $yeni = ("$($mevcut[0].metin)".TrimEnd() + ' ' + $o.eklenecek)
    $govde = (ConvertTo-Json -InputObject @{ metin = $yeni })
    $null = Invoke-RestMethod -Method Patch -Uri ("$ambarUcu`?id=eq." + $o.id) `
      -Headers ($basliklar + @{ Prefer='return=minimal' }) `
      -ContentType 'application/json; charset=utf-8' `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 90
    $yazilan++
  } catch { $hata++; Write-Host ("  !! {0}: {1}" -f $o.kaynak_ad, $_.Exception.Message) }
}
Write-Host ("yazilan: {0} · hata: {1}" -f $yazilan,$hata)
Write-Host 'SIRADAKI: motor\soru-damga-tazele.ps1 ile bagli sorulari yeniden damgala.'