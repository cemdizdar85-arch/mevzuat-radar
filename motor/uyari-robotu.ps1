# ============================================================================
#  UYARI ROBOTU (#44 push) — her firmayı profiline göre tarar, YENİ eşleşmeyi
#  firma_uyarilari'na yazar; e-posta varsa Resend ile bildirir.
#  Kaynaklar: veri/ihale-yurtici.json (il) + veri/kartlar-guncel.json (GTİP).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY + RESEND_FROM (opsiyonel).
#  Secret yoksa zarifçe atlar (exit 0). GitHub Actions cron ile günlük.
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

# KOR KALMA KURALI (30.07): kosu iz birakmali - yesil bitip sessiz kalmak yok.
# veri/uyari-ozet.json YALNIZ SAYI tasir (depo public; e-posta/VKN asla girmez).
$ozetYol = Join-Path $kok "veri/uyari-ozet.json"
function OzetYaz($n){ [IO.File]::WriteAllText($ozetYol, (ConvertTo-Json -InputObject $n -Depth 4), (New-Object Text.UTF8Encoding($false))) }
trap {
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok — uyari robotu atlandi. (GitHub Settings -> Secrets)"; exit 0
}
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; "Content-Type"="application/json" }

function GtipNorm($s){ if($null -eq $s){ return "" }; return ([regex]::Replace("$s",'[^\d]','')) }
function GtipEslesir($fk,$kk){ $a=GtipNorm $fk; $b=GtipNorm $kk; if($a.Length -lt 4 -or $b.Length -lt 4){ return $false }; $k=[Math]::Min($a.Length,$b.Length); return ($a.Substring(0,$k) -eq $b.Substring(0,$k)) }
# 30.07 TURKIYE-I TUZAGI DUZELTMESI: -replace buyuk/kucuk DUYARSIZDIR ve
# invariant kulturde 'i' deseni 'I'yi de yakalar - il eslesmesi bulutta
# sessizce sapabilirdi. Denetcideki ders (yapisal-denetci TrKucuk) kardes
# betige uygulandi: -creplace (duyarli) + ToUpperInvariant.
function TrUp($s){ if($null -eq $s){ return "" }; return (("$s" -creplace 'i','İ' -creplace 'ı','I').ToUpperInvariant()) }

# 30.07: ilan.gov.tr akisi ihale-DISI kayit da tasir (mahkeme/icra/tebligat).
# Panel bunlari eliyor; robot elemeden "ihale" diye uyari yazamaz - uyeye
# durusma ilanini ihale diye mail atmak guven oldurur. Panelle AYNI liste.
$IHALE_DISI = @('durusma','duruşma','tebligat','tebliğ','ilanen','mahkeme','icra','cekilis','çekiliş','genel kurul','kayyim','kayyım','iflas','konkordato','veraset')
function IhaleMi($x){
  $t = ("$($x.baslik) $($x.kurum)").ToLowerInvariant()
  foreach($kelime in $IHALE_DISI){ if($t.Contains($kelime)){ return $false } }
  return $true
}

# --- veri kaynaklari ---
# (alacak nobetinin sayaclari burada tanimlanir: 'firma yok' dali da ozete yaziyor)
$alacakEslesme = @{}
$izlenen = @()
$ihale = @(); try { $ihale = (Get-Content (Join-Path $kok "veri\ihale-yurtici.json") -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar } catch {}
$kartlar = @(); try { $kartlar = (Get-Content (Join-Path $kok "veri\kartlar-guncel.json") -Raw -Encoding UTF8 | ConvertFrom-Json).kartlar } catch {}
# 30.07 (#63): yapilandirma/af firsat penceresi - RG tarayicisi yazar
$firsatlar = @(); try { $firsatlar = @((Get-Content (Join-Path $kok "veri\firsat-guncel.json") -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler) } catch {}

# 30.07 (#64): ayni ilan akisindaki ICRA SATISLARI ihale-disi copten FIRSATA
# doner - sektorundeki makine/stok/tasinmaz icradan ucuza. Ele listesindeki
# oteki turler (durusma/tebligat/veraset...) firsat DEGILDIR, girmez.
function IcraSatisMi($x){
  $t = ("$($x.baslik) $($x.kurum)").ToLowerInvariant()
  foreach($k in @('icra','açık artırma','açik artirma','acik artirma')){ if($t.Contains($k)){ return $true } }
  return $false
}

# --- firmalar (service role RLS'i bypass eder) ---
# 30.07 PS TUZAGI: @(IRM ...) diziyi tek nesne sarar (N firma = "1 firma"
# gorunur, uyeler karisir). Once ata, sonra sar.
$firmalarHam = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/firmalar?select=*" -Headers $H -TimeoutSec 90
$firmalar = @($firmalarHam)
if(-not $firmalar.Count){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"; firma=0; yeni_uyari=0
    not="Henuz firma eklenmemis - panelden '+ Firma ekle' ile baslanir."
    veri=[ordered]@{ rg_karti=@($kartlar).Count; ihale_ilani=@($ihale).Count; izlenen_borclu=$izlenen.Count; alacak_eslesme=@($alacakEslesme.Keys).Count } })
  Write-Host "Firma yok."; exit 0
}

