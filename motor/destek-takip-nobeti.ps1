# ============================================================================
#  DESTEK TAKIP NOBETI (21.08.2026) - Cem: "sihirbaz cevabini saklayip
#  'profiline uyan yeni cagri acildi' maili".
#
#  NE: destek_takip'teki abonelerin profiline gore veri/cagri-radar.json'daki
#  YENI cagrilari bulur, destek_uyari'ya yazar ve (RESEND acikSA) mail atar.
#
#  ONEMLI SINIR: cagri kayitlarinda uygunluk verisi (kim basvurabilir) YOKTUR.
#  Bu yuzden eslesme PROGRAM degil KURUM duzeyindedir. Mail dili de buna gore:
#  "uygun oldugun kurumlardan" denir, "sana uygun cagri" DENMEZ.
#
#  ILK KOSU SESSIZ: yeni abonenin ilk taramasinda o an acik olan butun cagrilar
#  "gorulda" isaretlenir ama MAIL ATILMAZ. Yoksa kaydolan herkes ilk gece
#  ~90 satirlik bir mail yerdi. Mail yalnizca kayittan SONRA acilanlar icin.
#
#  DEDUP: (email, cagri_url) - ayni cagri ayni kisiye iki kez gitmez. Anahtar
#  takip_id degil EMAIL: kullanici profilini degistirip yeniden kaydolursa
#  eski cagrilar tekrar gonderilmez.
#
#  ENV: SUPABASE_SERVICE_KEY (zorunlu). RESEND_KEY / RESEND_FROM (opsiyonel -
#  yoksa mail atlanir, uyarilar yine tabloya yazilir; kor kalmayiz).
#  TABLO: veri/sql-destek-takip.sql (once calistirilmali).
#  Cikti: veri/destek-takip-raporu.json (GM gozetimi).
#
#  KOSUM: pwsh (PS7+; -SkipHttpErrorCheck PS5.1'de yoktur).
#    pwsh motor/destek-takip-nobeti.ps1 -kuru     # prova: hicbir sey yazilmaz
# ============================================================================
param([switch]$kuru, [int]$mailSatirTavan = 15)
$ErrorActionPreference = 'Stop'
# KIMLIK SATIRLARI (25.08.2026) - EKSIKTI VE TUM DEPOYU KIRMIZI TUTUYORDU.
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddediyor
# ([[supabase-tarayici-kimligi]]). Bu yuzden arac/kimlik-denetimi.ps1 her
# Supabase cagiran betikte bu iki satiri sart kosuyor. Bu dosya 21.08'de
# eklenirken satirlar konmamis; sonuc: HER PUSH'ta Dogrulama Kapisi kirmizi
# (17 kosu / 17 kirmizi, son yesil 19.08). 128 betikten eksigi olan TEK dosya
# buydu - iki satir, alti gunluk kirmizi.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/destek-takip-raporu.json'
function RaporYaz($o){ Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $o -Depth 6) -Encoding UTF8 -NoNewline }

if(-not $env:SUPABASE_SERVICE_KEY){
  Write-Host "SUPABASE_SERVICE_KEY yok - cikildi (bu robot Actions'ta kosar)."
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI - anahtar yok' }); exit 0
}
$API_ADRES = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck; $ham=if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}; if([int]$w.StatusCode -ge 400){ throw ("Supabase {0}: {1}" -f $w.StatusCode,$ham) }; return @($ham | ConvertFrom-Json) }
# PostgREST varsayilan tavani 1000 satirdir (kasa dersi). Sayfa sayfa cek.
function SbGetTum($yol){
  $hepsi = New-Object System.Collections.Generic.List[object]; $bas = 0; $adim = 1000
  while($true){
    $h = $SB.Clone(); $h['Range-Unit']='items'; $h['Range'] = "$bas-$($bas+$adim-1)"
    $w = Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $h -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck
    $ham = if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}
    if([int]$w.StatusCode -ge 400 -and [int]$w.StatusCode -ne 416){ throw ("Supabase {0}: {1}" -f $w.StatusCode,$ham) }
    if([int]$w.StatusCode -eq 416){ break }
    $parca = @($ham | ConvertFrom-Json)
    foreach($x in $parca){ $hepsi.Add($x) }
    if($parca.Count -lt $adim){ break }
    $bas += $adim
  }
  return $hepsi
}
function SbPost($yol,$govde){ $b=[Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 6)); $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Method Post -Headers ($SB+@{'Content-Type'='application/json';Prefer='return=minimal'}) -Body $b -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; return [int]$w.StatusCode }
function SbPatch($yol,$govde){ $b=[Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 6)); $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Method Patch -Headers ($SB+@{'Content-Type'='application/json';Prefer='return=minimal'}) -Body $b -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; return [int]$w.StatusCode }

