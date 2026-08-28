# ============================================================================
#  TESLİM TEYİDİ MERDİVENİ — "cevap gelene kadar susmayan uyarı"
#
#  NEDEN VAR (27.08.2026 rakip turu, ölçüldü):
#    konkordata.com          -> günlük e-posta + kurumsalda anlık SMS
#    konkordatoilanlari.com  -> e-posta + SMS + telefon + WhatsApp
#  Yani KANAL bir farklılaşma değil, ikisinde de var. Hiçbirinde OLMAYAN şey:
#  bildirimin ULAŞTIĞINI teyit etmek ve teyit gelene kadar tekrar etmek.
#  Alacaklı için fark tam burada: İİK m.299'da süre ilan tarihinden işler
#  (15 gün), m.219'da 1 aydır — mail spam kutusuna düştüyse "gönderdik"
#  demenin hiçbir kıymeti yoktur.
#
#  MERDİVEN (gün, uyarı oluştuğundan itibaren):
#    1/4  gün 0  · e-posta
#    2/4  gün 1  · e-posta
#    3/4  gün 3  · e-posta + SMS
#    4/4  gün 6  · e-posta + SMS   (son; sonrası panelde "teyit bekleniyor")
#  Toplam 6 gün — m.299'un 15 gününün içinde rahatça biter, kanal yanmaz.
#  Kullanıcı "Okudum, işleme aldım" düğmesine bastığı an merdiven susar.
#
#  KAPSAM: yalnız tur='alacak'. İhale/RG/fırsat uyarısı için üst üste bildirim
#  atmak kanalı yakar; onlarda tek özet mail yeterli (uyari-robotu.ps1 davranışı
#  korunuyor — orada alacak satırları özet maile artık GİRMEZ, bu betik onların
#  kendi adanmış mailini atar).
#
#  ENV: SUPABASE_SERVICE_KEY (zorunlu) · RESEND_KEY + RESEND_FROM (mail için)
#       SMS_SAGLAYICI + sağlayıcı anahtarları (SMS için — HENÜZ KURULU DEĞİL)
#  Anahtar yoksa zarifçe atlar ve özete "ATLANDI" yazar (kör kalma kuralı).
#
#  Şema/RPC : radar-app/sql/2026-08-27-teslim-teyidi.sql
#  Teyit ucu: uyari-teyit.html
# ============================================================================
param([switch]$kuru)

$ErrorActionPreference = "Stop"
# Supabase gizli anahtarlı istek KİMLİKSİZ gelirse 401 döner (16.08 ölçüldü).
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SUPABASE_KOK = "https://bjrleanjpyujtajmazxn.supabase.co"
$SITE_KOK     = "https://tetikte.com"