# --- 3) ALACAK: izlenen borclu VKN/TCKN'lerinde konkordato/iflas ilani ------
# 20.08 OLCULEN ACIK (Cem "rakiplerde olup bizde olmayan"): panel borclu_vkn
# ALIYOR, kartta "AKTIF" yaziyor ve 599 TL/ay abonelik TAM DA BUNUN icin
# satiliyordu — ama bu robot borclu_vkn'i HIC okumuyordu (dosyada tek gecis
# yoktu) ve "iflas/konkordato" kelimeleri IHALE_DISI eleme listesindeydi.
# Yani satilan nobet tutulmuyordu. firmalar tablosu o gun 0 kayitti, kimse
# magdur olmadi; acilistan once kapatildi.
#
# KAYNAK KASADIR, yerel dosya DEGIL: gunluk hasat dosyasi yalniz son ~400
# ilani tasir, kasada 5.775 ilan var (arsiv derinligi orada).
$alacakEslesme = @{}   # vkn/tckn -> ilan listesi
$izlenen = @()
foreach($f in $firmalar){ foreach($v in @($f.borclu_vkn)){
  $t = ("$v" -replace '\D',''); if($t.Length -ge 10){ $izlenen += $t }
} }
$izlenen = @($izlenen | Select-Object -Unique)
if($izlenen.Count){
  # PostgREST: vkn/tckn dogrudan, vknler/tcknler DIZI icinde (ov = overlap).
  # Grup konkordatosunda 2./3. borclunun VKN'si yalniz dizide durur.
  $liste = ($izlenen -join ',')
  $dizi  = '{' + $liste + '}'
  $alan  = 'ilan_no,baslik,kurum,il,tarih_str,tur,url,borclu,vkn,vknler,tckn,tcknler,esas_no,mahkeme,muhlet_tip,muhlet_bitis,komiser,itiraz_gun,borclular'
  $uri   = "$SB_URL/rest/v1/alacak_ilan?select=$alan&or=(vkn.in.($liste),tckn.in.($liste),vknler.ov.$dizi,tcknler.ov.$dizi)&order=tarih.desc&limit=500"
  try {
    $ham = Invoke-RestMethod -Method Get -Uri $uri -Headers $H -TimeoutSec 90
    foreach($il in @($ham)){
      # ilan hangi izlenen numaralara degiyorsa hepsine yazilir
      $degen = @()
      foreach($t in $izlenen){
        if("$($il.vkn)" -eq $t -or "$($il.tckn)" -eq $t){ $degen += $t; continue }
        if(@($il.vknler) -contains $t -or @($il.tcknler) -contains $t){ $degen += $t }
      }
      foreach($t in $degen){
        if(-not $alacakEslesme.ContainsKey($t)){ $alacakEslesme[$t] = @() }
        $alacakEslesme[$t] += $il
      }
    }
    Write-Host ("Alacak: {0} izlenen numara -> {1} ilan eslesti" -f $izlenen.Count, @($ham).Count)
  } catch {
    # KOR KALMA: kasa okunamazsa sessiz gecme, ozete yaz
    Write-Host ("Alacak kasasi okunamadi: {0}" -f $_.Exception.Message)
  }
}
# Ilanin borclular[] listesinde aranan numara hangisiyse ONUN adi yazilir —
# grup konkordatosunda ilanin ilk borclusunu yazmak "baska firma batmis"
# izlenimi verir (ayni ders 20.08'de kart basliginda da yasandi).
function AlacakAd($il, $t){
  foreach($b in @($il.borclular)){ if("$($b.vkn)" -eq $t -and "$($b.ad)"){ return "$($b.ad)" } }
  if("$($il.borclu)"){ return "$($il.borclu)" }
  return "VKN $t"
}

