# ============================================================================
#  AMBAR DENETIMI — 28.07.2026
#
#  NEDEN VAR (Cem kurali): "kanun maddeleri kendi resmi sitesinden okunacak,
#  baska bir yerden degil". Ayrica GM 28.07'de 590 soruyu AMBARA BAKARAK yargiladi.
#  Yani ambar artik HAKEM. Hakemin kendisi hic denetlenmedi.
#
#  Bu betik ambari denetler, PARA HARCAMAZ (yalniz okuma), ve kirmizi/yesil verir.
#  Kirmizi cikarsa profesor v2 kosturulmaz - bozuk kaynakla yargilama yapilmaz.
#
#  KONTROLLER
#   1) KAYNAK MESRUIYETI  : her kaydin kaynak_url'i RESMI alan adinda mi
#   2) KESIK METIN        : 1800 karakter tavaninda takilip cumle ortasinda biten
#   3) SUPHELI KISA       : cok kisa metin (madde govdesi kaybolmus olabilir)
#   4) MADDE SUREKLILIGI  : bir kanunda m.1..m.N arasinda EKSIK madde var mi
#   5) MUKERRER KAYIT     : ayni kaynak_ad birden fazla kez (parcali olanlar haric)
#   6) PARCA BUTUNLUGU    : "[2/5]" varsa [1/5]..[5/5] hepsi var mi
# ============================================================================
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
$KEY = if($env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY } else { "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg" }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# Cem kurali: yalniz bu alan adlari mesru kaynaktir.
$RESMI = @(
  'mevzuat.gov.tr',        # Cumhurbaskanligi Mevzuat Bilgi Sistemi - kanunlarin resmi metni
  'resmigazete.gov.tr',    # Resmi Gazete
  'gib.gov.tr',            # Gelir Idaresi Baskanligi (teblig/rehber/ozelge)
  'kgk.gov.tr',            # Kamu Gozetimi Kurumu (TMS/TFRS/BDS)
  'turmob.org.tr',         # TURMOB (meslek mevzuati)
  'tesmer.org.tr',         # TESMER
  'sgk.gov.tr',            # SGK
  'ticaret.gov.tr'         # Ticaret Bakanligi (gumruk)
)

Write-Host "AMBAR DENETIMI basliyor..."
$kayitlar = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $sayfa = Invoke-RestMethod -Uri "$SB_URL/rest/v1/dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($sayfa)
  if($d.Count -eq 0){ break }
  foreach($x in $d){ $kayitlar.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
  Write-Host ("  ...{0}" -f $kayitlar.Count)
}
Write-Host ("Okundu: {0} kayit" -f $kayitlar.Count)

$bulgu = [ordered]@{
  kaynak_disi = New-Object System.Collections.Generic.List[object]
  kesik       = New-Object System.Collections.Generic.List[object]
  supheli_kisa= New-Object System.Collections.Generic.List[object]
  madde_bosluk= New-Object System.Collections.Generic.List[object]
  mukerrer    = New-Object System.Collections.Generic.List[object]
  parca_eksik = New-Object System.Collections.Generic.List[object]
}

# ---- 1) KAYNAK MESRUIYETI
Write-Host "  [1/6] kaynak mesruiyeti..."
# 28.07 DUZELTME: 'teori-notu' turu BIZIM kendi yazdigimiz aciklamalardir; disaridan
# alinmadigi icin kaynak_url'i olmamasi normaldir - kanun metni degildir, kural anlatimidir.
# Denetim yalniz MEVZUAT metinlerini (kanun-madde / standart-madde / teblig) baglar.
foreach($k in $kayitlar){
  if("$($k.tur)" -eq 'teori-notu'){ continue }
  $u = "$($k.kaynak_url)"
  $ok = $false
  foreach($d in $RESMI){ if($u -like "*$d*"){ $ok = $true; break } }
  if(-not $ok){ $bulgu.kaynak_disi.Add([ordered]@{ id=$k.id; tur=$k.tur; kaynak_ad=$k.kaynak_ad; url=$u }) }
}

# ---- 2) KESIK METIN: 1800 tavanina yapisik VE cumle sonu olmayan
Write-Host "  [2/6] kesik metin..."
# 28.07 DUZELTME: "[4/9]" gibi PARCALI kayitlarda bir parcanin cumle ortasinda bitmesi
# NORMALDIR - devami sonraki parcadadir ve [6] kontrolu tum parcalarin varligini dogruluyor.
# GERCEK kesinti, TEK PARCA olan (yani devami olmayan) bir kaydin 1800 tavaninda
# cumle ortasinda bitmesidir; veri orada gercekten kaybolmustur.
foreach($k in $kayitlar){
  $ad = "$($k.kaynak_ad)"
  if($ad -match '\[\d+/\d+\]\s*$'){ continue }   # parcali -> devami var, kesik degil
  $m = "$($k.metin)"
  if($m.Length -ge 1790 -and $m.Length -le 1805){
    $son = $m.TrimEnd()
    if($son.Length -gt 0 -and $son[-1] -notin @('.',')',']','"',';',':')){
      $bulgu.kesik.Add([ordered]@{ id=$k.id; kaynak_ad=$ad; uzunluk=$m.Length; son60=$son.Substring([Math]::Max(0,$son.Length-60)) })
    }
  }
}