# KÖR KALMA: koşu iz bırakmalı. Depo PUBLIC — özete e-posta/telefon/VKN ASLA
# yazılmaz, yalnız sayı ve durum.
$ozetYol = Join-Path $kok "veri/teslim-teyidi-ozet.json"
function OzetYaz($n){
  [IO.File]::WriteAllText($ozetYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false)))
}
trap {
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$ANAHTAR = $env:SUPABASE_SERVICE_KEY
if(-not $ANAHTAR){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok - teslim teyidi atlandi."; exit 0
}
$BASLIKLAR = @{ apikey=$ANAHTAR; Authorization="Bearer $ANAHTAR"; "Content-Type"="application/json" }

# ---------------------------------------------------------------- MERDİVEN
# n = o ana kadar GÖNDERİLMİŞ bildirim sayısı. beklenenGun = son bildirimden
# (yoksa uyarının doğuşundan) beri geçmesi gereken gün.
$MERDIVEN = @(
  [ordered]@{ n=0; beklenenGun=0; kanallar=@('mail');        etiket='1/4' },
  [ordered]@{ n=1; beklenenGun=1; kanallar=@('mail');        etiket='2/4' },
  [ordered]@{ n=2; beklenenGun=2; kanallar=@('mail','sms');  etiket='3/4' },
  [ordered]@{ n=3; beklenenGun=3; kanallar=@('mail','sms');  etiket='4/4' }
)
$TAVAN = $MERDIVEN.Count

# ---------------------------------------------------------------- SMS ADAPTÖRÜ
# 🔴 DÜRÜST DURUM: SMS sağlayıcı hesabı HENÜZ AÇILMADI. Buraya çalışmadığını
# bilmediğim bir HTTP çağrısı YAZMIYORUM — test edilmemiş entegrasyon, kurulmuş
# gibi görünüp sessizce hiç göndermeyen en tehlikeli koddur (bkz. 20.08:
# "satılan nöbet tutulmuyordu"). Sağlayıcı seçilip hesap açılınca doldurulacak
# TEK yer burasıdır; merdivenin geri kalanı hazır ve çalışıyor.
function SmsGonder($telefon, $metin){
  $saglayici = "$env:SMS_SAGLAYICI".Trim()
  if(-not $saglayici){ return "KURULU_DEGIL" }
  if(-not $telefon){ return "TELEFON_YOK" }
  # Sağlayıcı eklendiğinde: burada tek bir Invoke-RestMethod çağrısı olacak ve
  # 'ok' / 'HATA: ...' döndürecek. Sözleşme bu; çağıran taraf değişmeyecek.
  return "SAGLAYICI_TANIMSIZ:$saglayici"
}

# ---------------------------------------------------------------- VERİ
# Teyit edilmemiş, tavanı doldurmamış alacak uyarıları + firmanın iletişimi.
$alanlar = 'id,baslik,detay,url,onem,created_at,bildirim_sayisi,son_bildirim_at,teyit_token,kanal_gecmisi,firmalar(email,firma_adi,telefon)'
$adres = "$SUPABASE_KOK/rest/v1/firma_uyarilari?select=$alanlar&tur=eq.alacak&teyit_at=is.null&bildirim_sayisi=lt.$TAVAN&order=created_at.asc&limit=500"
$bekleyenHam = Invoke-RestMethod -Method Get -Uri $adres -Headers $BASLIKLAR -TimeoutSec 90
# PS TUZAĞI (30.07): @(IRM ...) diziyi tek nesne sarar. Önce ata, sonra sar.
$bekleyen = @($bekleyenHam)

if(-not $bekleyen.Count){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"
    bekleyen=0; gonderilen=0; kuru=[bool]$kuru
    not="Teyit bekleyen alacak uyarisi yok." })
  Write-Host "Teyit bekleyen alacak uyarisi yok."; exit 0
}

$RESEND_ANAHTAR = ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')
$RESEND_GONDEREN = $env:RESEND_FROM
$mailAcik = [bool]($RESEND_ANAHTAR -and $RESEND_GONDEREN)