# --- mevcut uyarilar (tekrar yazmamak icin anahtar seti) ---
$mevcut = @{}
try {
  $ex = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/firma_uyarilari?select=firma_id,tur,baslik" -Headers $H -TimeoutSec 90
  foreach($u in @($ex)){ $mevcut["$($u.firma_id)|$($u.tur)|$($u.baslik)"] = $true }
} catch {}

$yeni = New-Object System.Collections.Generic.List[object]
$mailKuyruk = @{}   # firma_id -> @{email; ad; satirlar}

foreach($f in $firmalar){
  $bulunan = @()
  # 1) IHALE (il)
  $ilU = TrUp $f.il
  if($ilU){ foreach($x in $ihale){ if((IhaleMi $x) -and (TrUp $x.il) -eq $ilU){
    $bas = "$($x.baslik)"; $bulunan += @{ tur="ihale"; baslik=$bas; detay=("$($x.kurum) · $($x.il) · $($x.tarih)"); url=$x.url; onem="orta" }
  } } }
  # 1b) FIRSAT-ICRA (#64): ildeki icra satislari - ucuza varlik firsati
  if($ilU){ foreach($x in $ihale){ if((IcraSatisMi $x) -and (TrUp $x.il) -eq $ilU){
    $bulunan += @{ tur="firsat-icra"; baslik="$($x.baslik)"; detay=("İcradan satış fırsatı: $($x.kurum) · $($x.tarih) — ucuza varlık, ilana bak"); url=$x.url; onem="orta" }
  } } }
  # 1c) FIRSAT (#63): yapilandirma/af penceresi - TUM uyelere, profil sarti yok
  foreach($fm in $firsatlar){
    $bulunan += @{ tur="firsat"; baslik="$($fm.baslik)"; detay="Yapılandırma/af penceresi açıldı — başvuru süresi kaçırılmamalı, ayrıntı kaynakta."; url=$fm.url; onem="yuksek" }
  }
  # 2) RG KARTI (GTIP)
  foreach($k in $kartlar){ foreach($fk in @($f.gtip_kodlari)){ $eslesti=$false
    foreach($kk in @($k.gtip)){ if(GtipEslesir $fk $kk){ $eslesti=$true; break } }
    if($eslesti){
      $onem = if("$($k.etki)" -match "aleyhine"){ "yuksek" } else { "orta" }
      $bulunan += @{ tur="rg"; baslik="$($k.baslik)"; detay=("$($k.ne_oldu)"); url=$k.url; onem=$onem }
      break
    } } }
  # 3) ALACAK (izlenen borclu VKN/TCKN) — en yuksek onem: sure isliyor
  foreach($v in @($f.borclu_vkn)){
    $t = ("$v" -replace '\D',''); if($t.Length -lt 10){ continue }
    foreach($il in @($alacakEslesme[$t])){
      if(-not $il){ continue }
      $ad  = AlacakAd $il $t
      $bas = "$ad — $($il.baslik) · $($il.tarih_str)"
      # detay: sureyi hesaplamaz, ILANDA YAZANI tasir (m.299/m.219 sureleri
      # sayfadaki kartta hesaplaniyor; robot uydurmaz, kayda goturur).
      $par = @()
      if("$($il.mahkeme)" -or "$($il.kurum)"){ $par += (@("$($il.mahkeme)","$($il.kurum)") | Where-Object { $_ } | Select-Object -First 1) }
      if("$($il.esas_no)"){ $par += "$($il.esas_no)" }
      if("$($il.muhlet_bitis)"){ $par += "mühlet bitişi $($il.muhlet_bitis)" }
      if("$($il.komiser)"){ $par += "komiser: $($il.komiser)" }
      $par += "İlan tarihinden itibaren süre işler — alacak kaydını geciktirme"
      $bulunan += @{ tur="alacak"; baslik=$bas; detay=($par -join " · "); url=$il.url; onem="yuksek" }
    }
  }
  # yalniz YENI olanlari kuyruga al
  foreach($b in $bulunan){
    $ak = "$($f.id)|$($b.tur)|$($b.baslik)"
    if($mevcut.ContainsKey($ak)){ continue }
    $mevcut[$ak] = $true
    $yeni.Add([ordered]@{ firma_id=$f.id; user_id=$f.user_id; tur=$b.tur; baslik=$b.baslik; detay=$b.detay; url=$b.url; onem=$b.onem })
    # 27.08 TESLİM TEYİDİ: alacak uyarıları bu özet maile GİRMEZ. Onları
    # motor/teslim-teyidi.ps1 kendi adanmış mailiyle gönderir — çünkü tek
    # kritik uyarı odur (İİK süresi işliyor) ve "Okudum, işleme aldım"
    # düğmesiyle teyit alınana kadar merdiven halinde tekrar edilir.
    # Buradan da gönderilseydi kullanıcı aynı gün iki mail alırdı.
    if($f.email -and $b.tur -ne 'alacak'){
      if(-not $mailKuyruk.ContainsKey($f.id)){ $mailKuyruk[$f.id] = @{ email=$f.email; ad=$f.firma_adi; satirlar=@() } }
      $mailKuyruk[$f.id].satirlar += "• [$($b.tur.ToUpper())] $($b.baslik)"
    }
  }
}