# ---- 3) SUPHELI KISA: kisa metin ama "yururluge girer / yurutur" gibi mesru kisa
#         maddeler haric tutulur
Write-Host "  [3/6] supheli kisa metin..."
foreach($k in $kayitlar){
  $m = "$($k.metin)".Trim()
  if($m.Length -ge 160){ continue }
  if($m -match 'y[uü]r[uü]rl[uü][gğ]e girer|y[uü]r[uü]t[uü]r|kald[iı]r[iı]lm[iı][sş]|m[uü]lga'){ continue }
  $bulgu.supheli_kisa.Add([ordered]@{ id=$k.id; kaynak_ad=$k.kaynak_ad; uzunluk=$m.Length; metin=$m })
}

# ---- 4) MADDE SUREKLILIGI: kanun bazinda m.N dizisinde bosluk
Write-Host "  [4/6] madde surekliligi..."
$kanunMadde = @{}
foreach($k in $kayitlar){
  $ad = "$($k.kaynak_ad)" -replace '\s*\[\d+/\d+\]\s*$',''
  # 28.07 DUZELTME: eski desen "m.NN" ile BITEN kayitlari ariyordu. Oysa ambardaki
  # kayitlarin cogu "KDVK (3065 s.K.) m.2 - Teslim" gibi madde numarasindan sonra
  # BASLIK tasiyor. Eski desen bunlari goremedigi icin KDV Kanunu'nun 63 maddesinin
  # 53'unu "eksik" sandi ve sahte alarm uretti. Artik baslik eki opsiyonel.
  $mm = [regex]::Match($ad, '^(?<kanun>.+?)\s+(?<ek>ek\s+|gec\.\s+|geç\.\s+)?m\.(?<no>\d+)(/[A-Za-z0-9]+)?(\s*[-–—:]\s*.*)?$')
  if(-not $mm.Success){ continue }
  if($mm.Groups['ek'].Success){ continue }   # ek/gecici maddeler ayri seri
  $kn = $mm.Groups['kanun'].Value.Trim()
  $no = [int]$mm.Groups['no'].Value
  if(-not $kanunMadde.ContainsKey($kn)){ $kanunMadde[$kn] = New-Object System.Collections.Generic.HashSet[int] }
  [void]$kanunMadde[$kn].Add($no)
}
foreach($kn in $kanunMadde.Keys){
  $set = $kanunMadde[$kn]
  if($set.Count -lt 10){ continue }          # kucuk kumelerde bosluk anlamli degil
  $enb = ($set | Measure-Object -Maximum).Maximum
  # GUVENLIK: bozuk bir kaynak_ad'dan devasa madde numarasi parse edilirse dongu
  # milyonlarca tur doner. Turkiye'de en uzun kanun TTK ~1535 madde; 3000 fazlasiyla yeter.
  if($enb -gt 3000){
    $bulgu.madde_bosluk.Add([ordered]@{ kanun=$kn; en_buyuk_madde=$enb; mevcut=$set.Count; eksik_adet=-1; eksik=@(); not="madde numarasi anormal buyuk - kaynak_ad bozuk olabilir, sureklilik kontrolu atlandi" })
    continue
  }
  $eksikL = New-Object System.Collections.Generic.List[int]
  for($i=1; $i -le $enb; $i++){ if(-not $set.Contains($i)){ [void]$eksikL.Add($i) } }
  $eksik = @($eksikL)
  if($eksik.Count -gt 0){
    $bulgu.madde_bosluk.Add([ordered]@{ kanun=$kn; en_buyuk_madde=$enb; mevcut=$set.Count; eksik_adet=$eksik.Count; eksik=@($eksik | Select-Object -First 40) })
  }
}

# ---- 5) MUKERRER kaynak_ad
Write-Host "  [5/6] mukerrer kaynak_ad..."
$adSay = @{}
foreach($k in $kayitlar){ $a="$($k.kaynak_ad)"; if($adSay.ContainsKey($a)){ $adSay[$a]++ } else { $adSay[$a]=1 } }
foreach($a in $adSay.Keys){ if($adSay[$a] -gt 1){ $bulgu.mukerrer.Add([ordered]@{ kaynak_ad=$a; adet=$adSay[$a] }) } }