# --- cagri radari -----------------------------------------------------------
$cagriYol = Join-Path $kok 'veri/cagri-radar.json'
if(-not (Test-Path $cagriYol)){ Write-Host "cagri-radar.json yok - once cagri-hasat"; RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='CAGRI VERISI YOK' }); exit 0 }
$cd = Get-Content $cagriYol -Raw -Encoding UTF8 | ConvertFrom-Json

# Kaynak -> kurum. Tarayici tarafindaki ESI: destek-kural.js (destekler.html ve
# radar-app.html oradan okur). PowerShell o dosyayi okuyamadigi icin burada
# zorunlu bir ikinci kopya var; BIRI DEGISIRSE OTEKI DE DEGISIR.
function KurumAdi([string]$kaynak){
  if($kaynak -eq 'TÜBİTAK'){ return 'TÜBİTAK' }
  if($kaynak -eq 'KOSGEB'){ return 'KOSGEB' }
  if($kaynak -eq 'Kalkınma Ajansları'){ return 'KALKINMA AJANSI' }
  if($kaynak -eq 'TKDK (IPARD)'){ return 'TKDK' }
  if($kaynak.StartsWith('HAMLE')){ return 'HAMLE' }
  if($kaynak.StartsWith('KKYDP')){ return 'KKYDP' }
  if($kaynak.StartsWith('AB')){ return 'AB' }
  return $kaynak
}
$bugun = (Get-Date).Date
function GunKaldi($t){ if(-not $t){ return $null }; try { return ([int](([datetime]::ParseExact($t,'yyyy-MM-dd',$null)) - $bugun).TotalDays) } catch { return $null } }

# Bildirime giren cagrilar: acik + yakinda. Son tarihi GECMIS olan girmez -
# kapanmis cagriyi haber vermek kullaniciyi bosuna kosturur.
$aday = New-Object System.Collections.Generic.List[object]
foreach($c in @($cd.cagrilar)){
  $g = GunKaldi $c.sonTarih
  if($null -ne $g -and $g -lt 0){ continue }
  $aday.Add([pscustomobject]@{
    url="$($c.url)"; baslik="$($c.baslik)"; kurum=(KurumAdi "$($c.kaynak)")
    sonTarih="$($c.sonTarih)"; acilis="$($c.acilis)"; durum="$($c.durum)"; kalan=$g
  })
}
Write-Host ("Cagri: {0} kayittan {1} tanesi bildirime aday (kapananlar dislandi)" -f @($cd.cagrilar).Count, $aday.Count)

# --- aboneler ---------------------------------------------------------------
$satirlar = SbGetTum "destek_takip?select=id,email,profil,kurumlar,ab,token,ilk_tarama,olusturma&aktif=eq.true&order=olusturma.desc"
# Ayni e-posta birden cok kez kaydolduysa EN YENI satir gecerlidir.
$aboneler = @{}
foreach($s in $satirlar){ $e = "$($s.email)".Trim().ToLowerInvariant(); if($e -and -not $aboneler.ContainsKey($e)){ $aboneler[$e] = $s } }
Write-Host ("Aktif abone: {0} (toplam {1} satirdan tekillestirildi)" -f $aboneler.Count, $satirlar.Count)

# --- daha once gonderilmis/gorulmus olanlar (dedup) -------------------------
$gorulen = @{}
try { foreach($u in (SbGetTum "destek_uyari?select=email,cagri_url")){ $gorulen["$($u.email)|$($u.cagri_url)"] = $true } }
catch { Write-Host ("destek_uyari okunamadi (tablo yok olabilir): {0}" -f $_.Exception.Message) }

