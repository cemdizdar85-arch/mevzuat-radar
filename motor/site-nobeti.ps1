#requires -Version 5.1
<#
================================================================================
  SITE NOBETI — "site ayakta mi" sorusunun TEK cevabi  (12.09.2026)
  Cem: "guvenlik, hizli olmak ve site hic kesilmemesi cok onemli"

  NIYE VAR: 12.09'da olctum - 146 Actions akisinin 12'si tetikte.com'dan
  BAHSEDIYOR ama HICBIRI "site ayakta mi" diye BAKMIYOR. Kotu bir commit ya da
  Pages kesintisi olsa saatlerce kimse fark etmezdi. "Site hic kesilmesin"
  dilegi, olculmeden dilek olarak kalir.

  ⛔ HTTP 200 YETMEZ. 30.08 dersi: "olu adres 200+HTML doner, bilinmeyen API
     yolu 200+SPA kabugu verir" (CLAUDE.md). O yuzden her sayfada UC olcut:
       1) HTTP 200
       2) en az <asgari> bayt  (bos/kirpik sayfa yakalanir)
       3) IMZA metni iceriyor   (yanlis sayfa/hata sayfasi yakalanir)

  ⛔ KURT MASALI OKUMAZ. Tek basarisiz istek KIRMIZI degildir - ag titremesi
     her gun olur. Her adres 3 kez, artan beklemeyle denenir; UCU DE duserse
     kirmizi. Yanlis alarm, alarmin kendisini oldurur.

  ⚠ OLCULEMEDI != KIRMIZI. Kosucunun agi yoksa bunu "site coktu" diye
     bildirmek yanlis teshistir; o durum ayrica isaretlenir.

  KULLANIM
    powershell -NoProfile -File motor/site-nobeti.ps1            # olc + rapor
    powershell -NoProfile -File motor/site-nobeti.ps1 -Mail      # kirmizida mail
  BEDEL 0.
================================================================================
#>
param(
  [switch]$Mail,                 # kirmizida alarm maili at (Actions'ta acik)
  [int]$Deneme = 3,
  [int]$ZamanAsimi = 40
)
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok=Split-Path -Parent $buDizin
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# ⚠ ASGARI BAYT canli olcumden turetildi (12.09 08:30), %60'ina cekildi ki
#   normal icerik dalgalanmasi alarm uretmesin:
#     ana sayfa 133.074 · kaydir/sgs 23.767 · ders sayfasi 734.403
#   04.10 (Cem "uptime alarmını kur"): yeni ana sayfa 35 KB -> eski 60.000 eşiği 04.10 sabahından beri YANLIŞ ALARM
#   veriyordu. Eşikler 04.10 canlı boyunun ~%55'i; imzalar sayfanın kendi başlığından. kaydir/sgs/ taslak dizin
#   (ziyaretçi yönleniyor) yerine gerçek vitrin. Satış yolu sayfaları (sorular · seviye · fiyat · satın al · hesap) eklendi.
$HEDEFLER=@(
  @{ ad='ana sayfa';    url='https://tetikte.com/';                                  asgari=20000;  imza='Yanlışını, sebebiyle' }
  @{ ad='sinavlar';     url='https://tetikte.com/sorular.html';                      asgari=12000;  imza='Hangi sınava' }
  @{ ad='seviye testi'; url='https://tetikte.com/seviye-testi.html';                 asgari=35000;  imza='30 soruda seviyeni ölç' }
  @{ ad='fiyatlar';     url='https://tetikte.com/fiyat.html';                        asgari=20000;  imza='Açılış fiyatı' }   # 08.10: fiyat-motoru.js "kurucu"→"açılış"; eski imza 3/3 yanlış kırmızı + her koşuda alarm maili (Resend kotası)
  @{ ad='satin al';     url='https://tetikte.com/satin-al.html';                     asgari=30000;  imza='Siparişi tamamla' }
  @{ ad='hesabim';      url='https://tetikte.com/ogrenci.html';                      asgari=30000;  imza='Şifremi unuttum' }
  @{ ad='SGS vitrini';  url='https://tetikte.com/kaydir/vitrin/sgs.html';            asgari=150000; imza='Nöbetçi' }
  # 29.09 ADIM 2: SGS ders sayfaları 05.10'da kasa kabuğuna geçer (~160 KB) → bitirme kabuğuyla aynı eşik 50 KB.
  #   300 KB kalsaydı geçişten sonra 15 dk'da bir yanlış alarm verirdi (16.09 planındaki uyarı).
  @{ ad='ders sayfasi'; url='https://tetikte.com/kaydir/sgs/meslek-hukuku.html';     asgari=50000;  imza='Nöbetçi' }
  # 18.09 (Cem "kasadaki soruları siteye bağla"): bitirme ders sayfaları KASA MODUNDA sorusuz kabuktur (ölçüldü: 162 KB;
  #   içerik kasadan gelir) → asgari boy 300 KB DEĞİL, 50 KB. Dizin sayfası 3 KB, ondan kendi satırı ve kendi eşiği var.
  @{ ad='bitirme dizini'; url='https://tetikte.com/kaydir/smmm/';                    asgari=2000;   imza='Kaydır' }
  @{ ad='bitirme ders sayfasi (kasa kabugu)'; url='https://tetikte.com/kaydir/smmm/hukuk.html'; asgari=50000; imza='Nöbetçi' }
)