# ---- 6) PARCA BUTUNLUGU: "[2/5]" varsa 1..5 tam mi
Write-Host "  [6/6] parca butunlugu..."
$parca = @{}
foreach($k in $kayitlar){
  $pm = [regex]::Match("$($k.kaynak_ad)", '^(?<ad>.+?)\s*\[(?<i>\d+)/(?<n>\d+)\]\s*$')
  if(-not $pm.Success){ continue }
  $ad = $pm.Groups['ad'].Value.Trim(); $i=[int]$pm.Groups['i'].Value; $n=[int]$pm.Groups['n'].Value
  $anahtar = "$ad|$n"
  if(-not $parca.ContainsKey($anahtar)){ $parca[$anahtar] = New-Object System.Collections.Generic.HashSet[int] }
  [void]$parca[$anahtar].Add($i)
}
foreach($a in $parca.Keys){
  $ad,$n = $a -split '\|'
  $n = [int]$n
  $eks = @()
  for($i=1; $i -le $n; $i++){ if(-not $parca[$a].Contains($i)){ $eks += $i } }
  if($eks.Count -gt 0){ $bulgu.parca_eksik.Add([ordered]@{ kaynak_ad=$ad; beklenen=$n; eksik_parca=$eks }) }
}

# ---- RAPOR
Write-Host ""
Write-Host "================ AMBAR DENETIM RAPORU ================"
Write-Host ("  toplam kayit                 : {0}" -f $kayitlar.Count)
Write-Host ("  1) resmi olmayan kaynak      : {0}" -f $bulgu.kaynak_disi.Count)
Write-Host ("  2) kesik metin (1800 tavani) : {0}" -f $bulgu.kesik.Count)
Write-Host ("  3) supheli kisa metin        : {0}" -f $bulgu.supheli_kisa.Count)
Write-Host ("  4) madde bosluğu olan kanun  : {0}" -f $bulgu.madde_bosluk.Count)
Write-Host ("  5) mukerrer kaynak_ad        : {0}" -f $bulgu.mukerrer.Count)
Write-Host ("  6) eksik parcali belge       : {0}" -f $bulgu.parca_eksik.Count)

if($bulgu.kaynak_disi.Count -gt 0){
  Write-Host ""
  Write-Host "  --- RESMI OLMAYAN KAYNAK (ilk 10):"
  $bulgu.kaynak_disi | Select-Object -First 10 | ForEach-Object { Write-Host ("     {0}  ->  {1}" -f $_.kaynak_ad, $_.url) }
}
if($bulgu.kesik.Count -gt 0){
  Write-Host ""
  Write-Host "  --- KESIK METIN (ilk 8):"
  $bulgu.kesik | Select-Object -First 8 | ForEach-Object { Write-Host ("     {0} ({1} kr) ...{2}" -f $_.kaynak_ad, $_.uzunluk, $_.son60) }
}
if($bulgu.supheli_kisa.Count -gt 0){
  Write-Host ""
  Write-Host "  --- SUPHELI KISA (ilk 8):"
  $bulgu.supheli_kisa | Select-Object -First 8 | ForEach-Object { Write-Host ("     {0} ({1} kr): {2}" -f $_.kaynak_ad, $_.uzunluk, $_.metin) }
}
if($bulgu.madde_bosluk.Count -gt 0){
  Write-Host ""
  Write-Host "  --- MADDE BOSLUGU (ilk 8 kanun):"
  $bulgu.madde_bosluk | Sort-Object eksik_adet -Descending | Select-Object -First 8 | ForEach-Object { Write-Host ("     {0}: m.1-{1} arasinda {2} madde EKSIK (mevcut {3})" -f $_.kanun, $_.en_buyuk_madde, $_.eksik_adet, $_.mevcut) }
}

$rapor = [ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm")
  toplam_kayit = $kayitlar.Count
  resmi_alan_adlari = $RESMI
  ozet = [ordered]@{
    resmi_olmayan_kaynak = $bulgu.kaynak_disi.Count
    kesik_metin = $bulgu.kesik.Count
    supheli_kisa = $bulgu.supheli_kisa.Count
    madde_boslugu_olan_kanun = $bulgu.madde_bosluk.Count
    mukerrer_kaynak_ad = $bulgu.mukerrer.Count
    eksik_parcali_belge = $bulgu.parca_eksik.Count
  }
  bulgular = $bulgu
}
$yol = Join-Path $kok "veri/ambar-denetim-raporu.json"
[IO.File]::WriteAllText($yol, ($rapor | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("-> rapor: veri/ambar-denetim-raporu.json")

# ---- KARAR: hakem guvenilir mi
$agir = $bulgu.kaynak_disi.Count + $bulgu.kesik.Count + $bulgu.parca_eksik.Count
if($agir -gt 0){
  Write-Host ""
  Write-Host ("KIRMIZI: hakem olarak kullanilmadan once {0} agir bulgu giderilmeli." -f $agir)
  Write-Host "  (resmi olmayan kaynak / kesik metin / eksik parca)"
  exit 2
}
Write-Host ""
Write-Host "YESIL: ambar hakem olarak kullanilabilir."
exit 0