# ---------------------------------------------------------------- MAİL
# 19.08 teslim edilebilirlik dersi: düz-metin alternatifi + List-Unsubscribe
# başlığı + "neden alıyorsun" satırı ŞART.
# HtmlKac: System.Web bağımlılığı yerine 5 satır — borçlu unvanında & < >
# geçerse mail gövdesi bozulmasın (unvanlarda "A.Ş. & Ortakları" görülüyor).
function HtmlKac($s){
  if($null -eq $s){ return "" }
  return ("$s" -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;')
}
function MailGonder($eposta, $firmaAdi, $uyariBasligi, $ayrinti, $ilanUrl, $teyitUrl, $etiket, $sonMu){
  if(-not $mailAcik){ return "RESEND_YOK" }
  if(-not $eposta){ return "EPOSTA_YOK" }

  $konu = switch($etiket){
    '1/4' { "Alacak Radari: izledigin borcluda konkordato/iflas ilani var" }
    '2/4' { "Hatirlatma (2/4) - bu ilani gordun mu?" }
    '3/4' { "3/4 - hala teyit alamadik, sure isliyor" }
    default { "SON hatirlatma (4/4) - teyit alamadik" }
  }
  # 🔴 PS 5.1 TUZAĞI: `if` burada İFADE DEĞİLDİR — "..." + (if(..){..}) parse
  # hatası verir. Parçalar önce değişkene alınır, sonra birleştirilir.
  $sonNot = ""; $sonNotDuz = ""
  if($sonMu){
    $sonNot = "<p style='color:#b45309;font-size:13px'><b>Bu son hatirlatma.</b> Teyit vermezsen bu uyari icin bir daha mail atmayacagiz; uyari panelinde &quot;teyit bekleniyor&quot; olarak duracak.</p>"
    $sonNotDuz = "`nBu son hatirlatma. Teyit vermezsen bu uyari icin bir daha mail atmayacagiz; uyari panelde 'teyit bekleniyor' olarak duracak.`n"
  }
  $ilanHtml = ""; $ilanDuz = ""
  if($ilanUrl){
    $ilanHtml = "<p style='font-size:13px'><a href='$ilanUrl'>Resmi ilan metni &rarr;</a></p>"
    $ilanDuz  = "Resmi ilan metni: $ilanUrl`n"
  }

  $html = "<h2>Alacak Radari - $(HtmlKac $firmaAdi)</h2>" +
    "<p><b>$(HtmlKac $uyariBasligi)</b></p>" +
    "<p style='color:#444;font-size:14px'>$(HtmlKac $ayrinti)</p>" +
    "<p style='margin:22px 0'><a href='$teyitUrl' style='background:#f5a524;color:#03101f;font-weight:700;padding:13px 24px;border-radius:10px;text-decoration:none;display:inline-block'>Okudum, isleme aldim</a></p>" +
    "<p style='font-size:13px;color:#555'>Bu dugmeye basana kadar sana hatirlatmaya devam ederiz - cunku IIK'daki sure bizim gonderdigimiz an degil, <b>ilanin yayimlandigi gun</b> islemeye baslar (konkordatoda alacak kaydi 15 gun, m.299; iflasta 1 ay, m.219).</p>" +
    $sonNot + $ilanHtml +
    "<p style='color:#888;font-size:12px'>Tetikte - bir Dizdar Denetim A.S. yazilimidir. Bu maili Alacak Radari aboneligin icin aliyorsun; bildirimi kapatmak icin bu maile 'iptal' yanitini ver.</p>"

  $duz = "Alacak Radari - $firmaAdi`n`n$uyariBasligi`n`n$ayrinti`n`nOKUDUM, ISLEME ALDIM: $teyitUrl`n`n" +
    "Bu baglantiya basana kadar hatirlatmaya devam ederiz - IIK'daki sure bizim gonderdigimiz an degil, ilanin yayimlandigi gun islemeye baslar (konkordatoda alacak kaydi 15 gun, m.299; iflasta 1 ay, m.219).`n" +
    $sonNotDuz + $ilanDuz +
    "`nTetikte - bir Dizdar Denetim A.S. yazilimidir. Bu maili Alacak Radari aboneligin icin aliyorsun; bildirimi kapatmak icin bu maile 'iptal' yanitini ver."

  $govde = @{
    from=$RESEND_GONDEREN; to=@($eposta); reply_to="cem@dizdardenetim.com"
    subject=$konu; html=$html; text=$duz
    headers=@{ "List-Unsubscribe"="<mailto:cem@dizdardenetim.com?subject=iptal>" }
  } | ConvertTo-Json -Depth 5

  try {
    Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" `
      -Headers @{ Authorization="Bearer $RESEND_ANAHTAR"; "Content-Type"="application/json" } `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    return "ok"
  } catch { return "HATA: $($_.Exception.Message)" }
}

# ---------------------------------------------------------------- MERDİVENİ YÜRÜT
$simdi = (Get-Date).ToUniversalTime()
$gonderilen = 0; $sirasiGelmeyen = 0; $iletisimYok = 0
$basamakSayaci = @{ '1/4'=0; '2/4'=0; '3/4'=0; '4/4'=0 }
$kanalSayaci   = @{ mail=0; sms=0 }
$hatalar = @()

foreach($u in $bekleyen){
  $n = [int]$u.bildirim_sayisi
  if($n -ge $TAVAN){ continue }
  $adim = $MERDIVEN[$n]

  # Sırası geldi mi? Zamanı son bildirimden, yoksa uyarının doğuşundan sayarız.
  $baslangic = if($u.son_bildirim_at){ [datetime]::Parse($u.son_bildirim_at).ToUniversalTime() } else { [datetime]::Parse($u.created_at).ToUniversalTime() }
  $gecenGun = ($simdi - $baslangic).TotalDays
  if($n -gt 0 -and $gecenGun -lt $adim.beklenenGun){ $sirasiGelmeyen++; continue }

  $firma   = $u.firmalar
  $eposta  = "$($firma.email)"
  $telefon = "$($firma.telefon)"
  $firmaAdi= if("$($firma.firma_adi)"){ "$($firma.firma_adi)" } else { "firmanız" }
  if(-not $eposta -and -not $telefon){ $iletisimYok++; continue }

  $teyitUrl = "$SITE_KOK/uyari-teyit.html?t=$($u.teyit_token)"
  $sonMu = ($n -eq ($TAVAN-1))
  $sonuclar = @{}

  foreach($kanal in $adim.kanallar){
    if($kuru){ $sonuclar[$kanal] = "KURU_KOSU"; continue }
    if($kanal -eq 'mail'){
      $sonuclar['mail'] = MailGonder $eposta $firmaAdi "$($u.baslik)" "$($u.detay)" "$($u.url)" $teyitUrl $adim.etiket $sonMu
    } elseif($kanal -eq 'sms'){
      $sonuclar['sms'] = SmsGonder $telefon "Tetikte Alacak Radari: $($u.baslik) - teyit: $teyitUrl"
    }
  }

  # Bir kanalda bile GERÇEK gönderim olduysa basamak ilerler. Hiçbiri gitmediyse
  # sayaç ARTMAZ — yoksa RESEND takılı değilken merdiven boşa tükenir ve kimse
  # hiçbir şey almadan "4/4 gönderildi" görünürdü.
  $gercekGonderim = @($sonuclar.Values | Where-Object { $_ -eq 'ok' }).Count
  foreach($k in $sonuclar.Keys){ if($sonuclar[$k] -eq 'ok'){ $kanalSayaci[$k]++ } elseif($sonuclar[$k] -ne 'KURU_KOSU' -and $sonuclar[$k] -ne 'KURULU_DEGIL' -and $sonuclar[$k] -ne 'TELEFON_YOK' -and $sonuclar[$k] -ne 'RESEND_YOK' -and $sonuclar[$k] -ne 'EPOSTA_YOK'){ $hatalar += "$k :: $($sonuclar[$k])" } }

  if($kuru){
    Write-Host ("[KURU] {0} basamak {1} -> {2}" -f $u.id, $adim.etiket, ($adim.kanallar -join '+'))
    $basamakSayaci[$adim.etiket]++
    continue
  }
  if($gercekGonderim -eq 0){
    Write-Host ("Gonderilemedi (basamak {0}): {1}" -f $adim.etiket, (($sonuclar.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))
    continue
  }

  # Kayda geç: sayaç + zaman + kanal geçmişi (geçmiş, "neyi ne zaman denedik"in
  # tek kanıtı; şikâyet geldiğinde buradan bakılır).
  $gecmis = @()
  if($u.kanal_gecmisi){ $gecmis = @($u.kanal_gecmisi) }
  $gecmis += [ordered]@{ n=($n+1); etiket=$adim.etiket; at=$simdi.ToString("o"); sonuc=($sonuclar.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ',' }
  $yama = @{ bildirim_sayisi=($n+1); son_bildirim_at=$simdi.ToString("o"); kanal_gecmisi=$gecmis } | ConvertTo-Json -Depth 6
  try {
    Invoke-RestMethod -Method Patch -Uri "$SUPABASE_KOK/rest/v1/firma_uyarilari?id=eq.$($u.id)" `
      -Headers $BASLIKLAR -Body ([Text.Encoding]::UTF8.GetBytes($yama)) -TimeoutSec 60 | Out-Null
    $gonderilen++; $basamakSayaci[$adim.etiket]++
  } catch {
    # Gönderdik ama kaydedemedik: bir sonraki koşuda AYNI basamak tekrar gider.
    # Mükerrer mail, sessiz kayıptan iyidir; ama ize mutlaka yazılır.
    $hatalar += "kayit :: $($_.Exception.Message)"
    Write-Host "Gonderildi ama kayit yazilamadi: $($_.Exception.Message)"
  }
}

$smsNotu = if("$env:SMS_SAGLAYICI"){ "SMS_SAGLAYICI tanimli ama adaptor doldurulmadi" } else { "SMS saglayici hesabi acilmadi - 3/4 ve 4/4 basamaklari yalniz mail gonderir" }
OzetYaz ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm"); durum = "TAMAM"; kuru = [bool]$kuru
  bekleyen = $bekleyen.Count; gonderilen = $gonderilen
  sirasi_gelmeyen = $sirasiGelmeyen; iletisim_yok = $iletisimYok
  basamaklar = $basamakSayaci; kanallar = $kanalSayaci
  mail_notu = if($mailAcik){ "RESEND takili" } else { "RESEND anahtari yok - mail atlandi, merdiven ilerlemedi" }
  sms_notu = $smsNotu
  hata_ornekleri = @($hatalar | Select-Object -Unique -First 5)
})
Write-Host ("TAMAM: {0} bekleyen, {1} bildirim gonderildi, {2} sirasi gelmedi." -f $bekleyen.Count, $gonderilen, $sirasiGelmeyen)