function Olc($hedef){
  $sonHata=''
  foreach($deneme in 1..$Deneme){
    try{
      $t0=Get-Date
      $cevap=Invoke-WebRequest -Uri $hedef.url -TimeoutSec $ZamanAsimi -UseBasicParsing -Headers @{ 'User-Agent'='Tetikte-SiteNobeti/1.0' }
      $sure=[int]((Get-Date)-$t0).TotalMilliseconds
      $govde="$($cevap.Content)"
      $kusur=New-Object System.Collections.Generic.List[string]
      if([int]$cevap.StatusCode -ne 200){ $kusur.Add("HTTP $($cevap.StatusCode)") }
      if($govde.Length -lt [int]$hedef.asgari){ $kusur.Add("boy $($govde.Length) < asgari $($hedef.asgari)") }
      if($govde -notmatch [regex]::Escape($hedef.imza)){ $kusur.Add("imza yok: '$($hedef.imza)'") }
      return [pscustomobject]@{ ad=$hedef.ad; url=$hedef.url; durum=$(if($kusur.Count){'KIRMIZI'}else{'YESIL'})
                                kod=[int]$cevap.StatusCode; bayt=$govde.Length; ms=$sure
                                kusur=($kusur.ToArray() -join ' · '); deneme=$deneme }
    }catch{
      $sonHata=$_.Exception.Message
      if($deneme -lt $Deneme){ Start-Sleep -Seconds (5*$deneme) }
    }
  }
  # Uc deneme de istek ATAMADI. Adres cevap vermiyor ya da bizim agimiz yok.
  return [pscustomobject]@{ ad=$hedef.ad; url=$hedef.url; durum='KIRMIZI'; kod=0; bayt=0; ms=0
                            kusur="$Deneme denemede yanit yok: $sonHata"; deneme=$Deneme }
}

$sonuclar=New-Object System.Collections.Generic.List[object]
foreach($h in $HEDEFLER){ $sonuclar.Add((Olc $h)) }