# --- eslestirme -------------------------------------------------------------
$yeniKayit  = New-Object System.Collections.Generic.List[object]
$mailKuyruk = @{}
$sessizIlk  = New-Object System.Collections.Generic.List[object]
foreach($e in $aboneler.Keys){
  $a = $aboneler[$e]
  $kurumlar = @($a.kurumlar) | ForEach-Object { "$_" }
  $abIster  = [bool]$a.ab
  $ilkKosu  = -not [bool]$a.ilk_tarama
  foreach($c in $aday){
    if($c.kurum -eq 'AB'){ if(-not $abIster){ continue } }
    elseif($kurumlar -notcontains $c.kurum){ continue }
    $anahtar = "$e|$($c.url)"
    if($gorulen.ContainsKey($anahtar)){ continue }
    $gorulen[$anahtar] = $true
    $kayit = [ordered]@{ email=$e; cagri_url=$c.url; kurum=$c.kurum; baslik=$c.baslik; son_tarih=$c.sonTarih; mail_gitti=(-not $ilkKosu) }
    $yeniKayit.Add($kayit)
    if($ilkKosu){ $sessizIlk.Add($kayit); continue }
    if(-not $mailKuyruk.ContainsKey($e)){ $mailKuyruk[$e] = New-Object System.Collections.Generic.List[object] }
    $mailKuyruk[$e].Add([pscustomobject]@{ kayit=$kayit; cagri=$c; token="$($a.token)" })
  }
}
Write-Host ("Yeni kayit: {0} (bunlarin {1} tanesi ILK KOSU - sessiz) - mail kuyrugu: {2} abone" -f $yeniKayit.Count, $sessizIlk.Count, $mailKuyruk.Count)

# --- yazma ------------------------------------------------------------------
$yazildi = 0; $yaziHata = 0; $ilkIsaret = 0
if(-not $kuru){
  foreach($u in $yeniKayit){
    $sc = SbPost "destek_uyari" $u
    if($sc -ge 400){ $yaziHata++ } else { $yazildi++ }
  }
  # ilk taramasi biten aboneleri isaretle (bir daha sessiz kosmasin)
  foreach($e in $aboneler.Keys){
    $a = $aboneler[$e]
    if(-not [bool]$a.ilk_tarama){
      $sc = SbPatch ("destek_takip?id=eq." + $a.id) @{ ilk_tarama = $true }
      if($sc -lt 400){ $ilkIsaret++ }
    }
  }
}