if($yeni.Count -eq 0){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"; firma=$firmalar.Count; yeni_uyari=0
    not="Bugun yeni eslesme yok - mukerrer kilidi eskiyi tekrar yazmaz."
    veri=[ordered]@{ rg_karti=@($kartlar).Count; ihale_ilani=@($ihale).Count; izlenen_borclu=$izlenen.Count; alacak_eslesme=@($alacakEslesme.Keys).Count } })
  Write-Host "Yeni uyari yok."; exit 0
}

# --- toplu yaz ---
$body = ($yeni | ConvertTo-Json -Depth 5)
if($yeni.Count -eq 1){ $body = "[$body]" }
Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/firma_uyarilari" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 90 | Out-Null
Write-Host ("Yazilan yeni uyari: {0}" -f $yeni.Count)

# --- mail (Resend, opsiyonel) ---
$RK = ("$env:RESEND_KEY" -replace '[^\x21-\x7E]',''); $RF = $env:RESEND_FROM
if($RK -and $RF){
  $sent=0
  foreach($fid in $mailKuyruk.Keys){
    $m = $mailKuyruk[$fid]; if(-not $m.satirlar.Count){ continue }
    # 19.08 onemsiz-kutu dersi: uye mailinde duz-metin alternatif + List-Unsubscribe
    # basligi + "neden aliyorsunuz" satiri sart — spam puani ve sikayet riski duser.
    $html = "<h2>Radar uyariniz — $($m.ad)</h2><p>Firmanizi ilgilendiren yeni gelismeler:</p><p>" + ($m.satirlar -join "<br>") + "</p><p><a href='https://tetikte.com/radar-app.html'>Panele git &rarr;</a></p><p style='color:#888;font-size:12px'>Tetikte — bir Dizdar Denetim A.S. yazilimidir. Bu maili radar aboneliginiz icin aliyorsunuz; bildirimi kapatmak icin bu maile 'iptal' yanitini verin.</p>"
    $duz = "Radar uyariniz — $($m.ad)`n`nFirmanizi ilgilendiren yeni gelismeler:`n" + ($m.satirlar -join "`n") + "`n`nPanel: https://tetikte.com/radar-app.html`n`nTetikte — bir Dizdar Denetim A.S. yazilimidir. Bu maili radar aboneliginiz icin aliyorsunuz; bildirimi kapatmak icin bu maile 'iptal' yanitini verin."
    $mb = @{ from=$RF; to=@($m.email); reply_to="cem@dizdardenetim.com"; subject=$(if($m.satirlar -match '[ALACAK]'){ "Radar: izlediginiz borcluda konkordato/iflas ilani" } else { "Radar: firmanizi ilgilendiren $($m.satirlar.Count) yeni gelisme" }); html=$html; text=$duz; headers=@{ "List-Unsubscribe"="<mailto:cem@dizdardenetim.com?subject=iptal>" } } | ConvertTo-Json -Depth 4
    try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $RK"; "Content-Type"="application/json" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 60 | Out-Null; $sent++ } catch { Write-Host "Mail hata ($($m.email)): $($_.Exception.Message)" }
  }
  Write-Host ("Gonderilen mail: {0}" -f $sent)
} else { $sent = 0; Write-Host "RESEND_KEY/FROM yok — mail atlandi (uyarilar panoda gorunur)." }

OzetYaz ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm"); durum = "TAMAM"
  firma = $firmalar.Count; yeni_uyari = $yeni.Count; mail_gonderilen = $sent
  mail_notu = if($RK -and $RF){ "RESEND takili" } else { "RESEND anahtari yok - uyarilar panele yazildi, mail atlandi" }
  veri = [ordered]@{ rg_karti = @($kartlar).Count; ihale_ilani = @($ihale).Count; izlenen_borclu = $izlenen.Count; alacak_eslesme = @($alacakEslesme.Keys).Count }
})
Write-Host ("TAMAM: {0} firma, {1} yeni uyari." -f $firmalar.Count, $yeni.Count)