# ---- ARKA UÇ (04.10): sayfa ayakta ama Supabase düşmüşse giriş, kasa ve seviye testi çalışmaz -------------------
# Yayın anahtarı sitede zaten açık (huni-raporu.js ile aynı); servis anahtarı KULLANILMAZ. Her istek 3 deneme.
$SB='https://bjrleanjpyujtajmazxn.supabase.co'; $SBK='sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg'
$sbBas=@{ apikey=$SBK; Authorization="Bearer $SBK"; 'User-Agent'='Tetikte-SiteNobeti/1.0' }
function Api($ad,$url,[scriptblock]$denetle){
  $sonHata=''
  foreach($deneme in 1..$Deneme){
    try{
      $t0=Get-Date
      $c=Invoke-WebRequest -Uri $url -Headers $sbBas -TimeoutSec $ZamanAsimi -UseBasicParsing
      $sure=[int]((Get-Date)-$t0).TotalMilliseconds
      $kusur="$(& $denetle $c.Content)"
      return [pscustomobject]@{ ad=$ad; url=($url -replace '\?.*$',''); durum=$(if($kusur){'KIRMIZI'}else{'YESIL'})
                                kod=[int]$c.StatusCode; bayt="$($c.Content)".Length; ms=$sure; kusur=$kusur; deneme=$deneme }
    }catch{ $sonHata=$_.Exception.Message; if($deneme -lt $Deneme){ Start-Sleep -Seconds (5*$deneme) } }
  }
  return [pscustomobject]@{ ad=$ad; url=($url -replace '\?.*$',''); durum='KIRMIZI'; kod=0; bayt=0; ms=0; kusur="$Deneme denemede yanit yok: $sonHata"; deneme=$Deneme }
}
# giriş servisi (site girişi auth.tetikte.com üzerinden)
$sonuclar.Add((Api 'giris servisi' 'https://auth.tetikte.com/auth/v1/health' { param($g) if("$g" -notmatch 'version|GoTrue|name'){ 'beklenen saglik cevabi yok' } }))
# veritabanı: ücretsiz görünümden tek satır
$sonuclar.Add((Api 'veritabani' "$SB/rest/v1/ucretsiz_soru?select=id&order=id.asc&limit=3" { param($g) $j=$g|ConvertFrom-Json; if($j.Count -lt 1){ 'ucretsiz_soru bos dondu' } }))
# SEVİYE TESTLERİ: 04.10'da Yeterlilik seti 30'un 4'ünü kasada bulamadı, sayfa "Sorular hazırlanıyor"da kaldı ve
# hiçbir nöbetçi görmedi. Yeterlilik: sabit 30'un HEPSİ ücretsiz görünümde olmalı. SGS: havuzdan en az test_soru kadar.
function KimlikSay($ids){
  $bulunan=0
  for($i=0;$i -lt $ids.Count;$i+=60){
    $parca=$ids[$i..([Math]::Min($i+59,$ids.Count-1))]
    $liste=[uri]::EscapeDataString((($parca|ForEach-Object{ '"' + ($_ -replace '"','') + '"' }) -join ','))
    $c=Invoke-WebRequest -Uri "$SB/rest/v1/ucretsiz_soru?select=id&id=in.($liste)" -Headers $sbBas -TimeoutSec $ZamanAsimi -UseBasicParsing
    $satir=$c.Content|ConvertFrom-Json; $bulunan+=$satir.Count   # K2: @(...|ConvertFrom-Json) PS 5.1'de diziyi tek öğe sayar
  }
  return $bulunan
}
foreach($sv in @(@{ ad='seviye testi Yeterlilik'; dosya='veri\seviye\smmm-set.json' }, @{ ad='seviye testi SGS'; dosya='veri\seviye\sgs-havuz.json' })){
  $o=[pscustomobject]@{ ad=$sv.ad; url=$sv.dosya; durum='YESIL'; kod=200; bayt=0; ms=0; kusur=''; deneme=1 }
  try{
    $j=Get-Content (Join-Path $depoKok $sv.dosya) -Raw -Encoding UTF8 | ConvertFrom-Json
    if($j.sorular){ $ids=@($j.sorular|ForEach-Object{ $_.id }); $gerek=$ids.Count }
    else{ $ids=New-Object System.Collections.Generic.List[string]
          foreach($d in $j.havuz.PSObject.Properties){ foreach($z in $d.Value.PSObject.Properties){ foreach($q in @($z.Value)){ $ids.Add([string]$q.id) } } }
          $ids=$ids.ToArray(); $gerek=[int]$j.test_soru }
    $n=KimlikSay $ids; $o.bayt=$n
    if($n -lt $gerek){ $o.durum='KIRMIZI'; $o.kusur="ucretsiz havuzda $n / $($ids.Count) soru var, test $gerek ister - sayfa 'Sorular hazirlaniyor'da kalir" }
    elseif($j.sorular -and $n -lt $ids.Count){ $o.durum='KIRMIZI'; $o.kusur="sabit setin $($ids.Count - $n) sorusu kasada yok (node motor/seviye-set-sec.js smmm --onar)" }
  }catch{ $o.durum='KIRMIZI'; $o.kod=0; $o.kusur="olculemedi: $($_.Exception.Message)" }
  $sonuclar.Add($o)
}
$dizi=$sonuclar.ToArray()

foreach($s in $dizi){
  $renk=$(if($s.durum -eq 'YESIL'){'Green'}else{'Red'})
  Write-Host ("  {0,-14} {1,-8} HTTP {2,3} · {3,8:N0} bayt · {4,5} ms{5}" -f $s.ad,$s.durum,$s.kod,$s.bayt,$s.ms,$(if($s.kusur){" · $($s.kusur)"}else{''})) -ForegroundColor $renk
}
$kirmizi=@($dizi|Where-Object{ $_.durum -eq 'KIRMIZI' })
$genel=$(if($kirmizi.Count){'KIRMIZI'}else{'YESIL'})
Write-Host ("`nSITE NOBETI: {0} ({1}/{2} yesil)" -f $genel,($dizi.Count-$kirmizi.Count),$dizi.Count) -ForegroundColor $(if($kirmizi.Count){'Red'}else{'Green'})

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\site-nobeti.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum=$genel
  yesil=($dizi.Count-$kirmizi.Count); kirmizi=$kirmizi.Count
  hedefler=@($dizi|ForEach-Object{ [pscustomobject]$_ })
})

if($kirmizi.Count -and $Mail){
  $govde=("SITE NOBETI KIRMIZI - " + (Get-Date -Format 'dd.MM.yyyy HH:mm') + "`n`n" +
          (($kirmizi|ForEach-Object{ "$($_.ad)  ->  $($_.url)`n    $($_.kusur)  (HTTP $($_.kod), $($_.bayt) bayt)" }) -join "`n`n") +
          "`n`nOlcut: HTTP 200 + asgari boy + imza metni. Her adres $Deneme kez denendi.")
  try{ & (Join-Path $depoKok 'arac\alarm-maili.ps1') -Konu 'TETIKTE SITE NOBETI KIRMIZI' -Mesaj $govde }
  catch{ Write-Host "!! alarm maili gitmedi: $($_.Exception.Message)" -ForegroundColor Red }
}
# ⛔ Kirmizida cikis kodu 1 - akis KIRMIZI gorunsun, sessiz gecmesin.
if($kirmizi.Count){ exit 1 }