# --- mail (RESEND acikSA) ---------------------------------------------------
$mailAtilan = 0; $mailHata = 0
if($env:RESEND_KEY -and -not $kuru){
  $from = if($env:RESEND_FROM){ $env:RESEND_FROM } else { 'Tetikte <bildirim@tetikte.com>' }
  foreach($mail in $mailKuyruk.Keys){
    $liste = @($mailKuyruk[$mail] | Sort-Object { if($null -eq $_.cagri.kalan){ 9999 } else { $_.cagri.kalan } })
    $token = $liste[0].token
    $iptalUrl = "https://tetikte.com/iptal.html?t=$token"
    $gosterilen = @($liste | Select-Object -First $mailSatirTavan)
    $kalanAdet = $liste.Count - $gosterilen.Count
    $kurumOzet = (($liste | ForEach-Object { $_.cagri.kurum } | Sort-Object -Unique) -join ', ')

    $satirHtml = ($gosterilen | ForEach-Object {
      $c = $_.cagri
      $ne = if($c.durum -eq 'yakinda'){ if($c.acilis){ "yakinda acilir: $($c.acilis)" } else { "yakinda" } }
            elseif($c.sonTarih){ if($null -ne $c.kalan){ "son basvuru $($c.sonTarih) ($($c.kalan) gun)" } else { "son basvuru $($c.sonTarih)" } }
            else { "tarih duyuruda" }
      "<li><b>$($c.kurum)</b> &ndash; <a href=""$($c.url)"">$($c.baslik)</a><br><span style=""color:#888;font-size:12px"">$ne</span></li>"
    }) -join ""
    $satirDuz = ($gosterilen | ForEach-Object {
      $c = $_.cagri
      $ne = if($c.durum -eq 'yakinda'){ if($c.acilis){ "yakinda acilir: $($c.acilis)" } else { "yakinda" } }
            elseif($c.sonTarih){ "son basvuru $($c.sonTarih)" } else { "tarih duyuruda" }
      "- [$($c.kurum)] $($c.baslik) ($ne)`n  $($c.url)"
    }) -join "`n"
    $fazlaHtml = if($kalanAdet -gt 0){ "<p>Ve $kalanAdet cagri daha - hepsi <a href=""https://tetikte.com/destekler.html"">Destek Radari</a>'nda.</p>" } else { "" }
    $fazlaDuz  = if($kalanAdet -gt 0){ "`nVe $kalanAdet cagri daha - hepsi https://tetikte.com/destekler.html adresinde." } else { "" }

    # 19.08 onemsiz-kutu dersi: duz-metin alternatif + List-Unsubscribe SART.
    # Dil dikkat: "uygun oldugun KURUMLARDAN" - cagri kaydinda uygunluk verisi
    # olmadigi icin "sana uygun cagri" diye iddia KURMUYORUZ.
    $html = "<p>Merhaba,</p><p>Uygun oldugun kurumlardan (<b>$kurumOzet</b>) <b>$($liste.Count)</b> yeni cagri acildi:</p><ul>$satirHtml</ul>$fazlaHtml" +
            "<p style=""color:#666;font-size:13px"">Kimin basvurabilecegi, destek tutari ve gider kalemleri <b>cagri duyurusunda</b> yazar - biz duyuruyu haber veriyoruz, sartlari duyurudan oku.</p>" +
            "<p>Tetikte</p><p style=""color:#888;font-size:12px"">Bu maili Destek Radari bildirim kaydin icin aliyorsun. <a href=""$iptalUrl"">Tek tikla cik</a> ya da bu maile 'iptal' yanitini ver.</p>"
    $duz = "Merhaba,`n`nUygun oldugun kurumlardan ($kurumOzet) $($liste.Count) yeni cagri acildi:`n$satirDuz$fazlaDuz`n`n" +
           "Kimin basvurabilecegi, destek tutari ve gider kalemleri cagri duyurusunda yazar - biz duyuruyu haber veriyoruz, sartlari duyurudan oku.`n`nTetikte`n" +
           "Bu maili Destek Radari bildirim kaydin icin aliyorsun. Tek tikla cikmak icin: $iptalUrl - ya da bu maile 'iptal' yanitini ver."

    $konu = if($liste.Count -eq 1){ "Destek Radari: yeni cagri ($kurumOzet)" } else { "Destek Radari: $($liste.Count) yeni cagri ($kurumOzet)" }
    $body = @{ from=$from; to=@($mail); reply_to="cem@dizdardenetim.com"; subject=$konu; html=$html; text=$duz
               headers=@{ "List-Unsubscribe"="<$iptalUrl>, <mailto:cem@dizdardenetim.com?subject=iptal>" } }
    try {
      $w = Invoke-WebRequest -Uri "https://api.resend.com/emails" -Method Post -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')); 'Content-Type'='application/json' } -Body ([Text.Encoding]::UTF8.GetBytes(($body|ConvertTo-Json -Compress -Depth 6))) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
      if([int]$w.StatusCode -lt 400){ $mailAtilan++ } else { $mailHata++ }
    } catch { $mailHata++ }
  }
} else { Write-Host "RESEND_KEY yok ya da -kuru - mail atlandi (uyarilar tabloya yazildi)." }

$ozet = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod=$(if($kuru){'KURU'}else{'CANLI'})
  cagri_toplam=@($cd.cagrilar).Count; cagri_aday=$aday.Count
  abone_aktif=$aboneler.Count; abone_satir=$satirlar.Count
  yeni_kayit=$yeniKayit.Count; ilk_kosu_sessiz=$sessizIlk.Count
  tabloya_yazildi=$yazildi; yazi_hata=$yaziHata; ilk_tarama_isaretlenen=$ilkIsaret
  mail_kullanici=$mailKuyruk.Count; mail_atilan=$mailAtilan; mail_hata=$mailHata; resend=[bool]$env:RESEND_KEY
  kurum_dagilimi=@($aday | Group-Object kurum | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ kurum=$_.Name; adet=$_.Count } })
  ornekler=@($yeniKayit | Select-Object -First 10)
  not="Eslesme KURUM duzeyindedir (cagri kaydinda uygunluk verisi yok). Ilk kosu sessizdir: mevcut cagrilar gorulda isaretlenir, mail atilmaz."
}
RaporYaz $ozet
Write-Host ("`n-> {0}" -f $raporYol)
Write-Host ("yazilan: {0} - sessiz ilk: {1} - mail: {2} - resend: {3}" -f $yazildi, $sessizIlk.Count, $mailAtilan, [bool]$env:RESEND_KEY)
