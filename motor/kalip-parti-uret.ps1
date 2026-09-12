# ============================================================================
#  KALIP PARTİ ÜRETİCİSİ — SÖZLEŞME UYGULAYICI (01.09.2026 gece)
#  Cem: "HEPSİNİ ONAYLIYORUM... 30 soru yap BÜTÜN kararlarla, ben kontrol edeyim"
#
#  KALIP-SOZLESMESI.md'nin 10 maddesini uygular:
#   1 çekirdek (soru+5şık+tuzaklı açıklama+HAP)  2 hesaplıda tablo+verilenler+oynatıcı
#   3 konu başına İKİZ  4 ipucu merdiveni  5 SAYILI rozet (köprüden)
#   6 biçim çapası (onaylı örnek istemde)  8 makine kapıları (aritmetik+kaynak+ikiz-kod-denetimi)
#   (9 kart-akışı ayrı ürün ekranı; bu sayfa KONTROL sayfasıdır — tıklanabilir tam deneyim)
#  Konular KÖPRÜDEN (en çok çıkan), kaynaklar AMBARDAN; kaynaksız konu üretilmez
#  ve KAYNAK-BORCU olarak raporlanır (Cem kuralı: çok çıkıyorsa yutulacak).
#  Cache: veri/fabrika/kalip-parti-<etiket>.json (kesinti güvenli). KASAYA YAZMAZ.
# ============================================================================
param(
  [string]$Sinav='SGS',
  [string]$DersRegex='Finansal Muhasebe',
  [string]$KonuDosya='',
  [switch]$RedYenile,      # 03.09: hakem HAYIR / DERS-DISI kalan cache kayitlarini dusur, yeniden uret
  [switch]$SadeceHtml,     # 03.09 Cem "her seyde bedeli sor": yalniz cache'ten HTML cizer; API cagrisi denenirse DURUR (bedel 0 garantisi)
  [string]$PilotId='',     # 03.09: pilot - model fazlari YALNIZ bu id'lere calisir (virgullu: kp-04,kp-31); digerleri cache'ten
  [switch]$AdimYenile,     # 04.09 Cem "30'luk SGS seti": pilot id'lerin ESKI adimlari silinir, ogretici istemle yeniden yazilir
  [switch]$SadeceAdim,     # 04.09: yalniz FAZ B (adim) calisir; ikiz/yevmiye/hakem fazlari atlanir (bedel yalniz onaylanan is)
  [switch]$Sade,           # 04.09 Cem "dogru kismini herkesin anlayacagi dilde": FAZ S (sade Dogrusu + anahtar kavram) - sade'si OLMAYAN sorulara; ayri onayli bedel
  [switch]$SadeYenile,     # 04.09: FAZ S eldeki sade'yi de yeniden yazar
  [int]$Adet=30,
  [int]$UzunlukTavan=350,  # 04.09: ders bazlı soru uzunluğu tavanı (kr). FMuh medyan 317 → 350 (Cem 02.09). Maliyet medyan 551 → 600.
  [string]$Etiket='sgs-fmuh-30',
  # 01.09 Cem: "bunlar tam FMuh degil" - arsiv tum muhasebeyi tek catida tutuyor;
  # KAYIT-ODAKLI parti icin analiz/ileri-TMS konulari regex'le DISLANIR (dislanan
  # konu kendi dersinin partisine gider, cope degil).
  [string]$KonuDisla='',
  [string]$Zorluk='',      # 05.09 Cem "zor olsun, katmanlı": 'zor' → soru istemine ZORLUK bloğu (≥4 bağlı ara hesap, katman birleşimi, çeldirici = atlanan katman), adım 6-10
  [int]$DonemPencere=0,    # 06.09 K10 (Cem "yeni sınav kalıplarını almak lazım"): >0 ise konu adayları SON N dönemin etiketlerine göre sıralanır/süzülür ve biçim çapası o pencerenin GERÇEK kitapçığından konuya göre otomatik seçilir (Ö18)
  [string]$OrnekDosya='',  # 05.09: biçim çapası dosyadan (konunun GERÇEK çıkmış sorusu); yoksa sabit p90-SGS-01 örneği (Finansal) kullanılır
  [switch]$Verilenler,     # 06.09 Cem "1 yap": FAZ V - sorudaki her sayı ad+değer+anlam satırı (Haiku); builder VERİLENLER bloğunu çizer
  [switch]$VerilenYenile,  # 06.09: eldeki verilenler listesini de yeniden yazar
  [switch]$KonuGiris,      # 06.09 Cem "geç": FAZ G - konu girişi kartı (nedir / sınavda nasıl sorulur / yöntemler / örnek), Haiku ≈0,005 USD
  [switch]$GirisYenile,    # 06.09: eldeki girişi de yeniden yazar
  # 07.09 gece A kovası (Cem "A kovasındaki 10 maddeyi kapa"): kör çözüm + ikinci hakem + konu listesi kalıcılığı
  [string]$KorModel='claude-opus-5',   # FAZ K: anlatımı görmeden ASIL soruyu çözen bağımsız model (üreticiden FARKLI model; hesap sorusunda zorunlu)
  [switch]$KorYenile,      # eldeki kör çözüm kararını yeniden verdirir
  [switch]$KorKaynak,      # 11.09 Cem "bu yapalım": FAZ K'ye KAYNAK METNİ verilir (anlatım DEĞİL). Körlük korunur, ezber körlüğü kalkar.
  [int]$KorKaynakTavan=4500,  # kör pakete giren kaynak metninin karakter tavanı (Opus girdi 15 USD/M — tavan bedeli tutar)
  [switch]$Hakem2Yenile,   # eldeki ikinci hakem kararını yeniden verdirir
  [switch]$KonuYenile,     # konu listesi dosyasını (veri/fabrika/konu-secim-<etiket>.json) yok sayıp konuları yeniden seçer
  [switch]$Toplu,          # 08.09 Cem "daha ucuza": her fazın İLK denemesi Message Batches ile (yarı fiyat, paralel); kapıdan dönen tekrarlar anlık
  [int]$TopluBeklemeDk=$(if("$env:MEVZUAT_TOPLU_BEKLE_DK" -match '^\d+$'){ [int]$env:MEVZUAT_TOPLU_BEKLE_DK } else { 180 }),   # 09.09 Tur 2: kuyruk takılırsa faz 45 dk'da anlığa düşsün (ortam değişkeni; koşucu parametre geçirmiyor)
  [string]$HazirSoru='',   # 09.09 Cem "bunu sen yapabiliyorsun niye para verelim" → B: GM'in oturumda yazdığı soru+adım dosyası (json dizi). FAZ A ve FAZ B model çağrısı YOK; FAZ A'nın kod kapıları + hakem/kör/hakem2/giriş/ikiz/sim aynen koşar.
  [string]$EskiKaynak='',  # 08.09 B yolu (KURTARMA): eski soru dosyası (json dizi: id, soru, siklar, dogru, aciklama, konu, ders, kanun_no, madde_no, madde_damga, kaynak). FAZ A koşmaz; FAZ U eski soruyu kalıp alanlarına uyarlar, kalan fazlar aynen.
  [switch]$Simulasyon,     # 06.09 Cem "geç": FAZ Ö - öğrenci simülasyonu: Haiku hiç bilmeyen rolünde adımları okuyup ikizi çözer (≈0,01 USD)
  [string]$SimModel='claude-haiku-4-5-20251001',  # 06.09 kalibrasyon: 'claude-sonnet-5' verilirse sonuç `simulasyon_sonnet` alanına yazılır (Haiku sonucu korunur)
  [switch]$SimYenile,      # 06.09 Ö29: adım yenilenince simülasyon da yeniden koşar
  [string]$SoruModel='claude-sonnet-5',   # 11.09: FAZ A modeli. Olculdu: maliyetin %55'i FAZ A ciktisi ve Sonnet cikti 15 USD/M, Haiku 5 USD/M (3 kat). Kalite karsilastirmasi icin degistirilebilir.
  [switch]$CizmeAtla       # 11.09 Cem: toplu tamamlama turunda denetim HTML'ini ÇİZME (ölçüldü: 77 soruda 54 sn; 27 partide ≈24 dk). Bitiş damgası BASILMAZ - yeni üretimde kullanma.
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
. (Join-Path $kok 'arac\kimlik-ayikla.ps1')   # 11.09: kimlik ayiklama TEK kaynaktan
# 08.09 19:55 Cem "bir yerden sen bas, bir yerden başka gönder; ikisi de koşsun": anlık hatlar planın başından, toplu hatlar sonundan gelir;
# aynı etiketi iki hat basmasın → ETİKET SAHİPLİĞİ. Üretici başlarken claim-<etiket>.json yazar; canlı başka pid sahipse ya da etiket
# bitiş damgası (sql-yerel/kalip-parti-<etiket>.html) varsa ATLAR. Koşan koşucular eski kod olsa da üretici her etikette yeniden okunur.
# Bilinçli yeniden basım için MEVZUAT_CLAIM=0. -SadeceHtml çizimi sahiplik istemez.
if(-not $SadeceHtml -and "$env:MEVZUAT_CLAIM" -ne '0'){
  $claimYol=Join-Path $kok "veri\fabrika\kosucu-log\claim-$Etiket.json"
  $cl=$null; $sahip=$null
  if(Test-Path $claimYol){
    # 09.09 00:07 ÖLÇÜLDÜ (maliyet-kolay ATLANDI): ölü üreticinin pid'i (43984) başka bir sürece yeniden verilmişti, Get-Process "canlı" dedi →
    # etiket sahipsiz kaldı. Sahiplik yalnız o pid'in KOMUT SATIRI bu üreticiyi ve bu etiketi taşıyorsa canlı sayılır.
    try{ $cl=ConvertFrom-Json -InputObject (Get-Content $claimYol -Raw); $sp=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$cl.pid)" -ErrorAction SilentlyContinue; if($sp -and "$($sp.CommandLine)" -match 'kalip-parti-uret' -and "$($sp.CommandLine)" -match [regex]::Escape("-Etiket $Etiket")){ $sahip=$sp } }catch{}
    if($sahip -and [int]$cl.pid -ne $PID){ "ATLANDI: $Etiket başka hatta basılıyor (pid $($cl.pid) · $($cl.mod) · $($cl.zaman))"; exit 0 }
  }
  # 08.09 23:27 KAZA 5 dersi: damga kontrolü yalnız sahiplik dosyası VARSA yapılıyordu; sahiplik mekanizmasından (19:55) önce bitmiş etiketlerin
  # sahiplik dosyası yok → koşucular yeniden başlatılınca denetim-cokzor ve fmuh-kolay YENİDEN basılmaya başladı (FAZ V Haiku çağrıları, 1 yeni soru).
  # Damga kontrolü artık sahiplikten bağımsız: bitmiş etiket her koşulda atlanır.
  if(-not $sahip -and (Test-Path (Join-Path $kok "sql-yerel\kalip-parti-$Etiket.html"))){ "ATLANDI: $Etiket zaten basılmış (bitiş damgası var; yeniden basım için MEVZUAT_CLAIM=0)"; exit 0 }
  [IO.File]::WriteAllText($claimYol,(ConvertTo-Json -InputObject @{ pid=$PID; mod=$(if($Toplu){ 'toplu' } else { 'anlik' }); zaman=(Get-Date -Format 'dd.MM HH:mm') } -Compress),[Text.UTF8Encoding]::new($false))
  "ETİKET SAHİPLİĞİ: $Etiket → pid $PID ($(if($Toplu){ 'toplu' } else { 'anlik' }))"
}
if($SadeceHtml){
  # SIGORTA: model cagrisi yapan tek kapi bu fonksiyon; -SadeceHtml'de patlar, betik durur, para gitmez.
  function Invoke-ClaudeMesaj { throw 'SADECE-HTML: API cagrisi engellendi - cache eksik, once Cem''den bedel onayi al.' }
  "SADECE-HTML modu: API kapali, yalniz cache'ten cizim"
}
$CACHE=Join-Path $kok "veri\fabrika\kalip-parti-$Etiket.json"
$HEDEF=Join-Path $kok "sql-yerel\kalip-parti-$Etiket.html"
# ⛔ 12.09 bulut kosusu #1: bu iki klasor de .gitignore'da, Actions checkout'unda
#    YOKTUR ve WriteAllText klasor acmaz. Yerelde hep var oldugu icin yillarca
#    gorunmedi; bulutta ilk kosuda dustu. Acilista bir kez acilir - bedelsiz.
New-Item -ItemType Directory -Force (Split-Path $CACHE -Parent) | Out-Null
New-Item -ItemType Directory -Force (Split-Path $HEDEF -Parent) | Out-Null
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }

# --- KAPI-BAKIYE (10.09 ÖLÇÜLDÜ: GM Vergi t4) ------------------------------------------------------------------------
# vergi-kolay ve vergi-zor partileri hakem/kör/ikiz fazlarını TAMAMLADIKTAN sonra giriş fazında HTTP 400 ile öldü.
# Gövde: {"type":"error","error":{"type":"invalid_request_error","message":"Your credit balance is too low to access
# the Anthropic API..."}}. Yani bakiye koşunun ORTASINDA bitti: harcanan para duruyor, parti yarım kalıyor ve yeniden
# koşulduğunda hakem parası İKİNCİ KEZ ödeniyor. 400 dönen çağrı ücretsiz olduğu için bunu koşunun BAŞINDA ölçmek
# bedelsizdir: 1 jetonluk bir yoklama atılır. Yalnız "credit balance" mesajı koşuyu DURDURUR — başka her hata
# (ağ, model adı, geçici 429/5xx) uyarıdır, çünkü yanlış teşhisle koşuyu durdurmak da bir kayıptır.
if(-not $SadeceHtml -and "$env:MEVZUAT_BAKIYE_KAPISI" -ne '0'){
  $bkHedef=Get-ApiHedef
  # yoklama gövdesi Messages API biçimindedir; OpenRouter hattı /chat/completions kullanır, orada yoklama YAPILMAZ
  # (yanlış biçimden dönen hata bakiye hatası sanılmaz, ama boşuna gürültü de üretmesin).
  if(@('anthropic','aws') -notcontains "$($bkHedef.ad)"){
    # ⛔ KAPI-HAT (12.09.2026, Cem "sadece anthropic kullanalım der misin").
    #    ÖNCEDEN bu satır yalnızca "atlandı" deyip geçiyordu. Yani başka bir
    #    hatta (OpenRouter vb.) koşulduğunda BAKİYE FRENİ SESSİZCE DEVRE DIŞI
    #    kalıyordu — ve 11.09'da aylık tavan da Cem kararıyla kapı olmaktan
    #    çıkarıldı. İkisi birleşince geriye HİÇ fren kalmıyordu: yanlış bir
    #    ayar bakiye bitene kadar para yakardı.
    #    Ölçülü iki sebep daha:
    #      · Toplu istek (yarı fiyat) yalnız Anthropic-native'de var; OpenRouter
    #        batch API'yi desteklemiyor → üretim bedeli İKİ KATI olurdu.
    #      · Cem'in değişmez kuralı: "müşteri verisi güvenli yerde, DOĞRUDAN
    #        sağlayıcı." OpenRouter araya üçüncü bir şirket koyar.
    #    Bilerek aşmak için: MEVZUAT_HAT_KAPISI=0
    if("$env:MEVZUAT_HAT_KAPISI" -eq '0'){
      Write-Host "KAPI-HAT: BİLEREK AŞILDI (MEVZUAT_HAT_KAPISI=0) · hat '$($bkHedef.ad)' · BAKİYE FRENİ YOK" -ForegroundColor Red
    } else {
      throw "KAPI-HAT DÜŞTÜ: soru üretimi yalnız 'anthropic' (ya da 'aws') hattında koşar; şu anki hat '$($bkHedef.ad)'. Bu hatta KAPI-BAKIYE çalışmaz (bakiye freni YOK), toplu istek yoktur (bedel 2 katı) ve veri üçüncü bir aracıdan geçer. Bilerek aşmak için MEVZUAT_HAT_KAPISI=0."
    }
  }
  else{
  $bkGovde=@{ model='claude-haiku-4-5-20251001'; max_tokens=1; messages=@(@{ role='user'; content=@(@{ type='text'; text='.' }) }) }
  try{
    [void](Invoke-RestMethod -Method Post -Uri ($bkHedef.taban + '/v1/messages') -Headers $bkHedef.basliklar -Body ([Text.Encoding]::UTF8.GetBytes(($bkGovde | ConvertTo-Json -Depth 8))) -ContentType 'application/json' -TimeoutSec 60)
    "KAPI-BAKIYE: açık (1 jetonluk yoklama geçti)"
  }catch{
    $bkGovdeHata=''
    try{ $bkResp=$_.Exception.Response; if($bkResp){ $bkSr=New-Object IO.StreamReader($bkResp.GetResponseStream()); $bkGovdeHata=$bkSr.ReadToEnd() } }catch{}
    if("$bkGovdeHata" -match '(?i)credit balance'){
      throw "KAPI-BAKIYE DÜŞTÜ: Anthropic bakiyesi yetersiz, parti HİÇ BAŞLAMADAN durduruldu (yarım koşu = iki kez ödenen hakem parası). Sunucu: $bkGovdeHata"
    }
    Write-Host "KAPI-BAKIYE: yoklama yanıt vermedi, koşu sürüyor (bakiye hatası DEĞİL) - $($_.Exception.Message)" -ForegroundColor DarkYellow
  }
  }
}

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }
# 01.09 Cem yakaladi: model aciklamayi bazen YAPILI nesne dondurur; ekrana ham
# '@{ne_soruluyor=...}' dokulur. Nesneyse alanlarindan okunur metin derlenir.
function AciklamaDuz($a){
  if($null -eq $a){ return '' }
  if($a -is [string]){ return $a }
  $p=New-Object System.Collections.Generic.List[string]
  if($a.PSObject.Properties['ne_soruluyor'] -and $a.ne_soruluyor){ $p.Add("Ne soruluyor: $($a.ne_soruluyor)") }
  if($a.PSObject.Properties['kural'] -and $a.kural){ $p.Add("Kural: $($a.kural)") }
  if($a.PSObject.Properties['tuzak'] -and $a.tuzak){ $p.Add("$($a.tuzak)") }
  if($a.PSObject.Properties['hesap'] -and $a.hesap){ $p.Add("Hesap: $($a.hesap)") }
  # 02.09 akşam ölçümü: 26 sorunun 2'sinde "Dogrusu:" sızmıştı — kaynağı model değil,
  # BU SATIRDI (üretici kendi kusurunu yazıyordu; yazım kapısı bundan ÖNCE koşuyor).
  if($a.PSObject.Properties['dogrusu'] -and $a.dogrusu){ $p.Add("Doğrusu: $($a.dogrusu)") }
  if($p.Count -eq 0){ foreach($pr in $a.PSObject.Properties){ $p.Add("$($pr.Value)") } }
  return ($p -join ' ')
}
# sema tur adlari serbest donebiliyor - cizdiricinin tanidigi enum'a indir
function Katla2([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
function SemaNormalize($s){
  if($null -eq $s -or -not $s.tur){ return $s }
  $t="$($s.tur)".ToLowerInvariant() -replace 'ş','s' -replace 'ı','i'
  $yeni=switch -Regex ($t){ 'yevmiye' {'yevmiye'} 'elem' {'eleme'} 'karar' {'karar'} 'akis|akis' {'akis'} default {''} }
  if(-not $yeni){
    if($s.PSObject.Properties['ogeler'] -and $s.ogeler -and $s.ogeler.PSObject.Properties['borc']){ $yeni='yevmiye' }
    elseif($s.PSObject.Properties['kayitlar'] -and $s.kayitlar){ $yeni='yevmiye' }
    elseif($s.PSObject.Properties['ogeler'] -and @($s.ogeler).Count -and @($s.ogeler)[0] -is [string]){ $yeni='akis' }
  }
  if($yeni){ $s.tur=$yeni }
  return $s
}
function AmbarCek([string[]]$desenler,[int]$tavan=9000){
  $topla=New-Object System.Collections.Generic.List[string]
  $adlar=New-Object System.Collections.Generic.List[string]
  foreach($d in $desenler){
    if(-not $d){ continue }
    # 03.09: "p.0 - Künye ve yürürlük" parcasi kaynak DEGILDIR (icindekiler); disarida birakilir
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($d)+'&kaynak_ad=not.ilike.'+[uri]::EscapeDataString('% p.0 -%')+'&kaynak_ad=not.ilike.'+[uri]::EscapeDataString('%[giris]%')+'&limit=6'
    # 03.09 (SGS bosluk partisi olcumu): dayanak madde NUMARASIZ kanun ("TTK (6102 s.K.)") ise
    # ad aramasi bos donuyor, konu 'kaynak borcu' oluyordu - oysa TTK m.776 (bono unsurlari)
    # ambarda. '@<kanun oneki>|<kelime>' deseni: o kanunun maddeleri icinde METIN aramasi.
    # 03.09 '~kelime kelime' deseni: kaynak_ad icinde Turkce toleransli regex (imatch); kelimeler sirali,
    # aralarinda herhangi bir sey olabilir ('~merkezi takas kurulus' -> "Merkezi Takas Kuruluslarinin...").
    if($d.StartsWith('~')){
      $rxA=''
      foreach($kw in ($d.Substring(1) -split '\s+')){
        if(-not $kw){ continue }
        $kwRx=''
        foreach($ch in $kw.ToLowerInvariant().ToCharArray()){
          switch -CaseSensitive ("$ch"){
            # 09.09 MTA ölçümü: 'a' şapkalı eşi yoktu → "Kârlılık oranları" notu '~teori karlilik oranlari' desenine
            # HİÇ dönmüyordu (sessiz kaynak kaybı). Düzeltmeli harfler (â, î, û) sınıflara eklendi.
            'a' { $kwRx+='[aâ]' } 'c' { $kwRx+='[cç]' } 'g' { $kwRx+='[gğ]' } 'i' { $kwRx+='[iıİIî]' } 'o' { $kwRx+='[oö]' } 's' { $kwRx+='[sş]' } 'u' { $kwRx+='[uüû]' }
            default { if("$ch" -match '[a-z0-9]'){ $kwRx+="$ch" } else { $kwRx+='.' } }
          }
        }
        if($rxA){ $rxA+='.*' }; $rxA+=$kwRx
      }
      $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch.'+[uri]::EscapeDataString($rxA)+'&kaynak_ad=not.ilike.'+[uri]::EscapeDataString('% p.0 -%')+'&kaynak_ad=not.ilike.'+[uri]::EscapeDataString('%[giris]%')+'&limit=6'
    }
    if($d.StartsWith('@')){
      $parca=$d.Substring(1) -split '\|',2
      if($parca.Count -lt 2 -or -not $parca[1]){ continue }
      # 03.09: konu kokleri ASCII ('buro'), ambar metni Turkce ('büro') -> ilike kacirir. Her harf
      # Turkce esiyle karakter sinifina cevrilip PostgREST 'imatch' (buyuk/kucuk duyarsiz regex)
      # kullanilir (konu-kaynak-karnesi.ps1 TurkceRegex dersi).
      $rx=''
      foreach($ch in $parca[1].ToLowerInvariant().ToCharArray()){
        switch -CaseSensitive ("$ch"){
          'c' { $rx+='[cç]' } 'g' { $rx+='[gğ]' } 'i' { $rx+='[iıİI]' } 'o' { $rx+='[oö]' } 's' { $rx+='[sş]' } 'u' { $rx+='[uü]' }
          ' ' { $rx+='\s?' }
          default { if("$ch" -match '[a-z0-9]'){ $rx+="$ch" } else { $rx+='.' } }
        }
      }
      # limit 3: tek kaynak (Teblig m.17'nin 24 parcasi gibi) 10'luk kaynak kotasini dolduramasin
      $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($parca[0]+'%')+'&metin=imatch.'+[uri]::EscapeDataString($rx)+'&limit=3'
    }
    # 02.09 KRITIK: eski hali 'catch{ continue }' idi - AG HATASI sessizce
    # "kaynak yok" gibi davraniyordu ve konu KAPI-A'dan 'alakasiz kaynak' diye
    # duduyordu. Olculemeyen ile YOK ayni sey degildir: artan bekleme ile 3 kez
    # denenir, yine olmazsa AG HATASI olarak isaretlenir (kaynak borcu DEGIL).
    $r=$null; $agHatasi=$null
    foreach($dn in 1..3){
      try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60; $agHatasi=$null; break }
      catch{ $agHatasi=$_.Exception.Message; if($dn -lt 3){ Start-Sleep -Seconds (4*$dn) } }
    }
    if($agHatasi){ $script:AMBAR_AG_HATASI=$agHatasi; continue }
    foreach($x in @($r)){
      # 06.09 KAPI-K kaynak süzgeci: pencere sözlüğü varsa, adı pencere dışı kök taşıyan TEORİ NOTU kaynak paketine girmez
      # ("Teori Notu - kusurlu ve bozuk mamul maliyetleri" → 'kusur' son 7 dönem Maliyet sorularında yok). Kanun/standart/THP kaynağı süzülmez.
      # 09.09: konu ADIYLA bulunan not ('~teori kok kok' deseni) pencere süzgecine girmez — adı konunun köklerini taşıyor, konu dışı sayılamaz;
      # uzun adlı yeni notlar ("Ücret bordrosu kaydı (770/760/720 giderler, 335 Personele Borçlar, ...)") geniş sözlükte tek kök eksiğiyle atılıyordu.
      if($script:PENCERE_KOK -and $script:PENCERE_KOK.Keys.Count -and -not $script:GK_DERS -and -not $d.StartsWith('~teori') -and "$($x.kaynak_ad)" -match '^(TEORI|Teori Notu)'){
        # 06.09 maliyet-k10d dersi: "Ortak (müşterek) maliyetlerin dağıtımı" notu tek parantez kelimesi yüzünden atılıyordu → dar sözlükte ≥2 kök eksikse
        # ya da geniş sözlükte ≥1 kök eksikse atlanır ("kusurlu ve bozuk mamul": dar 2 eksik → atlanır · "müşterek": dar 1 eksik, geniş var → kalır)
        $adKisim=("$($x.kaynak_ad)" -replace '^(TEORI|Teori Notu)\s*-\s*',''); $disiDar=@(PencereKavram $adKisim -YalnizDar); $disiGenis=@(PencereKavram (($adKisim -split '\s+' | Where-Object { $_.Length -ge 6 }) -join ' ') | Where-Object { $w=$_; -not $script:PENCERE_KOK.ContainsKey($w.Substring(0,5)) })
        if($disiDar.Count -ge 2 -or $disiGenis.Count -ge 1){ Write-Host "  PENCERE DIŞI KAYNAK atlandı: $($x.kaynak_ad) (dar: $($disiDar -join ', ') · geniş: $($disiGenis -join ', '))" -ForegroundColor DarkGray; continue }
      }
      # 07.09 Ö47 asgari GÜNCELLİK KAPISI (Vergi): eski 5422 dönemi Kurumlar Vergisi tebliğleri (Seri No ≠ 1) ve metninde "5422 sayılı" geçen kaynak paketi dışı
      if($DersRegex -match 'Vergi'){ $kaEski=("$($x.kaynak_ad)" -match '(?i)Kurumlar Vergisi.*Seri No:?\s*(\d+)' -and [int]$matches[1] -ne 1) -or ("$($x.metin)" -match '5422 sayılı'); if($kaEski){ Write-Host "  GÜNCELLİK: eski dönem kaynağı atlandı: $($x.kaynak_ad)" -ForegroundColor DarkGray; continue } }
      if($adlar -notcontains $x.kaynak_ad){ $adlar.Add($x.kaynak_ad); $topla.Add("[$($x.kaynak_ad)] $($x.metin)") }
    }
    # 03.09 OLCULDU (SMMM 'kambiyo kari kaydi' -> KAYNAK BORCU; oysa THP 646 KAMBIYO KARLARI ambarda):
    # '@' aramasi yalniz METIN icinde bakiyordu; hesap adinin KENDISI kelimeyi tasiyorsa yakalanmiyordu.
    # Ikinci sorgu: ayni kanun onekinde kaynak_ad icinde de ara (Turkce toleransli imatch).
    if($d.StartsWith('@') -and @($r).Count -eq 0){
      $u2='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($parca[0]+'%')+'&kaynak_ad=imatch.'+[uri]::EscapeDataString($rx)+'&limit=3'
      $r2=$null; try{ $r2=Invoke-RestMethod -Uri $u2 -Headers $SB -TimeoutSec 60 }catch{}
      foreach($x in @($r2)){ if($adlar -notcontains $x.kaynak_ad){ $adlar.Add($x.kaynak_ad); $topla.Add("[$($x.kaynak_ad)] $($x.metin)") } }
    }
    if($adlar.Count -ge 10){ break }
  }
  # 11.09 KAPI-KP: eskiden burada kor `Substring($tavan)` vardi ve son kaynagi
  # BASLIGINDAN sonra kesiyordu. Artik sigmayan blok KOMPLE duser (PaketKirp).
  # Konu bilinmedigi icin siralama yok, yalniz sinirda kesme; siralamayi
  # kaynak_metin_ozet kurulurken konu ile yapiyoruz.
  $m=($topla -join "`n---`n")
  if($m.Length -gt $tavan){ $atD=$null; $m=PaketKirp $m '' $tavan ([ref]$atD) }
  return @{ metin=$m; adlar=@($adlar); agHatasi=$script:AMBAR_AG_HATASI }
}
# --- DAYANAK KARA LISTESI (02.09 Cem: "cop dayanaklari bosalt") --------------
# Kopru dayanaklari Excel'den geliyor ve bir kismi cop: tek maddeye binlerce konu
# baglanmis. AMA korlemesine bosaltmak ZARARLI - olculdu: VUK m.275'e 2.088 konu
# bagli ve %80'i DOGRU; onu bosaltmak 1.670 dogru dayanagi silerdi.
# Bu yuzden yalnizca OLCULMUS copler (yanlis orani >=%50) listeye alinir; uretici
# o dayanagi YOK SAYAR ve konuyu dogrudan ambarda arar. Kopru kaydi silinmez.
# Olcum araci: arac/dayanak-kara-liste.ps1 (hakem, maddenin GERCEK metniyle sorar).
$KARA_DAYANAK=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$klYol=Join-Path $kok 'veri\dayanak-kara-liste.json'
if(Test-Path $klYol){
  try{
    $kl=Get-Content $klYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($d in @($kl.kara_liste)){ if("$d".Trim()){ [void]$KARA_DAYANAK.Add("$d".Trim()) } }
    if($KARA_DAYANAK.Count){ "kara liste: $($KARA_DAYANAK.Count) guvenilmez dayanak yok sayilacak" }
  }catch{ "kara liste okunamadi: $($_.Exception.Message)" }
}
function KaraMi([string]$dayanak){
  $t=($dayanak -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $t){ return $false }
  return $KARA_DAYANAK.Contains($t)
}
# dayanak ham metninden ambar sorgu desenleri türet
$KANUN=@{ 'VUK'='VUK (213 s.K.)'; 'TTK'='TTK (6102 s.K.)'; 'TBK'='TBK (6098 s.K.)'; 'GVK'='GVK (193 s.K.)'; 'KVK'='KVK GUT (1 Seri No)'; 'KDV'='KDV%'; 'SPK'='Sermaye Piyasası K. (6362 s.K.)'; 'İİK'='İİK%'; 'SGK'='5510 s. SGK Kanunu'; 'SMMM'='SMMM K. (3568 s.K.)' }
# --- ATIF GENISLETME (03.09 olcumu, SMMM ret turu) ----------------------------
# Model dogru maddeyi BILIYOR ve 'dayanak' alanina yaziyor (GVK m.6 dar mukellef,
# SPKn m.26/2 yonetim kontrolu, m.35/C, m.83/4) ama kaynak paketi konu kelimesiyle
# bulunan tanim maddelerinden (m.1-m.3, VUK m.4) olusuyordu -> hakem 'kaynakta yok'
# diye reddediyordu. Cozum: hakemden ONCE modelin atif verdigi maddeler AMBARDAN
# cekilip kaynak paketine eklenir. Hakem yine metne bakar; uydurma madde ambarda
# bulunmaz, o zaman ret haklidir. Bu, hakemi gevsetmek degil, hakeme dogru
# dosyayi vermektir.
function AtifDesen([string]$dayanak){
  $d=New-Object System.Collections.Generic.List[string]
  if(-not $dayanak){ return @() }
  # 03.09 ikinci olcum (SMMM SPK kp-05/11/13 atif bos kaldi): model kanunu SAYIYLA ("6362 s.K. m.35/C"),
  # kisaltmayla ("SerPK") ya da Teblig adiyla ("Kurumsal Yönetim Tebliği (II-17.1) m.3") aniyor.
  # ⛔ 11.09 OLCULDU: bu fonksiyon 777 KAYNAK-EKSIK retinin buyuk kisminin
  #    KOK NEDENI. Dayanak DOGRU yaziliyor, madde AMBARDA VAR, ama kisaltma
  #    tablosunda olmayan kanun icin desen BOS donuyor -> atif genisletme hic
  #    atesle.miyor -> dogru madde pakete HIC girmiyor -> hakem "kaynakta yok"
  #    diyor. Olculen ornekler (ucu de ambarda VAR, ucu de desen uretmiyordu):
  #      "6356 sayili Sendikalar ve TIS Kanunu m.17"      -> BOS
  #      "2577 sayili IYUK m.28/6 (6183 s.K. m.48 atfi)"  -> BOS
  #      "213 sayili VUK'un 275 inci maddesi"             -> BOS (sira sayili)
  #    ⚠ Ayni kusur DERS_KANUN listesinde 07.09'da bulunup duzeltilmis, ama bu
  #      tablo guncellenmemisti - kanun bir kapidan gecip digerinde takiliyordu.
  # SIRA SAYILI MADDE: "275 inci maddesi" -> "m.275"
  $dayanak = $dayanak -replace '(\d{1,4})\s*(?:inci|ıncı|uncu|üncü|nci|ncı)\s*madde(si|sinde|sine)?','m.$1 '
  $t=$dayanak -replace 'Sermaye Piyasas[ıi] K(anunu|\.)?\s*(\(6362[^)]*\))?','SPK ' -replace '\bSPKn\b|\bSerPK\b|\b6362\s*s(ayılı|\.)?\s*(K\.|Kanun)?','SPK ' -replace 'Kurumlar Vergisi K(anunu|\.)?','KVK ' -replace 'Vergi Usul K(anunu|\.)?|\b213\s*s(ayılı|\.)?\s*(K\.|Kanun)?','VUK ' -replace 'Gelir Vergisi K(anunu|\.)?|\b193\s*s(ayılı|\.)?\s*(K\.|Kanun)?','GVK ' -replace 'Türk Ticaret K(anunu|\.)?|\b6102\s*s(ayılı|\.)?\s*(K\.|Kanun)?','TTK ' -replace 'Türk Borçlar K(anunu|\.)?|\b6098\s*s(ayılı|\.)?\s*(K\.|Kanun)?','TBK ' -replace '\b4857\s*s(ayılı|\.)?\s*(İş\s*K\.|İş Kanunu|K\.|Kanun)?|\bİş K(anunu|\.)','ISK ' -replace '\b5510\s*s(ayılı|\.)?\s*(K\.|Kanun|SGK Kanunu)?','SGK ' -replace '\b3568\s*s(ayılı|\.)?\s*(K\.|Kanun)?','SMMM '
  # ⬇ 11.09: eksik kanunlar. KVK ONCE gelir - ciplak "KVK" eski tabloda
  #    TEBLIG'e ('KVK GUT') gidiyordu; kanun maddesi isteyen soru teblig aliyordu.
  $t=$t -replace '\bKVK\s*\(5520[^)]*\)|Kurumlar Vergisi K(anunu|\.)?|\b5520\s*s(ayılı|\.)?\s*(K\.|Kanun)?','KVKK '
  $t=$t -replace 'Sendikalar ve Toplu [İi]ş Sözleşmesi K(anunu|\.)?|\b6356\s*s(ayılı|\.)?\s*(K\.|Kanun)?','SENK ' `
        -replace '[İi]dari Yarg[ıi]lama Usul[uü] K(anunu|\.)?|\b[İi]YUK\b|\b2577\s*s(ayılı|\.)?\s*(K\.|Kanun)?','IYUK ' `
        -replace 'Amme Alacaklar[ıi]n[ıi]n Tahsil Usul[uü] Hakk[ıi]nda K(anunu|\.)?|\bAATUHK\b|\b6183\s*s(ayılı|\.)?\s*(K\.|Kanun)?','AATU ' `
        -replace 'Katma De[gğ]er Vergisi K(anunu|\.)?|\bKDVK\b|\b3065\s*s(ayılı|\.)?\s*(K\.|Kanun)?','KDVK ' `
        -replace 'Damga Vergisi K(anunu|\.)?|\b488\s*s(ayılı|\.)?\s*(K\.|Kanun)?','DAMGA ' `
        -replace '[İi]ş Sa[gğ]l[ıi][gğ][ıi] ve G[uü]venli[gğ]i K(anunu|\.)?|\b6331\s*s(ayılı|\.)?\s*(K\.|Kanun)?','ISGK ' `
        -replace '[İi]cra ve [İi]flas K(anunu|\.)?|\b2004\s*s(ayılı|\.)?\s*(K\.|Kanun)?','IIK ' `
        -replace '[İi]şsizlik Sigortas[ıi] K(anunu|\.)?|\b4447\s*s(ayılı|\.)?\s*(K\.|Kanun)?','ISSIZ ' `
        -replace 'Bankac[ıi]l[ıi]k K(anunu|\.)?|\b5411\s*s(ayılı|\.)?\s*(K\.|Kanun)?','BANK ' `
        -replace 'Emlak Vergisi K(anunu|\.)?|\b1319\s*s(ayılı|\.)?\s*(K\.|Kanun)?','EMLAK ' `
        -replace 'Motorlu Ta[sş][ıi]tlar Vergisi K(anunu|\.)?|\bMTV\b|\b197\s*s(ayılı|\.)?\s*(K\.|Kanun)?','MTVK ' `
        -replace 'T[uü]rk Medeni K(anunu|\.)?|\bTMK\b|\b4721\s*s(ayılı|\.)?\s*(K\.|Kanun)?','TMKK ' `
        -replace '[ÖO]zel T[uü]ketim Vergisi K(anunu|\.)?|\b[ÖO]TV K\b|\b4760\s*s(ayılı|\.)?\s*(K\.|Kanun)?','OTVK ' `
        -replace 'Kamu Mal[iî] Y[oö]netimi[^,;.]{0,20}K(anunu|\.)?|\b5018\s*s(ayılı|\.)?\s*(K\.|Kanun)?','KMYK ' `
        -replace 'Sigortac[ıi]l[ıi]k K(anunu|\.)?|\b5684\s*s(ayılı|\.)?\s*(K\.|Kanun)?','SIGK ' `
        -replace 'Gider Vergileri K(anunu|\.)?|\b6802\s*s(ayılı|\.)?\s*(K\.|Kanun)?','GIDERV ' `
        -replace 'Veraset ve [İi]ntikal Vergisi K(anunu|\.)?|\b7338\s*s(ayılı|\.)?\s*(K\.|Kanun)?','VIVK ' `
        -replace 'Har[cç]lar K(anunu|\.)?|\b492\s*s(ayılı|\.)?\s*(K\.|Kanun)?','HARC ' -replace 'Kurumsal Y[oö]netim Tebli[gğ]i?\s*(\(II-17\.1\))?','KYT ' -replace '\bPay Tebli[gğ]i?\s*(\(VII-128\.1\))?','PAYT ' -replace 'Yat[ıi]r[ıi]m Fonlar[ıi]na [İi]li[sş]kin Esaslar Tebli[gğ]i?\s*(\(III-52\.1\))?','FONT ' -replace '(SMMM ve YMM K(anunu)?\.?\s*)?Disiplin Y[oö]netmeli[gğ]i','DISY ' -replace 'Haks[ıi]z Rekabet ve Reklam Yasa[gğ][ıi] Y[oö]netmeli[gğ]i','HRRY ' -replace '(TÜRMOB\s*)?(Mesleki Faaliyetlerde\s*)?Etik [İi]lkeler( Hakk[ıi]nda)? Y[oö]netmeli[gğ]i?(\s*EK)?','ETIKY ' -replace '(SMMM\s*)?Staj Y[oö]netmeli[gğ]i','STAJY '
  # 09.09 Meslek Hukuku ÖLÇÜLDÜ (kolay 12 · zor 7 · çok zor 8 yayın / 29 konu; hakem "kaynakta yok" %25–37): model "Disiplin Yönetmeliği m.6/c",
  # "Haksız Rekabet ve Reklam Yasağı Yönetmeliği m.14, m.32" anıyor, ambarda maddeler var ("SMMM ve YMM K. Disiplin Yonetmeligi m.6"), ama atıf
  # genişletme yalnız kanun kısaltmalarını tanıyordu → yönetmelik maddeleri pakete girmiyordu. Dört yönetmelik kısaltma tablosuna eklendi.
  $KANUN2=@{}; foreach($k in $KANUN.Keys){ $KANUN2[$k]=$KANUN[$k] }
  $KANUN2['DISY']='SMMM ve YMM K. Disiplin Yonetmeligi'; $KANUN2['HRRY']='Haksız Rekabet ve Reklam Yasağı Yön.'; $KANUN2['ETIKY']='TÜRMOB Etik İlkeler Yön.'; $KANUN2['STAJY']='SMMM Staj Yonetmeligi'
  $KANUN2['ISK']='İş K. (4857 s.K.)';
  $KANUN2['SENK']='Sendikalar ve TİS K. (6356 s.K.)'; $KANUN2['IYUK']='İYUK (2577 s.K.)'
  $KANUN2['AATU']='AATUHK (6183 s.K.)'; $KANUN2['KDVK']='KDVK (3065 s.K.)'
  $KANUN2['DAMGA']='Damga V.K. (488 s.K.)'; $KANUN2['KVKK']='KVK (5520 s.K.)'
  $KANUN2['ISGK']='İSG K. (6331 s.K.)'; $KANUN2['IIK']='İİK (2004 s.K.)'
  $KANUN2['ISSIZ']='4447 s. İşsizlik Sig. K.'; $KANUN2['BANK']='Bankacılık K. (5411 s.K.)'
  # ⬇ 11.09 ikinci tur: DERS_KANUN'da olup ATIF tablosunda OLMAYAN 8 kanun.
  #    Hepsi ambarda VAR (adlar birebir dogrulandi). 492 Harclar K. ambarda YOK -
  #    o gercek yutma is emri, buraya yazilmadi.
  $KANUN2['EMLAK']='Emlak V.K. (1319 s.K.)'; $KANUN2['MTVK']='MTV K. (197 s.K.)'
  $KANUN2['TMKK']='TMK (4721 s.K.)'; $KANUN2['OTVK']='ÖTV K. (4760 s.K.)'
  $KANUN2['KMYK']='Kamu Malî Yönetimi K. (5018 s.K.)'; $KANUN2['SIGK']='Sigortacılık K. (5684 s.K.)'
  $KANUN2['GIDERV']='Gider Vergileri K. (6802 s.K.)'; $KANUN2['VIVK']='Veraset ve İntikal V.K. (7338 s.K.)'
  $KANUN2['HARC']='Harçlar K. (492 s.K.)'
  $KANUN2['KYT']='Kurumsal Yonetim Tebligi (II-17.1)'; $KANUN2['PAYT']='Pay Tebligi (VII-128.1)'; $KANUN2['FONT']='Yatirim Fonlarina Iliskin Esaslar Tebligi (III-52.1)'
  # 08.09 Tur 1 Denetim ÖLÇÜLDÜ (dayanak-dusus-olcum: 161 sorunun 31'i "kaynakta yok"): model "BDS 200 p.12" yazıyor, desen "BDS 200 p.%"
  # standardın p.1'den başlayan İLK parçalarını çekiyor, 7.000 tavanı p.12'ye gelmeden doluyordu → hakem "paket yalnız p.0–6" diye reddediyordu.
  # Artık anılan PARAGRAF numaraları önce ("p.12", "p.A96", "paragraf 5", "p.15, A21"), genel p.% en sona yedek. Ek/UR paragrafları bazı
  # standartlarda "p.A96", bazılarında (bds220) çift "p.96" olarak yutulmuş → A'lı atıfta iki biçim de aranır.
  $stdM=[regex]::Matches($t,'(TMS|TFRS|BDS|GDS|TSRS|SBDS|KYS)\s*(\d+)')
  for($si=0;$si -lt $stdM.Count;$si++){
    $sm=$stdM[$si]; $stdAd="$($sm.Groups[1].Value) $($sm.Groups[2].Value)"
    $segBas=$sm.Index+$sm.Length; $segBit=$(if($si+1 -lt $stdM.Count){ $stdM[$si+1].Index } else { $t.Length })
    $seg=$t.Substring($segBas,$segBit-$segBas)
    $parNo=New-Object System.Collections.Generic.List[string]
    foreach($pm in [regex]::Matches($seg,'(?:\bp\.|\bparagraf\s*|\bpar\.\s*|\bprg\.\s*)\s*(A?\d+)(?![\d.]\d)')){ if($parNo -notcontains $pm.Groups[1].Value){ $parNo.Add($pm.Groups[1].Value) } }
    if($parNo.Count){ foreach($pm in [regex]::Matches($seg,'(?<=\b(?:p\.|paragraf\s*)A?\d+(?:\([a-z]\))?(?:,\s*(?:p\.)?A?\d+(?:\([a-z]\))?)*,\s*(?:p\.)?)(A?\d+)(?![\d.]\d)')){ if($parNo -notcontains $pm.Groups[1].Value){ $parNo.Add($pm.Groups[1].Value) } } }
    foreach($pn in $parNo){
      $d.Add("$stdAd p.$pn"); $d.Add("$stdAd p.$pn %")
      if($pn -match '^A(\d+)$'){ $d.Add("$stdAd p.$($matches[1])"); $d.Add("$stdAd p.$($matches[1]) %") }
    }
    $d.Add("$stdAd p.%")
  }
  foreach($m in [regex]::Matches($t,'THP\s*(\d{3})')){ $d.Add("THP $($m.Groups[1].Value)%") }
  # "GVK m.6 - ...; m.3 - ...; m.2" : kanun adi bir kez gecer, sonraki m.'ler ayni kanuna aittir
  $son=''
  foreach($m in [regex]::Matches($t,'(?:\b(VUK|TTK|TBK|GVK|KVKK|KVK|SPK|SGK|SMMM|ISK|SENK|IYUK|AATU|KDVK|DAMGA|ISGK|IIK|ISSIZ|BANK|EMLAK|MTVK|TMKK|OTVK|KMYK|SIGK|GIDERV|VIVK|HARC|KYT|PAYT|FONT|DISY|HRRY|ETIKY|STAJY)\b[^m;]*)?\bm(?:adde)?\.?\s*(\d+)(?:/([A-Z0-9]))?')){
    if($m.Groups[1].Success){ $son=$m.Groups[1].Value }
    if(-not $son -or -not $KANUN2.ContainsKey($son) -or $KANUN2[$son] -match '%$'){ continue }
    $ek=if($m.Groups[3].Success){ "/$($m.Groups[3].Value)" } else { '' }
    # 'm.6%' m.61/m.62'yi de yakalar; ad ya tam 'm.6' ya 'm.6 ' ile devam eder -> iki desen
    $d.Add("$($KANUN2[$son]) m.$($m.Groups[2].Value)$ek"); $d.Add("$($KANUN2[$son]) m.$($m.Groups[2].Value)$ek %")
    if($d.Count -ge 10){ break }
  }
  return @($d | Select-Object -Unique)
}
# 03.09 (bosluk partisi olcumu): dayanagi HIC olmayan konu (bizde yok, kopru dayanak yazamamis)
# icin dersin ANA KANUNU icinde metin aramasi. Ders profil adi ($DersRegex) -> kanun onek(ler)i.
$DERS_KANUN=@{
  'Ticaret Hukuku'=@('TTK (6102 s.K.)'); 'Borclar Hukuku'=@('TBK (6098 s.K.)')
  # 07.09 parti30 OLCULDU: 6356 listede yoktu -> 'sendika uyeligi' sorusunda kaynak Is K. m.5/7'ye dustu, hakem reddetti. Adlar ambardan birebir.
  'Is ve Sosyal Guvenlik Hukuku'=@('İş K. (4857 s.K.)','5510 s. SGK Kanunu','Sendikalar ve TİS K. (6356 s.K.)','İSG K. (6331 s.K.)','4447 s. İşsizlik Sig. K.')
  # 07.09 parti30 OLCULDU: 'KVK (5520 s.K.)' listede YOKTU -> kurumlar vergisi dayanagi "ders disi kanun" sayildi,
  # kaynak capadan 5510 SGK + IYUK'a dustu, hakem 2 soruyu reddetti (vergi 4 -> 1). Kanun listede, teblig yaninda.
  'Vergi Hukuku'=@('VUK (213 s.K.)','GVK (193 s.K.)','KVK (5520 s.K.)','KVK GUT (1 Seri No)','KDVK (3065 s.K.)','Damga V.K. (488 s.K.)','AATUHK (6183 s.K.)','İİK (2004 s.K.)',
                   'ÖTV K. (4760 s.K.)','MTV K. (197 s.K.)','Harçlar K. (492 s.K.)','Emlak V.K. (1319 s.K.)','Veraset ve İntikal V.K. (7338 s.K.)','Gider Vergileri K. (6802 s.K.)')   # adlar AMBAR-ENVANTERI'nden birebir (07.09)
  # 07.09 parti30 OLCULDU: Meslek listesinde yalniz 3568 vardi -> 'haksiz rekabet reklam yasagi' TTK m.55'e, 'meslek etik
  # ilkeleri' TSPB genelgesine dustu (hakem HAYIR). Meslek yonetmelikleri ambarda VAR, adlar AMBAR-ENVANTERI'nden birebir.
  'Meslek Hukuku'=@('SMMM K. (3568 s.K.)','Haksız Rekabet ve Reklam Yasağı Yön.','TÜRMOB Etik İlkeler Yön.','TÜRMOB Etik İlkeler Yön. EK','SMMM ve YMM K. Disiplin Yonetmeligi','SMMM Staj Yonetmeligi')
  # 08.09 Tur 1 FMuh kolay ölçümü: 56 hakem reddinin 52'si "kaynak paketi kuralı içermiyor" — köprü FMuh konularına alakasız VUK maddeleri
  # (ücret bordrosu → VUK inceleme yasakları, sermaye artırımı → VUK m.5) çekiyordu. Muhasebe tekniği TEORİ notları (teori-notlari-20260908-sgs-fmuh-*.json)
  # kaynak listesinin başına: hakem kuralı notta görür, VUK yalnız değerleme/amortisman/envanter konularında öne geçer ($KELIME_KANUN).
  'Finansal Muhasebe'=@('TEORI','Teori Notu','THP','VUK (213 s.K.)')
  # 08.09 Cem "SGS'de dışladığımız 6 dersi kuralım": mevzuat metni olmayan dersler → kaynak TEORİ NOTU (motor/teori-notu-uret.ps1; ambar 'TEORI - <konu>')
  'Turkce'=@('TEORI','Teori Notu'); 'Matematik'=@('TEORI','Teori Notu'); 'Yabanci Dil'=@('TEORI','Teori Notu'); 'Ataturk Ilke'=@('TEORI','Teori Notu')
  'Ekonomi'=@('TEORI','Teori Notu'); 'Maliye'=@('TEORI','Teori Notu','Kamu Malî Yönetimi K. (5018 s.K.)')
  # 08.09 Tur 1 Denetim ölçümü: hakem reddinin bir kısmı BDS metninde olmayan ders kitabı kavramı (denetim hedefleri/yönetim beyanları, risk modeli çarpımı, denetim türleri) → TEORI notları yedek kaynak
  # 09.09 00:48 MTA kolay ÖLÇÜLDÜ: 32 konu → 19 soru → 9 yayın; kaynak borcu 9 (cari oran/asit-test, çalışma sermayesi, F/K). SGS ders adı 'Mali Tablolar Analizi'
  # listede YOKTU (yalnız SMMM 'Finansal Tablolar ve Analizi' vardı) → ders kanunu/teori araması hiç çalışmadı. Ambarda 21 oran + 8 dikey + 5 likidite notu var.
  'Mali Tablolar Analizi'=@('TEORI','Teori Notu','TMS','THP')
  # 09.09 GM yazımı ÖLÇÜLDÜ: Tur 1 maliyet-kolay 28 konunun 12'si kaynak borcu; ambarda 20+ maliyet TEORİ notu (sapmalar, kademeli/matematiksel dağıtım, eşdeğer birim,
  # normal/değişken maliyet, FTM) var ama listede TEORI yoktu → hiç çekilmiyordu. Not adı konu köküyle eşleşerek çekilir ('~teori', metin araması yok); MSUGT 2 ve THP kalır.
  'Denetim'=@('BDS','TEORI','Teori Notu'); 'Maliyet Muhasebesi'=@('TEORI','Teori Notu','MUHASEBE SISTEMI UYGULAMA GENEL TEBLIGI (SIRA NO: 2)','THP')   # 07.09 K6 (Cem evet): maliyet TEKNİĞİNİN kaynağı MSUGT Sıra No 2 (ambarda bölüm 10–14), hakem artık VUK 275'e yaslanmaz
  # KGK (03.09, Cem "KGK icin agir bosluk partisine basla") - ambar adlari canli olculdu
  'Türkiye Muhasebe Standartları'=@('TMS','TFRS','THP','VUK (213 s.K.)')
  'Türkiye Denetim Standartları'=@('BDS','KYS')
  # 03.09 06:30 OLCULDU (50 sorunun 23'u hakem reddi, 19'unda ilk kaynak Teblig): Teblig her konuda
  # one geciyordu, finans teorisi (eldeki kus, geri odeme, portfoy) TEORI notuna hic ulasamiyordu.
  # Sira: once teori notlari, sonra Teblig, TTK, TBK (genel hukuk konulari da bu derse dusuyor).
  'Kurumsal Yönetim İlkeleri ve Finansal Yönetim'=@('TEORI','Teori Notu','Kurumsal Yonetim Tebligi (II-17.1)','TTK (6102 s.K.)','TBK (6098 s.K.)')
  # 03.09 OLCULDU (SMMM SPK 'pay turleri' / 'semsiye fon turleri' KAPI-A reddi): Pay Tebligi ve
  # Yatirim Fonlari Tebligi ambarda var ama listede yoktu; konu kelimesi ($KELIME_KANUN) one alir.
  'Sermaye Piyasası Mevzuatı'=@('Sermaye Piyasası K. (6362 s.K.)','Pay Tebligi (VII-128.1)','Yatirim Fonlarina Iliskin Esaslar Tebligi (III-52.1)','Kurumsal Yonetim Tebligi (II-17.1)','TTK (6102 s.K.)')
  'Bankacılık Mevzuatı'=@('Bankacılık K. (5411 s.K.)')
  'Sigortacılık ve Özel Emeklilik Mevzuatı'=@('Sigortacılık K. (5684 s.K.)','Sigortacilik Tekduzen','TTK (6102 s.K.)')
  'Kurumsal Sürdürülebilirlik Raporlaması'=@('TSRS')
  'Sürdürülebilirlik Denetimi'=@('GDS','SBDS','TSRS')
  # SMMM Yeterlilik (03.09, Cem "bitince SMMM icin de kos")
  'Hukuk'=@('TTK (6102 s.K.)','TBK (6098 s.K.)','İş K. (4857 s.K.)','5510 s. SGK Kanunu','İYUK (2577 s.K.)')
  'Muhasebe Denetimi'=@('BDS','KYS','Bagimsiz Denetim Yonetmeligi')
  'Vergi Mevzuatı ve Uygulaması'=@('VUK (213 s.K.)','GVK (193 s.K.)','KVK GUT (1 Seri No)','KDVK (3065 s.K.)','AATUHK (6183 s.K.)')
  'Finansal Tablolar ve Analizi'=@('TEORI','Teori Notu','TMS')
  'Muhasebecilik ve Mali Müşavirlik Meslek Hukuku'=@('SMMM K. (3568 s.K.)')
  # SPL / SPK LISANSLAMA (03.09, Cem "SPK sinavlarinda hazirlik yaptiracagiz, 7 ders yakin sinav var")
  # Ambar adlari canli olculdu: "Sermaye Piyasası K. (6362 s.K.) m.N", "<Ad> Tebligi (II-23.2) m.N",
  # "SPK Tebliğ (II-15.2) - ...", "SPK Rehber - ...", "SPK Diğer Karar - ...". '%' ile baslayan onek = icerir.
  'Dar Kapsamlı Sermaye Piyasası Mevzuatı'=@('Sermaye Piyasası K. (6362 s.K.)','%Tebligi (','SPK Tebliğ','SPK Rehber','TSPB')
  'Geniş Kapsamlı Sermaye Piyasası Mevzuatı'=@('Sermaye Piyasası K. (6362 s.K.)','%Tebligi (','SPK Tebliğ','SPK Rehber','SPK Diğer Karar','TSPB')
  'Sermaye Piyasası Araçları'=@('Sermaye Piyasası K. (6362 s.K.)','%Tebligi (','SPK Tebliğ','TTK (6102 s.K.)','TEORI','Teori Notu')
  'Yatırım Kuruluşları'=@('%Tebligi (','SPK Tebliğ','Sermaye Piyasası K. (6362 s.K.)','SPK Rehber')
  'Takas, Saklama ve Operasyon İşlemleri'=@('%Tebligi (','SPK Tebliğ','SPK Rehber','SPK Diğer Karar','Sermaye Piyasası K. (6362 s.K.)')
  'Finansal Piyasalar'=@('TEORI','Teori Notu','Sermaye Piyasası K. (6362 s.K.)','%Tebligi (','Bankacılık K. (5411 s.K.)')
  'Türev Araçlar, Piyasalar ve Risk Yönetimi'=@('TEORI','Teori Notu','%Tebligi (','SPK Tebliğ')
  'Kurumlarda ve Sermaye Piyasasında Vergilendirme'=@('GVK (193 s.K.)','KVK GUT (1 Seri No)','KDVK (3065 s.K.)','VUK (213 s.K.)','Damga V.K. (488 s.K.)')
  'Finansal Yönetim ve Mali Analiz'=@('TEORI','Teori Notu')
  'Genel Ekonomi'=@('TEORI','Teori Notu')
  'Temel Finans Matematiği ve Değerleme Yöntemleri'=@('TEORI','Teori Notu')
  'Muhasebe ve Finansal Raporlama'=@('TMS','TFRS','THP','TEORI')
  'Kurumsal Yönetim'=@('Kurumsal Yonetim Tebligi (II-17.1)','TTK (6102 s.K.)','TEORI','Teori Notu')
  'Kredi Derecelendirmesi'=@('%Derecelendirme%','SPK Tebliğ','TEORI','Teori Notu')
  'Gayrimenkul'=@('%Gayrimenkul%','TMK (4721 s.K.)','%Tebligi (','SPK Tebliğ')
  'Bilgi Sistemleri'=@('%Bilgi Sistemleri%','%Tebligi (','SPK Tebliğ')
}
# --- MULGA / YENIDEN ADLANDIRILMIS STANDART ESLEMESI (02.09, olcumle bulundu)
# Cem "yut onlari" dedi; olculdu ki YUTULACAK BIR SEY YOK - ucu de ambarda mevcut,
# yalnizca ADLARI degismis ya da YERLERINE yeni standart gelmis:
#   KKS 1  -> KYS 1  (2022: Kalite KONTROL Std. yerine Kalite YONETIM Std.; ambarda 107 parca)
#   TMS 11 -> TFRS 15 (2018: Insaat Sozlesmeleri, Hasilat'a devroldu; ambarda 239 parca)
#   TFRS 4 -> TFRS 17 (2023: Sigorta Sozlesmeleri; ambarda 259 parca)
# Mulga metni yutmak YANLIS olurdu: ogrenciye yururlukten kalkmis kural ogretirdik.
$STANDART_HALEF=@{
  'KKS 1'='KYS 1'; 'KKS1'='KYS 1'
  'TMS 11'='TFRS 15'; 'TMS11'='TFRS 15'
  'TFRS 4'='TFRS 17'; 'TFRS4'='TFRS 17'
}
function HalefStandart([string]$ad){
  $t=($ad -replace '\s+',' ').Trim()
  foreach($eski in $STANDART_HALEF.Keys){
    if($t -match ('(?i)\b'+[regex]::Escape($eski)+'\b')){ return $STANDART_HALEF[$eski] }
  }
  return ''
}
# 08.09 Tur 1 Vergi kolay ÖLÇÜLDÜ (KVK konuları KAYNAK BORCU): ders adı "Vergi Hukuku" DERS_KANUN'da hem 'Vergi Hukuku' hem de SMMM
# yeterlilik anahtarı 'Hukuk' ile eşleşiyordu ('-match' alt dize); 'Hukuk' listesi (TTK, TBK, İş K., 5510, İYUK) 10 desen üretip AmbarCek'in
# 10 kaynak kotasını dolduruyor, KVK/GVK/KDVK'ya sıra gelmiyordu (03.09'daki "damga vergisi → 5510 SGK affı" da buydu). Ticaret/Borçlar/Meslek
# Hukuku da 'Hukuk'a takılıyordu. Kural: DersRegex'in bir parçasına BİREBİR eşit anahtar varsa yalnız o; yoksa eşleşen EN UZUN anahtar.
function DersKanunAnahtari([string]$dersAdi){
  $parcalar=@(($dersAdi -replace '[\^\$\\]','') -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  $tam=@($DERS_KANUN.Keys | Where-Object { $k=$_; @($parcalar | Where-Object { $_ -eq $k }).Count })
  if($tam.Count){ return @($tam) }
  $es=@($DERS_KANUN.Keys | Where-Object { $k=$_; @($parcalar | Where-Object { $_ -match [regex]::Escape($k) }).Count } | Sort-Object { -$_.Length })
  if($es.Count){ return @($es[0]) }
  return @()
}
function DesenUret($kayit){
  $d=New-Object System.Collections.Generic.List[string]
  # 03.09 SPL Duzey 1 olcumu (4 ret): konu adi TEBLIG KODU tasiyor ("... tebliğ iii-45.1") ve o Teblig
  # ambarda VAR ("... Tebligi (III-45.1) m.1", 46 madde) ama aranmiyordu; uretici SPKn m.3'e kayiyor,
  # KAPI D konu-disi diyordu. Kod -> '%(III-45.1)%' ad deseni EN ONE. TSPB kurallari adiyla; Teblig/
  # Yonetmelik adli konular icin ilk uc ozgul kelimeyle Turkce toleransli ad aramasi ('~' = imatch).
  # 03.09 ikinci olcum (1005 kp-03/05 hala SPKn m.3): kod deseni listeye ILK eklenmisti ama ders-kanun
  # '@' desenleri sonradan InsertRange(0) ile ONUNE geciyor, AmbarCek 10 kaynakta duruyor -> Teblig hic
  # cekilmiyordu. Kod desenleri AYRI listede toplanir ve EN SONDA basa konur. Teblig icinde konu
  # kokuyle metin aramasi da eklenir ('@%(KOD)%|kok') ki m.1-3 (amac/kapsam/tanim) yerine esas madde gelsin.
  $kodOne=New-Object System.Collections.Generic.List[string]
  $konuKat0=(Katla2 "$($kayit.konu)")
  $TEBLIG_BOS='^(hakkinda|iliskin|esaslar|esaslari|esaslarina|genel|tebligi|teblig|yonetmelik|yonetmeligi|anonim|sirketi|bolumler|kurulmasina|tarafindan|kullanilacak|yontemlerine|ortamda|sermaye|piyasasi|piyasalari|ve|ile)$'
  foreach($src in @("$($kayit.konu)","$($kayit.dayanak)","$($kayit.cikmis_dayanak)")){
    foreach($m in [regex]::Matches($src,'(?i)\b([IVX]{1,4})\s*-\s*(\d{1,3}(?:\.\d+)?(?:/[A-Za-z]\.?\d*)?)')){
      $kod=($m.Groups[1].Value.ToUpperInvariant()+'-'+$m.Groups[2].Value.ToUpperInvariant())
      $kokler=@(($konuKat0 -replace '\(.*?\)','' -replace '[ivx]+-[\d./a-z]+','' -split '\s+') | Where-Object { $_.Length -ge 5 -and $_ -notmatch $TEBLIG_BOS } | Select-Object -First 2 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
      foreach($kk in $kokler){ $kodOne.Add("@%($kod)%|$kk") }
      $kodOne.Add("%($kod)%")
    }
  }
  # 09.09 Meslek Hukuku ÖLÇÜLDÜ: bu iki TSPB deseni SPK dersi için yazılmıştı ama HER derste çalışıyordu → SGS Meslek "etik ilkeler tehditleri"
  # sorularına TSPB Sermaye Piyasası Çalışanları Etik Kuralları ve SPK Tebliği (VII-128.7) çekildi, hakem HAYIR. Yalnız sermaye piyasası derslerinde.
  if($DersRegex -match 'Sermaye|SPK|Dar Kapsam|Geni[sş] Kapsam'){
    if($konuKat0 -match 'etik ilke|davranis kural'){ $kodOne.Add('TSPB Sermaye Piyasasi Calisanlari Etik%') }
    if($konuKat0 -match 'meslek kural'){ $kodOne.Add('TSPB Uyelerinin%Meslek Kurallari%') }
  }
  if($kodOne.Count -eq 0 -and $konuKat0 -match 'yonetmeli|teblig|genelge|rehber|ilke'){
    $adKel=@(($konuKat0 -replace '\(.*?\)','' -split '\s+') | Where-Object { $_.Length -ge 5 -and $_ -notmatch $TEBLIG_BOS } | Select-Object -First 3 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
    if($adKel.Count -ge 2){ $kodOne.Add('~'+($adKel -join ' ')) }
  }
  # halef standart varsa ONCE onun desenini koy (mulga ad ambarda hic yok)
  foreach($ham in @("$($kayit.dayanak)","$($kayit.cikmis_dayanak)","$($kayit.konu)")){
    $halef=HalefStandart $ham
    if($halef){ $d.Add("$halef p.%"); break }
  }
  # 09.09 genel kültür pilotu ÖLÇÜLDÜ: "fiil zamani (past tense)" (Yabancı Dil) sorusunun kaynak paketine köprü dayanağı yüzünden
  # VUK m.30 / m.73 girdi, hakem "kaynak vergi teorisi" diyerek reddetti. Dersin kaynak listesi YALNIZ teori notuysa (genel kültür 6 ders)
  # köprünün kanun dayanağı YOK SAYILIR: bu derslerin mevzuat kaynağı yoktur, kaynak yalnız TEORİ NOTUdur.
  $teoriDers=$false
  foreach($dk0 in (DersKanunAnahtari ($DersRegex -replace '[\^\$\\]',''))){ $lst=@($DERS_KANUN[$dk0]); if($lst.Count -and -not @($lst | Where-Object { $_ -notmatch '^(TEORI|Teori Notu)$' }).Count){ $teoriDers=$true } }
  foreach($ham in @($(if($teoriDers){ @() } else { @("$($kayit.dayanak)","$($kayit.cikmis_dayanak)") }))){
    if(-not $ham){ continue }
    # 02.09: kara listedeki dayanak DESEN URETIMINE GIRMEZ - olculdu ki konularin
    # cogunlugu o maddeyle ilgisiz (TTK m.720 %80, SMMM K. m.29 %70 yanlis).
    # Boyle bir konu dayanaksiz sayilir ve asagidaki kok-joker yoluyla ambarda
    # KONU ADIYLA aranir; bulunamazsa kaynak borcu olarak raporlanir.
    if(KaraMi $ham){ continue }
    foreach($m in [regex]::Matches($ham,'(TMS|TFRS|BDS|GDS|TSRS|SBDS)\s*(\d+)')){ $d.Add("$($m.Groups[1].Value) $($m.Groups[2].Value) p.%") }
    foreach($m in [regex]::Matches($ham,'THP\s*(\d{3})')){ $d.Add("THP $($m.Groups[1].Value)%") }
    foreach($m in [regex]::Matches($ham,'(VUK|TTK|TBK|GVK|SMMM)[^m]*m\.?\s*(\d+)(?:\s*[-–]\s*(\d+))?')){
      $ka=$KANUN[$m.Groups[1].Value]; $n1=[int]$m.Groups[2].Value
      $n2=if($m.Groups[3].Success){[int]$m.Groups[3].Value}else{$n1}
      if($n2-$n1 -gt 8){ $n2=$n1+8 }
      for($n=$n1;$n -le $n2;$n++){ $d.Add("$ka m.$n%") }
    }
    # 03.09 OLCULDU (SGS Is-SGK 'is sozlesmesi feshi' -> KAYNAK BORCU; oysa 'İş K. (4857 s.K.) m.11'
    # ambarda): yukaridaki madde deseni yalniz VUK/TTK/TBK/GVK/SMMM taniyordu; Is K., 5510, SPKn,
    # 3568 maddeli dayanaklar hic aranmiyordu. Kanun no ile onek bulunur, madde iki bicimde aranir
    # ('m.11' tam / 'm.11 ' devam) ki m.110-111 karismasin.
    if($ham -notmatch '\b(VUK|TTK|TBK|GVK|SMMM)\b' -and $ham -match '\bm(?:adde)?\.?\s*(\d+)'){
      $onekM=''
      if($ham -match '4857|İş K'){ $onekM='İş K. (4857 s.K.)' }
      elseif($ham -match '5510'){ $onekM='5510 s. SGK Kanunu' }
      elseif($ham -match '3568'){ $onekM='SMMM K. (3568 s.K.)' }
      elseif($ham -match '6362|Sermaye Piyasas|SPKn|\bSPK\b'){ $onekM='Sermaye Piyasası K. (6362 s.K.)' }
      elseif($ham -match '6183|AATUHK'){ $onekM='AATUHK (6183 s.K.)' }
      elseif($ham -match '3065|KDVK|Katma Değer|KDV Kanunu|\bKDV\b'){ $onekM='KDVK (3065 s.K.)' }   # 07.09 Ö48: köprü "KDV Kanunu m.10" yazıyor, ambar "KDVK (3065 s.K.) m.10" (170 kayıt) → kaynak borcu sahteydi
      elseif($ham -match '6356|STİSK|STISK|Sendikalar ve Toplu'){ $onekM='Sendikalar ve TİS K. (6356 s.K.)' }   # 07.09 Ö48: 6356 ambarda VAR (102 madde), köprü uzun adla/STİSK ile yazıyordu
      elseif($ham -match '\b488\b|Damga'){ $onekM='Damga V.K. (488 s.K.)' }
      if($onekM){ foreach($m in [regex]::Matches($ham,'\bm(?:adde)?\.?\s*(\d+)')){ $nM=$m.Groups[1].Value; $d.Add("$onekM m.$nM"); $d.Add("$onekM m.$nM %"); if($d.Count -ge 8){ break } } }
    }
  }
  if($d.Count -eq 0){
    # teori/eslesmemis: konu adiyla ad-aramasi. 01.09 dersi (7. ek-tuzagi vakasi):
    # 'tahakkuku' ambardaki 'TAHAKKUKLARI' ile eslesmiyordu - kelime KOKUNE inilir
    # (>=6 harfli kelimenin son 2 harfi atilir, joker girer).
    $kel=@(("$($kayit.konu)" -split '\s+') | Where-Object { $_.Length -ge 4 } | Select-Object -First 2 | ForEach-Object { if($_.Length -ge 6){ $_.Substring(0,$_.Length-2) } else { $_ } })
    if($kel.Count -ge 1){ $d.Add('%'+($kel -join '%')+'%') }
  }
  # 02.09 gece OLCULDU (KGK Kurumsal Yon.+Fin. Yon. partisi, 22 "kaynak borcu"): ambarda
  # "Teori Notu - kaldirac ve basabas", "- risk getiri portfoy", "- sermaye butcelemesi
  # NPV IRR" gibi notlar VARDI ama bulunamadi. Iki sebep: (1) dayanak varsa (SPK Tebligi
  # gibi ambarda olmayan bir kunye) konu adiyla HIC aranmiyordu; (2) konu-ad deseni
  # kelimeleri SIRAYLA istiyordu ('%basabas%noktas%'), not adi baska sirada.
  # Cozum: HER konu icin teori notlarinda tek tek kelime araması da eklenir
  # (TEORI/Teori Notu onekli, >=5 harfli kokler). Kaynak metni yalniz ad ile bulunur;
  # metin icinde arama yok, dolayisiyla yanlis-pozitif sinirli; KAPI-A ve hakem yine siniyor.
  # 03.09 olcumu (cek hukuku -> TFRS 10 + Noterlik K.): 'hukuku', 'kanunu' gibi GENEL kokler her seyi
  # esliyor; stop listesi genisletildi. Kanun ici (@) arama icin 3-4 harfli ozgul kokler de alinir (cek, bono).
  $GENEL_KOK='^(hesabi|hesaplama|yontemi|yontem|teorisi|kavrami|kavram|ilkesi|ilkeler|degeri|suresi|araclari|sartlari|haklari|problemi|sistemi|tanimi|unsurlari|hukuku|hukuk|kanunu|kanun|mevzuat|standart|standardi|genel|temel|ozel|turleri|halleri|kurali|kurallari|islemi|islemleri|kaydi|kayitlari|analizi|hesaplari)$'
  # 09.09 GM pilotu ÖLÇÜLDÜ: "cari oran-asit test yorumlama" tire ile tek kelime sayıldı ("oran-asit" → regex 'oran.a[sş]'), not adı "Cari oran ve asit-test"
  # eşleşmedi, hakem TMS 1 p.64 ile "kaynak formülü içermiyor" dedi. Kökler tire ve bölü işaretinden de ayrılır.
  $teoriKok=@(("$($kayit.konu)" -split '[\s\-/]+') | Where-Object { $_.Length -ge 5 -and $_ -notmatch $GENEL_KOK } | Select-Object -First 3 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
  $kanunKok=@(("$($kayit.konu)" -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch $GENEL_KOK -and $_ -notmatch '^(ve|ile|icin|bir|bu|olan|dair)$' } | Select-Object -First 3 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
  # 03.09 OLCULDU (SMMM denetim partisi, 8 hakem reddi): TEK kok cok gevsek - 'sistem' ->
  # doviz kuru riski notu, 'sozlesme' -> sigorta zeyilname notu. Cem "1.2.3 yap" -> 3:
  # teori deseni EN AZ IKI kok ister (iki sirada da); tek kok yalniz konu tek kelimeyse.
  # 09.09 15:40 ÖLÇÜLDÜ (Cem "notları yaz"): Tur 1'de kaynak yüzünden düşen 68 FMuh konusunun 56'sının notu dün YAZILMIŞTI ve ambardaydı;
  # Tur 2'de yine aynı sebeple düştüler. Üç kusur: (1) 'TEORI%sermaye%artiri%' ilike deseni ASCII kök ile Türkçe adlı notu ("Sermaye artırımı",
  # "Ücret bordrosu", "Amortisman yöntemleri") BULAMIYOR — ölçüldü: ucret%bordro 0 sonuç, Ücret%bordro 1 sonuç. (2) Ad desenleri listenin ortasına
  # ekleniyor, '@' metin desenleri InsertRange(0) ile önüne geçiyor → doğru not paketin sonuna düşüp 9.000 kr tavanında KESİLİYOR (iç kontrol notu
  # 14.004. karakterde başlıyordu). (3) '@TEORI|kok' metin araması FMuh'ta rastgele not çekiyor (borç senedi yenileme → Senyoraj, Haliç Konferansı).
  # Çözüm: ad deseni Türkçe toleranslı imatch ('~teori kok kok' → "teori.*[sş]ermaye.*art[iı]r[iı]"), ayrı listede toplanır ve EN ÖNE konur.
  $teoriOne=New-Object System.Collections.Generic.List[string]
  # 09.09 GM maliyet ÖLÇÜLDÜ (kp-14 "standart maliyet direkt iscilik"): ikili desenler "maliyet+direkt" ile 6 alakasız not çekip 10 kaynak kotasını
  # doldurdu, "direkt+iscilik" deseni hiç sıra alamadı → doğru not paketin dışında kaldı, hakem HAYIR. ÜÇ kök birlikte (her sırayla) EN ÖNCE aranır.
  if($teoriKok.Count -ge 3){
    foreach($p3 in @(@(0,1,2),@(0,2,1),@(1,0,2),@(1,2,0),@(2,0,1),@(2,1,0))){ $teoriOne.Add("~teori $($teoriKok[$p3[0]]) $($teoriKok[$p3[1]]) $($teoriKok[$p3[2]])") }
  }
  if($teoriKok.Count -ge 2){
    for($i=0;$i -lt $teoriKok.Count;$i++){ for($j=0;$j -lt $teoriKok.Count;$j++){ if($i -eq $j){ continue }; $teoriOne.Add("~teori $($teoriKok[$i]) $($teoriKok[$j])") } }
  } elseif($teoriKok.Count -eq 1){ $teoriOne.Add("~teori $($teoriKok[0])") }
  # 03.09: kanun var, MADDE YOK ("TTK (6102 s.K.)", "5510 sayılı Kanun") -> o kanunun maddeleri
  # icinde konu kelimesiyle METIN aramasi (AmbarCek '@' deseni). Ilk iki kok ayri ayri denenir.
  foreach($ham in @("$($kayit.dayanak)","$($kayit.cikmis_dayanak)")){
    if(-not $ham -or $ham -match '\bm\.?\s*\d+'){ continue }
    $onek=''
    foreach($ks in @('VUK','TTK','TBK','GVK','KVK','SPK')){ if($ham -match ('\b'+$ks+'\b') -and $KANUN.ContainsKey($ks) -and $KANUN[$ks] -notmatch '%$'){ $onek=$KANUN[$ks]; break } }
    if(-not $onek -and $ham -match '5510'){ $onek='5510 s. SGK Kanunu' }
    if(-not $onek -and $ham -match '4857'){ $onek='İş K. (4857 s.K.)' }
    if(-not $onek -and $ham -match '3568'){ $onek='SMMM K. (3568 s.K.)' }
    if(-not $onek){ continue }
    foreach($tk in ($teoriKok | Select-Object -First 2)){ $d.Add("@$onek|$tk") }
    break
  }
  # 03.09 DENETIM olcumu (14 sorunun 6'si hakem reddi): '@BDS|kelime' aramasi rastgele BDS
  # paragrafi getiriyor (iliskili taraf -> BDS 501 stoklar; planlama -> BDS 200 kunye), model
  # dogru standardi (550, 300, 230) ANIYOR ama kaynakta yok -> red. Konu kelimesi -> standart
  # numarasi haritasi: dogru standardin paragraflari ONE alinir.
  $DENETIM_STD=@(
    @('iliskili taraf','BDS 550'),@('yonetim beyan','BDS 580'),@('yonetim iddia','BDS 315'),@('ic kontrol','BDS 315'),
    @('planlama','BDS 300'),@('belgelendir','BDS 230'),@('calisma kagit','BDS 230'),@('orneklem','BDS 530'),
    @('onemlilik','BDS 320'),@('kanit','BDS 500'),@('dis teyit|dogrulama','BDS 505'),@('acilis bakiye','BDS 510'),
    @('analitik','BDS 520'),@('tahmin','BDS 540'),@('bilanco sonrasi|sonraki olay','BDS 560'),@('sureklilik','BDS 570'),
    @('gorus|denetci raporu|rapor','BDS 700'),@('sartli|olumsuz|kacinma','BDS 705'),@('hile','BDS 240'),
    @('kalite','KYS 1'),@('denetim risk|tespit edememe|risk','BDS 200'),@('topluluk','BDS 600'),@('ic denetim','BDS 610'),
    @('uzman','BDS 620'),@('denetim sozlesme|sozlesme sart','BDS 210'),@('denetim sureci|bagimsiz denetim sureci','BDS 200')
  )
  $konuKat=(Katla2 "$($kayit.konu)")
  if($DersRegex -match 'Denetim|Denetim Standartlar' ){
    $stdOne=New-Object System.Collections.Generic.List[string]
    foreach($cift in $DENETIM_STD){ if($konuKat -match $cift[0]){ $stdOne.Add("$($cift[1]) p.%"); if($stdOne.Count -ge 2){ break } } }
    if($stdOne.Count){ $d.InsertRange(0,$stdOne) }
  }
  # dayanak yoksa YA DA zayif/olculmemisse (03.09 olcumu: 'SPK Rehber' zayif dayanagi bono sorusuna
  # SPK Kanunu getirdi, TTK m.776 hic aranmadi): dersin ana kanunlarinda konu kokuyle metin aramasi.
  # Zayif dayanakta bu desenler ONE alinir ki model once dogru kanunu gorsun.
  # 03.09: kara listedeki dayanak (orn. TTK m.720 'TEYITLI' gorunse de) DAYANAKSIZ sayilir;
  # olculdu: 'kambiyo kari kaydi' koprude TTK m.720/TEYITLI diye ders-kanun aramasina
  # hic girmiyor, THP 646 ambarda dururken KAYNAK BORCU yaziliyordu.
  $dayGecerli=@(@("$($kayit.dayanak)","$($kayit.cikmis_dayanak)") | Where-Object { $_.Trim() -and -not (KaraMi $_) })
  $dayanakZayif=$teoriDers -or ($dayGecerli.Count -eq 0) -or ("$($kayit.guc)" -match 'ZAYIF|OLCULMEDI|^$')   # teori dersinde köprü dayanağı yok sayılır (09.09)
  # 03.09 OLCULDU (SGS Vergi 'damga vergisi' -> 5510 gec. m.55 SGK affi; 'kdv matrahi' -> 5510 m.81 prim
  # tesviki): kopru dayanagi DERSIN KANUN LISTESI DISINDA bir kanunsa (kanun numarasiyla olculur) dayanak
  # ZAYIF sayilir; ders kanunlari one gecer, kopru dayanagi yine listede kalir (hakem+KAPI D sinar).
  if(-not $dayanakZayif){
    $dersAdiK=($DersRegex -replace '[\^\$\\]','')
    $dersNo=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($dk in (DersKanunAnahtari $dersAdiK)){ foreach($px in @($DERS_KANUN[$dk])){ foreach($m in [regex]::Matches($px,'\b(\d{3,4})\b')){ [void]$dersNo.Add($m.Groups[1].Value) } } }
    if($dersNo.Count){
      foreach($ham in $dayGecerli){
        $hamNo=@([regex]::Matches($ham,'\b(\d{3,4})\s*(s\.|sayılı|s\.K)') | ForEach-Object { $_.Groups[1].Value })
        if($hamNo.Count -and -not @($hamNo | Where-Object { $dersNo.Contains($_) }).Count){ $dayanakZayif=$true; Write-Host "  DAYANAK DERS DISI KANUN (zayif sayildi): $($kayit.konu) <- $ham" -ForegroundColor DarkYellow; break }
      }
    }
  }
  # 09.09 ikinci ölçüm: teori dersinde '@TEORI|kok' METİN araması rastgele not çekiyordu (Matematik "fonksiyon" → Black-Scholes notu,
  # Yabancı Dil "fiil" → maliyet notu) ve 10 kaynak kotasını doldurup doğru ADLI notu ("TEORI - fiil zamani (past tense)") dışarıda bırakıyordu.
  # Saf teori derslerinde yalnız AD eşleşmesi (aşağıdaki TEORI%kok%kok% desenleri) kullanılır.
  if($dayanakZayif -and $kanunKok.Count -ge 1 -and -not $teoriDers){
    $dersAdi=($DersRegex -replace '[\^\$\\]','')
    $one=New-Object System.Collections.Generic.List[string]
    # 03.09 OLCULDU (SMMM Vergi: 'gelir vergisi matrahi' -> VUK m.4 'vergi dairesi yetkisi' geldi, hakem
    # reddetti): dersin kanun listesi konu kelimesine gore SIRALANIR - gelir vergisi -> GVK, kurumlar -> KVK,
    # kdv -> KDVK, damga -> Damga V.K., tahsil/odeme emri -> AATUHK, defter/degerleme/amortisman -> VUK.
    $KELIME_KANUN=@(
      @('gelir vergi|gvk|ucret|serbest meslek|menkul sermaye|gayrimenkul sermaye|dar mukellef|tam mukellef|beyanname','GVK'),
      @('kurumlar|kvk|istirak|tasfiye|birlesme','KVK'),@('kdv|katma deger|indirim|tevkifat|istisna','KDVK'),
      @('damga','Damga'),@('tahsil|odeme emri|haciz|gecikme zammi|tecil|amme','AATUHK'),
      @('defter|belge|degerleme|amortisman|envanter|usul|tebligat|uzlasma|ceza','VUK (213'),
      @('banka','Bankacılık'),@('sigorta|emeklilik|reasurans','Sigortacılık'),@('surdurulebilirlik|iklim|tsrs','TSRS'),
      @('bds|denetim|denetci|kanit|onemlilik','BDS'),@('tms|tfrs|stok|hasilat|kiralama|deger dusuklugu','TMS'),
      @('^pay |pay turleri|halka arz|izahname|imtiyazli','Pay Tebligi'),@('fon|semsiye|portfoy|katilma payi','Yatirim Fonlarina'),
      @('is sozlesme|fesih|feshi|ucret|kidem|ihbar|calisma sure|fazla calisma|yillik izin','İş K.'),@('sigortali|prim|emeklilik|malulluk|is kazasi|meslek hastaligi','5510')
    )
    $oncelik=@(); foreach($kk in $KELIME_KANUN){ if($konuKat -match $kk[0]){ $oncelik+=$kk[1] } }
    foreach($dk in (DersKanunAnahtari $dersAdi)){
      $liste=@($DERS_KANUN[$dk])
      if($oncelik.Count){ $liste=@($liste | Sort-Object { $s=$_; $i=[array]::FindIndex($oncelik,[Predicate[object]]{ param($o) $s -like "$o*" -or $s -like "*$o*" }); if($i -lt 0){ 99 } else { $i } }) }
      # 09.09: TEORI/Teori Notu öneklerinde METİN araması yok — not adları konuyu taşır, metin araması gürültü çekiyordu (yukarıdaki ölçüm).
      foreach($onek2 in ($liste | Where-Object { $_ -notmatch '^(TEORI|Teori Notu)$' })){ foreach($tk in ($kanunKok | Select-Object -First 2)){ $one.Add("@$onek2|$tk") } }
    }
    if($one.Count){ $d.InsertRange(0,$one) }
  }
  if($teoriOne.Count){ $d.InsertRange(0,$teoriOne) }   # 09.09: konu ADIYLA bulunan teori notu '@' metin desenlerinin ve THP'nin ÖNÜNDE (9.000 kr tavanında kesilmesin)
  if($kodOne.Count){ $d.InsertRange(0,$kodOne) }   # Teblig kodu / TSPB / '~' ad aramasi HER SEYIN ONUNDE
  return @($d | Select-Object -Unique)
}
# Haritanin YANLIS dayanak yazdigi konular icin elle dogru kaynak (01.09:
# 'gelir tahakkuku'na 3568 m.29, 'hesap isleyisi'ne TTK 720 yazilmisti - ikisi de
# alakasiz ZAYIF tahmin; gercek kaynaklar THP/VUK).
$OZEL_DESEN=@{
  # 03.09 SMMM SPK: 'pay turleri' kok 'pay' tek basina SPKn'de rastgele madde getiriyor, KAPI-A iki kez
  # reddetti. Gercek kaynak TTK (nama/hamiline m.484, imtiyazli m.478-479) + Pay Tebligi m.4 tanimlar.
  'pay turleri'     = @('TTK (6102 s.K.) m.484','TTK (6102 s.K.) m.478','TTK (6102 s.K.) m.479','Pay Tebligi (VII-128.1) m.4 %')
  # 03.09 SGS KAPI D yakaladi (5 kayma), ambar adlari canli olculdu:
  'tms 18 hasilat'  = @('TFRS 15 p.9 %','TFRS 15 p.22 %','TFRS 15 p.31 %','TFRS 15 p.46 %','TFRS 15 p.47 %')   # TMS 18 yururlukten kalkti, halefi TFRS 15
  'denetim riski'   = @('BDS 200 p.13 %','BDS 200 p.17 %','BDS 200 p.A36 %','BDS 200 p.A40 %','BDS 315 p.4 - Yapısal Risk%')
  'iliskili taraflar denetimi' = @('BDS 550 p.2 %','BDS 550 p.9 %','BDS 550 p.10 %','BDS 550 p.11 %','BDS 550 p.12 %','BDS 550 p.13 %')
  'cek hukuku'      = @('TTK (6102 s.K.) m.795','TTK (6102 s.K.) m.796','TTK (6102 s.K.) m.808','TTK (6102 s.K.) m.780','TTK (6102 s.K.) m.781')
  'damga vergisi'   = @('Damga V.K. (488 s.K.) m.1 %','Damga V.K. (488 s.K.) m.3 %','Damga V.K. (488 s.K.) m.10 %','Damga V.K. (488 s.K.) m.14%','Damga V.K. (488 s.K.) m.22%')
  'kdv matrahi'     = @('KDVK (3065 s.K.) m.20 %','KDVK (3065 s.K.) m.24 %','KDVK (3065 s.K.) m.25 %','KDVK (3065 s.K.) m.21 %','KDVK (3065 s.K.) m.26 %','KDVK (3065 s.K.) m.27 %')   # 03.09 uc turda 5510 m.81 -> KDV istisnasi kaymasi
  # 03.09 SMMM SPK kp-10: 'birligi' koku SPKn m.2 kapsam maddesini getirdi, KAPI D konu-disi dedi. TSPB = SPKn m.74-75.
  'turkiye sermaye piyasalari birligi gorevleri' = @('Sermaye Piyasası K. (6362 s.K.) m.74','Sermaye Piyasası K. (6362 s.K.) m.74 %','Sermaye Piyasası K. (6362 s.K.) m.75','Sermaye Piyasası K. (6362 s.K.) m.75 %')
  'gelir tahakkuku' = @('THP 181%','THP 281%','VUK (213 s.K.) m.22%','VUK (213 s.K.) m.283%')
  'hesap isleyisi'  = @('THP 102%','THP 120%','THP 320%','THP 191%','THP 391%')
  # 01.09 hakem-red onarimlari: kuralin YASADIGI paragraflar (tanim+yururluk degil)
  'tms 36 deger dusuklugu'   = @('TMS 36 p.2%','TMS 36 p.4%','TMS 36 p.6%','TMS 36 p.8%','TMS 36 p.9%','TMS 36 p.59%','TMS 36 p.60%')
  'nakit akis tablosu'       = @('TMS 7 p.10%','TMS 7 p.13%','TMS 7 p.14%','TMS 7 p.16%','TMS 7 p.18%','TMS 7 p.19%','TMS 7 p.20%')
  'tms 7 nakit akis tablosu' = @('~teori tms 7 nakit','TMS 7 p.7%','TMS 7 p.8%','TMS 7 p.45%','TMS 7 p.46%','TMS 7 p.10%')
  'tms 12 ertelenmis vergi'  = @('~teori tms 12 ertelen','TMS 12 p.5%','TMS 12 p.15%','TMS 12 p.16%','TMS 12 p.20%','TMS 12 p.24%','TMS 12 p.47%')
  # 01.09 kayit-odakli yeni konular (FMuh suzgeci sonrasi)
  'kar dagitimi kaydi'       = @('TTK (6102 s.K.) m.519%','TTK (6102 s.K.) m.523%','THP 570%','THP 590%','THP 591%')
  'kar dagitimi'             = @('TTK (6102 s.K.) m.519%','TTK (6102 s.K.) m.523%','THP 570%','THP 590%','THP 591%')
  'fifo yontemi'             = @('TMS 2 p.25%','TMS 2 p.27%','VUK (213 s.K.) m.274%','THP 153%')
  'finansman bonosu ihraci'  = @('THP 305%','THP 308%','THP 300%')
  # 10.09 ÖLÇÜLDÜ (İş-SGK t2b ön ölçümü): ders kanun listesi (satır 291) VAR diyordu ama kök eşleşmesi
  # ALAKASIZ maddeye düşüyordu — 'fazla calisma hukumleri' -> VUK ek m.13 (memur fazla mesaisi),
  # 'toplu is sozlesmesi' -> Avukatlık K. m.191 (tip sözleşme), 'sosyal sigortali sayilma' -> İş K. m.30
  # (engelli çalıştırma), 'sendika uyeligi' -> İş K. m.18 (iş güvencesi), 'fiili hizmet suresi zammi'
  # -> 5510 m.29 (yaşlılık aylığı hesabı). Ambarda 4857'nin 138, 6356'nın 94 maddesi TAM duruyor;
  # kusur desende. Madde adları ambardan birebir okundu.
  'fazla calisma hukumleri'         = @('İş K. (4857 s.K.) m.41%','İş K. (4857 s.K.) m.42','İş K. (4857 s.K.) m.43','İş K. (4857 s.K.) m.63')
  'fazla calisma'                   = @('İş K. (4857 s.K.) m.41%','İş K. (4857 s.K.) m.42','İş K. (4857 s.K.) m.43','İş K. (4857 s.K.) m.63')
  'is kanunu calisma sureleri'      = @('İş K. (4857 s.K.) m.63','İş K. (4857 s.K.) m.64','İş K. (4857 s.K.) m.66','İş K. (4857 s.K.) m.68')
  'toplu is sozlesmesi'             = @('Sendikalar ve TİS K. (6356 s.K.) m.33','Sendikalar ve TİS K. (6356 s.K.) m.34','Sendikalar ve TİS K. (6356 s.K.) m.35','Sendikalar ve TİS K. (6356 s.K.) m.36','Sendikalar ve TİS K. (6356 s.K.) m.39')
  'tesmil karari'                   = @('Sendikalar ve TİS K. (6356 s.K.) m.40','Sendikalar ve TİS K. (6356 s.K.) m.39')
  'sendika uyeligi'                 = @('Sendikalar ve TİS K. (6356 s.K.) m.17','Sendikalar ve TİS K. (6356 s.K.) m.18','Sendikalar ve TİS K. (6356 s.K.) m.19%')
  'sendika uyeligi kazanilmasi'     = @('Sendikalar ve TİS K. (6356 s.K.) m.17','Sendikalar ve TİS K. (6356 s.K.) m.18')
  'sendikal guvenceler'             = @('Sendikalar ve TİS K. (6356 s.K.) m.23','Sendikalar ve TİS K. (6356 s.K.) m.24','Sendikalar ve TİS K. (6356 s.K.) m.25%')
  'sendika kanunu tanimlari'        = @('Sendikalar ve TİS K. (6356 s.K.) m.2 [%','Sendikalar ve TİS K. (6356 s.K.) m.3')
  'sendika yetkisi dusmesi'         = @('Sendikalar ve TİS K. (6356 s.K.) m.42','Sendikalar ve TİS K. (6356 s.K.) m.43%','Sendikalar ve TİS K. (6356 s.K.) m.45')
  'grev lokavt yasagi'              = @('Sendikalar ve TİS K. (6356 s.K.) m.62','Sendikalar ve TİS K. (6356 s.K.) m.63','Sendikalar ve TİS K. (6356 s.K.) m.58')
  # 10.09 TUZAK: 'm.4%' ilike oneki m.40..m.49'u DA yakaliyor — ilk olcumde 'sosyal sigortali sayilma'
  # 5510 m.40'a (fiili hizmet zammi), 'sigortali sayilmayanlar' m.62'ye dustu. Parcali maddede ad
  # "m.4 [1/4]" oldugu icin dogru onek 'm.4 [%'; tek parcali maddede joker HIC kullanilmaz.
  'sosyal sigortali sayilma'        = @('5510 s. SGK Kanunu m.4 [%','5510 s. SGK Kanunu m.7 [%','5510 s. SGK Kanunu m.7')
  'sigortali sayilmayanlar'         = @('5510 s. SGK Kanunu m.6 [%','5510 s. SGK Kanunu m.4 [%')
  'is kazasi sayilan haller'        = @('5510 s. SGK Kanunu m.13%','5510 s. SGK Kanunu m.14%')
  'is kazasi isveren sorumlulugu'   = @('5510 s. SGK Kanunu m.21%','5510 s. SGK Kanunu m.13%')
  'is kazasi surekli is goremezlik' = @('5510 s. SGK Kanunu m.19%','5510 s. SGK Kanunu m.20%')
  'gecici is goremezlik sigorta kollari' = @('5510 s. SGK Kanunu m.18%','5510 s. SGK Kanunu m.15%','5510 s. SGK Kanunu m.16%')
  'fiili hizmet suresi zammi'       = @('5510 s. SGK Kanunu m.40%')
  'hizmet borclanmasi'              = @('5510 s. SGK Kanunu m.41%')
  'yaslilik ayligi prim gunu'       = @('5510 s. SGK Kanunu m.28 [%','5510 s. SGK Kanunu m.29%')
  # 10.09 ÖLÇÜLDÜ: 'kolaylastirilmis emeklilik' adiyla ambarda belge YOK, konu kaynaksiz sanildi.
  # 5510 m.28 [2/4] ve [3/4] metni okundu: engellilik derecesine gore yas sarti aranmaksizin yaslilik
  # ayligi (%50-59 -> 16 yil/4320 gun, %40-49 -> 18 yil/4680 gun), 55 yasinda erken yaslanma, agir
  # engelli cocugu olan kadin sigortalinin prim gun eklemesi, maden yeralti 20 yil -> yas 50.
  # Konunun kaynagi VAR, eksik olan desendi.
  'kolaylastirilmis emeklilik'      = @('5510 s. SGK Kanunu m.28 [%')
  'olum ayligi kesilmesi'           = @('5510 s. SGK Kanunu m.34%','5510 s. SGK Kanunu m.35%')
  'uzun vadeli sigorta kollari'     = @('5510 s. SGK Kanunu m.25%','5510 s. SGK Kanunu m.28%','5510 s. SGK Kanunu m.32%')
  'belirli sureli is sozlesmesi'    = @('İş K. (4857 s.K.) m.11','İş K. (4857 s.K.) m.12','İş K. (4857 s.K.) m.8')
  'kismi sureli is sozlesmesi'      = @('İş K. (4857 s.K.) m.13%','İş K. (4857 s.K.) m.14%')
  'is sozlesmesi turleri'           = @('İş K. (4857 s.K.) m.9','İş K. (4857 s.K.) m.10','İş K. (4857 s.K.) m.11','İş K. (4857 s.K.) m.13%','İş K. (4857 s.K.) m.14%')
  'sozlesme sekli'                  = @('İş K. (4857 s.K.) m.8','İş K. (4857 s.K.) m.9')
  'alt isverenlik'                  = @('İş K. (4857 s.K.) m.2 [%')
  'isyeri devri-is kanunu'          = @('İş K. (4857 s.K.) m.6')
  'is guvencesi kapsami'            = @('İş K. (4857 s.K.) m.18%','İş K. (4857 s.K.) m.19','İş K. (4857 s.K.) m.21%')
  'is kanunu fesih'                 = @('İş K. (4857 s.K.) m.17','İş K. (4857 s.K.) m.24%','İş K. (4857 s.K.) m.25%')
  'İs kanunu kapsami'               = @('İş K. (4857 s.K.) m.1','İş K. (4857 s.K.) m.4 [%')
  'ucret hukumleri'                 = @('İş K. (4857 s.K.) m.32%','İş K. (4857 s.K.) m.34','İş K. (4857 s.K.) m.35')
  'ucretin ise hasredilmesi'        = @('İş K. (4857 s.K.) m.36%','İş K. (4857 s.K.) m.35')
  'ucretin odenmemesi hakli fesih'  = @('İş K. (4857 s.K.) m.24%','İş K. (4857 s.K.) m.34')
  'haciz siniri'                    = @('İş K. (4857 s.K.) m.35')
  # 10.09 T3 TOPYEKUN KAYNAK DENETIMI: 42 etiketin 14 benzersiz konu listesi tek tek olculdu.
  # Alt satirdaki 15 konu "VAR" diyordu ama gelen belge ALAKASIZDI; hedef madde adlari ambardan
  # birebir dogrulandi (hepsi mevcut), kusur yalnizca desendeydi. Joker tuzagina dikkat:
  # 'm.64%' TTK'da m.640-649'u da yakalar -> parcali maddede 'm.64 [%', tek parcalida joker YOK.
  # --- Borclar Hukuku: TBK m.47 (manevi tazminat) geliyordu, sebepsiz zenginlesme m.77-82'dir
  'sebepsiz zenginlesme'            = @('TBK (6098 s.K.) m.77','TBK (6098 s.K.) m.78','TBK (6098 s.K.) m.79','TBK (6098 s.K.) m.80')
  'sebepsiz zenginlesme zamanasimi' = @('TBK (6098 s.K.) m.82','TBK (6098 s.K.) m.77')
  # --- Denetim: GDS 3410 (sera gazi guvence denetimi) ve GDS 3402 (hizmet kurulusu) geliyordu
  'ic kontrol sistemi'              = @('BDS 315%')
  'bds 530 ornekleme yontemi'       = @('BDS 530%')
  'calisma kagitlari'               = @('BDS 230%')
  'analitik prosedurler'            = @('BDS 520%','BDS 315%')
  # --- Finansal Muhasebe: VUK m.45 (emlak vergisi bedelleri) geliyordu, aktiflesen gider m.262/269/272
  'aktiflesen gider'                = @('VUK (213 s.K.) m.272','VUK (213 s.K.) m.262%','VUK (213 s.K.) m.269')
  # --- Meslek Hukuku: Avukatlik K. m.168 ve TSPB Sermaye Piyasasi Etik Ilkeleri geliyordu
  'ucret tarifesi'                  = @('SMMM K. (3568 s.K.) m.46','TÜRMOB Etik İlkeler Yön. EK%')
  'etik ilkeler tehditleri'         = @('TÜRMOB Etik İlkeler Yön. EK%','TÜRMOB Etik İlkeler Yön. m.4','TÜRMOB Etik İlkeler Yön. m.5')
  # --- Ticaret Hukuku: TTK m.235 (kollektif sirket), m.147 (birlesme), Kooperatifler K. m.25,
  #     SPK Borsa Istanbul karari geliyordu; dogru maddeler asagida
  'ticari temsilcilik yetkisi'      = @('TBK (6098 s.K.) m.547','TBK (6098 s.K.) m.548','TBK (6098 s.K.) m.551')
  'ticari defter tutma yukumlulugu' = @('TTK (6102 s.K.) m.64 [%','TTK (6102 s.K.) m.65')
  'anonim sirket temsili'           = @('TTK (6102 s.K.) m.365','TTK (6102 s.K.) m.370','TTK (6102 s.K.) m.371 [%')
  'cek uzerindeki kayitlar'         = @('TTK (6102 s.K.) m.780 [%','TTK (6102 s.K.) m.781','TTK (6102 s.K.) m.782')
  # --- Vergi Hukuku: Belediye Gelirleri K. ek m.1 ve 5422 donemi KVGT Seri 86 geliyordu
  'kdv vergiyi doguran olay'        = @('KDVK (3065 s.K.) m.10 -%')
  'kurumlar vergisi mukellefleri'   = @('KVK (5520 s.K.) m.1','KVK (5520 s.K.) m.2 [%','KVK (5520 s.K.) m.3')
  'kurumlar vergisi istisnasi'      = @('KVK (5520 s.K.) m.5 [%')
  # 09.09: OZEL_DESEN DesenUret'in YERİNE geçer → buradaki konuların dün yazılan TEORİ notları hiç çekilmiyordu; '~teori' ad deseni eklendi
  'hazine bonosu tahsili'    = @('~teori hazine bonosu','THP 112%','THP 111%','THP 102%')
  # 09.09 Tur 1/2 kaynak yüzünden düşen, notu olan ama adı konu kökleriyle eşleşmeyen konular (ölçüldü, Cem "önce ölç, kaynağı yut, sonra bas")
  'iasb calismalari'         = @('~teori ifrs vakfi iasb','~teori iasb')
  'uluslararasi etik kurulu' = @('~teori ifac iesba','~teori ifac')
  'cari oran duran varlik'   = @('~teori bilanco esitli','~teori cari oran','~teori duran varlik','THP 253%','THP 300%')
  'brut satis kari degisimi' = @('~teori brut satis kari','THP 600%','THP 621%','THP 610%','THP 611%')
  'hasilat kavrami'          = @('~teori gelir hasilat kazanc','THP 600%','THP 679%','THP 649%','THP 391%')
  'ust yonetimle iletisim'   = @('~teori istirak bagli ortaklik','THP 242%','THP 245%','THP 240%')   # konu adı yanlış; Tur 1 sorusu 245 Bağlı Ortaklıklar yönetim çoğunluğu ölçütünü sormuştu
  # 09.09 GM maliyet-kolay ÖLÇÜLDÜ (5 hakem reddi, hepsi kaynak): 'standart' GENEL_KOK'ta olduğu için "standart maliyet sistemi" tek kök "maliyet"le 6 alakasız
  # not çekti; "normal maliyet" ve "bakım onarım" dayanağındaki TMS 2 / TMS 16 atıfı paketi standart paragraflarıyla doldurdu. Doğru notlar ADLA öne alınır.
  'standart maliyet sistemi'        = @('~teori standart maliyet kartinin','~teori standart maliyet miktar','~teori standart maliyet fark','THP 711%','THP 712%','THP 713%','THP 722%','THP 723%')   # 09.09 cokzor: standart KARTIN KURULMASI notu yoktu, yazıldı (kayit-5)
  'standart maliyet direkt iscilik' = @('~teori direkt iscilik ucret','~teori standart maliyet miktar','THP 722%','THP 723%')
  'direkt iscilik sure farki'       = @('~teori direkt iscilik sure','~teori direkt iscilik ucret','THP 723%','THP 722%')
  'direkt iscilik farklari'         = @('~teori direkt iscilik sure','~teori direkt iscilik ucret','THP 722%','THP 723%')
  'normal maliyet-kapasite kullanim'= @('~teori normal maliyet','~teori tam maliyet normal','THP 680%','THP 730%')
  'ozel maliyetler bakim onarim'    = @('~teori bakim onarim','THP 730%','THP 770%','THP 760%','THP 264%')
  'tam maliyet yontemi'             = @('~teori tam maliyet normal','~teori degisken maliyet sistemi','~teori normal maliyet','THP 730%')   # "tam" 3 harf, "yontemi" genel kök → tek kök "maliyet" 6 alakasız not çekti (09.09 ölçüldü)
  # 09.09 GM maliyet-zor ÖLÇÜLDÜ (3 hakem reddi, hepsi kaynak): notlar VARDI ama adı konu kökleriyle eşleşmiyordu ("Teori Notu - maliyet gider harcama kavramlari",
  # "TEORI - Ardisik donem satilan mamul maliyeti"); direkt işçilik gideri (boşa geçen süre, fazla çalışma primi) notu YOKTU → yazıldı (teori-notlari-20260909-sgs-maliyet-kayit-3.json)
  'maliyet esasi kavrami'           = @('~teori maliyet gider harcama','~teori maliyetlerin siniflandirilmasi','THP 710%','THP 720%','THP 730%','THP 150%')
  # 09.09 GM maliyet-cokzor ölçümü: THP 264 kaynak paketine girmiyordu (hakem ATIF TEYITSIZ); özel maliyet konusu adla çekilir
  'ozel maliyet itfasi'             = @('~teori bakim onarim','THP 264%','THP 730%','THP 770%')
  'genel uretim giderleri'          = @('~teori maliyetlerin siniflandirilmasi','~teori uretim giderlerinin dagitimi','THP 730%','THP 710%','THP 720%')
  'uretim satis maliyeti hesaplama' = @('~teori ardisik donem satilan','~teori secene uretim maliyeti','THP 151%','THP 152%','THP 620%')
  'satilan mamul maliyeti'          = @('~teori ardisik donem satilan','~teori stok degerleme','THP 152%','THP 620%')
  'direkt iscilik gideri hesaplama' = @('~teori direkt iscilik giderinin','~teori direkt iscilik ucret','THP 720%','THP 730%')
  # 09.09 GM t2b MTA: 23 konunun 14'ünde ambar notu yoktu (ölçüldü), beş kapsayıcı not yazıldı (teori-notlari-20260909-sgs-mta-oranlar.json).
  # Ad eşleşmesi zayıf kalan konular desenle bağlanır; ötekiler kök eşleşmesiyle notu kendiliğinden buluyor.
  'cari oran-asit test yorumlama'          = @('~teori likidite oranlari','THP 100%','THP 150%','THP 300%')
  'sektor oranlari analizi'                = @('~teori likidite oranlari','~teori finansal yapi','~teori karlilik oranlari')
  'kisa vadeli kredi taksidi'              = @('~teori likidite oranlari','~teori finansal yapi','THP 300%','THP 400%')
  'net calisma sermayesi devir hizi'       = @('~teori faaliyet devir','~teori likidite oranlari')
  'kisa vadeli yabanci kaynak dikey yuzde' = @('~teori dikey yuzde','~teori finansal yapi')
  'calisma sermayesi analizi'              = @('~teori likidite oranlari','~teori net isletme sermayesi')
  # 09.09 22:55 arac/konu-kaynak-on-olcum.ps1 ile ÖLÇÜLDÜ (Cem: "kaynak yüzünden düşen konuyu önceden ölçelim"):
  # MTA zor'un 27 konusundan 6'sı "kaynak YOK" çıktı; notlar ambarda VARDI ama konu adı not adıyla eşleşmiyordu.
  # 09.09 23:10 ders ders kaynak ölçümü (Cem: "kaynağı olmayana şu an koşmayacak, sen tamamlanınca koşacak"):
  # Maliyet'in 43 tekil konusundan 5'i kaynaksız çıktı — notlar ambarda VAR, konu adı eşleşmiyordu.
  'ortak urun maliyet dagitimi'            = @('~teori ortak maliyet dagitiminda','~teori birlesik ortak maliyetin','~teori yan urun maliyetinde')
  'birlesik urun katsayi yontemi'          = @('~teori ortak maliyet dagitiminda','~teori birlesik ortak maliyetin')
  'katsayili maliyet dagitimi'             = @('~teori ortak maliyet dagitiminda','~teori birlesik ortak maliyetin')
  'yatirim siparis avansi'                 = @('~teori siparis avansi','THP 159%','THP 259%','THP 340%')
  '7-a secenegi genel uretim gideri'       = @('~teori secene uretim maliyeti','~teori maliyetlerin siniflandirilmasi','THP 730%','THP 731%','THP 680%')
  'ozsermaye karlilik orani'               = @('~teori karlilik oranlari','~teori piyasa oranlari','THP 590%','THP 570%')
  'aktif karlilik orani'                   = @('~teori karlilik oranlari','~teori aktif devir','THP 590%')
  'yatay analiz yorumlama'                 = @('~teori karsilastirmali yatay','~teori yuzde degisim')
  'yuzde degisim analizi'                  = @('~teori karsilastirmali yatay','~teori yuzde degisim')
  'bilanco kaldirac orani'                 = @('~teori finansal yapi','~teori kaldirac orani')
  'cari oran bilanco analizi'              = @('~teori likidite oranlari','~teori cari oran')
  'mali tablolar analiz teknikleri'        = @('~teori mali tablolar analizinde','~teori karsilastirmali yatay','~teori dikey yuzde')
  'gelir tablosu analiz sinirlamalari'     = @('~teori gelir tablosu analizinin','~teori karsilastirmali yatay')
  # 10.09 ÖLÇÜLDÜ (MTA kolay kp-05 + MTA zor kp-02): deseni olmayan konuda kök eşleşmesi ALAKASIZ belge getiriyordu
  # ve hakem "kaynak metni bu konuyu hiç içermiyor" diyerek soruyu düşürüyordu. Örnekler: 'brut kar orani' ->
  # faaliyet tabanlı maliyetleme + uluslararası iktisat; 'cari oran hesaplama' -> kamu harcamaları sınıflandırma
  # (cari-yatırım); 'kâr marji analizi' -> Keynesyen çarpan; 'nakit orani' -> TMS 1 Nakit Akış Tablosu.
  # Kaynak VARDI, çekim yanlıştı: "belge sayısı > 0" tek başına "doğru kaynak" demek değildir.
  'brut kar orani'                         = @('~teori karlilik oranlari','~teori faaliyet kar marjini')
  'kâr marji analizi'                      = @('~teori karlilik oranlari','~teori faaliyet kar marjini')
  'cari oran hesaplama'                    = @('~teori likidite oranlari','~teori cari oran ve asit')
  'nakit orani'                            = @('~teori likidite oranlari','~teori cari oran ve asit')
  'likidite orani hesaplama'               = @('~teori likidite oranlari','~teori stok bagimlilik')
  'likidite oranlari analizi'              = @('~teori likidite oranlari','~teori cari oran ve asit')
  'net calisma sermayesi'                  = @('~teori likidite oranlari','~teori calisma sermayesi analizi')
  'net isletme sermayesi analizi'          = @('~teori surekli sermaye','~teori calisma sermayesi analizi')
  'yabanci kaynak orani analizi'           = @('~teori finansal yapi','~teori oz sermaye carpani')
  'fiyat kazanc orani'                     = @('~teori fiyat kazanc','~teori karlilik oranlari')
  'aktif devir hizi'                       = @('~teori faaliyet devir','~teori aktif devir')
  'dikey yuzde-aktif analizi'              = @('~teori dikey yuzde','~teori dikey yuzdelerden oran')
  'mali tablo standart oranlar'            = @('~teori likidite oranlari','~teori finansal yapi','~teori karlilik oranlari')
  'stokta kalma suresi'                    = @('~teori faaliyet devir','~teori stok devir')
  # 10.09 ÖLÇÜLDÜ (bütün derslere yayılan kaynak denetimi): Meslek Hukuku'nun disiplin konuları
  # ambardaki TEK "Disiplin Yönetmeliği" adlı belgeye, yani SPK Türkiye Sermaye Piyasaları Birliği
  # Disiplin Yönetmeliği'ne bağlanıyordu. Doğru kaynak 'SMMM ve YMM K. Disiplin Yonetmeligi' ile
  # SMMM K. (3568 s.K.) m.48-49'dur; ikisi de ambarda VARDI, çekim yanlış belgeye gidiyordu.
  'disiplin yonetmeligi itiraz'            = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.48%','SMMM K. (3568 s.K.) m.49%')
  'disiplin cezalari'                      = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.48%')
  'disiplin cezasi kinama'                 = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.48%')
  'disiplin cezalari eslestirme'           = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.48%')
  'disiplin kovusturmasi'                  = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.49%')
  'meslek hukuku disiplin cezasi'          = @('SMMM ve YMM K. Disiplin Yonetmeligi%','SMMM K. (3568 s.K.) m.48%')
  'turmob meslek odasi gelirleri'          = @('TÜRMOB Birlik Yön.%','SMMM K. (3568 s.K.) m.28%','SMMM K. (3568 s.K.) m.29%')
  'police muhasebelestirme'  = @('THP 121%','THP 321%','TTK (6102 s.K.) m.671%','TTK (6102 s.K.) m.672%')
  'önemlilik kavramı'        = @('MSUGT 1 kavram%')
  'amortisman ayirma'        = @('THP 257%','THP 730%','THP 770%','VUK (213 s.K.) m.313%','VUK (213 s.K.) m.315%')
  # 02.09: teori notu yazilip yutuldu (veri/mevzuat/teori-mizan-20260902.json)
  'kesin mizan'              = @('TEORI - Mizan%')
  # 02.09 KOPRU YANLIS ESLESMESI ONARIMI: bu alti konu kopruDE yanlis dayanaga
  # baglanmisti (ucu birden "VUK m.275 - Imal edilen emtia"). KAPI-A yanlis
  # eslesmeyi dogru yakaladi; asagidaki desenler AMBARDA TEK TEK OLCULDU (hepsi VAR).
  'ozkaynak hesaplama'          = @('THP 500%','THP 540%','THP 570%','THP 590%','THP 529%')
  'dönemsellik kavramı'         = @('MSUGT 1 kavram%','THP 180%','THP 380%','THP 181%','THP 381%')
  'duran varlik satisi'         = @('VUK (213 s.K.) m.328%','THP 253%','THP 257%','THP 679%','THP 689%')
  # Iki yanlis denemeden sonra OLCUYLE bulundu: kollektif sirkette kar payi hakki ve
  # zarara katilma TTK m.226-228'de ("E) Kar payi hakki ve zarara katilma" baslikli
  # bolum; m.227 kar dagitimi karari, m.228 ortagin kar payini isteme hakki).
  # m.62%/m.638 denemeleri sirket turu ve LIMITED sirket hukumlerini getirmisti.
  'kollektif sirket kar dagitimi'= @('TTK (6102 s.K.) m.227%','TTK (6102 s.K.) m.228%','TTK (6102 s.K.) m.226%','THP 331%','THP 590%')
  'yasal yedek akce'            = @('TTK (6102 s.K.) m.519%','THP 540%','THP 541%')
  'kasa sayim farki'            = @('THP 197%','THP 397%','THP 100%')
  # 02.09 HAKEM (KAPI-B) yakalamalari - ikisi de ayni sinif: kopru yanlis dayanak.
  # kp-04: soru 381 GIDER TAHAKKUKLARI (PASIF gecici) sorarken kopru VUK m.283'e
  #        (AKTIF gecici hesaplar) baglamisti - dogrusu m.287.
  # kp-29: 690'a devir KAYIT teknigi sorarken kopru TMS 1'e (sunulus) baglamisti.
  'gider tahakkuku'             = @('VUK (213 s.K.) m.287%','THP 381%','THP 770%')
  'gelir tablosu hesaplari'     = @('THP 690%','THP 600%','THP 611%','THP 621%')
  # 10.09 ÖLÇÜLDÜ (GM Vergi Hukuku + Maliye t4): 108 hazır sorunun 34'ü hakemden döndü ve 34'ünün de gerekçesi
  # AYNIYDI — "kaynak metni soru konusunu içermiyor". Soru kusurlu değildi, hakemin gördüğü paket yanlıştı:
  # deseni olmayan konuda DesenUret kök eşleşmesine düşüyor, kök alakasız maddeyi getiriyordu. Hakem sözleriyle:
  # '5018 butce turleri' -> "Kaynak metni soru konusunu (5018 m.3'teki genel yönetim kapsamı) hiç içermemektedir";
  # 'is-lm acik ekonomi' -> "kaynak metni Atatürk dönemi ekonomi politikası, bütçe sınıflandırması...".
  # Aşağıdaki 14 desen ambarda TEK TEK ölçüldü (arac/desen sınaması; her biri hedef belgeyi döndürüyor).
  # JOKER TUZAĞI burada iki kez ısırdı: '6183 m.10%' m.100-109'u, '6183 m.11%' m.110-118'i, '5018 m.3%' m.30-39'u
  # da yakalıyor. Tek parçalı maddede ad "m.10 - Teminat ve değerlenmesi" olduğu için doğru önek 'm.10 -%';
  # parçalı maddede "m.3 [1/3]" olduğu için 'm.3 [%'. Joker asla çıplak numaranın hemen ardına konmaz.
  'amme alacagi tecil'                = @('AATUHK (6183 s.K.) m.48 -%','AATUHK (6183 s.K.) m.49%','AATUHK (6183 s.K.) m.51%')
  'amme alacagi teminat paraya cevirme'= @('AATUHK (6183 s.K.) m.56%','AATUHK (6183 s.K.) m.10 -%','AATUHK (6183 s.K.) m.11 -%','AATUHK (6183 s.K.) m.12 -%','AATUHK (6183 s.K.) m.9 -%')
  'amme alacagi tasarruf iptali'      = @('AATUHK (6183 s.K.) m.24 -%','AATUHK (6183 s.K.) m.26 -%','AATUHK (6183 s.K.) m.27%','AATUHK (6183 s.K.) m.28 -%','AATUHK (6183 s.K.) m.29 -%')
  # 10.09 İKİ KAYNAK: konu adı "indirim" diyor (GVK mük.121'deki %5 uyumlu mükellef indirimi; ambardaki adı
  # "GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO: 301) muk. m.121"), yazılan sorular ise 6183 m.48/A'yı (uyumlu
  # mükellefin borcunun TECİLİ) ölçüyor. Hakem bu farkı yakaladı: "soru resmi konu olan 'vergiye uyumlu
  # mükellef indirimi' değil, 'vergiye uyumlu mükelleflerin borçlarının tecili' konusunu ölçmektedir" (zor kp-10).
  # İkisi de pakete konur: soru hangi açıdan yazılırsa yazılsın hakem doğru metni görür. Konu adıyla soru
  # arasındaki uyum ayrı bir iştir — desen onu çözmez, KAPI D doğru davranıyor.
  'vergiye uyumlu mukellef indirimi'  = @('GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO: 301) muk. m.121%','AATUHK (6183 s.K.) m.48/A%')
  'otv engelli istisnasi'             = @('ÖTV K. (4760 s.K.) m.7 [%')
  'ozel iletisim vergisi'             = @('Gider Vergileri K. (6802 s.K.) m.39 [%')
  'emlak vergisi-bina vergisi'        = @('Emlak V.K. (1319 s.K.) m.7 -%','Emlak V.K. (1319 s.K.) m.8 -%','Emlak V.K. (1319 s.K.) m.9 -%','Emlak V.K. (1319 s.K.) m.1 -%','Emlak V.K. (1319 s.K.) m.3 -%')
  'kdv matrahina dahil unsurlar'      = @('KDVK (3065 s.K.) m.24 -%','KDVK (3065 s.K.) m.20 -%','KDVK (3065 s.K.) m.25 -%','KDVK (3065 s.K.) m.27 -%')
  'kdv istisnalari'                   = @('KDVK (3065 s.K.) m.11 -%','KDVK (3065 s.K.) m.12 [%','KDVK (3065 s.K.) m.18 -%','KDVK (3065 s.K.) m.16')
  # Maliye: dördü de teori konusu; notlar ambarda VARDI, adları konu kökleriyle eşleşmiyordu (09.09 dersinin tekrarı)
  'gelir vergisi dilim tarifesi'      = @('~teori vergi siniflandirmasi','GVK (193 s.K.) m.103%')
  'gelir vergisi subjektivite'        = @('~teori vergi siniflandirmasi','~teori vergileme ilkeleri')
  'is-lm acik ekonomi'                = @('~teori is-lm acik ekonomi','~teori is-lm likidite tuzagi para','~teori denge geliri')
  '5018 butce turleri'                = @('~teori 5018 butce turleri','Kamu Malî Yönetimi K. (5018 s.K.) m.3 [%','~teori merkezi yonetim butcesi kapsami')
  'kamu harcamalari artis kuramlari'  = @('~teori kamu harcamalarinin artis','~teori wagner kanunu')
}
# Hakem yakalamalarindan dogan konu-ozel uretim uyarilari (isteme eklenir)
$OZEL_NOT=@{
  # 06.09 kalıp-5 pilotu (hakem yakaladı): model dava masrafını alacağa EKLEYİP karşılık ayırdı; 2022/1 çıkmış sorunun tuzağı tam buydu (110.000 şıkları).
  'supheli alacak karsiligi' = "DIKKAT (hakem yakaladi): Vergi Usul Kanunu 323'e gore karsilik, dava/icra asamasindaki alacagin (KDV dahil tutar kabul edilir) TEMINATTAN GERI KALAN kismi icin ayrilir; donem ici tahsilat dusulur. DAVA/ICRA MASRAFI ALACAGA EKLENMEZ - ayri gider olarak (659/770) kaydedilir. Cikmis sinav bu masrafi tuzak olarak verir (108.000 dogru, 110.000 tuzak); soruda masraf veriliyorsa DOGRU sik masrafsiz tutar, masrafli tutar CELDIRICI olur."
  'kar dagitimi kaydi' ="DIKKAT (hakem yakaladi): TTK m.519/2-c'ye gore II. tertip kanuni yedek, 'pay sahiplerine %5 kar payi odendikten sonra KARA KATILACAK KISILERE DAGITILMASI KARARLASTIRILAN TOPLAM TUTARIN %10'u'dur - 'dagitim sonrasi kalan tutarin %10'u' DEGILDIR. Hesabi bu dogru kuralla kur."
  # 01.09 ders-uyum hakemi yakalamalari: konu mesru, SORU acisi kaymisti - KAYIT acisiyla kur
  'muhasebe bilgi sistemi' = "DERS UYARISI (hakem yakaladi): belgenin vergi-hukuku gecerliligini SORMA; belge->yevmiye->defter KAYIT AKISINI ve muhasebe surecindeki rolunu sor (FMuh boyutu)."
  'amortisman ayirma'      = "DERS UYARISI (hakem yakaladi): amortisman HESAPLAMA teknigi/oran secimi Vergi Hukuku'na kacar; burada AYIRMA KAYDINI sor - 7xx/730 gider, 257 Birikmis Amortismanlar isleyisi, dogrudan/endirekt kayit yontemi. Hesap sade tutulur (duz amortisman, tam yil)."
  'gelir tablosu hesaplari'= "DERS UYARISI (hakem yakaladi): dikey yuzde/oran analizi Mali Tablolar Analizi'ne kacar; burada 6xx GELIR TABLOSU HESAPLARININ ISLEYISINI sor - hangi islem hangi hesaba, yansitma/kapanis kayitlari, brut satistan net kara akisin KAYIT boyutu."
  # 02.09 ders-uyum hakemi yakalamasi
  'tms 2 stoklar'          = "DERS UYARISI (hakem yakaladi): NGD/GUD gibi ileri OLCUM-KAVRAM ayrimlari Denetim/ileri MTA'ya kacar. Burada stoklarin KAYIT boyutunu sor: 153 Ticari Mallar maliyetine neyin girip neyin girmedigi (nakliye, sigorta, alis iskontosu), 157 Diger Stoklar, deger dusuklugu karsiliginin (158) ayrilma KAYDI. Sade tutarlarla, tek islem."
}

# --- YAZIM KAPISI (02.09 Cem: "soru cevap kismini begenmedim") ---------------
# Olculdu: 30 sorunun 26'sinda ASCII yazim kusuru vardi ("Dogrusu", "Tuzagi").
# Sebep: istem ASCII yazilmisti, model taklit ediyordu. Istem duzeltildi; bu kapi
# ESKI cache'i ve modelin kacak ASCII'sini de onarir. Yalniz TAM KELIME eslesir -
# kaynak metinlerindeki resmi yazimlara ve hesap adlarina dokunmaz.
# DIKKAT: hashtable ANAHTARLARI da harf ayirmaz ('\bDogrusu\b' ile '\bdogrusu\b'
# ayni kutudur) - bu yuzden sozluk degil DIZI CIFTI kullaniliyor. Eslesme harfe
# DUYARLI olmali ki 'Dogrusu' -> 'Doğrusu', 'dogrusu' -> 'doğrusu' ayri gitsin.
$YAZIM_DUZELT=@(
  @('\bDogrusu\b','Doğrusu'), @('\bdogrusu\b','doğrusu')
  @('\bTuzagi\b','Tuzağı'),   @('\btuzagi\b','tuzağı')
  @('\bHesak\b','Hesap'),     @('\bhesak\b','hesap')
  @('\bYanlisi\b','Yanlışı'), @('\byanlisi\b','yanlışı')
  @('\bYanlislik\b','Yanlışlık'), @('\bDikkat\s+:\s*','Dikkat: ')
)
# 08.09 (pilot6 ölçümü: model "yillik, asagidakilerden, hesabi, dogrusu, bagli, degerleme" yazdı, KAPI-D2 üç tur yaktı): sözlük, KAPI-D2 kelime
# listesinin Türkçe karşılıklarıyla genişletildi. Her kelime için küçük ve Baş harfli iki çift; ASCII biçim Türkçe'den türetilir (İ→I, ş→s…).
$YAZIM_TR=@('için','değil','değildir','günü','şirket','şirketi','işletme','işletmenin','işletmesi','dönem','dönemin','dönemi','üretim','bütün','doğru','doğrusu','yanlış','yanlıştır','ücret','ücreti','ölçüm','hesabı','hesabına','karşılık','karşılığı','müşteri','satış','satışlar','satışları','alış','ödeme','ödemesi','yükümlülük','özkaynak','özkaynaklar','dönen','büyük','küçük','yıl','yılında','yılının','yüzde','değer','değeri','değerleme','sayı','işçi','işçilik','süreç','süre','geçerli','geçmiş','dağıtım','dağıtımı','oluşan','oluşur','bağlı','bağımsız','yönetim','yönetimi','denetçi','düşük','yüksek','artış','azalış','gerçekleşen','gerçek','ağırlıklı','müşavir','müdür','kayıt','kaydı','kayıtları','birikmiş','ödenmiş','ödenecek','verilmiş','alınmış','bağış','taşıt','taşıtlar','demirbaş','demirbaşlar','özel','doğrudan','günlük','aylık','yıllık','tüketim','ürün','ürünler','üretilen','çıkardığı','çıkarmış','başladığı','zararı','tutarı','tutarında','aşağıdakilerden','yapılan','yapılmış','edilmiş','içinde','üzerinden','önce','itibarıyla')
function AsciiBicim([string]$w){ ($w -creplace 'İ','I' -creplace 'ı','i' -creplace 'ğ','g' -creplace 'Ğ','G' -creplace 'ü','u' -creplace 'Ü','U' -creplace 'ş','s' -creplace 'Ş','S' -creplace 'ö','o' -creplace 'Ö','O' -creplace 'ç','c' -creplace 'Ç','C') }
# DİKKAT: PS'te $w ile $W AYNI değişkendir (08.09'da 'İşletme' yerine 'Işletme' üretti) → baş harfli biçim ayrı ada ($bas) yazılır; 'i' → 'İ' ordinal kontrolle.
foreach($w in $YAZIM_TR){ $a=AsciiBicim $w; if($a -eq $w){ continue }; $YAZIM_DUZELT+=,@(('\b'+[regex]::Escape($a)+'\b'),$w)
  $bas=$(if($w.StartsWith('i',[StringComparison]::Ordinal)){ 'İ'+$w.Substring(1) } else { $w.Substring(0,1).ToUpperInvariant()+$w.Substring(1) }); $basA=AsciiBicim $bas; $YAZIM_DUZELT+=,@(('\b'+[regex]::Escape($basA)+'\b'),$bas) }
function YazimOnar([string]$metin){
  if(-not $metin){ return $metin }
  $t=$metin
  foreach($cift in $YAZIM_DUZELT){
    $t=[regex]::Replace($t,$cift[0],$cift[1],[Text.RegularExpressions.RegexOptions]::None)
  }
  return $t
}
# yanlis siklarda tekrarlanan "Ne soruluyor:" cumlesini kirp (olculdu: 16/30 soruda
# bes sik ayni cumleyle basliyordu - ogrenci ayni satiri bes kez okuyordu)
function TekrarKirp([string]$metin,[bool]$dogruSik){
  if($dogruSik -or -not $metin){ return $metin }
  $t=[regex]::Replace($metin,'^\s*Ne soruluyor:.*?(?=(Kural:|[A-ZÇĞİÖŞÜ][^:]{2,40}\s*Tuza[ğg][ıi]:))','',[Text.RegularExpressions.RegexOptions]::Singleline)
  return $t.Trim()
}

# --- DERS PROFILI (01.09 Cem: "Excel'de ders ders gonderdim") ----------------
# Resmi ders tanimi veri/ders-profili.json'dan okunur (2-DERSLER sekmesi kokenli).
$DERS_TARIF=''; $KOMSULAR=''
$profYol=Join-Path $kok 'veri\ders-profili.json'
if(Test-Path $profYol){
  $prof=Get-Content $profYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $svTam=@($prof.sinavlar.PSObject.Properties.Name | Where-Object { $_ -match [regex]::Escape($Sinav) }) | Select-Object -First 1
  if($svTam){
    $dAd=@($prof.sinavlar.$svTam.PSObject.Properties.Name | Where-Object { $_ -match $DersRegex }) | Select-Object -First 1
    if($dAd){
      $dp=$prof.sinavlar.$svTam.$dAd
      if($dp.kapsam_tarifi){ $DERS_TARIF="$($dp.kapsam_tarifi)" }
      $KOMSULAR=(@($dp.komsu_dersler) -join ', ')
      "ders profili: $svTam / $dAd | tarif: $($DERS_TARIF.Length) kr | komsu: $(@($dp.komsu_dersler).Count) ders"
    }
  }
}

# --- KONULAR: kopruden en cok cikan (tekil) ---------------------------------
$tam=Get-Content (Join-Path $kok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$adaylar=@($tam | Where-Object { $_.sinav -eq $Sinav -and ("$($_.bizim_ders)$($_.arsiv_ders)" -match $DersRegex) -and $_.donem -ge 1 } | Sort-Object donem -Descending)
# 03.09 (Cem "bir ve ikiyi yap" -> 1): AGIR BOSLUK partisi. Konu listesi DOSYADAN verilir
# (json dizi: konu adlari); ders suzgeci yalniz PROFIL secimi icin kalir, konu secimi listeden.
# Neden: bosluk konularinin bizim_ders'i bos (bizde yok), arsiv etiketi 'Hukuk' gibi genis;
# ders ancak dayanagin kanunundan bilinir - o esleme disarida yapilip listeye yazilir.
# ⛔⭐ 12.09.2026 — SESSIZ DUSUS KAPATILDI. Onceki kosul `if($KonuDosya -and
#    (Test-Path $KonuDosya))` idi: yol VERILMIS ama YOKSA blok sessizce atlanir,
#    parti konu listesini hic gormeden BASKA bir secimle uretirdi. Yesil kosu,
#    yanlis sorular, odenmis para. Bulutta bu kesin olurdu: planlar konuDosya'yi
#    "C:\Users\cemdi\..." diye mutlak yaziyor, runner'da o yol yok (688 soruluk
#    plan-siklik-tum.json'un 126 partisinin TAMAMI boyleydi).
#    Kural: yol istendiyse ya CALISIR ya DURUR. Esi motor/kalip-kosucu.ps1'de.
if($KonuDosya -and -not (Test-Path $KonuDosya)){
  throw "KONU DOSYASI YOK: '$KonuDosya' - konu listesi istendi ama dosya bulunamadi. Sessizce baska konularla uretmektense DURULUYOR. (Plan gorece yol kullanmali: veri/sinav/konu/<etiket>.json)"
}
if($KonuDosya){
  # PS 5.1: ConvertFrom-Json JSON dizisini TEK nesne olarak verir; boru ile "$_" yapinca
  # butun liste tek metin olur ("istenen 1" - 03.09 ilk kosu boyle 0 aday secti). foreach ile acilir.
  $istenenListe=New-Object System.Collections.Generic.List[string]
  # 05.09: köprü konu adları ASCII ("sapmasi"), konu dosyası Türkçe ("sapması") → eşleşmiyor, konu sentezleniyor ve dönem 1'e
  # düşüyordu (kalıp-1 sorusu "1 dönemde çıktı" rozeti aldı, gerçek 3). Karşılaştırma Türkçe harf katlanarak yapılır.
  foreach($x in @((Get-Content $KonuDosya -Raw -Encoding UTF8 | ConvertFrom-Json))){ $istenenListe.Add((Katla2 "$x")) }
  $istenen=$istenenListe.ToArray()
  $adaylar=@($tam | Where-Object { $_.sinav -eq $Sinav -and ($istenen -contains (Katla2 "$($_.konu)")) } | Sort-Object donem -Descending)
  "konu dosyasi: $KonuDosya -> $($adaylar.Count) aday (istenen $($istenen.Count))"
  # 03.09 SPL: cikmis arsivi yok (SPL yayimlamiyor), kopru kaydi yok -> konu dosyasindaki adlar
  # (SPL resmi alt-konu listesi, ders-profili resmi_alt_konular) dogrudan aday olur; dayanak bos,
  # kaynak DERS_KANUN kanun-ici aramasiyla bulunur. Kopru kaydi olmayan her sinav icin gecerli.
  if($adaylar.Count -lt $istenen.Count){
    $eksikler=@($istenen | Where-Object { $k=$_; -not ($adaylar | Where-Object { (Katla2 "$($_.konu)") -eq $k }) })
    $sentez=New-Object System.Collections.Generic.List[object]
    foreach($ek in $eksikler){ $sentez.Add([pscustomobject]@{ sinav=$Sinav; konu=$ek; bizim_ders=''; arsiv_ders=''; bizim=0; cikmis=0; durum='LISTEDEN (kopru kaydi yok)'; dayanak=''; cikmis_dayanak=''; guc=''; donem=1; dayanak_anahtar=''; cikmis_dayanak_anahtar='' }) }
    if($sentez.Count){ $adaylar=@($adaylar)+$sentez.ToArray(); "  kopru disi sentez: $($sentez.Count) konu (SPL resmi alt-konu listesi gibi)" }
  }
}
$gorulen=@{}; $KONULAR=New-Object System.Collections.Generic.List[object]; $sira=0
foreach($a in $adaylar){
  $kAd="$($a.konu)".ToLowerInvariant()
  if($KonuDisla -and $kAd -match $KonuDisla){ continue }
  if($gorulen[$kAd]){ continue }
  $gorulen[$kAd]=1; $sira++
  $KONULAR.Add(@{ id=('kp-{0:d2}' -f $sira); kayit=$a })
  # 07.09 parti-30 dersi: pencere açıkken kesme YOK — önce bütün adaylar son N dönem sayısına göre sıralanır, ilk Adet ondan sonra alınır
  # (eski hâl: ilk Adet konu toplam döneme göre alınıp pencere yalnız onların içinde sıralıyordu → "sermaye artırımı 2 kez" 1. sıraya çıktı)
  if($KONULAR.Count -ge $Adet -and $DonemPencere -le 0){ break }
  if($KONULAR.Count -ge 400){ break }
}
"konu secildi: $($KONULAR.Count) (kopruden, donem-sirali tekil)"

# --- K10 DÖNEM PENCERESİ (06.09 Cem: "soru kalıplarında o kadar geriye gitmeye gerek yok, yeni sınav kalıplarını almak lazım") ---
# Köprüdeki 'donem' 2015'ten beri TOPLAM dönem sayısıdır; on yıl önce çıkıp düşen konuyu üste taşır. Pencere açıkken her konu için
# SON N dönemin etiket dosyasından (veri/<sinav>-analiz.json, donemler[].konuSayim) "kaç dönemde geçti" sayılır. Etiketler ince ve
# tutarsız ("safha maliyet esdeger birim" / "safha maliyeti esdeger birim") → eşleşme kök-önekiyle (5 harf) + küçük eş anlam haritası.
# Ölçüm 06.09: birebir etiket eşleşmesiyle 'evre maliyet sistemi' son 7 dönemde 0 görünüyordu, oysa her dönem soruluyor.
$CAPA=@{}; $SON_DONEM_SAYI=@{}; $CAPA_TIP=@{}   # 06.09 fmuh-k10 dersi: çapa teori sorusuyken model hesap sorusu yazdı → çapanın tipi soru tipini belirler
# 06.09 KAPI-K (Cem "anormal düzeltme maliyeti anlamlı gelmedi"): pencerenin gerçek kitapçıklarından KÖK SÖZLÜĞÜ (5 harf önek, ≥5 harfli kelimeler).
# Ölçüm: 2023/3'ün 8 Maliyet sorusu bu sözlüğe göre 0-2 eksik kök veriyor (imalat, tonluk gibi); K10 ile basılan soru "anorm" + "alisl" verdi ve
# kaynak paketine "Teori Notu - kusurlu ve bozuk mamul" girmişti. Sözlük iki yerde kullanılır: (1) AmbarCek teori notu süzgeci, (2) FAZ A gövde kapısı.
$script:PENCERE_KOK=$null
function PencereKavram([string]$metin,[switch]$YalnizDar){
  if(-not $script:PENCERE_KOK -or -not $script:PENCERE_KOK.Keys.Count){ return @() }
  $sayim=@{}; $kelime=@{}
  # 08.09 Tur 1 ölçümü (4 parçada 200+ sahte tekrar): Katla2 Türkçe harfi tam katlamıyor, '[^a-z ]' Türkçe harfte kelimeyi BÖLÜYORDU →
  # "çerçevesinde" → "evesinde", "gösterilip" → "sterilip", "müzakerelerin" → "zakerelerin" pencere dışı sayıldı. Önce tam ASCII katlama.
  $duz=("$metin" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant()
  foreach($w in ($duz -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -lt 6){ continue }; $on=$w.Substring(0,5); if(-not $sayim.ContainsKey($on)){ $sayim[$on]=0; $kelime[$on]=$w }; $sayim[$on]++ }
  $eksik=@{}
  foreach($on in $sayim.Keys){
    if($YalnizDar){ $sz=$(if($script:PENCERE_KOK_DAR){ $script:PENCERE_KOK_DAR } else { $script:PENCERE_KOK }); if(-not $sz.ContainsKey($on)){ $eksik[$kelime[$on]]=1 }; continue }
    if(-not $script:PENCERE_KOK.ContainsKey($on)){ $eksik[$kelime[$on]]=1; continue }                                   # geniş sözlükte yok → kusur
    if($script:PENCERE_KOK_DAR -and -not $script:PENCERE_KOK_DAR.ContainsKey($on) -and $sayim[$on] -ge 2){ $eksik[$kelime[$on]]=1 }   # dar sözlükte yok ve ≥2 kez → kusur
  }
  return @($eksik.Keys | Sort-Object)
}
function KokOnek([string]$s){ $t=(Katla2 $s) -replace '[^a-z0-9 ]',' '; $es=@{ 'evre'='safha'; 'gug'='genel'; 'ilk'='ilk'; 'dimm'='ilk'; 'esdeger'='esdeger' }
  @(($t -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|ile|veya|icin|bir|olan|sistemi|yontemi|sistem|yontem|hesaplama|hesabi|kaydi|kayit|analizi|analiz|orani|oran|tablosu|tablo|muhasebesi|muhasebe)$' } | ForEach-Object { $w=$_; if($es.ContainsKey($w)){ $w=$es[$w] }; if($w.Length -gt 5){ $w.Substring(0,5) } else { $w } } | Select-Object -Unique) }
if($DonemPencere -gt 0){
  $anYol=Join-Path $kok ("veri\" + $Sinav.ToLowerInvariant() + "-analiz.json")
  if(-not (Test-Path $anYol)){ "PENCERE: $anYol yok - pencere uygulanamadi (olculmedi)" }
  else {
    $anJ=Get-Content $anYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $dList=New-Object System.Collections.Generic.List[object]; $anJ.donemler | ForEach-Object { $dList.Add($_) }
    $sonD=@($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $DonemPencere)
    $etiketDonem=@{}   # etiket kökleri -> dönem kümesi
    foreach($dn in $sonD){ foreach($p in @($dn.konuSayim.PSObject.Properties)){ $lab=($p.Name -replace '^[^|]*\|',''); $k=(KokOnek $lab) -join ' '; if(-not $etiketDonem.ContainsKey($k)){ $etiketDonem[$k]=@{} }; $etiketDonem[$k]["$($dn.donem)"]=1 } }
    "PENCERE: son $DonemPencere donem = $(($sonD | ForEach-Object { $_.donem }) -join ', ') · $($etiketDonem.Count) etiket"
    $yeniK=New-Object System.Collections.Generic.List[object]
    # 07.09 Ö63 (A kovası 7): GENEL kökler tek başına eşleşme kurmaz ("gelir" her gelir etiketine, "vergi" her vergi etiketine uyup pencere
    # sayısını şişiriyordu: gelir tablosu toplam 2 dönemken pencerede 7). Konunun ÖZGÜL kökleri alınır; hepsi genelse genel köklerle ≥2 aranır.
    $GENEL_KOK=@('gelir','gider','vergi','kurum','serma','maliy','kayit','kayd','hesap','oran','tablo','anali','sirke','kanun','madde','genel','uygul','islem','sorum','sure','hukuk','denet','stand','finan','ticar','borc','alaca','deger','yonte','ilke','kavra','bilan','sonuc','donem','yil')
    function OzgulKok([string]$konu){ $k=@(KokOnek $konu); $s=@($k | Where-Object { $GENEL_KOK -notcontains $_ }); if($s.Count -ge 1){ return $s }; return $k }
    foreach($kk in $KONULAR){
      $kokler=@(OzgulKok "$($kk.kayit.konu)"); $dset=@{}
      foreach($et in $etiketDonem.Keys){ $etK=$et -split ' '; $ortak=@($kokler | Where-Object { $etK -contains $_ }).Count; $gerek=[Math]::Min(2,$kokler.Count); if($kokler.Count -ge 1 -and $ortak -ge $gerek){ foreach($d in $etiketDonem[$et].Keys){ $dset[$d]=1 } } }
      $SON_DONEM_SAYI[$kk.id]=$dset.Count
      $kk.kayit | Add-Member -NotePropertyName son_donem -NotePropertyValue $dset.Count -Force
      $yeniK.Add($kk)
    }
    # 07.09 A kovası 8: KONU LİSTESİ KALICI — seçim bir kez yapılır ve veri/fabrika/konu-secim-<etiket>.json'a yazılır; sonraki koşular
    # (yenileme, pilot, ek faz) aynı listeyi okur. Analiz/köprü robotu değişse önbellek (kp-NN) kaymaz. -KonuYenile yeniden seçer.
    $secimYol=Join-Path $kok ("veri\fabrika\konu-secim-" + $Etiket + ".json")
    $secimYuklendi=$false
    # Eskiden basılmış parti (önbellekte soru var) ama listesi yok: liste ÖNBELLEKTEN türetilir, yeniden seçilmez (07.09 testi: seçim kaydı,
    # kp-06 "faaliyet kârı" iken listeye "alacak senedi kaydı" yazıldı). Önbellek = gerçek; liste ona uydurulur.
    $cacheYolK=Join-Path $kok ("veri\fabrika\kalip-parti-" + $Etiket + ".json")
    if(-not $KonuDosya -and -not $KonuYenile -and -not (Test-Path $secimYol) -and (Test-Path $cacheYolK)){
      try{ $cj=ConvertFrom-Json -InputObject (Get-Content $cacheYolK -Raw -Encoding UTF8); $liste=@()
        foreach($p in ($cj.PSObject.Properties | Sort-Object Name)){ $v=$p.Value; if($v -and $v.PSObject.Properties['konu'] -and "$($v.konu)"){ $liste+=[pscustomobject]@{ id=$p.Name; konu="$($v.konu)"; donem=$(if($v.PSObject.Properties['donem']){ [int]$v.donem } else { 0 }); son_donem=$(if($v.PSObject.Properties['son_donem']){ [int]$v.son_donem } else { 0 }); secim='önbellekten türetildi ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') } } }
        if($liste.Count){ [IO.File]::WriteAllText($secimYol,(ConvertTo-Json -InputObject @($liste) -Depth 3),[Text.UTF8Encoding]::new($false)); "  KONU LİSTESİ önbellekten türetildi ($($liste.Count) konu): $secimYol" } }catch{ "  KONU LİSTESİ önbellekten türetilemedi: $($_.Exception.Message)" }
    }
    if(-not $KonuDosya -and -not $KonuYenile -and (Test-Path $secimYol)){
      try{ $sec=@(ConvertFrom-Json -InputObject (Get-Content $secimYol -Raw -Encoding UTF8)); if($sec.Count -eq 1 -and $sec[0].PSObject.Properties['SyncRoot']){ $sec=@($sec[0].SyncRoot) }
        $havuz=@{}; foreach($kk in $yeniK){ $havuz[(Katla2 "$($kk.kayit.konu)")]=$kk }
        $yeniL=New-Object System.Collections.Generic.List[object]; $eksik=@()
        foreach($s in $sec){ $ka=Katla2 "$($s.konu)"; if($havuz.ContainsKey($ka)){ $kk=$havuz[$ka]; $kk.id="$($s.id)"; $yeniL.Add($kk) } else { $eksik+="$($s.konu)" } }
        if($yeniL.Count -and -not $eksik.Count){ $KONULAR=$yeniL; $secimYuklendi=$true; "  KONU LİSTESİ dosyadan: $secimYol ($($yeniL.Count) konu; yeniden seçim yok)" }
        else { "  KONU LİSTESİ dosyası eşleşmedi ($($eksik -join ', ')) -> yeniden seçiliyor" } }catch{ "  KONU LİSTESİ dosyası okunamadı -> yeniden seçiliyor" }
    }
    # konu dosyası verilmişse liste Cem'in listesidir, süzülmez; verilmemişse pencerede 0 olan konu düşer, sıralama pencere sayısına göre
    if(-not $KonuDosya -and -not $secimYuklendi){
      $sirali=@($yeniK | Where-Object { $SON_DONEM_SAYI[$_.id] -ge 1 } | Sort-Object { -$SON_DONEM_SAYI[$_.id] }, { -[int]$_.kayit.donem })
      # 07.09 A kovası 7: KONU TEKİLLEŞTİRME — yakın adlar tek konu (MTA'da "cari oran analizi / cari oran hesaplama / cari oran" üçü seçilmişti,
      # İş-SGK'da iki "sendika üyeliği"). Özgül kökleri seçilmiş bir konuyla ≥min(2,kök) ortak olan aday atlanır (loga yazılır).
      $KONULAR=New-Object System.Collections.Generic.List[object]; $secKok=@(); $s2=0
      foreach($kk in $sirali){ if($KONULAR.Count -ge $Adet){ break }; $kz=@(OzgulKok "$($kk.kayit.konu)"); $benzer=$null
        foreach($sk in $secKok){ $ortak=@($kz | Where-Object { $sk.kok -contains $_ }).Count; if($kz.Count -ge 1 -and $ortak -ge [Math]::Min(2,$kz.Count)){ $benzer=$sk.konu; break } }
        if($benzer){ "  konu tekil: '$($kk.kayit.konu)' atlandı ('$benzer' ile aynı konu)"; continue }
        $s2++; $kk.id=('kp-{0:d2}' -f $s2); $KONULAR.Add($kk); $secKok+=@{ konu="$($kk.kayit.konu)"; kok=$kz } }
      try{ [IO.File]::WriteAllText($secimYol,(ConvertTo-Json -InputObject @($KONULAR | ForEach-Object { [pscustomobject]@{ id=$_.id; konu="$($_.kayit.konu)"; donem=[int]$_.kayit.donem; son_donem=$SON_DONEM_SAYI[$_.id]; secim=(Get-Date -Format 'yyyy-MM-dd HH:mm') } }) -Depth 3),[Text.UTF8Encoding]::new($false)); "  KONU LİSTESİ yazıldı: $secimYol" }catch{ "  KONU LİSTESİ yazılamadı: $($_.Exception.Message)" }
    }
    foreach($kk in $KONULAR){ "  pencere: $($kk.id) $($kk.kayit.konu) -> son $DonemPencere donemde $($kk.kayit.son_donem) (toplam $($kk.kayit.donem))" }   # Ö63(1): eski id anahtarı yerine kaydın kendi sayısı
    # --- Ö18 OTOMATİK ÇAPA: pencerenin gerçek kitapçıklarından konuya en yakın SORU bloğu (SGS: tam kitapçık = 'ingilizce' varyantı; Maliyet 57–64 ölçüldü)
    if($Sinav -eq 'SGS' -and -not $OrnekDosya){
      # 09.09 ÖLÇÜLDÜ (2026/2 kitapçığı soru soru okundu; yönerge 6.2 sayımlarıyla birebir: 7+8+5+10 | 26+8+8+16 | 6+6+6+6+6+6+6 = 130):
      # Türkçe 1–7 · Matematik 8–15 · İnkılap 16–20 · Yabancı Dil 21–30 · FMuh 31–56 · Maliyet 57–64 · MTA 65–72 · Denetim 73–88 · Ekonomi 89–94 ·
      # Maliye 95–100 · Meslek 101–106 · İş-SGK 107–112 · Vergi 113–118 · Ticaret 119–124 · Borçlar 125–130. Sıralı liste: 'Maliyet' 'Maliye'den önce sınanır.
      $DERS_ARALIK=@(
        @('Turkce|Türkçe',@(1,7)),@('Matematik',@(8,15)),@('Ataturk|Atatürk|Inkilap|İnkılap',@(16,20)),@('Yabanci Dil|Yabancı Dil|Ingilizce|İngilizce',@(21,30)),
        @('Finansal Muhasebe',@(31,56)),@('Maliyet',@(57,64)),@('Mali Tablolar',@(65,72)),@('Denetim',@(73,88)),@('Ekonomi',@(89,94)),@('Maliye',@(95,100)),
        # 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): Borçlar planının ders adı 'Borclar Hukuku|Ticaret ve Borclar' olduğu için sıralı liste ÖNCE 'Ticaret'e
        # takılıyor ve KAPI-K'nın DAR sözlüğü 119-124'ten (Ticaret Hukuku) kuruluyordu; Borçlar'ın kendi aralığı 125-130 hiç kullanılmıyordu.
        # Sonuç: 'vekalet', 'zenginlesme', 'aldatmasi' gibi dersin ÖZ kelimeleri "sınav dili dışı" sayıldı, 6 soru düştü (koşu logu gm-borclar-*-1).
        # 'Borclar|Borçlar' Ticaret'ten ÖNE alındı. Ticaret partileri DersRegex='Ticaret Hukuku' kullanıyor, o desen 'Borclar'a takılmaz (ölçüldü).
        @('Meslek',@(101,106)),@('Is ve Sosyal|İş ve Sosyal|Sosyal Guvenlik|Sosyal Güvenlik',@(107,112)),@('Vergi',@(113,118)),@('Borclar|Borçlar',@(125,130)),@('Ticaret',@(119,124))
      )
      $aralik=$null; foreach($cift in $DERS_ARALIK){ if($DersRegex -match $cift[0]){ $aralik=$cift[1]; break } }
      $bloklar=New-Object System.Collections.Generic.List[object]
      foreach($dn in $sonD){
        # ⛔ 12.09: burada `order=` YOKTU. ilike DESENI birden cok belgeye uyabilir ve
#    sirasiz limit=1 onlardan RASTGELE birini alir - ayni donem icin her kosuda
#    BASKA capa gelebilirdi, sessizce. (11.09'da ayni sinif hata '492 Harclar
#    ambarda yok' yanilgisini uretmisti.) Tuzak Nobetcisi yakaladi.
$uB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&kaynak_ad=ilike.'+[uri]::EscapeDataString("CIKMIS SINAV - SGS $($dn.donem) (%ingilizce)")+'&order=kaynak_ad.asc&limit=1'
        try{ $rB=$null; (ConvertFrom-Json (Invoke-WebRequest -Uri $uB -Headers $SB -UseBasicParsing -TimeoutSec 120).Content) | ForEach-Object { if(-not $rB){ $rB=$_ } } }catch{ $rB=$null }
        if(-not $rB){ continue }
        foreach($p in [regex]::Split("$($rB.metin)",'(?=SORU \d+:)')){ if($p -match '^SORU (\d+):'){ $no=[int]$Matches[1]; $govde=$p; $kes=$govde.IndexOf('TÜRMOB'); if($kes -gt 0){ $govde=$govde.Substring(0,$kes) }; $govde=$govde -replace '\s+',' '; $govde=$govde -replace '\s+\d+\s+(İzleyen|Diğer) sayfaya geçiniz\.?.*$','' -replace '\s+STAJA GİRİŞ SINAVI.*$','' -replace '\s+\d+\s+(İzleyen|Diğer) sayfaya geçiniz\.?\s*[A-E]?\s*$',''; $bloklar.Add([pscustomobject]@{ donem="$($dn.donem)"; no=$no; metin=$govde.Trim() }) } }
      }
      "  çapa havuzu: $($bloklar.Count) çıkmış soru bloğu ($($sonD.Count) kitapçık)"
      # KAPI-K kök sözlüğü: ders aralığı biliniyorsa (Maliyet 57–64) yalnız o aralık (dar ama dersin gerçek dili), yoksa bütün kitapçık
      # İki sözlük (06.09 ölçümü): GENİŞ = 7 kitapçığın tamamı (2023/3 gerçek Maliyet soruları 0-2 eksik verir, "anormal"ı yakalar ama "kusurlu"yu
      # Hukuk'ta geçtiği için kaçırır) · DAR = yalnız ders aralığı (292 kök; "kusurlu"yu yakalar ama gerçek sorular 0-10 eksik verir, gürültülü).
      # Kural: GENİŞ'te olmayan her kök kusur; DAR'da olmayan kök yalnız gövdede ≥2 kez geçiyorsa kusur. Kaynak süzgeci DAR ile.
      $script:PENCERE_KOK=@{}; $script:PENCERE_KOK_DAR=$(if($aralik){ @{} } else { $null })
      foreach($bl in $bloklar){ $darMi=($aralik -and $bl.no -ge $aralik[0] -and $bl.no -le $aralik[1]); foreach($w in ((Katla2 $bl.metin) -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -ge 5){ $on=$w.Substring(0,5); $script:PENCERE_KOK[$on]=1; if($darMi){ $script:PENCERE_KOK_DAR[$on]=1 } } } }
      "  kök sözlüğü: geniş $($script:PENCERE_KOK.Keys.Count) · dar $(if($script:PENCERE_KOK_DAR){ "$($script:PENCERE_KOK_DAR.Keys.Count) (soru $($aralik[0])-$($aralik[1]))" } else { 'yok' })"
      foreach($kk in $KONULAR){
        $kokler=@(KokOnek "$($kk.kayit.konu)"); $enIyi=$null; $enPuan=0
        # 06.09 ilk koşu ölçümü: "satılan mamul maliyeti" için kök isabeti 3/3 ile 2026/2 Soru 60 (standart maliyet sapması) seçildi — kökler tek tek
        # her Maliyet sorusunda geçiyor. Puan artık: kök isabeti + tam öbek (konu adı ardışık) ×3 + ikili öbek ×2; eşitlikte uzun gövde.
        $konuKat=(Katla2 "$($kk.kayit.konu)") -replace '\s+',' '; $ikili=@(); $kw=@($konuKat -split ' ' | Where-Object { $_.Length -ge 3 }); for($q=0;$q -lt $kw.Count-1;$q++){ $ikili+=("$($kw[$q]) $($kw[$q+1])") }
        foreach($bl in $bloklar){ if($aralik -and ($bl.no -lt $aralik[0] -or $bl.no -gt $aralik[1])){ continue }; $gk=(Katla2 $bl.metin) -replace '\s+',' '
          $puan=@($kokler | Where-Object { $gk -match ('\b'+[regex]::Escape($_)) }).Count
          if($konuKat.Length -ge 6 -and $gk -match [regex]::Escape($konuKat)){ $puan+=3 }
          foreach($ik in $ikili){ if($gk -match [regex]::Escape($ik)){ $puan+=2 } }
          if($puan -gt $enPuan -or ($puan -eq $enPuan -and $enIyi -and $bl.metin.Length -gt $enIyi.metin.Length)){ $enPuan=$puan; $enIyi=$bl } }
        if($enIyi -and $enPuan -ge [Math]::Min(2,$kokler.Count)){ $CAPA[$kk.id]=($enIyi.metin -replace '^SORU \d+:\s*','')
          # çapanın tipi: gövdede "kaç" ya da ≥3 tutar → hesaplama; yevmiye satırı (3 haneli kod + HS/hesabı) → kayıt; yoksa teori. Soru bu tiple istenir.
          $cg=$CAPA[$kk.id]; $sayiN=@([regex]::Matches($cg,'\d{1,3}(?:\.\d{3})+|\b\d{2,}\b')).Count
          $CAPA_TIP[$kk.id]=$(if($cg -match '(?i)\bkaç\b' -or $sayiN -ge 3){ 'hesaplama' } elseif($cg -match '(?i)\b[1-7]\d{2}\s+[A-ZÇĞİÖŞÜ][^\n]{2,40}(HS\.?|hesabı)'){ 'kayit' } else { 'teori' })
          $kk.kayit | Add-Member -NotePropertyName capa_kaynak -NotePropertyValue "SGS $($enIyi.donem) Soru $($enIyi.no)" -Force; "  çapa: $($kk.id) <- SGS $($enIyi.donem) Soru $($enIyi.no) ($($CAPA[$kk.id].Length) kr, kök isabeti $enPuan/$($kokler.Count), tip $($CAPA_TIP[$kk.id]))" }
        elseif($aralik){
          # 09.09 genel kültür ölçümü (Matematik 15/39, Yabancı Dil 10/37 çapa): konu adı gövdede geçmiyor (formül / İngilizce metin) → kelime
          # eşleşmesi çalışmaz. Ders aralığı biliniyorsa DERSİN kendi çıkmış sorularından biri konu sırasına göre dönüşümlü çapa olur: biçim, uzunluk
          # ve dil dersin gerçek sınav diliyle gelir (matematikte formül soruları, İngilizcede boşluk doldurma). Konu-isabet yoktur, etikette görülür.
          $havuz=@($bloklar | Where-Object { $_.no -ge $aralik[0] -and $_.no -le $aralik[1] } | Sort-Object { $_.donem },{ $_.no })
          if($havuz.Count){
            $sira=[int](($kk.id -replace '\D','')); $sec=$havuz[$sira % $havuz.Count]
            $CAPA[$kk.id]=($sec.metin -replace '^SORU \d+:\s*',''); $cg=$CAPA[$kk.id]; $sayiN=@([regex]::Matches($cg,'\d{1,3}(?:\.\d{3})+|\b\d{2,}\b')).Count
            $CAPA_TIP[$kk.id]=$(if($DersRegex -match 'Matematik' -or $cg -match '(?i)\bkaç' -or $sayiN -ge 3){ 'hesaplama' } else { 'teori' })
            $kk.kayit | Add-Member -NotePropertyName capa_kaynak -NotePropertyValue "SGS $($sec.donem) Soru $($sec.no)" -Force
            "  çapa (ders aralığından, konu isabeti yok): $($kk.id) <- SGS $($sec.donem) Soru $($sec.no) ($($cg.Length) kr, tip $($CAPA_TIP[$kk.id]))"
          } else { "  çapa: $($kk.id) ders aralığında blok yok - sabit çapa kullanılır" }
        }
        else { "  çapa: $($kk.id) pencerede eşleşen çıkmış soru YOK (kök isabeti $enPuan) - sabit çapa kullanılır" }
      }
    }
  }
}

# --- bicim capasi: onayli p90-SGS-01 ornegi ---------------------------------
$ornekSoru=''
try{
  foreach($sat in (Get-Content (Join-Path $kok 'veri\fabrika\sik90-sonuc.jsonl') -Encoding UTF8)){
    if($sat -match 'p90-SGS-01-'){
      $r=$sat|ConvertFrom-Json
      $e=Coz ((@($r.result.message.content)|? { $_.type -eq 'text' }|Select-Object -Last 1).text)
      if($e -and $e.soru){ $ornekSoru="$($e.soru)`nA) $($e.siklar.A)`nB) $($e.siklar.B)`nC) $($e.siklar.C)`nD) $($e.siklar.D)`nE) $($e.siklar.E)"; break }
    }
  }
}catch{}
# ⛔ BULUT YEDEĞİ (12.09.2026): yukarıdaki kaynak `veri/fabrika/sik90-sonuc.jsonl`
#    (823 KB) ve o klasör .gitignore'da — GitHub Actions'ta o dosya YOKTUR.
#    Ölçüldü: bulut üretiminde biçim çapası BOŞ kalırdı ve soru biçimi sınavdan
#    sapardı; sessizce, hata vermeden. Çapanın kendisi TEK bir onaylı sorudur
#    (p90-SGS-01, ortak maliyet/katsayı), 568 karakter — dosyaya çıkarıldı ve
#    depoya konuldu. Kendi onayladığımız örnek olduğu için public depoda durması
#    sakıncasız; ham parti çıktısı (denetlenmemiş soru) YİNE depoya girmiyor.
if(-not $ornekSoru){
  $capaYol=Join-Path $kok 'veri\sgs-bicim-capasi.txt'
  if(Test-Path $capaYol){
    $ornekSoru=[IO.File]::ReadAllText($capaYol,[Text.Encoding]::UTF8).Trim()
    "biçim çapası YEDEK dosyadan: veri/sgs-bicim-capasi.txt ($($ornekSoru.Length) kr)"
  }
}
# 05.09 (kalıp-3 pilotu, Cem "sınavda sorulma şekli neyse o"): çapa tek sabit Finansal örneğiydi; konunun gerçek çıkmış sorusu
# dosyadan verilebilir. Ölçüm: 13 dönemin ortak maliyet soruları yöntemi ve politikayı işletme cümlesiyle SÖYLÜYOR, çözüm sırasını değil.
if($OrnekDosya -and (Test-Path $OrnekDosya)){ $ornekSoru=[IO.File]::ReadAllText($OrnekDosya,[Text.Encoding]::UTF8).Trim(); "biçim çapası dosyadan: $OrnekDosya ($($ornekSoru.Length) kr)" }
"bicim ornegi: $($ornekSoru.Length) kr"

# --- cache ---
$don=[ordered]@{}
if(Test-Path $CACHE){ foreach($p in (Get-Content $CACHE -Raw -Encoding UTF8|ConvertFrom-Json).PSObject.Properties){ $don[$p.Name]=$p.Value } }
"cache: $($don.Count) hazir"
function CacheYaz{ $dN=[ordered]@{}; foreach($x in ($don.Keys|Sort-Object)){ $dN[$x]=$don[$x] }; [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false)) }
# --- TOPLU İSTEK ÖN GEÇİŞİ (08.09, Cem "daha ucuza nasıl?"): her faz -Toplu ile iki geçiş koşar. 1. geçiş (ON_GECIS) yalnız istemleri toplar,
# tek partide gönderir (yarı fiyat, paralel), cevaplar TOPLU_HAZIR'a düşer. 2. geçiş normal döngüdür: ilk denemede TopluAl hazır cevabı verir,
# API çağrısı yapılmaz; kapıdan dönen tekrarlar ve tek kalan istekler anlık gider. İstem her iki geçişte AYNI koddan üretilir (sapma yok).
$script:TOPLU_HAZIR=@{}; $script:ON_GECIS=$false; $script:TOPLU_ISLER=New-Object System.Collections.Generic.List[object]
function TopluTopla([string]$id,[string]$model,$icerik,[int]$maxTok,[string]$effort=''){ $script:TOPLU_ISLER.Add(@{ id=$id; model=$model; icerik=$icerik; maxTok=$maxTok; effort=$effort }) }   # 08.09 effort: faz bazlı düşünme derinliği
function TopluGonder([string]$faz){
  $isler=@($script:TOPLU_ISLER.ToArray()); $script:TOPLU_ISLER=New-Object System.Collections.Generic.List[object]
  if(-not $script:TOPLU_HAZIR.ContainsKey($faz)){ $script:TOPLU_HAZIR[$faz]=@{} }
  # 08.09 Tur 1 dersi: koşucu yeniden başlatılınca bellekteki parti cevapları kayboluyor, ödenen parti yeniden ödeniyordu. Aynı etiket/faz için
  # daha önce gönderilmiş parti(ler) bekleyen-partiler.json'dan bulunur, bitmişse cevapları BEDAVA hasat edilir; yalnız cevabı olmayan işler gönderilir.
  # 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): hasat yalnız id ile eşleşiyordu → düzeltilmiş soru ESKİ kararını geri alıyordu (çok zor kp-05/kp-11;
  # HAKEM2 jetonu iki koşuda birebir aynı çıktı, gerekçe silinmiş ifadeleri alıntılamayı sürdürdü). Artık partiye gönderilirken yazılan
  # İÇERİK PARMAK İZİ ile karşılaştırılır: tutmuyorsa cevap ALINMAZ, iş yeniden gönderilir. Parmak izi taşımayan ESKİ kayıtlardan da
  # hasat yapılmaz (içerik doğrulanamıyor) — bu, bir kereye mahsus yeniden gönderim bedelidir, karşılığı bayat kararın imkânsızlaşmasıdır.
  try{
    $eskiler=@(Get-BekleyenPartiler "$Etiket/$faz"); $hasat=0; $hasatId=New-Object System.Collections.Generic.List[string]; $atlanan=New-Object System.Collections.Generic.List[string]
    if($eskiler.Count){ $hedefT=Get-TopluBasliklar
      foreach($ep in $eskiler){ if(-not $isler.Count){ break }
        $es=$null; try{ $es=Get-ClaudeTopluSonuc "$($ep.id)" $hedefT "$Etiket/$faz" $false }catch{ $es=$null }
        if(-not $es){ continue }
        $pm=$(if($ep.PSObject.Properties['parmak']){ $ep.parmak } else { $null })
        $kalan=New-Object System.Collections.Generic.List[object]
        foreach($is in $isler){ $iid="$($is.id)"
          $uyum=$false
          if($pm -and $pm.PSObject.Properties[$iid]){ $uyum = ("$($pm.$iid)" -eq (Get-IcerikParmak $is.icerik)) }
          if($es.ContainsKey($iid) -and $es[$iid] -and $uyum){ $script:TOPLU_HAZIR[$faz][$iid]=$es[$iid]; $hasat++; $hasatId.Add($iid) }
          else { if($es.ContainsKey($iid) -and $es[$iid] -and -not $uyum){ $atlanan.Add($iid) }; $kalan.Add($is) } }
        $isler=@($kalan.ToArray()) }
      if($hasat){ Write-Host "  TOPLU $faz : önceki partiden $hasat cevap BEDAVA hasat edildi ($($hasatId -join ', ')), gönderilecek $($isler.Count)" -ForegroundColor Cyan }
      if($atlanan.Count){ Write-Host "  TOPLU $faz : $($atlanan.Count) bayat cevap ATLANDI, içerik değişmiş ya da parmak izi yok ($(@($atlanan | Select-Object -Unique) -join ', ')) - yeniden gönderilecek" -ForegroundColor Yellow } }
  }catch{ Write-Host "  TOPLU $faz : eski parti hasadı atlandı ($($_.Exception.Message))" -ForegroundColor DarkYellow }
  if(-not $isler.Count){ return }
  if($isler.Count -lt 2){ if($isler.Count){ Write-Host "  TOPLU $faz : tek istek, anlık gidecek" -ForegroundColor DarkGray }; return }
  try{ $sonuc=Invoke-ClaudeToplu -Isler $isler -Etiket "$Etiket/$faz" -BeklemeDk $TopluBeklemeDk
    foreach($k in @($sonuc.Keys)){ if($k -notlike '__*'){ $script:TOPLU_HAZIR[$faz][$k]=$sonuc[$k] } }
    if($sonuc.ContainsKey('__hata') -and $sonuc['__hata'].Count){ foreach($hk in $sonuc['__hata'].Keys){ Write-Host "  TOPLU $faz hata ($hk): $($sonuc['__hata'][$hk]) → anlık denenecek" -ForegroundColor DarkYellow } }
    Write-Host "  TOPLU $faz : $($script:TOPLU_HAZIR[$faz].Count)/$($isler.Count) cevap hazır" -ForegroundColor Cyan
  }catch{ Write-Host "  TOPLU $faz gönderilemedi ($($_.Exception.Message)) → bu faz anlık koşar" -ForegroundColor Yellow }
}
function TopluAl([string]$faz,[string]$id){ if($script:TOPLU_HAZIR.ContainsKey($faz) -and $script:TOPLU_HAZIR[$faz].ContainsKey($id)){ $y=$script:TOPLU_HAZIR[$faz][$id]; $script:TOPLU_HAZIR[$faz].Remove($id); return $y }; return $null }

# --- son10'dan canli: genc-dili adim istemi + css + Tablo/Sema cizdiriciler --
$son10=Get-Content (Join-Path $here 'son10-uret.ps1') -Raw -Encoding UTF8
$adimIstem=[regex]::Match($son10,"(?s)\`$adimIstem=@'(.*?)'@").Groups[1].Value
# 08.09 FAZ BAZLI DÜŞÜNME DERİNLİĞİ (pilot6 ölçümü: çıktının %76–86'sı düşünme; çıktı fiyatı girdinin 5 katı). Anlatım/yargı fazları low,
# hesap tasarımı yapan fazlar (soru A, ikiz C, kör K) medium kalır. Ortam değişkeni MEVZUAT_EFFORT_ADIM / _GIRIS / _HAKEM2 ile ezilir.
$ADIM_EFFORT=$(if($env:MEVZUAT_EFFORT_ADIM){ $env:MEVZUAT_EFFORT_ADIM } else { 'low' })
$GIRIS_EFFORT=$(if($env:MEVZUAT_EFFORT_GIRIS){ $env:MEVZUAT_EFFORT_GIRIS } else { 'low' })
$HAKEM2_EFFORT=$(if($env:MEVZUAT_EFFORT_HAKEM2){ $env:MEVZUAT_EFFORT_HAKEM2 } else { 'medium' })   # Cem 08.09 "kontrol kalitesi en üst seviyede": yargı fazları kısılmaz
$css=[regex]::Match($son10,"(?s)\`$css=@'(.*?)'@").Groups[1].Value
if($adimIstem.Length -lt 500 -or $css.Length -lt 500){ throw 'son10 sablonlari cekilemedi' }
if($Zorluk -eq 'zor'){ $adimIstem=$adimIstem.Replace('4. 5-8 adım.','4. 6-10 adım (katmanlı soru: her katman kendi adımı).') }   # 05.09 zor ayarı
if($Zorluk -eq 'cokzor'){ $adimIstem=$adimIstem.Replace('4. 5-8 adım.','4. 7-12 adım (çok katmanlı soru: her katman ve her tuzak kendi adımı; "Dahil değil" satırı zorunlu).') }
if($Zorluk -eq 'kolay'){ $adimIstem=$adimIstem.Replace('4. 5-8 adım.','4. 4-6 adım (tek kural, tek işlem; verilenler + kural + hesap + sağlama + yanlış yol).') }
Invoke-Expression ([regex]::Match($son10,'(?s)function TabloHtml.*?\n\}\r?\n').Value)
Invoke-Expression ([regex]::Match($son10,'(?s)function SemaHtml.*?\n\}\r?\n(?=\r?\n)').Value)

# --- KAPI-O KOKU ve KAPI-B BENZERLİK yardımcıları (07.09 A kovası 3 ve 5) ------------------------------------------------
# Koku izleri DİLDEDİR (19.08 kuralı): yer tutucu unvan (ABC/XYZ A.Ş.), bütün tutarların onbinlik yuvarlak olması (≥4 tutar), klişe, uzun tire, üç nokta.
# Sınav soruları da yuvarlak tutar kullanır; kapı yalnız "hepsi onbinlik" durumunu kusur sayar (bugünkü FMuh 25.000/15.000 geçer, 100.000+8.000+3.000 tipi düşer).
function KokuKusur($a){
  $k=@(); $govde="$($a.soru)"; $tum=$govde+' '+(@('A','B','C','D','E') | ForEach-Object { "$($a.siklar.$_)" }) -join ' '
  $acik=''; if($a.aciklama){ foreach($hh in 'A','B','C','D','E'){ $acik+=' '+(AciklamaDuz $a.aciklama.$hh) } }
  if($tum -match '(?i)\b(ABC|XYZ|DEF|KLM|XY|AB)\b\s*(A\.?\s?Ş\.?|Ltd|Ticaret|İşletme|Şirket|San\.|A\.S\.)'){ $k+='yer tutucu unvan (ABC/XYZ)' }
  elseif($govde -match '(?i)\bABC\b|\bXYZ\b'){ $k+='yer tutucu ad (ABC/XYZ)' }
  $tutar=@([regex]::Matches($govde,'(?<![\d.,])\d{1,3}(?:\.\d{3})+(?![\d.,])') | ForEach-Object { [long]($_.Value -replace '\.','') })
  if($tutar.Count -ge 4 -and -not @($tutar | Where-Object { $_ % 10000 -ne 0 }).Count){ $k+="tutarların hepsi onbinlik yuvarlak ($($tutar.Count) tutar)" }
  foreach($kl in @('önem arz et','bu bağlamda','göz önünde bulundur','unutulmamalıdır ki','dikkat edilmesi gereken','söz konusu olduğunda','bu doğrultuda')){ if(($govde+' '+$acik) -match ('(?i)'+[regex]::Escape($kl))){ $k+="klişe '$kl'" } }
  if(($govde+' '+$acik) -match '—'){ $k+='uzun tire (—)' }
  if(($govde+' '+$acik) -match '…'){ $k+='üç nokta (…)' }
  return $k
}
# 08.09 Cem "Türkçe kelime yazmalı, borç alacak düzgün atmalı" → iki DETERMİNİSTİK kapı daha (FAZ A, sert):
# KAPI-D2 TÜRKÇE HARF: soru/şık/açıklamada ASCII kalmış sık kelime (icin, degil, isletme, yil, kar…) → yeniden. Karnedeki TurkceKusur sözlüğüyle aynı.
$ASCII_TR_A='(?i)\b(icin|degil|degildir|gunu|sirket|sirketi|isletme|isletmenin|isletmesi|donem|donemin|donemi|uretim|butun|dogru|dogrusu|yanlis|yanlistir|ucret|ucreti|olcum|hesabi|hesabina|karsilik|karsiligi|musteri|satis|satislar|satislari|alis|odeme|odemesi|yukumluluk|ozkaynak|ozkaynaklar|donen|buyuk|kucuk|yil|yilinda|yilinin|yuzde|deger|degeri|degerleme|sayi|isci|iscilik|surec|sure|gecerli|gecmis|dagitim|dagitimi|olusan|olusur|bagli|bagimsiz|yonetim|yonetimi|denetci|dusuk|yuksek|artis|azalis|gerceklesen|gercek|agirlikli|musavir|mudur|kayit|kaydi|kayitlari|birikmis|odenmis|odenecek|verilmis|alinmis|bagis|tasit|tasitlar|demirbas|demirbaslar|ozel|dogrudan|gunluk|aylik|yillik|tuketim|urun|urunler|uretilen|cikardigi|cikarmis|basladigi|zarari|tutari|tutarinda|asagidakilerden|yapilan|yapilmis|edilmis|icinde|uzerinden|once|itibariyla)\b'   # kâr/kar, fatura, iade, olan, sonra, tarihinde gibi zaten Türkçe olan kelimeler LİSTEDE YOK (sahte alarm)
function YazimOnarNesne($c){ if(-not $c){ return }
  # YD modunda soru kökü ve şıklar İngilizce → yazım sözlüğü onlara dokunmaz (yalnız Türkçe alanlar)
  $alanlar=$(if($script:YD_MOD){ @('hap','sinav_taktigi','notlandirici','dayanak') } else { @('soru','hap','sinav_taktigi','notlandirici','dayanak') })
  foreach($alan in $alanlar){ if($c.PSObject.Properties[$alan] -and $c.$alan -is [string]){ $c.$alan=YazimOnar $c.$alan } }
  foreach($hh in 'A','B','C','D','E'){
    if(-not $script:YD_MOD -and $c.siklar -and $c.siklar.PSObject.Properties[$hh] -and $c.siklar.$hh -is [string]){ $c.siklar.$hh=YazimOnar $c.siklar.$hh }
    if($c.aciklama -and $c.aciklama.PSObject.Properties[$hh]){ $v=$c.aciklama.$hh; if($v -is [string]){ $c.aciklama.$hh=YazimOnar $v } elseif($v){ foreach($p in @($v.PSObject.Properties)){ if($p.Value -is [string]){ $v.($p.Name)=YazimOnar $p.Value } } } }
    if($c.PSObject.Properties['teshis'] -and $c.teshis -and $c.teshis.PSObject.Properties[$hh] -and $c.teshis.$hh){ $t=$c.teshis.$hh; foreach($p in @($t.PSObject.Properties)){ if($p.Value -is [string]){ $t.($p.Name)=YazimOnar $p.Value } } } }
  if($c.PSObject.Properties['cozum_tablo'] -and $c.cozum_tablo -and $c.cozum_tablo.satirlar){ foreach($st in @($c.cozum_tablo.satirlar)){ if($st -and $st.Count -and $st[0] -is [string]){ $st[0]=YazimOnar $st[0] } } }
}
# 08.09 ADIM TÜRKÇE KAPISI (pilot6 karnesi: KAPI-D2 yalnız soru/şık/açıklamaya bakıyordu, adımlarda ASCII kaldı → karne 5/6 kırmızı):
# adımların formül+anlatım ve verilenler metni önce sözlükle onarılır, kalan ASCII Türkçe kelimeler kusur olarak döner (tur tekrarlatır).
function AdimTurkceKusur($adimlar,$verilen){
  $tum=''; foreach($ad in @($adimlar)){ if($ad){ foreach($alan in @('anlatim','formul')){ if($ad.PSObject.Properties[$alan] -and $ad.$alan -is [string]){ $ad.$alan=YazimOnar $ad.$alan; $tum+=' '+$ad.$alan } } } }
  foreach($v in @($verilen)){ if($v){ if($v -is [string]){ $tum+=' '+(YazimOnar $v) } else { foreach($p in @($v.PSObject.Properties)){ if($p.Value -is [string]){ $v.($p.Name)=YazimOnar $p.Value; $tum+=' '+$v.($p.Name) } } } } }
  $tumK=$tum.ToLowerInvariant()
  return @([regex]::Matches($tumK,($ASCII_TR_A -replace '^\(\?i\)','')) | ForEach-Object { $_.Value } | Select-Object -Unique)
}
# 09.09 YABANCI DİL (İNGİLİZCE) MODU — Cem "genel kültür 6 ders hattı": SGS Yabancı Dil soruları (kitapçık 21–30) İNGİLİZCE'dir. Ders adı
# Yabancı Dil ise soru kökü + şıklar İngilizce yazılır; açıklama/adım/tuzak adları Türkçe kalır. Türkçe harf kapısı (KAPI-D2) ve yazım
# onarımı yalnız Türkçe alanlara (açıklama) bakar; KAPI-K pencere sözlüğü (10 soru × 7 kitapçık = 70 İngilizce blok) İngilizce için anlamsız → kapalı.
$script:YD_MOD=[bool]($DersRegex -match 'Yabanci Dil|Yabancı Dil|Ingilizce|İngilizce')
# 09.09 pilot3 ÖLÇÜLDÜ: "TEORI - Yabanci Dil: kip fiilleri (modal verbs)" notu KAPI-K kaynak süzgecine takıldı ("fiilleri, yabanci" pencere
# sözlüğünde yok) → YD etiketleri 0 soru / kaynak borcu verdi. Pencere sözlüğü çıkmış soru GÖVDESİNDEN kurulur; genel kültür derslerinde
# (Türkçe/Matematik/YD/İnkılap/Ekonomi/Maliye) not adları bizim yazdığımız başlıklardır ve sınav gövdesiyle örtüşmez — bu derslerde
# kaynak adı süzgeci KAPALI (soru gövdesi kapısı KAPI-K ayrıca çalışır, YD'de o da kapalı).
$script:GK_DERS=[bool]($DersRegex -match 'Yabanci Dil|Yabancı Dil|Ingilizce|İngilizce|Turkce|Türkçe|Matematik|Ataturk|Atatürk|Inkilap|İnkılap|Ekonomi|Maliye')
$YD_DIL_KURAL=@'

    YABANCI DİL (İNGİLİZCE) MODU: Bu ders SGS kitapçığının 21–30. soruları gibi İNGİLİZCE yazılır. Soru kökü ve 5 şık İngilizce;
    biçimler (çıkmış kitapçıklardan): boşluk doldurma "----" ile dilbilgisi (zaman, edat, bağlaç, ilgi zamiri, edilgen yapı), kelime/anlam,
    cümle tamamlama ("Although ..., ----."), okuma parçasına dayalı soru. Şıklar kısa (1–8 kelime), tek doğru; yanlış şıklar gerçek
    dilbilgisi tuzakları (yanlış zaman, yanlış edat, özne-yüklem uyumsuzluğu, anlamca ters bağlaç). Açıklama, tuzak adları ve
    "Ne soruluyor / Kural / Doğrusu" TÜRKÇE yazılır; kural KAYNAK METNİNDEKİ (teori notu) dilbilgisi kuralından çıkar, dayanak
    alanına notun adını yaz. Türkçe harf kuralı yalnız Türkçe kısımlar içindir; İngilizce metinde Türkçe harf aranmaz.
'@
if($script:YD_MOD){ "YABANCI DİL MODU: soru+şık İngilizce, açıklama Türkçe; KAPI-D2/yazım onarımı yalnız açıklamada, KAPI-K kapalı" }
function TurkceKapisi($a){ $tum=$(if($script:YD_MOD){ '' } else { "$($a.soru) "+(@('A','B','C','D','E') | ForEach-Object { "$($a.siklar.$_)" }) -join ' ' }); if($a.aciklama){ foreach($hh in 'A','B','C','D','E'){ $tum+=' '+(AciklamaDuz $a.aciklama.$hh) } }
  # tr-TR kültüründe (?i) 'I' ile 'i'yi eşlemez ("Isletme" kaçıyordu, 08.09 öz-sınav) → metin ToLowerInvariant ile küçültülür, desen küçük harf
  $tumK=$tum.ToLowerInvariant()
  return @([regex]::Matches($tumK,($ASCII_TR_A -replace '^\(\?i\)','')) | ForEach-Object { $_.Value } | Select-Object -Unique) }
# KAPI-YD YEVMİYE DENGESİ: sema.tur='yevmiye' ise her kayıtta borç toplamı = alacak toplamı; tutar yoksa/çözülmüyorsa kusur. Ayrıca 6xx gelir hesabı
# BORÇ tarafında ya da 7xx gider hesabı ALACAK tarafında ise "yön şüpheli" (kapatma/iade kayıtlarında meşru olabilir → kusur değil, rapor + hakem2'ye not).
function YevmiyeDengeKapisi($a){ $out=@(); $sm=$(if($a.PSObject.Properties['sema']){ $a.sema } else { $null }); if(-not $sm -or "$($sm.tur)" -ne 'yevmiye'){ return @() }
  $kyt=@(); if($sm.PSObject.Properties['kayitlar'] -and $sm.kayitlar){ $kyt=@($sm.kayitlar) } elseif($sm.PSObject.Properties['ogeler'] -and $sm.ogeler){ $kyt=@(,([pscustomobject]@{ baslik=''; ogeler=$sm.ogeler })) }
  $n=0; foreach($ky in $kyt){ $n++; if(-not $ky.ogeler){ continue }; $b=0.0; $al=0.0; $bozuk=$false
    foreach($og in @($ky.ogeler.borc)){ $v=SayiCozC "$($og.tutar)"; if($null -eq $v){ $bozuk=$true } else { $b+=$v } }
    foreach($og in @($ky.ogeler.alacak)){ $v=SayiCozC "$($og.tutar)"; if($null -eq $v){ $bozuk=$true } else { $al+=$v } }
    if($bozuk){ $out+="kayıt ${n}:tutar çözülemedi"; continue }
    if([Math]::Abs($b-$al) -gt 0.51){ $out+="kayıt ${n}:borç $([math]::Round($b,2)) ≠ alacak $([math]::Round($al,2))" } }
  return $out }
function YevmiyeYonNotu($a){ $out=@(); $sm=$(if($a.PSObject.Properties['sema']){ $a.sema } else { $null }); if(-not $sm -or "$($sm.tur)" -ne 'yevmiye'){ return @() }
  $kyt=@(); if($sm.PSObject.Properties['kayitlar'] -and $sm.kayitlar){ $kyt=@($sm.kayitlar) } elseif($sm.PSObject.Properties['ogeler'] -and $sm.ogeler){ $kyt=@(,([pscustomobject]@{ ogeler=$sm.ogeler })) }
  foreach($ky in $kyt){ if(-not $ky.ogeler){ continue }; foreach($og in @($ky.ogeler.borc)){ if("$($og.hesap)" -match '^\s*6\d{2}\b'){ $out+="6xx borçta: $($og.hesap)" } }; foreach($og in @($ky.ogeler.alacak)){ if("$($og.hesap)" -match '^\s*7\d{2}\b'){ $out+="7xx alacakta: $($og.hesap)" } } }
  return $out }
function KelimeKume([string]$t){ $s=New-Object 'System.Collections.Generic.HashSet[string]'; foreach($w in ((Katla2 $t) -replace '[^a-z0-9 ]',' ' -split '\s+')){ if($w.Length -ge 4){ [void]$s.Add($w) } }; return $s }
function Jaccard($a,$b){ if(-not $a.Count -or -not $b.Count){ return 0 }; $o=0; foreach($w in $a){ if($b.Contains($w)){ $o++ } }; return [math]::Round($o / ($a.Count + $b.Count - $o),2) }
# 08.09 Cem "atladık demeyelim": benzerlik yalnız aynı etikete bakıyordu; kolay/zor/çok zor ve tur 2 AYRI etiketlerde → aynı konunun öteki
# seviyedeki/turdaki sorusu kopya çıkabilirdi. Aynı planın (etiket öneki: "sgs-t1-") bütün önbellekleri de karşılaştırma havuzuna girer.
$script:BENZER_HAVUZ=$null
function BenzerHavuz{
  if($null -ne $script:BENZER_HAVUZ){ return $script:BENZER_HAVUZ }
  $h=New-Object System.Collections.Generic.List[object]
  # 09.09 Cem "boşa aynı soruyu basmayalım" ÖLÇÜLDÜ: havuz yalnız AYNI PLAN önekini yüklüyordu ('sgs-t1' ya da 'sgs-t2'), yani Tur 2
  # soruları Tur 1'in yayınlanmış sorularıyla hiç karşılaştırılmıyordu (aynı konunun kolay hâli Tur 1'de, zor hâli Tur 2'de basılıyor).
  # Artık havuz SINAV düzeyinde: 'sgs-*' bütün etiketler (Tur 1 + Tur 2 + genel kültür + pilotlar). Bedeli yok, yalnız yerel karşılaştırma.
  $onek=$(if($Etiket -match '^([a-z]+)-'){ $Matches[1] } else { '' })
  if($onek){ foreach($f in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter "kalip-parti-$onek-*.json" -ErrorAction SilentlyContinue)){ if($f.BaseName -eq "kalip-parti-$Etiket"){ continue }
      try{ $j=ConvertFrom-Json -InputObject (Get-Content $f.FullName -Raw -Encoding UTF8); foreach($p in $j.PSObject.Properties){ if($p.Value -and $p.Value.soru){ $h.Add([pscustomobject]@{ etiket=($f.BaseName -replace '^kalip-parti-',''); id=$p.Name; konu="$($p.Value.konu)"; kume=(KelimeKume "$($p.Value.soru)") }) } } }catch{} } }
  $script:BENZER_HAVUZ=$h; if($h.Count){ Write-Host "  benzerlik havuzu: $($h.Count) soru (aynı plan, öteki etiketler)" -ForegroundColor DarkGray }
  return $h
}
function BenzerlikKusur($a,[string]$benId){
  $k=@(); $ka=KelimeKume "$($a.soru)"
  # 09.09 pilot3: matematik soruları kalıp gereği benzer kelime taşır ("f: R → R fonksiyonu … f(3) kaçtır"); çapa 159 karakterlik kısa bir
  # soru olduğunda Jaccard 0.56 çıkıyor ve gerçek kopya olmadığı hâlde kapı düşürüyordu. Genel kültür derslerinde çapa eşiği 0,72.
  $capaEsik=$(if($script:GK_DERS){ 0.72 } else { 0.55 })
  if($CAPA.ContainsKey($benId)){ $j=Jaccard $ka (KelimeKume $CAPA[$benId]); if($j -ge $capaEsik){ $k+="çapaya (çıkmış soru) fazla benziyor (Jaccard $j)" } }
  foreach($oid in @($don.Keys)){ if($oid -eq $benId){ continue }; $o=$don[$oid]; if(-not $o -or -not $o.soru){ continue }; $j=Jaccard $ka (KelimeKume "$($o.soru)"); if($j -ge 0.60){ $k+="partideki $oid ile aynı soru sayılır (Jaccard $j)" ; break } }
  foreach($h in (BenzerHavuz)){ $j=Jaccard $ka $h.kume; if($j -ge 0.60){ $k+="$($h.etiket)/$($h.id) [$($h.konu)] ile aynı soru sayılır (Jaccard $j) — başka seviye/tur, özgün senaryo gerek"; break } }
  return $k
}
# 08.09 Cem "atladık demeyelim" — KAPI-P YASAL PARAMETRE: yıla bağlı had/oran (asgari ücret, kıdem tavanı, KDV/SGK/damga oranı, gecikme zammı,
# yeniden değerleme oranı, istisna haddi) soruda geçiyorsa SAYISI da soruda verilmeli; verilmezse cevap o yılın gerçeğine bağlı kalır ve hiçbir kapı
# doğrulayamaz (SORU-BASMA-KURALLARI 3.1 / 4.1). Parametre adı geçen cümlede sayı (% ya da TL) yoksa düşer.
function ParametreKapisi($a){ $out=@(); $soru="$($a.soru)"
  $parametreler=@('asgari ücret','kıdem tazminatı tavanı','kıdem tavanı','KDV oranı','katma değer vergisi oranı','SGK prim oranı','sigorta prim oranı','işsizlik sigortası prim','damga vergisi oranı','gecikme zammı oranı','gecikme faizi oranı','yeniden değerleme oranı','istisna haddi','istisna tutarı','beyanname verme sınırı','defter tutma haddi','amortisman sınırı','fatura düzenleme sınırı','kurumlar vergisi oranı','gelir vergisi tarifesi','stopaj oranı','tevkifat oranı','asgari geçim','vergi dilimi')
  foreach($cumle in ($soru -split '(?<=[.!?;])\s+')){ foreach($pa in $parametreler){ if($cumle -match ('(?i)'+[regex]::Escape($pa))){ if($cumle -notmatch '%\s*\d|\d\s*%|\d{1,3}(\.\d{3})+|\d+(,\d+)?\s*TL'){ $out+="'$pa' geçiyor ama cümlede sayısı yok (yıla bağlı had soruda verilir)" } } } }
  return @($out | Select-Object -Unique)
}
# 08.09 Cem: "yanlışlıkla eski kanuna bakıyordur, o kanun değişmiştir, onun kontrolünü yapsın" — KAPI-M MÜLGA MEVZUAT / ESKİ KURUM.
# Ambar günlük aynadır: yürürlükteki metinle çelişen kural hakemde düşer. Açık kalan delik: mülga kanunun/standardın metni ambarda HİÇ YOK
# (6762, 818, 5422, 506 ölçüldü: envanterde yok) → atıf genişletme boş kalıyor, hakem başka kaynakla EVET diyebiliyordu. Bu kapı soruda,
# şıklarda, açıklamada, dayanakta ve hapta mülga kanun numarası / mülga standart / kapanmış kurum adı arar; bulursa SERT düşer.
$MULGA_LISTE=@(
  @('\b6762\b','eski TTK 6762 (mülga) → 6102 sayılı Türk Ticaret Kanunu'),
  @('\b818\s*s(ayılı|\.)','eski Borçlar Kanunu 818 (mülga) → 6098 sayılı Türk Borçlar Kanunu'),
  @('\b5422\b','eski KVK 5422 (mülga) → 5520 sayılı Kurumlar Vergisi Kanunu'),
  @('\b506\s*s(ayılı|\.)','SSK 506 (mülga) → 5510 sayılı Kanun'),
  @('\b1479\s*s(ayılı|\.)','Bağ-Kur 1479 (mülga) → 5510 sayılı Kanun'),
  @('\b2925\s*s(ayılı|\.)|\b5434\s*s(ayılı|\.)','eski sosyal güvenlik kanunu (mülga/yürürlük dışı) → 5510'),
  @('\b2499\s*s(ayılı|\.)','eski SPKn 2499 (mülga) → 6362 sayılı Sermaye Piyasası Kanunu'),
  @('\b1050\s*s(ayılı|\.)','Muhasebe-i Umumiye K. 1050 (mülga) → 5018 sayılı Kamu Malî Yönetimi ve Kontrol Kanunu'),
  @('\b4077\s*s(ayılı|\.)','eski Tüketici K. 4077 (mülga) → 6502'),
  @('\b1086\s*s(ayılı|\.)','HUMK 1086 (mülga) → 6100 sayılı HMK'),
  @('\b743\s*s(ayılı|\.)','eski Medeni Kanun 743 (mülga) → 4721'),
  @('\b765\s*s(ayılı|\.)','eski TCK 765 (mülga) → 5237'),
  @('\b(2821|2822)\s*s(ayılı|\.)','eski Sendikalar/Toplu İş Sözleşmesi K. (mülga) → 6356'),
  @('\b4389\s*s(ayılı|\.)','eski Bankalar K. 4389 (mülga) → 5411'),
  @('\b3417\s*s(ayılı|\.)','tasarrufu teşvik 3417 (mülga)'),
  @('\bTMS\s*(11|17|18|39)\b(?!\d)','mülga standart (TMS 11→TFRS 15, TMS 17→TFRS 16, TMS 18→TFRS 15, TMS 39→TFRS 9)'),
  @('\bTFRS\s*4\b(?!\d)','mülga standart TFRS 4 → TFRS 17'),
  @('\bKKS\s*1\b','mülga KKS 1 → KYS 1'),
  @('Sosyal\s+Sigortalar\s+Kurumu|\bSSK\b|Ba[ğg]-?\s?Kur\b|Emekli\s+Sand[ıi][ğg][ıi]','kapanmış kurum (SSK/Bağ-Kur/Emekli Sandığı) → Sosyal Güvenlik Kurumu (2006)'),
  @('Türkiye\s+Muhasebe\s+Standartlar[ıi]\s+Kurulu|\bTMSK\b','kapanmış kurum TMSK → Kamu Gözetimi Kurumu (KGK)'),
  @('Sanayi\s+ve\s+Ticaret\s+Bakanl[ıi][ğg][ıi]|Gümrük\s+ve\s+Ticaret\s+Bakanl[ıi][ğg][ıi]','kapanmış bakanlık → Ticaret Bakanlığı'),
  @('Devlet\s+Planlama\s+Te[şs]kilat[ıi]|\bDPT\b','kapanmış kurum DPT → Strateji ve Bütçe Başkanlığı'),
  @('\bYTL\b|Yeni\s+Türk\s+Liras[ıi]','YTL (2009''da kaldırıldı) → TL'),
  @('Yeni\s+Türk\s+Ticaret\s+Kanunu|\bYeni\s+TTK\b|\beski\s+TTK\b|eski\s+Borçlar\s+Kanunu|\bmülga\b|yürürlükten\s+kald[ıi]r[ıi]lan','eski/yeni kanun karşılaştırması sınav dili değil; yalnız yürürlükteki kanun anılır')
)
function MulgaKapisi($a){ $out=@(); if(-not $a){ return $out }
  $tum="$($a.soru) "+((@('A','B','C','D','E') | ForEach-Object { "$($a.siklar.$_)" }) -join ' ')
  if($a.aciklama){ foreach($hh in 'A','B','C','D','E'){ $tum+=' '+(AciklamaDuz $a.aciklama.$hh) } }
  foreach($alan in @('dayanak','hap')){ if($a.PSObject.Properties[$alan] -and $a.$alan -is [string]){ $tum+=' '+$a.$alan } }
  foreach($c in $MULGA_LISTE){ if([regex]::IsMatch($tum,$c[0],'IgnoreCase, CultureInvariant')){ $out+=$c[1] } }
  # 1475 sayılı İş K.: yalnız m.14 (kıdem tazminatı) yürürlükte; kıdem bağlamı yoksa mülga sayılır
  if([regex]::IsMatch($tum,'\b1475\s*s(ayılı|\.)','IgnoreCase, CultureInvariant') -and -not [regex]::IsMatch($tum,'k[ıi]dem|m(adde)?\.?\s*14\b','IgnoreCase, CultureInvariant')){ $out+='1475 sayılı İş K. yalnız m.14 (kıdem) yürürlükte; kıdem dışı hüküm 4857''ye göre yazılır' }
  return @($out | Select-Object -Unique)
}
# "Maliye Bakanlığı" (Hazine ve Maliye Bakanlığı 2018) kanun metinlerinde hâlâ öyle geçer → sert değil, rapor notu
function MulgaNotu($a){ $t="$($a.soru) "+((@('A','B','C','D','E') | ForEach-Object { "$($a.siklar.$_)" }) -join ' '); if($t -match 'Maliye\s+Bakanl[ıi][ğg][ıi]' -and $t -notmatch 'Hazine\s+ve\s+Maliye'){ return @('"Maliye Bakanlığı" → güncel ad "Hazine ve Maliye Bakanlığı" (kanun alıntısıysa meşru)') }; return @() }
# 08.09 Cem: "eski süresi dolan verinin olmaması" — KAPI-S SÜRESİ DOLAN VERİ: geçmiş son tarih ("31.12.2025 tarihine kadar"), eski yıla
# bağlanmış had/oran ("2024 yılı yeniden değerleme oranı") sert düşer; geçici madde dayanağı hakeme GÜNCELLİK sorusu olarak gider.
function SureKapisi($a){ $out=@(); if(-not $a){ return $out }
  $tum="$($a.soru) "+((@('A','B','C','D','E') | ForEach-Object { "$($a.siklar.$_)" }) -join ' ')
  if($a.aciklama){ foreach($hh in 'A','B','C','D','E'){ $tum+=' '+(AciklamaDuz $a.aciklama.$hh) } }
  $bugun=Get-Date
  foreach($m in [regex]::Matches($tum,'\b(\d{1,2})[./](\d{1,2})[./](20\d\d)\s*(tarihine|gününe)\s*kadar')){
    try{ $d=[datetime]::new([int]$m.Groups[3].Value,[int]$m.Groups[2].Value,[int]$m.Groups[1].Value); if($d -lt $bugun.Date){ $out+="süresi dolmuş son tarih: $($m.Value)" } }catch{}
  }
  foreach($m in [regex]::Matches($tum,'\b(20[0-2]\d)\s*(y[ıi]l[ıi]n?[ıa]?(?:\s+için)?|takvim\s+y[ıi]l[ıi])\s+[^.;]{0,50}?(geçerli|asgari\s+ücret|yeniden\s+değerleme|tarife|hadd?i|s[ıi]n[ıi]r[ıi]|tavan[ıi]|oran[ıi])','IgnoreCase, CultureInvariant')){
    if([int]$m.Groups[1].Value -lt $bugun.Year){ $out+="eski yıla bağlı had/oran: '$($m.Value)' (bugün $($bugun.Year))" }
  }
  return @($out | Select-Object -Unique)
}
function GeciciMaddeNotu($a){ $t="$($a.soru) $($a.dayanak)"; $g=@([regex]::Matches($t,'ge[çc]ici\s*(madde|m\.)\s*\d+','IgnoreCase, CultureInvariant') | ForEach-Object { $_.Value } | Select-Object -Unique); return @($g) }
# --- KAPI-KV: KOK-SIK VAADI UYUMU (11.09.2026) -------------------------------
# DOGUSU: kapi turunda sgs-t1-fmuh-kolay/kp-16 dustu. Hakemin gerekcesi ZAYIFTI
# ("THP 770 taniminda 257'den bahsedilmiyor" - THP tanimlari birbirine ATIF
# YAPMAZ, kaynaktan imkansiz bir sey istemek), ama soruda BASKA ve GERCEK bir
# zayiflik vardi: kok "muhasebe KAYDI asagidakilerden hangisidir" diyor, siklar
# kaydin TEK TARAFINI veriyor. Cem'in bulduğu kp-80 de ayni aileden.
#
# OLCULDU (635 basili soru): kok TAM KAYIT vaat eden 35 soru var; bunlarin
# 14'unde (%40) dogru sikta 2'den az hesap kodu geciyor. Yani kok tam kayit
# vaat ediyor, sik yarim veriyor.
#
# KURAL: kok tam kayit vaat ediyorsa ("muhasebe kaydi", "yevmiye kaydi",
# "yapilmasi gereken kayit") dogru sikta EN AZ IKI hesap kodu bulunmali.
# Tek taraf yeterliyse kok onu sormali ("hangi hesap borclandirilir").
# ⚠ Kapi sikki degil KOK-SIK UYUMUNU denetler; iki cozumu de kabul eder:
#   ya sik tam kayda cevrilir, ya kok tek tarafi soracak sekilde yazilir.
function KokSikVaadiKapisi($c){
  if(-not $c -or -not $c.soru -or -not $c.dogru){ return @() }
  $kok="$($c.soru)"
  if($kok -notmatch '(?i)(muhasebe kayd[ıi]|yevmiye kayd[ıi]|kay[ıi]t\s+a[sş]a[gğ][ıi]dakilerden|kayd[ıi]\s+a[sş]a[gğ][ıi]dakilerden|yap[ıi]lmas[ıi] gereken kay)'){ return @() }
  $kod=@(Get-HesapKodu "$($c.siklar.$($c.dogru))")
  if($kod.Count -ge 2){ return @() }
  return @("kok TAM KAYIT vaat ediyor ama dogru sikta $($kod.Count) hesap kodu var; ya sik tam kayda cevrilsin ya kok tek tarafi sorsun")
}
# --- KAPI-KE: KONU–ETİKET ÖRTÜŞMESİ (11.09.2026) -----------------------------
# Cem: "etiketle soru farklı gelmesi hatasını sürekli yaşıyoruz. oluşmadan
# hataları temizlemek için ne yapmalıyız"
#
# NEDEN OLUŞUYORDU: `konu` FAZ A'ya bir GİRDİ olarak veriliyor ama yazıldıktan
# sonra hiçbir şey "soru gerçekten o konuyu mu ölçtü" diye geri bakmıyordu.
# Model konudan sessizce sapabiliyordu ve sapma ancak aylar sonra, ücretli bir
# turda görünüyordu.
#
# ÖLÇÜLDÜ (11.09): 636 basılı soruda ayrı bir ikinci görüş turu (₺36) 71 yanlış
# etiket buldu (%11,2) ve 71'inde de ÜRETİM HAKEMİ "EVET" demişti — yani
# hakemin konu_uyum alanı bu sınıfı görmüyor. Aynı gün sözcük düzeyi ölçüm
# (arac/konu-etiket-uyumu.ps1) 182 soruyu işaretledi ve bunların 91'i anlam
# turunda doğrulandı. Yani bu kapı üretim anında koşsaydı hataların büyük kısmı
# HİÇ OLUŞMAYACAKTI ve ücretli tura gerek kalmayacaktı.
#
# NASIL: etiketin ayırt edici kelimeleri (≥3 harf, dolgu listesi dışı) soru
# KÖKÜNDE aranır. Hiçbiri geçmiyorsa kusur → tek tur yeniden yazdırılır.
# ⚠ SERT DEĞİL, ELEYİCİ DE DEĞİL: etiket kelimeleri soruda geçmeden de doğru
#   olabilir ("duran varlık satışı" etiketi ↔ "makine satışı" sorusu — ölçüldü,
#   11.09'da elle okunan 4 vakadan biri buydu). O yüzden kapı yalnız HİÇ
#   örtüşme yoksa düşürür ve yalnız BİR tur tekrar ister; ikinci turda yine
#   düşerse soru kabul edilir ve rapora not yazılır. Amaç sapmayı azaltmak,
#   doğru soruyu öldürmek değil.
$KE_DOLGU = @('ile','icin','veya','bir','olan','gibi','hesabi','hesap','kaydi','kayit',
              'islemi','islemleri','yontemi','yontemleri','tutari','orani','oran','genel','ozel',
              'esaslari','hukumleri','turleri','sekli','sartlari','unsurlari','kavrami','tanimi',
              'hesaplama','hesaplanmasi','belirlenmesi','degerlendirmesi','uygulamasi','analizi')
function KonuEtiketKapisi($c,[string]$konu){
  if(-not $c -or -not $c.soru -or -not "$konu".Trim()){ return @() }
  $kel = @([regex]::Matches((Katla2 "$konu"),'[a-z0-9]{3,}') | ForEach-Object { $_.Value } |
           Where-Object { $KE_DOLGU -notcontains $_ } | Select-Object -Unique)
  if(-not $kel.Count){ return @() }
  $kok = Katla2 "$($c.soru)"
  $var = @($kel | Where-Object { $kok.Contains($_) }).Count
  if($var -gt 0){ return @() }
  return @("konu '$konu' kelimelerinin HİÇBİRİ soru kökünde geçmiyor ($($kel -join ', '))")
}

# --- ROL BASLIGI: SORU-URETIM-ROLU.md'nin FAZ A'ya bagli hali (11.09.2026) ---
# Cem: "Belgeyi FAZ A'ya baglayalim; {ONAYLI_HESAPLAR}, {ONAYLI_STANDARTLAR},
# {CEKIRDEK_HESAPLAR} ve {KATEGORI} alanlarini sistem otonom doldursun."
#
# ⛔ KATEGORIYI MODEL SECMEZ - dersten turetilir. Gerekce olculdu: 636 sorunun
#    71'inde konu etiketi yanlisti ve hakem 71'inde de "EVET" demisti; kendi
#    etiketini koyan model yanlis etiketi de kendi onaylar.
#
# ⚠ UC DURUMLU BEYAZ LISTE - kurulusun en kritik yeri:
#    kalip VAR + MUHURLU   -> SERT beyaz liste ("yalniz bu hesaplar")
#    kalip VAR + muhursuz  -> YOL GOSTERICI ("beklenen hesaplar sunlar")
#    kalip YOK             -> beyaz liste YAZILMAZ; yerine "yalniz kaynak
#                             paketinde gordugun hesaplari kullan" konur.
#    Ucuncusu sart: hesap-kalibi.json'da bugun 5 satir var. Korlemesine
#    baglansaydi kalibi olmayan her konuda BOS KUME olusur ve model hicbir
#    hesap kullanamayacagi icin uretim tumuyle dururdu.
$KATEGORI_DERS = @{
  'MUHASEBE VE DENETIM'  = @('finansal muhasebe','maliyet muhasebesi','mali tablolar analizi','denetim','turkiye muhasebe standartlari','turkiye denetim standartlari','muhasebe ve finansal raporlama')
  'HUKUK VE MEVZUAT'     = @('ticaret hukuku','borclar hukuku','ticaret ve borclar','vergi hukuku','meslek hukuku','is ve sosyal guvenlik hukuku','is ve sosyal guvenlik','maliye','kurumsal yonetim','sermaye piyasasi mevzuati')
  'SOZEL VE YABANCI DIL' = @('turkce','yabanci dil','ataturk ilkeleri ve inkilap tarihi','ataturk ilkeleri')
  'MATEMATIK VE SAYISAL' = @('matematik')
  'KAVRAMSAL VE TEORIK'  = @('ekonomi')
}
# 11.09 olcumu: dogru sikkinda hesap anan 64 sorunun 16'si (%25) bu hesaplari
# kullaniyor (102 Bankalar 4 soruda, 121 Alacak Senetleri 4, 770 Genel Yonetim 4).
# kp-80'in onayli kumesinde 102 YOKTU; muafiyet olmasa DOGRU soru reddedilirdi.
$CEKIRDEK_HESAPLAR = @('100','101','102','103','120','121','128','153','191','320','321','329','360','361','391','600','610','611','620','621','632','770','780')

function KategoriBul([string]$ders){
  $d=Katla2 "$ders"
  foreach($k in $KATEGORI_DERS.Keys){ foreach($x in $KATEGORI_DERS[$k]){ if($d -eq $x){ return $k } } }
  foreach($k in $KATEGORI_DERS.Keys){ foreach($x in $KATEGORI_DERS[$k]){ if($d -like "*$x*"){ return $k } } }
  return ''
}

function RolBasligi([string]$ders,[string]$konu){
  $kat=KategoriBul $ders
  if(-not $kat){ return '' }                      # kategori cozulemezse rol baslikti EKLENMEZ
  $s=New-Object System.Text.StringBuilder
  [void]$s.AppendLine("=== ROL ===")
  [void]$s.AppendLine("[KATEGORI] $kat   (bu etiket DERSTEN turetildi; DEGISTIREMEZSIN)")
  switch($kat){
    'MUHASEBE VE DENETIM' {
      [void]$s.AppendLine("Kati bir Tekduzen Hesap Plani / TMS-TFRS / Vergi uzmanisin.")
      $k=HesapKalibi $ders $konu
      $onayli=@(); if($k){ $onayli=@(@($k.dogru_hesaplar) | ForEach-Object { "$_" }) }
      if($onayli.Count -and $k -and [bool]$k.dogrulandi){
        [void]$s.AppendLine("ONAYLI HESAPLAR (YALNIZ bunlar + cekirdek): " + ($onayli -join ', '))
        [void]$s.AppendLine("Bu kume disinda hesap KULLANAMAZSIN. Yetmiyorsa uydurma:")
        [void]$s.AppendLine("  HATA: Onayli hesap kumesi yetersiz. Eksik: <hangi islem icin hangi hesap>")
      } elseif($onayli.Count){
        [void]$s.AppendLine("BEKLENEN HESAPLAR (yol gosterici, muhursuz): " + ($onayli -join ', '))
        [void]$s.AppendLine("Baska hesap kullanacaksan KAYNAK METNINDE tanimini gormus olmalisin.")
      } else {
        [void]$s.AppendLine("Bu konunun onayli hesap kumesi HENUZ YOK. Kural: YALNIZ kaynak paketinde")
        [void]$s.AppendLine("tanimini GORDUGUN hesaplari kullan; ezberinden hesap ekleme.")
      }
      [void]$s.AppendLine("CEKIRDEK HESAPLAR (her kayitta serbest): " + ($CEKIRDEK_HESAPLAR -join ', '))
      $env2=StandartEnvanteri
      if($env2.Count){
        $std=@(); foreach($on in @('BDS','TMS','TFRS','TSRS')){ if($env2.ContainsKey($on) -and $env2[$on].Count){ $std += ($on + ' ' + (($env2[$on]) -join ',')) } }
        if($std.Count){ [void]$s.AppendLine("ONAYLI STANDARTLAR (yalniz bu numaralar anilabilir): " + ($std -join ' | ')) }
      }
      [void]$s.AppendLine("KAYNAK ADLARI: TMS, TFRS, BOBI FRS, KUMI FRS, MSUGT Sira No:1 Tekduzen Hesap Plani, VUK, TTK. 'UFRS' ve 'TDHP Izahnamesi' AMBARDA YOKTUR.")
    }
    'HUKUK VE MEVZUAT' {
      [void]$s.AppendLine("Kati bir Mevzuat ve Atif Denetcisisin.")
      [void]$s.AppendLine("HESAP KODU ARAMA - bu derste hesap kodu yoklugu kusur DEGILDIR.")
      [void]$s.AppendLine("Madde numarasi HAFIZADAN yazilmaz; kaynak paketinde okudugun kunye yazilir.")
      [void]$s.AppendLine("Kurum adi yururlukteki olmali (KGK, SPK, TURMOB, TESMER, SGK); SSK ve TMSK MULGADIR.")
      [void]$s.AppendLine("Sure ve had/oran kaynaktan alinir; yila bagli tutar soruda SAYI olarak verilir.")
      [void]$s.AppendLine("Yetmiyorsa: HATA: Onayli madde kumesi yetersiz. Eksik: <hangi hukum>")
    }
    'SOZEL VE YABANCI DIL' {
      [void]$s.AppendLine("Uzman bir Dilbilimci ve Olcme-Degerlendirme Uzmanisin.")
      [void]$s.AppendLine("HESAP KODU ve KANUN MADDESI ARAMA - yoklugu kusur DEGILDIR.")
      [void]$s.AppendLine("Imla ve noktalama TDK kurallarina (yabanci dilde o dilin standardina) uyar.")
      [void]$s.AppendLine("Dil capasi Oxford/Cambridge DEGIL, BU SINAVIN cikmis sorularidir.")
    }
    'MATEMATIK VE SAYISAL' {
      [void]$s.AppendLine("Kati bir Mantik ve Islem Denetcisisin.")
      [void]$s.AppendLine("HESAP KODU ve KANUN MADDESI ARAMA - yoklugu kusur DEGILDIR.")
      [void]$s.AppendLine("Kurguyu arka planda ADIM ADIM cozerek saglamasini yap; sonuc sikla birebir tutmali.")
      [void]$s.AppendLine("Veri eksigi ('x tam sayi mi belirtilmemis') kapatilir; kok TEK buyukluk ister.")
    }
    'KAVRAMSAL VE TEORIK' {
      [void]$s.AppendLine("Uzman bir Iktisat Teorisi ve Model Denetcisisin.")
      [void]$s.AppendLine("HESAP KODU ve KANUN MADDESI ARAMA - yoklugu kusur DEGILDIR.")
      [void]$s.AppendLine("Muafiyet 'kaynaksiz yaz' DEMEK DEGILDIR: tanim ve model kaynak paketinden alinir.")
      [void]$s.AppendLine("Dogru sik TEK bir teorik tanima dayanir; 'bazi yaklasimlara gore' olmaz.")
      [void]$s.AppendLine("Sayisal kurgu varsa islem ispati sart.")
    }
  }
  [void]$s.AppendLine("ORTAK: her yanlis sik HEM kesin yanlis HEM ogrencinin gercekten yapabilecegi bir hatanin sonucu olmali.")
  [void]$s.AppendLine("=== ROL BITTI ===")
  return $s.ToString()
}
# --- KAPI-SS: STANDART SETI (11.09.2026) -------------------------------------
# Cem: "beyaz liste tek alan degil, alan kumesi"
# OLCULDU: Kategori 1 (Muhasebe ve Denetim) sorularinin %40'i hesap kodu DEGIL
# STANDART NUMARASI aniyor (449 soruda: 201 hesap kodu, 181 standart, 147 hicbiri).
# Hesap kodunda KAPI-H + KAPI-HS vardi; standart numarasinda DENGI YOKTU.
# Bu kapi, soruda anilan her BDS/TMS/TFRS/TSRS numarasinin ambarda GERCEKTEN
# bulundugunu dogrular (KAPI-H'nin kod-ad ciftini dogruladigi gibi).
#
# BUGUN 0 IHLAL: basili 636 soruda anilan 50 benzersiz standardin hepsi ambarda.
# Kapi ONLEYICI olarak kuruluyor - KAPI-HS de kp-80'e kadar hic ihlal
# bulmamisti.
#
# ⚠ ENVANTER SAYFALANARAK URETILIR. Ilk olcumumde limit=1000 ile cektim, BDS'te
#   7 numara gorundu (gercegi 37) ve "BDS 705 ambarda yok" gibi 33 SAHTE bulgu
#   cikti. Envanter arac/standart-envanteri.ps1 ile uretilir, elle yazilmaz.
$script:STD_ENV=$null
function StandartEnvanteri{
  if($null -ne $script:STD_ENV){ return $script:STD_ENV }
  $script:STD_ENV=@{}
  $sy=Join-Path $kok 'veri\standart-envanteri.json'
  if(Test-Path $sy){
    try{
      $sj=Get-Content $sy -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach($pp in $sj.numaralar.PSObject.Properties){ $script:STD_ENV[$pp.Name]=@($pp.Value | ForEach-Object { "$_" }) }
    }catch{}
  }
  return $script:STD_ENV
}
function StandartSetiKapisi($c){
  if(-not $c -or -not $c.soru){ return @() }
  $env=StandartEnvanteri
  if(-not $env.Count){ return @() }               # envanter yoksa hukum verilmez
  $m="$($c.soru) " + ((@('A','B','C','D','E') | ForEach-Object { "$($c.siklar.$_)" }) -join ' ')
  $yok=New-Object System.Collections.Generic.List[string]
  foreach($sn in (Get-StandartNo $m)){
    $on=($sn -split ' ')[0]; $no=($sn -split ' ')[1]
    if(-not $env.ContainsKey($on)){ continue }    # o onek hic yutulmamis - hukum yok
    if(-not ($env[$on] -contains $no)){ if($yok -notcontains $sn){ $yok.Add($sn) } }
  }
  if(-not $yok.Count){ return @() }
  return @("soruda anilan standart ambarda YOK: " + ($yok -join ', '))
}
# --- KAPI-HS: HESAP SETI (11.09.2026) ----------------------------------------
# Cem: "hesap setinin kurumsal dilde sorular basmadan otomatik engelleyecek
# sekilde yapabiliyor muyuz"
#
# KURAL (beyaz liste, kara liste DEGIL):
#   Dogru sikkin kullandigi HER hesap kodu, konunun ONAYLI HESAP KUMESINDE
#   (veri/hesap-kalibi.json -> dogru_hesaplar) olmak ZORUNDADIR.
#   Kumede olmayan bir hesap kullanilmissa soru REDDEDILIR.
#
# NEDEN KARA LISTE DEGIL - OLCULDU: once "tuzak hesaplari yasakla" diye kurmayi
# dusundum ve kp-80'de sinadim: o konunun kalibinda tuzaklar 243/246/520 idi,
# sorunun kullandigi 529 tuzak listesinde YOKTU - kapi YAKALAMAZDI. Beyaz liste
# ayni vakada yakaliyor: 529, onayli kume {242,245,521,501} icinde degil.
# Kara liste kimsenin aklina gelmeyen hesabi kacirir; beyaz liste kacirmaz.
#
# ⛔ SERTLIK MUHURE BAGLI - bu kasitli:
#   dogrulandi=true  -> SERT. Soru reddedilir, yeniden yazdirilir.
#   dogrulandi=false -> YUMUSAK. Yalniz hakeme uyari gider.
#   Cunku kalip su an MODEL taslagidir ve gurultu tasidigi OLCULDU (kp-80
#   konusunda dogru_hesaplar'a 242/245 girmis, 102 Bankalar hic girmemis).
#   Muhurlenmemis bir listeye karsi sert kapi, DOGRU sorulari reddederdi.
#   Yani kapiyi acan sey Cem'in muhrudur.
$script:HESAP_KALIBI=$null
function HesapKalibi([string]$ders,[string]$konu){
  if($null -eq $script:HESAP_KALIBI){
    $script:HESAP_KALIBI=@{}
    $hk=Join-Path $kok 'veri\hesap-kalibi.json'
    if(Test-Path $hk){
      try{
        $hj=Get-Content $hk -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($s in @($hj.satirlar)){ $script:HESAP_KALIBI[(Katla2 "$($s.ders)|$($s.konu)")]=$s }
      }catch{}
    }
  }
  $a=Katla2 "$ders|$konu"
  if($script:HESAP_KALIBI.ContainsKey($a)){ return $script:HESAP_KALIBI[$a] }
  return $null
}
# Dogru sikkin kullandigi hesap kodlari (kod + ardindan ad geliyorsa hesap kodudur)
function SikHesaplari($c){
  if(-not $c -or -not $c.dogru){ return @() }
  $m="$($c.siklar.$($c.dogru))"
  return @([regex]::Matches($m,'(?<!(?:BDS|TMS|TFRS|TSRS|KKS|BOBİ FRS|KÜMİ FRS|BOBI FRS|KUMI FRS)\s)(?<![\d.,])([1-7]\d{2})(?![\d.,])\s+(?=[A-ZÇĞİÖŞÜa-zçğıöşü])') |
           ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
}
function HesapSetiKapisi($c,[string]$ders,[string]$konu){
  $k=HesapKalibi $ders $konu
  if(-not $k){ return @() }
  $onayli=@(@($k.dogru_hesaplar) | ForEach-Object { "$_" })
  if(-not $onayli.Count){ return @() }          # kalip bos - hukum verilmez
  $kullanilan=@(SikHesaplari $c)
  if(-not $kullanilan.Count){ return @() }      # soru hesap anmiyor
  $disarda=@($kullanilan | Where-Object { $onayli -notcontains $_ })
  if(-not $disarda.Count){ return @() }
  $tuzakMi=@()
  foreach($d in $disarda){
    $t=@($k.tuzaklar) | Where-Object { "$($_.kod)" -eq $d } | Select-Object -First 1
    if($t){ $tuzakMi += "$d TUZAK: $($t.neden)" } else { $tuzakMi += "$d onayli kumede yok" }
  }
  return @("dogru sik onayli hesap kumesi disinda hesap kullaniyor -> " + ($tuzakMi -join ' | ') +
           " (onayli: " + ($onayli -join ',') + ")")
}
# --- KAPI-KS: KAYNAK SIRALAMA (11.09.2026) -----------------------------------
# Kaynak paketi "ilk 4" ile degil "konuyla EN ALAKALI 4" ile kurulur.
# OLCULDU (635 basili soru, bedel 0, model cagrilmadi):
#   ilk kaynak konuyla HIC ortusmuyor             : 447 soru (%70,4)
#   konuyla ortusen kaynak ilk 4'un DISINDA kalmis: 191 soru (%30,1)
#   "ilk 4" kesimiyle hic cekilmeyen kaynak       : 2.569
# Ornek (sgs-t1-denetim-cokzor/kp-12, konu "genel kabul gormus denetim
# standartlari"): ilk kaynak TTK m.398 idi; aranan "Teori Notu - genel kabul
# gormus denetim standartlari (GKGDS)" 5. siradaydi ve HIC CEKILMEDI.
# kp-80'de 521 Hisse Senedi Iptal Karlari'nin pakete hic girmemesi de bu
# ailedendir; hesap kodunu adiyla anan 92 sorunun 66'sinda (%71,7) tanimin
# pakette olmamasi buradan besleniyor olabilir.
# Siralama DETERMINISTIK: konu adinin >=4 harfli ayirt edici kelimelerinden
# kac tanesi kaynak ADINDA geciyor. Esitlikte eski sira korunur (kararli).
function KaynakSirala($adlar,[string]$konu,[int]$kac=4){
  $hepsi=@($adlar); if($hepsi.Count -le $kac){ return $hepsi }
  $kel=@([regex]::Matches((Katla2 "$konu"),'[a-z0-9]{4,}') | ForEach-Object { $_.Value } | Select-Object -Unique)
  if(-not $kel.Count){ return @($hepsi | Select-Object -First $kac) }
  $i=0
  return @($hepsi | ForEach-Object {
      $i++; $adK=Katla2 "$_"
      [pscustomobject]@{ ad=$_; puan=@($kel | Where-Object { $adK.Contains($_) }).Count; sira=$i }
    } | Sort-Object @{e='puan';d=$true},@{e='sira';d=$false} |
      Select-Object -First $kac | ForEach-Object { $_.ad })
}
# --- KAPI-KP: KAYNAK PAKETI SINIRDA KESILIR, ORTADAN DEGIL (11.09.2026) -----
# Cem: "1 yanlis cikti, nedeni ne, bir daha karsilasmamak icin nasil kaldiririz".
# OLCULDU (sgs-kapituru-11eylul/kp-01, "muhasebe bilgi sistemi", hakem HAYIR):
# paket 4.500 karakterde KOR bir Substring ile kesilmisti. Icerigi:
#     konum     0  Teori Notu - ... kontrol siniflamasi        2.113 krk  (konu disi)
#     konum 2.113  Teori Notu - ... nakit donusum dongusu      2.181 krk  (konu disi)
#     konum 4.294  TEORI - ... mizan turleri  <-- CEVABIN KAYNAGI, 206 krk sonra KESILDI
# Yani konuyla ilgisiz iki kaynak butcenin %95'ini yedi, cevabi tasiyan kaynak
# BASLIGINDAN hemen sonra koptu. "kesin mizan" ifadesi pakette yalniz BASLIKTA
# gecti. Hakem dogru davrandi: "kaynak metni kesintiye ugramis" deyip TEYITSIZ
# verdi. SORU YANLIS DEGILDI - PAKET SAKATTI.
#
# Iki kusur birden vardi, ikisi de burada kapaniyor:
#   1) SIRASIZ : paket AmbarCek'in dondurdugu ham sirayla kuruluyordu; konuyla
#      ilgi puani hic bakilmiyordu. (KaynakSirala vardi ama yalniz hakem dalinda.)
#   2) ORTADAN KESIK : sigmayan kaynak BASI birakilip govdesi atiliyordu.
#      Basligi gorunen ama govdesi olmayan kaynak, modele "bu kaynak var" diye
#      YALAN soyler - en zararli hali budur.
#
# Yeni kural: paket bloklara ayrilir, konuya gore siralanir, butce blok blok
# doldurulur; SIGMAYAN BLOK KOMPLE DUSER. Yarim blok asla kalmaz.
function PaketKirp([string]$paket,[string]$konu,[int]$tavan,[ref]$dusen){
  if(-not "$paket".Trim() -or $paket.Length -le $tavan){ return $paket }
  $bloklar=@($paket -split "`n---`n" | Where-Object { "$_".Trim() })
  if($bloklar.Count -le 1){
    # Tek blok tavani asiyorsa kesmek zorundayiz ama CUMLE sinirinda kesiyoruz,
    # kelimenin ortasinda degil; ve kesildigini modele acikca soyluyoruz.
    $k=$paket.Substring(0,$tavan); $nk=$k.LastIndexOfAny([char[]]@('.',';','!','?'))
    if($nk -gt [int]($tavan*0.5)){ $k=$k.Substring(0,$nk+1) }
    return ($k + "`n[UYARI: bu kaynak uzunlugu asdigi icin cumle sinirinda kesildi.]")
  }
  $kel=@([regex]::Matches((Katla2 "$konu"),'[a-z0-9]{4,}') | ForEach-Object { $_.Value } | Select-Object -Unique)
  $i=0
  $puanli=@($bloklar | ForEach-Object {
    $i++; $b="$_"
    $ad=''; $m=[regex]::Match($b,'^\s*\[([^\]]{1,200})\]'); if($m.Success){ $ad=$m.Groups[1].Value }
    $adK=Katla2 $ad
    $p=0; foreach($k in $kel){ if($adK.Contains($k)){ $p++ } }
    [pscustomobject]@{ blok=$b; ad=$ad; puan=$p; sira=$i }
  } | Sort-Object @{e='puan';d=$true},@{e='sira';d=$false})
  $al=New-Object System.Collections.Generic.List[object]
  $at=New-Object System.Collections.Generic.List[string]
  $boy=0
  foreach($b in $puanli){
    $ek=$b.blok.Length + 5
    if($boy+$ek -le $tavan){ $al.Add($b); $boy+=$ek }
    else { $at.Add($(if($b.ad){ $b.ad } else { "(adsiz blok #$($b.sira))" })) }
  }
  # Hicbiri sigmadiysa (tek blok bile tavandan buyuk): en ilgili blogu cumle
  # sinirinda kirpip ver - bos paket dondurmek hakemi kesin HAYIR'a surukler.
  if(-not $al.Count){
    $enIyi=$puanli[0].blok
    return (PaketKirp $enIyi $konu $tavan $dusen)
  }
  if($dusen){ $dusen.Value=@($at) }
  # Cikisti ORIJINAL sirasina geri koy: model kaynaklari okurken sira atlamasin.
  return ((@($al | Sort-Object sira | ForEach-Object { $_.blok })) -join "`n---`n")
}
# --- FAZ A: SORU ------------------------------------------------------------
# 04.09 KAPI-Ş: şık dengesi (Cem "cevap belli, sınavda böyle mi?"). Ölçüm: 7 çıkmış SGS sapma sorusunun 5'inde her tutar
# iki yönle geçiyor. Kural: yön kelimesi taşıyan şıklarda (olumlu/olumsuz/lehte/aleyhte/eksik-fazla yükleme) tutar sayısı
# ve yön çiftleri sayılır; en az 2 tutar iki yönle görünmeli, hiçbir tutar TEK BAŞINA iki yönle görünmemeli.
function SikDengesi($aday){
  if(-not $aday -or -not $aday.siklar){ return '' }
  $sik=@('A','B','C','D','E' | ForEach-Object { "$($aday.siklar.$_)" })
  $yonlu=@($sik | Where-Object { $_ -match '(?i)\b(olumlu|olumsuz|lehte|aleyhte|eksik yükleme|fazla yükleme|eksik|fazla)\b' })
  if($yonlu.Count -lt 4){ return '' }   # yön sorusu değil
  $cift=@{}
  foreach($s in $sik){ $t=[regex]::Match($s,'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?').Value; if(-not $t){ continue }
    $y=if($s -match '(?i)\b(olumlu|lehte|fazla)\b'){ '+' } elseif($s -match '(?i)\b(olumsuz|aleyhte|eksik)\b'){ '-' } else { '?' }
    if(-not $cift.ContainsKey($t)){ $cift[$t]=@{} }; $cift[$t][$y]=1 }
  $ikiYonlu=@($cift.Keys | Where-Object { $cift[$_].Count -ge 2 })
  if($cift.Count -ge 2 -and $ikiYonlu.Count -lt 2){ return "yön şıklarında $($cift.Count) tutar var, iki yönle görünen $($ikiYonlu.Count) (gerek: en az 2)" }
  if($sik -match '(?i)\b(lehte|aleyhte)\b'){ return "yön kelimesi 'lehte/aleyhte' (sınav dili: olumlu/olumsuz)" }
  return ''
}
# 04.09 GM-2: kapı diğer şık tiplerine genişledi (çıkmış şık kalıbı ölçümü: motor/celdirici-olcum.ps1).
#  (1) SAYI şıkları: beş tutar birbirinden farklı olmalı (yönsüz tekrar = cevap belli) ve küçükten büyüğe sıralı.
#  (2) CÜMLE şıkları: doğru şık en uzunsa ve medyanın 1,6 katından uzunsa "en uzun şık doğru" ele verir.
#  (3) TEK FARKLI BİÇİM: yalnız doğru şıkta birim/parantez/ondalık varsa (diğer dördünde yoksa) ele verir.
# 06.09 (Cem "geç"): SAYI ŞIKLARI ÜRETİM SONRASI SIRALANIR — çıkmışta küçükten büyüğe %57-100, bizde %0-17 (05.09 ölçümü). Model
# çağrısı yok: şıklar artan sıraya dizilir, harfler yeniden dağıtılır, dogru ve aciklama anahtarları birlikte taşınır. Yön şıkları
# (olumlu/olumsuz) 2a dengesine bağlı, dokunulmaz. sade/ikiz sonra üretilir (harfe bağlı alan bu aşamada yok).
function SikSirala($cvp){
  if(-not $cvp -or -not $cvp.siklar -or -not $cvp.dogru){ return $false }
  $harf=@('A','B','C','D','E'); $trS=[cultureinfo]::GetCultureInfo('tr-TR'); $deg=@{}
  # yalnız SAF SAYI şıkları ("80.000", "40 TL/kg", "%20"); kayıt şıkları ("654 KARŞILIK GİDERLERİ hesabı ...") hesap koduyla sıralanmaz (06.09 kalıp-5 dersi)
  foreach($h in $harf){ $s="$($cvp.siklar.$h)".Trim(); $m=[regex]::Match($s,'^%?\s*(-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?)\s*(₺|TL|%|adet|kg|saat|gün|yıl|ton|birim|TL/kg|TL/adet|TL/saat|TL/ton)?\s*$'); if(-not $m.Success){ return $false }; try{ $deg[$h]=[double]::Parse($m.Groups[1].Value,$trS) }catch{ return $false } }
  if(@($harf | Where-Object { "$($cvp.siklar.$_)" -match '(?i)\b(olumlu|olumsuz|eksik|fazla)\b' }).Count -ge 4){ return $false }
  $sira=@($harf | Sort-Object { $deg[$_] }); if(($sira -join '') -eq ($harf -join '')){ return $false }
  $yeniS=[ordered]@{}; $yeniA=[ordered]@{}; $yeniDogru=''
  for($i=0;$i -lt 5;$i++){ $eski=$sira[$i]; $yeni=$harf[$i]; $yeniS[$yeni]="$($cvp.siklar.$eski)"; if($cvp.aciklama -and $cvp.aciklama.PSObject.Properties[$eski]){ $yeniA[$yeni]=$cvp.aciklama.$eski }; if("$($cvp.dogru)" -eq $eski){ $yeniDogru=$yeni } }
  if(-not $yeniDogru){ return $false }
  $cvp.siklar=[pscustomobject]$yeniS; if($yeniA.Count){ $cvp.aciklama=[pscustomobject]$yeniA }; $cvp.dogru=$yeniDogru
  return $true
}
# 06.09 KAPI-H (Cem "bu beşi geç" #2): HESAP KODU–AD KAPISI. Şık/kayıt metninde geçen her "3 haneli kod + ad" çifti, ambardaki
# Tekdüzen Hesap Planı adıyla (kaynak_ad "THP 120 - Alıcılar") karşılaştırılır; resmî adın köklerinin yarısından fazlası kodun
# ardındaki 90 karakterde yoksa kusur. Sözlük bir kez çekilir (269 belge, bedel 0). Sonuç cache'e `hesap_kod` olarak yazılır (karne hücresi).
$script:THP_SOZLUK=$null
function ThpSozluk{
  if($script:THP_SOZLUK){ return $script:THP_SOZLUK }
  $d=@{}
  try{ $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString('THP %')+'&limit=1000'
    (ConvertFrom-Json (Invoke-WebRequest -Uri $u -Headers $SB -UseBasicParsing -TimeoutSec 120).Content) | ForEach-Object { $m=[regex]::Match("$($_.kaynak_ad)",'^THP\s+(\d{3})\s*-\s*(.+)$'); if($m.Success){ $d[$m.Groups[1].Value]=$m.Groups[2].Value.Trim() } }
  }catch{ Write-Host "  THP sözlüğü çekilemedi (KAPI-H ölçülmedi): $($_.Exception.Message)" -ForegroundColor DarkYellow }
  $script:THP_SOZLUK=$d; return $d
}
# 07.09 KAPI-Ç (Cem "kandırmacılı çok seçenekli"): hesap sorusunda her yanlış şık, üreticinin yazdığı YANLIŞ YOL formülünün sonucu olmalı.
# Kendi hesaplayıcısı var (AritmetikKusur/SayiCoz bu noktada henüz tanımlı değil): Türkçe sayı → nokta ondalık, %x → (x/100), yalnız rakam
# ve işleçten oluşan ifade Invoke-Expression ile hesaplanır, şık tutarıyla ±%0,5 kıyaslanır. Sayı olmayan (cümle/yön) şıklara uygulanmaz.
function SayiCozC([string]$s){ $t=("$s" -replace '[^\d\.,\-]',''); if(-not $t -or $t -notmatch '\d'){ return $null }; $t=$t -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }; return $null }
function CeldiriciYolKapisi($aday){
  $out=@()
  if(-not ($aday.PSObject.Properties['cozum_tablo'] -and $aday.cozum_tablo -and @($aday.cozum_tablo.satirlar).Count -ge 2)){ return @() }
  $yol=$(if($aday.PSObject.Properties['celdirici_yol'] -and $aday.celdirici_yol){ $aday.celdirici_yol } else { $null })
  $inv=[Globalization.CultureInfo]::InvariantCulture
  foreach($h in 'A','B','C','D','E'){
    if($h -eq "$($aday.dogru)"){ continue }
    $sikT="$($aday.siklar.$h)"; if($sikT -match '[A-Za-zÇĞİÖŞÜçğıöşü]{4,}'){ continue }   # cümle/yön şıkkı: sayı kapısı yok
    $sikN=SayiCozC $sikT; if($null -eq $sikN){ continue }
    $f=$(if($yol -and $yol.PSObject.Properties[$h]){ "$($yol.$h)" } else { '' })
    if(-not $f.Trim()){ $out+="$h) yanlış yol formülü yok"; continue }
    # 08.09 Tur 1 FMuh ölçümü (p4: 68 KAPI-Ç tekrarı, 25 düşüş; 32 "'=' yok" + 70 "çözülemedi"): (1) model "=" etrafına boşluk koymuyor
    # ("300.000×%20=60.000") → '\s=\s' bölmüyordu; (2) çok adımlı yol ";" ile yazılıyor ("… = 310.000; max(240.000,310.000)=310.000; 320.000-310.000 = 10.000")
    # → son adımdan önceki her şey formüle karışıyordu. Şimdi: son ";" parçası alınır, "=" boşluksuz da bölünür, max/min desteklenir.
    $fSon=$f; $parcalar=@($f -split ';'); if($parcalar.Count -gt 1){ $fSon=$parcalar[$parcalar.Count-1] }
    $fSon=$fSon -replace '\s*\([^()]*[A-Za-zÇĞİÖŞÜçğıöşü][^()]*\)\s*$',''   # sondaki "(hatanın adı)" notu
    $par=@($fSon -split '\s*=\s*' | Where-Object { "$_".Trim() }); if($par.Count -lt 2){ $out+="$h) yanlış yol formülünde '=' yok"; continue }
    $sol=$par[$par.Count-2]
    # 08.09 B kovası 19: iç eşitlik "(20.000/400=50)" → "(20.000/400)" (iç sonuç dış hesapta yeniden hesaplanır, sahte "çözülemedi" bitti);
    # Unicode eksi (−) ve rakam arası "x" (300x0,50) da aritmetiğe çevrilir. Ölçüm: 07.09 Maliyet kp-01/kp-02 üç sahte tur bu yüzdendi.
    # 08.09 Tur 1 FMuh ölçümü (29 KAPI-Ç tekrar/etiket): "(40.000 x %10)" parantezi, içindeki 'x' HARF sayıldığı için "not" diye siliniyordu → "40000 +" kaldı,
    # "hesaplanamadı". Sıra düzeltildi: önce çarpım işareti ve birimler temizlenir, SONRA yalnız harf içeren (not) parantezler atılır.
    $solT=$sol -replace '−','-' -replace '–','-' -replace '×','*'
    $solT=[regex]::Replace($solT,'(?<=[\d\)%\.])\s*[xX]\s*(?=[\d\(%])','*')
    $solT=$solT -replace '(?i)\b(TL|₺|kg|ton|adet|birim|ay|yıl|yil|gün|gun|saat)\b',' '
    $solT=$solT -replace '\([^)]*[A-Za-zÇĞİÖŞÜçğıöşü][^)]*\)',' '   # yalnız harf içeren parantez (not) atılır, aritmetik parantez kalır
    $solT=[regex]::Replace($solT,'\(([^()=]*?)\s*=\s*[\d\.,]+\s*%?\s*\)','($1)')
    $solT=[regex]::Replace($solT,'(?<=[\d\)])\s*[xX]\s*(?=[\d\(%])','*')
    # max/min içindeki argüman virgülü ("max(240.000,300.000)") ondalık virgülle karışmasın: binlik noktalı sayı izliyorsa ayraçtır → ' | ' (sonra geri ',')
    $solT=[regex]::Replace($solT,'(?i)\b(max|min)\s*\(([^()]*)\)',[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value+'('+([regex]::Replace($m.Groups[2].Value,',(?=\s*\d{1,3}(?:\.\d{3})+(?![\d,]))',' | '))+')' })
    $solT=[regex]::Replace($solT,'%\s*(\d{1,3}(?:\.\d{3})*(?:,\d+)?)',[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $v=SayiCozC $m.Groups[1].Value; if($null -eq $v){ $m.Value } else { '('+($v/100).ToString($inv)+')' } })
    $solT=[regex]::Replace($solT,'(\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?)',[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $v=SayiCozC $m.Value; if($null -eq $v){ $m.Value } else { $v.ToString($inv) } })
    $solT=($solT -replace '\s+',' ').Trim()
    $solT=[regex]::Replace($solT,'(?i)\bmax\s*\(','[Math]::Max('); $solT=[regex]::Replace($solT,'(?i)\bmin\s*\(','[Math]::Min(')   # 08.09: "max(240.000,310.000)" desteklenir
    $solT=$solT -replace '\s*\|\s*',','
    $kontrol=$solT -replace '\[Math\]::(Max|Min)\(','(' -replace ',',' '
    if($kontrol -notmatch '^[\d\.\s\+\-\*/\(\)]+$'){ $out+="$h) yanlış yol çözülemedi: $f"; continue }
    $hes=$null; try{ $hes=[double](Invoke-Expression $solT) }catch{ $out+="$h) yanlış yol hesaplanamadı: $f"; continue }
    $tol=[Math]::Max(0.51,[Math]::Abs($sikN)*0.005)
    if([Math]::Abs($hes-$sikN) -gt $tol -and [Math]::Abs($hes*100-$sikN) -gt $tol -and [Math]::Abs($hes/100-$sikN) -gt $tol){ $out+="$h) yanlış yol $([math]::Round($hes,2)) çıkıyor, şık $sikT" }
  }
  return $out
}
function HesapKodKapisi($aday){
  $d=ThpSozluk; if(-not $d -or -not $d.Count -or -not $aday -or -not $aday.siklar){ return @() }
  $metinler=New-Object System.Collections.Generic.List[string]
  foreach($h in 'A','B','C','D','E'){ $metinler.Add("$($aday.siklar.$h)") }
  if($aday.sema){ $kyt=@(); if($aday.sema.PSObject.Properties['kayitlar']){ $kyt=@($aday.sema.kayitlar) } elseif($aday.sema.PSObject.Properties['ogeler']){ $kyt=@($aday.sema) }
    foreach($ky in $kyt){ if($ky -and $ky.ogeler){ foreach($og in @($ky.ogeler.borc)+@($ky.ogeler.alacak)){ if($og){ $metinler.Add("$($og.hesap)") } } } } }
  $kusur=New-Object System.Collections.Generic.List[string]; $gorulen=@{}
  foreach($t in $metinler){
    # standart/madde numaraları hesap kodu değildir ("BDS 260", "TMS 240", "m. 523") — 06.09 karne ölçümünde 3 sahte alarm
    # "400 TL olumlu sapma" bir tutardır, hesap kodu değil (06.09 fmuh-k10 sahte alarmı): birim/para sözcüğü izleyen sayı atlanır
    foreach($m in [regex]::Matches($t,'(?<![\d.,])(?<!(?:BDS|TMS|TFRS|GDS|KKS|UMS|UFRS|IFRS|ISA|ISQM|KGK|Sıra No|No|madde|m\.|md\.|p\.)\s{0,2})([1-7]\d{2})(?![\d.,])(?!\s*(?:TL|₺|lira|adet|kg|ton|gün|yıl|ay|saat|birim|kişi|%|puan|metre|litre))\s+([^\d]{3,90})')){
      $kod=$m.Groups[1].Value; if(-not $d.ContainsKey($kod)){ continue }
      $yazHam=$m.Groups[2].Value.Trim(); $yaz=Katla2 $yazHam; $res=Katla2 $d[$kod]
      $resK=@(($res -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|veya|ile|hesabi|hs)$' }); if(-not $resK.Count){ continue }
      $eksik=@($resK | Where-Object { $w=$_; $on=$(if($w.Length -gt 5){ $w.Substring(0,5) } else { $w }); $yaz -notmatch ('\b'+[regex]::Escape($on)) })
      $anah="$kod|$yaz"; if($gorulen[$anah]){ continue }; $gorulen[$anah]=1
      if($eksik.Count -gt [Math]::Floor($resK.Count/2)){ $kusur.Add("$kod yazılan '$($yazHam.Substring(0,[Math]::Min(40,$yazHam.Length)))' ≠ resmî '$($d[$kod])'") }
    }
  }
  return @($kusur | Select-Object -Unique)
}
function SikBicimi($aday){
  if(-not $aday -or -not $aday.siklar -or -not $aday.dogru){ return '' }
  $harf=@('A','B','C','D','E'); $sik=@($harf | ForEach-Object { "$($aday.siklar.$_)".Trim() }); $d="$($aday.dogru)".Trim().ToUpperInvariant()
  if($harf -notcontains $d){ return '' }
  $dogruS="$($aday.siklar.$d)".Trim()
  $yonlu=@($sik | Where-Object { $_ -match '(?i)\b(olumlu|olumsuz|lehte|aleyhte|eksik|fazla)\b' }).Count
  $sayiRx='^\s*[\d.,]+\s*(₺|TL|%|adet|kg|saat|gün|yıl|TL/kg|TL/adet)?\s*$'
  $sayiN=@($sik | Where-Object { $_ -match $sayiRx }).Count
  if($sayiN -ge 4 -and $yonlu -lt 4){
    $deg=@($sik | ForEach-Object { $m=[regex]::Match($_,'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?'); if($m.Success){ try{ [double]::Parse($m.Value,[cultureinfo]::GetCultureInfo('tr-TR')) }catch{ $null } } })
    $deg=@($deg | Where-Object { $null -ne $_ })
    if(@($deg | Select-Object -Unique).Count -lt $deg.Count){ return "sayı şıklarında aynı tutar tekrar ediyor" }
    # sıralama KAPI DEĞİL, istem tercihi: çıkmış sınavda artan sıra payı derse göre %58-83 (04.09 ölçüm); eldeki 60 sorunun
    # 17'si yalnız bu yüzden geri dönerdi (her dönüş bir çağrı). Kural 2a "küçükten büyüğe" der, model çoğunlukla uyar.
    $birimli=@($sik | Where-Object { $_ -match '(₺|TL|%|adet|kg|saat)' }).Count
    if($birimli -eq 1 -and $dogruS -match '(₺|TL|%|adet|kg|saat)'){ return "birim yalnız doğru şıkta" }
    return ''
  }
  if($sayiN -le 1 -and $yonlu -lt 4){
    $uz=@($sik | ForEach-Object { $_.Length } | Sort-Object); $medyan=[double]$uz[[int]($uz.Count/2)]
    # eşik 1,8: çıkmış cümle şıklarında en uzun/medyan MEDYANI ders başına 1,14–1,6 (04.09 ölçüm, 3.590 soru); 1,6 gerçek sınavı da düşürürdü
    # 06.09 (Cem "geç", 05.09 ölçümü): çıkmışta doğru şık en uzun %5-24 (rastgele), bizde %33-71 → eşik 1,8'den 1,3'e
    if($medyan -gt 0 -and $dogruS.Length -eq $uz[-1] -and $dogruS.Length -ge 1.3*$medyan){ return "doğru şık en uzun ve medyanın $([math]::Round($dogruS.Length/$medyan,1)) katı (çıkmışta doğru en uzun rastgele düzeyde)" }
    $parantezli=@($sik | Where-Object { $_ -match '\(' }).Count
    if($parantezli -eq 1 -and $dogruS -match '\('){ return "parantezli açıklama yalnız doğru şıkta" }
  }
  return ''
}
$soruIstem=@'
Sen "Nobetci" adli hoca-yazarsin. {SINAV} sinavinin {DERS} dersinden, verilen KONUda, SIFIRDAN bir sinav sorusu uret. Universite mezunu gence, gercek sinav ayarinda.
KURALLAR (KALIP SOZLESMESI - kural 19-25 seti):
1. YALNIZ asagidaki KAYNAK METNINE dayan; kural/oran/tanim kaynaktan. Senaryo tutarlari serbest.
2. 5 sik, TEK dogru; her yanlis sik BIR ADLI TUZAGIN sonucu.
2a. SIK DENGESI (04.09 Cem "cevap belli, sınavda böyle mi?" → 7 çıkmış sapma sorusu ölçüldü): tutar + YÖN birlikte
    sorulan şıklarda (sapma/fark/yükleme) her tutar İKİ YÖNLE de görünür: 2 tutar × 2 yön + 1 tek şık (üçüncü tutar ya da
    "Sapma yok"). Örnek (SGS 2020/3): 20.000 olumlu · 30.000 olumlu · 30.000 olumsuz · 40.000 olumlu · 40.000 olumsuz.
    Tek bir tutarın iki yönle, diğerlerinin tek yönle verilmesi YASAK (cevap tutardan belli olur). Yön kelimesi sınav
    dilidir: "olumlu / olumsuz" (lehte/aleyhte sınavda geçmez); genel üretim gideri yüklemesinde "eksik yükleme / fazla
    yükleme". Genel ilke her şık tipinde: doğru şık, biçimiyle (tek farklı hesap, tek farklı birim, tek çift, en uzun
    cümle) ele vermez; sayı şıklarında beş tutar birbirinden farklı ve küçükten büyüğe sıralı yazılır.
    Sayı şıklarında BİRİM YAZILMAZ, birim kökte durur (06.09 ölçüm, çıkmış kitapçıklar: "kaç ₺'dir? A) 19.200 B) 20.200";
    şık "19.200 TL" değil "19.200"). Yön kelimesi (olumlu/olumsuz, eksik/fazla yükleme) şıkta kalır.
    BU DERSİN ÇIKMIŞ ŞIK KALIBI (ölçüldü): {SIK_KALIP}
3. ACIKLAMA - her sik icin TEK PARCA DUZ METIN STRING (nesne/alt-alan YASAK).
   TURKCE HARFLER TAM YAZILIR: "Doğrusu", "Tuzağı", "Kural", "Hesap" - ASCII yazim
   ("Dogrusu", "Tuzagi") KUSURDUR, sayfada oyle gorunur ve urunu ucuzlatir.
   3a-0. "Ne soruluyor" cümlesi CEVABI İMA ETMEZ (06.09 kalıp-6 dersi: "ticari borçların az gösterilmesi riski…" yazınca doğru şık
       belli oldu). "Hangisi yanlıştır/doğrudur/değildir" sorusunda "beş ifadeden hangisinin BDS 500'e aykırı olduğu soruluyor"
       gibi GENEL yazılır; ayırt edici olgu (yön, tutar, hesap) "Kural" ve "Doğrusu" parçalarında kalır.
   3a. DOGRU SIK: "Ne soruluyor: <tek cumle> Kural: <dayanaktan cikan kural>
       Hesap: <sayi zinciri, hesapliysa> Doğrusu: <tek cumle sonuc>"
   3b. YANLIS SIKLAR: "Ne soruluyor" CUMLESINI TEKRARLAMA - ogrenci onu dogru sikta
       zaten okudu. Dogrudan tuzaga gir: "<Ad> Tuzağı: <ogrencinin nasil dusundugu>
       Doğrusu: <tek cumle>". Yanlis sik aciklamasi EN FAZLA 2 CUMLE / 250 karakter.
3c. TUZAK ADLARI CESITLI OLACAK: ayni parti icinde 'Ters Kayıt' gibi tek bir tuzak
   adini iki soruda birden kullanma. Her yanlis sik FARKLI bir kavram yanilgisini
   temsil etsin: hesap secimi, taraf (borc/alacak), tutar/oran, zamanlama (donem),
   kapsam (hangi islem), belge/kanit, vergi katmani gibi.
3d. CELDIRICI DERINLIGI: 'dogru kaydin aynisini ters cevirmek' UCUZ celdiricidir -
   partide en fazla bir kez kullan. Iyi celdirici, ogrencinin GERCEKTEN yapabilecegi
   hatayi tasir (yanlis hesap kodu, gun kesri unutma, KDV'yi matraha katma gibi).
4. HESAPLI konuysa COZUM TABLOSU ZORUNLU ({"basliklar":[...],"satirlar":[[...]]}, ilk kolon kalem, SON SATIR SONUC). Teorik konuysa cozum_tablo null olabilir ama SEMA ZORUNLU.
4b. MALI TABLO FORMU (Cem: "bilanco/gelir tablosu gibi gorelim"): konu finansal durum/
   bilanco/oran tipiyse tablo BILANCO duzeninde kurulur - bolum basligi AYRI SATIR olur
   ve tutar kolonlari '-' birakilir (or. ["DONEN VARLIKLAR","-"]), altina kalemler,
   sonra ["Donen Varliklar Toplami","120.000"]. Gelir tablosu tipiyse GELIR TABLOSU
   akisi (Brut Satislar'dan asagi). Yevmiye tipiyse sema tur=yevmiye zaten T-cetveli verir.
4c. DENKLEM SORULARI (05.09 Cem, karşılıklı dağıtım incelemesi — başabaş, standart maliyet, karşılıklı dağıtım gibi
   denklemle çözülen her konu): (i) Gider yeri/ürün/kalem adları HARF DEĞİL AD ile anılır ("Bakım-Onarım toplamı",
   "Yemekhane toplamı"; A/B yazılmaz çünkü şık harfleriyle karışır). (ii) Çözüm tablosu SAYISAL satırlardan kurulur
   (kendi gideri, karşı taraftan gelen pay, giden pay, düzeltilmiş toplam, karşı tarafın toplamı, SAĞLAMA); tablo
   hücresine denklem metni yazılmaz, denklem açıklamaya gider. (iii) Soru kökü TEK ANLAMLI olur: istenen büyüklük
   açıkça adlandırılır ("dağıtıma esas toplam (düzeltilmiş) maliyeti kaç TL'dir?"); iki farklı okunuşla iki farklı
   şıkka çıkan kök YASAK (ör. "esas üretim yerlerine dağıtılacak toplam" hem 100.000 hem 90.000 okunur).
4d. VERİLENLER (06.09 Cem: "soruda çok veri var, tabloda ikisi; hiç bilmeyene böyle olmuyor"): JSON'a "verilenler" listesi ekle:
   soru metnindeki HER sayı ayrı satır {"ad","deger","anlam"} — ad sınav dilinde kısa ad, deger metindeki yazımıyla birimiyle,
   anlam tek cümle: bu sayı nedir, hesapta nerede kullanılır (hiç bilmeyene). Ekran tabloyu VERİLENLER → HESAP → SONUÇ düzeninde çizer;
   bu yüzden cozum_tablo'da soruda VERİLEN sayı için ayrı satır AÇMA (verilen satırı hesap bloğunda tekrarlanmaz), tablo yalnız hesaplanan satırları taşır.
5. SEMA: tur alani YALNIZ su dort degerden biri olabilir: "yevmiye" | "eleme" | "karar" | "akis" (baska ad/varyant YASAK). Bu ders KAYIT dersiyse ve soru bir islemin muhasebesine dokunuyorsa tur=yevmiye ZORUNLUDUR ({"tur":"yevmiye","baslik":"...","ogeler":{"borc":[{"hesap":"181 GELIR TAHAKKUKLARI","tutar":"..."}],"alacak":[...]}}) - T-cetveli budur. SORUNUN KENDI VERISIYLE, jenerik yasak.
6. hap (tek cumle kalici kural), sinav_taktigi (1 cumle), notlandirici (en cok puan kaybettiren nokta).
7. Rakamlar her katmanda BIREBIR tutarli.
8. DERS KAPSAMI (RESMI - 01.09): {DERS_TARIF}
   Bu kapsamin DISINA cikan soru uretme; konu kapsama uymuyorsa soruyu KAPSAMA
   UYAN acisiyla kur (or. TMS konusu geldiyse KAYIT boyutunu sor, olcum teknigi degil).
9. UZUNLUK - SINAV AYARI (02.09 Cem karari, cikmis sinav olcumuyle): soru govdesi
   (siklar HARIC) EN FAZLA {TAVAN} KARAKTER. Gercek {DERS} sorularinin olculen kalibi:
   {KALIP}. Bu bir uslup tercihi degil KAPIDIR - asan soru reddedilip yeniden yazilir.
   NASIL KISALTILIR: tek islem anlat (olay zinciri sart degilse kurma), sirket/kisi
   hikayesi ve gereksiz tarih-adres detayi yazma, "asagidakilerden hangisidir" ile bitir.
   Gercek sinav ornegi (251 kr): "Isletme, gercek kisiden kiraladigi yonetim binasina ait
   olan 100.000 TL'lik temmuz ayi kira tutarini %20 gelir vergisi kesintisi (stopaj)
   yaptiktan sonra banka araciligiyla odemistir. Soz konusu isleme iliskin muhasebe kaydi
   asagidakilerden hangisidir?" - ZORLUK AYRIMDA olur, kelime sayisinda DEGIL.
<<<DEGISKEN>>>
10. SORU TIPI (02.09 - gercek sinavin tip dagilimindan gelen kota): {TIP_TARIF}
11. SINAV DILI (03.09 - 1.042 cikmis kitapcik olculdu, veri: SINAV-DILI-SOZLUGU):
{DIL}
    Her sınavda ORTAK: "THP" kısaltması YASAK (çıkmış sorularda 0 kez geçer) - gerekiyorsa
    "Tekdüzen Hesap Planı" yaz, çoğu zaman hiç anma; "DVK" yerine "Damga Vergisi Kanunu";
    "İş K." yerine "İş Kanunu"; KDV, TMS, TFRS, BDS, TL kısaltmaları serbesttir (sınav öyle yazar).
    Maliyet kısaltmaları YASAK (06.09, kalıp-4 pilotu): "DB YM / DS YM / GÜG / DİMM / DİG / FIFO" yazma; sınav "dönem başı yarı
    mamul", "dönem sonu yarı mamul", "genel üretim gideri", "direkt ilk madde ve malzeme", "direkt işçilik", "ilk giren ilk çıkar
    yöntemi" der. Soru, şık, açıklama, tablo ve adımlarda aynı kural.
    Şirket adı: çoğunlukla sınav gibi "İşletme" de; unvan gerekiyorsa sektör + tür biçiminde gerçekçi ve HER SORUDA FARKLI bir ad kur
    (istemdeki hiçbir örneği kopyalama). "ABC / XYZ A.Ş." gibi yer tutucu unvan YASAK (08.09 pilot ölçümü: istem bunu önerdiği için her soru
    KAPI-O'dan bir tur yaktı; örnek ad verilince de model aynı adı her soruya yazdı). Açıklama, hap ve tuzak metinleri de bu dile uyar.
12. TEŞHİS (07.09 Ö54, "Yanlışını böyle öğrenirsin"): JSON'a "teshis" nesnesi ekle, HER ŞIK için {"yanilgi","gercek","ayirt","paragraf"}:
    yanilgi = bu şıkkı seçen öğrencinin KAFASINDAKİ yanlış inanç, "sen" diliyle tek cümle ("Elden çıkarırken şirketin katlandığı her
    masrafı elden çıkarma maliyeti sanıyorsun"); DOĞRU şık için yanilgi = bu şıkkı ELEYEN öğrencinin yanılgısı.
    gercek = kuralın kendisi + kaynak, en çok iki cümle ("TMS 36 p.28 yalnız satışa doğrudan bağlı ek masrafı sayar; tazminat
    TMS 37'nin konusudur"). ayirt = öğrencinin bir daha yanılmamak için kendine soracağı TEK soru ("Varlığı satmasam da bu para
    çıkar mıydı?"). paragraf = kısa kaynak künyesi ("p.28", "m.328"). Jargon yok, tuzak adı yazma. Bu alanlar açıklama metnini
    DEĞİŞTİRMEZ, ona ek gelir; hesaplı soruda da yazılır (yanilgi = atlanan katman).
14. HESAP PLANI ve ADLANDIRMA (07.09 Cem "hepsine evet": K2, K3, Ö37): para birimi "TL" yazılır (₺ yazma). Hesap planı TEKDÜZEN'dir (MSUGT):
    TMS/TFRS konularında da Tekdüzen kodları ve resmî adları kullanılır (250 ARAZİ VE ARSALAR; "250 Yatırım Amaçlı Gayrimenkuller" gibi TFRS-eki
    adları YASAK, o KGK sınavına aittir). Soru gövdesinde mamul/gider yeri harfle anılabilir (A, B, C — sınav böyle yazar); açıklama,
    adım ve ikizde "A mamulü" gibi tam adla anılır, şık harfleriyle karışmaz.
13. ÇELDİRİCİ DOĞRULAMA — KAPI-Ç (07.09 Cem: "sınavda en çok çıkan, kandırmacılı çok seçenekli, zor"): HESAPLAMA sorusunda JSON'a "celdirici_yol"
    ekle: her YANLIŞ şık için o şıkkın tutarına götüren YANLIŞ YOL formülü, SAYILARLA, sonu "= <şık tutarı>", ardından parantezde hatanın adı
    ("C":"950.000 - 845.000 = 105.000 (tazminatı elden çıkarma maliyetine kattın)"). Formül gerçekten o tutarı VERMELİ: makine hesaplar,
    tutmayan soru geri döner. Her yanlış şık gerçekten yapılabilecek bir hatanın sonucu olur (atlanan katman, yanlış ölçü, ters işaret,
    yüzde puanı/oran karışıklığı, çeldirici verilenin hesaba katılması); rastgele sayı YASAK. TEORİ sorusunda karşılığı: en az iki şık AYNI
    paragraf/maddeden, tek kelime ya da ölçüt farkıyla ayrılır (yakın-şık); bütün yanlış şıklar kaynakta karşılığı olan gerçek ifadelerdir.
16. YASAL PARAMETRE — KAPI-P (08.09): yıla bağlı had/oran/tavan (asgari ücret, kıdem tazminatı tavanı, KDV/SGK/damga/stopaj oranı, gecikme
    zammı, yeniden değerleme oranı, istisna haddi, defter tutma/fatura sınırı, vergi tarifesi) soruda geçiyorsa SAYISI soruda VERİLİR
    ("KDV oranı %20", "kıdem tazminatı tavanının 50.000 TL olduğu varsayılmıştır"). Hafızadan yıl parametresi kullanılmaz; sınav da böyle yapar.
17. DAYANAK DOĞRULUĞU (08.09 pilot: "kredi faiz tahakkuku" sorusuna VUK m.283 yazıldı, o madde AKTİF geçici hesap kıymetlerini tanımlar, hakem düşürdü):
    "dayanak" alanına yazdığın madde/paragraf, DOĞRU ŞIKKIN KURALINI KOYAN parçadır; konuyla "ilgili görünen" ya da yalnız hesap adını
    anan madde değil. Kaynak paketinde o kuralı OKUDUĞUN parçanın künyesini yaz; kaynak paketinde kuralı koyan parça yoksa dayanağa
    yalnız hesap planı künyesini yaz ("THP 780 / 381") ve kanun maddesi UYDURMA. Yürürlükten kalkmış kanun/standart/kurum anılmaz (KAPI-M);
    süresi geçmiş tarih ya da eski yılın had/oranı kullanılmaz (KAPI-S). Bent düzeyi: "213 sayılı VUK m.323/1", "TMS 36 p.22(b)".
15. YIL — KAPI-Y (07.09 Cem: "şu an {YIL} yılındayız, sorular {YIL} yılını versin"): olay yılları BUGÜNE göre kurulur. Sorulan dönem
    {YIL} yılıdır ("{YIL} yılı amortisman gideri", "{YIL} dönemi"); edinme/başlangıç tarihleri daha eski olabilir ama sorudaki EN YENİ yıl
    {YIL} olmalıdır. Geçmiş yılın dönemini sorma. Tutarı yıldan yıla değişen kalemlerde (oran, tavan, had) sayıyı soruda VER, hafızadan yazma.
BICIM CAPASI - asagidaki onayli ornekle AYNI ses/uzunluk/sik yapisi:
{ORNEK}
Cevap YALNIZ JSON:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"X","aciklama":{...},"teshis":{"A":{"yanilgi":"...","gercek":"...","ayirt":"...","paragraf":"..."},"B":{...},"C":{...},"D":{...},"E":{...}},"celdirici_yol":{"<yanlış şık>":"<sayılı yanlış yol> = <şık tutarı> (<hatanın adı>)",...},"hap":"...","sinav_taktigi":"...","notlandirici":"...","sema":{...},"cozum_tablo":{...veya null},"verilenler":[{"ad":"...","deger":"...","anlam":"..."}],"dayanak":"kisa kunye"}
=== KONU === {KONU}  (cikmis arsivde {DONEM} ayri donemde soruldu)
=== KAYNAK METNI (ambardan) === {KAYNAK}
'@
# --- SINAV DILI (03.09 Cem "1 yap, uretici­ye isle"; olcum scratchpad sinav-dili-sozlugu.ps1, 1.042 belge) -------
# SGS: kanun kisaltmasi ~0 (VUK 3 / "Vergi Usul Kanunu" 346 / "213 sayili" 251; TTK 0/1079/953; TBK 0/1226/1198;
#      GVK 0/281/238) -> kanun TAM ADIYLA ve/veya "sayili" ile; hesap "100 KASA" buyuk harf (11.790 kez).
# SMMM: kisaltma da geciyor (VUK 63/116, GVK 108/112, KDV 1177) -> ilk gecis tam ad, sonra kisaltma serbest.
# KGK: standart dili (TMS 1750, TFRS 1353, BDS 1020, BOBI FRS 455); "Sermaye Piyasasi Kurulu/Kanunu" uzun ad
#      (SPK 18 / uzun 1489); hesap kodu az, "... hesabi" anlatimi (3.067).
$DIL_KURAL=switch -Regex ($Sinav){
  # NOT: ornek yazimlar TURKCE HARFLI verilir - istem ASCII olunca model taklit ediyor (02.09 dersi).
  '^SGS' { '    SGS kitapçıklarında kanun KISALTMASI KULLANILMAZ: "VUK", "TTK", "TBK", "GVK", "KVK", "AATUHK" YAZMA;
    "Vergi Usul Kanunu", "Türk Ticaret Kanunu", "Türk Borçlar Kanunu", "Gelir Vergisi Kanunu", "Kurumlar Vergisi
    Kanunu", "6183 sayılı Amme Alacaklarının Tahsil Usulü Hakkında Kanun" yaz; madde anıyorsan "213 sayılı Vergi
    Usul Kanununun 275 inci maddesi" biçiminde. Hesaplar KOD + BÜYÜK HARF AD: "100 KASA", "131 ORTAKLARDAN ALACAKLAR".' }
  '^SMMM' { '    SMMM kitapçıkları kısaltmayı da kullanır: ilk geçişte tam ad ("Vergi Usul Kanunu (VUK)"), sonra
    kısaltma serbest. Hesaplar KOD + BÜYÜK HARF AD: "100 KASA". "Sermaye Piyasası Kurulu" tam ad yazılır.' }
  '^KGK' { '    KGK kitapçıkları STANDART diliyle yazar: "TMS 2", "TFRS 15", "BDS 315", "BOBİ FRS" kısaltmaları
    normaldir; kanunlar tam adıyla ("Türk Ticaret Kanunu", "Sermaye Piyasası Kanunu" - "SPK" kısaltması nadir).
    Hesap kodu az kullanılır; "... hesabı" ("Kasa hesabı") ve standart paragrafı diliyle anlat.' }
  default { '    Kanunları tam adıyla ve "sayılı" ile an; kısaltmayı yalnız KDV/TMS/TFRS/BDS için kullan.' }
}
# Cikti kapisi: modelin yine de yazdigi yasak kisaltmalar duzeltilir (her sinav) + SGS'de kanun kisaltmalari uzun ada acilir.
$DIL_ORTAK=@(@("\bTHP'(n?de)\b","Tekdüzen Hesap Planı'nda"),@("\bTHP'(n?a|ye)\b","Tekdüzen Hesap Planı'na"),@("\bTHP'nin\b","Tekdüzen Hesap Planı'nın"),@("\bTHP'(n?dan|den)\b","Tekdüzen Hesap Planı'ndan"),@('\bTHP\b','Tekdüzen Hesap Planı'),@('\bDVK\b','Damga Vergisi Kanunu'),@('\bİş\s*K\.(?!anunu)','İş Kanunu'))
$DIL_SGS=@(@('\bVUK\b','Vergi Usul Kanunu'),@('\bTTK\b','Türk Ticaret Kanunu'),@('\bTBK\b','Türk Borçlar Kanunu'),@('\bGVK\b','Gelir Vergisi Kanunu'),@('\bKVK\b','Kurumlar Vergisi Kanunu'),@('\bAATUHK\b','6183 sayılı Amme Alacaklarının Tahsil Usulü Hakkında Kanun'),@('\bİİK\b','İcra ve İflas Kanunu'),
  # 04.09 ölçüldü (kp-28): "VUK 213 sayılı Kanun'un" → "Vergi Usul Kanunu 213 sayılı Kanun'un" oluyordu → "213 sayılı Vergi Usul Kanunu'nun"
  @("(Vergi Usul Kanunu|Türk Ticaret Kanunu|Türk Borçlar Kanunu|Gelir Vergisi Kanunu|Kurumlar Vergisi Kanunu)\s+(\d+)\s+sayılı Kanun'(un|ün|a|e|da|de|dan|den)",'$2 sayılı $1''n$3'),
  @("(Vergi Usul Kanunu|Türk Ticaret Kanunu|Türk Borçlar Kanunu|Gelir Vergisi Kanunu|Kurumlar Vergisi Kanunu)\s+(\d+)\s+sayılı Kanun\b",'$2 sayılı $1'))
$script:DIL_DUZELTME=0
# 04.09 TERİM KATMANI (Cem "sınavda genel idare gideri çıkıyor mu?"; ölçüm scratchpad TERIM-CIFTLERI.md, üç sınav birden):
# kanun dili → sınav dili. SGS 65 kitapçık: "genel idare gideri" 0 / "genel yönetim gideri" 230; "genel imal(at)" 0 / "genel
# üretim gideri" 379; "DİMM" 5 / "direkt ilk madde" 311; "Dİ" 0 / "direkt işçilik" 316; "GÜG" 23 / 379. KGK ve SMMM aynı yönde.
# Bire bir karşılığı olmayan çiftler (kıymet/değer, müessese/işletme, ücret/maaş, emtia/stok) BİLEREK dışarıda: "menkul kıymet" gibi
# gerçek terimleri bozar. Tırnak içindeki KANUN ALINTISI dokunulmaz ("…genel idare giderlerinden mamule düşen hisse…").
# 04.09 GM-3 (Cem "1.3 yap"): liste ARTIK ÖLÇÜMDEN okunur — veri/terim-ciftleri.json (motor/terim-olcum.ps1 yazar; yalnız
# karar='kapi' olanlar). Dosya 30 günden eskiyse ve arşiv yerelde varsa ölçüm önce koşar (API yok). Dosya yoksa yedek liste.
$DIL_TERIM_YEDEK=@(
  @('[Gg]enel\s+[İi]dare\s+[Gg]ider','genel yönetim gider'),
  @('[Gg]enel\s+[İi]mal(?:at)?\s+[Gg]ider','genel üretim gider'),
  @('(?<![A-Za-zÇĞİÖŞÜçğıöşü])DİMM(?![A-Za-zÇĞİÖŞÜçğıöşü])','direkt ilk madde ve malzeme'),
  @('(?<![A-Za-zÇĞİÖŞÜçğıöşü])GÜG(?![A-Za-zÇĞİÖŞÜçğıöşü])','genel üretim gideri'),
  @('(?<![A-Za-zÇĞİÖŞÜçğıöşü])GİG(?![A-Za-zÇĞİÖŞÜçğıöşü])','genel üretim gideri'),   # SGS 65 kitapçıkta 0 (04.09 ölçüm)
  @('(?<![A-Za-zÇĞİÖŞÜçğıöşü])Dİ(?![A-Za-zÇĞİÖŞÜçğıöşü])','direkt işçilik')
)
$DIL_TERIM=@()
$terimDosya=Join-Path $kok 'veri\terim-ciftleri.json'
try{
  $bayat=$true
  if(Test-Path $terimDosya){ $tj=Get-Content $terimDosya -Raw -Encoding UTF8 | ConvertFrom-Json; try{ $bayat=((Get-Date)-[datetime]::ParseExact("$($tj.olcum)",'yyyy-MM-dd HH:mm',$null)).TotalDays -gt 30 }catch{ $bayat=$true } }
  if($bayat -and -not $SadeceHtml -and (Test-Path (Join-Path $kok 'veri\sgs-arsiv'))){
    Write-Host "  terim ölçümü bayat/yok -> motor/terim-olcum.ps1 koşuyor (API yok)" -ForegroundColor DarkCyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'terim-olcum.ps1') -Sessiz | Out-Null
    if(Test-Path $terimDosya){ $tj=Get-Content $terimDosya -Raw -Encoding UTF8 | ConvertFrom-Json }
  }
  if($tj -and $tj.ciftler){ foreach($c in @($tj.ciftler)){ if("$($c.karar)" -eq 'kapi' -and $c.desen_kanun -and $c.karsilik){ $DIL_TERIM+=,@("$($c.desen_kanun)","$($c.karsilik)") } } }
}catch{ Write-Host "  terim dosyası okunamadı: $($_.Exception.Message)" -ForegroundColor Yellow }
if(-not $DIL_TERIM.Count){ $DIL_TERIM=$DIL_TERIM_YEDEK; Write-Host "  terim katmanı: ölçüm dosyası yok, yedek liste ($($DIL_TERIM.Count) çift)" -ForegroundColor DarkGray }
else { Write-Host "  terim katmanı: ölçümden $($DIL_TERIM.Count) çift" -ForegroundColor DarkGray }
function TerimOnar([string]$t){
  # tırnak dışı parçalarda çalışır; eşleşme büyük harfle başlıyorsa karşılık Başlık Düzeninde yazılır
  $parcalar=$t -split '(["“”])'; $cikti=New-Object System.Text.StringBuilder; $icerde=$false
  foreach($p in $parcalar){
    if($p -match '^["“”]$'){ [void]$cikti.Append($p); $icerde=-not $icerde; continue }
    if($icerde){ [void]$cikti.Append($p); continue }
    $y=$p
    foreach($c in $DIL_TERIM){ $kar=$c[1]; $y=[regex]::Replace($y,$c[0],{ param($m) if($m.Value.Substring(0,1) -cmatch '[A-ZÇĞİÖŞÜ]' -and $m.Value -cne $m.Value.ToUpper([cultureinfo]::GetCultureInfo('tr-TR'))){ (($kar -split ' ') | ForEach-Object { if($_ -eq 've'){ $_ } else { $_.Substring(0,1).ToUpper([cultureinfo]::GetCultureInfo('tr-TR'))+$_.Substring(1) } }) -join ' ' } else { $kar } }) }
    # 05.09 (kalıp-1 sorusu): model "lehte (olumlu)" yazmış, onarım "olumlu (olumlu)dur" üretmişti → aynı kelimenin parantez tekrarı silinir
    $y=[regex]::Replace($y,'(?i)\b(\p{L}+)\s*\(\1\)','$1')
    $y=[regex]::Replace($y,'(?i)\b(\p{L}+),?\s+yani\s+(?=\1)','')   # "lehte yani olumlu" → "olumlu yani olumlu" → "olumlu"
    [void]$cikti.Append($y)
  }
  return $cikti.ToString()
}
function DilOnar([string]$t){
  if(-not $t){ return $t }
  $x=$t
  foreach($c in $DIL_ORTAK){ $x=[regex]::Replace($x,$c[0],$c[1]) }
  if($Sinav -match '^SGS'){ foreach($c in $DIL_SGS){ $x=[regex]::Replace($x,$c[0],$c[1]) } }
  $x=TerimOnar $x
  $x=YazimOnar $x   # 08.09 pilot6 karnesi: adımlar/ikiz/giriş DilOnar'dan geçiyor ama yazım sözlüğünden geçmiyordu → 6 sorunun 5'inde adımlarda "yillik, degil, yanlis" kaldı
  if($x -ne $t){ $script:DIL_DUZELTME++ }
  return $x
}
function DilOnarNesne($cvp){
  if(-not $cvp){ return }
  foreach($alan in @('soru','hap','sinav_taktigi','notlandirici')){ if($cvp.PSObject.Properties[$alan] -and $cvp.$alan -is [string]){ $cvp.$alan=DilOnar $cvp.$alan } }
  foreach($h in 'A','B','C','D','E'){
    if($cvp.siklar -and $cvp.siklar.PSObject.Properties[$h] -and $cvp.siklar.$h -is [string]){ $cvp.siklar.$h=DilOnar $cvp.siklar.$h }
    if($cvp.aciklama -and $cvp.aciklama.PSObject.Properties[$h] -and $cvp.aciklama.$h -is [string]){ $cvp.aciklama.$h=DilOnar $cvp.aciklama.$h }
    elseif($cvp.aciklama -and $cvp.aciklama.PSObject.Properties[$h] -and $cvp.aciklama.$h){ $ao=$cvp.aciklama.$h; foreach($p in @($ao.PSObject.Properties)){ if($p.Value -is [string]){ $ao.($p.Name)=DilOnar $p.Value } } }   # 04.09: yapılı açıklama (ne_soruluyor/kural/hesap/dogrusu) da kapıdan geçer
  }
  foreach($ad1 in @($cvp.adimlar)){ if($ad1){ foreach($alan in @('anlatim','formul')){ if($ad1.PSObject.Properties[$alan] -and $ad1.$alan -is [string]){ $ad1.$alan=DilOnar $ad1.$alan } } } }
  # ogrenciye gorunen diger alanlar: dayanak kunyesi, sema/kayit basliklari (kaynak_adlar ve hakem DOKUNULMAZ - ambar adi/denetim izi)
  if($cvp.PSObject.Properties['dayanak'] -and $cvp.dayanak -is [string]){ $cvp.dayanak=DilOnar $cvp.dayanak }
  foreach($sm in @('sema','ikiz_sema')){ $s1=$null; if($cvp.PSObject.Properties[$sm]){ $s1=$cvp.$sm }; if(-not $s1){ continue }
    if($s1.PSObject.Properties['baslik'] -and $s1.baslik -is [string]){ $s1.baslik=DilOnar $s1.baslik }
    if($s1.PSObject.Properties['kayitlar']){ foreach($ky in @($s1.kayitlar)){ if($ky -and $ky.PSObject.Properties['baslik'] -and $ky.baslik -is [string]){ $ky.baslik=DilOnar $ky.baslik } } } }
  if($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz){ foreach($alan in @('ikiz_soru','ikiz_aciklama','ikiz_ipucu')){ if($cvp.ikiz.PSObject.Properties[$alan] -and $cvp.ikiz.$alan -is [string]){ $cvp.ikiz.$alan=DilOnar $cvp.ikiz.$alan } } }
  # 04.09: çözüm tablosu hücreleri (kp-28'de "Genel İdare Gideri Payı", "DİMM" tabloda kalmıştı) + sade katman
  $BasHarf={ param($s) if($s -and $s.Length -gt 1 -and $s.Substring(0,1) -cmatch '[a-zçğıöşü]'){ $s.Substring(0,1).ToUpper([cultureinfo]::GetCultureInfo('tr-TR'))+$s.Substring(1) } else { $s } }
  if($cvp.PSObject.Properties['cozum_tablo'] -and $cvp.cozum_tablo){
    $ct=$cvp.cozum_tablo
    if($ct.PSObject.Properties['basliklar']){ $ct.basliklar=@(@($ct.basliklar) | ForEach-Object { if($_ -is [string]){ & $BasHarf (DilOnar $_) } else { $_ } }) }
    if($ct.PSObject.Properties['satirlar']){ $ct.satirlar=@(@($ct.satirlar) | ForEach-Object { ,@(@($_) | ForEach-Object { if($_ -is [string]){ & $BasHarf (DilOnar $_) } else { $_ } }) }) }
  }
  # 04.09: ikiz tablo hücreleri de (Kaydır-Çöz "Sen çöz" oyununda görünür; "3.600 TL (Aleyhte)" kalmıştı)
  if($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz -and $cvp.ikiz.PSObject.Properties['tablo'] -and $cvp.ikiz.tablo){
    $it=$cvp.ikiz.tablo
    if($it.PSObject.Properties['basliklar']){ $it.basliklar=@(@($it.basliklar) | ForEach-Object { if($_ -is [string]){ & $BasHarf (DilOnar $_) } else { $_ } }) }
    if($it.PSObject.Properties['satirlar']){ $it.satirlar=@(@($it.satirlar) | ForEach-Object { ,@(@($_) | ForEach-Object { if($_ -is [string]){ & $BasHarf (DilOnar $_) } else { $_ } }) }) }
    if($cvp.ikiz.PSObject.Properties['hedef_cumle'] -and $cvp.ikiz.hedef_cumle -is [string]){ $cvp.ikiz.hedef_cumle=DilOnar $cvp.ikiz.hedef_cumle }
  }
  if($cvp.PSObject.Properties['sade'] -and $cvp.sade){
    $sd=$cvp.sade
    foreach($alan in @('dogru','sinav')){ if($sd.PSObject.Properties[$alan] -and $sd.$alan -is [string]){ $sd.$alan=DilOnar $sd.$alan } }
    if($sd.PSObject.Properties['siklar'] -and $sd.siklar){ foreach($p in $sd.siklar.PSObject.Properties){ if($p.Value -is [string]){ $sd.siklar.($p.Name)=DilOnar $p.Value } } }
    foreach($kv in @($sd.kavramlar)){ if($kv){ foreach($alan in @('ad','tanim')){ if($kv.PSObject.Properties[$alan] -and $kv.$alan -is [string]){ $kv.$alan=DilOnar $kv.$alan } } } }
  }
}
# 03.09 Cem "1 yap": eldeki cache'e dil kapisi GERIYE DONUK uygulanir (yalniz -SadeceHtml modunda; API yok).
if($SadeceHtml -and $don.Count){
  $script:DIL_DUZELTME=0
  foreach($id in @($don.Keys)){ DilOnarNesne $don[$id] }
  if($script:DIL_DUZELTME -gt 0){ CacheYaz }
  "dil kapisi (geriye donuk): $($script:DIL_DUZELTME) alan duzeltildi"
}
$rapor=New-Object System.Collections.Generic.List[string]
$kaynakBorcu=New-Object System.Collections.Generic.List[string]

# --- GERCEK SINAV KALIBI (02.09 Cem: "sinavda sorulan sorulari ders ders
# ayristir, o kalipta yapacagiz ... 350 diye degis") ---------------------------
# arac/cikmis-ders-kalibi.ps1 cikmis kitapciklari derse ayirip olcuyor.
# Olculen SGS gercegi: Finansal Muhasebe medyan 317 kr, p90 504 kr,
# tip dagilimi kayit %41 / hesaplama %26 / teori %18.
# Cem karari: TAVAN 350 (medyanin hemen ustu - gercek sinavin ~%65'i bu bandin altinda).
$UZUNLUK_TAVAN=$UzunlukTavan
$KALIP_TIP=''
$TIP_HEDEF=New-Object System.Collections.Generic.List[string]
$TIP_TARIF=@{
  # 08.09: bu tarifler ASCII yazılıydı, model istemin yazımını kopyalıyordu ("asagidakilerden", "hesabi") → Türkçe harfle yazıldı (02.09 kök dersi)
  'kayit'     = "KAYIT sorusu: bir işlemin muhasebe kaydını sorar - 'Söz konusu işleme ilişkin muhasebe kaydı aşağıdakilerden hangisidir?' Şıklar YEVMİYE MADDESİ olur (borç/alacak hesapları + tutarlar)."
  'hesaplama' = "HESAPLAMA sorusu: verilen rakamlardan bir tutar/oran bulunur - 'ne kadardır / kaç TL'dir'. Şıklar RAKAM olur."
  'teori'     = "TEORİ sorusu: kural/tanım/ilke sorar - 'aşağıdakilerden hangisi ... değildir/yanlıştır'. Şıklar CÜMLE olur, rakam gerekmez; çözüm tablosu da gerekmez (şema yeter)."
}
$kalipYol=Join-Path $kok ("veri\cikmis-ders-kalibi-" + ($Sinav.ToLowerInvariant()) + ".json")
if(Test-Path $kalipYol){
  try{
    $kp=Get-Content $kalipYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $dAd=@($kp.dersler.PSObject.Properties.Name | Where-Object { $_ -match $DersRegex -or (Katla2 $_) -match (Katla2 $DersRegex) }) | Select-Object -First 1
    if($dAd){
      $dk=$kp.dersler.$dAd
      $tipler=@($dk.tip_dagilim.PSObject.Properties | Sort-Object { -[int]$_.Value } | ForEach-Object { "$($_.Name) %$([math]::Round(100*[int]$_.Value/[int]$dk.soru_sayisi))" })
      $KALIP_TIP=($tipler -join ', ')
      "gercek kalip [$dAd]: n=$($dk.soru_sayisi) medyan=$($dk.medyan) p90=$($dk.p90) | tip: $KALIP_TIP"
      # 06.09 (Cem "geç", 05.09 ölçümü: hukuk soruları 1,5-2× uzundu): -UzunlukTavan açıkça verilmediyse tavan DERSİN çıkmış p75'idir
      if(-not $PSBoundParameters.ContainsKey('UzunlukTavan') -and $dk.PSObject.Properties['p75'] -and [int]$dk.p75 -gt 0){ $UZUNLUK_TAVAN=[int]$dk.p75; "tavan ders p75'ten: $UZUNLUK_TAVAN kr (tek 350 yerine)" }
      # TIP KOTASI (02.09 Cem "3 yap"): parti, gercek sinavin tip dagilimini taklit
      # eder. 'diger' kotasi dagitilmaz - dolgu tipi degil, olcum artigidir.
      $TIP_HEDEF=New-Object System.Collections.Generic.List[string]
      $tipSira=@('kayit','hesaplama','teori')
      $toplamSayilan=0
      foreach($t in $tipSira){ if($dk.tip_dagilim.PSObject.Properties[$t]){ $toplamSayilan+=[int]$dk.tip_dagilim.$t } }
      if($toplamSayilan -gt 0){
        foreach($t in $tipSira){
          if(-not $dk.tip_dagilim.PSObject.Properties[$t]){ continue }
          # DIKKAT: '$adet' DENMEZ - PS harf ayirmaz, -Adet parametresini ezer ve
          # kota her turda kuculur (02.09: 30 soru icin 14/4/1 uretti, dogrusu 12/8/6).
          $tipAdet=[math]::Round($Adet*([int]$dk.tip_dagilim.$t/[double]$toplamSayilan))
          for($q=0;$q -lt $tipAdet;$q++){ $TIP_HEDEF.Add($t) }
        }
        while($TIP_HEDEF.Count -lt $Adet){ $TIP_HEDEF.Add('kayit') }
        "tip kotasi: " + (($TIP_HEDEF | Group-Object | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' ')
      }
    }
  }catch{ "kalip dosyasi okunamadi: $($_.Exception.Message)" }
} else { "kalip dosyasi YOK ($kalipYol) - tavan $UZUNLUK_TAVAN ile devam" }
# 04.09 GM-2: ÇIKMIŞ ŞIK KALIBI (motor/celdirici-olcum.ps1 → veri/celdirici-kalibi-<sinav>.json) isteme ders örnekleriyle girer
$SIK_KALIP='ölçülmedi'
$celYol=Join-Path $kok ("veri\celdirici-kalibi-" + ($Sinav.ToLowerInvariant()) + ".json")
if(Test-Path $celYol){
  try{
    $cj=Get-Content $celYol -Raw -Encoding UTF8 | ConvertFrom-Json
    # 04.09 GM-2 ölçümü: KGK parti ders adı ("a) Türkiye Muhasebe Standartları") ile ölçülen modül adı ("Muhasebe
    # Standartları") farklı → önce regex/çapa/harf ön eki soyulur, sonra KGK takma adları, sonra katlanmış içerme.
    $dersDuz=$DersRegex -replace '^\^|\$$','' -replace '\\','' -replace '^[a-zçğıöşü]\)\s*',''
    $KGK_TAKMA=@{ 'Türkiye Muhasebe Standartları'='Muhasebe Standartları'; 'Türkiye Denetim Standartları'='Denetim'; 'Sermaye Piyasası Mevzuatı'='Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı'; 'Bankacılık Mevzuatı'='Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı'; 'Sigortacılık ve Özel Emeklilik Mevzuatı'='Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı' }
    if($Sinav -eq 'KGK' -and $KGK_TAKMA.ContainsKey($dersDuz)){ $dersDuz=$KGK_TAKMA[$dersDuz] }
    $cAd=@($cj.dersler.PSObject.Properties.Name | Where-Object { $_ -eq $dersDuz -or $_ -match $DersRegex -or (Katla2 $_) -eq (Katla2 $dersDuz) -or (Katla2 $_).Contains((Katla2 $dersDuz)) -or (Katla2 $dersDuz).Contains((Katla2 $_)) }) | Select-Object -First 1
    if($cAd){
      $cd=$cj.dersler.$cAd; $tipS=(@($cd.tip.PSObject.Properties | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ', ')
      $sat=New-Object System.Collections.Generic.List[string]
      $sat.Add("$cAd, $($cd.soru) çıkmış soru; şık tipi dağılımı: $tipS.")
      if($null -ne $cd.sayi_tekil_orani){ $sat.Add("Sayı şıklarında beş tutarın hepsi farklı: %$([int](100*$cd.sayi_tekil_orani)); küçükten büyüğe sıralı: %$([int](100*$cd.sayi_artan_orani)).") }
      if($null -ne $cd.yon_cift_orani){ $sat.Add("Tutar+yön sorularında en az iki tutar iki yönle: %$([int](100*$cd.yon_cift_orani)).") }
      if($null -ne $cd.cumle_uzunluk_orani_medyan){ $sat.Add("Cümle şıklarında en uzun şık / medyan: $($cd.cumle_uzunluk_orani_medyan) (şıklar birbirine yakın uzunlukta).") }
      if($cd.PSObject.Properties['dogru_en_uzun_orani'] -and $cd.dogru_en_uzun_orani -isnot [string]){ $sat.Add("Cevap anahtarıyla ölçüldü: doğru şık en uzun şık olan soru payı yalnız %$([int](100*$cd.dogru_en_uzun_orani)); doğru harfler dengeli dağılır - en uzun şıkkı doğru yapma.") }
      foreach($t in @($cd.ornek.PSObject.Properties.Name)){ $o=@($cd.ornek.$t)[0]; if($o){ $sat.Add("Örnek [$t] ($($o.kitapcik -replace '^CIKMIS SINAV - ','')): " + ((@($o.siklar) | ForEach-Object { "$_" }) -join ' · ')) } }
      $SIK_KALIP=($sat -join ' ')
      "şık kalıbı [$cAd]: $($cd.soru) soru · $tipS"
    }
  }catch{ "şık kalıbı okunamadı: $($_.Exception.Message)" }
} else { "şık kalıbı dosyası YOK ($celYol) - isteme 'ölçülmedi' gider" }
# --- FAZ U: ESKİ SORU UYARLAMA — KURTARMA (08.09, SORU-BASMA-KURALLARI B; Cem "eski soruları kalıba sokabilecek misin?") ----------------
# Eski soru (kasa) + açıklamadan kalıbın FAZ A alanları çıkarılır: çözüm tablosu (hesap), her şık için teşhis, yanlış şıklar için çeldirici yolu,
# verilenler, dayanak künyesi, yevmiye şeması. SORU / ŞIKLAR / DOĞRU / KAYNAK DOKUNULMAZ (B2). Kapılar esnetilmez (B4): kaynak ambarda yoksa,
# yer tutucu unvan varsa, kod-ad çifti tutmuyorsa, çeldirici yolu hesaplanmıyorsa soru DÜŞER ve nedeniyle veri/fabrika/kurtarma-dusen-<etiket>.json'a yazılır (B5).
# Kalan fazlar (adımlar, verilenler, giriş, ikiz, sim, hakem, kör çözüm, hakem2) yeni soruyla AYNI koşar. Yeni soru üretilmez ($KONULAR boşaltılır).
if($EskiKaynak){
  if(-not (Test-Path $EskiKaynak)){ throw "EskiKaynak dosyası yok: $EskiKaynak" }
  $eskiL=@(ConvertFrom-Json -InputObject (Get-Content $EskiKaynak -Raw -Encoding UTF8)); if($eskiL.Count -eq 1 -and $eskiL[0].PSObject.Properties['SyncRoot']){ $eskiL=@($eskiL[0].SyncRoot) }
  $KONULAR=New-Object System.Collections.Generic.List[object]
  "FAZ U: $($eskiL.Count) eski soru kurtarmaya giriyor (yeni soru üretilmez)"
  $script:FAZ_ADI='U'
  $uyarIstem=@'
Sen Tetikte'nin soru editörüsün. Aşağıda ESKİ bir sınav sorusu, şıkları, doğru cevabı ve şık açıklamaları var. Soruyu, şıkları ve doğru cevabı DEĞİŞTİRME.
Görevin: bu soruyu Kaydır-Çöz kalıbının alanlarına uyarlamak. Yalnız verilen kaynak metnine ve soruya dayan; rakam uydurma.
1. cozum_tablo: HESAP sorusuysa (şıklar sayı) çözümün tablosu: {"basliklar":["Kalem","Tutar (TL)"],"satirlar":[["ara kalem adı (kısa formül parantezde)","tutar"],...,["SONUÇ kalemi","doğru şık tutarı"]]}; en az 2 satır, son satır doğru şıkkın tutarı. Teori/kayıt sorusunda null.
2. teshis: HER ŞIK için {"yanilgi":"öğrenci bu şıkkı seçerse ne sanıyordur (tek cümle, 'Öğrenci ... sanır' kalıbı YASAK)","gercek":"kaynak kuralıyla gerçek (tek cümle)","ayirt":"nereden anlarsın (tek cümle)","paragraf":"kısa künye: madde/paragraf/hesap"}; doğru şıkta yanilgi boş kalabilir, gercek = kuralın kendisi.
3. celdirici_yol: HESAP sorusunda her YANLIŞ şık için sayılarla yanlış yol formülü, sonu "= <şık tutarı>", parantezde hatanın adı ("950.000 - 845.000 = 105.000 (tazminatı maliyete kattın)"). Formül GERÇEKTEN o tutarı vermeli; makine hesaplar. Yanlış şık hiçbir yanlış yolla üretilemiyorsa o şık için "YOL YOK" yaz. Teori sorusunda boş nesne.
4. verilenler: soru metnindeki her sayı için {"ad":"...","deger":"800.000 TL","anlam":"tek cümle"}. Teoride boş dizi.
5. dayanak: kısa künye, bent düzeyinde ("213 sayılı VUK m.323/1", "TMS 36 p.22(b)", "THP 645").
6. sema: kayıt sorusuysa {"tur":"yevmiye","kayitlar":[{"baslik":"...","ogeler":{"borc":[{"hesap":"120 Alıcılar","tutar":"..."}],"alacak":[{"hesap":"600 Yurt İçi Satışlar","tutar":"..."}]}}]}, değilse null.
Türkçe harfler tam; TL yazılır; hesap adları Tekdüzen'in resmî adıyla; kısaltma yalnız KDV/TMS/TFRS/BDS.
Yalnız JSON: {"cozum_tablo":{...}|null,"teshis":{"A":{...},"B":{...},"C":{...},"D":{...},"E":{...}},"celdirici_yol":{"<harf>":"..."},"verilenler":[...],"dayanak":"...","sema":{...}|null}
=== SORU === {SORU}
=== ŞIKLAR ===
{SIKLAR}
=== DOĞRU === {DOGRU}
=== ŞIK AÇIKLAMALARI (eski) === {ACIK}
=== KAYNAK METNİ === {KAYNAK}
'@
  function EskiSayiSikli($c){ $n=0; foreach($hh in 'A','B','C','D','E'){ if("$($c.siklar.$hh)" -match '^\s*%?\s*-?\d[\d.,]*\s*(TL|₺|%|adet|kg|gün|yıl|ay|saat|birim)?\s*$'){ $n++ } }; return ($n -ge 4) }
  $dusenYol=Join-Path $kok "veri\fabrika\kurtarma-dusen-$Etiket.json"; $dusenL=New-Object System.Collections.Generic.List[object]
  # ⛔ 12.09: FAZLADAN PARANTEZ ZORUNLU. Oncesi `@(ConvertFrom-Json -InputObject (...))` idi;
#    PS 5.1 diziyi TEK ogeye sardigi icin bu foreach BIR KEZ donuyor, $x diziyi
#    tutuyor, $x.PSObject.Properties['id'] tutmuyor -> $dusenL HIC DOLMUYORDU.
#    Olculdu: @($j|ConvertFrom-Json).Count=1 · @(($j|ConvertFrom-Json)).Count=3
if(Test-Path $dusenYol){ foreach($x in @((ConvertFrom-Json -InputObject (Get-Content $dusenYol -Raw -Encoding UTF8)))){ if($x -and $x.PSObject.Properties['id']){ $dusenL.Add($x) } } }
  $dusenId=New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $dusenL){ [void]$dusenId.Add("$($x.id)") }
  function Dus([string]$id,$e,[string]$sebep){ $dusenL.Add([pscustomobject]@{ id=$id; eski_id="$($e.id)"; ders="$($e.ders)"; konu="$($e.konu)"; sebep=$sebep; tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm') }); [void]$dusenId.Add($id); Write-Host "  KURTARMA DÜŞTÜ $id [$($e.konu)]: $sebep" -ForegroundColor Red; $rapor.Add("KURTARMA DÜŞTÜ: $id [$($e.konu)] $sebep") }
  foreach($e in $eskiL){
    $ham=("$($e.id)" -replace '[^0-9a-fA-F]',''); if($ham.Length -lt 8){ $ham=($ham+'00000000') }; $id='e-'+$ham.Substring(0,8)
    if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
    if($dusenId.Contains($id)){ continue }
    if($don.Contains($id) -and $don[$id].PSObject.Properties['uyarlama']){ continue }
    if(-not $e.soru -or -not $e.siklar -or -not $e.dogru){ Dus $id $e 'soru/şık/doğru eksik'; continue }
    $cvp=[pscustomobject]@{ soru="$($e.soru)"; siklar=$e.siklar; dogru="$($e.dogru)"; aciklama=$e.aciklama; konu="$($e.konu)"; ders="$($e.ders)"; hap=$(if($e.PSObject.Properties['hap']){ "$($e.hap)" } else { '' }); eski_id="$($e.id)"; kaynak_eski="$($e.kaynak)"; kanun_no="$($e.kanun_no)"; madde_no="$($e.madde_no)"; madde_damga="$($e.madde_damga)"; donem=0; kurtarma=$true; sema=$null }
    # --- B8 MEKANİK DÜZELTME İSTİSNASI (Cem 08.09 "üçüne de evet, kur"): anlam değişmez, yazım/ad/sıra düzelir; künyede iz kalır -----------------
    $mek=@()
    # (a) YIL KAYDIRMA — yalnız muhasebe dersleri (hukukta yıla bağlı had gerçeği bozulur; orada eski yıl ELENİR)
    $muhasebeMi=("$($e.ders)" -match '(?i)Finansal Muhasebe|Maliyet|Mali Tablolar|Denetim')
    $yRx='\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))'; $yillarE=@([regex]::Matches("$($cvp.soru)",$yRx) | ForEach-Object { [int]$_.Groups[1].Value })
    if($yillarE.Count){ $enYeniE=($yillarE | Measure-Object -Maximum).Maximum; $farkE=(Get-Date).Year-$enYeniE
      if($farkE -gt 0){
        if(-not $muhasebeMi){ Dus $id $e "yıl eski ($enYeniE), hukuk dersinde kaydırılmaz (yıla bağlı had riski)"; continue }
        $ekT=@{0='de';1='de';2='de';3='te';4='te';5='te';6='da';7='de';8='de';9='da'}
        $kaydirM={ param($t) $t2=[regex]::Replace("$t",$yRx,{ param($m) "$([int]$m.Groups[1].Value + $farkE)" }); [regex]::Replace($t2,"\b(20[0-3](\d))'([dt])([ea])(n?)\b",{ param($m) $son=[int]$m.Groups[2].Value; $ek=$ekT[$son]; "$($m.Groups[1].Value)'$ek$($m.Groups[5].Value)" }) }
        $cvp.soru=& $kaydirM $cvp.soru
        $yeniS=[ordered]@{}; foreach($hh in 'A','B','C','D','E'){ $yeniS[$hh]=(& $kaydirM "$($cvp.siklar.$hh)") }; $cvp.siklar=[pscustomobject]$yeniS
        if($cvp.aciklama){ $yeniA=[ordered]@{}; foreach($hh in 'A','B','C','D','E'){ $v=$cvp.aciklama.$hh; if($v -is [string]){ $yeniA[$hh]=(& $kaydirM $v) } else { $yeniA[$hh]=$v } }; $cvp.aciklama=[pscustomobject]$yeniA }
        $mek+="yıl +$farkE ($enYeniE→$((Get-Date).Year))" } }
    # (b) YER TUTUCU UNVAN → "İşletme" (ABC A.Ş.'nin → İşletme'nin)
    $ytRx='(?i)\b(ABC|XYZ|DEF|KLM|XY|AB)\b\s*(A\.?\s?Ş\.?|Ltd\.?\s*Şti\.?|Ltd\.?|Ticaret\s+A\.?Ş\.?|Ticaret|İşletmesi|Şirketi|San\.?\s*(ve\s*Tic\.?)?\s*A\.?Ş\.?|A\.S\.)'
    if("$($cvp.soru)" -match $ytRx){ $cvp.soru=[regex]::Replace($cvp.soru,$ytRx,'İşletme'); $cvp.soru=$cvp.soru -replace '(?i)\bİşletme\s+(işletmesi|şirketi)\b','İşletme'; $mek+='yer tutucu → İşletme' }
    # (c) UZUN TİRE / ÜÇ NOKTA → virgül / nokta
    $tireVar=$false; $tireDuzelt={ param($t) $t -replace '\s*—\s*',', ' -replace '\s*–\s*',', ' -replace '…','.' }
    if("$($cvp.soru)" -match '—|–|…'){ $cvp.soru=& $tireDuzelt $cvp.soru; $tireVar=$true }
    $yeniS2=[ordered]@{}; foreach($hh in 'A','B','C','D','E'){ $v="$($cvp.siklar.$hh)"; if($v -match '—|–|…'){ $tireVar=$true; $v=& $tireDuzelt $v }; $yeniS2[$hh]=$v }; $cvp.siklar=[pscustomobject]$yeniS2
    if($cvp.aciklama){ $yeniA2=[ordered]@{}; foreach($hh in 'A','B','C','D','E'){ $v=$cvp.aciklama.$hh; if($v -is [string] -and $v -match '—|–|…'){ $tireVar=$true; $v=& $tireDuzelt $v }; $yeniA2[$hh]=$v }; $cvp.aciklama=[pscustomobject]$yeniA2 }
    if($tireVar){ $mek+='uzun tire / üç nokta' }   # 08.09 ölçümü: tire yalnız soruda düzeltilince açıklamadaki tire koku kapısından düşürüyordu
    # (d) TÜRKÇE HARF + KANUN KISALTMASI → DilOnarNesne (YazimOnar sözlüğü + "213 sayılı Vergi Usul Kanunu"); soru sonunda yine koşar, burada iz için
    $onceS="$($cvp.soru)"; DilOnarNesne $cvp; if("$($cvp.soru)" -ne $onceS){ $mek+='Türkçe harf / kısaltma açılımı' }
    # (e) SAYI ŞIKLARI KÜÇÜKTEN BÜYÜĞE (harf, doğru ve açıklama birlikte taşınır)
    if(SikSirala $cvp){ $mek+="şık sıralama (doğru → $($cvp.dogru))" }
    if($mek.Count){ $cvp | Add-Member -NotePropertyName mekanik -NotePropertyValue @($mek) -Force; Write-Host "  MEKANİK $id : $($mek -join ' · ')" -ForegroundColor DarkCyan }
    # --- SERT KURALLAR (B4, Cem 08.09 "elenmeleri doğru"): doğru şık en uzun / tekrar tutar / yön dengesi (KAPI-Ş) · şıkta gerekçe · koku (yuvarlak, klişe, kalan yer tutucu)
    $sikK=SikDengesi $cvp; if(-not $sikK){ $sikK=SikBicimi $cvp }; if($sikK){ Dus $id $e "KAPI-Ş: $sikK"; continue }
    $hesapOn=EskiSayiSikli $cvp
    if(-not $hesapOn){ $gerekceli=@('A','B','C','D','E' | Where-Object { $t="$($cvp.siklar.$_)"; $t -match '(?i)\b(çünkü|nedeniyle|dolayısıyla|bu yüzden|zira)\b' -or $t.Length -gt 160 }); if($gerekceli.Count){ Dus $id $e "şıkta gerekçe / uzun cümle şık ($($gerekceli -join ','))"; continue } }
    $ko=@(KokuKusur $cvp); if($ko.Count){ Dus $id $e ("koku: "+($ko -join '; ')); continue }
    # 08.09 KAPI-M / KAPI-S kurtarmada da eler (B9): mülga kanun/standart/kurum ya da süresi dolmuş veri taşıyan eski soru arşive
    $mu=@(MulgaKapisi $cvp); if($mu.Count){ Dus $id $e ("KAPI-M mülga mevzuat: "+($mu -join '; ')); continue }
    $su=@(SureKapisi $cvp); if($su.Count){ Dus $id $e ("KAPI-S süresi dolan veri: "+($su -join '; ')); continue }
    if("$($e.kanun_no)".Trim() -match '^(6762|818|5422|506|1479|2499|1050|4077|1086|743|765|2821|2822|4389)$'){ Dus $id $e "KAPI-M: eski künye mülga kanuna bağlı ($($e.kanun_no) sayılı)"; continue }
    # kaynak paketi: damga → kanun/madde → köprü deseni
    # madde_damga bir ÖZET (hash), künye değil → kanun_no + madde_no, yoksa eski 'kaynak' metni (08.09 ölçümü: damga 'fa94e38b…' çıktı)
    $day=$(if("$($e.kanun_no)".Trim() -match '^\d{3,5}$'){ "$($e.kanun_no) sayılı Kanun$(if("$($e.madde_no)".Trim()){ " m.$($e.madde_no)" })" } else { "$($e.kaynak)" })   # kanun_no 'THP'/'TMS' gibi ise (sayı değil) eski 'kaynak' künyesi ("THP 521", "TMS 2 p.10") kullanılır
    $ds=@(DesenUret ([pscustomobject]@{ konu="$($e.konu)"; dayanak=$day; cikmis_dayanak='' }))
    # eski künye "THP 521" / "THP 521, 520" ise o hesap(lar) kaynak paketinin BAŞINA (08.09 ölçümü: konu adı 110/118/240'ı çekti, 521 gelmedi)
    foreach($mm in [regex]::Matches($day,'(?i)\bTHP\s*(\d{3})')){ $ds=@("THP $($mm.Groups[1].Value) %")+@($ds) }
    $amb=AmbarCek $ds
    if(-not $amb.metin -or $amb.metin.Length -lt 200){ Dus $id $e "kaynak ambarda bulunamadı (dayanak: $day)"; continue }
    $sikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $($e.siklar.$_)" }) -join "`n"
    $acikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $(if($e.aciklama){ AciklamaDuz $e.aciklama.$_ })" }) -join "`n"
    $kMet=$amb.metin; if($kMet.Length -gt 6000){ $kMet=$kMet.Substring(0,6000) }
    $istU=$uyarIstem.Replace('{SORU}',"$($e.soru)").Replace('{SIKLAR}',$sikM).Replace('{DOGRU}',"$($e.dogru)").Replace('{ACIK}',$acikM).Replace('{KAYNAK}',$kMet)
    $yU=$null; foreach($d in 1..3){ try{ $yU=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istU -MaxTok 7000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
    Write-Host ("  UYARLAMA TOKEN {0}: girdi {1} · cikti {2} · model claude-sonnet-5" -f $id,$yU.girdi,$yU.cikti) -ForegroundColor DarkGray
    $u=Coz $yU.metin
    if(-not $u -or -not $u.PSObject.Properties['teshis'] -or -not $u.teshis){ Dus $id $e "uyarlama çıktısı bozuk (durma=$($yU.dur))"; continue }
    foreach($alan in 'cozum_tablo','teshis','celdirici_yol','verilenler','dayanak','sema'){ if($u.PSObject.Properties[$alan] -and $null -ne $u.$alan){ $cvp | Add-Member -NotePropertyName $alan -NotePropertyValue $u.$alan -Force } }
    $hesapMi=EskiSayiSikli $cvp
    if($hesapMi -and -not ($cvp.PSObject.Properties['cozum_tablo'] -and $cvp.cozum_tablo -and @($cvp.cozum_tablo.satirlar).Count -ge 2)){ Dus $id $e 'hesap sorusu, çözüm tablosu çıkarılamadı'; continue }
    if($hesapMi){ $yolYok=@(); if($cvp.PSObject.Properties['celdirici_yol'] -and $cvp.celdirici_yol){ foreach($p in $cvp.celdirici_yol.PSObject.Properties){ if("$($p.Value)" -match 'YOL YOK'){ $yolYok+=$p.Name } } }; if($yolYok.Count){ Dus $id $e "çeldirici yolu yok: şık $($yolYok -join ',') rastgele sayı (KAPI-Ç, B4)"; continue } }
    $hk=@(HesapKodKapisi $cvp); if($hk.Count){ Dus $id $e "kod-ad çifti tutmuyor: $($hk -join '; ')"; continue }
    $cy=@(CeldiriciYolKapisi $cvp); if($cy.Count){ Dus $id $e "çeldirici yolu hesaplanmıyor: $($cy -join '; ')"; continue }
    $cvp | Add-Member -NotePropertyName hesap_kod -NotePropertyValue @() -Force
    $kpAt=$null; $cvp | Add-Member -NotePropertyName kaynak_metin_ozet -NotePropertyValue (PaketKirp $amb.metin "$($cvp.konu)" 4500 ([ref]$kpAt)) -Force
    if($kpAt -and @($kpAt).Count){ Write-Host "  KAPI-KP: $id paket 4500 krk -> konu disi $(@($kpAt).Count) kaynak komple dusuruldu: $(@($kpAt | Select-Object -First 2) -join ' ; ')" -ForegroundColor DarkCyan }
    $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb.adlar) -Force
    $cvp | Add-Member -NotePropertyName uyarlama -NotePropertyValue ([pscustomobject]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); model='claude-sonnet-5'; girdi=[int]$yU.girdi; cikti=[int]$yU.cikti; hesap=$hesapMi }) -Force
    DilOnarNesne $cvp
    $don[$id]=$cvp; CacheYaz
    Write-Host "  UYARLAMA OK $id [$($e.konu)] $(if($hesapMi){'hesap'}else{'teori/kayıt'})" -ForegroundColor Green
  }
  [IO.File]::WriteAllText($dusenYol,(ConvertTo-Json -InputObject @($dusenL.ToArray()) -Depth 4),[Text.UTF8Encoding]::new($false))
  "FAZ U bitti: uyarlanan $(@($don.Keys | Where-Object { $_ -like 'e-*' }).Count) · düşen $($dusenL.Count) -> $dusenYol"
}
foreach($gecisA in @(1,2)){ if($gecisA -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisA -eq 1); $rapor0=$rapor.Count; $kb0=$kaynakBorcu.Count
foreach($kk in $KONULAR){
  $id=$kk.id
  if($SadeceHtml){ continue }   # yalniz cizim: cache neyse o (konu degisse de dusurulmez), uretim yok
  # 03.09 OLCULDU (pilot kp-04): kopru konusu degisince FAZ A pilot soruyu DUSURUP YENIDEN URETTI (2 cagri, gider
  # tahakkuku sorusu silindi). Pilot yalniz ADIM/ikiz/yevmiye/hakem fazlari icindir: FAZ A'da SORU ASLA uretilmez.
  if($PilotId){ continue }
  if($HazirSoru){ continue }   # 09.09 FAZ GM: hazır soru modunda FAZ A HİÇ soru üretmez (bedel 0); soru kaynağı dosyadır, FAZ GM bloğu aşağıda
  # 02.09: cache id-bazli; konu listesi degisince (dislama kalkti/yeni konu girdi)
  # ayni id ESKI konunun sorusunu tasir ve sayfa yanlis konuyu gosterir. Konu
  # farkliysa kayit dusurulur, yeniden uretilir.
  if($don.Contains($id) -and $don[$id].soru -and "$($don[$id].konu)" -ne "$($kk.kayit.konu)"){
    Write-Host "  CACHE DUSTU (konu degisti): $id '$($don[$id].konu)' -> '$($kk.kayit.konu)'" -ForegroundColor Yellow
    $don.Remove($id)
  }
  # 03.09 (Cem "1.2.3 yap" -> 3): cache KONU anahtarli kurtarma. Kopru degisince ayni konu
  # baska id'ye kayiyor ve yeniden uretiliyordu (02.09 gecesi 6+ soru bosa gitti). Bu id
  # bos ve AYNI konunun sorusu cache'te baska bir id'de (o id'nin yeni konusu farkli) duruyorsa
  # tasinir; para harcanmaz. Sadece bu KONULAR listesinde o id'ye artik baska konu dustuyse.
  if(-not ($don.Contains($id) -and $don[$id].soru)){
    $konuAd="$($kk.kayit.konu)"
    $eskiId=$null
    foreach($ek in @($don.Keys)){
      if($ek -eq $id){ continue }
      if("$($don[$ek].konu)" -ne $konuAd){ continue }
      $ekSahibi=$KONULAR | Where-Object { $_.id -eq $ek } | Select-Object -First 1
      if(-not $ekSahibi -or "$($ekSahibi.kayit.konu)" -ne $konuAd){ $eskiId=$ek; break }
    }
    if($eskiId){ $don[$id]=$don[$eskiId]; $don.Remove($eskiId); CacheYaz; Write-Host "  CACHE TASINDI (konu anahtari): $eskiId -> $id '$konuAd'" -ForegroundColor DarkGray }
  }
  # 02.09: HAKEM REDDI + kaynak degisti -> yeniden bas. Hakem "dayanak kaynaktan
  # cikmiyor" dediyse ve o konuya sonradan elle olculmus OZEL_DESEN eklendiyse,
  # soru ESKI yanlis kaynakla uretilmis demektir; cache'te birakmak reddi kalicilastirir.
  if($don.Contains($id) -and $don[$id].soru -and $don[$id].PSObject.Properties['hakem'] -and "$($don[$id].hakem.karar)" -ne 'EVET' -and $OZEL_DESEN.ContainsKey("$($kk.kayit.konu)".ToLowerInvariant())){
    $eskiKaynak=(@($don[$id].kaynak_adlar) | Select-Object -First 1)
    Write-Host "  CACHE DUSTU (hakem reddi + yeni kaynak): $id $($kk.kayit.konu) [eski: $eskiKaynak]" -ForegroundColor Yellow
    $don.Remove($id)
  }
  # ayni mantik DERS-DISI icin: KAPI C 'baska dersin sorusu' dediyse ve konuya
  # sonradan OZEL_NOT (ders acisi duzeltmesi) yazildiysa soru yeniden kurulur.
  if($don.Contains($id) -and $don[$id].soru -and $don[$id].PSObject.Properties['hakem'] -and "$($don[$id].hakem.ders_uyum)" -eq 'DERS-DISI' -and $OZEL_NOT.ContainsKey("$($kk.kayit.konu)".ToLowerInvariant())){
    Write-Host "  CACHE DUSTU (ders-disi + ders acisi notu): $id $($kk.kayit.konu)" -ForegroundColor Yellow
    $don.Remove($id)
  }
  # 03.09 -RedYenile: arama/profil duzeltmesinden sonra hakemin reddettigi sorular yeniden
  # (kaynak degismis olabilir; red kalici kalmasin). Yalniz bayrakla - normalde para harcanmaz.
  if($RedYenile -and $don.Contains($id) -and $don[$id].soru -and $don[$id].PSObject.Properties['hakem'] -and ("$($don[$id].hakem.karar)" -ne 'EVET' -or "$($don[$id].hakem.ders_uyum)" -eq 'DERS-DISI' -or "$($don[$id].hakem.konu_uyum)" -eq 'KONU-DISI' -or "$($don[$id].hakem.tek_anlam)" -eq 'CIFT-ANLAM')){
    Write-Host "  CACHE DUSTU (-RedYenile: hakem $($don[$id].hakem.karar)/$($don[$id].hakem.ders_uyum)): $id $($kk.kayit.konu)" -ForegroundColor Yellow
    $don.Remove($id)
  }
  # 02.09 uzunluk kapisi GERIYE DONUK: tavani asan eski sorular yeniden basilir
  # (soru degisince adim/ikiz/yevmiye de dusurulur ki tutarli kalsin).
  if($don.Contains($id) -and $don[$id].soru -and "$($don[$id].soru)".Length -gt $UZUNLUK_TAVAN){
    Write-Host "  CACHE DUSTU (uzun: $("$($don[$id].soru)".Length) kr > $UZUNLUK_TAVAN): $id $($kk.kayit.konu)" -ForegroundColor Yellow
    $don.Remove($id)
  }
  if($don.Contains($id) -and $don[$id].soru){
    # 06.09: eldeki soruya çapa metni sonradan eklenir (model çağrısı yok) — giriş kartı "Sınavda böyle çıktı"
    if($CAPA.ContainsKey($id) -and -not ($don[$id].PSObject.Properties['capa_metin'] -and "$($don[$id].capa_metin)".Trim())){ $don[$id] | Add-Member -NotePropertyName capa_metin -NotePropertyValue "$($CAPA[$id])" -Force; if($kk.kayit.PSObject.Properties['capa_kaynak']){ $don[$id] | Add-Member -NotePropertyName capa_kaynak -NotePropertyValue "$($kk.kayit.capa_kaynak)" -Force }; CacheYaz; Write-Host "  çapa metni eklendi: $id" -ForegroundColor DarkGray }
    continue }
  $ky=$kk.kayit
  $konuLc="$($ky.konu)".ToLowerInvariant()
  # 06.09 fmuh-k10b dersi: köprü konusu "duran varlik (sabit kiymet) satisi kaydi" iken elle ölçülmüş desen "duran varlik satisi" (THP 253/257/679/689,
  # VUK 328) BİREBİR eşleşmediği için genel desen THP 197/199/248 çekti → hakem HAYIR. Birebir yoksa: desen anahtarının bütün kökleri konuda geçiyorsa o desen.
  if(-not $OZEL_DESEN.ContainsKey($konuLc)){
    $konuKok=@((Katla2 $konuLc) -split '\s+' | Where-Object { $_.Length -ge 4 } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } })
    $enA=$null; $enN=0
    foreach($ak in $OZEL_DESEN.Keys){ $akK=@((Katla2 $ak) -split '\s+' | Where-Object { $_.Length -ge 4 } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } }); if(-not $akK.Count){ continue }; $ortak=@($akK | Where-Object { $konuKok -contains $_ }).Count; if($ortak -eq $akK.Count -and $akK.Count -gt $enN){ $enN=$akK.Count; $enA=$ak } }
    if($enA -and $enN -ge 2){ Write-Host "  OZEL_DESEN kök eşleşmesi: '$konuLc' -> '$enA'" -ForegroundColor DarkGray; $konuLc=$enA }
  }
  $desenler=if($OZEL_DESEN.ContainsKey($konuLc)){ $OZEL_DESEN[$konuLc] } else { DesenUret $ky }
  $script:AMBAR_AG_HATASI=$null
  $amb=AmbarCek $desenler
  # AG HATASI != KAYNAK YOK. Olculemeyen konu borca yazilmaz, ayri raporlanir.
  if($amb.agHatasi -and (-not $amb.metin -or $amb.metin.Length -lt 300)){
    $rapor.Add("OLCULEMEDI (ag hatasi, kaynak borcu DEGIL): $($ky.konu)")
    Write-Host "  AG HATASI (kaynak cekilemedi, tekrar denenecek): $($ky.konu)" -ForegroundColor Magenta
    continue
  }
  # 08.09 Tur 1 Vergi kolay ÖLÇÜLDÜ: "kurumlar vergisi mukellefleri / asgari kurumlar vergisi / kurumlar vergisi istisnasi" KAYNAK BORCU çıktı;
  # oysa KVK m.2 / m.32 / m.5 ambarda (680 KVK kaydı). Köprü dayanağı eski Seri No 86 tebliğiydi: güncellik kapısı onu eledi, dayanak "zayıf"
  # sayılmadığı için (kanun numarası yok) dersin ana kanunlarında '@' araması hiç yapılmadı → boş. İKİNCİ DENEME: dayanaksız/zayıf sayılarak
  # ders kanunları + teori notlarında konu köküyle yeniden aranır; yine boşsa gerçek borçtur.
  if(-not $amb.metin -or $amb.metin.Length -lt 300){
    $kyZ=[pscustomobject]@{ konu="$($ky.konu)"; dayanak=''; cikmis_dayanak=''; guc='ZAYIF' }
    $desen2=@(DesenUret $kyZ | Where-Object { $desenler -notcontains $_ })
    if($desen2.Count){
      $script:AMBAR_AG_HATASI=$null; $amb2z=AmbarCek $desen2
      if($amb2z.metin -and $amb2z.metin.Length -ge 300){ Write-Host "  KAYNAK İKİNCİ DENEME (ders kanunu/teori, dayanaksız arama): $($ky.konu) <- $(@($amb2z.adlar | Select-Object -First 3) -join ' ; ')" -ForegroundColor DarkCyan; $rapor.Add("KAYNAK IKINCI DENEME: $($ky.konu) <- $(@($amb2z.adlar | Select-Object -First 3) -join ' ; ')"); $amb=$amb2z; $desenler=@($desenler)+$desen2 }
    }
  }
  if(-not $amb.metin -or $amb.metin.Length -lt 300){
    $kaynakBorcu.Add("[$($ky.donem) donem] $($ky.konu) | dayanak: $($ky.dayanak) / $($ky.cikmis_dayanak)")
    Write-Host "  KAYNAK BORCU: $($ky.konu)" -ForegroundColor Yellow
    continue
  }
  # KAPI A (01.09 Cem: "boyle yanlislar olursa ben yanarim"): kaynak-konu ALAKA denetimi.
  # Konu kelime koklerinden en az biri kaynak metninde gecmeli; gecmiyorsa kaynak
  # ALAKASIZ demektir (haritanin yanlis dayanagi ambarda var diye soruya sizamaz).
  # 10. Turkce vakasi: kokler ve metin AYNI katlamadan gecmeli ('dagiti' vs 'dağıtı')
  function KokKatla([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
  $konuKokler=@(("$($ky.konu)" -split '\s+') | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^\d' } | ForEach-Object { $k2=KokKatla $_; if($k2.Length -ge 6){ $k2.Substring(0,$k2.Length-2) } else { $k2 } })
  $ambLc=KokKatla $amb.metin
  $alaka=($konuKokler.Count -eq 0) -or (@($konuKokler | Where-Object { $ambLc.Contains($_) }).Count -ge 1)
  # 02.09: OZEL_DESEN'deki kaynaklar ELLE OLCULEREK secildi (konu-kaynak eslesmesi
  # GM tarafindan dogrulandi). Kok-arama orada yanlis red uretebilir - ornegin
  # 'ozkaynak' kelimesi THP 500 SERMAYE metninde gecmeyebilir ama kaynak DOGRUDUR.
  # Guvenlik kaybi yok: dayanak hakemi (KAPI B) bu sorulari yine de siniyor.
  if(-not $alaka -and $OZEL_DESEN.ContainsKey($konuLc)){
    $alaka=$true
    Write-Host "  KAPI-A atlandi (OZEL_DESEN elle dogrulanmis): $($ky.konu)" -ForegroundColor DarkGray
  }
  if(-not $alaka){
    if($amb.agHatasi){
      $rapor.Add("OLCULEMEDI (ag hatasi, eksik kaynakla alaka denetimi): $($ky.konu)")
      Write-Host "  AG HATASI (eksik kaynak - KAPI-A guvenilmez): $($ky.konu)" -ForegroundColor Magenta
      continue
    }
    $kaynakBorcu.Add("[$($ky.donem) donem] $($ky.konu) | KAPI-A: cekilen kaynak konuyla ALAKASIZ ($((@($amb.adlar)|Select-Object -First 2) -join '; '))")
    Write-Host "  KAPI-A RED (alakasiz kaynak): $($ky.konu)" -ForegroundColor Yellow
    continue
  }
  $ekNot=if($OZEL_NOT.ContainsKey($konuLc)){ "`nOZEL UYARI: $($OZEL_NOT[$konuLc])" } else { '' }
  # 05.09 Cem "soru zor değildi; sınavda en çok çıkan konu, zor ve katmanlı olsun": zorluk kelime sayısında değil KATMAN sayısında.
  if($Zorluk -eq 'zor'){ $ekNot+=@"

ZORLUK: ZOR VE KATMANLI (sınavın en zor sorusu ayarı):
(a) Çözüm en az DÖRT bağlı ara hesap ister; her ara hesap bir öncekinin sonucunu kullanır (biri atlanırsa sonraki bulunamaz).
(b) Konunun tek yöntemi değil, gerçek sınavın BİRLEŞTİRDİĞİ katmanlar birlikte gelir. Örnek (ortak maliyet): yan ürünün net
    gerçekleşebilir değeri ortak maliyetten düşülür → kalan ortak maliyet ayrılma noktasındaki satış değerine göre dağıtılır →
    ayrılma sonrası ek işleme maliyeti eklenir → istenen ürünün birim maliyeti ya da brüt kârı bulunur. Başka konuda aynı mantık:
    dönem başı yarı mamul + eşdeğer birim + fire, ya da kapasite sapması + bütçe sapması + yükleme farkı birlikte.
(c) HER YANLIŞ ŞIK bir katmanın ATLANMASINDAN ya da yanlış sırada yapılmasından TÜRETİLİR: soru verisiyle hesaplanabilir bir tutar
    olur, uydurma rakam YOK; açıklamasında o yanlış hesap yolu rakamlarıyla yazılır ("yan ürün değeri düşülmeden 600.000 × %40 = ...").
(d) Gövde hikâye değil yoğun veridir; uzunluk tavanı yine geçerlidir. Zorluk katman sayısında ve verinin işlenme sırasındadır.
(e) Çözüm tablosunda her katman AYRI SATIR olur (yan ürün NGD, dağıtıma esas ortak maliyet, ürün payı, ek işleme, toplam, birim);
    SON SATIR istenen büyüklüktür.
(f) Kök tek anlamlıdır: istenen büyüklüğü adıyla ve hangi ürün için olduğunu açıkça söyle.
(g) GÖVDE SINAV GİBİ KURULUR (05.09 ölçüm: 13 dönemin ortak maliyet soruları okundu). Sınav, yöntemi ve işletme POLİTİKASINI
    tek cümlede söyler, ÇÖZÜM SIRASINI anlatmaz. Sınav cümlesi: "İşletme, ortak maliyetlerin dağıtımında mamullerin beklenen satış
    değerlerini dikkate almakta ve yan mamullerin net gerçekleşebilir değerini ortak maliyetten çıkararak hesaplama yapmaktadır."
    YASAK: "bu tutar düşülür, kalan dağıtılır, sonra eklenir" gibi adım adım tarif. Veriler sınavdaki gibi TABLO cümlesiyle verilir
    ("Dönemde üretilen mamuller ve piyasa satış değerleri aşağıdaki gibidir: A Mamulü 6.000 br 3,00 TL/br ..."). Kök sınav kalıbı:
    "Buna göre, K mamulünün ortak maliyetten alacağı pay kaç TL'dir?" / "... ton başına maliyeti kaç TL'dir?"
(h) ZORLUK KAYNAKLARI SINAVDAN (ölçülen): yan ürünün net gerçekleşebilir değeri (satış değeri − yan ürünü satılabilir kılma ek maliyeti)
    ortak maliyetten düşülür · ayrılma sonrası ek maliyet + nihai satış değeri (net gerçekleşebilir değer yöntemi) · birim KÂR istenir
    (satış fiyatı − birim maliyet) · TERS SORU (pay verilir, üretim miktarı ya da satış fiyatı istenir) · "piyasa değeri yöntemine göre
    dağıtsaydı" karşılaştırması. En az İKİ zorluk kaynağı birlikte kullanılır.
"@ }
  # 08.09 (SORU-BASMA-KURALLARI 1.7 / 1.10, Cem "kolay zor çok zor"): üç seviye. Aynı konu üç ayrı geçişte üç seviyede basılır; her seviye kendi etiketinde.
  if($Zorluk -eq 'kolay'){ $ekNot+=@"

ZORLUK: KOLAY (sınavın açılış sorusu ayarı — çıkmış soruların %42'si bu bandda):
(a) TEK kural, TEK işlem: öğrenci kuralı biliyorsa tek adımda (en çok iki ara hesapla) cevaba ulaşır.
(b) Veri az ve doğrudan: soru en çok 3 sayı verir; çeldirici veri (hesaba girmeyen kalem) en çok bir tane.
(c) Yanlış şıklar yine gerçek yanlış yoldur (işaret hatası, yanlış hesap, kuralı tersten uygulama); rastgele sayı yok.
(d) Gövde kısa (dersin medyanının altı), kök doğrudan: "… kaç TL'dir?" / "… hangisidir?". Teori sorusunda tek madde/paragraf, tek kavram.
"@ }
  if($Zorluk -eq 'cokzor'){ $ekNot+=@"

ZORLUK: ÇOK ZOR (sınavın en zor %7'si — elemeyi belirleyen soru ayarı):
(a) ZOR ayarının her şartı geçerlidir (≥4 bağlı ara hesap, katman birleşimi, çeldirici = atlanan katman, gövde sınav gibi).
(b) ÜSTÜNE üçünden en az ikisi: TERS SORU (sonuç verilir, girdi istenir) · ÇELDİRİCİ VERİLEN (soruda geçen ama hesaba girmeyen, adayın
    katmaya meyilli olduğu kalem; "Dahil değil" satırı bunu açıklar) · İKİ KURALIN KESİŞİMİ (iki madde/standart aynı olayda birlikte;
    biri unutulursa şıklardan biri çıkar).
(c) Yanlış şıklar bu iki-üç tuzağın tek tek düşülmesinden türer; iki tuzağa birden düşenin şıkkı da vardır.
(d) Kök yine tek anlamlı; uzunluk tavanı geçerli (zorluk katman ve tuzak sayısında, kelime sayısında değil). Teori sorusunda: iki paragrafın
    kesişimi, istisnanın istisnası, ya da "hangisi HER ZAMAN doğrudur" gibi mutlak kök — ama sızıntı kuralı 4c korunur.
"@ }
  # 11.09 Cem "belgeyi FAZ A'ya baglayalim": rol basligi istemin BASINA konur.
  # Kategori dersten turetilir, hesap/standart kumeleri makineden gelir.
  # Kategori cozulemezse baslik EKLENMEZ (bos string) - eski davranis korunur.
  $rolB = RolBasligi $DersRegex "$($ky.konu)"
  $ist=$rolB + $soruIstem.Replace('{YIL}',"$((Get-Date).Year)").Replace('{SIK_KALIP}',$SIK_KALIP).Replace('{DIL}',$(if($script:YD_MOD){ $DIL_KURAL + $YD_DIL_KURAL } else { $DIL_KURAL })).Replace('{SINAV}',$Sinav).Replace('{DERS}',$DersRegex).Replace('{DERS_TARIF}',$DERS_TARIF).Replace('{KONU}',"$($ky.konu)").Replace('{DONEM}',"$($ky.donem)").Replace('{ORNEK}',$(if($CAPA.ContainsKey($id)){ $CAPA[$id] } else { $ornekSoru })).Replace('{KAYNAK}',$amb.metin).Replace('{TAVAN}',"$UZUNLUK_TAVAN").Replace('{KALIP}',$(if($KALIP_TIP){"medyan uzunluk $UZUNLUK_TAVAN kr civari, tip dagilimi $KALIP_TIP"}else{"medyan $UZUNLUK_TAVAN kr"})).Replace('{TIP_TARIF}',$(
    $buTip=''
    if($TIP_HEDEF.Count){ $ix=($KONULAR.IndexOf($kk)); if($ix -lt 0){ $ix=0 }; if($ix -lt $TIP_HEDEF.Count){ $buTip=$TIP_HEDEF[$ix] } }
    if($CAPA_TIP.ContainsKey($id) -and $TIP_TARIF.ContainsKey($CAPA_TIP[$id])){ $buTip=$CAPA_TIP[$id]; Write-Host "  tip çapadan: $id -> $buTip" -ForegroundColor DarkGray }   # 06.09: çapa teori ise soru teori (fmuh-k10 dersi)
    if($buTip -and $TIP_TARIF.ContainsKey($buTip)){ $TIP_TARIF[$buTip] } else { 'Konuya en uygun tipi sec (kayit / hesaplama / teori).' }
  ))+$ekNot
  # UZUNLUK KAPISI (02.09): asan soru KABUL EDILMEZ - 2 kez kisaltma istenir.
  # 02.09 HIZ: MaxTok 20.000'di ama gercek cevap ~1.900 karakter (olculdu) - yuksek
  # tavan modeli uzun dusundurup cagriyi yavaslatiyordu. 8.000 fazlasiyla yeter.
  # Uzunluk kapisi da 3 denemeden 2'ye indi: 30 soruluk parti 4,5 saatten ~25 dk'ya iner.
  if($script:ON_GECIS){ TopluTopla $id 'claude-sonnet-5' $ist 20000; continue }   # 1. geçiş: yalnız istemi topla (kaynak/çapa aynı koddan kuruldu)
  $cvp=$null
  foreach($deneme in 1..2){
    $istBu=$ist
    if($deneme -gt 1){ $istBu=$ist+"`nDIKKAT: onceki denemende soru govdesi TAVANI ASTI. Bu kez $UZUNLUK_TAVAN karakteri KESINLIKLE asma - senaryoyu tek isleme indir, hikayeyi at." }
    $y=$null
    # 02.09 gece KGK partisinde OLCULDU: KGK sorularinin HEPSI 8k'da kesilip 20k ile yeniden
    # gidiyor (her soru iki cagri = iki kat sure). KGK/SMMM uzun kaynak metniyle dusunuyor;
    # onlarda tavan bastan 20k. SGS 8k'da kaliyor (26/30 gecti).
    # 06.09 ölçüldü (parti-1): -Zorluk zor ile HER soru 8k'da kesilip 20k ile yeniden çağrıldı (soru başına 1 boş çağrı, ~3 dk).
    # Zor ayarında ilk tavan doğrudan 20k; sade SGS'de 8k kalır.
    # 06.09 Parti-2 ölçümü: normal ayarda da 8 sorunun 4'ü 8k'da kesildi (Denetim 3/4, MTA 1/4) → her kesik = bir boş çağrı. Tek tavan 20k.
    $ilkTavan=20000
    $y=$(if($deneme -eq 1){ TopluAl 'A' $id } else { $null })   # 08.09 toplu: 1. denemenin cevabı partiden gelir; yoksa ya da tekrarda anlık
    if(-not $y){ foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model $SoruModel -Icerik $istBu -MaxTok $ilkTavan; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } } }
    # 02.09 gece OLCULDU (bozuk-*.txt kapisi sayesinde): 4 konu "durma=max_tokens, 0 kr"
    # ile bozuktu - model 8.000 jetonun TAMAMINI dusunmeye harcayip metin yazamadan
    # kesiliyor (OpenRouter hattinda akil yurutme jetonu max_tokens'a dahil). Hiz icin
    # 20k->8k indirilen tavan bu 4 konuyu oldurdu. Cozum: bos+kesik cevapta BIR KEZ
    # 20.000 ile yeniden dene; diger 26 soru 8k'da kaldigi icin hiz kaybi yok.
    # (kp-21 ile ikinci yuz: 1.962 kr yazip JSON'un ortasinda kesilmek - metin var ama
    # cozulmuyor. Iki hal de ayni ilac: kesik + cozulemeyen cevap => 20k ile bir kez daha.)
    if("$($y.dur)" -eq 'max_tokens' -and (-not "$($y.metin)".Trim() -or -not (Coz $y.metin))){
      Write-Host "  KESIK ($id): 8k tavanda kesildi ($("$($y.metin)".Length) kr), 32k ile yeniden" -ForegroundColor DarkYellow   # 07.09: 20k'da zor Maliyet iki kez kesildi (düşünme jetonları) → 32k + effort=medium (api-hedef)
      foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model $SoruModel -Icerik $istBu -MaxTok 32000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
    }
    $aday=Coz $y.metin
    if(-not ($aday -and $aday.soru -and $aday.aciklama)){
      # 02.09 KAPI 4. KATMAN: "BOZUK" tek basina hicbir sey soylemiyordu (kp-05/06 iki
      # koşuda da bozuk cikti, sebep gorulemedi). Ham cevap + durma sebebi dosyaya yazilir.
      $bozukYol=Join-Path $kok ("veri\fabrika\bozuk-$Etiket-$id-d$deneme.txt")
      $sebep=if(-not $aday){ 'JSON COZULEMEDI' } elseif(-not $aday.soru){ 'soru alani yok' } else { 'aciklama alani yok' }
      [IO.File]::WriteAllText($bozukYol,("sebep: $sebep | durma: $($y.dur) | cikti token: $($y.cikti) | uzunluk: $("$($y.metin)".Length) kr`n`n$($y.metin)"),[Text.UTF8Encoding]::new($false))
      Write-Host "  BOZUK SEBEP ($id d$deneme): $sebep, durma=$($y.dur), $("$($y.metin)".Length) kr -> $(Split-Path $bozukYol -Leaf)" -ForegroundColor DarkYellow
      continue
    }
    # 08.09: kapılardan ÖNCE yazım onarımı (YazimOnar sözlüğü: dogrusu→doğrusu, hesabi→hesabı…) — kapı yalnız sözlüğün düzeltemediğini düşürür,
    # böylece bilinen ASCII kalıntısı için para harcanıp yeniden yazdırılmaz (pilot6: "yillik, asagidakilerden, hesabi" 3 kapı turu yaktı)
    YazimOnarNesne $aday
    DilOnarNesne $aday   # 08.09 Cem "soru kalıpları / genel yönetim gideri": sınav dili terim çiftleri (genel idare→genel yönetim, DİMM açılımı…) kapılardan ÖNCE uygulanır
    $uz="$($aday.soru)".Length
    # 04.09 KAPI-Ş (şık dengesi): tutar+yön şıklarında her tutar iki yönle geçmeli; tek çift = cevap belli.
    $sikKusur=SikDengesi $aday; if(-not $sikKusur){ $sikKusur=SikBicimi $aday }   # KAPI-Ş: yön dengesi + sayı/cümle/biçim
    $hkKusur=@(HesapKodKapisi $aday)   # 06.09 KAPI-H: hesap kodu–resmî ad eşleşmesi
    $kvKusur=$(if($script:YD_MOD){ @() } else { @(PencereKavram "$($aday.soru)") })   # 06.09 KAPI-K: gövdede son N dönem sınavında hiç geçmeyen kök (anormal, kusurlu…); YD modunda kapalı (İngilizce sözlük 70 blok)
    # 08.09 Tur 1 denetim-cokzor ölçümü: 43 KAPI-K tekrarının çoğu TEK sıradan kelime ("teyide, edindiği, kesiksiz, çözülmüş") — pencere sözlüğü
    # 119 soruluk, her Türkçe kelimeyi içermiyor. Tek kelime = rapor notu (tekrar yok); ≥2 kelime yine tekrar (Cem'in "anormal düzeltme" vakası 2 kelimeydi).
    if($kvKusur.Count -eq 1){ $rapor.Add("KAPI-K NOTU (tek kelime, tekrar yok): $id | $($kvKusur[0])"); $kvKusur=@() }
  # 11.09 KAPI-KE: soru verilen konuyu mu ölçüyor? Yalnız 1. denemede tekrar
  # ister; 2. denemede de düşerse soru kabul edilir, rapora not düşer. Sapmayı
  # azaltmak için, doğru soruyu öldürmek için değil (bkz. fonksiyon başlığı).
  # ⚠ Bu döngüde konu kaydı $ky'dir ($kayit DesenUret'in parametresidir; yanlış
  #   yazılsaydı boş metin gider, kapı hiç düşmez ve "kapı var" yanılgısı olurdu.)
  # ⚠ YENİDEN YAZDIRMIYOR — BİLEREK. İlk tasarım "düşerse tekrar yaz" idi;
  #   geriye dönük sınandı (635 basılı soru, bedel 0): kapı 97 soru düşürürdü,
  #   bunların yalnız 34'ü anlam turunda gerçekten yanlıştı → %35 isabet.
  #   63 doğru soru boşuna yeniden yazdırılırdı ve daha kötüsü, modele "etiketin
  #   kelimeleri soru kökünde geçsin" dedirtmek soruyu YAPAYLAŞTIRIR: gerçek
  #   sınav sorusu konusunun adını söylemez ("makine satışı" der, "duran varlık
  #   satışı" demez — 11.09'da elle okunan vaka).
  #   O yüzden kapı SORUYA DEĞİL, HAKEME bağlanır: şüpheli soruda hakemin
  #   konu_uyum denetimi özellikle uyarılır. Ölçüm hakemin bu sınıfı tamamen
  #   kaçırdığını gösterdi (71 yanlış etiketin 71'inde de "EVET" demişti).
  # --- KAPI-HS: hesap seti (11.09) -------------------------------------------
  # Muhurlu kalipta SERT (soru yeniden yazdirilir), muhursuzde hakeme uyari.
  # 11.09 KAPI-SS: anilan standart numarasi ambarda var mi (hesap kodunun dengi)
  $ssKusur=@(StandartSetiKapisi $aday)
  if($ssKusur.Count -and $deneme -eq 1){
    Write-Host "  KAPI-SS (standart seti) ($id): $($ssKusur[0]) - yeniden" -ForegroundColor Magenta
    $ist=$ist+"`nKAPI-SS DUSTU: $($ssKusur[0]). Ambarda bulunmayan standart numarasi ANMA; yalniz kaynak paketinde gordugun standartlari kullan."
    continue
  }
  if($ssKusur.Count){ Write-Host "  KAPI-SS NOTU ($id): $($ssKusur[0])" -ForegroundColor DarkYellow; $rapor.Add("KAPI-SS: $id | $($ssKusur[0])") }
  $hsKusur=@(HesapSetiKapisi $aday $DersRegex "$($ky.konu)")
  if($hsKusur.Count){
    $hsK=HesapKalibi $DersRegex "$($ky.konu)"
    if($hsK -and [bool]$hsK.dogrulandi -and $deneme -eq 1){
      Write-Host "  KAPI-HS (hesap seti, MUHURLU) ($id): $($hsKusur[0]) - yeniden" -ForegroundColor Magenta
      $ist=$ist+"`nKAPI-HS DUSTU: $($hsKusur[0]). Soruyu, konunun ONAYLI hesap kumesindeki hesaplarla yeniden yaz."
      continue
    }
    Write-Host "  KAPI-HS ISARETI ($id): $($hsKusur[0])" -ForegroundColor DarkYellow
    $aday | Add-Member -NotePropertyName hesap_seti_isareti -NotePropertyValue "$($hsKusur[0])" -Force
    $rapor.Add("KAPI-HS: $id | $($hsKusur[0])")
  }
  # 11.09 KAPI-KH: sik hesabi ADIYLA aniyor ama KODUNU yazmiyorsa KAPI-H
  # dogrulayamaz, KAPI-HS beyaz listeye sokamaz. Deyimler ("nam ve hesabina")
  # elenir. Olculdu: 48 sikta hesap adi var, 5'inde kod yok (3'u gercek).
  $khKusur=@(Get-KodsuzHesapAdi "$($aday.siklar.$($aday.dogru))")
  if($khKusur.Count -and $deneme -eq 1){
    Write-Host "  KAPI-KH (kodsuz hesap adi) ($id): $($khKusur -join ', ') - yeniden" -ForegroundColor DarkYellow
    $ist=$ist+"`nKAPI-KH DUSTU: sikta '$($khKusur -join ", ")' hesabi ADIYLA anilmis ama KODU yazilmamis. Her hesap adinin onune THP kodunu yaz (ornek: '521 Hisse Senedi Iptal Karlari')."
    continue
  }
  if($khKusur.Count){ Write-Host "  KAPI-KH NOTU ($id): kodsuz hesap adi -> $($khKusur -join ', ')" -ForegroundColor DarkGray; $rapor.Add("KAPI-KH: $id | kodsuz hesap adi: $($khKusur -join ', ')") }
  # 11.09 KAPI-KV: kok tam kayit vaat ediyorsa sik da tam kayit vermeli
  $kvKusur2=@(KokSikVaadiKapisi $aday)
  if($kvKusur2.Count -and $deneme -eq 1){
    Write-Host "  KAPI-KV (kok-sik vaadi) ($id): $($kvKusur2[0]) - yeniden" -ForegroundColor DarkYellow
    $ist=$ist+"`nKAPI-KV DUSTU: $($kvKusur2[0]). Ya siklari TAM KAYIT olarak yaz (borclu ve alacakli taraf birlikte), ya da soru kokunu tek tarafi soracak sekilde degistir."
    continue
  }
  if($kvKusur2.Count){ Write-Host "  KAPI-KV NOTU ($id): $($kvKusur2[0])" -ForegroundColor DarkGray; $rapor.Add("KAPI-KV: $id | $($kvKusur2[0])") }
  $keKusur=@(KonuEtiketKapisi $aday "$($ky.konu)")
  if($keKusur.Count){
    Write-Host "  KAPI-KE İŞARETİ ($id): $($keKusur[0]) → hakeme uyarı" -ForegroundColor DarkYellow
    $aday | Add-Member -NotePropertyName konu_sapma_isareti -NotePropertyValue "$($keKusur[0])" -Force
  }
    # 07.09 KAPI-T (fmuh-zor2 dersi, Ö53): çapa HESAPLAMA iken model tablosuz teori sorusu ("hangisi yanlıştır") yazdı; "tip çapadan"
    # yalnız istemdi, kapısı yoktu. Çapa hesaplama ise soru ≥2 satırlı çözüm tablosu taşımalı, yoksa yeniden (2 deneme).
    $tipKusur=''; if($CAPA_TIP.ContainsKey($id) -and $CAPA_TIP[$id] -eq 'hesaplama' -and -not ($aday.PSObject.Properties['cozum_tablo'] -and $aday.cozum_tablo -and @($aday.cozum_tablo.satirlar).Count -ge 2)){ $tipKusur='çapa hesaplama, soru tablosuz (teori biçimi)' }
    $cyKusur=@(CeldiriciYolKapisi $aday)   # 07.09 KAPI-Ç: her yanlış şık = gerçek bir yanlış yolun sonucu
    # 09.09 pilot3 (mat-kolay 0 soru): KAPI-Ç formülü makinede hesaplar; matematik dersinde yanlış yol fonksiyon/limit/türev gösterimi taşır
    # ("g(3)=2·3+1"), aritmetik ayrıştırıcı çözemez ve "çözülemedi" sert kapı olur. Genel kültürde ÇÖZÜLEMEDİ = not, YANLIŞ SONUÇ = kapı.
    if($script:GK_DERS -and $cyKusur.Count){
      $cyNot=@($cyKusur | Where-Object { $_ -match 'çözülemedi|hesaplanamadı' }); $cyKusur=@($cyKusur | Where-Object { $_ -notmatch 'çözülemedi|hesaplanamadı' })
      if($cyNot.Count){ Write-Host "  KAPI-Ç NOTU (genel kültür, tekrar yok) ($id): $($cyNot -join ' · ')" -ForegroundColor DarkGray; $rapor.Add("KAPI-C NOTU: $id | $($cyNot -join '; ')") }
    }
    # 07.09 KAPI-Y (Cem "2025 değil 2026 versin"): soruda yıl geçiyorsa en yenisi bugünün yılı olmalı ("2004 sayılı" gibi kanun numaraları sayılmaz)
    $yilKusur=''; $yilBu=(Get-Date).Year; $yillar=@([regex]::Matches("$($aday.soru)",'\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))') | ForEach-Object { [int]$_.Groups[1].Value }); if($yillar.Count -and (($yillar | Measure-Object -Maximum).Maximum -lt $yilBu)){ $yilKusur="sorudaki en yeni yıl $(($yillar | Measure-Object -Maximum).Maximum), bugün $yilBu" }
    # 07.09 A kovası 3 — KAPI-O KOKU (Cem 19.08 "öğrenci yapay zeka yazmış demesin"; kural yalnız kasa taramasındaydı, üreticide kapı yoktu, 21 soruda "ABC A.Ş." çıktı)
    $koKusur=@(KokuKusur $aday)
    # 07.09 A kovası 5 — KAPI-B BENZERLİK: çapaya (çıkmış soru) ve partideki diğer sorulara kelime kümesi benzerliği (telif + tekrar)
    $bzKusur=@(BenzerlikKusur $aday $id)
    # 08.09 Cem: "Türkçe kelime yazmalı · borç alacak düzgün atmalı" → KAPI-D2 Türkçe harf (sert) + KAPI-YD yevmiye dengesi (sert) + yön notu (rapor)
    $trKusur=@(TurkceKapisi $aday); $ydKusur=@(YevmiyeDengeKapisi $aday); $yonNot=@(YevmiyeYonNotu $aday)
    $paKusur=@(ParametreKapisi $aday)   # 08.09 KAPI-P: yıla bağlı had/oran soruda sayı olarak verilmeli
    $muKusur=@(MulgaKapisi $aday); $suKusur=@(SureKapisi $aday)   # 08.09 KAPI-M mülga mevzuat/kurum · KAPI-S süresi dolan veri (Cem "eski kanun, süresi dolan veri")
    if($uz -le $UZUNLUK_TAVAN -and -not $sikKusur -and -not $hkKusur.Count -and -not $kvKusur.Count -and -not $tipKusur -and -not $cyKusur.Count -and -not $yilKusur -and -not $koKusur.Count -and -not $bzKusur.Count -and -not $trKusur.Count -and -not $ydKusur.Count -and -not $paKusur.Count -and -not $muKusur.Count -and -not $suKusur.Count){ $cvp=$aday; if(SikSirala $cvp){ Write-Host "  ŞIK SIRALANDI ($id): doğru artık $($cvp.dogru)" -ForegroundColor DarkGray }; if($yonNot.Count){ Write-Host "  YEVMİYE YÖN NOTU ($id): $($yonNot -join ' · ') (kapatma/iade kaydıysa meşru; hakem2 bakar)" -ForegroundColor DarkYellow; $rapor.Add("YEVMIYE YON NOTU: $id | $($yonNot -join '; ')") }; $mNot=@(MulgaNotu $aday); if($mNot.Count){ $rapor.Add("KURUM ADI NOTU: $id | $($mNot -join '; ')") }; break }
    if($muKusur.Count){ Write-Host "  KAPI-M (mülga mevzuat) ($id): $($muKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-M DÜŞTÜ (mülga mevzuat/kurum): $($muKusur -join '; '). Soru yalnız YÜRÜRLÜKTEKİ kanun, standart ve kurum adıyla yazılır; eski kanun numarası, mülga standart, kapanmış kurum adı ve eski/yeni karşılaştırması geçmez. Kaynak paketindeki güncel metne dayan." }
    if($suKusur.Count){ Write-Host "  KAPI-S (süresi dolan veri) ($id): $($suKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-S DÜŞTÜ (süresi dolan veri): $($suKusur -join '; '). Geçmiş bir son tarihe ya da eski yılın had/oranına dayanan veri kullanılmaz; tarihler $((Get-Date).Year) ve sonrası olur, had/oran soruda sayı olarak verilir." }
    if($trKusur.Count){ Write-Host "  KAPI-D2 (Türkçe harf) ($id): $($trKusur -join ', ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-D2 DÜŞTÜ: şu kelimeler Türkçe harfsiz yazılmış: $($trKusur -join ', '). Bütün metinde ş, ç, ğ, ı, ö, ü, İ tam yazılır (için, değil, işletme, yıl, kâr)." }
    if($ydKusur.Count){ Write-Host "  KAPI-YD (yevmiye dengesi) ($id): $($ydKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-YD DÜŞTÜ: yevmiye kaydında borç toplamı alacak toplamına eşit değil ($($ydKusur -join '; ')). Her kayıtta borç = alacak; tutarları yeniden hesapla, gerekirse şıkları düzelt." }
    if($paKusur.Count){ Write-Host "  KAPI-P (yasal parametre) ($id): $($paKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-P DÜŞTÜ: $($paKusur -join '; '). Yıla bağlı her had/oran/tavan soruda SAYI olarak verilir ('KDV oranı %20', 'kıdem tazminatı tavanı 50.000 TL olduğu varsayılmıştır'); hafızadan yıl parametresi kullanılmaz." }
    if($yilKusur){ Write-Host "  KAPI-Y (yıl) ($id): $yilKusur - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-Y DÜŞTÜ: $yilKusur. Bütün yılları kaydır: sorulan dönem $yilBu olsun, eski tarihler aynı aralıkla kaysın (süreler değişmesin); şık tutarları buna göre yeniden hesaplansın." }
    if($koKusur.Count){ Write-Host "  KAPI-O (koku) ($id): $($koKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-O DÜŞTÜ (yapay zeka izi): $($koKusur -join '; '). Gerçek sınav sorusu gibi yaz: 'ABC/XYZ' gibi yer tutucu unvan yerine 'işletme' ya da gerçekçi bir ad; tutarların hepsi onbinlik yuvarlak olmasın (12.500, 47.350 gibi gerçekçi tutarlar karışsın; hesap yine düzgün çıksın); klişe kalıp ve uzun tire (—) yok." }
    if($bzKusur.Count){ Write-Host "  KAPI-B (benzerlik) ($id): $($bzKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-B DÜŞTÜ (benzerlik): $($bzKusur -join '; '). Örnek çıkmış soru yalnız BİÇİM çapasıdır; olayı, sayıları ve şık dizilimini kopyalama; aynı konuda özgün bir senaryo kur." }
    if($cyKusur.Count){ Write-Host "  KAPI-Ç (çeldirici yolu) ($id): $($cyKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-Ç DÜŞTÜ: $($cyKusur -join '; '). Her yanlış şık için celdirici_yol yaz: sayılı yanlış yol formülü, sonu '= <şık tutarı>' ve şık tutarı formülün GERÇEK sonucu olmalı; tutmuyorsa şık tutarını formülün sonucuna göre düzelt." }
    if($tipKusur){ Write-Host "  KAPI-T (soru tipi) ($id): $tipKusur - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-T DÜŞTÜ: örnek çıkmış soru HESAPLAMA sorusudur, sen teori sorusu yazdın. Soru sayısal veri verip 'kaç TL' diye sormalı ve en az 2 satırlı cozum_tablo taşımalı; 'hangisi yanlıştır/doğrudur' biçimi YASAK." }
    if($kvKusur.Count){ Write-Host "  KAPI-K (pencere dışı kavram) ($id): $($kvKusur -join ', ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-K DÜŞTÜ: şu kelimeler son $DonemPencere dönemin sınav sorularında HİÇ geçmiyor: $($kvKusur -join ', '). Sınavın sormadığı kavramla soru kurma; gövdeyi yalnız sınavda geçen kavramlarla (verilen örnek sorunun diliyle) yeniden yaz." }
    if($uz -gt $UZUNLUK_TAVAN){ Write-Host "  UZUN ($uz kr > $UZUNLUK_TAVAN) - yeniden: $($ky.konu)" -ForegroundColor DarkYellow }
    if($sikKusur){ Write-Host "  KAPI-Ş ($id): $sikKusur - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-Ş DÜŞTÜ: önceki denemede şıklar cevabı ele veriyordu ($sikKusur). Kural 2a'yı uygula: her tutar iki yönle (olumlu/olumsuz), 2 tutar × 2 yön + 1." }
    if($hkKusur.Count){ Write-Host "  KAPI-H (hesap adı) ($id): $($hkKusur -join ' · ') - yeniden" -ForegroundColor DarkYellow; $ist=$ist+"`nKAPI-H DÜŞTÜ: hesap adları Tekdüzen Hesap Planı'ndaki resmî adla BİREBİR yazılır: $($hkKusur -join '; ')." }
    if($deneme -eq 2){
      if($uz -gt $UZUNLUK_TAVAN){ $rapor.Add("UZUNLUK TAVANI ASILDI ($uz kr): $($ky.konu)") }
      if($sikKusur){ $rapor.Add("KAPI-Ş (şık dengesi) DÜŞTÜ: $($ky.konu) | $sikKusur") }
      if($hkKusur.Count){ $rapor.Add("KAPI-H (hesap adı) DÜŞTÜ: $($ky.konu) | $($hkKusur -join '; ')") }
      if($kvKusur.Count){ $rapor.Add("KAPI-K (pencere dışı kavram) DÜŞTÜ: $($ky.konu) | $($kvKusur -join ', ')") }
      if($tipKusur){ $rapor.Add("KAPI-T (soru tipi) DÜŞTÜ: $($ky.konu) | $tipKusur") }
      if($cyKusur.Count){ $rapor.Add("KAPI-Ç (çeldirici yolu) DÜŞTÜ: $($ky.konu) | $($cyKusur -join '; ')") }
      if($yilKusur){ $rapor.Add("KAPI-Y (yıl) DÜŞTÜ: $($ky.konu) | $yilKusur") }
      if($koKusur.Count){ $rapor.Add("KAPI-O (koku) DÜŞTÜ: $($ky.konu) | $($koKusur -join '; ')") }
      if($bzKusur.Count){ $rapor.Add("KAPI-B (benzerlik) DÜŞTÜ: $($ky.konu) | $($bzKusur -join '; ')") }
      # 08.09 SORU-BASMA-KURALLARI 7 / A6 ("ikinci denemede de düşen soru rapora yazılır, KAYDEDİLMEZ"): eskiden en sonuncu alınıyordu
      # (kusurlu soru karneye düşsün diye). Şimdi SERT kapılar (şık, hesap adı, tip, çeldirici, yıl, koku, benzerlik) ikinci denemede de düşerse
      # soru üretilmez; yalnız YUMUŞAK kapılar (uzunluk, pencere dışı kavram) raporla kaydedilir.
      if($trKusur.Count){ $rapor.Add("KAPI-D2 (Türkçe harf) DÜŞTÜ: $($ky.konu) | $($trKusur -join ', ')") }
      if($ydKusur.Count){ $rapor.Add("KAPI-YD (yevmiye dengesi) DÜŞTÜ: $($ky.konu) | $($ydKusur -join '; ')") }
      if($paKusur.Count){ $rapor.Add("KAPI-P (yasal parametre) DÜŞTÜ: $($ky.konu) | $($paKusur -join '; ')") }
      if($muKusur.Count){ $rapor.Add("KAPI-M (mülga mevzuat) DÜŞTÜ: $($ky.konu) | $($muKusur -join '; ')") }
      if($suKusur.Count){ $rapor.Add("KAPI-S (süresi dolan veri) DÜŞTÜ: $($ky.konu) | $($suKusur -join '; ')") }
      $sertDustu=($sikKusur -or $hkKusur.Count -or $tipKusur -or $cyKusur.Count -or $yilKusur -or $koKusur.Count -or $bzKusur.Count -or $trKusur.Count -or $ydKusur.Count -or $paKusur.Count -or $muKusur.Count -or $suKusur.Count)
      if($sertDustu){ Write-Host "  SORU DÜŞTÜ ($id): sert kapı ikinci denemede de tutmadı - kaydedilmedi" -ForegroundColor Red; $rapor.Add("SORU DÜŞTÜ (sert kapı ×2): $($ky.konu)"); $cvp=$null }
      else { $cvp=$aday }   # yalnız yumuşak kusur: en sonuncuyu al, rapora yazıldı
    }
  }
  if($cvp -and $cvp.soru -and $cvp.aciklama){
    # sema alan-adi normalizasyonu (01.09 bug: model 'ogeler' yerine 'adimlar' dondurdu -> bos cizim)
    if($cvp.sema -and -not $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.PSObject.Properties['adimlar']){
      $cvp.sema | Add-Member -NotePropertyName ogeler -NotePropertyValue @($cvp.sema.adimlar) -Force
    }
    $cvp | Add-Member -NotePropertyName konu -NotePropertyValue "$($ky.konu)" -Force
    $cvp | Add-Member -NotePropertyName hesap_kod -NotePropertyValue @(HesapKodKapisi $cvp) -Force   # KAPI-H sonucu (boş = eşleşti) → karne
    if($script:PENCERE_KOK -and $script:PENCERE_KOK.Keys.Count){ $cvp | Add-Member -NotePropertyName pencere_kavram -NotePropertyValue @(PencereKavram "$($cvp.soru)") -Force }   # KAPI-K sonucu (boş = sınav dili) → karne
    if($ky.PSObject.Properties['son_donem']){ $cvp | Add-Member -NotePropertyName son_donem -NotePropertyValue ([int]$ky.son_donem) -Force; $cvp | Add-Member -NotePropertyName pencere -NotePropertyValue $DonemPencere -Force }
    if($ky.PSObject.Properties['capa_kaynak']){ $cvp | Add-Member -NotePropertyName capa_kaynak -NotePropertyValue "$($ky.capa_kaynak)" -Force }
    if($CAPA.ContainsKey($id)){ $cvp | Add-Member -NotePropertyName capa_metin -NotePropertyValue "$($CAPA[$id])" -Force }   # 06.09 Cem "3 yap": giriş kartında "Sınavda böyle çıktı" (cevapsız gerçek soru)
    $kpAt=$null; $cvp | Add-Member -NotePropertyName kaynak_metin_ozet -NotePropertyValue (PaketKirp $amb.metin "$($cvp.konu)" 4500 ([ref]$kpAt)) -Force
    if($kpAt -and @($kpAt).Count){ Write-Host "  KAPI-KP: $id paket 4500 krk -> konu disi $(@($kpAt).Count) kaynak komple dusuruldu: $(@($kpAt | Select-Object -First 2) -join ' ; ')" -ForegroundColor DarkCyan }
    $cvp | Add-Member -NotePropertyName donem -NotePropertyValue $ky.donem -Force
    $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb.adlar) -Force
    DilOnarNesne $cvp   # 03.09 sinav dili kapisi (THP/DVK/Is K. her sinavda; SGS'de kanun kisaltmalari uzun ada)
    $don[$id]=$cvp; CacheYaz
    Write-Host "  SORU OK [$($don.Count)/$($KONULAR.Count)] $id $($ky.konu)"
  } else { $rapor.Add("BOZUK: $($ky.konu)"); Write-Host "  BOZUK: $id" -ForegroundColor Yellow }
}
# 1. geçişin yan etkileri (kaynak borcu / rapor satırları) ikinci geçişte yeniden yazılacağı için geri alınır, sonra parti gönderilir
if($script:ON_GECIS){ while($rapor.Count -gt $rapor0){ $rapor.RemoveAt($rapor.Count-1) }; while($kaynakBorcu.Count -gt $kb0){ $kaynakBorcu.RemoveAt($kaynakBorcu.Count-1) }; TopluGonder 'A' } }
$script:ON_GECIS=$false

# --- ARİTMETİK ZİNCİR DEĞERLENDİRİCİ (06.09 Cem "bu beşi geç" #2: uyarı KAPI oldu) ------------------------------------
# Eskiden yalnız sayfa altına "aritmetik uyarı" yazılırdı (MTA parti-2: 9 uyarı, hiçbiri durdurmadı). Şimdi FAZ B'de adım alınınca
# formüller hesaplanır; tutmayan zincir varsa adım bir kez daha yazdırılır, sonuç cache'e `aritmetik` olarak girer (karne hücresi).
function SayiCoz([string]$s){ $t=$s -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }; return $null }
# 06.09 karne ölçümü 5 sahte alarm verdi: "%60" → "60/100" soldan sağa bölünüyordu, "a + b x c" öncelik tanımıyordu, tarih farkı zincir sayılıyordu,
# yüzde puanı sonucu (0,15 = 15) tutmuyordu. Şimdi: yüzde ondalığa çevrilir, çarpma/bölme önce, tarih atlanır, sonuç ×100 / ÷100 da kabul.
$YUZDE_ONDALIK=[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $v=SayiCoz $m.Groups[1].Value; if($null -eq $v){ return $m.Value }; return ' '+(([string]($v/100)) -replace '\.',',')+' ' }
function ZincirHesapla([string]$sol){
  $toks=@([regex]::Matches($sol,'([\d\.,]+)|([x*/+\-])') | ForEach-Object { $_.Value }); if(-not $toks.Count){ return $null }
  $terimler=New-Object System.Collections.Generic.List[double]; $cur=$null; $bekleyen='+'; $op=$null
  foreach($tk in $toks){
    if($tk -match '^[x*/+\-]$'){ $op=$tk; continue }
    $v=SayiCoz $tk; if($null -eq $v){ return $null }
    if($null -eq $cur){ $cur=$v; continue }
    if($null -eq $op){ return $null }
    switch($op){ 'x'{ $cur=$cur*$v } '*'{ $cur=$cur*$v } '/'{ if($v -eq 0){ return $null }; $cur=$cur/$v } '+'{ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })); $bekleyen='+'; $cur=$v } '-'{ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })); $bekleyen='-'; $cur=$v } default{ return $null } }
    $op=$null
  }
  if($null -ne $cur){ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })) }
  $t=0.0; foreach($x in $terimler){ $t+=$x }; return $t
}
function AritmetikKusur($adimlar){
  $out=New-Object System.Collections.Generic.List[string]
  foreach($a in @($adimlar)){
    if(-not $a){ continue }
    foreach($sat in ("$($a.formul)" -split "`n")){
      if($sat -match '\d{1,2}\.\d{1,2}\.\d{4}'){ continue }   # tarih farkı ("01.10.2025 - 01.07.2022 = 39 ay") hesap zinciri değil
      $tmz=$sat -replace '×','x' -replace 'X','x' -replace '\([^)]*\)',' '
      $tmz=[regex]::Replace($tmz,'%\s*([\d\.,]+)',$YUZDE_ONDALIK); $tmz=[regex]::Replace($tmz,'([\d\.,]+)\s*%',$YUZDE_ONDALIK)
      $tmz=$tmz -replace '(?i)\b(TL|₺|USD|EUR|kg|ton|adet|ay|yil|yıl|gun|gün|saat|birim|kisi|kişi)\b',' ' -replace '−','-' -replace '–','-'
      # 08.09 B kovası 19: ZİNCİR EŞİTLİK — "Ad = 70.000 + 100.000 x 0,10 = 70.000 + 10.000 = 80.000": her aritmetik parça zincirin SON değeriyle
      # kıyaslanır (eskiden ilk parça hemen sağındaki ara ifadeyle kıyaslanıp sahte kırmızı veriyordu; 07.09 Maliyet kp-05 karnesi).
      $segs=@($tmz -split '\s=\s' | ForEach-Object { $_.Trim() } | Where-Object { $_ }); if($segs.Count -lt 2){ continue }
      $sonDeger=SayiCoz ($segs[$segs.Count-1] -replace '[^\d\.,\-]','' ); if($null -eq $sonDeger -or $segs[$segs.Count-1] -notmatch '^[\d\.,\-\s]+$'){ continue }
      foreach($sol in ($segs[0..($segs.Count-2)])){
        if($sol -notmatch '^[\d\.,\s]+(?:[x*/+\-]\s*[\d\.,]+\s*)+$'){ continue }   # yalnız sayı-işleç zinciri olan parçalar hesaplanır (ad parçası atlanır)
        $c1=$sonDeger
        $terimler=@([regex]::Matches($sol,'[\d\.,]+') | ForEach-Object { $_.Value })
        $hepsiKod=($terimler.Count -ge 2) -and (-not @($terimler | Where-Object { $_ -notmatch '^[1-7]\d{2}$' }).Count) -and ("$($segs[$segs.Count-1])" -match '^[1-7]\d{2}$')
        if($hepsiKod){ continue }
        $hes=ZincirHesapla $sol; if($null -eq $hes){ continue }
        $tol=[Math]::Max(0.51,[Math]::Abs($c1)*0.001)
        $uyum=([Math]::Abs($hes-$c1) -le $tol) -or ([Math]::Abs($hes*100-$c1) -le $tol) -or ([Math]::Abs($hes/100-$c1) -le $tol)   # yüzde puanı / oran yazımı
        if(-not $uyum){ $out.Add("'$sol = $($segs[$segs.Count-1])' hesap=$([math]::Round($hes,2))") }
      }
    }
  }
  return @($out)
}

# --- FAZ GM: HAZIR SORU GİRİŞİ (09.09 Cem "bunu sen yapabiliyorsun niye para verelim" → B seçeneği: GM yazar, dört kapı çalışır) -------------
# GM'in oturumda yazdığı soru + adımlar (FAZ A ve FAZ B alanları hazır) dosyadan alınır; model çağrısı yok. FAZ A'nın BÜTÜN kod kapıları burada
# da koşar (uzunluk, KAPI-Ş, H, Ç, O, B, D2, YD, P, M, S, Y, K) + adım kapıları (aritmetik, Türkçe). Düşen soru KAYDEDİLMEZ, nedeniyle
# veri/fabrika/hazir-dusen-<etiket>.json'a yazılır. Geçen soru cache'e girer; hakem, kör, hakem2, giriş, ikiz, sim, yevmiye fazları yeni soruyla
# AYNI koşar; yayın şartı (koşucu 8.1) değişmez. İz: yazar='GM', gm_kapi. Konu eşlemesi konu ADIYLA (id'ler köprü sırasına göre değişir).
# Blok AritmetikKusur'dan SONRA durur (fonksiyon tanımı 2014'te); FAZ A döngüsü $HazirSoru varken zaten atlıyor.
if($HazirSoru -and -not $SadeceHtml){
  if(-not (Test-Path $HazirSoru)){ throw "HazirSoru dosyası yok: $HazirSoru" }
  $hzL=@(ConvertFrom-Json -InputObject (Get-Content $HazirSoru -Raw -Encoding UTF8)); if($hzL.Count -eq 1 -and $hzL[0].PSObject.Properties['SyncRoot']){ $hzL=@($hzL[0].SyncRoot) }
  "FAZ GM: $($hzL.Count) hazır soru (GM yazımı) kod kapılarına giriyor (FAZ A/B model çağrısı yok)"
  $hzDusenYol=Join-Path $kok "veri\fabrika\hazir-dusen-$Etiket.json"; $hzDusen=New-Object System.Collections.Generic.List[object]
  function HzDus([string]$konu,[string]$sebep){ $hzDusen.Add([pscustomobject]@{ konu=$konu; sebep=$sebep; tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm') }); Write-Host "  HAZIR SORU DÜŞTÜ [$konu]: $sebep" -ForegroundColor Red; $rapor.Add("HAZIR SORU DÜŞTÜ: [$konu] $sebep") }
  foreach($e in $hzL){
    if(-not $e -or -not $e.soru){ continue }
    $eKonu=(Katla2 "$($e.konu)")
    $kk=$null; foreach($x in $KONULAR){ if((Katla2 "$($x.kayit.konu)") -eq $eKonu){ $kk=$x; break } }
    if(-not $kk){ HzDus "$($e.konu)" 'konu bu etiketin konu listesinde yok (konu dosyası / pencere süzgeci)'; continue }
    $id=$kk.id
    # -RedYenile: hakem HAYIR / DERS-DISI kalan hazır soru düşürülür ve dosyadan yeniden alınır (FAZ A'daki düşürme bu modda koşmaz — 09.09 pilot kp-09 ölçümü)
    # 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): bu koşul FAZ A'daki eşdeğerinden (yukarıda, 'RedYenile -and $don.Contains') İKİ damga eksikti — konu_uyum
    # ve tek_anlam. Sonuç: hakem KONU-DISI ya da CIFT-ANLAM damgası vurduğunda hazır soru düzeltilse bile FAZ GM onu önbellekten düşürmüyor,
    # düzeltilmiş metin hiç basılamıyordu (çok zor kp-07 'kusursuz sorumluluk'). Hazır soru yolu Tur 2'nin ana yolu olduğu için delik her derste
    # tekrarlanırdı. İki damga FAZ A ile birebir eşitlendi.
    if($RedYenile -and $don.Contains($id) -and $don[$id].PSObject.Properties['hakem'] -and $don[$id].hakem -and ("$($don[$id].hakem.karar)" -ne 'EVET' -or "$($don[$id].hakem.ders_uyum)" -eq 'DERS-DISI' -or "$($don[$id].hakem.konu_uyum)" -eq 'KONU-DISI' -or "$($don[$id].hakem.tek_anlam)" -eq 'CIFT-ANLAM')){ Write-Host "  HAZIR SORU YENİLENİYOR (hakem reddi düşürüldü): $id" -ForegroundColor Yellow; $don.Remove($id) }
    # 09.09 maliyet-zor ölçümü: hakem2 HAYIR (kp-14 "soru kökü çelişkili") ve kör çözüm YANLIŞ kayıtları da -RedYenile ile düşer; GM soruyu düzeltip dosyadan yeniden verir
    if($RedYenile -and $don.Contains($id) -and (($don[$id].PSObject.Properties['hakem2'] -and $don[$id].hakem2 -and "$($don[$id].hakem2.karar)" -ne 'EVET') -or ($don[$id].PSObject.Properties['kor_cozum'] -and $don[$id].kor_cozum -and -not [bool]$don[$id].kor_cozum.dogru_mu))){ Write-Host "  HAZIR SORU YENİLENİYOR (hakem2/kör reddi düşürüldü): $id" -ForegroundColor Yellow; $don.Remove($id) }
    if($don.Contains($id) -and $don[$id].soru -and $don[$id].PSObject.Properties['gm_kapi']){ continue }
    $cvp=[pscustomobject]@{ soru="$($e.soru)"; siklar=$e.siklar; dogru="$($e.dogru)"; aciklama=$e.aciklama; konu="$($kk.kayit.konu)"; yazar='GM'; donem=$kk.kayit.donem; sema=$(if($e.PSObject.Properties['sema']){ $e.sema } else { $null }) }
    foreach($alan in 'teshis','celdirici_yol','verilenler','dayanak','cozum_tablo','hap','sinav_taktigi','notlandirici'){ if($e.PSObject.Properties[$alan] -and $null -ne $e.$alan){ $cvp | Add-Member -NotePropertyName $alan -NotePropertyValue $e.$alan -Force } }
    if(-not $cvp.siklar -or -not $cvp.dogru -or -not $cvp.aciklama){ HzDus "$($e.konu)" 'şık / doğru / açıklama eksik'; continue }
    YazimOnarNesne $cvp; DilOnarNesne $cvp
    $kus=New-Object System.Collections.Generic.List[string]
    $uzH="$($cvp.soru)".Length; if($uzH -gt $UZUNLUK_TAVAN){ $kus.Add("uzunluk $uzH kr > $UZUNLUK_TAVAN") }
    $sK=SikDengesi $cvp; if(-not $sK){ $sK=SikBicimi $cvp }; if($sK){ $kus.Add("KAPI-Ş: $sK") }
    foreach($x in @(HesapKodKapisi $cvp)){ $kus.Add("KAPI-H: $x") }
    foreach($x in @(CeldiriciYolKapisi $cvp)){ $kus.Add("KAPI-Ç: $x") }
    foreach($x in @(KokuKusur $cvp)){ $kus.Add("KAPI-O: $x") }
    foreach($x in @(BenzerlikKusur $cvp $id)){ $kus.Add("KAPI-B: $x") }
    foreach($x in @(TurkceKapisi $cvp)){ $kus.Add("KAPI-D2: $x") }
    foreach($x in @(YevmiyeDengeKapisi $cvp)){ $kus.Add("KAPI-YD: $x") }
    foreach($x in @(ParametreKapisi $cvp)){ $kus.Add("KAPI-P: $x") }
    foreach($x in @(MulgaKapisi $cvp)){ $kus.Add("KAPI-M: $x") }
    foreach($x in @(SureKapisi $cvp)){ $kus.Add("KAPI-S: $x") }
    $yilH=@([regex]::Matches("$($cvp.soru)",'\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))') | ForEach-Object { [int]$_.Groups[1].Value }); if($yilH.Count -and (($yilH | Measure-Object -Maximum).Maximum -lt (Get-Date).Year)){ $kus.Add("KAPI-Y: sorudaki en yeni yıl $(($yilH | Measure-Object -Maximum).Maximum)") }
    # 10.09 ÖLÇÜLDÜ (sgs-a6e-yabancidil-p1): FAZ A'da YD modunda KAPI-K kapalı (satır 2138) ama FAZ GM'de
    # koşul YOKTU → 25 GM sorusunun 8'i İngilizce kelimeler ("auditor, expressing, opinion") pencere
    # sözlüğünde yok diye düştü. Pencere sözlüğü Türkçe kitapçıktan kurulur, İngilizce soruda anlamsızdır.
    # Aynı sınıf kusur 10.09'da bir kez daha görüldü (FAZ GM -RedYenile'de konu_uyum/tek_anlam eksikti):
    # FAZ GM yolu, FAZ A'daki her kapı koşuluyla BİREBİR eşitlenmelidir.
    if(-not $script:YD_MOD -and $script:PENCERE_KOK -and $script:PENCERE_KOK.Keys.Count){ $kvH=@(PencereKavram "$($cvp.soru)"); if($kvH.Count -ge 2){ $kus.Add("KAPI-K: $($kvH -join ', ')") } elseif($kvH.Count -eq 1){ $rapor.Add("KAPI-K NOTU (tek kelime, tekrar yok): $id | $($kvH[0])") } }
    $adimVar=[bool]($e.PSObject.Properties['adimlar'] -and $e.adimlar)
    if($adimVar){ foreach($x in @(AritmetikKusur $e.adimlar)){ $kus.Add("ADIM ARİTMETİK: $x") }; foreach($x in @(AdimTurkceKusur $e.adimlar $e.verilen)){ $kus.Add("ADIM TÜRKÇE: $x") } }
    if($kus.Count){ HzDus "$($e.konu)" ($kus -join ' · '); continue }
    if(SikSirala $cvp){ Write-Host "  ŞIK SIRALANDI ($id): doğru artık $($cvp.dogru)" -ForegroundColor DarkGray }
    if($adimVar){
      foreach($ad1 in @($e.adimlar)){ if($ad1){ foreach($alan in @('anlatim','formul')){ if($ad1.PSObject.Properties[$alan] -and $ad1.$alan -is [string]){ $ad1.$alan=DilOnar $ad1.$alan } } } }
      $cvp | Add-Member -NotePropertyName adimlar -NotePropertyValue @($e.adimlar) -Force
      $cvp | Add-Member -NotePropertyName aritmetik -NotePropertyValue @() -Force
      $cvp | Add-Member -NotePropertyName verilen -NotePropertyValue @($(if($e.PSObject.Properties['verilen'] -and $null -ne $e.verilen){ $e.verilen } else { @() })) -Force
    }
    $cvp | Add-Member -NotePropertyName hesap_kod -NotePropertyValue @() -Force
    if($CAPA.ContainsKey($id)){ $cvp | Add-Member -NotePropertyName capa_metin -NotePropertyValue "$($CAPA[$id])" -Force }
    $cvp | Add-Member -NotePropertyName gm_kapi -NotePropertyValue ([pscustomobject]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kapilar='uzunluk,Ş,H,Ç,O,B,D2,YD,P,M,S,Y,K,adım-aritmetik,adım-Türkçe'; adim=$adimVar }) -Force
    $don[$id]=$cvp; CacheYaz
    Write-Host "  HAZIR SORU OK $id [$($cvp.konu)] $(if($adimVar){'soru+adım'}else{'soru'})" -ForegroundColor Green
  }
  [IO.File]::WriteAllText($hzDusenYol,(ConvertTo-Json -InputObject @($hzDusen.ToArray()) -Depth 4),[Text.UTF8Encoding]::new($false))
  "FAZ GM bitti: alınan $(@($don.Keys | Where-Object { $don[$_].PSObject.Properties['gm_kapi'] }).Count) · düşen $($hzDusen.Count) -> $hzDusenYol"
}

# --- ŞIK HARFİ DENGESİ (07.09 A kovası 6 — "hep C" olmaz) ---------------------------------------------------------------
# Sayı şıkları SikSirala ile küçükten büyüğe dizilir (harf oradan çıkar, dokunulmaz). Cümle şıklı (teori/kayıt) sorularda bir harf partide
# %40'ı aşarsa (n≥5) o harfteki bir soru henüz ADIMLARI YAZILMAMIŞKEN en az kullanılan harfe taşınır: siklar · aciklama · teshis · celdirici_yol
# birlikte taşınır ("Hepsi / Hiçbiri / Yukarıdakilerin" içeren soruya dokunulmaz). 10.09: adımı OLAN soru değil, adımı ŞIK HARFİNE
# BAĞLI olan soru taşınmaz (AdimHarfeBagliMi) — eski hâli hazır soru yolunda dengelemeyi tümüyle kapatıyordu.
function SikTasi($c,[string]$kaynakH,[string]$hedefH){
  # ⛔⭐ 12.09.2026 — sade.siklar EKLENDI. OLCULDU, tahmin degil:
  #   sade.siklar her harf icin "BU SIK NEDEN YANLIS" metnini tutar ve
  #   Kaydir-Coz panelinde EKRANDA GOSTERILIR (motor/kaydir-coz.ps1:174).
  #   299 soruda olculdu: yanlis siklarda 1.196 dolu / 0 bos · dogru sikta
  #   248 bos (dogru sik "yanlis" degil, o yuzden bos).
  #   Bu alan tasinmazsa harf kayar ama gerekce yerinde kalir: panel, artik
  #   DOGRU olan sikkin altinda "su yuzden yanlis" yazar. Gorunur, ciddi hasar.
  #   sade FAZ S ile 04.09'da geldi; SikTasi ondan once yazilmisti ve
  #   guncellenmemisti - yani bu tuzak bugune kadar sessizce bekliyordu.
  #
  # ⚠ teori_ikiz'e BILEREK DOKUNULMUYOR. Olculdu: teori_ikiz AYRI BIR SORU
  #   (farkli senaryo, kendi dogru harfi). Ayni sik kumesini paylassa da
  #   bagimsizdir; ana sorunun harfi tasinirken onu da tasimak IKIZI BOZAR.
  #   (Ilk teshisimde "tasimiyor" diye kusur saymistim - yanlisti.)
  foreach($alan in 'siklar','aciklama','teshis','celdirici_yol'){ if(-not $c.PSObject.Properties[$alan] -or -not $c.$alan){ continue }; $o=$c.$alan
    $vK=$(if($o.PSObject.Properties[$kaynakH]){ $o.$kaynakH } else { $null }); $vH=$(if($o.PSObject.Properties[$hedefH]){ $o.$hedefH } else { $null })
    if($null -ne $vK){ $o | Add-Member -NotePropertyName $hedefH -NotePropertyValue $vK -Force } elseif($o.PSObject.Properties[$hedefH]){ $o.PSObject.Properties.Remove($hedefH) }
    if($null -ne $vH){ $o | Add-Member -NotePropertyName $kaynakH -NotePropertyValue $vH -Force } elseif($o.PSObject.Properties[$kaynakH]){ $o.PSObject.Properties.Remove($kaynakH) } }
  # --- 2. SEVIYE: sade.siklar (ekranda gosterilen "neden yanlis" metni) -----
  if($c.PSObject.Properties['sade'] -and $c.sade -and $c.sade.PSObject.Properties['siklar'] -and $c.sade.siklar){
    $sd=$c.sade.siklar
    $sK=$(if($sd.PSObject.Properties[$kaynakH]){ $sd.$kaynakH } else { $null })
    $sH=$(if($sd.PSObject.Properties[$hedefH]){ $sd.$hedefH } else { $null })
    if($null -ne $sK){ $sd | Add-Member -NotePropertyName $hedefH -NotePropertyValue $sK -Force } elseif($sd.PSObject.Properties[$hedefH]){ $sd.PSObject.Properties.Remove($hedefH) }
    if($null -ne $sH){ $sd | Add-Member -NotePropertyName $kaynakH -NotePropertyValue $sH -Force } elseif($sd.PSObject.Properties[$kaynakH]){ $sd.PSObject.Properties.Remove($kaynakH) }
  }
  $c.dogru=$hedefH
  # 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): dengeleme YARGILAMADAN SONRA da çalışabiliyor (hazır soru yolunda parti iki turda basılıyor).
  # kor_cozum HARFE BAĞLI üç alan taşır: 'cevap' (modelin seçtiği harf), 'dogru' (o anki doğru harf) ve 'hesap' (şık şık A) B) C)
  # anlatımı). Harf taşınıp bu kayıt bırakılırsa kayıt YALAN SÖYLER: 'dogru' sorunun doğrusuyla çelişir, 'hesap' başka şıkkı anlatır.
  # simulasyon da öğrencinin seçtiği harfi tutar. Bu yüzden taşınan soruda harfe bağlı kararlar DÜŞÜRÜLÜR; aynı koşunun ilerleyen
  # fazları onları yeni harfe göre yeniden hesaplar. hakem/hakem2 kararı içeriğe (dayanak/ders/konu) bağlı olduğu için korunur.
  foreach($alan in 'kor_cozum','simulasyon','simulasyon_sonnet'){ if($c.PSObject.Properties[$alan]){ $c.PSObject.Properties.Remove($alan) } }
}
function SayiSikli($c){ $n=0; foreach($hh in 'A','B','C','D','E'){ if("$($c.siklar.$hh)" -match '^\s*%?\s*-?\d[\d.,]*\s*(TL|₺|%|adet|kg|gün|yıl|ay|saat|birim)?\s*$'){ $n++ } }; return ($n -ge 4) }
# 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): aşağıdaki "adımı yazılmış soru taşınmaz" istisnası, HAZIR SORU yolunda dengelemeyi tümüyle
# kapatıyordu — hazır soruların hepsinde adım var. Sonuç: Borçlar kolay %92 A, zor %95 B, çok zor %91 B (42 sorunun 42'si);
# "hep B" yazan öğrenci zor bankadan 18/19 alırdı. Her soru tek tek kusursuzdu, kusur DAĞILIMDAYDI ve hiçbir kapı görmüyordu.
# İstisnanın gerçek gerekçesi adımın ŞIK HARFİNE bağlı olmasıdır; artık varlık değil HARF REFERANSI aranır: adımda 'sik' alanı
# ya da adım/hap/taktik metninde "B şıkkı", "şık C" gibi bir gönderme varsa soru yine taşınmaz (taşınırsa metin yalan söyler).
function AdimHarfeBagliMi($c){
  if(-not ($c.PSObject.Properties['adimlar'] -and $c.adimlar)){ return $false }
  foreach($a in @($c.adimlar)){ if($a -and $a.PSObject.Properties['sik'] -and "$($a.sik)".Trim()){ return $true } }
  $t=(@($c.adimlar | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')+' '+"$($c.hap) $($c.sinav_taktigi) $($c.notlandirici)"
  return ($t -match '(?i)(\b[A-E]\s*[şs]ık|\b[şs]ık+[ıi]?\s*\(?[A-E]\)?\b|\([A-E]\)\s*[şs]ık)')
}
if(-not $SadeceHtml -and -not $SadeceAdim){
  # ⛔⭐ 12.09.2026 CEM KURALI: "bundan sonraki duzgun yapalim, kural koyalim,
  #    bundan sonra kacmasin" · "ders ders bakmak lazim, sinav sinav degil"
  #
  #  ESKI HALI IKI SEYI KACIRIYORDU - OLCULDU:
  #  1) SAYISAL SIKLI SORULAR KUMEYE HIC GIRMIYORDU (`-not (SayiSikli $c)`).
  #     1.802 basili soruda olculdu: sayisal alt kumede (554 soru)
  #     ki-kare 215,4 · E %1,3 (554 soruda 7 tane) · C %35,9.
  #     Sebebi: siklar ARTAN siralaniyor (537/554) ve celdiriciler dogru
  #     degerin altina/ustune serpildigi icin dogru deger DOGAL OLARAK ORTADA
  #     kaliyor -> orta = C. Sayi sorulari dengelenmeyince ipucu dogdu:
  #     "sayi sorusunda E'yi isaretleme" kurali %98,7 dogruydu.
  #  2) OLCUT "PARTI ICINDE %40'I GECMESIN" idi - yani TABANA hic bakmiyordu.
  #     Bir harf %1'e duse kapi sessizdi. Ve parti ici olcum banka genelini
  #     hic gormedigi icin kapi 611 kutukten yalniz 12'sinde tetiklendi.
  #
  #  GERCEK SGS HEDEFI OLCULDU (veri/sgs-arsiv anahtar tablolari, 595 cevap):
  #     A %21,0 B %20,2 C %19,5 D %20,2 E %19,2 · ki-kare 0,6
  #  Yani gercek sinav harfleri BILEREK esitliyor. Hedef %20.
  #
  #  YENI OLCUT: hedef partinin degil DERSIN KUMULATIF ortalamasi.
  #  veri/cevap-dagilimi.json (arac/cevap-dagilimi-olc.ps1) dersin bankadaki
  #  mevcut sayimini verir; parti o eksigi kapatacak yonde dengelenir.
  #  Boylece eksigi olan derste eksik harf FAZLA basilir, zaten dengeli
  #  derste %20'de tutulur (olculdu: 11 dersin 6'si ZATEN dengeli - onlari
  #  kor bir duzeltme BOZARDI).
  #
  #  ⛔ ESKI SORULAR DEGISTIRILMEZ (Cem sarti 12.09). Duzeltme yalniz yeni
  #     sorularla. Hesap: yeni sorular tam %20 basilirsa ortalama %20'ye ASLA
  #     varmaz (E'yi %19'a cekmek 11.823 soru ister); eksik harf FAZLA
  #     basilirsa ~700-1.000 soru yeter.
  #  ⛔ PARTI TAVANI %40 KALIYOR (guvenlik): kumulatif eksik buyuk olsa bile
  #     tek parti "hepsi E" olmaz; duzeltme partilere yayilir.
  $cumleli=@($don.Keys | Where-Object { $c=$don[$_]; $c -and $c.soru -and $c.siklar })
  # Dersin bankadaki mevcut dagilimi (yoksa bos - o zaman yalniz parti dengelenir)
  $bankaSay=@{}; foreach($hh in 'A','B','C','D','E'){ $bankaSay[$hh]=0 }
  try{
    $dagYol=Join-Path $kok 'veri\cevap-dagilimi.json'
    if(Test-Path $dagYol){
      $dagHam=Get-Content $dagYol -Raw -Encoding UTF8 | ConvertFrom-Json   # ONCE DEGISKENE (K2)
      if($dagHam.PSObject.Properties['dersler'] -and $dagHam.dersler){
        foreach($dp in $dagHam.dersler.PSObject.Properties){
          # ders adi -DersRegex ile eslesiyor mu (harf ayrimsiz, kasitli)
          if("$($dp.Name)" -match "$DersRegex" -or "$DersRegex" -match [regex]::Escape("$($dp.Name)")){
            foreach($hh in 'A','B','C','D','E'){ $bankaSay[$hh]=[int]$bankaSay[$hh]+[int]$dp.Value.say.$hh }
            break
          }
        }
      }
    }
  }catch{ Write-Host "  ŞIK DENGESİ: banka dağılımı okunamadı, yalnız parti dengelenir ($($_.Exception.Message))" -ForegroundColor DarkGray }
  $bankaTop=0; foreach($hh in 'A','B','C','D','E'){ $bankaTop+=[int]$bankaSay[$hh] }
  if($bankaTop -gt 0){ Write-Host ("  ŞIK DENGESİ: ders bankası $bankaTop soru · " + (@('A','B','C','D','E') | ForEach-Object { "$_=$([int]$bankaSay[$_])" }) -join ' ') -ForegroundColor DarkGray }
  # ⛔⭐ 12.09 ESIK 5 -> 2. OLCULDU, B kosusunu BASMADAN ONCE yakalandi:
  #   plan-siklik-tum-b.json 94 partinin 65'i BES SORUDAN KUCUK - yani 343
  #   sorunun 164'u (%48) dengeleyiciye HIC GIRMEYECEKTI. Esik 5'te kalsaydi
  #   duzeltme yarim kosardi ve bunu ancak basdiktan sonra gorurduk.
  #   Kucuk partide "parti ici dagilim" zaten anlamsizdir; onemli olan DERSIN
  #   KUMULATIF ortalamasi - 65 parti birer soru tasirsa 65 duzeltme eder.
  #   Bu yuzden: taban denetimi yalniz 5+ soruluk partilerde uygulanir (kucukte
  #   bosaltilacak bir dagilim yok), tavan ise en az 1'e sabitlenir.
  if($cumleli.Count -ge 2){
    # 10.09: tur tavanı 10'du ve her tur YALNIZ BİR soru taşır. Borçlar zor partisinde gereken taşıma tam 10 çıktı (18 -> 8),
    # yani tavan bir soru daha kaysa hedef SESSİZCE tutturulamayacaktı (döngü biter, uyarı yok). Döngü zaten hedefe varınca
    # kırılıyor, fazla tur bedelsiz: tavan parti büyüklüğüne yer bırakacak biçimde 40'a çıkarıldı.
    # ⛔ 12.09 PROVADA OLCULDU - TAVAN %40'TAN %30'A INDI, TABAN EKLENDI.
    #    Kumulatif hedefle ilk prova: sgs-t2-fmuh-cokzor (111 soru) partisinde
    #    C 33 -> 5 (%4,5) ve E 10 -> 44 (%39,6) oldu. Birlesik ortalama duzeliyordu
    #    ama PARTININ KENDISI dengesizlesti - o partiden cekilen bir deneme
    #    sinavinda ogrenci E'yi dort kat fazla gorurdu. Duzeltme partilere
    #    YAYILMALI: B kosusu 94 parti / 343 soru, uc dersin eksigi toplam 106 -
    #    %30 tavanla rahat sigar.
    #    TABAN da sart: kaynak harf bosaltilip yeni bir sapma uretilmemeli.
    $partiTavan=[Math]::Max(1,[math]::Floor(0.30*$cumleli.Count))
    # taban YALNIZ 5+ soruluk partide anlamli; kucukte 0 (denetim devre disi)
    $partiTaban=$(if($cumleli.Count -ge 5){ [math]::Ceiling(0.10*$cumleli.Count) } else { 0 })
    for($tur=0;$tur -lt 80;$tur++){
      # parti sayimi
      $say=@{}; foreach($hh in 'A','B','C','D','E'){ $say[$hh]=0 }
      foreach($oid in $cumleli){ $dg="$($don[$oid].dogru)".Trim().ToUpperInvariant(); if($say.ContainsKey($dg)){ $say[$dg]++ } }
      # BIRLESIK sayim (banka + bu parti) -> hedef bunun uzerinden hesaplanir
      $bir=@{}; foreach($hh in 'A','B','C','D','E'){ $bir[$hh]=[int]$say[$hh]+[int]$bankaSay[$hh] }
      $birTop=0; foreach($hh in 'A','B','C','D','E'){ $birTop+=[int]$bir[$hh] }
      $birHedef=$birTop/5.0
      # en FAZLA harf: birlesikte artigi en buyuk VE partide tasinacak sorusu olan
      $fazla=$null; $fazlaArtik=0
      foreach($hh in 'A','B','C','D','E'){
        if([int]$say[$hh] -lt 1){ continue }
        $artik=[int]$bir[$hh]-$birHedef
        if($artik -gt $fazlaArtik){ $fazlaArtik=$artik; $fazla=$hh }
      }
      # en EKSIK harf: birlesikte eksigi en buyuk
      $eksik=$null; $eksikMik=0
      foreach($hh in 'A','B','C','D','E'){
        $mik=$birHedef-[int]$bir[$hh]
        if($mik -gt $eksikMik){ $eksikMik=$mik; $eksik=$hh }
      }
      # DURMA SARTLARI
      if(-not $fazla -or -not $eksik -or $fazla -eq $eksik){ break }
      if($fazlaArtik -lt 1 -or $eksikMik -lt 1){ break }          # birlesik zaten dengeli
      if(([int]$say[$eksik]+1) -gt $partiTavan -and $partiTavan -ge 1){ break }  # parti guvenlik TAVANI
      if(([int]$say[$fazla]-1) -lt $partiTaban){ break }                          # parti guvenlik TABANI
      # tasinabilir aday
      $aday=$null
      foreach($oid in $cumleli){ $c=$don[$oid]
        if("$($c.dogru)".Trim().ToUpperInvariant() -ne $fazla){ continue }
        if(AdimHarfeBagliMi $c){ continue }
        $hepsi=$false; foreach($hh in 'A','B','C','D','E'){ if("$($c.siklar.$hh)" -match '(?i)hepsi|hiçbiri|yukarıdaki|yalnız (I|II|III)\b'){ $hepsi=$true } }
        if($hepsi){ continue }
        # ⛔ sema.ogeler HARFE ANAHTARLI olabilir ve SikTasi onu TASIMIYOR.
        #    Olculdu: 1.802 soruda 1 tane. Tasimak yerine o soruya DOKUNMUYORUZ -
        #    yanlis tasimak, hic tasimamaktan kotudur.
        if($c.PSObject.Properties['sema'] -and $c.sema -and $c.sema.PSObject.Properties['ogeler'] -and $c.sema.ogeler){
          $semaAd=@($c.sema.ogeler.PSObject.Properties.Name)
          if(@($semaAd | Where-Object { $_ -cmatch '^[A-E]$' }).Count -ge 3){ continue }
        }
        $aday=$oid; break
      }
      if(-not $aday){ break }
      SikTasi $don[$aday] $fazla $eksik
      Write-Host ("  ŞIK DENGESİ: $aday doğru $fazla -> $eksik taşındı (parti " + ((@('A','B','C','D','E') | ForEach-Object { "$_=$([int]$say[$_])" }) -join ' ') + " · birleşik hedef $([math]::Round($birHedef,1)))") -ForegroundColor DarkGray
      $script:sikDengeYaz=$true
    }
    if($script:sikDengeYaz){ CacheYaz }
  }
}

# --- KAPI-DR: HAKEM KOSACAKSA DERS ADI GERCEK OLMALI (11.09.2026) -----------
# 11.09'da az kalsin havuz bozuluyordu: pilot kosularda gun boyu -DersRegex '.'
# kullandim (kolay ve zararsizdi, cunku hakem yeniden kosmuyordu). KAPI-HG
# `hesap_uyum` alanini zorunlu kilinca hakem YENIDEN kosar oldu ve hakeme
# "bu soru '.' dersine mi ait?" diye soruldu. Hakem dogal olarak DERS-DISI dedi;
# ayni gun ekledigim secim kapisi da DERS-DISI'yi dusuruyor. Yani tek bir
# dikkatsiz bayrak, once hakem kaydini bozup sonra sorulari yayindan silecekti.
# OLCULDU: sgs-t1-mta-kolay kp-01 ve kp-02 boyle HAYIR/DERS-DISI oldu; sorularda
# hicbir kusur yoktu, gerekce "kaynak metni VUK m.275" idi.
# Bundan sonra: hakem kosacaksa ders adi GERCEK olmali. Regex joker ('.', '.*')
# ya da 3 harften kisa ad ile hakem kosmaz - kosu DURUR ve sebebini soyler.
if(-not ($SadeceHtml -or $SadeceAdim)){
  $drSade = "$DersRegex".Trim()
  if($drSade -in @('.','.*','.+','') -or $drSade.Length -lt 3){
    # Hakem gercekten kosacak mi? Yalniz hakem karari EKSIK/ESKI olan soru varsa.
    $hakemKosacak = $false
    foreach($idDR in @($don.Keys)){
      if($PilotId -and (($PilotId -split ',') -notcontains $idDR)){ continue }
      $vDR=$don[$idDR]; if(-not $vDR.soru){ continue }
      if(-not ($vDR.PSObject.Properties['hakem'] -and $vDR.hakem -and
               $vDR.hakem.PSObject.Properties['hesap_uyum'] -and
               $vDR.hakem.PSObject.Properties['ders_uyum'] -and
               $vDR.hakem.PSObject.Properties['konu_uyum'])){ $hakemKosacak=$true; break }
    }
    if($hakemKosacak){
      throw ("KAPI-DR: hakem kosacak ama -DersRegex '$DersRegex' gercek bir ders adi degil. " +
             "Hakeme 'bu soru $DersRegex dersine mi ait' diye sorulur ve DERS-DISI damgalanir; " +
             "secim kapisi da o sorulari yayindan duurur. Gercek ders adiyla kos " +
             "(ornek: -DersRegex 'Mali Tablolar Analizi').")
    }
  }
}

# --- KAPI B: DAYANAK HAKEMI (01.09 Cem guvencesi) ----------------------------
# Bagimsiz ucuz gozle her soru sinanir: "dogru sikkin kurali kaynaktan cikiyor mu?"
# HAYIR -> sayfada kirmizi HAKEM REDDI damgasi; kasa yolunda karantina demektir.
$hakemIstem=@'
Sen bagimsiz bir DENETCI-HAKEMSIN. IKI ayri karar vereceksin:
1) DAYANAK: sorunun DOGRU sikkinin dayandigi kural/bilgi, verilen KAYNAK METNINDEN gercekten cikiyor mu?
   Kaynakta ACIKCA destegi varsa EVET; kural kaynakta yoksa ya da celisiyorsa HAYIR.
   (Parasal senaryo tutarlari kaynakta olmak zorunda degil; KURAL/oran/tanim kaynaktan olmali.)
2) DERS UYUMU (KAPI C - 01.09): soru "{DERS}" dersinin RESMI KAPSAMINA uyuyor mu,
   yoksa su komsu derslerden birinin sorusu mu: {KOMSULAR}?
   RESMI KAPSAM: {TARIF}
   Kapsama uyuyorsa EVET; baska dersin sorusuysa DERS-DISI (+hangi ders).
3) KONU UYUMU (KAPI D - 03.09): bu soru "{KONU}" konusunu mu OLCUYOR? {KE_ISARET}Konu adi metinde gecse bile
   sorunun olctugu kural/hesap baska bir konuya aitse (orn. "damga vergisi" konusunda SGK af hukmu;
   "yonetim iddialari" konusunda stok sayimi) KONU-DISI de; konunun ozunu olcuyorsa EVET.
4) TEK ANLAM (KAPI E - 05.09): soru koku TEK bir buyuklugu mu istiyor? Koku iki farkli sekilde okuyunca iki farkli
   sikka cikiliyorsa (orn. "esas uretim yerlerine dagitilacak toplam (duzeltilmis) maliyet" hem duzeltilmis toplam
   100.000 hem esas uretime giden 90.000 okunur ve ikisi de sikta var) CIFT-ANLAM de ve hangi sikkin da savunulabilir
   oldugunu yaz; kok tek anlamliysa EVET. Yalniz gercek cift okunus sayilir, zorlama yorum degil.
5) GUNCELLIK (KAPI-M/S - 08.09): dogru sikkin dayandigi hukum YURURLUKTE mi? Kaynak metninde "mulga", "yururlukten kaldirilmistir",
   suresi gecmis bir gecici madde, eski yila ait had/oran varsa ya da soru/dayanak mulga kanun-standart-kurum aniyorsa (6762, 818,
   5422, 506, 2499, TMS 17/18/39, TFRS 4, SSK, TMSK) ESKI de ve KARARI HAYIR ver. Hukum yururlukteyse GUNCEL. {GECICI}
6) ATIF (kural 6.5): soru ve dayanakta anilan kanun + madde numarasi ({DAYANAK}) KAYNAK METNINDEKI madde basligiyla uyusuyor mu?
   Kaynakta o madde var ve hukum orada ise EVET; madde numarasi kaynaktaki hukumle uyusmuyorsa (baska maddenin hukmu bu numaraya
   yazilmis) ATIF-YANLIS de ve KARARI HAYIR ver; kaynak paketinde o madde hic yoksa TEYITSIZ (hukum baska parcadan destekleniyorsa karar EVET kalabilir).
7) HESAP KODU (KAPI-HG - 11.09): soru bir THP hesabi aniyorsa, KAYNAK METNI icinde "ILGILI HESAP
   GRUBUNUN TUM HESAPLARI" basligi altinda o grubun butun hesap tanimlari verilmistir. Dogru sikkin
   kullandigi hesap, o gruptaki tanimlara gore DOGRU hesap mi? Gruptaki BASKA bir hesabin tanimi olayi
   daha birebir karsiliyorsa (orn. iptal edilen hisse senetlerinin nominal ustu satisi 529 "diger"e
   degil, 521 "hisse senedi iptal karlari"na aittir; 529'un kendi tanimi "sayilanlarin DISINDA kalan"
   der) HESAP-YANLIS de, dogru hesap kodunu yaz ve KARARI HAYIR ver. Hesap dogruysa EVET.
   ⚠ Hesabi EZBERDEN dogrulama: hukmun KAYNAK METNINDEKI tanimdan cikmasi sart. Tanim pakette yoksa
   "TEYITSIZ" de, uydurma.
8) DOGRU SIK VAR MI (KAPI-DS - 11.09, Cem onerisi): bes sikkin ICINDE dogru cevap gercekten var mi?
   Kendi cozumunu yap; buldugun sonuc siklardan HICBIRIYLE tutmuyorsa "dogru_sik_var":"HICBIRI" de,
   dogru sonucu "dogru_sik_gerekce" alanina yaz ve KARARI HAYIR ver. Bu, isaretli sikkin yanlis
   olmasindan FARKLIDIR: burada sorunun DOGRU cevabi siklarda hic yoktur, soru butunuyle bozuktur.
   ⚠ Olculdu (11.09, kp-80): 529 isaretliydi, dogrusu 521'di ve 521 SIKLARDA YOKTU; hicbir kapi
   "dogrusu hicbiri" diyemedigi icin soru yayina gitti.
Cevap YALNIZ JSON: {"karar":"EVET|HAYIR","gerekce":"tek cumle","dogru_sik_var":"EVET|HICBIRI (BASKA DEGER YAZMA; emin degilsen HICBIRI degil EVET de ve gerekceye yaz)","dogru_sik_gerekce":"tek cumle (HICBIRI ise dogru sonuc ne)","hesap_uyum":"EVET|HESAP-YANLIS|TEYITSIZ|YOK","hesap_gerekce":"tek cumle (HESAP-YANLIS ise dogru hesap kodu+adi)","ders_uyum":"EVET|DERS-DISI","ders_gerekce":"tek cumle (DERS-DISI ise hangi ders)","konu_uyum":"EVET|KONU-DISI","konu_gerekce":"tek cumle (KONU-DISI ise soru aslinda hangi konuyu olcuyor)","tek_anlam":"EVET|CIFT-ANLAM","tek_anlam_gerekce":"tek cumle (CIFT-ANLAM ise hangi sik da savunulabilir)","guncellik":"GUNCEL|ESKI","guncellik_gerekce":"tek cumle","atif":"EVET|ATIF-YANLIS|TEYITSIZ","atif_gerekce":"tek cumle (kaynaktaki madde basligini an)"}
=== SORU === {SORU}
=== DOGRU SIK ({DOGRU}) === {SIK}
=== DOGRU SIKKIN ACIKLAMASI === {ACIK}
=== KAYNAK METNI === {KAYNAK}
'@
# --- 11.09 TOPLU: FAZ H de iki gecisli kosar (Cem "toplu istege gec") ---------
# A · K · H2 · B · G · C fazlari 08.09'dan beri toplu gidiyordu; HAKEM ve SADE
# disarida kalmisti. Hasat turu tam bu iki fazi kosuyor: 1.098 soru x 2 cagri
# = 2.196 SIRALI istek, ~7,6 saat ve tam fiyat. Toplu istek yari fiyat + paralel.
foreach($gecisH0 in @(1,2)){ if($gecisH0 -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisH0 -eq 1); $raporH0=$rapor.Count
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not $cvp.soru){ continue }
  # 03.09 KAPI D (konu uyumu) eklendi: konu_uyum alani olmayan eski karar YENIDEN verdirilir (ucuz hakem).
  # 11.09 KAPI-HG ayni yolla devreye giriyor: `hesap_uyum` alani olmayan karar eskidir, yeniden verdirilir.
  # ⚠ BEDEL: bu kosul, dokunulan her partide hakemi YENIDEN kosturur. Toplu turda
  #    -PilotId ile sinirla; yoksa 636 sorunun hakemi bastan koşar.
  if($SadeceHtml -or $SadeceAdim){ continue }   # yalniz cizim / yalniz adim: eski karar neyse o kalir, hakem cagrilmaz
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if($cvp.PSObject.Properties['hakem'] -and $cvp.hakem -and $cvp.hakem.PSObject.Properties['hesap_uyum'] -and $cvp.hakem.PSObject.Properties['ders_uyum'] -and $cvp.hakem.PSObject.Properties['konu_uyum']){ continue }
  # sema normalizasyonu geriye donuk (ogeler<-adimlar)
  if($cvp.sema -and -not $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.PSObject.Properties['adimlar']){
    $cvp.sema | Add-Member -NotePropertyName ogeler -NotePropertyValue @($cvp.sema.adimlar) -Force
  }
  $kMetin=''
  if($cvp.PSObject.Properties['kaynak_metin_ozet'] -and $cvp.kaynak_metin_ozet){ $kMetin=$cvp.kaynak_metin_ozet }
  elseif($cvp.PSObject.Properties['kaynak_adlar'] -and @($cvp.kaynak_adlar).Count){
    $parca=New-Object System.Collections.Generic.List[string]
    foreach($ka in (KaynakSirala $cvp.kaynak_adlar "$($cvp.konu)" 4)){
      $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ka)+'&limit=1'
      try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60; if(@($r).Count){ $parca.Add("[$ka] $(@($r)[0].metin)") } }catch{}
    }
    $kMetin=($parca -join "`n---`n")
    if($kMetin.Length -gt 4500){ $kpAt2=$null; $kMetin=PaketKirp $kMetin "$($cvp.konu)" 4500 ([ref]$kpAt2)
      if($kpAt2 -and @($kpAt2).Count){ Write-Host "  KAPI-KP (hakem): $id konu disi $(@($kpAt2).Count) kaynak dusuruldu" -ForegroundColor DarkCyan } }
  }
  else{
    # hakem-red onarimi: kaynak alanlari silinmisse OZEL_DESEN/DesenUret ile TAZE cek
    $konuLc2="$($cvp.konu)".ToLowerInvariant()
    # 10.09 ÖLÇÜLDÜ (GM Vergi/Maliye t4): HAZIR SORU yolunda kayıt buraya kaynak_adlar'sız geliyor, yani paketi
    # HER ZAMAN bu satır kuruyor. Kurulan sahte kayıtta `guc` alanı YOKTU; DesenUret'in 536. satırı ("$($kayit.guc)"
    # -match 'ZAYIF|OLCULMEDI|^$') boş metni ZAYIF sayıp $dayanakZayif'i her seferinde true yapıyor, köprü dayanağı
    # yok sayılıp kör kök eşleşmesine düşülüyordu. Konu kaydı $KONULAR'da zaten duruyor: guc ve cikmis_dayanak
    # oradan verilir, böylece hazır soru yolu FAZ A ile aynı paketi görür.
    $kyD=$null; foreach($xk in $KONULAR){ if((Katla2 "$($xk.kayit.konu)") -eq (Katla2 "$($cvp.konu)")){ $kyD=$xk.kayit; break } }
    $ds=if($OZEL_DESEN.ContainsKey($konuLc2)){ $OZEL_DESEN[$konuLc2] } else { DesenUret ([pscustomobject]@{
          konu=$cvp.konu
          dayanak=$cvp.dayanak
          cikmis_dayanak=$(if($kyD -and $kyD.PSObject.Properties['cikmis_dayanak']){ "$($kyD.cikmis_dayanak)" } else { '' })
          guc=$(if($kyD -and $kyD.PSObject.Properties['guc']){ "$($kyD.guc)" } else { '' })
        }) }
    $amb2=AmbarCek $ds
    $kMetin=$amb2.metin
    if($amb2.adlar.Count){ $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb2.adlar) -Force }
  }
  # 03.09 ATIF GENISLETME: modelin dayanak alaninda andigi maddeler ambardan cekilip
  # kaynak paketinin BASINA konur (hakem once bunlari gorur). Ambarda yoksa paket degismez.
  if($cvp.PSObject.Properties['dayanak'] -and "$($cvp.dayanak)".Trim()){
    $atifD=@(AtifDesen "$($cvp.dayanak)")
    if($atifD.Count){
      # 03.09 OLCULDU (SMMM SPK kp-11): m.35/C dort parca, 3.500 tavani [4/4]'u (f.7) kesti -> hakem
      # 'fikra 7 kaynakta yok' dedi. Atif paketi 7.000, toplam 12.000 (haiku 200k pencere; maliyet ihmal).
      $atif=AmbarCek $atifD 7000
      if($atif.adlar.Count){
        $yeniAd=@($atif.adlar) + @(@($cvp.kaynak_adlar) | Where-Object { $atif.adlar -notcontains $_ })
        $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($yeniAd) -Force
        $cvp | Add-Member -NotePropertyName atif_genisletme -NotePropertyValue @($atif.adlar) -Force
        $kMetin=$atif.metin + "`n---`n" + $kMetin; if($kMetin.Length -gt 12000){ $kMetin=$kMetin.Substring(0,12000) }
        Write-Host "  ATIF GENISLETME: $id <- $(@($atif.adlar | Select-Object -First 3) -join ' ; ')" -ForegroundColor DarkCyan
      } else {
        # 08.09 Cem "kanun maddelerinin doğru olduğu": dayanaktaki madde ambarda yoksa numara doğrulanamaz → iz + hakeme TEYITSIZ uyarısı
        $cvp | Add-Member -NotePropertyName atif_ambarda_yok -NotePropertyValue $true -Force
        Write-Host "  ATIF AMBARDA YOK: $id | $($cvp.dayanak)" -ForegroundColor DarkYellow; $rapor.Add("ATIF AMBARDA YOK: $id | $($cvp.dayanak)")
      }
    }
  }
  # --- KAPI-HG · HESAP GRUBU GENISLETME (11.09.2026) --------------------------
  # DOGUSU: Cem muhur ornegi #4'te (sgs-t1-fmuh-kolay/kp-80) gercek hata buldu.
  # Iskat edilen hisse senetlerinin nominal ustu satisindan dogan 35.000 TL soruda
  # 529 Diger Sermaye Yedekleri'ne atilmisti; dogrusu 521 Hisse Senedi Iptal
  # Karlari. Ambardaki MSUGT metni 521'i olayin adiyla tarif ediyor, 529 ise kendi
  # tanimiyla "sayilanlarin DISINDA kalan" artik hesap.
  #
  # KOK NEDEN OLCULDU: o soruya giden kaynak paketi TTK m.482 + THP 333 + THP 407
  # + THP 433 + VUK m.5 VERGI MAHREMIYETI idi. Ne 521 ne 529 ne 500/501/102
  # PAKETTE YOKTU. Model hesabi ezberinden yazdi; hakem de "THP 529 hesap tanimi"
  # diyerek GORMEDIGI kaynagi dayanak gosterdi. Kor cozum de ayni korlukte ikinci
  # gozdu. Uc kapi da gecti cunku ucu de ayni eksik paketi okuyordu.
  #
  # SINIF OLCULDU (636 basilan soru): hesap kodunu ADIYLA anan 92 sorunun
  # 66'sinda (%71,7) o hesabin tanimi kaynak paketinde yoktu.
  #
  # NE YAPAR: soru yazildiktan SONRA, sorunun/sikklarin andigi her hesap kodunun
  # TUM GRUBU ambardan cekilip paketin basina konur (521 anilmasa bile 52x grubu
  # gelir). Boylece hakem dogru hesabi GORUR ve yanlisini soyleyebilir.
  # Kod ancak ardindan BUYUK HARFLE baslayan ad geliyorsa hesap kodu sayilir
  # ("501 Odenmemis Sermaye"); "BDS 240", "TMS 17", "m.482" bu kaliba uymaz.
  #
  # ⚠ $SB burada Supabase BASLIKLARIDIR (satir 87). Satir ~3525'te ayni ad
  #   StringBuilder'a veriliyor ($sb) ve PS harf ayirmadigi icin onu EZER. Bu blok
  #   3525'ten ONCE oldugu icin dogru calisiyor; hesap/atif cekimini oradan SONRAYA
  #   tasiyan biri sessizce kirar.
  if($cvp.siklar){
    $hgMetin = "$($cvp.soru) " + ((@('A','B','C','D','E') | ForEach-Object { "$($cvp.siklar.$_)" }) -join ' ')
    $hgKodlar = @(Get-HesapKodu $hgMetin)
    $hgGruplar = @($hgKodlar | ForEach-Object { $_.Substring(0,2) } | Select-Object -Unique)
    if($hgGruplar.Count){
      $hgParca = New-Object System.Collections.Generic.List[string]
      $hgAdlar = New-Object System.Collections.Generic.List[string]
      foreach($hgG in ($hgGruplar | Select-Object -First 6)){
        $hgU='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString("THP $hgG%")+'&limit=12'
        try{
          $hgR=Invoke-RestMethod -Uri $hgU -Headers $SB -TimeoutSec 60
          foreach($hgX in @($hgR)){ $hgParca.Add("[$($hgX.kaynak_ad)] $($hgX.metin)"); $hgAdlar.Add("$($hgX.kaynak_ad)") }
        }catch{}
      }
      if($hgParca.Count){
        $hgPaket=($hgParca -join "`n---`n")
        if($hgPaket.Length -gt 9000){ $hgPaket=$hgPaket.Substring(0,9000) }
        $kMetin = "=== ILGILI HESAP GRUBUNUN TUM HESAPLARI ===`n" + $hgPaket + "`n---`n" + $kMetin
        if($kMetin.Length -gt 20000){ $kMetin=$kMetin.Substring(0,20000) }
        $cvp | Add-Member -NotePropertyName hesap_genisletme -NotePropertyValue @($hgAdlar) -Force
        Write-Host ("  HESAP GRUBU: {0} <- {1} grubu, {2} hesap tanimi eklendi" -f $id,($hgGruplar -join '/'),$hgAdlar.Count) -ForegroundColor DarkCyan
      } else {
        Write-Host ("  HESAP GRUBU BOS: {0} <- {1} grubu ambardan gelmedi" -f $id,($hgGruplar -join '/')) -ForegroundColor DarkYellow
        $rapor.Add("HESAP GRUBU AMBARDA YOK: $id ($($hgGruplar -join '/'))")
      }
    }
  }
  # 09.09 GM pilotu: kp-10 hakemsiz kaldı, sebebi yalnız rapora yazılmıştı (konsolda iz yok) → konsola da yazılır
  if(-not $kMetin){ $rapor.Add("HAKEM ATLANDI (kaynak cekilemedi): $id"); Write-Host "  HAKEM ATLANDI (kaynak paketi BOŞ, soru yayına giremez): $id [$($cvp.konu)]" -ForegroundColor Red; continue }
  $gecici=@(GeciciMaddeNotu $cvp); $geciciNot=$(if($gecici.Count){ "DIKKAT: soru/dayanak gecici madde aniyor ($($gecici -join ', ')); gecici hukmun suresi kaynak metninde dolmussa ESKI." } else { '' })
  # 11.09 KAPI-KE isareti hakeme tasinir: sozcuk olcumu "etiket kelimeleri soru
# kokunde HIC gecmiyor" dediyse hakem konu uyumunu ozellikle denetler. Olculdu:
# bu isaretin tek basina isabeti %35, yani hukum degil DIKKAT CAGRISIDIR.
$keIsaret = $(if($cvp.PSObject.Properties['konu_sapma_isareti'] -and "$($cvp.konu_sapma_isareti)".Trim()){ "DIKKAT: sozcuk olcumu bu soruda konu sapmasi isaretledi ($($cvp.konu_sapma_isareti)); konu uyumunu ozellikle dikkatli denetle. " } else { '' })
$ih=$hakemIstem.Replace('{KE_ISARET}',$keIsaret).Replace('{DERS}',$DersRegex).Replace('{KOMSULAR}',$KOMSULAR).Replace('{TARIF}',$DERS_TARIF).Replace('{SORU}',"$($cvp.soru)").Replace('{DOGRU}',"$($cvp.dogru)").Replace('{SIK}',"$($cvp.siklar.$($cvp.dogru))").Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))").Replace('{KONU}',"$($cvp.konu)").Replace('{KAYNAK}',$kMetin).Replace('{DAYANAK}',"$($cvp.dayanak)").Replace('{GECICI}',$geciciNot)
  # 1. gecis: yalniz istemi topla (istem YUKARIDA ayni koddan kuruldu, sapma yok)
  if($script:ON_GECIS){ TopluTopla $id 'claude-haiku-4-5-20251001' $ih 2000; continue }
  $yh=TopluAl 'H' $id            # 2. gecis: partiden gelen cevap varsa bedava
  if($yh){ Write-Host "  HAKEM (toplu): $id" -ForegroundColor DarkGray }
  # 08.09 Tur 1 kazası 2: hakem JSON'una güncellik+atıf alanları eklenince 600 jeton yetmedi, 65 sorunun 31'inde cevap KESİLDİ → "HAKEM CIKTISI BOZUK"
  # yalnız rapora yazılıyordu, konsola değil; hakemsiz soru yayın şartını geçemedi (29 yayın kaybı). Tavan 1.600 + bozukluk konsola + kesilme notu.
  # 11.09: KAPI-HG iki alan daha ekledi (hesap_uyum, hesap_gerekce) -> 1.600 -> 2.000.
  # 08.09'da tam bu sebeple 65 sorunun 31'inde cevap KESILMISTI; tavan alanla birlikte buyur.
  if(-not $yh){ foreach($d in 1..3){ try{ $yh=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $ih -MaxTok 2000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } } }
  $hk=Coz $yh.metin
  if(-not ($hk -and $hk.karar)){ Write-Host "  HAKEM ÇIKTISI BOZUK ($id): durma=$($yh.dur) · $("$($yh.metin)".Length) kr" -ForegroundColor Red }
  if($hk -and $hk.karar){
    $cvp | Add-Member -NotePropertyName hakem -NotePropertyValue $hk -Force
    CacheYaz
    $renk=if("$($hk.karar)" -eq 'EVET'){'Green'}else{'Red'}
    Write-Host "  HAKEM $($hk.karar): $id" -ForegroundColor $renk
    # --- ENUM NOBETCISI (11.09, kapi turunda dogdu) --------------------------
    # Hakemin HER enum alani kodda '-eq <sabit>' ile sorgulaniyor. Model enum
    # DISINDA bir deger dondururse hicbir kosul tutmaz ve deger SESSIZCE yutulur.
    # Olculdu: kp-01'de dogru_sik_var='TEYITSIZ' geldi (enum EVET|HICBIRI idi).
    # Tek alani yamamak yerine HEPSI denetleniyor - ayni kusur 5 alanda mumkun.
    $ENUM_ALANLARI=@{
      karar        = @('EVET','HAYIR')
      ders_uyum    = @('EVET','DERS-DISI')
      konu_uyum    = @('EVET','KONU-DISI')
      tek_anlam    = @('EVET','CIFT-ANLAM')
      hesap_uyum   = @('EVET','HESAP-YANLIS','TEYITSIZ','YOK')
      dogru_sik_var= @('EVET','HICBIRI')
    }
    foreach($ea in $ENUM_ALANLARI.Keys){
      if(-not ($hk.PSObject.Properties[$ea])){ continue }
      $dv="$($hk.$ea)".Trim().ToUpperInvariant()
      if(-not $dv){ continue }
      if($ENUM_ALANLARI[$ea] -notcontains $dv){
        Write-Host "  ENUM DISI DEGER ($id): hakem.$ea = '$dv' (beklenen: $($ENUM_ALANLARI[$ea] -join '|'))" -ForegroundColor DarkYellow
        $rapor.Add("ENUM DISI: $id | hakem.$ea='$dv'")
      }
    }
    # 11.09 KAPI-HG: sessiz gecmesin - hesap hukmu ayri satir (Cem'in kp-80 bulgusu)
    # 11.09 KAPI-DS: "dogrusu hicbiri" hukmu sessiz gecmez ve karari HAYIR'a ceker
    # --- KAPI-KT: KAYNAK TEYIT (11.09, Cem onerisi) -------------------------
    # Hakemin GEREKCEDE andigi kaynak, kendisine verilen PAKETTE gercekten var mi?
    # OLCULDU (kp-80): hakem "Tekduzen Hesap Plani 529 ... hesap tanimi" diyerek
    # dayanak gosterdi; o tanim PAKETTE YOKTU. Yani hakem gormedigi bir kaynagi
    # dayanak yazdi - halusinasyon, ve kapi sormuyordu.
    # Deterministik: gerekcelerde anilan kimlikleri (hesap kodu · standart no)
    # cikar, paketin icinde ara. Pakette olmayan varsa isaretle.
    $ktMetin = "$($hk.gerekce) $($hk.hesap_gerekce) $($hk.konu_gerekce) $($hk.ders_gerekce)"
    $ktYok=New-Object System.Collections.Generic.List[string]
    foreach($kd in (Get-HesapKodu $ktMetin)){ if($kMetin -notmatch "(?<![\d.,])$kd(?![\d.,])"){ if($ktYok -notcontains "THP $kd"){ $ktYok.Add("THP $kd") } } }
    foreach($sn in (Get-StandartNo $ktMetin)){
      $on=($sn -split ' ')[0]; $no=($sn -split ' ')[1]
      if($kMetin -notmatch "(?i)$on\s*$no"){ if($ktYok -notcontains $sn){ $ktYok.Add($sn) } }
    }
    if($ktYok.Count){
      Write-Host ("  KAPI-KT ({0}): hakem PAKETTE OLMAYAN kaynagi dayanak gosterdi -> {1}" -f $id,($ktYok -join ', ')) -ForegroundColor Magenta
      $rapor.Add("KAPI-KT: $id | hakem gerekcesinde pakette olmayan kaynak: $($ktYok -join ', ')")
      $cvp | Add-Member -NotePropertyName hakem_kaynak_teyitsiz -NotePropertyValue ($ktYok -join ',') -Force
      CacheYaz
    }
    # 🔴 11.09 SESSIZ KAPI (kapi turunda bulundu): hakem enum DISINDA deger
    # dondurebiliyor. kp-01'de dogru_sik_var='TEYITSIZ' geldi; kodum yalniz
    # 'HICBIRI' uzerine islem yapiyordu ve TEYITSIZ sessizce yutuluyordu.
    # Bugun konusturdugumuz sessiz kapilarin aynisi - modelin serbest metin
    # donebildigi HER alan bu riski tasir.
    # Kural: EVET disindaki HER deger KONUSUR. HICBIRI sert (karar HAYIR),
    # otekiler isaret (hakem emin degil demektir, hukum degil).
    $dsv="$($hk.dogru_sik_var)".Trim().ToUpperInvariant()
    if($dsv -and $dsv -ne 'EVET' -and $dsv -ne 'HICBIRI'){
      Write-Host "  KAPI-DS BEKLENMEDIK DEGER ($id): dogru_sik_var='$dsv' -> hakem emin degil" -ForegroundColor DarkYellow
      $rapor.Add("KAPI-DS BELIRSIZ: $id | dogru_sik_var='$dsv' | $($hk.dogru_sik_gerekce)")
      $cvp | Add-Member -NotePropertyName dogru_sik_belirsiz -NotePropertyValue $dsv -Force
      CacheYaz
    }
    if($dsv -eq 'HICBIRI'){

      Write-Host "  DOGRU SIK YOK (KAPI-DS): $id [$($cvp.konu)] -> $($hk.dogru_sik_gerekce)" -ForegroundColor Magenta
      $rapor.Add("KAPI-DS DOGRU SIK YOK: $id | $($hk.dogru_sik_gerekce)")
      if("$($hk.karar)" -ne 'HAYIR'){ $hk.karar='HAYIR'; $cvp | Add-Member -NotePropertyName hakem -NotePropertyValue $hk -Force; CacheYaz }
    }
    if("$($hk.hesap_uyum)" -eq 'HESAP-YANLIS'){ Write-Host "  HESAP YANLIS (KAPI-HG): $id [$($cvp.konu)] -> $($hk.hesap_gerekce)" -ForegroundColor Magenta; $rapor.Add("HESAP YANLIS (KAPI-HG): $id | $($hk.hesap_gerekce)") }
    elseif("$($hk.hesap_uyum)" -eq 'TEYITSIZ'){ Write-Host "  HESAP TEYITSIZ (KAPI-HG): $id [$($cvp.konu)] -> hesap tanimi pakette yok" -ForegroundColor DarkYellow; $rapor.Add("HESAP TEYITSIZ (KAPI-HG): $id") }
    if("$($hk.tek_anlam)" -eq 'CIFT-ANLAM'){ Write-Host "  CIFT-ANLAM (KAPI E): $id [$($cvp.konu)] -> $($hk.tek_anlam_gerekce)" -ForegroundColor Magenta; $rapor.Add("CIFT-ANLAM (KAPI E): $($cvp.konu) | $($hk.tek_anlam_gerekce)") }
    # 08.09 güncellik + atıf (hakem 5 ve 6): ESKI / ATIF-YANLIS karar HAYIR'la gelir (istem); TEYITSIZ yayına çıkar ama karneye iz düşer
    if($hk.PSObject.Properties['guncellik'] -and "$($hk.guncellik)" -eq 'ESKI'){ Write-Host "  GÜNCELLİK ESKİ (KAPI-M/S hakem): $id [$($cvp.konu)] -> $($hk.guncellik_gerekce)" -ForegroundColor Magenta; $rapor.Add("GUNCELLIK ESKI (hakem): $($cvp.konu) | $($hk.guncellik_gerekce)") }
    if($hk.PSObject.Properties['atif'] -and "$($hk.atif)" -ne 'EVET'){ Write-Host "  ATIF $($hk.atif) (hakem): $id [$($cvp.konu)] -> $($hk.atif_gerekce)" -ForegroundColor $(if("$($hk.atif)" -eq 'ATIF-YANLIS'){'Magenta'}else{'DarkYellow'}); $rapor.Add("ATIF $($hk.atif) (hakem): $($cvp.konu) | $($hk.atif_gerekce)") }
  } else { $rapor.Add("HAKEM CIKTISI BOZUK: $id") }
}
# 1. gecisin rapor satirlarini geri al (FAZ A ile ayni desen): on gecis hicbir
# karar vermez, yalniz istem toplar; oradan rapora yazilan sey yanilticidir.
if($script:ON_GECIS){
  # On gecis paket kurarken rapora yaziyor ("ATIF AMBARDA YOK"); 2. gecis ayni
  # satirlari tekrar yazar -> rapor cift gorunur. FAZ A ile ayni sekilde geri alinir.
  while($rapor.Count -gt $raporH0){ $rapor.RemoveAt($rapor.Count-1) }
  TopluGonder 'H'
} }
$script:ON_GECIS=$false
$hakemRed=@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] -and ("$($don[$_].hakem.karar)" -eq 'HAYIR' -or "$($don[$_].hakem.konu_uyum)" -eq 'KONU-DISI') })
foreach($id in @($don.Keys)){ if($don[$id].PSObject.Properties['hakem'] -and "$($don[$id].hakem.konu_uyum)" -eq 'KONU-DISI'){ Write-Host "  KONU-DISI (KAPI D): $id [$($don[$id].konu)] -> $($don[$id].hakem.konu_gerekce)" -ForegroundColor Magenta } }
$dersRed=@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] -and "$($don[$_].hakem.ders_uyum)" -eq 'DERS-DISI' })

# 08.09 21:40 Cem "hakemi öne al yaz": KAPI B (dayanak hakemi, Haiku ≈0,03 USD/soru) artık FAZ A'nın hemen ardında. Tur 1 ölçümü: hakem HAYIR
# soruların üçte biri; her biri adım+giriş+ikiz+sim+kör+hakem2'den geçip ≈0,20 USD yiyordu. Hakemden geçmeyen soru pahalı fazlara GİRMEZ.
# Yayın kuralı değişmedi (koşucu 8.1: hakem EVET ∧ sim ∧ kör ∧ hakem2); yalnız sıra değişti. Bloğun kendisi 2644–2747'den taşındı, içi aynı.
$HAKEM_GECMEDI=New-Object 'System.Collections.Generic.HashSet[string]'
foreach($hid in @($don.Keys)){ $hc=$don[$hid]; if(-not $hc.soru){ continue }; if(-not ($hc.PSObject.Properties['hakem'] -and $hc.hakem -and "$($hc.hakem.karar)" -eq 'EVET')){ [void]$HAKEM_GECMEDI.Add($hid) } }
function HakemGecti([string]$id){ return -not $HAKEM_GECMEDI.Contains($id) }
if($HAKEM_GECMEDI.Count){ Write-Host "  HAKEM ÖNDE: $($HAKEM_GECMEDI.Count) soru hakemden geçmedi → adım/giriş/ikiz/sim/kör/hakem2 fazlarına girmeyecek ($((@($HAKEM_GECMEDI) | Select-Object -First 10) -join ', '))" -ForegroundColor Yellow; $rapor.Add("HAKEM ONDE: $($HAKEM_GECMEDI.Count) soru pahali fazlara girmedi") }
# --- FAZ K: KÖR ÇÖZÜM (07.09 A kovası 1 — Cem "hatasız olacak"; Maliyet kp-05'te yüzdeler ters kurulmuştu, hakem+sim+aritmetik üçü de geçirdi) -----
# Bağımsız ve FARKLI bir model, anlatımı/ikizi/açıklamayı görmeden yalnız soru + şıkları çözer. Cevap doğru şıkla tutmuyorsa soru yayına çıkmaz
# (koşucu seçimi kor_cozum.dogru_mu ister). Bir kez koşar, karar önbellekte; -KorYenile yeniden verdirir. Teori sorusunda da koşar (şık seçer).
$script:FAZ_ADI='K'
$korIstem=@'
Sen SMMM sınavına giren çok titiz bir adaysın. Aşağıdaki soruyu YALNIZ soru metnine ve şıklara dayanarak çöz; başka hiçbir bilgi verilmedi, tahmin etme.
Hesap sorusunda her ara işlemi yaz ve sonucu şıklarla karşılaştır. Şıkların hiçbiri sonucunla tutmuyorsa cevaba "HİÇBİRİ" yaz ve bulduğun sonucu belirt.
Teori sorusunda her şıkkı tek tek doğru/yanlış diye değerlendir, kökün ne istediğine (doğru mu, yanlış olan mı) dikkat et.
Yalnız JSON: {"cevap":"A|B|C|D|E|HİÇBİRİ","sonuc":"bulduğun sayı ya da ifade","hesap":"kısa hesap zinciri ya da şık şık gerekçe (en çok 60 kelime)","guven":"yüksek|orta|düşük","kusur":"soruda çelişki/eksik veri/iki doğru şık görürsen yaz, yoksa boş","kaynak_celisti":"ezberinle KAYNAK METNİ çelişiyorsa tek cümle yaz, yoksa boş"}
SORU: {SORU}
ŞIKLAR:
{SIKLAR}
{KAYNAK}
'@
# 11.09 Cem: "yeni kör göz ekleme; var olanı gerçekten kör-ama-kaynaklı yap."
# NEDEN: kp-80'de kör çözüm (Opus) de yanlış şıkkı seçti. Sebep göz sayısı değil —
# kör çözüme KAYNAK VERİLMİYOR, ezberinden çözüyor. Üreticiden farklı MODEL ama
# farklı BİLGİ KAYNAĞI değil; ikisi de aynı külliyattan öğrenmiş. Bir modelin
# ezberi yanlışsa ötekininki de büyük ihtimalle yanlış.
# KÖRLÜK NE DEMEK: açıklama, adımlar, hap, teşhis, sade, ikiz VERİLMEZ — yani
# "cevap nedir" bilgisi verilmez. Kaynak metni (kanun maddesi, hesap tanımı)
# gerçek bir sınav adayının çalıştığı şeydir; onu vermek körlüğü bozmaz.
$korKaynakEk=@'

=== KAYNAK METİNLERİ (çözüm DEĞİL; sınavda çalışmış olman beklenen mevzuat) ===
{METIN}
=== KAYNAK BİTTİ ===
Cevabı bu kaynaklardan DOĞRULA. Ezberin kaynakla çelişiyorsa KAYNAĞA uy ve
"kaynak_celisti" alanına neyin çeliştiğini yaz. Kaynak soruyu çözmeye yetmiyorsa
kendi bilginle çöz ama bunu "guven" alanına yansıt.
'@
foreach($gecisK in @(1,2)){ if($gecisK -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisK -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or $SadeceAdim){ break }
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]; if(-not $cvp.soru -or -not $cvp.siklar){ continue }
  if(-not $KorYenile -and $cvp.PSObject.Properties['kor_cozum'] -and $cvp.kor_cozum -and $cvp.kor_cozum.PSObject.Properties['dogru_mu']){ continue }
  $sikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $($cvp.siklar.$_)" }) -join "`n"
  # --- KÖR PAKETİ: kaynak VAR, anlatım YOK -----------------------------------
  # Pakete giren: hesap grubu tanımları (KAPI-HG'nin çektiği) + kaynak_metin_ozet.
  # Pakete GİRMEYEN: aciklama · adimlar · hap · teshis · sade · ikiz · dayanak
  #   gerekçesi. Bunlar "cevap nedir"i söyler; körlük onlarla bozulur.
  # Hesap tanımları ÖNE konur: ölçülen kusur sınıfı orada (92 sorunun 66'sında
  # anılan hesabın tanımı pakette yoktu).
  $korEk=''
  if($KorKaynak){
    $kp=New-Object System.Collections.Generic.List[string]
    foreach($ha in @($cvp.hesap_genisletme)){
      if(-not $ha){ continue }
      foreach($x in (AmbarCek @("$ha") 900).metin){ if($x){ $kp.Add("$x") } }
    }
    if("$($cvp.kaynak_metin_ozet)".Trim()){ $kp.Add("$($cvp.kaynak_metin_ozet)") }
    $km=($kp -join "`n---`n")
    if($km.Length -gt $KorKaynakTavan){ $km=$km.Substring(0,$KorKaynakTavan) }
    if($km){ $korEk=$korKaynakEk.Replace('{METIN}',$km) }
  }
  $istK=$korIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{SIKLAR}',$sikM).Replace('{KAYNAK}',$korEk)
  if($script:ON_GECIS){ TopluTopla $id $KorModel $istK 2500; continue }
  $yK=TopluAl 'K' $id
  if(-not $yK){ foreach($d in 1..3){ try{ $yK=Invoke-ClaudeMesaj -Model $KorModel -Icerik $istK -MaxTok 2500; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } } }
  Write-Host ("  KÖR TOKEN {0}: girdi {1} · cikti {2} · model {3}" -f $id,$yK.girdi,$yK.cikti,$KorModel) -ForegroundColor DarkGray
  $aK=Coz $yK.metin
  if(-not $aK -or -not $aK.PSObject.Properties['cevap']){ $rapor.Add("KÖR ÇÖZÜM BOZUK: $id"); Write-Host "  KÖR ÇÖZÜM BOZUK ($id)" -ForegroundColor Red; continue }
  $cev=("$($aK.cevap)".Trim().ToUpperInvariant() -replace '[^A-EHİ]','')
  if($cev -match '^H'){ $cev='HİÇBİRİ' } elseif($cev.Length -gt 1){ $cev=$cev.Substring(0,1) }
  $dm=($cev -eq "$($cvp.dogru)".Trim().ToUpperInvariant())
  $cvp | Add-Member -NotePropertyName kor_cozum -NotePropertyValue ([pscustomobject]@{ cevap=$cev; dogru=$cvp.dogru; dogru_mu=$dm; sonuc="$($aK.sonuc)"; hesap="$($aK.hesap)"; guven="$($aK.guven)"; kusur="$($aK.kusur)"; kaynak_celisti="$($aK.kaynak_celisti)"; kaynakli=[bool]$KorKaynak; model=$KorModel; tarih=(Get-Date -Format 'yyyy-MM-dd') }) -Force
  CacheYaz
  if($dm){ Write-Host "  KÖR ÇÖZÜM ✓ ($id): $cev" -ForegroundColor Green } else { Write-Host "  KÖR ÇÖZÜM ✗ ($id): kör $cev · anahtar $($cvp.dogru) · $("$($aK.hesap)".Substring(0,[Math]::Min(160,"$($aK.hesap)".Length)))" -ForegroundColor Red; $rapor.Add("KÖR ÇÖZÜM YANLIŞ: $id | kör $cev, anahtar $($cvp.dogru) | $($aK.hesap)") }
  if("$($aK.kusur)".Trim()){ $rapor.Add("KÖR ÇÖZÜM KUSUR NOTU: $id | $($aK.kusur)") }
  # 11.09: kaynakla ezber çeliştiyse bu EN DEĞERLİ sinyaldir - kp-80 tipi hatanın
  # doğrudan parmak izi. Sessiz geçmez.
  if("$($aK.kaynak_celisti)".Trim()){ Write-Host "  KÖR: KAYNAK ÇELİŞTİ ($id): $($aK.kaynak_celisti)" -ForegroundColor Magenta; $rapor.Add("KÖR KAYNAK ÇELİŞKİSİ: $id | $($aK.kaynak_celisti)") }
}
if($script:ON_GECIS){ TopluGonder 'K' } }
$script:ON_GECIS=$false
# --- FAZ H2: İKİNCİ HAKEM (07.09 A kovası 2 — "sınav sorusu gibi mi, yapay zeka kokusu var mı, çeldirici gerçek adayın tuzağı mı") ----------
# Birinci hakem kaynak-uyum bakar; bu hakem sınav kalıbı + dil + çeldirici gerçekçiliği + zorluk seviyesi verir. Karar EVET değilse koşucu seçmez.
$script:FAZ_ADI='H2'
$hakem2Istem=@'
Sen TESMER/TÜRMOB sınav komisyonunda yıllarca soru yazmış bir hakemsin. Aşağıdaki soruyu üç ölçüte göre değerlendir; yalnız JSON ver.
0. SINAVIN YAPISI (bu bilgi kesindir, itiraz etme): {YAPI}
1. sinav_gibi: Bu soru gerçek {SINAV} {DERS} sınav sorusu gibi mi? Kök kalıbı, uzunluk, şık biçimi (sonuç + kısa etiket, gerekçesiz), dil, veri sunumu sınavla uyumlu mu? EVET/HAYIR + gerekçe.
   DİKKAT: "Bu sınavda bu ders sorulmaz" DEME — dersin sınavda olduğu 0. maddede yazılıdır; yalnız SORUNUN KENDİSİNİ (kalıp, dil, biçim) o dersin çıkmış sorularıyla kıyasla.
2. koku: Yapay zeka izi var mı? Yer tutucu unvan yalnız ABC/XYZ gibi ANLAMSIZ harf dizisidir ("Çelik Makine Sanayi A.Ş." gibi gerçekçi ad koku DEĞİLDİR, yazma), bütün tutarların yuvarlak olması, klişe cümle ("önem arz etmektedir", "bu bağlamda"), aynı kalıbın tekrarı, uzun tire, doğru şıkkın diğerlerinden belirgin uzun/nüanslı olması, iki şıkkın birbirinin tam tersi olması. Bulduklarını LİSTELE, yoksa boş liste. Muhasebe tekniği hatası (ör. 590 hesabının yönü) koku değil, 3. maddede (celdirici_gercek HAYIR + gerekçe) yazılır.
3. celdirici_gercek: Yanlış şıklar gerçek bir adayın düşeceği tuzaklar mı (atlanan katman, ters işaret, yanlış oran, kavram karışıklığı), yoksa rastgele sayı/cümle mi? EVET/HAYIR + gerekçe. İki doğru şık ya da doğru şıkta hata görürsen burada yaz.
4. zorluk: kolay (tek kural tek işlem) | zor (iki zorluk kaynağı) | cok_zor (ters soru + çeldirici verilen + iki kuralın kesişimi).
karar: sinav_gibi EVET ve celdirici_gercek EVET ve koku boşsa EVET, değilse HAYIR.
Yalnız JSON: {"sinav_gibi":"EVET|HAYIR","sinav_gerekce":"...","koku":["..."],"celdirici_gercek":"EVET|HAYIR","celdirici_gerekce":"...","zorluk":"kolay|zor|cok_zor","karar":"EVET|HAYIR"}
SORU: {SORU}
ŞIKLAR:
{SIKLAR}
DOĞRU: {DOGRU}
DOĞRU ŞIKKIN AÇIKLAMASI: {ACIK}
'@
foreach($gecisH in @(1,2)){ if($gecisH -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisH -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or $SadeceAdim){ break }
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]; if(-not $cvp.soru -or -not $cvp.siklar){ continue }
  if(-not $Hakem2Yenile -and $cvp.PSObject.Properties['hakem2'] -and $cvp.hakem2 -and $cvp.hakem2.PSObject.Properties['karar']){
    # 08.09: eldeki karar API'siz yeniden türetilir (sert koku listesi değişti: "birbirinin tam tersi" artık sert değil) — 0 USD
    $h2=$cvp.hakem2; $tumKoku=@(@($h2.koku)+@($(if($h2.PSObject.Properties['koku_not']){ $h2.koku_not } else { @() })) | Where-Object { "$_" })
    $sertY=@($tumKoku | Where-Object { ($_ -match '(?i)\b(ABC|XYZ|DEF|KLM)\b|klişe|aynı (kalıp|cümle)|tekrar|uzun tire|em-dash|—|üç nokta|önem arz|bu bağlamda' -or ((@($h2.koku) -contains $_) -and $_ -match '(?i)yuvarlak')) -and $_ -notmatch '(?i)(Sanayi|Ticaret|Ltd|Holding|Tekstil|Gıda|İnşaat|Makine)\b.*(A\.Ş\.|Ltd)' -and $_ -notmatch '(?i)birbirinin (tam )?tersi' })
    $kararY=$(if("$($h2.sinav_gibi)" -eq 'EVET' -and "$($h2.celdirici_gercek)" -eq 'EVET' -and -not $sertY.Count){ 'EVET' } else { 'HAYIR' })
    if($kararY -ne "$($h2.karar)"){ $h2.karar=$kararY; $h2.koku=@($sertY); $h2 | Add-Member -NotePropertyName koku_not -NotePropertyValue @($tumKoku | Where-Object { $sertY -notcontains $_ }) -Force; CacheYaz; Write-Host "  HAKEM2 KARAR YENİDEN TÜRETİLDİ ($id): $kararY" -ForegroundColor Cyan }
    continue }
  $sikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $($cvp.siklar.$_)" }) -join "`n"
  $acikM=$(if($cvp.aciklama){ AciklamaDuz $cvp.aciklama.$($cvp.dogru) } else { '' })
  # 09.09 genel kültür pilotu ÖLÇÜLDÜ: hakem2 "SGS'de muhasebe/vergi sorulur, bu Türkçe/matematik sorusu SGS'ye ait değil" diyerek
  # turkce-kolay 2/2, mat-kolay 1/2, inkilap/ekonomi kolay 1'er soruyu düşürdü. Sınav yapısı (2026 yönergesi 6.2) isteme yazıldı.
  $YAPI_TARIF=$(switch -Regex ($Sinav){
    '^SGS' { 'SGS (Staja Başlama) 130 sorudur ve GENEL KÜLTÜR + YABANCI DİL bölümleri VARDIR: Türkçe 7, Matematik 8, Atatürk İlkeleri ve İnkılap Tarihi 5, Yabancı Dil (İngilizce) 10 = 30 soru; Alan bilgisi 100 soru (Finansal Muhasebe 26, Denetim 16, Maliyet 8, Mali Tablolar Analizi 8, Ekonomi 6, Maliye 6, Meslek/İş-SGK/Vergi/Ticaret/Borçlar Hukuku 6''şar). Matematik soruları soyut fonksiyon/limit/türev/seri sorularını da içerir (2026/2 kitapçığı soru 8-15); Yabancı Dil soruları İNGİLİZCE yazılır (soru 21-30); Türkçe soruları paragraf, yazım, dil bilgisi ölçer (soru 1-7).' }
    '^SMMM' { 'SMMM Yeterlilik sınavı 8 dersten oluşur; genel kültür bölümü YOKTUR.' }
    default { 'Sınav yapısı için ek bilgi yok; yalnız sorunun kalıbını değerlendir.' } })
  $istH=$hakem2Istem.Replace('{YAPI}',$YAPI_TARIF).Replace('{SINAV}',$Sinav).Replace('{DERS}',($DersRegex -replace '[\^\$\\]','')).Replace('{SORU}',"$($cvp.soru)").Replace('{SIKLAR}',$sikM).Replace('{DOGRU}',"$($cvp.dogru)").Replace('{ACIK}',"$acikM")
  if($script:ON_GECIS){ TopluTopla $id 'claude-sonnet-5' $istH 1500 $HAKEM2_EFFORT; continue }   # 08.09: yargı fazı, düşünme low
  $yH=TopluAl 'H2' $id
  if(-not $yH){ foreach($d in 1..3){ try{ $yH=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istH -MaxTok 1500 -Effort $HAKEM2_EFFORT; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } } }
  Write-Host ("  HAKEM2 TOKEN {0}: girdi {1} · cikti {2} · model claude-sonnet-5" -f $id,$yH.girdi,$yH.cikti) -ForegroundColor DarkGray
  $aH=Coz $yH.metin
  if(-not $aH -or -not $aH.PSObject.Properties['karar']){ $rapor.Add("HAKEM2 BOZUK: $id"); continue }
  $koku=@($aH.koku | Where-Object { "$_".Trim() })
  # 08.09 ölçümü: hakem2 gerçekçi işletme adını ("Çelik Makine Sanayi A.Ş.") yer tutucu sayıp düşürdü → yalnız DETERMİNİSTİK koku sınıfları kararı etkiler
  # (ABC/XYZ harf dizisi, hepsi yuvarlak tutar, klişe, aynı kalıp tekrarı, uzun tire); kalan koku notları bilgi olarak saklanır (koku_not).
  # "yuvarlak" iddiası yalnız bizim deterministik kuralımız da tutuyorsa (≥4 tutar, hepsi ONBİNLİK) sert sayılır — sınav soruları binlik yuvarlak tutar kullanır,
  # hakem2 08.09 testinde 40.000/58.000/66.000 gibi sınav-benzeri tutarları "yuvarlak" diye düşürüyordu. "Birbirinin tam tersi şık" (4c sızıntı) sert.
  $detKoku=@(KokuKusur $cvp); $detYuvarlak=[bool]($detKoku -match 'yuvarlak')
  # 08.09 Tur 1 denetim-cokzor: "birbirinin tam tersi şık" sert sayılıyordu ama KAPI-Ş TAM BUNU İSTİYOR (her tutar iki yönle; SGS 2020/3 ölçümü) →
  # 9 hakem2 reddinin çoğu buydu; sert listesinden çıkarıldı (koku_not'ta kalır).
  $kokuSert=@($koku | Where-Object { ($_ -match '(?i)\b(ABC|XYZ|DEF|KLM)\b|klişe|aynı (kalıp|cümle)|tekrar|uzun tire|em-dash|—|üç nokta|önem arz|bu bağlamda' -or ($detYuvarlak -and $_ -match '(?i)yuvarlak')) -and $_ -notmatch '(?i)(Sanayi|Ticaret|Ltd|Holding|Tekstil|Gıda|İnşaat|Makine)\b.*(A\.Ş\.|Ltd)' -and $_ -notmatch '(?i)birbirinin (tam )?tersi' })
  $karar=$(if("$($aH.sinav_gibi)" -eq 'EVET' -and "$($aH.celdirici_gercek)" -eq 'EVET' -and -not $kokuSert.Count){ 'EVET' } else { 'HAYIR' })   # karar makinede türetilir, modelin kararına güvenilmez
  $cvp | Add-Member -NotePropertyName hakem2 -NotePropertyValue ([pscustomobject]@{ karar=$karar; sinav_gibi="$($aH.sinav_gibi)"; sinav_gerekce="$($aH.sinav_gerekce)"; koku=@($kokuSert); koku_not=@($koku | Where-Object { $kokuSert -notcontains $_ }); celdirici_gercek="$($aH.celdirici_gercek)"; celdirici_gerekce="$($aH.celdirici_gerekce)"; zorluk="$($aH.zorluk)"; model='claude-sonnet-5'; tarih=(Get-Date -Format 'yyyy-MM-dd') }) -Force
  CacheYaz
  if($karar -eq 'EVET'){ Write-Host "  HAKEM2 EVET ($id) · zorluk $($aH.zorluk)" -ForegroundColor Green } else { Write-Host "  HAKEM2 HAYIR ($id): sınav gibi $($aH.sinav_gibi) · çeldirici $($aH.celdirici_gercek) · koku [$($koku -join '; ')] · $("$($aH.sinav_gerekce) $($aH.celdirici_gerekce)".Substring(0,[Math]::Min(200,"$($aH.sinav_gerekce) $($aH.celdirici_gerekce)".Length)))" -ForegroundColor Red; $rapor.Add("HAKEM2 HAYIR: $id | sınav gibi $($aH.sinav_gibi) · çeldirici $($aH.celdirici_gercek) · koku [$($koku -join '; ')]") }
}
if($script:ON_GECIS){ TopluGonder 'H2' } }
$script:ON_GECIS=$false

# 09.09 Cem "sırayı değiştir": KÖR ÇÖZÜM + HAKEM2 anlatımın ÖNÜNE alındı. Ölçüm: Sonnet çıktı jetonu toplam harcamanın %57'si ve neredeyse
# tamamı soru + ADIM anlatımı; hakemden geçen soruların ≈dörtte biri kör/hakem2'de düşüyor, düşmeden ÖNCE adım+giriş+ikiz+sim bedeli
# ödeniyordu. Bu iki kapı yalnız soru ve şıklara bakar, anlatıma ihtiyaç duymaz → önce onlar koşar, geçemeyen soru anlatım fazına girmez.
# Simülasyon (FAZ Ö) adımları okuduğu için yerinde kalır. Yayın kuralı DEĞİŞMEDİ (hakem ∧ sim ∧ kör ∧ hakem2).
if(-not ($SadeceHtml -or $SadeceAdim)){ foreach($hid in @($don.Keys)){ $hc=$don[$hid]; if(-not $hc.soru){ continue }   # yalnız çizim/adım modunda FAZ K ve H2 hiç koşmaz; kararları yok diye anlatım kapatılmaz
  $korOk=($hc.PSObject.Properties['kor_cozum'] -and $hc.kor_cozum -and $hc.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$hc.kor_cozum.dogru_mu)
  $h2Ok=($hc.PSObject.Properties['hakem2'] -and $hc.hakem2 -and "$($hc.hakem2.karar)" -eq 'EVET')
  if(-not ($korOk -and $h2Ok)){ [void]$HAKEM_GECMEDI.Add($hid) } } }
if($HAKEM_GECMEDI.Count){ Write-Host "  KAPI ÖNDE: $($HAKEM_GECMEDI.Count) soru hakem/kör/hakem2'den geçmedi → anlatım fazlarına (adım, giriş, ikiz, sim) girmeyecek" -ForegroundColor Yellow; $rapor.Add("KAPI ONDE: $($HAKEM_GECMEDI.Count) soru anlatim fazlarina girmedi") }

# --- FAZ B: ADIMLAR (hesaplilarda; genc dili) --------------------------------
$script:FAZ_ADI='B'
# 03.09 Cem "ogretmen her soruda olsun": tablosuz KAYIT sorulari da adim alir; tablo yerine yevmiye
# satirlarindan kurulan Kalem|Tutar tablosu verilir (kayit satirlari 'doldur' hedefi olur).
function AdimTablosu($cvp){
  if($cvp.cozum_tablo -and $cvp.cozum_tablo.satirlar -and @($cvp.cozum_tablo.satirlar).Count){ return $cvp.cozum_tablo }
  # (KayitListesi daha asagida tanimli - burada ayni mantik satir ici)
  $sm=$cvp.sema
  if(-not $sm -or "$($sm.tur)" -ne 'yevmiye'){
    # 04.09 (30'luk set: 30 sorunun 20'si teori/hukuk, tablo da yevmiye de yok) -> KAVRAM TABLOSU: dogru sik
    # aciklamasinin parcalari satir olur (Ne soruluyor / Kural / Bu olayda / Dogru sik); adimlar bunlari acar.
    if(-not $cvp.soru -or -not $cvp.dogru){ return $null }
    $ac="$($cvp.aciklama.$($cvp.dogru))"; $sat=@()
    $ne=[regex]::Match($ac,'(?s)Ne soruluyor:\s*(.*?)(?=Kural:|Hesap:|Bu olayda:|Doğrusu:|Dogrusu:|$)'); if($ne.Success -and $ne.Groups[1].Value.Trim()){ $sat+=,@('Ne soruluyor',$ne.Groups[1].Value.Trim()) }
    $ku=[regex]::Match($ac,'(?s)Kural:\s*(.*?)(?=Hesap:|Bu olayda:|Doğrusu:|Dogrusu:|$)'); if($ku.Success -and $ku.Groups[1].Value.Trim()){ $sat+=,@('Kural',$ku.Groups[1].Value.Trim()) }
    $ol=[regex]::Match($ac,'(?s)(Hesap:|Bu olayda:)\s*(.*?)(?=Doğrusu:|Dogrusu:|$)'); if($ol.Success -and $ol.Groups[2].Value.Trim()){ $sat+=,@('Bu olayda',$ol.Groups[2].Value.Trim()) }
    $sat+=,@('Doğru şık',"$($cvp.dogru)) $($cvp.siklar.$($cvp.dogru))")
    if($sat.Count -lt 2){ return $null }
    return [pscustomobject]@{ basliklar=@('Adım','İçerik'); satirlar=$sat; teori=$true }
  }
  $kyt=@(); if($sm.PSObject.Properties['kayitlar'] -and $sm.kayitlar){ $kyt=@($sm.kayitlar) } elseif($sm.PSObject.Properties['ogeler'] -and $sm.ogeler){ $kyt=@(,([pscustomobject]@{baslik='';ogeler=$sm.ogeler})) }
  if(-not $kyt.Count){ return $null }
  $sat=@(); foreach($ky in $kyt){ foreach($og in @($ky.ogeler.borc)){ $sat+=,@("$($og.hesap) (BORÇ)","$($og.tutar)") }; foreach($og in @($ky.ogeler.alacak)){ $sat+=,@("$($og.hesap) (ALACAK)","$($og.tutar)") } }
  if(-not $sat.Count){ return $null }
  return [pscustomobject]@{ basliklar=@('Kayıt','Tutar'); satirlar=$sat }
}
# 07.09 Ö56 (denetim-zor2 ölçümü: teori kuralı 7(j) genel hesap isteminin içinde kaldı, model eski kalıbı yazdı) → TEORİ DERSİ İÇİN AYRI İSTEM.
# "Bir olay, beş karar": tek somut olay, her şık bir karar sorusu, tanım yok; çıktı yapısı KAPI ile denetlenir (A–E şık adımı + karar alanı).
$adimIstemTeori=@'
Sen "Nöbetçi"sin: soru çözerek konu anlatan, hiç bilmeyene sabırla anlatan bir rehber. Aşağıdaki TEORİ sorusu için "BİR OLAY, BEŞ KARAR" dersi yaz.
YAZIM: Türkçe harfler tam ("şimdi", "kâr", "İptal"); kanun ve standart tam adıyla ("Türk Ticaret Kanunu", "TMS 36", "BDS 500"); "THP" kısaltması yasak. Resmî rapor dili yasak ("söz konusu", "dikkate alınır", "niteliğinde olup", "kapsamında"). Konuşur gibi, "sen" diliyle. Her anlatım EN ÇOK 3 kısa cümle. Adımda TANIM YOK (tanımlar kavramlar bölümünündür); "X nedir?" adımı yazma; soruyu yeniden anlatma.
YAPI — TAM 8 ADIM, bu sırayla:
1. formul "Olay: <tek somut hikâye>" — sorunun olayı DEĞİL, aynı kuralın başka bir işletmedeki gerçek olayı; rakamlı (tutar, tarih, adet), gencin gözünde canlanan; bütün ders bu tek olayda geçer. anlatim olayı kurar.
2. formul "Ne yapacağız: <kuralın iskeleti, bu olayın rakamlarıyla>" — kural bir kez söylenir; anlatim "beş ifadeyi bu olayda tek tek deneyeceğiz" ile biter.
3–7. HER ŞIK BİR ADIM, A→E sırasıyla. formul "Şık A: <olayda bu ifadenin karşılığı olan somut KARAR SORUSU, öğrenciye 'sen' diliyle>" (örnek: "Şık C: müdür 'işçi tazminatını satış masrafına ekleyelim' diyor, ekler misin?"). anlatim: olayda ne olur + kural + kaynağın hangi paragrafı/bendi (şık paragrafın bir bendine dayanıyorsa bendi an: "p.22(b)"). Alanlar ZORUNLU: "sik":"A", "karar":"doğru" ya da "yanlış" (İFADENİN kendisi doğru mu, yanlış mı), "paragraf":"p.28" ya da "p.22(b)" ya da "m.328" gibi kısa künye.
8. formul "Kapanış: A ✓ B ✓ C ✓ D ✗ E ✓" (gerçek dağılıma göre) — anlatim: tek cümle özet + öğrencinin bir daha yanılmamak için kendine soracağı TEK ayırt etme sorusu.
"hangisi doğrudur" sorusunda aynı yapı (✓/✗ dağılımı değişir). Öğrencinin seçtiği şıkkın yanılgı teşhisini sayfa ekler, sen yazma. "doldur" alanlarını boş dizi bırak. Kaynak metinlerine sadık kal; kaynakta olmayan kural uydurma.
Cevap YALNIZ JSON: {"adimlar":[{"formul":"...","anlatim":"...","sik":"A","karar":"doğru","paragraf":"p.21","doldur":[]}, ...],"verilen":[]}
=== SORU === {SORU}
=== ŞIKLAR === {SIKLAR}
=== DOĞRU ŞIK === {DOGRU}
=== DOĞRU ŞIKKIN AÇIKLAMASI === {ACIK}
=== TEŞHİS (her şık: ne sanıyorsun / aslında / nereden anlarsın) === {TESHIS}
=== KAYNAK METİNLERİ (ambardan) === {KAYNAK}
'@
foreach($gecisB in @(1,2)){ if($gecisB -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisB -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or ($SadeceAdim -and $script:FAZ_ADI -ne 'B')){ break }   # yalniz cizim / yalniz adim: diger model fazlari atlanir
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]
  $tabloAdim=AdimTablosu $cvp
  if(-not $tabloAdim){ continue }
  if(-not $AdimYenile -and $cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar -and $cvp.PSObject.Properties['verilen']){ continue }
  if($AdimYenile -and $cvp.PSObject.Properties['adimlar']){ Write-Host "  ADIM YENILENIYOR (ogretici istem): $id" -ForegroundColor Yellow }
  $teoriDers=[bool]($tabloAdim.PSObject.Properties['teori'] -and $tabloAdim.teori)
  if($teoriDers){
    $sikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $($cvp.siklar.$_)" }) -join "`n"; $teshisM=$(if($cvp.PSObject.Properties['teshis'] -and $cvp.teshis){ ConvertTo-Json -InputObject $cvp.teshis -Depth 4 -Compress } else { '(yok)' })
    $kayM=$(if($cvp.PSObject.Properties['kaynak_metin_ozet']){ "$($cvp.kaynak_metin_ozet)" } else { '' })
    $ist2=$adimIstemTeori.Replace('{SORU}',"$($cvp.soru)").Replace('{SIKLAR}',$sikM).Replace('{DOGRU}',"$($cvp.dogru)").Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))").Replace('{TESHIS}',$teshisM).Replace('{KAYNAK}',$kayM)
    Write-Host "  ADIM İSTEMİ: teori dersi (bir olay, beş karar) $id" -ForegroundColor DarkGray
  } else {
  # 08.09 önbellek: adım kural bloğu (≈13.000 kr, her soruda aynı) önek, soru metninden itibaren değişken (api-hedef Split-OnbellekBloklari)
  $ist2=$adimIstem.Replace('{SORUM}',$global:MEVZUAT_ONBELLEK_SINIR+"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $tabloAdim -Depth 5 -Compress)).Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))")
  # 03.09 "konuyu soruyla ogretelim": sorudaki hesaplarin Tekduzen Hesap Plani tanimlari (ambar) isteme eklenir;
  # "X nedir?" adimlari uydurma degil bu metinden yazilir. Supabase okumasi, model bedeli yok.
  $kodlarA=New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($st in @($tabloAdim.satirlar)){ foreach($m in [regex]::Matches("$(@($st)[0])",'(?<![\d.,])([1-7]\d{2})(?![\d.,])')){ [void]$kodlarA.Add($m.Groups[1].Value) } }
  foreach($h in 'A','B','C','D','E'){ foreach($m in [regex]::Matches((@(Get-HesapKodu "$($cvp.siklar.$h)") -join ' '),'([1-7]\d{2})')){ [void]$kodlarA.Add($m.Groups[1].Value) } }
  if($kodlarA.Count){ $thpD=AmbarCek @($kodlarA | ForEach-Object { "THP $_ %" }) 3500; if($thpD.metin){ $ist2+="`n=== HESAP TANIMLARI (Tekdüzen Hesap Planı, ambardan) ===`n"+$thpD.metin } }
  }
  # 08.09 ölçüm: adım çıktısının %76–86'sı düşünme jetonuydu (5.648 çıktı / 772 metin) → adım fazı effort=low; aritmetik/tek işlem/Türkçe kapıları
  # ve karne aynen çalışır, kusur artarsa tur tekrarı zaten var. $ADIM_EFFORT ile değiştirilebilir.
  if($script:ON_GECIS){ TopluTopla $id 'claude-sonnet-5' $ist2 12000 $ADIM_EFFORT; continue }
  $y2=$null; $a2=$null
  # 06.09 ADIM DİL KAPISI (Cem "geç"): anlatım en çok 2 cümle; 3+ cümleli adım sayısı 2'yi geçerse bir kez geri döner
  $aritK=@()
  foreach($turA in 1..3){
    $y2=$(if($turA -eq 1){ TopluAl 'B' $id } else { $null })
    if(-not $y2){ foreach($d in 1..3){ try{ $y2=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist2 -MaxTok 12000 -Effort $ADIM_EFFORT; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } } }
    # 03.09 bedel olcumu (Cem "her seyde bedeli sor"): cagri basina token kaydi
    Write-Host ("  ADIM TOKEN {0}: girdi {1} (onbellek okuma {2}, yazma {3}) · cikti {4} · model claude-sonnet-5" -f $id,$y2.girdi,$y2.onbellekOkuma,$y2.onbellekYazma,$y2.cikti) -ForegroundColor DarkGray
    $a2=Coz $y2.metin
    if(-not $a2 -or -not $a2.adimlar){ break }
    $cumleTavan=$(if($tabloAdim.PSObject.Properties['teori'] -and $tabloAdim.teori){ 3 } else { 2 })   # 07.09 Ö56: teori dersinde adım ≤3 cümle + karar sorusu
    $uzunAd=@(@($a2.adimlar) | Where-Object { $_ -and (@(("$($_.anlatim)" -split '(?<=[.!?])\s+') | Where-Object { $_.Trim().Length -gt 2 }).Count -gt $cumleTavan) }).Count
    $dolgu=@(@($a2.adimlar) | Where-Object { $_ -and "$($_.anlatim)" -match '(?i)(birazdan|az sonra|unutmayalım|hadi |işte |şimdi bakalım|hesaplamadık)' }).Count
    $aritK=@(AritmetikKusur $a2.adimlar)   # 06.09 ARİTMETİK KAPISI: formül zincirleri hesaplanır
    # 07.09 Ö56 YAPI KAPISI (teori dersi): A–E beş şık adımı, her birinde karar doğru/yanlış, tanım adımı yok
    $yapiK=@(); if($teoriDers){ $sikler=@(@($a2.adimlar) | Where-Object { $_ -and $_.PSObject.Properties['sik'] -and "$($_.sik)" } | ForEach-Object { "$($_.sik)".Trim().ToUpperInvariant() })
      foreach($hh in 'A','B','C','D','E'){ if($sikler -notcontains $hh){ $yapiK+="Şık $hh adımı yok" } }
      $kararsiz=@(@($a2.adimlar) | Where-Object { $_ -and $_.PSObject.Properties['sik'] -and "$($_.sik)" -and ("$($_.karar)" -notmatch '^(?i)(doğru|dogru|yanlış|yanlis)$') }).Count; if($kararsiz){ $yapiK+="$kararsiz şık adımında karar alanı doğru/yanlış değil" }
      $tanimli=@(@($a2.adimlar) | Where-Object { $_ -and "$($_.formul)" -match '(?i)\bnedir\b' }).Count; if($tanimli){ $yapiK+="$tanimli tanım adımı var (yasak)" }
      if(-not (@($a2.adimlar) | Where-Object { $_ -and "$($_.formul)" -match '^\s*Olay\s*:' })){ $yapiK+='1. adım "Olay:" değil' } }
    # 07.09 Cem (FIFO ekranı "neyle çarpıyor anlaşılmıyor") — TEK İŞLEM KAPISI: sayılı parçada parantez dışı ≥2 "+" VE terimlerde ×// varsa
    # (karışık formül: çarpımların toplamı) adım bölünmeli. Yalın toplam (a + b + c) serbest.
    $cokK=@(); if(-not $teoriDers){ foreach($ad in @($a2.adimlar)){ $f="$($ad.formul)"; if($f -match '^\s*(Verilen|Soruda ne var|Yanlış yol|Sağlama|Sonuç|Ters durum|Dahil değil)'){ continue }
        $segs=@($f -split '\s=\s'); if($segs.Count -lt 3){ continue }; $say=$segs[1]
        $d=0; $arti=0; $carp=$false; for($i=0;$i -lt $say.Length;$i++){ $ch=$say[$i]; if($ch -eq '('){ $d++ } elseif($ch -eq ')'){ $d-- } elseif($d -eq 0 -and $ch -eq '+' -and $i -gt 0 -and $say[$i-1] -eq ' '){ $arti++ } elseif($ch -match '[×x*/÷]'){ $carp=$true } }
        if($arti -ge 2 -and $carp){ $cokK+="'$($segs[0].Trim())' tek adımda $($arti+1) terimi çarpımla topluyor" } } }
    $cokOk=(-not $cokK.Count)
    $trA=@(AdimTurkceKusur $a2.adimlar $a2.verilen)   # 08.09 ADIM TÜRKÇE KAPISI: sözlükle onarır, kalan ASCII kelime tur tekrarlatır
    $dilOk=($uzunAd -le 2 -and $dolgu -eq 0); $aritOk=(-not $aritK.Count); $yapiOk=(-not $yapiK.Count)
    if(-not $cokOk -and $turA -lt 3){ $dilOk=$false }   # tek işlem kusuru turu tekrarlatır (son turda olduğu gibi kalır, rapora yazılır)
    if(-not $cokOk -and $turA -eq 3){ Write-Host "  TEK İŞLEM KAPISI son turda da düştü: $($cokK -join '; ')" -ForegroundColor Red; $rapor.Add("TEK ISLEM KAPI DÜŞTÜ: $id | $($cokK -join '; ')") }
    if($trA.Count -and $turA -lt 3){ $dilOk=$false }
    if($trA.Count -and $turA -eq 3){ Write-Host "  ADIM TÜRKÇE son turda da düştü: $($trA -join ', ')" -ForegroundColor Red; $rapor.Add("ADIM TURKCE DÜŞTÜ: $id | $($trA -join ', ')") }
    if(($dilOk -and $aritOk -and $yapiOk) -or $turA -eq 3){
      if(-not $dilOk){ Write-Host "  ADIM DİL: $uzunAd adım 3+ cümle · dolgu $dolgu (son turda da) - olduğu gibi" -ForegroundColor DarkYellow; $rapor.Add("ADIM DIL: $id (uzun $uzunAd, dolgu $dolgu)") }
      if(-not $aritOk){ Write-Host "  ARİTMETİK: $($aritK.Count) zincir tutmuyor (son turda da) - olduğu gibi, karneye KIRMIZI" -ForegroundColor Red; $rapor.Add("ARITMETIK KAPI DÜŞTÜ: $id | $($aritK -join ' · ')") }
      if(-not $yapiOk){ Write-Host "  YAPI KAPISI (teori dersi) son turda da düştü: $($yapiK -join '; ')" -ForegroundColor Red; $rapor.Add("YAPI KAPI DÜŞTÜ (teori dersi): $id | $($yapiK -join '; ')") }
      break }
    $notlar=@(); if($uzunAd -gt 2 -or $dolgu -gt 0){ $notlar+="$uzunAd adımın anlatımı $($cumleTavan+1)+ cümle ve $dolgu adımda dolgu cümlesi var; her anlatım EN ÇOK $cumleTavan cümle, dolgu cümlelerini sil" }
    if(-not $cokOk){ $notlar+="TEK İŞLEM KURALI (m): $($cokK -join '; '). Her çarpım terimi KENDİ adımı olsun (adı + nedeni + '= sonuç'), sonra ayrı bir toplama adımı tablo hücresini doldursun; tamamlanmayan oranı '(1 − %100 = %0)' biçiminde yaz" }
    if($trA.Count){ $notlar+="TÜRKÇE HARF: şu kelimeler Türkçe harfsiz yazılmış: $($trA -join ', '). Adım anlatımı, formül adları ve verilenlerde ş, ç, ğ, ı, ö, ü, İ tam yazılır (yıllık, değil, yanlış, hesabı, işletme)" }
    if(-not $aritOk){ $notlar+="şu formül satırları ARİTMETİK olarak tutmuyor (sol taraf hesaplanınca sağdaki sonuç çıkmıyor): $($aritK -join '; '). Her formülde sol tarafı gerçekten hesapla, sonucu ona göre yaz; ara sonuç ile tablo hücresi aynı olsun" }
    if(-not $yapiOk){ $notlar+="YAPI: $($yapiK -join '; '). Tam 8 adım: Olay · Ne yapacağız · Şık A · Şık B · Şık C · Şık D · Şık E (her birinde sik/karar/paragraf alanları) · Kapanış; tanım adımı yazma" }
    Write-Host "  ADIM KAPI ($id, tur $turA): $(if(-not $dilOk){"dil($uzunAd/$dolgu) "})$(if(-not $aritOk){"aritmetik($($aritK.Count)) "})$(if(-not $yapiOk){"yapı($($yapiK.Count))"}) -> tekrar" -ForegroundColor Yellow
    $ist2+="`n`nKAPI DÜŞTÜ: $($notlar -join ' · '). Yalnız JSON."
  }
  if($a2 -and $a2.adimlar){
    foreach($ad1 in @($a2.adimlar)){ if($ad1){ foreach($alan in @('anlatim','formul')){ if($ad1.PSObject.Properties[$alan] -and $ad1.$alan -is [string]){ $ad1.$alan=DilOnar $ad1.$alan } } } }   # sinav dili kapisi (adimlar)
    $cvp | Add-Member -NotePropertyName adimlar -NotePropertyValue $a2.adimlar -Force
    $cvp | Add-Member -NotePropertyName aritmetik -NotePropertyValue @($aritK) -Force   # boş = bütün zincirler tuttu (karne hücresi)
    $cvp | Add-Member -NotePropertyName verilen -NotePropertyValue @($a2.verilen) -Force
    CacheYaz; Write-Host "  ADIM OK $id"
  } else { $rapor.Add("ADIM BOZUK: $id") }
}
if($script:ON_GECIS){ TopluGonder 'B' } }
$script:ON_GECIS=$false

# --- FAZ S: SADE "DOĞRUSU" + ANAHTAR KAVRAM (Cem 04.09: "doğru kısmını herkesin anlayacağı dilde anlatsak";
# "belirli süreli sözleşmeyi kısa açıklasak") ---------------------------------------------------------------
# İki katman: sade cümle (hiç bilmeyene, kısaltma/madde numarası yok) + sınav dili (tek satır). Her yanlış şık için
# sade "neden yanlış". Anahtar kavram tanımı YALNIZ kaynak metninden (ambar); metinde yoksa listeye girmez.
# Yalnız -Sade / -SadeYenile ile koşar (bedel kuralı). Model: Haiku 4.5. Kapı: sade alanlarda kısaltma/madde no → 1 tekrar.
$script:FAZ_ADI='S'
$sadeIstem=@'
Sen Tetikte'nin Nöbetçisisin. Aşağıdaki sınav sorusunun cevabını, bu konuyu HİÇ bilmeyen birine anlatır gibi sade Türkçeyle yeniden yazacaksın. Kaynak metinler ve hesap tanımları ekte; kavram tanımlarını YALNIZ bu metinlerden çıkar, metinde yoksa uydurma, listeye alma.

SORU: {SORU}
ŞIKLAR: {SIKLAR}
DOĞRU ŞIK: {DOGRU}
ÜRETİCİNİN AÇIKLAMASI (sınav dili): {ACIK}
YANLIŞ ŞIK AÇIKLAMALARI: {YANLIS}

KURALLAR
1. dogru_sade: en fazla 3 kısa cümle, toplam 45 kelimeyi geçme. Olayın diliyle anlat ("dava büyük ihtimalle kaybedilecek, ne kadar ödeneceği tahmin edilebiliyor" gibi). Kısaltma yok (TMS, TFRS, VUK, TTK, THP, p., m. yazma), madde veya paragraf numarası yok, hesap kodu yazma, "sayılı" yazma. "Öğrenci ... sanır" kalıbı yasak. Neden bu cevap, tek nefeste anlaşılsın.
2. sinav_dili: tek cümle, sınavda geçtiği biçimde: kanun UZUN adı + madde ("Vergi Usul Kanunu 275. madde", "İş Kanunu 12. madde"); standartlar sınavda kısa adıyla geçer ("TMS 37 paragraf 11" serbest).
3. siklar_sade: her YANLIŞ şık için 1-2 cümle: aday bunu neden seçer, neden yanlış. Kural 1 burada da geçerli. Her şık farklı başlasın; aynı kalıp tekrar etmesin.
4. kavramlar: sorunun dayandığı 1-3 anahtar kavram (örnek: "belirli süreli iş sözleşmesi", "karşılık", "genel imalat gideri"). Her biri {"ad","tanim","kaynak"}: tanım 1-2 sade cümle; kaynak = ekteki metnin köşeli parantezdeki adı. Ekteki metinde tanım YOKSA o kavramı listeye ALMA.
5. Türkçe harfleri tam yaz (ç ğ ı İ ö ş ü); ASCII yazma.
6. Yalnız JSON döndür, başka hiçbir şey yazma:
{"dogru_sade":"...","sinav_dili":"...","siklar_sade":{"A":"...","B":"..."},"kavramlar":[{"ad":"...","tanim":"...","kaynak":"..."}]}
'@
function SadeKapi([string]$t){
  # sade katmanda yasak: kısaltma, madde/paragraf numarası, "sayılı", 60 kelimeden uzun
  $y=New-Object System.Collections.Generic.List[string]
  if([regex]::IsMatch($t,'(?i)(^|[^\wçğıöşü])(m|md|p|prg|f|s)\.\s*\d')){ $y.Add('madde/paragraf kısaltması') }
  if([regex]::IsMatch($t,'(?i)\b\d+\s*\.\s*(madde|fıkra|paragraf|bent|bend)')){ $y.Add('madde numarası') }
  if([regex]::IsMatch($t,'\b(TMS|TFRS|BDS|GDS|VUK|TTK|TBK|GVK|KVK|THP|AATUHK|İİK|KDVK|SPKn)\b')){ $y.Add('kısaltma') }
  if([regex]::IsMatch($t,'(?i)\bsayılı\b')){ $y.Add('"sayılı"') }
  if(@(($t -split '\s+') | Where-Object { $_ }).Count -gt 60){ $y.Add('60 kelimeden uzun') }
  return $y
}
function SadeKaynak($cvp){
  # hakemdeki paket mantığı (kaynak_adlar → dokümanlar; dayanak atıfları; hesap tanımları) - cvp DEĞİŞTİRİLMEZ
  $parca=New-Object System.Collections.Generic.List[string]
  if($cvp.PSObject.Properties['dayanak'] -and "$($cvp.dayanak)".Trim()){ $atifD=@(AtifDesen "$($cvp.dayanak)"); if($atifD.Count){ $atif=AmbarCek $atifD 5000; if($atif.metin){ $parca.Add($atif.metin) } } }
  if($cvp.PSObject.Properties['kaynak_adlar'] -and @($cvp.kaynak_adlar).Count){
    foreach($ka in (KaynakSirala $cvp.kaynak_adlar "$($cvp.konu)" 4)){
      $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ka)+'&limit=1'
      try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60; if(@($r).Count){ $parca.Add("[$ka] $(@($r)[0].metin)") } }catch{}
    }
  }
  $kodlarS=New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($h in 'A','B','C','D','E'){ foreach($m in [regex]::Matches((@(Get-HesapKodu "$($cvp.siklar.$h)") -join ' '),'([1-7]\d{2})')){ [void]$kodlarS.Add($m.Groups[1].Value) } }
  if($kodlarS.Count){ $thpS=AmbarCek @($kodlarS | ForEach-Object { "THP $_ %" }) 3000; if($thpS.metin){ $parca.Add($thpS.metin) } }
  $m0=($parca -join "`n---`n"); if($m0.Length -gt 9000){ $m0=$m0.Substring(0,9000) }
  return $m0
}
# --- 11.09 TOPLU: FAZ S de iki gecisli (Cem "toplu istege gec") --------------
# Yalniz 1. TUR toplu gider. 2. tur ancak SADE KAPISI dustugunde kosar ve
# istemi degistirir ("onceki cevap kullanilamadi..."); onu toplamak yanlis
# olurdu - degisen istem partiye girmez, anlik gider.
foreach($gecisS in @(1,2)){ if($gecisS -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisS -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or -not ($Sade -or $SadeYenile)){ break }   # FAZ S yalnız açık onayla koşar
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]
  if(-not $cvp.soru -or -not $cvp.dogru){ continue }
  if(-not $SadeYenile -and $cvp.PSObject.Properties['sade'] -and $cvp.sade){ continue }
  $kMetinS=SadeKaynak $cvp
  $siklarS=(@('A','B','C','D','E') | ForEach-Object { "$_) $($cvp.siklar.$_)" }) -join "`n"
  $yanlisS=(@('A','B','C','D','E') | Where-Object { $_ -ne "$($cvp.dogru)" -and $cvp.aciklama.PSObject.Properties[$_] } | ForEach-Object { "$_) $(AciklamaDuz $cvp.aciklama.$_)" }) -join "`n"
  $istS=$sadeIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{SIKLAR}',$siklarS).Replace('{DOGRU}',"$($cvp.dogru)").Replace('{ACIK}',(AciklamaDuz $cvp.aciklama.$($cvp.dogru))).Replace('{YANLIS}',$yanlisS)
  if($kMetinS){ $istS+="`n=== KAYNAK METİNLERİ (ambar) ===`n"+$kMetinS } else { $istS+="`n=== KAYNAK METNİ YOK: kavramlar listesi BOŞ dönsün ===" }
  if($script:ON_GECIS){ TopluTopla $id 'claude-haiku-4-5-20251001' $istS 1800; continue }
  $sadeN=$null; $tokG=0; $tokC=0; $sadeSebep=''
  foreach($tur in 1..2){
    $yS=$(if($tur -eq 1){ TopluAl 'S' $id } else { $null })   # yalniz 1. tur partiden gelir
    if(-not $yS){ foreach($d in 1..3){ try{ $yS=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istS -MaxTok 1800; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } } }
    $tokG+=[int]$yS.girdi; $tokC+=[int]$yS.cikti
    $sadeN=Coz $yS.metin
    # 11.09 Cem "sessiz kapiyi konustur": burasi SESSIZ dusuyordu. `Coz` null
    # dondugunde ya da `dogru_sade` bos geldiginde hicbir satir basilmadan
    # `break` ediliyordu; gerekce yalnizca sonda $rapor'a girip 629 KB'lik
    # HTML'in "Uretim notlari" satirina gomuluyordu - toplu turda kimsenin
    # bakmadigi yer. 10.09 turunda kp-14 bu yoldan dustu, cagrinin parasi
    # (2.840 girdi + 810 cikti token) odenmisti ve log tek kelime etmedi.
    # Artik: (1) sebep loga basilir, (2) ham cevabin basi gosterilir,
    # (3) 1. turda BREAK degil TEKRAR edilir - odenmis cagriya ikinci sans.
    if(-not $sadeN -or -not $sadeN.dogru_sade){
      $sadeSebep = if(-not $sadeN){ 'JSON cozulemedi' } else { 'dogru_sade alani bos' }
      $ham = "$($yS.metin)"; if($ham.Length -gt 160){ $ham=$ham.Substring(0,160) }
      $ham = $ham -replace '\s+',' '
      Write-Host ("  SADE COZULEMEDI ({0}) tur {1}/2: {2} · ham: {3}" -f $id,$tur,$sadeSebep,$ham) -ForegroundColor Red
      $sadeN=$null
      if($tur -eq 1){ $istS+="`n`nONCEKI CEVAP KULLANILAMADI ($sadeSebep). YALNIZ gecerli JSON don, once/sonra hicbir metin yazma. `dogru_sade` alani BOS BIRAKILAMAZ."; continue }
      break
    }
    $dusen=New-Object System.Collections.Generic.List[string]
    foreach($k1 in (SadeKapi "$($sadeN.dogru_sade)")){ $dusen.Add("dogru_sade: $k1") }
    if($sadeN.siklar_sade){ foreach($p in $sadeN.siklar_sade.PSObject.Properties){ foreach($k1 in (SadeKapi "$($p.Value)")){ $dusen.Add("siklar_sade.$($p.Name): $k1") } } }
    if(-not $dusen.Count){ break }
    if($tur -eq 1){ Write-Host "  SADE KAPI ($id): $($dusen -join '; ') -> tekrar" -ForegroundColor Yellow; $istS+="`n`nKAPI DÜŞTÜ: $($dusen -join '; '). Bu alanları olayın diliyle, kısaltmasız ve madde numarasız yeniden yaz. Yalnız JSON." }
    else { Write-Host "  SADE KAPI DUSTU ($id), olduğu gibi kaydedildi: $($dusen -join '; ')" -ForegroundColor Red; $rapor.Add("SADE KAPI: $id") }
  }
  Write-Host ("  SADE TOKEN {0}: girdi {1} · cikti {2} · model claude-haiku-4-5" -f $id,$tokG,$tokC) -ForegroundColor DarkGray
  # 11.09: bu satir da SESSIZDI - yalnizca $rapor'a yaziyordu (HTML'e gomulu).
  # Simdi ekrana da basar; digerleri (SIM BOZUK, TEORI IKIZ BOZUK) zaten boyle.
  if(-not $sadeN){
    $rapor.Add("SADE BOZUK: $id ($sadeSebep)")
    Write-Host ("  SADE BOZUK ({0}): {1} - 2 tur denendi, sade YAZILMADI" -f $id,$sadeSebep) -ForegroundColor Red
    continue
  }
  # kavram tanımı kaynak metninden mi? (5+ harfli kelimelerin en az %35'i kaynak metinde geçmeli; yoksa düşer)
  $kMetinK=Katla2 $kMetinS; $kavramlar=@()
  foreach($kv in @($sadeN.kavramlar)){ if(-not $kv -or -not $kv.ad -or -not $kv.tanim){ continue }
    $kel=@([regex]::Matches((Katla2 "$($kv.tanim)"),'[a-z]{5,}') | ForEach-Object { $_.Value } | Select-Object -Unique)
    $var=@($kel | Where-Object { $kMetinK.Contains($_) }).Count
    if($kel.Count -and ($var/$kel.Count) -ge 0.35){ $kavramlar+=[pscustomobject]@{ ad="$($kv.ad)"; tanim="$($kv.tanim)"; kaynak="$($kv.kaynak)" } }
    else { Write-Host "  KAVRAM DUSTU ($id): '$($kv.ad)' kaynak metninde karşılığı yok ($var/$($kel.Count))" -ForegroundColor DarkYellow }
  }
  $siklarSade=[ordered]@{}; if($sadeN.siklar_sade){ foreach($p in $sadeN.siklar_sade.PSObject.Properties){ if("$($p.Value)".Trim()){ $siklarSade[$p.Name]="$($p.Value)" } } }
  $sadeObj=[pscustomobject]@{ dogru="$($sadeN.dogru_sade)"; sinav=(DilOnar "$($sadeN.sinav_dili)"); siklar=[pscustomobject]$siklarSade; kavramlar=$kavramlar; model='claude-haiku-4-5'; token="$tokG/$tokC"; tarih=(Get-Date -Format 'yyyy-MM-dd') }
  $cvp | Add-Member -NotePropertyName sade -NotePropertyValue $sadeObj -Force
  CacheYaz; Write-Host "  SADE OK $id · kavram $($kavramlar.Count)"
}
if($script:ON_GECIS){ TopluGonder 'S' } }
$script:ON_GECIS=$false

# --- FAZ V: VERİLENLERİ TANI (06.09 Cem "soruda çok veri var, tabloda ikisi taşınmış; hiç bilmeyene böyle olmuyor" → "1 yap") ---
# Sorudaki HER sayı bir satır: ad + değer + tek cümlelik anlam. Builder tabloyu VERİLENLER → HESAP → SONUÇ diye çizer; Adım 1
# verilenleri tanıtır. Haiku, soru başına ≈0,005 USD. Kapı: listelenen her değer soru metninde geçmeli (uydurma sayı düşer);
# sorudaki sayıların en az %80'i listede olmalı, yoksa 1 tekrar. Yalnız -Verilenler / -VerilenYenile ile koşar (bedel kuralı).
# Yeni üretimlerde Sonnet FAZ A'da doğrudan yazar (soruIstem 4d); bu faz eldeki cache'ler içindir.
$script:FAZ_ADI='V'
$verilenIstem=@'
Sen Tetikte'nin Nöbetçisisin. Aşağıdaki sınav sorusunda VERİLEN her sayıyı, bu konuyu HİÇ bilmeyen birine tanıtacaksın.
KURALLAR
1. Soru metninde geçen HER sayı (tutarlar, miktarlar, oranlar, katsayılar, gün/ay) ayrı bir satır olur; soru metnindeki sırayla. Soruda olmayan sayı yazma.
2. ad: sınav dilinde kısa ad ("Ürün Q'nun fiili miktarı", "Yan mamulün satılabilir hâle getirme maliyeti"); kısaltma yok (DB YM, GÜG, FIFO yazma).
3. deger: soru metnindeki yazımıyla, birimiyle ("2.000 kg", "%30", "14.800 TL").
4. anlam: tek cümle, hiç bilmeyene bu sayının NE olduğu ve hesapta NEREDE kullanılacağı ("yan ürünü satabilmek için yapılan ek harcama; yan ürünün satış değerinden düşülür"). En çok 25 kelime. "Öğrenci … sanır" kalıbı yok.
5. Türkçe harfler tam (ç ğ ı İ ö ş ü). Yalnız JSON döndür: {"verilenler":[{"ad":"...","deger":"...","anlam":"..."}]}
SORU: {SORU}
ÇÖZÜM TABLOSU (bu sayıların hangi hesapta kullanıldığını görmek için): {TABLO}
'@
foreach($id in @($don.Keys)){
  if($SadeceHtml -or -not ($Verilenler -or $VerilenYenile)){ break }
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]; if(-not $cvp.soru){ continue }
  if(-not $VerilenYenile -and $cvp.PSObject.Properties['verilenler'] -and @($cvp.verilenler).Count){ continue }
  # standart/madde numaraları verilen değildir ("BDS 500", "TMS 37", "m.323", "paragraf A27", "213 sayılı") — 06.09 kalıp-6 dersi
  $soruTemiz=[regex]::Replace("$($cvp.soru)",'(?i)\b(BDS|GDS|TMS|TFRS|TSRS|BOBİ FRS|KGK|SPK)\s*\d+[A-Za-z]?|\b(m|md|p|paragraf|madde|fıkra|bent)\.?\s*[A-Za-z]?\d+(/\d+)?|\d+\s+sayılı','')
  $soruSayi=@([regex]::Matches($soruTemiz,'%?\d{1,3}(?:\.\d{3})*(?:,\d+)?') | ForEach-Object { $_.Value -replace '[^\d,%]','' } | Select-Object -Unique)
  if(-not $soruSayi.Count){ Write-Host "  VERILEN ATLANDI ($id): soruda sayısal veri yok (teori)" -ForegroundColor DarkGray; continue }
  $istV=$verilenIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{TABLO}',$(if($cvp.cozum_tablo){ ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress } else { '(tablo yok)' }))
  $listeV=$null; $tokG=0; $tokC=0
  foreach($tur in 1..2){
    $yV=$null; foreach($d in 1..3){ try{ $yV=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istV -MaxTok 1500; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
    $tokG+=[int]$yV.girdi; $tokC+=[int]$yV.cikti
    $vN=Coz $yV.metin; if(-not $vN -or -not $vN.verilenler){ $listeV=$null; break }
    $secilen=@()
    foreach($x in @($vN.verilenler)){ if(-not $x -or -not $x.deger){ continue }; $dn="$($x.deger)" -replace '[^\d,%]',''
      if($dn -and ($soruSayi -contains $dn)){ $secilen+=[pscustomobject]@{ ad=(DilOnar "$($x.ad)"); deger="$($x.deger)"; anlam=(DilOnar "$($x.anlam)") } }
      else { Write-Host "  VERILEN DUSTU ($id): '$($x.deger)' soru metninde yok" -ForegroundColor DarkYellow } }
    $listeV=$secilen
    $kapsananN=@($soruSayi | Where-Object { $s0=$_; @($secilen | Where-Object { ("$($_.deger)" -replace '[^\d,%]','') -eq $s0 }).Count -gt 0 }).Count
    $kapsam=$kapsananN / [double]$soruSayi.Count
    if($kapsam -ge 0.8){ break }
    if($tur -eq 1){ Write-Host ("  VERILEN KAPI ({0}): sorudaki sayıların %{1} listelendi -> tekrar" -f $id,[int]($kapsam*100)) -ForegroundColor Yellow; $istV+="`n`nKAPI DÜŞTÜ: soru metnindeki sayıların bir kısmı listede yok. HER sayıyı ayrı satır yap. Yalnız JSON." }
    else { $rapor.Add("VERILEN KAPI: $id (%$([int]($kapsam*100)))") }
  }
  Write-Host ("  VERILEN TOKEN {0}: girdi {1} · cikti {2} · model claude-haiku-4-5" -f $id,$tokG,$tokC) -ForegroundColor DarkGray
  if(-not $listeV -or -not @($listeV).Count){ $rapor.Add("VERILEN BOZUK: $id"); continue }
  $cvp | Add-Member -NotePropertyName verilenler -NotePropertyValue @($listeV) -Force
  CacheYaz; Write-Host "  VERILEN OK $id · $(@($listeV).Count) satır"
}

# --- FAZ G: KONU GİRİŞİ (06.09 Cem "geç"; 26.08 konu notu katmanı kararının ilk parçası) ----------------------------------
# Soruya girmeden 3 parça: konu nedir · sınavda nasıl sorulur · yöntemler ve ne zaman hangisi. Nöbetçi'nin 0. adımı olarak çizilir.
# Haiku, ≈0,005 USD/soru. Kapı: ≤90 kelime, kısaltma/madde no yok (SadeKapi). Yalnız -KonuGiris ile.
$script:FAZ_ADI='G'
$girisIstem=@'
Sen Tetikte'nin Nöbetçisisin. Aşağıdaki sınav sorusunun KONUSU için, konuyu HİÇ bilmeyen bir gence İKİ KATMANLI giriş yaz (07.09 Ö54: panel = teşhis, Nöbetçi 0. adım = ders; iki katmanda AYNI CÜMLE OLMAZ).
KATMAN 1 — PANEL (şık seçilir seçilmez görünür, 20 saniyede okunur; kısaltma yok, madde numarası yok):
1. nedir: konu İKİ cümlede — ne işe yarar, sınav neyi ölçer.
2. panel_ornek: gencin günlük hayatından TEK örnek, 2-3 cümle, RAKAMLI olabilir (ikinci el telefon, kiralık ev, araba taksiti gibi);
   rakamlar sorunun rakamları DEĞİL ve sorunun rakamlarının ÖLÇEKLİ KOPYASI DA DEĞİL (800.000 → 800 yazmak yasaktır, cevabı sızdırır);
   tamamen farklı, küçük ve yuvarlak rakamlar; hesap yazıyorsan doğru yap. "ha, bu demek" dedirtsin.
KATMAN 2 — NÖBETÇİ 0. ADIM (ders; panelle aynı cümle yok):
3. harita: konunun cevapladığı üç soru, her biri tek cümle ("Ne zaman test edilir: … / Nasıl ölçülür: … / Nasıl kaydedilir: …" gibi; konuya
   göre üç soru değişir). En çok 3 cümle.
4. terimler: konunun DÖRT anahtar terimi: [{"ad":"...","tanim":"en çok 12 kelime","kim":"kim belirler (bu dersin seçenekleri aşağıda)","kaynak":"sınavda nereden gelir: soruda verilir | sen hesaplarsın | kuraldan bilinir"}]
   (07.09 Cem: "kullanım değerini kim belirliyor? soruda bize verilmiş, biz değerledik tarzı" — öğrenci hangi sayıyı soruda arayacağını, hangisini hesaplayacağını bilmeli).
   "kim" ile "kaynak" FARKLI bilgidir: kim = o değeri/kuralı GERÇEK HAYATTA kim koyar; kaynak = SINAVDA o değer nereden gelir (soruda verilir · sen hesaplarsın · kuraldan bilinir).
   "kim" alanına "hesaplanır / bulunur / sen hesaplarsın / muhasebe kayıtları hesaplar" YAZMA — bunlar kaynak alanının işidir, kim alanı bir KİŞİ ya da KURUM söyler.
   BU DERSTE "kim" için yalnız şu seçenekler geçerlidir: {KIMSECENEK}
   İkisine aynı ifadeyi yazma. Tanım KAVRAMI söyler, yerini değil:
   tutar terimlerinde "neyden ne düşülür, ne kalır" biçimi ("Defter değeri: maliyet bedelinden ayrılan birikmiş amortisman düşüldükten sonra
   kalan net tutar"); "tablodaki tutar", "yukarıdaki değer" gibi yer tarifi YASAK (07.09 Cem: "amortisman düşüldükten sonra tablodaki tutar" kusurlu).
5. desen: sınav bu konuyu nasıl sorar — tuzak noktaları kaynak paragrafı/maddesiyle (burada "p.28" gibi künye serbest), en çok 3 cümle,
   son cümle "Bu soru … noktasından geliyor." Çıkmış dönem sayısı ektedir, uydurma sayı yazma.
6. sinavda: 1 cümle, ne verilir ne istenir; işlem adı/formül yazma. 7. yontemler: en çok 2 cümle (tek yöntemse en kritik kural).
Toplam 220 kelimeyi geçme. Yalnız kaynak metinleri ve soruya dayan. Türkçe harfler tam.
Yalnız JSON: {"nedir":"...","panel_ornek":"...","harita":"...","terimler":[{"ad":"...","tanim":"..."}],"desen":"...","sinavda":"...","yontemler":"...","ornek":"..."}  ("ornek" = panel_ornek ile aynı metin, eski alan)
KONU: {KONU} · çıkmış arşivde {DONEM} dönemde soruldu
SORU: {SORU}
=== KAYNAK METİNLERİ === {KAYNAK}
'@
# 07.09 Cem (FMuh gelir tablosu girişi: "hisse senedi satış kârı · denetçi belirler · sen hesaplarsın — ne bu, yanlış"): istem "denetçi belirler"i
# BÜTÜN derslere örnek veriyordu, model muhasebe sorusunda onu seçti. "kim" seçenekleri DERSE göre verilir + ders dışı belirleyen kapıda düşer.
$dersAdiG=($DersRegex -replace '[\^\$\\]','')
$kimDenetim=($dersAdiG -match 'Denetim')
$kimHukuk=($dersAdiG -match 'Vergi|Ticaret|Borclar|Borçlar|Is ve Sosyal|İş ve Sosyal|Meslek')
$kimSecenek=$(if($kimDenetim){ 'denetçi mesleki yargıyla belirler · standart (BDS) sabitler · işletme yönetimi yalnız finansal tabloyu ve beyanı hazırlar (belirleyici değildir)' }
  elseif($kimHukuk){ 'kanun sabitler · mahkeme ya da idare karar verir · taraflar sözleşmeyle belirler · meslek kuruluşu düzenler · mükellef / işveren beyan eder. Denetçi bu derste belirleyici DEĞİLDİR, yazma.' }
  else { 'işletme yönetimi tahmin eder ya da belirler (faydalı ömür, tamamlanma yüzdesi, normal kapasite) · piyasa fiyatlar (satış bedeli, alış bedeli gibi gerçekleşen tutarlar) · Tekdüzen hesap planı ya da standart tanımlar · kanun sabitler. DENETÇİ bu derste belirleyici DEĞİLDİR, yazma.' })
$girisIstem=$girisIstem.Replace('{KIMSECENEK}',$kimSecenek)
foreach($gecisG in @(1,2)){ if($gecisG -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisG -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or -not $KonuGiris){ break }
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]; if(-not $cvp.soru){ continue }
  if(-not $GirisYenile -and $cvp.PSObject.Properties['konu_giris'] -and $cvp.konu_giris -and $cvp.konu_giris.nedir -and $cvp.konu_giris.PSObject.Properties['harita'] -and "$($cvp.konu_giris.harita)".Trim()){ continue }   # 07.09 Ö54: haritasız (eski iki katmansız) giriş yenilenir; -GirisYenile hepsini
  $kMetinG=SadeKaynak $cvp; if($kMetinG.Length -gt 6000){ $kMetinG=$kMetinG.Substring(0,6000) }
  $istG=$girisIstem.Replace('{KONU}',"$($cvp.konu)").Replace('{DONEM}',"$($cvp.donem)").Replace('{SORU}',"$($cvp.soru)").Replace('{KAYNAK}',$(if($kMetinG){ $kMetinG } else { '(kaynak metni yok: yalnız soruya dayan, genel kural yazma)' }))
  if($script:ON_GECIS){ TopluTopla $id 'claude-sonnet-5' $istG 3000 $GIRIS_EFFORT; continue }   # 08.09: giriş anlatım fazı, düşünme low (pilot: 4.177 çıktı / 2.243 kr metin, max_tokens'ta kesildi)
  $gN=$null; $tokG=0; $tokC=0
  foreach($tur in 1..2){
    # 07.09 Ö54/Ö27: iki katmanlı giriş + rakamlı gencin örneği → Sonnet (Haiku aritmetiği güvenilmezdi, "hesap yasak" kapısı kalktı) ≈0,02 USD
    $yG=$(if($tur -eq 1){ TopluAl 'G' $id } else { $null })
    if(-not $yG){ foreach($d in 1..3){ try{ $yG=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istG -MaxTok 3000 -Effort $GIRIS_EFFORT; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } } }   # 07.09 denetim-zor2: 1600'de kesildi, giriş kaydedilmedi → 3000
    $tokG+=[int]$yG.girdi; $tokC+=[int]$yG.cikti
    $gN=Coz $yG.metin; if(-not $gN -or -not $gN.nedir){ if($tur -eq 1){ Write-Host "  GİRİŞ BOZUK ($id, tur 1): JSON çözülemedi (durma=$($yG.dur), $("$($yG.metin)".Length) kr) -> daha kısa, tekrar" -ForegroundColor Yellow; $istG+="`n`nÖNCEKİ CEVAP KESİLDİ/BOZUKTU: bütün alanları daha KISA yaz (toplam 180 kelime), yalnız JSON."; $gN=$null; continue }; $gN=$null; break }
    if(-not ($gN.PSObject.Properties['ornek'] -and "$($gN.ornek)".Trim()) -and $gN.PSObject.Properties['panel_ornek']){ $gN | Add-Member -NotePropertyName ornek -NotePropertyValue "$($gN.panel_ornek)" -Force }
    if(-not ($gN.PSObject.Properties['panel_ornek'] -and "$($gN.panel_ornek)".Trim())){ $gN | Add-Member -NotePropertyName panel_ornek -NotePropertyValue "$($gN.ornek)" -Force }
    $tumG="$($gN.nedir) $($gN.panel_ornek) $($gN.sinavda)"; $dusenG=@(SadeKapi $tumG | Where-Object { $_ -ne '60 kelimeden uzun' })
    $tumG2="$($gN.nedir) $($gN.panel_ornek) $($gN.harita) $($gN.desen) $($gN.sinavda) $($gN.yontemler)"; if(@(($tumG2 -split '\s+') | Where-Object { $_ }).Count -gt 240){ $dusenG+='240 kelimeden uzun' }; if(-not "$($gN.ornek)".Trim()){ $dusenG+='örnek yok' }
    if(-not "$($gN.harita)".Trim()){ $dusenG+='harita yok' }; if(@($gN.terimler).Count -lt 3){ $dusenG+='terimler eksik (4 gerek)' }; if(-not "$($gN.desen)".Trim()){ $dusenG+='desen yok' }
    # 07.09 Cem: terim tanımı yer tarif etmez ("tablodaki tutar"); kavramı söyler ("… düşüldükten sonra kalan net tutar")
    $yerTarif=@(@($gN.terimler) | Where-Object { $_ -and "$($_.tanim)" -match '(?i)\b(tablodaki|tabloda|yukarıdaki|aşağıdaki|soldaki|sağdaki)\b' } | ForEach-Object { "$($_.ad)" }); if($yerTarif.Count){ $dusenG+="terim tanımı yer tarif ediyor ($($yerTarif -join ', ')) — kavramı yaz: neyden ne düşülür, ne kalır" }
    # 07.09 Cem "kullanım değerini kim belirliyor?": her terimde kim + kaynak alanı dolu olmalı (denetim-zor2 girişi boş bıraktı)
    $eksikKim=@(@($gN.terimler) | Where-Object { $_ -and $_.ad -and (-not ($_.PSObject.Properties['kim'] -and "$($_.kim)".Trim()) -or -not ($_.PSObject.Properties['kaynak'] -and "$($_.kaynak)".Trim())) } | ForEach-Object { "$($_.ad)" }); if($eksikKim.Count){ $dusenG+="terimlerde 'kim belirler' / 'sınavda kaynağı' boş ($($eksikKim -join ', '))" }
    # 07.09: kim == kaynak ("soruda verilir · soruda verilir") ya da denetim dersinde "işletme yönetimi" belirleyen → kapı
    $ayniKim=@(@($gN.terimler) | Where-Object { $_ -and $_.ad -and $_.PSObject.Properties['kim'] -and $_.PSObject.Properties['kaynak'] -and ((Katla2 "$($_.kim)") -eq (Katla2 "$($_.kaynak)")) } | ForEach-Object { "$($_.ad)" }); if($ayniKim.Count){ $dusenG+="'kim' ile 'kaynak' aynı yazılmış ($($ayniKim -join ', ')); kim = belirleyen, kaynak = sınavda nereden" }
    if($DersRegex -match 'Denetim'){ $yonetimK=@(@($gN.terimler) | Where-Object { $_ -and $_.ad -and "$($_.kim)" -match '(?i)işletme yönetimi|isletme yonetimi|yönetim tahmin' } | ForEach-Object { "$($_.ad)" }); if($yonetimK.Count){ $dusenG+="denetim teriminde belirleyen işletme yönetimi olamaz ($($yonetimK -join ', ')); denetçi ya da standart yaz" } }
    # 07.09 Cem "denetçi belirler ne bu": denetim dışı derste belirleyen denetçi olamaz; "kim" alanına kaynak cümlesi (hesaplanır/bulunur/sen hesaplarsın) yazılamaz
    if(-not $kimDenetim){ $denetciK=@(@($gN.terimler) | Where-Object { $_ -and $_.ad -and "$($_.kim)" -match '(?i)denetçi|denetci' } | ForEach-Object { "$($_.ad)" }); if($denetciK.Count){ $dusenG+="bu derste belirleyen denetçi olamaz ($($denetciK -join ', ')); seçenekler: $kimSecenek" } }
    $kaynakGibiKim=@(@($gN.terimler) | Where-Object { $_ -and $_.ad -and "$($_.kim)" -match '(?i)hesapla|bulunur|sen |kayıtları|kayitlari|sistemi hesap|sonucu oluşur|sonucundan bilinir' } | ForEach-Object { "$($_.ad)" }); if($kaynakGibiKim.Count){ $dusenG+="'kim' alanı kaynak gibi yazılmış ($($kaynakGibiKim -join ', ')); kim = kişi ya da kurum" }
    # panel ile 0. adım aynı cümleyi taşımasın (tekrar kapısı): nedir/panel_ornek cümleleri harita/desen içinde geçmez
    $panelC=@(("$($gN.nedir) $($gN.panel_ornek)" -split '(?<=[.!?])\s+') | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -ge 25 }); $dersM="$($gN.harita) $($gN.desen)"; $tekrarC=@($panelC | Where-Object { $dersM.Contains($_) }); if($tekrarC.Count){ $dusenG+="panel cümlesi 0. adımda tekrar ediyor ($($tekrarC.Count))" }
    # 06.09 Cem ekran görüntüsü: örnek sorunun kendi rakamlarını (500.000, 225.000, 45.000) tekrarlayıp cevabı 1. adımda veriyordu → sorudaki her 3+ haneli tutar örnekte YASAK
    $soruTutar=@([regex]::Matches("$($cvp.soru)",'\d{1,3}(?:\.\d{3})+|\b\d{3,}\b') | ForEach-Object { $_.Value } | Select-Object -Unique); $tekrar=@($soruTutar | Where-Object { $t=$_; "$($gN.ornek)" -match ('(?<![\d.])'+[regex]::Escape($t)+'(?![\d.])') })
    # 07.09 maliyet-zor2: "100" (100 TL/ton) tek başına sızıntı sayıldı, giriş reddedildi. Üç haneli yalın sayı (100, 200, 500) yaygındır:
    # sızıntı = binlik ayraçlı/4+ haneli tutar tekrarı YA DA en az iki farklı üç haneli sayının birlikte tekrarı
    $tekrarBuyuk=@($tekrar | Where-Object { $_ -match '\.' -or $_.Length -ge 4 }); $tekrarKucuk=@($tekrar | Where-Object { $_ -notmatch '\.' -and $_.Length -le 3 })
    if($tekrarBuyuk.Count -or $tekrarKucuk.Count -ge 2){ $dusenG+="örnek sorunun rakamını tekrarlıyor ($($tekrar -join ', '))" }
    # 07.09 fmuh-zor3 dersi: örnek sorunun rakamlarını BİNDE BİRE ölçekleyip aynen kullandı (800.000→800 lira … "100 lira eksik" = cevap 100.000).
    # Ölçekli kopya da sızıntıdır: sorudaki tutarların baş hane grubu (800.000→800) örnekte ≥3 kez sayı olarak geçiyorsa kapı düşer.
    $cekirdek=@($soruTutar | ForEach-Object { ($_ -replace '\.\d{3}','') } | Where-Object { $_ -match '^\d{2,3}$' } | Select-Object -Unique); $olcekli=@($cekirdek | Where-Object { $c=$_; "$($gN.ornek)" -match ('(?<![\d.,])'+[regex]::Escape($c)+'(?![\d.,])') })
    if($olcekli.Count -ge 3){ $dusenG+="örnek sorunun rakamlarını ölçekleyerek kopyalıyor ($($olcekli -join ', ')) — cevabı sızdırır; tamamen farklı rakamlar seç" }
    # 07.09 denetim-zor2 dersi: panel örneği ASCII yazımla geldi ("arkadasin", "kagidi", "supheleniyorsan") → Türkçe harf kapısı (sık kelimelerin ASCII biçimi ≥2)
    $asciiK=@([regex]::Matches(("$($gN.nedir) $($gN.panel_ornek) $($gN.harita) $($gN.desen)").ToLowerInvariant(),'\b(degil|icin|cunku|sirket|deger|kagit|kagid|arkadas|ogrenci|dusuk|buyuk|kucuk|yuksek|calis|olcul|satis|sinav|dedig|suphe|tasi|kullanim|isletme|musteri|olcum|uretim|butun|bugun)\w*') | ForEach-Object { $_.Value } | Select-Object -Unique)
    if($asciiK.Count -ge 2){ $dusenG+="Türkçe harfler eksik ($($asciiK -join ', ')) — ş, ç, ğ, ı, ö, ü tam yazılır" }
    # 06.09 Cem (eksiler #4): "Sınavda nasıl sorulur" ne VERİLİR ne İSTENİR der; işlem adı/formül (çıkarılarak, toplanarak, düşülerek, eksi, formül…) cevabın yolunu ele verir → yasak
    if("$($gN.sinavda)" -match '(?i)(çıkarıl|çıkararak|toplanarak|toplanır|düşül|bölerek|bölünerek|çarparak|çarpılarak|formül|\beksi\b|\bartı\b|=|hesaplanarak)'){ $dusenG+="'nasıl sorulur' satırında işlem adı var (yasak: yalnız ne verilir, ne istenir)" }
    if(-not $dusenG.Count){ break }
    if($tur -eq 1){ Write-Host "  GİRİŞ KAPI ($id): $($dusenG -join '; ') -> tekrar" -ForegroundColor Yellow; $istG+="`n`nKAPI DÜŞTÜ: $($dusenG -join '; '). Panelde kısaltmasız ve madde numarasız, toplam 220 kelime altında, iki katmanda aynı cümle olmadan yeniden yaz. Yalnız JSON." }
    else { $rapor.Add("GIRIS KAPI: $id | $($dusenG -join '; ')"); Write-Host "  GİRİŞ KAPI ($id, tur 2): $($dusenG -join '; ')" -ForegroundColor Yellow
      # 07.09: sızıntı (sorunun rakamı / ölçekli kopyası) 2. turda da varsa giriş KAYDEDİLMEZ — cevabı sızdıran örnek ekrana çıkmaz
      if(@($dusenG | Where-Object { $_ -match 'rakam' }).Count){ Write-Host "  GİRİŞ REDDEDİLDİ ($id): örnek cevabı sızdırıyor" -ForegroundColor Red; $gN=$null } }
  }
  Write-Host ("  GİRİŞ TOKEN {0}: girdi {1} · cikti {2} · model claude-sonnet-5" -f $id,$tokG,$tokC) -ForegroundColor DarkGray
  if(-not $gN){ $rapor.Add("GIRIS BOZUK: $id"); continue }
  $terimL=@(); foreach($tr in @($gN.terimler)){ if($tr -and $tr.ad){ $terimL+=[pscustomobject]@{ ad=(DilOnar "$($tr.ad)"); tanim=(DilOnar "$($tr.tanim)"); kim=$(if($tr.PSObject.Properties['kim']){ DilOnar "$($tr.kim)" } else { '' }); kaynak=$(if($tr.PSObject.Properties['kaynak']){ DilOnar "$($tr.kaynak)" } else { '' }) } } }
  $cvp | Add-Member -NotePropertyName konu_giris -NotePropertyValue ([pscustomobject]@{ nedir=(DilOnar "$($gN.nedir)"); sinavda=(DilOnar "$($gN.sinavda)"); yontemler=(DilOnar "$($gN.yontemler)"); ornek=(DilOnar "$($gN.ornek)"); panel_ornek=(DilOnar "$($gN.panel_ornek)"); harita=(DilOnar "$($gN.harita)"); terimler=$terimL; desen=(DilOnar "$($gN.desen)"); model='claude-sonnet-5'; tarih=(Get-Date -Format 'yyyy-MM-dd') }) -Force
  CacheYaz; Write-Host "  GİRİŞ OK $id"
}
if($script:ON_GECIS){ TopluGonder 'G' } }
$script:ON_GECIS=$false

# --- FAZ C: IKIZ (konu basina 1 = her soru; kod denetimli) -------------------
$script:FAZ_ADI='C'
$ikizIstem=@'
Aşağıdaki ÇÖZÜLMÜŞ sorunun İKİZİNİ üret: AYNI yöntem, FARKLI rakamlar/adlar, tercihen FARKLI hedef kalem sorulur (ana soru Q'yu soruyorsa ikiz R'yi sorsun: aynı yöntem, başka istek — sınav böyle yapar). Öğrenci tabloyu KENDİSİ dolduracak.
KURALLAR:
1. ikiz_soru: yeni kısa soru metni (rakamlar YENİ), Türkçe harfler tam. hedef_cumle: "tabloyu doldur ve X'in ... olduğunu bul" tarzı tek cümle.
2. tablo: ana soruyla AYNI kolon yapısı; TÜM hücre değerleri YENİ rakamlarla DOLU (doğru cevaplar - kontrol için).
3. verilen: [[satır,kolon],...] = YALNIZ ikiz_soru METNİNDE AÇIKÇA verilen değerlerin koordinatları. Hesaplanan bir hücrenin
   değeri metindeki bir rakamla TESADÜFEN aynıysa o hücre verilen DEĞİLDİR (05.09: B'nin eşdeğer miktarı 3.000, A'nın fiili
   miktarı 3.000'e çakışıp dolu gelmişti). Tesadüfü önlemek için rakamları birbirinden farklı seç.
4. bosluk: [[satır,kolon],...] = öğrencinin dolduracağı TÜM kalan hücreler (kalem kolonu hariç). verilen+bosluk = kalem-dışı TÜM hücreler; SIZINTI YASAK (verilende olmayan hiçbir değer metinde geçmez).
5. Rakamlar aritmetik TUTARLI.
6. ADLAR HARF DEĞİL (kural 4c, 05.09): ürün / gider yeri / kalem adları A, B, C gibi tek harf OLMAZ — şık harfleriyle karışır.
   Ana sorudaki adlandırma biçimini koru (P/Q/R gibi çift olmayan harfler ya da "Ürün Kuzey", "Bakım-Onarım", "Yemekhane" gibi adlar).
7. YIL (07.09 Cem): ikizde yıl geçiyorsa sorulan dönem {YIL} yılıdır (bugün {YIL}); eski tarihler aynı aralıkla, süreler değişmez.
Cevap YALNIZ JSON: {"ikiz_soru":"...","hedef_cumle":"...","tablo":{"basliklar":[...],"satirlar":[[...]]},"verilen":[[r,c],...],"bosluk":[[r,c],...]}
=== ANA SORU === {SORU}
=== ANA TABLO === {TABLO}
'@
foreach($gecisC in @(1,2)){ if($gecisC -eq 1 -and -not $Toplu){ continue }; $script:ON_GECIS=($gecisC -eq 1)
foreach($id in @($don.Keys)){
  if($SadeceHtml -or ($SadeceAdim -and $script:FAZ_ADI -ne 'B')){ break }   # yalniz cizim / yalniz adim: diger model fazlari atlanir
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]
  if(-not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar){ continue }
  if($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz){ continue }
  $ist3=$ikizIstem.Replace('{YIL}',"$((Get-Date).Year)").Replace('{SORU}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress))
  if($script:ON_GECIS){ TopluTopla $id 'claude-sonnet-5' $ist3 9000; continue }
  $y3=TopluAl 'C' $id
  if(-not $y3){ foreach($d in 1..3){ try{ $y3=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist3 -MaxTok 9000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } } }
  $a3=Coz $y3.metin
  # 07.09 KAPI-Y (ikiz): model eski yıl yazdıysa BÜTÜN yıllar aynı farkla kaydırılır (süreler korunur; metin + hedef cümle + kalem adları + başlıklar). Yeniden çağrı yok, sıfır bedel.
  # Yıl eki uyumu: 2023'te, 2026'da (kaydırma sonrası ek bozulmasın). DİKKAT: bu satıra satır içi yorum yazma, satırın kalanını yutar (07.09'da yuttu).
  if($a3 -and $a3.ikiz_soru){ $yilBu=(Get-Date).Year; $yI=@([regex]::Matches("$($a3.ikiz_soru)",'\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))') | ForEach-Object { [int]$_.Groups[1].Value }); if($yI.Count){ $enYeni=($yI | Measure-Object -Maximum).Maximum; $fark=$yilBu-$enYeni; if($fark -gt 0){ $kaydir={ param($t) $t2=[regex]::Replace("$t",'\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))',{ param($m) "$([int]$m.Groups[1].Value + $fark)" }); [regex]::Replace($t2,"\b(20[0-3](\d))'([dt])([ea])(n?)\b",{ param($m) $son=[int]$m.Groups[2].Value; $ekT=@{0='de';1='de';2='de';3='te';4='te';5='te';6='da';7='de';8='de';9='da'}; $ek=$ekT[$son]; "$($m.Groups[1].Value)'$ek$($m.Groups[5].Value)" }) }; $a3.ikiz_soru=& $kaydir $a3.ikiz_soru; if($a3.PSObject.Properties['hedef_cumle']){ $a3.hedef_cumle=& $kaydir $a3.hedef_cumle }; if($a3.tablo){ if($a3.tablo.basliklar){ $a3.tablo.basliklar=@($a3.tablo.basliklar | ForEach-Object { & $kaydir $_ }) }; if($a3.tablo.satirlar){ foreach($st in $a3.tablo.satirlar){ if($st -and $st.Count){ $st[0]=& $kaydir $st[0] } } } }; Write-Host "  KAPI-Y (ikiz) ${id}: yıllar +$fark kaydırıldı (en yeni $enYeni -> $yilBu)" -ForegroundColor DarkGray } } }
  $gecerli=$false
  if($a3 -and $a3.tablo -and $a3.tablo.satirlar){
    # KOD DENETIMI (fark.html dersi): verilen ∪ bosluk = kalem-disi tum hucreler
    $kume=@{}
    foreach($v in @($a3.verilen)){ $kume["$(@($v)[0]),$(@($v)[1])"]='v' }
    foreach($v in @($a3.bosluk)){ $kume["$(@($v)[0]),$(@($v)[1])"]='b' }
    $gecerli=$true
    $ns=@($a3.tablo.satirlar).Count
    # 05.09 (kalıp-2 pilotu, iki kez RED): model bazı hücreleri hiç listelemiyor. Listelenmeyen hücre GÜVENLİ tarafa alınır
    # (bosluk = öğrenci doldurur); sızıntı denetimini builder zaten yapıyor (verilen ∩ metin). Ret yalnız satır/sütun dışı koordinat için.
    $eksikH=New-Object System.Collections.Generic.List[object]
    for($r=0;$r -lt $ns;$r++){
      $kc=@(@($a3.tablo.satirlar)[$r]).Count
      for($c=1;$c -lt $kc;$c++){
        $hv="$(@(@($a3.tablo.satirlar)[$r])[$c])"
        if($hv -eq '-' -or $hv -eq ''){ continue }
        if(-not $kume.ContainsKey("$r,$c")){ $eksikH.Add(@($r,$c)) }
      }
    }
    # 06.09 (kalıp-4 pilotu): model sütunları 1'den saymış ([1,2] iki sütunlu tabloda) → tüm koordinatların sütunu tablo genişliğine
    # eşit ya da aşkınsa ve hiçbiri 0 değilse 1 tabanlı sayılır, bir azaltılır; satırlar aynı şekilde sınanır.
    $tumK=@(@($a3.verilen)+@($a3.bosluk)); $genis=@(@($a3.tablo.satirlar)[0]).Count
    if($tumK.Count -and (@($tumK | Where-Object { [int]@($_)[1] -ge $genis }).Count -gt 0) -and (@($tumK | Where-Object { [int]@($_)[1] -le 0 }).Count -eq 0)){
      $a3.verilen=@(@($a3.verilen) | ForEach-Object { ,@([int]@($_)[0],([int]@($_)[1]-1)) }); $a3.bosluk=@(@($a3.bosluk) | ForEach-Object { ,@([int]@($_)[0],([int]@($_)[1]-1)) })
      $kume=@{}; foreach($v in @($a3.verilen)){ $kume["$(@($v)[0]),$(@($v)[1])"]='v' }; foreach($v in @($a3.bosluk)){ $kume["$(@($v)[0]),$(@($v)[1])"]='b' }
      $eksikH=New-Object System.Collections.Generic.List[object]; for($r=0;$r -lt $ns;$r++){ $kc=@(@($a3.tablo.satirlar)[$r]).Count; for($c=1;$c -lt $kc;$c++){ $hv="$(@(@($a3.tablo.satirlar)[$r])[$c])"; if($hv -eq '-' -or $hv -eq ''){ continue }; if(-not $kume.ContainsKey("$r,$c")){ $eksikH.Add(@($r,$c)) } } }
      Write-Host "  IKIZ: koordinatlar 1 tabanlıydı, sütunlar bir azaltıldı ($id)" -ForegroundColor DarkGray }
    # satırlar da 1 tabanlı olabilir ([13,1] 13 satırlı tabloda): satır 0 hiç yoksa ve satır sayısına eşit satır varsa bir azalt
    $tumK=@(@($a3.verilen)+@($a3.bosluk))
    if($tumK.Count -and (@($tumK | Where-Object { [int]@($_)[0] -ge $ns }).Count -gt 0) -and (@($tumK | Where-Object { [int]@($_)[0] -le 0 }).Count -eq 0)){
      $a3.verilen=@(@($a3.verilen) | ForEach-Object { ,@(([int]@($_)[0]-1),[int]@($_)[1]) }); $a3.bosluk=@(@($a3.bosluk) | ForEach-Object { ,@(([int]@($_)[0]-1),[int]@($_)[1]) })
      Write-Host "  IKIZ: satırlar 1 tabanlıydı, bir azaltıldı ($id)" -ForegroundColor DarkGray }
    # tablo dışı kalan koordinat RED sebebi değil: atılır (verilen'den atılan hücre boşluğa düşer = güvenli taraf)
    $ic={ param($v) $rr=[int]@($v)[0]; $cc=[int]@($v)[1]; ($rr -ge 0 -and $rr -lt $ns -and $cc -ge 1 -and $cc -lt @(@($a3.tablo.satirlar)[$rr]).Count) }
    $dis=@($tumK | Where-Object { -not (& $ic $_) }).Count; if($dis){ Write-Host "  IKIZ: $dis tablo dışı koordinat atıldı ($id)" -ForegroundColor DarkGray }
    $a3.verilen=@(@($a3.verilen) | Where-Object { & $ic $_ }); $a3.bosluk=@(@($a3.bosluk) | Where-Object { & $ic $_ })
    $kume=@{}; foreach($v in @($a3.verilen)){ $kume["$(@($v)[0]),$(@($v)[1])"]='v' }; foreach($v in @($a3.bosluk)){ $kume["$(@($v)[0]),$(@($v)[1])"]='b' }
    $eksikH=New-Object System.Collections.Generic.List[object]; for($r=0;$r -lt $ns;$r++){ $kc=@(@($a3.tablo.satirlar)[$r]).Count; for($c=1;$c -lt $kc;$c++){ $hv="$(@(@($a3.tablo.satirlar)[$r])[$c])"; if($hv -eq '-' -or $hv -eq ''){ continue }; if(-not $kume.ContainsKey("$r,$c")){ $eksikH.Add(@($r,$c)) } } }
    if($eksikH.Count){ $a3.bosluk=@(@($a3.bosluk)+$eksikH.ToArray()); Write-Host "  IKIZ: $($eksikH.Count) listelenmeyen hücre boşluğa alındı ($id)" -ForegroundColor DarkGray }
    if(-not @($a3.bosluk).Count){ $gecerli=$false; Write-Host "  IKIZ RED sebebi: doldurulacak boşluk kalmadı ($id)" -ForegroundColor Yellow }
  } else { Write-Host "  IKIZ RED sebebi: JSON çözülemedi ya da tablo yok ($id)" -ForegroundColor Yellow }
  if($gecerli){
    $cvp | Add-Member -NotePropertyName ikiz -NotePropertyValue $a3 -Force
    CacheYaz; Write-Host "  IKIZ OK $id"
  } else { $rapor.Add("IKIZ REDDEDILDI (kapsama denetimi): $id"); Write-Host "  IKIZ RED: $id" -ForegroundColor Yellow }
}
if($script:ON_GECIS){ TopluGonder 'C' } }
$script:ON_GECIS=$false

# 07.09 Ö52: FAZ Ö (simülasyon) İKİZ'den önce koşuyordu → hesap sorusunda 'ikiz yok' diye atlanıyordu (maliyet-zor1). FAZ C öne alındı.
# --- FAZ Ö: ÖĞRENCİ SİMÜLASYONU (06.09 Cem "geç"; 05.09'dan beri önerilen "öğretiyor muyuz" ölçüsü) -------------------------
# Haiku, hiç bilmeyen stajyer rolünde YALNIZ Nöbetçi adımlarını okur ve ikiz soruyu çözer. Cevap ikiz tablosunun sonuç hücresiyle
# karşılaştırılır (±%1). Sonuç cache'e `simulasyon` olarak yazılır; parti raporunda SIM doğru/yanlış sayılır. ≈0,01 USD/soru.
$script:FAZ_ADI='O'
$simIstem=@'
Sen bu konuyu HİÇ bilmeyen bir staja giriş sınavı adayısın. Ezber bilgin yok, kaynak yok. Sana yalnız aşağıdaki ÇÖZÜM ANLATIMI verildi (bir örnek sorunun adım adım çözümü). Bu anlatımı okuyup, aynı yöntemle YENİ SORUYU çöz.
Kurallar: yalnız anlatımın öğrettiği kadarıyla çöz; anlatım yetmiyorsa cevap "yetmedi" olsun ve neyin eksik/anlaşılmaz olduğunu yaz. Hesabını kısa adımlarla yaz. Sonunda TEK sayı ver (birimsiz, Türkçe biçim: 85.200).
Yalnız JSON: {"cevap":"<sayı ya da yetmedi>","adimlar":"kısa hesap","eksik":"anlatımda eksik ya da karışık olan şey; yoksa boş"}
=== ÇÖZÜM ANLATIMI (örnek soru ve Nöbetçi adımları) ===
ÖRNEK SORU: {SORU}
ADIMLAR:
{ADIMLAR}
=== YENİ SORU (bunu çöz) ===
{IKIZ}
'@
foreach($id in @($don.Keys)){
  if($SadeceHtml -or -not $Simulasyon){ break }
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]; if(-not $cvp.soru -or -not $cvp.PSObject.Properties['adimlar'] -or -not $cvp.adimlar){ continue }
  $simAlanT=$(if($SimModel -match 'sonnet'){ 'simulasyon_sonnet' } else { 'simulasyon' })
  if(-not ($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz -and $cvp.ikiz.ikiz_soru -and $cvp.ikiz.tablo -and $cvp.ikiz.tablo.satirlar)){
    # 06.09 Ö24 (Cem "bu beşi geç" #3): TEORİ SİMÜLASYONU. Tablosuz/kayıtsız (teori) soruda ikiz yok; "aynı kuralın başka olayı" 5 şıklı
    # TEORİ İKİZİ üretilir (Sonnet, cache `teori_ikiz`), sonra öğrenci-modeli YALNIZ adımları okuyup ikizin şıkkını seçer. ≈0,03 USD/soru.
    $teoriMi=(-not ($cvp.cozum_tablo -and $cvp.cozum_tablo.satirlar)) -and (-not ($cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye'))
    if(-not $teoriMi){ Write-Host "  SIM ATLANDI ($id): ikiz yok" -ForegroundColor DarkGray; continue }
    if(-not $SimYenile -and $cvp.PSObject.Properties[$simAlanT] -and $cvp.$simAlanT -and "$($cvp.$simAlanT.tur)" -eq 'teori'){ continue }
    if(-not ($cvp.PSObject.Properties['teori_ikiz'] -and $cvp.teori_ikiz -and $cvp.teori_ikiz.soru)){
      $istTI=@"
Aşağıdaki TEORİ sorusunun İKİZİNİ üret: AYNI kural/hüküm, FARKLI olay (başka işletme, başka durum, başka kişi), 5 şık (A-E), tek doğru.
Kurallar: kaynaktaki hükmü değiştirme; olay sınav dilinde ve kısa; şıklar cümle, doğru şık en uzun OLMASIN; Türkçe harfler tam; kısaltma yok.
Yalnız JSON: {"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A-E","gerekce":"tek cümle"}
=== ANA SORU ===
$($cvp.soru)
A) $($cvp.siklar.A)
B) $($cvp.siklar.B)
C) $($cvp.siklar.C)
D) $($cvp.siklar.D)
E) $($cvp.siklar.E)
DOĞRU: $($cvp.dogru)
=== DAYANAK (kaynak özeti) ===
$("$($cvp.kaynak_metin_ozet)".Substring(0,[Math]::Min(2500,"$($cvp.kaynak_metin_ozet)".Length)))
"@
      $yT=$null; foreach($d in 1..3){ try{ $yT=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istTI -MaxTok 4000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
      Write-Host ("  TEORİ İKİZ TOKEN {0}: girdi {1} · cikti {2} · model claude-sonnet-5" -f $id,$yT.girdi,$yT.cikti) -ForegroundColor DarkGray
      $tI=Coz $yT.metin
      if(-not ($tI -and $tI.soru -and $tI.siklar -and $tI.dogru)){ $rapor.Add("TEORI IKIZ BOZUK: $id"); Write-Host "  TEORİ İKİZ BOZUK ($id)" -ForegroundColor Red; continue }
      $cvp | Add-Member -NotePropertyName teori_ikiz -NotePropertyValue ([pscustomobject]@{ soru=(DilOnar "$($tI.soru)"); siklar=$tI.siklar; dogru="$($tI.dogru)".Trim().ToUpperInvariant(); gerekce="$($tI.gerekce)"; model='claude-sonnet-5'; tarih=(Get-Date -Format 'yyyy-MM-dd') }) -Force
      CacheYaz
    }
    $ti=$cvp.teori_ikiz
    # 06.09 Cem "2 yap" — SIZDIRMAZ ölçüm: ilk koşu 8/8 doğruydu ama öğrenci örnek sorunun "Doğru şık" adımını ve doğru şık metnini görüyordu.
    # Şimdi: "Doğru şık" başlıklı adım atılır, doğru şıkkın metni anlatımlardan silinir, örnek sorunun şıkları verilmez. Yalnız KURAL öğretir.
    $dogruMetin="$($cvp.siklar.$($cvp.dogru))".Trim()
    $adimSiz=@($cvp.adimlar | Where-Object { $_ -and "$($_.formul)" -notmatch '^(Doğru şık|Dogru sik|Doğru cevap|Cevap)' })
    $adimMetinT=($adimSiz | ForEach-Object -Begin { $q=0 } -Process { $q++; $f="$($_.formul)"; $an="$($_.anlatim)"; if($dogruMetin.Length -ge 12){ $f=$f.Replace($dogruMetin,'[…]'); $an=$an.Replace($dogruMetin,'[…]') }; $an=$an -replace ('(?i)doğru (şık|cevap)\s*:?\s*'+[regex]::Escape("$($cvp.dogru)")+'\)?'),'doğru şık: […]'; "$q) $f`n   $an" }) -join "`n"
    if(@($cvp.adimlar).Count -ne $adimSiz.Count){ Write-Host "  SIM SIZDIRMAZ ($id): $(@($cvp.adimlar).Count - $adimSiz.Count) 'Doğru şık' adımı gizlendi" -ForegroundColor DarkGray }
    $istOT=@"
Sen bu konuyu HİÇ bilmeyen bir staja giriş sınavı adayısın. Ezber bilgin yok, kaynak yok. Sana yalnız aşağıdaki ÇÖZÜM ANLATIMI verildi (bir örnek sorunun adım adım açıklaması). Bu anlatımdaki KURALI öğrenip YENİ SORUDA doğru şıkkı seç.
Kurallar: yalnız anlatımın öğrettiği kadarıyla karar ver; anlatım yetmiyorsa cevap "yetmedi" olsun ve neyin eksik olduğunu yaz.
Yalnız JSON: {"cevap":"A-E ya da yetmedi","neden":"tek cümle","eksik":"anlatımda eksik ya da karışık olan şey; yoksa boş"}
=== ÇÖZÜM ANLATIMI (örnek soru ve Nöbetçi adımları) ===
ÖRNEK SORU: $($cvp.soru)
ADIMLAR:
$adimMetinT
=== YENİ SORU (bunu çöz) ===
$($ti.soru)
A) $($ti.siklar.A)
B) $($ti.siklar.B)
C) $($ti.siklar.C)
D) $($ti.siklar.D)
E) $($ti.siklar.E)
"@
    $yOT=$null; foreach($d in 1..3){ try{ $yOT=Invoke-ClaudeMesaj -Model $SimModel -Icerik $istOT -MaxTok 800; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
    Write-Host ("  SIM TOKEN {0}: girdi {1} · cikti {2} · model {3} (teori)" -f $id,$yOT.girdi,$yOT.cikti,$SimModel) -ForegroundColor DarkGray
    $oT=Coz $yOT.metin
    if(-not $oT -or -not $oT.PSObject.Properties['cevap']){ $mC=[regex]::Match("$($yOT.metin)",'"cevap"\s*:\s*"([^"]*)"'); if($mC.Success){ $oT=[pscustomobject]@{ cevap=$mC.Groups[1].Value; neden=''; eksik='' } } }
    if(-not $oT){ $rapor.Add("SIM BOZUK: $id"); continue }
    $cevT="$($oT.cevap)".Trim().ToUpperInvariant(); $dogruT=($cevT -eq "$($ti.dogru)")
    $cvp | Add-Member -NotePropertyName $simAlanT -NotePropertyValue ([pscustomobject]@{ tur='teori'; cevap=$cevT; hedef="$($ti.dogru)"; dogru_mu=$dogruT; eksik="$($oT.eksik)"; adimlar="$($oT.neden)"; model=$SimModel; tarih=(Get-Date -Format 'yyyy-MM-dd') }) -Force
    CacheYaz; Write-Host ("  SIM {0} ({1}, teori): cevap {2} · hedef {3}{4}" -f $(if($dogruT){'DOĞRU'}else{'YANLIŞ'}),$id,$cevT,$ti.dogru,$(if("$($oT.eksik)".Trim()){ " · eksik: $($oT.eksik)" } else { '' })) -ForegroundColor $(if($dogruT){'Green'}else{'Red'})
    if(-not $dogruT){ $rapor.Add("SIM YANLIŞ (teori): $id | cevap $cevT hedef $($ti.dogru) | $($oT.eksik)") }
    continue
  }
  # hedef: ikizin SORDUĞU satır (06.09 fmuh-k10c dersi: ikiz "net defter değeri" sordu, öğrenci 337.500 dedi, karşılaştırıcı son satırdaki
  # kâr/zararı (-137.500) hedef alıp YANLIŞ saydı). Soru kökündeki istenen ifade ile satır etiketleri kök-önekiyle eşlenir; eşleşme yoksa son satır.
  $satirlarI=@($cvp.ikiz.tablo.satirlar); $hedefSat=$null
  $kokM=[regex]::Match("$($cvp.ikiz.ikiz_soru)",'([^.?!]{6,}?)\s*(kaç|ne kadardır|hangisidir|nedir)[^.?!]*\?\s*$')
  if($kokM.Success){
    # 06.09 maliyet-k10d dersi: cümlenin tamamı ("ortak maliyetin ... dağıtımı sonucunda R ürününün kg başına maliyeti") 'Ortak Maliyet Payı' satırını seçti,
    # oysa istenen SON öbek ("kg başına maliyeti" → Birim Maliyet). İstenen = "kaç"tan önceki son 5 kelime.
    $sonObek=(@(($kokM.Groups[1].Value -split '\s+') | Where-Object { $_ }) | Select-Object -Last 5) -join ' '
    $istenenK=@(((Katla2 $sonObek) -replace '[^a-z ]+',' ') -split '\s+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(gore|olan|tarih|sonu|basi|donem|yili|urun|urunu|urununun)$' } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } } | Select-Object -Unique)
    if($istenenK -contains 'basin'){ $istenenK=@($istenenK)+@('birim') }   # "kg başına" = birim
    # eşitlikte SONRAKİ satır kazanır (sonuç satırları tabloda alttadır)
    # 09.09 GM pilotu kp-06 ÖLÇÜLDÜ: ikiz "stok devir hızı" sordu, öğrenci 8 dedi (doğru); satır etiketi "Stokta kalma süresi (360 / stok devir hızı)"
    # parantezdeki formül yüzünden 3 kök eşleyip hedef seçildi, sim YANLIŞ sayıldı. Eşleme önce PARANTEZSİZ etiketle yapılır; hiç eşleşme yoksa tam etiketle.
    # 09.09 GM maliyet ÖLÇÜLDÜ (4 sahte YANLIŞ): (a) "Kontrol:/Sağlama:" satırı tabloda SON satır olunca kök eşleşmesi yokken varsayılan hedef oldu (kp-11:
    # öğrenci 795.000 doğru, hedef 5.000 kontrol satırı); (b) "stoku" ile "stok" 5 harflik kökte eşleşmedi (kp-20). Kontrol/sağlama satırları hedef adayı
    # DEĞİLDİR; kök eşleşmesi önek toleranslı (biri ötekinin başıysa eş). Ayrıca aşağıda: öğrenci cevabı başka bir sonuç satırına eşitse DOĞRU sayılır.
    $adaySat=@($satirlarI | Where-Object { "$(@($_)[0])" -notmatch '^\s*(Kontrol|Sağlama|Saglama)\b' }); if(-not $adaySat.Count){ $adaySat=@($satirlarI) }
    $kokEs={ param($a,$b) if($a -eq $b){ return $true }; if("$a".Length -ge 4 -and "$b".Length -ge 4){ return ("$a".StartsWith("$b") -or "$b".StartsWith("$a")) }; return $false }
    $enP=0; foreach($st in $adaySat){ $etAd=("$(@($st)[0])" -replace '\([^)]*\)',' '); $etK=@(((Katla2 $etAd) -replace '[^a-z ]+',' ') -split '\s+' | Where-Object { $_ } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } }); $p=@($istenenK | Where-Object { $ik=$_; @($etK | Where-Object { & $kokEs $ik $_ }).Count -gt 0 }).Count; if($p -gt 0 -and $p -ge $enP){ $enP=$p; $hedefSat=$st } }
    if($enP -eq 0){ foreach($st in $adaySat){ $etK=@(((Katla2 "$(@($st)[0])") -replace '[^a-z ]+',' ') -split '\s+' | Where-Object { $_ } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } }); $p=@($istenenK | Where-Object { $ik=$_; @($etK | Where-Object { & $kokEs $ik $_ }).Count -gt 0 }).Count; if($p -gt 0 -and $p -ge $enP){ $enP=$p; $hedefSat=$st } } }
    if($hedefSat -and $enP -ge 1){ Write-Host "  SIM HEDEF ($id): '$(@($hedefSat)[0])' satırı (soru kökü eşleşmesi $enP)" -ForegroundColor DarkGray } else { $hedefSat=$null }
  }
  $adaySat=@($satirlarI | Where-Object { "$(@($_)[0])" -notmatch '^\s*(Kontrol|Sağlama|Saglama)\b' }); if(-not $adaySat.Count){ $adaySat=@($satirlarI) }
  $sonSat=@($(if($hedefSat){ $hedefSat } else { $adaySat[-1] })); $hedefS=''; for($c=$sonSat.Count-1;$c -ge 1;$c--){ if("$($sonSat[$c])" -match '\d'){ $hedefS="$($sonSat[$c])"; break } }
  if(-not $hedefS){ Write-Host "  SIM ATLANDI ($id): ikiz sonuç hücresi yok" -ForegroundColor DarkGray; continue }
  $adimMetin=(@($cvp.adimlar) | ForEach-Object -Begin { $q=0 } -Process { $q++; "$q) $($_.formul)`n   $($_.anlatim)" }) -join "`n"
  $istO=$simIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{ADIMLAR}',$adimMetin).Replace('{IKIZ}',"$($cvp.ikiz.ikiz_soru)")
  $simAlan=$(if($SimModel -match 'sonnet'){ 'simulasyon_sonnet' } else { 'simulasyon' })
  if(-not $SimYenile -and $cvp.PSObject.Properties[$simAlan] -and $cvp.$simAlan -and $cvp.$simAlan.hedef){ continue }   # aynı modelle bir kez (-SimYenile ile tekrar)
  $yO=$null; foreach($d in 1..3){ try{ $yO=Invoke-ClaudeMesaj -Model $SimModel -Icerik $istO -MaxTok 1500; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  Write-Host ("  SIM TOKEN {0}: girdi {1} · cikti {2} · model {3}" -f $id,$yO.girdi,$yO.cikti,$SimModel) -ForegroundColor DarkGray
  $oN=Coz $yO.metin
  # Haiku bazen JSON'u bozuyor (adımlar alanında tırnak/satır); cevap ve eksik alanları regex ile kurtarılır
  if(-not $oN -or -not $oN.PSObject.Properties['cevap']){ $mC=[regex]::Match("$($yO.metin)",'"cevap"\s*:\s*"([^"]*)"'); $mE=[regex]::Match("$($yO.metin)",'"eksik"\s*:\s*"([^"]*)"'); if($mC.Success){ $oN=[pscustomobject]@{ cevap=$mC.Groups[1].Value; adimlar=''; eksik=$(if($mE.Success){ $mE.Groups[1].Value } else { '' }) }; Write-Host "  SIM JSON bozuktu, regex ile kurtarıldı ($id)" -ForegroundColor DarkYellow } }
  if(-not $oN){ $rapor.Add("SIM BOZUK: $id"); Write-Host "  SIM BOZUK ($id): $("$($yO.metin)".Substring(0,[Math]::Min(160,"$($yO.metin)".Length)))" -ForegroundColor Red; continue }
  $trO=[cultureinfo]::GetCultureInfo('tr-TR'); $sayi={ param($t) $m=[regex]::Match("$t",'-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?'); if($m.Success){ try{ [double]::Parse($m.Value,$trO) }catch{ $null } } else { $null } }
  $cv=& $sayi $oN.cevap; $hd=& $sayi $hedefS
  # 06.09 Ö35: hedef yön kelimesiyle geliyorsa ("%37,5 azalış", "12.000 olumsuz") işaret karşılaştırmaya girmez — MTA kp-02'de "-37,5" doğruyken yanlış sayılmıştı
  $yonluHedef=("$hedefS" -match '(?i)azalış|azalis|olumsuz|olumlu|artış|artis|düşüş|dusus|lehte|aleyhte|\(-\)')
  $dogruMu=$false; if($null -ne $cv -and $null -ne $hd){ $cvK=$(if($yonluHedef){ [math]::Abs($cv) } else { $cv }); $hdK=$(if($yonluHedef){ [math]::Abs($hd) } else { $hd }); $dogruMu=([math]::Abs($cvK-$hdK) -le [math]::Max(0.5,[math]::Abs($hdK)*0.01)) }
  # 09.09: hedef satır seçimi yanılabilir (ikiz başka kalemi sormuş olabilir). Öğrencinin cevabı tablonun kontrol dışı BAŞKA bir sonuç hücresine eşitse
  # doğru sayılır (kp-09: öğrenci 150.000 = "Premium kalite toplam payı" satırı; hedef yanlışlıkla birim eşdeğer maliyet 50 seçilmişti).
  # Sıkı kural (09.09 ikinci ölçüm, 39 aday kaydın bir kısmı ARA satıra denk geliyordu — kalite): kurtarma yalnız (1) ikiz kökünden istenen bilinirken,
  # (2) satır etiketi istenenle en az bir kök paylaşıyorsa; küçük sayılarda tolerans 0,02 (1,25 ile -1/2 eşleşmesin).
  if(-not $dogruMu -and $null -ne $cv -and $kokM.Success -and $istenenK -and $istenenK.Count){
    foreach($st in $adaySat){ $etK2=@(((Katla2 ("$(@($st)[0])" -replace '\([^)]*\)',' ')) -replace '[^a-z ]+',' ') -split '\s+' | Where-Object { $_ } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } }); $ort=@($istenenK | Where-Object { $ik=$_; @($etK2 | Where-Object { & $kokEs $ik $_ }).Count -gt 0 }).Count; if($ort -lt 1){ continue }
      $hv=$null; $hc=-1; for($c2=@($st).Count-1;$c2 -ge 1;$c2--){ if("$(@($st)[$c2])" -match '\d'){ $hv=& $sayi "$(@($st)[$c2])"; $hc=$c2; break } }
      if($null -eq $hv){ continue }; $tol=$(if([math]::Abs($hv) -ge 100){ [math]::Max(0.5,[math]::Abs($hv)*0.01) } else { [math]::Max(0.02,[math]::Abs($hv)*0.01) })
      if([math]::Abs([math]::Abs($cv)-[math]::Abs($hv)) -le $tol){ $dogruMu=$true; $hedefS="$(@($st)[$hc])"; Write-Host "  SIM HEDEF DÜZELTİLDİ ($id): öğrenci cevabı '$(@($st)[0])' satırıyla eşleşti (kök ortak $ort)" -ForegroundColor DarkYellow; $rapor.Add("SIM HEDEF DUZELTILDI: $id | $(@($st)[0])"); break } } }
  $simObj=[pscustomobject]@{ cevap="$($oN.cevap)"; hedef=$hedefS; dogru_mu=$dogruMu; eksik="$($oN.eksik)"; adimlar="$($oN.adimlar)"; model=$SimModel; tarih=(Get-Date -Format 'yyyy-MM-dd') }
  $cvp | Add-Member -NotePropertyName $simAlan -NotePropertyValue $simObj -Force
  CacheYaz; Write-Host ("  SIM {0} ({1}): cevap {2} · hedef {3}{4}" -f $(if($dogruMu){'DOĞRU'}else{'YANLIŞ'}),$id,$oN.cevap,$hedefS,$(if("$($oN.eksik)".Trim()){ " · eksik: $($oN.eksik)" } else { '' })) -ForegroundColor $(if($dogruMu){'Green'}else{'Red'})
  if(-not $dogruMu){ $rapor.Add("SIM YANLIŞ: $id | cevap $($oN.cevap) hedef $hedefS | $($oN.eksik)") }
}

# --- FAZ S: YEVMIYE TAMAMLAMA (01.09 Cem: "muhasebe kaydini gostermiyorsun,
# T-cetveli soru cozecektik") - KAYIT dersinde tablolu her soru yevmiyesiz kalamaz.
$yevmiyeIstem=@'
Asagidaki cozulmus muhasebe sorusunun YEVMIYE KAYDINI/KAYITLARINI (T-cetveli) uret. Rakamlar soru/tablodakiyle BIREBIR; hesap adlari Tekduzen Hesap Plani kod+adiyla ("121 ALACAK SENETLERI" gibi).
ZINCIR KURALI (Cem 01.09): Soruda birden fazla islem (OLAY ZINCIRI) varsa her islemin maddesi AYRI kayit olarak SIRAYLA verilir - ornek: 1) Satis kaydi: 120 ALICILAR borc / 600 YURTICI SATISLAR alacak + 391 HESAPLANAN KDV alacak, 2) Policenin kabulu: 121 ALACAK SENETLERI borc / 120 ALICILAR alacak. Ogrenci "bu kayit nereden geldi" diye gormeli. Tek islem varsa tek kayit yeterli.
BASLIK KURALI (02.09 - SIZINTI YASAGI): Kayit basligi ogrenciye kaydi KENDISI yaptirdigimiz oyunda da gorunur. Bu yuzden baslik YALNIZCA "N) <tarih varsa tarih> - <islemin adi>" olur; ornek: "2) 22.03.2026 - Policenin teslim alinmasi", "1) Malin satisi". Basliga HESAP ADI/KODU, TUTAR, ORAN, YONTEM ADI (FIFO, normal amortisman vb.), MADDE NUMARASI ve GEREKCE YAZILMAZ - bunlar cevabin kendisidir. Baslik 45 karakteri asmaz.
Cevap YALNIZ JSON: {"tur":"yevmiye","baslik":"...","kayitlar":[{"baslik":"1) ...","ogeler":{"borc":[{"hesap":"...","tutar":"..."}],"alacak":[{"hesap":"...","tutar":"..."}]}}]}
ISTISNA: Soru KAVRAMSAL ya da SALT HESAPLAMA ise (ornek: ozkaynak = aktif - borclar hesabi, TMS kavram sorusu) ve yevmiye kaydi GERCEKTEN uygulanmiyorsa UYDURMA kayit yazma - su JSON'u dondur: {"tur":"yok","sebep":"tek cumle neden"}
=== SORU === {SORU}
=== COZUM TABLOSU === {TABLO}
=== DOGRU ACIKLAMA === {ACIK}
'@
foreach($id in @($don.Keys)){
  if($SadeceHtml -or ($SadeceAdim -and $script:FAZ_ADI -ne 'B')){ break }   # yalniz cizim / yalniz adim: diger model fazlari atlanir
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]
  if(-not $cvp.soru -or -not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar){ continue }
  $cvp | Add-Member -NotePropertyName sema -NotePropertyValue (SemaNormalize $(if($cvp.PSObject.Properties['sema']){ $cvp.sema } else { $null })) -Force   # 08.09: kurtarma kaydında 'sema' özelliği olmayabilir, doğrudan atama düşüyordu
  # atlama SIKI: tur=yevmiye YETMEZ, yapisi da standart olmali (01.09: 11 soruda
  # modelin serbest 'madde/kayit' bicimi cizdiriciye BOS tablo bastirdi).
  # 01.09 zincir kurali: artik ZORUNLU bicim 'kayitlar' dizisi - eski tek-'ogeler'
  # kayitlar yeniden basilir ki olay zinciri (satis + police) tam gorunsun.
  $ky0=$null; if($cvp.sema -and $cvp.sema.PSObject.Properties['kayitlar']){ $ky0=@($cvp.sema.kayitlar) }
  if($cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye' -and $ky0 -and $ky0.Count -ge 1 -and -not @($ky0 | Where-Object { -not ($_.ogeler -and $_.ogeler.PSObject.Properties['borc'] -and @($_.ogeler.borc).Count -ge 1) }).Count){ continue }
  # gerekceli 'yevmiye uygulanmaz' karari (kp-07 ozkaynak hesabi, kp-21 TMS kavrami) - tekrar denenmez
  if($cvp.PSObject.Properties['yevmiye_yok'] -and $cvp.yevmiye_yok){ continue }
  $istY=$yevmiyeIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress)).Replace('{ACIK}',(AciklamaDuz $cvp.aciklama.$($cvp.dogru)))
  $yv=$null
  foreach($d in 1..3){ try{ $yv=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istY -MaxTok 3000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $sv2=Coz $yv.metin
  # 01.09: her tablolu soru kayit sorusu degil - model gerekcesiyle 'yok' derse
  # uydurma kayit YAZDIRILMAZ. Sozel sema (eleme/karar/akis) varsa korunur;
  # sahte tek-yevmiye varsa dusurulur (sema='yok' -> cizdirici hic basmaz).
  if($sv2 -and "$($sv2.tur)" -eq 'yok'){
    $sozel=($cvp.sema -and (@('eleme','karar','akis') -contains "$($cvp.sema.tur)") -and $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.ogeler)
    if(-not $sozel){ $cvp | Add-Member -NotePropertyName sema -NotePropertyValue ([pscustomobject]@{tur='yok'}) -Force }
    $cvp | Add-Member -NotePropertyName yevmiye_yok -NotePropertyValue "$($sv2.sebep)" -Force
    CacheYaz; Write-Host "  YEVMIYE GEREKMIYOR (gerekceli) $id"; continue
  }
  # zincir bicimi dogrulama: kayitlar[] var ve HER kayitta borc dolu; eski tek-ogeler de kabul (sarmalanir)
  if($sv2 -and -not ($sv2.PSObject.Properties['kayitlar'] -and $sv2.kayitlar) -and $sv2.ogeler -and $sv2.ogeler.borc){
    $sv2 | Add-Member -NotePropertyName kayitlar -NotePropertyValue @(,([pscustomobject]@{baslik='';ogeler=$sv2.ogeler})) -Force
  }
  if($sv2 -and $sv2.kayitlar -and @($sv2.kayitlar).Count -ge 1 -and -not @(@($sv2.kayitlar) | Where-Object { -not ($_.ogeler -and $_.ogeler.borc) }).Count){
    $cvp | Add-Member -NotePropertyName sema -NotePropertyValue $sv2 -Force
    CacheYaz; Write-Host "  YEVMIYE OK $id"
  } else { $rapor.Add("YEVMIYE BOZUK: $id") }
}

# --- FAZ S2: IKIZ YEVMIYESI (02.09 Cem "1 YAP" - GM onerisi 1: ikiz ile denk
# oyunu birlesir). Ogrenci ayni kaydi IKINCI KEZ, ikizin YENI rakamlariyla yazar;
# kas hafizasi burada olusur. Asil kaydin YAPISI korunur, tutarlar ikizden gelir.
$ikizYevIstem=@'
Asagida bir muhasebe sorusunun ASIL YEVMIYE KAYDI/KAYITLARI ve ayni yontemin IKIZ sorusu (farkli rakamlar) var.
IKIZ SORUNUN yevmiye kaydini uret: hesap yapisi asil kayitla AYNI mantikta, tutarlar IKIZ SORUNUN rakamlarindan hesaplanir (ikiz tablosuyla BIREBIR tutarli). Hesap adlari Tekduzen kod+adiyla. Zincir varsa her islem ayri numarali kayit.
Cevap YALNIZ JSON: {"tur":"yevmiye","baslik":"...","kayitlar":[{"baslik":"1) ...","ogeler":{"borc":[{"hesap":"...","tutar":"..."}],"alacak":[{"hesap":"...","tutar":"..."}]}}]}
Ikiz sorunun rakamlariyla kayit KURULAMIYORSA: {"tur":"yok","sebep":"tek cumle"}
=== ASIL KAYIT === {ASIL}
=== IKIZ SORU === {IKIZSORU}
=== IKIZ TABLO (dogru degerler) === {IKIZTABLO}
'@
foreach($id in @($don.Keys)){
  if($SadeceHtml -or ($SadeceAdim -and $script:FAZ_ADI -ne 'B')){ break }   # yalniz cizim / yalniz adim: diger model fazlari atlanir
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvp=$don[$id]
  if(-not ($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz)){ continue }
  if(-not ($cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye')){ continue }
  if($cvp.PSObject.Properties['ikiz_sema'] -and $cvp.ikiz_sema){ continue }
  if($cvp.PSObject.Properties['ikiz_yev_yok'] -and $cvp.ikiz_yev_yok){ continue }
  $asil=ConvertTo-Json -InputObject $cvp.sema -Depth 6 -Compress
  $istI=$ikizYevIstem.Replace('{ASIL}',$asil).Replace('{IKIZSORU}',"$($cvp.ikiz.ikiz_soru)").Replace('{IKIZTABLO}',(ConvertTo-Json -InputObject $cvp.ikiz.tablo -Depth 5 -Compress))
  $yi=$null
  foreach($d in 1..3){ try{ $yi=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istI -MaxTok 3000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $si=Coz $yi.metin
  if($si -and "$($si.tur)" -eq 'yok'){
    $cvp | Add-Member -NotePropertyName ikiz_yev_yok -NotePropertyValue "$($si.sebep)" -Force
    CacheYaz; Write-Host "  IKIZ-YEVMIYE GEREKMIYOR $id"; continue
  }
  if($si -and -not ($si.PSObject.Properties['kayitlar'] -and $si.kayitlar) -and $si.ogeler -and $si.ogeler.borc){
    $si | Add-Member -NotePropertyName kayitlar -NotePropertyValue @(,([pscustomobject]@{baslik='';ogeler=$si.ogeler})) -Force
  }
  if($si -and $si.kayitlar -and @($si.kayitlar).Count -ge 1 -and -not @(@($si.kayitlar) | Where-Object { -not ($_.ogeler -and $_.ogeler.borc) }).Count){
    $cvp | Add-Member -NotePropertyName ikiz_sema -NotePropertyValue $si -Force
    CacheYaz; Write-Host "  IKIZ YEVMIYE OK $id"
  } else { $rapor.Add("IKIZ YEVMIYE BOZUK: $id") }
}

# --- YEVMIYE DENKLIK KAPISI (01.09 Cem: "altinda toplam borcun alacagin tuttugu")
# Her kayitta borc toplami = alacak toplami olmali; tutmayan uretim notuna duser.
function YvT2([string]$t){ $s=("$t" -replace '(?i)\s*tl\s*','' -replace '[^\d\.,]',''); if(-not $s){ return $null }; try{ return [decimal]::Parse($s,[Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }catch{ return $null } }
# 02.09: kayit listesini tek yerden cikaran yardimci (asil + ikiz, eski/yeni bicim)
function KayitListesi($sema){
  if(-not $sema -or "$($sema.tur)" -ne 'yevmiye'){ return @() }
  if($sema.PSObject.Properties['kayitlar'] -and $sema.kayitlar){ return @($sema.kayitlar) }
  if($sema.PSObject.Properties['ogeler'] -and $sema.ogeler){ return @(,([pscustomobject]@{baslik='';ogeler=$sema.ogeler})) }
  return @()
}
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  foreach($hangi in @('sema','ikiz_sema')){
    if(-not ($cvp.PSObject.Properties[$hangi] -and $cvp.$hangi)){ continue }
    # DIKKAT: bu degiskene '$etiket' DENMEZ - PS harf ayirmaz, -Etiket parametresini
    # ezer ve sonda "yazildi: kalip-parti-.html" gibi bos ad basar (02.09 yasandi).
    $denetEtiket=if($hangi -eq 'ikiz_sema'){ 'IKIZ ' } else { '' }
    $ki=0
    foreach($ky in (KayitListesi $cvp.$hangi)){
      $ki++
      if(-not $ky.ogeler){ continue }
      $tB=[decimal]0; $tA=[decimal]0; $tam=$true
      foreach($og in @($ky.ogeler.borc)){ $n=YvT2 $og.tutar; if($null -ne $n){ $tB+=$n } else { $tam=$false } }
      foreach($og in @($ky.ogeler.alacak)){ $n=YvT2 $og.tutar; if($null -ne $n){ $tA+=$n } else { $tam=$false } }
      if($tam -and $tB -ne $tA){ $rapor.Add("${denetEtiket}YEVMIYE DENK DEGIL: $id kayit $ki (borc $tB / alacak $tA)") }
    }
  }
}



# --- TUZAK CESITLILIGI KAPISI (02.09 Cem: "begenmedim") ----------------------
# Olculdu: 120 tuzagin 11'i tek bir adla ('Ters Kayit') tekrarlaniyordu ve 12 soruda
# celdiriciler yalnizca hesap degistiriyordu. Ayni tuzak adi 2'den cok tekrarlaniyorsa
# parti TEKDUZE demektir - rapora yazilir, Cem gormeden kasaya gitmez.
$tuzakSayaci=@{}
foreach($id in @($don.Keys)){
  if($SadeceHtml -or ($SadeceAdim -and $script:FAZ_ADI -ne 'B')){ break }   # yalniz cizim / yalniz adim: diger model fazlari atlanir
  if($PilotId -and (($PilotId -split ',') -notcontains $id)){ continue }   # pilot: yalniz secili sorular
  if(-not (HakemGecti $id)){ continue }   # 08.09 hakem önde: hakemden geçmeyen soru bu faza girmez (bedel)
  $cvpT=$don[$id]
  if(-not $cvpT.soru -or -not $cvpT.aciklama){ continue }
  foreach($hh in 'A','B','C','D','E'){
    if("$($cvpT.dogru)" -eq $hh){ continue }
    $mt=[regex]::Match((AciklamaDuz $cvpT.aciklama.$hh),'([A-ZÇĞİÖŞÜ][\w çğıöşüÇĞİÖŞÜ\-]{2,60}?)\s*Tuza[ğg][ıi]')
    if(-not $mt.Success){ continue }
    $ad=($mt.Groups[1].Value.Trim())
    if(-not $tuzakSayaci.ContainsKey($ad)){ $tuzakSayaci[$ad]=0 }
    $tuzakSayaci[$ad]++
  }
}
$tekduze=@($tuzakSayaci.Keys | Where-Object { $tuzakSayaci[$_] -ge 3 } | Sort-Object { -$tuzakSayaci[$_] })
foreach($ad in $tekduze){ $rapor.Add("TUZAK TEKDUZE: '$ad' $($tuzakSayaci[$ad]) kez kullanildi (en fazla 2 olmali)") }

# --- ARITMETIK KAPISI (sayfa altı özeti; asıl kapı FAZ B'de, 06.09) ---------------------------------------------------
# 01.09 v2: TAM-ZINCIR degerlendirme ("a + b + c = d"); 06.09: değerlendirici AritmetikKusur fonksiyonuna taşındı, FAZ B'de kapı.
# Burada yalnız eldeki bütün soruların (eski cache dahil) özeti çıkarılır ve cache'te `aritmetik` alanı yoksa yazılır (karne için).
$aritUyari=New-Object System.Collections.Generic.List[string]
foreach($id in @($don.Keys)){
  $kus=@(AritmetikKusur $don[$id].adimlar)
  foreach($k in $kus){ $aritUyari.Add("$id : $k") }
  if(-not $don[$id].PSObject.Properties['aritmetik'] -and $don[$id].PSObject.Properties['adimlar'] -and $don[$id].adimlar){ $don[$id] | Add-Member -NotePropertyName aritmetik -NotePropertyValue @($kus) -Force; $script:aritYaz=$true }
}
if($script:aritYaz -and -not $SadeceHtml){ CacheYaz }

# --- BEDEL (07.09 A kovası 9): bu koşunun bütün çağrıları model bazında + USD tahmini; veri/fabrika/bedel-<etiket>.jsonl'a eklenir ---------
try{
  if(Get-Command Get-BedelOzet -ErrorAction SilentlyContinue){
    $bz=Get-BedelOzet
    foreach($s in $bz.satirlar){ Write-Host ("  BEDEL {0}: {1} çağrı · girdi {2} · çıktı {3} · önbellek okuma {4} · ≈{5} USD" -f $s.model,$s.cagri,$s.girdi,$s.cikti,$s.onbellekOkuma,$(if($null -ne $s.usd){ $s.usd } else { '?' })) -ForegroundColor DarkCyan }
    Write-Host ("BEDEL TOPLAM (bu koşu, {0}): ≈{1} USD{2}" -f $Etiket,$bz.toplamUsd,$(if($bz.fiyatVarsayim){ ' (fiyat tablosu VARSAYIM: Sonnet 3/15, Opus 15/75, Haiku 1/5 USD/M; MEVZUAT_FIYAT_JSON ile ez)' } else { '' })) -ForegroundColor Cyan
    if($bz.bilinmeyenModel.Count){ Write-Host "  BEDEL: fiyatı bilinmeyen model: $($bz.bilinmeyenModel -join ', ')" -ForegroundColor Yellow }
    $bedelYol=Join-Path $kok 'veri\fabrika\bedel-kayit.jsonl'
    # 11.09 (Cem "paralel kostur"): artik AYNI ANDA birden cok parti kosuyor ve
    # hepsi bu TEK dosyaya ekliyor. Kilitsiz AppendAllText'te iki surec ayni anda
    # yazarsa satir bozulur ya da cagri "erisim engellendi" ile duser - bedel
    # defteri, harcamanin TEK kaydidir; bozulmasi olculemez harcama demektir.
    # Makine capinda adlandirilmis Mutex (bekleyen-partiler.json ile ayni desen).
    $bedelSatir=((ConvertTo-Json -InputObject ([ordered]@{ zaman=(Get-Date -Format 'yyyy-MM-dd HH:mm'); etiket=$Etiket; ders=$DersRegex; toplamUsd=$bz.toplamUsd; varsayim=$bz.fiyatVarsayim; satirlar=$bz.satirlar }) -Compress -Depth 4)+"`n")
    $bmx=New-Object System.Threading.Mutex($false,'Global\tetikte-bedel-kayit'); $bal=$false
    try{ $bal=$bmx.WaitOne(20000) }catch{ $bal=$true }   # AbandonedMutex: sahibi olduk
    try{ [IO.File]::AppendAllText($bedelYol,$bedelSatir,[Text.UTF8Encoding]::new($false)) }
    finally{ if($bal){ try{ $bmx.ReleaseMutex() }catch{} }; $bmx.Dispose() }
    if($bz.toplamUsd -gt 0 -and -not @($bz.satirlar | Where-Object { $_.onbellekOkuma -gt 0 }).Count){ Write-Host "  BEDEL NOTU: istem önbelleği hiç okunmadı (0) — kaynak paketi cache_control ile işaretlenirse girdi bedeli düşer (açık iş)" -ForegroundColor DarkYellow }
  }
}catch{ Write-Host "  BEDEL özeti yazılamadı: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- SAYFA (tiklanabilir TAM deneyim: sik->tuzak->oynatici->ikiz->ipucu) -----
$ekCss=@'
.sikbtn{display:block;width:100%;text-align:left;background:#26231f;border:1px solid #3b372f;border-radius:10px;color:#e8e6e3;padding:10px 13px;margin:6px 0;font-size:.95em;cursor:pointer;font-family:inherit}
.sikbtn:hover{border-color:#c9a227}.sikbtn.dg{border-color:#7fc98f;background:rgba(127,201,143,.10)}.sikbtn.yn{border-color:#e07b7b;background:rgba(224,123,123,.10)}
.tzk{display:none;border-left:3px solid #e07b7b;background:rgba(224,123,123,.08);border-radius:0 8px 8px 0;padding:8px 11px;margin:8px 0;font-size:.9em}
.acik{display:none}
.ikizB{display:none;border:1px dashed #7fc98f;border-radius:12px;padding:12px;margin-top:10px}
.ikx{width:104px;background:#1b1b1f;border:1px solid #5a5648;border-radius:6px;color:#e8e6e3;padding:4px 7px;font-family:inherit;font-size:.9em}
.ikx.dog{border-color:#7fc98f;background:rgba(127,201,143,.12)}.ikx.yan{border-color:#e07b7b;background:rgba(224,123,123,.12)}
.verilen{box-shadow:inset 3px 0 0 #78b4ff}
.ipP{display:none;border:1px solid #78b4ff;border-radius:10px;padding:9px 12px;margin-top:8px;background:rgba(120,180,255,.07);font-size:.9em}
.ipP .ipf{font-family:Consolas,monospace;font-size:.92em;color:#8fd0ff;background:rgba(120,180,255,.10);border-radius:8px;padding:6px 9px;margin-top:5px;white-space:pre-line}
.dgm2{display:inline-block;background:#c9a227;color:#1b1b1f;font-weight:800;border:none;border-radius:8px;padding:7px 13px;cursor:pointer;font-family:inherit;margin:8px 6px 0 0;font-size:.88em}
.dkB{display:none;border:1px dashed #78b4ff;border-radius:12px;padding:12px;margin-top:10px}
/* 02.09 mobil: genis icerik SAYFAYI degil KENDINI kaydirir */
.tkay{overflow-x:auto;-webkit-overflow-scrolling:touch}
table.tcetvel{min-width:340px}
@media (max-width:640px){
  body{padding:0 11px;font-size:15.5px}
  .dkx,.ikx{width:88px;font-size:16px;padding:7px 8px}
  .sikbtn{padding:12px 13px}
  .dgm2,.padim{padding:11px 15px;font-size:.92em}
  #seriKutu{margin:-10px -11px 12px}
}
.dkx{width:96px;background:#1b1b1f;border:1px solid #5a5648;border-radius:6px;color:#e8e6e3;padding:4px 7px;font-family:inherit;font-size:.9em}
.dkx.dog{border-color:#7fc98f;background:rgba(127,201,143,.12)}.dkx.yan{border-color:#e07b7b;background:rgba(224,123,123,.12)}
.rozet2{display:inline-block;background:rgba(201,162,39,.14);border:1px solid #c9a227;color:#c9a227;border-radius:999px;padding:2px 10px;font-size:.78em;font-weight:800;margin-left:8px}
'@
# DENK OYUNU cizdiricisi (02.09) - asil kayit ve IKIZ kayit ayni fonksiyondan.
# $ekSinif='ikiz' ise oyun ikiz blogunun icine gomulur (kendi kapsaminda calisir).
# 02.09 SIZINTI FRENI: oyunda gosterilen kayit basligi cevabi ele vermemeli.
# Istem artik kisa baslik istiyor ama ESKI cache'te uzun basliklar var; bu fonksiyon
# parantez icini ve gerekce kuyrugunu atar, 'N) tarih - islem' cekirdegini birakir.
function BaslikTemiz([string]$b){
  $t="$b".Trim()
  if(-not $t){ return '' }
  $t=[regex]::Replace($t,'\s*\([^)]*\)','')                 # parantezli aciklama = cogu sizinti
  $t=[regex]::Replace($t,'\s*[:,]\s*(FIFO|LIFO|ortalama).*$','',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $t=[regex]::Replace($t,'\s*-\s*(cunku|zira|oldugundan|nedeniyle).*$','',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
  # tutar sizintisi - ama TARIH bozulmaz: '(\.\d{3})+' sonrasi rakam gelirse (01.09.2025
  # icindeki '09.202' gibi) eslesme IPTAL edilir. (02.09'da tarihler '01.5'e dusmustu.)
  $t=[regex]::Replace($t,'(?<![\d\.])\d{1,3}(\.\d{3})+(?!\d)(,\d+)?\s*(TL|₺)?','')
  $t=[regex]::Replace($t,'\s*%\s*\d+([,\.]\d+)?','')                        # oran sizintisi
  $t=[regex]::Replace($t,'\s*\b[1-7]\d{2}\s+[A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ\s]{3,}','')  # hesap kodu+adi
  $t=($t -replace '\s{2,}',' ').Trim(' ','-',':',',')
  if($t.Length -gt 45){ $t=$t.Substring(0,44).TrimEnd(' ','-',':',',')+'…' }
  return $t
}
function OyunHtml($kayitlar,[string]$dugmeYazi,[string]$anlatim,[string]$ekSinif){
  if(-not $kayitlar -or @($kayitlar).Count -eq 0){ return '' }
  $dk=[Text.StringBuilder]::new()
  $bg=if($ekSinif -eq 'ikiz'){ '#78b4ff' } else { '#8fc98f' }
  [void]$dk.Append("<div class='dkSar $ekSinif' style='margin-top:12px'><button class='dgm2 dkAc' style='background:$bg'>$dugmeYazi</button><div class='dkB'><p style='font-size:.88em'>$anlatim</p>")
  foreach($ky in @($kayitlar)){
    if(-not ($ky.ogeler -and $ky.ogeler.PSObject.Properties['borc'])){ return '' }
    $bTemiz=BaslikTemiz $ky.baslik
    if($bTemiz){ [void]$dk.Append("<div style='margin:10px 0 4px;font-weight:800;font-size:.9em;color:#78b4ff'>$(K $bTemiz)</div>") }
    [void]$dk.Append("<div class='tkay'><table class='tcetvel'><tr><th style='text-align:left'>HESAP</th><th style='width:118px'>BORÇ</th><th style='width:118px'>ALACAK</th></tr>")
    $tumOg=@()
    foreach($og in @($ky.ogeler.borc)){ $tumOg+=,@{h="$($og.hesap)";t="$($og.tutar)";taraf='b'} }
    foreach($og in @($ky.ogeler.alacak)){ $tumOg+=,@{h="$($og.hesap)";t="$($og.tutar)";taraf='a'} }
    foreach($og in @($tumOg | Sort-Object { $_.h })){
      $db=''; $da=''; if($og.taraf -eq 'b'){ $db=$og.t } else { $da=$og.t }
      [void]$dk.Append("<tr><td style='text-align:left'>$(K $og.h)</td><td><input class='dkx' data-d='$(K $db)'></td><td><input class='dkx' data-d='$(K $da)'></td></tr>")
    }
    [void]$dk.Append("<tr style='border-top:2px solid #78b4ff;font-weight:800'><td style='text-align:left'>TOPLAM</td><td class='ttutar dkTb'>—</td><td class='ttutar dkTa'>—</td></tr></table></div>")
  }
  [void]$dk.Append("<button class='dgm2 dkKontrol'>⚖️ Denk mi?</button><button class='dgm2 dkGoster' style='background:#5a5648;color:#e8e6e3'>Doğruları göster</button><div class='dkMesaj' style='margin-top:8px;font-weight:800'></div></div></div>")
  return $dk.ToString()
}
# --- ÇİZİM KAPISI (11.09.2026, Cem "CizmeAtla anahtarını ekleyeyim") ---------
# Toplu tamamlama turlarında (ör. FAZ S'i 27 partiye sonradan koşmak) her parti
# kendi denetim HTML'ini yeniden çiziyordu; oysa tur sonunda 9 yayın sayfası
# zaten tek seferde yeniden basılıyor. ÖLÇÜLDÜ (iddia değil): 77 soruluk
# sgs-t1-denetim-kolay partisinin yalnız çizimi -SadeceHtml ile 54 sn sürüyor
# → 27 partide ≈24 dakika. (Turun asıl süresi burada değil, ardışık model
# çağrılarında geçiyor: aynı partide 50 Haiku çağrısı ≈8 dk.)
#
# ⚠ BİTİŞ DAMGASI: satır 73'teki "ATLANDI: zaten basılmış" kapısı bu HTML
# dosyasının VARLIĞINA bakar. -CizmeAtla ile koşan parti damga BASMAZ; bir
# sonraki normal koşu partiyi yeniden işler. Tamamlama turunda istenen davranış
# budur, ama yeni üretimde -CizmeAtla KULLANILMAZ.
#
# $rapor bu noktaya kadar biriken üretim notlarını taşır ve normalde YALNIZ
# HTML'in "Üretim notları" satırına yazılır. Çizim atlanırsa o notlar yok olurdu
# - bugün sessiz kapıyı konuşturduktan sonra bu kabul edilemez, o yüzden
# atlarken notlar ekrana basılır.
if($CizmeAtla){
  Write-Host ("CIZIM ATLANDI (-CizmeAtla): kalip-parti-$Etiket.html yazilmadi, bitis damgasi BASILMADI") -ForegroundColor Cyan
  if($rapor.Count){
    Write-Host ("URETIM NOTLARI ({0}):" -f $rapor.Count) -ForegroundColor Yellow
    $rapor | ForEach-Object { Write-Host "  - $_" }
  } else { Write-Host "URETIM NOTLARI: yok" }
  # ⚠ `$ikmap` bu noktadan SONRA (satir ~3545) kurulur - buraya YAZILMAZ, yoksa
  #   "ikiz: 0" diye yanlis rakam basardi. Sondaki ozet satirindan tek farki bu.
  "yazildi: (cizim atlandi) | soru: $($don.Count) | kaynak-borcu: $($kaynakBorcu.Count) | aritmetik uyari: $($aritUyari.Count)"
  exit 0
}
$sb=[Text.StringBuilder]::new()
[void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width, initial-scale=1""><title>KALIP PARTİSİ — $Sinav $DersRegex ($($don.Count) soru)</title><style>$css$ekCss</style></head><body>")
[void]$sb.Append("<div id='seriKutu' style='position:sticky;top:0;z-index:50;background:#1b1b1f;border-bottom:1px solid #3b372f;padding:7px 10px;margin:-10px -10px 12px;display:flex;align-items:center;gap:10px;font-weight:800;font-size:.9em'><span id='seriSerit' style='color:#8a8a8a'>⚖️ Denk serisi: 0</span><span id='seriRekor' style='color:#8a8a8a;font-weight:600;font-size:.85em'></span></div>")
[void]$sb.Append("<h1>🧪 KALIP PARTİSİ — $Sinav / $DersRegex — SÖZLEŞMENİN TAMAMI, TIKLANABİLİR</h1><p style='color:#aaa;font-size:13px'>Şık seç → tuzak kutusu → açıklama → 🎬 adım adım → ✍️ ikiz + 💡 ipucu. Konular köprüden, kaynaklar ambardan. KASAYA YAZILMADI.</p>")
if($kaynakBorcu.Count){ [void]$sb.Append("<div style='border:1px solid #e07b7b;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>📌 KAYNAK BORCU (üretilmedi — yutulacak):</b><br>$(($kaynakBorcu | ForEach-Object { K $_ }) -join '<br>')</div>") }
if($rapor.Count){ [void]$sb.Append("<p style='color:#e0a458;font-size:12px'>Üretim notları: $(K ($rapor -join ' · '))</p>") }
if($aritUyari.Count){ [void]$sb.Append("<p style='color:#ff8080;font-size:12px'>⚠ Aritmetik uyarı ($($aritUyari.Count)): $(K (($aritUyari|Select-Object -First 6) -join ' · '))</p>") }
if($hakemRed.Count){ [void]$sb.Append("<div style='border:2px solid #ff6b5e;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>⛔ HAKEM REDDİ ($($hakemRed.Count)) — kasa yolunda karantina:</b><br>$(($hakemRed | ForEach-Object { K ("$_ : "+$don[$_].hakem.gerekce) }) -join '<br>')</div>") }
else{ [void]$sb.Append("<p style='color:#7fc98f;font-size:12.5px'>✅ Dayanak Hakemi: $(@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] }).Count) sorunun tamamı ONAYLI.</p>") }
if($dersRed.Count){ [void]$sb.Append("<div style='border:2px solid #e0a458;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>📚 DERS-DIŞI ($($dersRed.Count)) — kendi dersinin partisine devredilecek:</b><br>$(($dersRed | ForEach-Object { K ("$_ ($($don[$_].konu)) : "+$don[$_].hakem.ders_gerekce) }) -join '<br>')</div>") }
else{ [void]$sb.Append("<p style='color:#7fc98f;font-size:12.5px'>✅ Ders-Uyum Hakemi (KAPI C): tüm sorular '$DersRegex' resmî kapsamına uygun.</p>") }
$adet=0
$amap=[ordered]@{}; $vmap=[ordered]@{}; $tzmap=[ordered]@{}; $ikmap=[ordered]@{}
foreach($id in ($don.Keys|Sort-Object)){
  $cvp=$don[$id]; if(-not $cvp.soru){ continue }
  $adet++
  $adVar=($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar)
  $ikVar=($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz)
  # tuzak sozlugu: aciklamalardan ad cek
  $tz=[ordered]@{}
  foreach($hh in 'A','B','C','D','E'){
    if("$($cvp.dogru)" -eq $hh){ continue }
    $mt=[regex]::Match((YazimOnar (AciklamaDuz $cvp.aciklama.$hh)),'([A-ZÇĞİÖŞÜ][\w çğıöşüÇĞİÖŞÜ\-]{2,60}?Tuza[ğg]ı)')
    if($mt.Success){ $tz[$hh]=$mt.Groups[1].Value.Trim() }
  }
  $tzmap[$id]=$tz
  $hkDamga=''
  if($cvp.PSObject.Properties['hakem'] -and $cvp.hakem){
    if("$($cvp.hakem.karar)" -eq 'EVET'){ $hkDamga="<span style='color:#7fc98f;font-size:.72em;font-weight:800;margin-left:8px'>✅ hakem onaylı</span>" }
    else{ $hkDamga="<span style='color:#ff6b5e;font-size:.72em;font-weight:800;margin-left:8px'>⛔ HAKEM REDDİ: $(K $cvp.hakem.gerekce)</span>" }
  }
  [void]$sb.Append("<div class='soru' data-sid='$id' data-dogru='$($cvp.dogru)'><span class='tip'>YENİ</span><span class='konu'>#$adet · $(K $cvp.konu)</span><span class='rozet2'>📌 Çıkmış arşivde $($cvp.donem) dönemde soruldu</span>$hkDamga<div style='font-size:.72em;color:#777;margin-top:2px'>kaynak: $(K ((@($cvp.kaynak_adlar)|Select-Object -First 2) -join '; '))</div>")
  [void]$sb.Append("<p><b>$(K $cvp.soru)</b></p>")
  foreach($hh in 'A','B','C','D','E'){ [void]$sb.Append("<button class='sikbtn' data-h='$hh'>$hh) $(K $cvp.siklar.$hh)</button>") }
  [void]$sb.Append("<div class='tzk'></div><div class='acik'><div class='ac'>")
  foreach($hh in 'A','B','C','D','E'){
    $isr=''; $dogruMu=("$($cvp.dogru)" -eq $hh); if($dogruMu){ $isr=' ✓' }
    # 02.09: yazim onarimi + yanlis siklarda tekrarlanan "Ne soruluyor" kirpma
    $acikMetin=YazimOnar (TekrarKirp (AciklamaDuz $cvp.aciklama.$hh) $dogruMu)
    [void]$sb.Append("<p><b>$hh$isr)</b> $(K $acikMetin)</p>")
  }
  if($adVar){ [void]$sb.Append("<div><button class='padim'>🎬 Bu çözümü adım adım yaşa</button><div class='panlat'><div class='psayac'></div><div class='pformul'></div><div class='pmetin' style='margin-top:6px;font-size:.93em'></div><button class='padim pileri' style='margin-top:8px;padding:6px 12px;font-size:.85em'>İleri →</button></div></div>") }
  $verList=$null; if($cvp.PSObject.Properties['verilen']){ $verList=$cvp.verilen }
  $tabloH=TabloHtml $cvp.cozum_tablo $verList
  $semaH=SemaHtml $cvp.sema
  # 01.09 Cem "1 YAP": DENK OYUNU - ogrenci tutari DOGRU TARAFA kendisi yazar,
  # "Denk mi?" toplamlari kiyaslar; denk + dogruysa rozet + seri (localStorage).
  # Hesaplar kod sirasiyla TEK listede verilir ki taraf bilgisi sizmasin.
  # 02.09: eski tek-'ogeler' biciminde kalan sorular (cozum_tablo'su olmadigi icin
  # FAZ-S'ye hic girmeyenler) da oyun alir - cizdiricideki geri uyumun aynisi.
  # @() SART: PS fonksiyondan donen tek elemanli diziyi COZER, .Count null olur ve
  # oyun sessizce basilmaz (02.09: 23 kayittan 14'u boyle kayboldu).
  $oyunKayit=@(KayitListesi $cvp.sema)
  $oyunH=''; if($oyunKayit.Count){ $oyunH=OyunHtml $oyunKayit '⚖️ Kaydı SEN yap — denk tutturabilecek misin?' 'Tutarlar yukarıdaki çözüm tablosunda — ama tutarı hangi tarafa yazacağına <b>sen</b> karar vereceksin: borç mu, alacak mı? Bitince <b>Denk mi?</b> düğmesine bas; denk tutturunca ya da <b>Doğruları göster</b> deyince doğru defter hemen altında belirir.' '' }
  # 02.09 Cem: defter KAPALI baslasin (details) idi. 03.09 Cem "3 yap": TEK KUTU, OGRETICI SIRA -
  # cozum tablosu (hesaplama) -> "Kaydi SEN yap" (bos defter, aday kendisi yazar) -> DOGRU DEFTER
  # gizli; "Denk mi?" basarili olunca / "Dogrulari goster" deyince / adim adim son adimda belirir.
  # Boylece defter cozum tablosunun icinde ama oyunun cevabini onceden gostermez.
  if($semaH -and $cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye'){
    $defterGizli=if($oyunH){ "display:none" } else { "" }
    $defterBaslik="<div style='font-weight:800;font-size:.9em;color:#78b4ff;margin-top:14px'>📖 Defter — doğru yevmiye kaydı</div>"
    [void]$sb.Append("<div class='cozumKutu' style='border:1px dashed rgba(120,180,255,.45);border-radius:10px;padding:8px 12px 12px;margin-top:12px'>$tabloH$oyunH<div class='defterD' style='$defterGizli'>$defterBaslik$semaH</div></div>")
  } else {
    [void]$sb.Append($tabloH); [void]$sb.Append($semaH); if($oyunH){ [void]$sb.Append($oyunH) }
  }
  if($ikVar){
    $ik=$cvp.ikiz
    $ikVerK=@{}; foreach($v in @($ik.verilen)){ $ikVerK["$(@($v)[0]),$(@($v)[1])"]=1 }
    $ikBosK=@{}; foreach($v in @($ik.bosluk)){ $ikBosK["$(@($v)[0]),$(@($v)[1])"]=1 }
    $tb=[Text.StringBuilder]::new()
    [void]$tb.Append("<table class='tcetvel'><tr>")
    foreach($b in @($ik.tablo.basliklar)){ [void]$tb.Append("<th>$(K $b)</th>") }
    [void]$tb.Append('</tr>')
    $rq=0
    foreach($st in @($ik.tablo.satirlar)){
      $rq++
      [void]$tb.Append('<tr>')
      $cq=0
      foreach($hc in @($st)){
        $kkey="$($rq-1),$cq"
        if($cq -eq 0){ [void]$tb.Append("<td style='font-weight:600'>$(K $hc)</td>") }
        elseif($ikBosK.ContainsKey($kkey)){ [void]$tb.Append("<td><input class='ikx' data-dogru='$(K $hc)' placeholder='?'></td>") }
        elseif($ikVerK.ContainsKey($kkey)){ [void]$tb.Append("<td class='verilen'>$(K $hc)</td>") }
        else{ [void]$tb.Append("<td>$(K $hc)</td>") }
        $cq++
      }
      [void]$tb.Append('</tr>')
    }
    [void]$tb.Append('</table>')
    # 02.09 GM onerisi 1 (Cem "1 YAP"): ikizin KAYIT versiyonu AYNI blogun icinde -
    # ogrenci ayni yontemi ikinci kez, YENI rakamlarla uygular. Kas hafizasi burada.
    $ikOyun=''
    if($cvp.PSObject.Properties['ikiz_sema'] -and $cvp.ikiz_sema){
      $ikOyun=OyunHtml (KayitListesi $cvp.ikiz_sema) '⚖️ Şimdi kaydı da sen yaz — yeni rakamlarla' 'Aynı yöntem, yeni rakamlar. Tutarları hangi tarafa yazacağına yine <b>sen</b> karar ver.' 'ikiz'
    }
    [void]$sb.Append("<div style='margin-top:12px'><button class='dgm2 ikizAcB'>✍️ Şimdi sen dene — aynı yöntemi yeni rakamlarla</button><div class='ikizB'><p style='font-weight:600'>$(K $ik.ikiz_soru)</p><p style='color:#7fc98f;font-size:.88em'>🎯 $(K $ik.hedef_cumle) — 🔷 maviler soruda verildi; boşları SEN doldur.</p>$($tb.ToString())<button class='dgm2 ikKontrol'>Kontrol et</button><button class='dgm2 ipAl' style='background:#78b4ff'>💡 Takıldım — ipucu (1/3)</button><button class='dgm2 ikGoster' style='background:#5a5648;color:#e8e6e3'>Doğruları göster</button><span class='ikSkor' style='margin-left:8px;font-weight:800'></span><div class='ipP'><span style='font-weight:800;color:#78b4ff;font-size:.8em' class='ipB'></span><div class='ipM' style='margin-top:4px'></div><div class='ipf' style='display:none'></div></div>$ikOyun</div></div>")
    # ipucu verisi: formul zinciri adimlardan
    $genel=New-Object System.Collections.Generic.List[string]
    foreach($aa in @($cvp.adimlar)){
      $ilkS=@("$($aa.formul)" -split "`n")[0].Trim()
      if($ilkS -and $ilkS -notmatch '^Verilenler' -and $ilkS -match '='){
        $gnl=($ilkS -split '=')[0].Trim()+' = '+(($ilkS -split '=')[1]).Trim()
        if($gnl -notmatch '\d{2}' -and -not $genel.Contains($gnl)){ [void]$genel.Add($gnl) }
      }
    }
    # 06.09: cache'te çift iki biçimde yaşıyor - [r,c] dizisi ya da {value:[r,c],Count:2} (boru sargısı); ikisi de okunur
    $ilkBos=$null; foreach($v in @($ik.bosluk)){ $ilkBos=$(if($v -and $v.PSObject.Properties['value']){ @($v.value) } else { @($v) }); break }
    $ilkDeger=''; if($ilkBos -and @($ilkBos).Count -ge 2){ try{ $ilkDeger="$(@(@($ik.tablo.satirlar)[[int]@($ilkBos)[0]])[[int]@($ilkBos)[1]])" }catch{ $ilkDeger='' } }
    $ikmap[$id]=@(
      @{ b='💡 İPUCU 1/3 — Formül zinciri'; m='Cevabı söylemiyorum — yolu gösteriyorum:'; f=(($genel | ForEach-Object -Begin{$q=0} -Process{ $q++; "$q) $_" }) -join "`n") },
      @{ b='💡 İPUCU 2/3 — Soru sana ne verdi?'; m='Mavi kenarlı hücreler sorunun verdikleri. Önce onları formül zincirine yerleştir.' },
      @{ b='💡 İPUCU 3/3 — İlk adımı beraber yapalım'; m=('İlk boş hücreyi doldurdum: {0}. Kalanı aynı yöntemle SEN.' -f $ilkDeger); doldur=$ilkDeger }
    )
  }
  if($cvp.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $cvp.sinav_taktigi)</div>") }
  if($cvp.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $cvp.notlandirici)</div>") }
  if($cvp.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $cvp.hap)</div>") }
  [void]$sb.Append("</div></div></div>")
  if($adVar){ $amap[$id]=@($cvp.adimlar) }
  if($cvp.PSObject.Properties['verilen'] -and $cvp.verilen -and $cvp.cozum_tablo){
    $vb=[Text.StringBuilder]::new()
    [void]$vb.Append("<div style='font-weight:800;font-size:.8em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
    $ok=$true
    foreach($vv in @($cvp.verilen)){
      if(@($vv).Count -lt 2){ continue }   # 07.09: boş/tek elemanlı verilen kaydı "Index operation ... null" ile raporu düşürüyordu
      $r=@($vv)[0]; $c=@($vv)[1]
      if($null -eq $r -or $null -eq $c){ continue }
      $sat=@(@($cvp.cozum_tablo.satirlar)[$r])
      if($null -eq $sat -or $c -ge @($sat).Count){ $ok=$false; break }
      [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($cvp.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
    }
    [void]$vb.Append('</table>')
    if($ok){ $vmap[$id]=$vb.ToString() }
  }
}
$amapJson='{}'; if($amap.Count){ $amapJson=ConvertTo-Json -InputObject $amap -Depth 7 -Compress }
$vmapJson='{}'; if($vmap.Count){ $vmapJson=ConvertTo-Json -InputObject $vmap -Depth 3 -Compress }
$tzJson=ConvertTo-Json -InputObject $tzmap -Depth 3 -Compress
$ikJson='{}'; if($ikmap.Count){ $ikJson=ConvertTo-Json -InputObject $ikmap -Depth 4 -Compress }
[void]$sb.Append(@"
<script>
const ADIMMAP=$amapJson; const VTMAP=$vmapJson; const TUZAKMAP=$tzJson; const IPUCUMAP=$ikJson;
// 02.09 GM onerisi 2 (Cem "2 YAP"): SERI SERIDI sayfanin tepesinde sabit durur -
// ogrenci seriyi kirmamak icin devam eder. Tek kaynak: localStorage.
const SERISER=document.getElementById('seriSerit'), SERIREK=document.getElementById('seriRekor');
function SERI(delta){
  let s=0,r=0;
  try{ s=parseInt(localStorage.getItem('tetikte_denk_seri')||'0'); r=parseInt(localStorage.getItem('tetikte_denk_rekor')||'0'); }catch(e){}
  if(delta===0){ s=0; } else if(delta){ s+=delta; }
  if(s>r){ r=s; }
  try{ localStorage.setItem('tetikte_denk_seri',String(s)); localStorage.setItem('tetikte_denk_rekor',String(r)); }catch(e){}
  if(SERISER){
    SERISER.textContent=(s>0?('🔥 Denk serisi: '+s+' kayıt'):'⚖️ Denk serisi: 0 — ilk kaydı tuttur');
    SERISER.style.color=(s>=3)?'#c9a227':(s>0?'#8fc98f':'#8a8a8a');
  }
  if(SERIREK){ SERIREK.textContent=(r>0?('en iyi: '+r):''); }
  return s;
}
SERI();
document.querySelectorAll('.soru').forEach(soru=>{
  const sid=soru.dataset.sid, DOGRU=soru.dataset.dogru, TZ=TUZAKMAP[sid]||{};
  // SIK -> tuzak + aciklama
  soru.querySelectorAll('.sikbtn').forEach(b=>{ b.addEventListener('click',()=>{
    soru.querySelectorAll('.sikbtn').forEach(x=>{ x.disabled=true; if(x.dataset.h===DOGRU)x.classList.add('dg'); });
    if(b.dataset.h!==DOGRU){ b.classList.add('yn');
      const tk=soru.querySelector('.tzk');
      if(TZ[b.dataset.h]){ tk.innerHTML='🪤 <b>Düştüğün tuzağın adı:</b> '+TZ[b.dataset.h]+' — aşağıda nasıl çalıştığını göreceksin.'; tk.style.display='block'; } }
    soru.querySelector('.acik').style.display='block';
  });});
  // OYNATICI
  const adimlar=ADIMMAP[sid], btn=soru.querySelector('.padim:not(.pileri)');
  if(adimlar&&btn){
    const pan=soru.querySelector('.panlat'), say=soru.querySelector('.psayac'), met=soru.querySelector('.pmetin'), frm=soru.querySelector('.pformul'), ile=soru.querySelector('.pileri');
    const hcs=()=>soru.querySelectorAll('.hcell');
    const hc=(r,c)=>soru.querySelector(".hcell[data-r='"+r+"'][data-c='"+c+"']");
    let ad=-1;
    const g=()=>{ const s=adimlar[ad];
      say.textContent='ADIM '+(ad+1)+' / '+adimlar.length; met.textContent=s.anlatim;
      if(ad===0&&VTMAP[sid]){ frm.innerHTML=VTMAP[sid]; } else { frm.textContent=s.formul||''; }
      (s.doldur||[]).forEach(k=>{const el=hc(k[0],k[1]); if(el){el.classList.remove('gizli'); el.classList.add('parla'); setTimeout(()=>el.classList.remove('parla'),950);}});
      if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.remove('gizli')); const df=soru.querySelector('.defterD'); if(df){ df.setAttribute('open',''); df.style.display='block'; } }
      ile.textContent=(ad===adimlar.length-1)?'🔄 Baştan':'İleri →'; };
    btn.addEventListener('click',()=>{ hcs().forEach(el=>el.classList.add('gizli')); btn.style.display='none'; pan.style.display='block'; ad=0; g(); });
    ile.addEventListener('click',()=>{ if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.add('gizli')); ad=0; g(); return; } ad++; g(); });
  }
  // IKIZ + IPUCU
  const ikA=soru.querySelector('.ikizAcB');
  if(ikA){
    const norm=t=>String(t||'').toLowerCase().replace(/tl|kg|%/g,'').replace(/[.\s]/g,'').replace(',','.').trim();
    ikA.addEventListener('click',()=>{ ikA.style.display='none'; soru.querySelector('.ikizB').style.display='block'; });
    soru.querySelector('.ikKontrol').addEventListener('click',()=>{
      let d=0,t=0;
      soru.querySelectorAll('.ikx').forEach(i=>{ t++; const ok=norm(i.value)===norm(i.dataset.dogru); i.classList.remove('dog','yan'); i.classList.add(ok?'dog':'yan'); if(ok)d++; });
      const sk=soru.querySelector('.ikSkor'); sk.textContent=d+'/'+t+(d===t?' 🎉 Yöntem senin!':''); sk.style.color=(d===t)?'#7fc98f':'#c9a227';
    });
    soru.querySelector('.ikGoster').addEventListener('click',()=>{ soru.querySelectorAll('.ikx').forEach(i=>{ i.value=i.dataset.dogru; i.classList.remove('yan'); i.classList.add('dog'); }); });
    const IP=IPUCUMAP[sid]||null, ipBtn=soru.querySelector('.ipAl');
    if(IP&&ipBtn){ let n=0;
      ipBtn.addEventListener('click',()=>{ if(n>=IP.length) return; const ip=IP[n];
        soru.querySelector('.ipB').textContent=ip.b; soru.querySelector('.ipM').textContent=ip.m;
        const f=soru.querySelector('.ipf'); f.textContent=ip.f||''; f.style.display=ip.f?'block':'none';
        if(n===1){ soru.querySelectorAll('.ikizB td.verilen').forEach(td=>{ td.classList.remove('parla'); void td.offsetWidth; td.classList.add('parla'); }); }
        if(ip.doldur){ const ilk=soru.querySelector('.ikizB .ikx'); if(ilk&&!ilk.value){ ilk.value=ip.doldur; ilk.classList.add('dog'); } }
        soru.querySelector('.ipP').style.display='block'; n++;
        ipBtn.textContent=(n>=IP.length)?'💡 İpucu bitti — kalanı sende!':'💡 Takıldım — ipucu ('+(n+1)+'/3)';
        if(n>=IP.length){ ipBtn.style.opacity='.55'; } }); }
    else if(ipBtn){ ipBtn.style.display='none'; }
  }
  // DENK OYUNU (01.09; 02.09 coklu: asil kayit + IKIZ kayit ayni soruda)
  soru.querySelectorAll('.dkSar').forEach(sar=>{
    const dkA=sar.querySelector('.dkAc'); if(!dkA) return;
    const nrm=t=>String(t||'').toLowerCase().replace(/tl/g,'').replace(/[.\s]/g,'').replace(',','.').trim();
    const say=t=>{const n=parseFloat(nrm(t));return isNaN(n)?0:n;};
    const fmt=n=>n.toLocaleString('tr-TR');
    dkA.addEventListener('click',()=>{ dkA.style.display='none'; sar.querySelector('.dkB').style.display='block'; });
    const topla=()=>{ sar.querySelectorAll('.dkB table').forEach(tb=>{
        let b=0,a=0; tb.querySelectorAll('tr').forEach(tr=>{ const ins=tr.querySelectorAll('.dkx'); if(ins.length===2){ b+=say(ins[0].value); a+=say(ins[1].value);} });
        const cb=tb.querySelector('.dkTb'), ca=tb.querySelector('.dkTa');
        if(cb){ cb.textContent=fmt(b); ca.textContent=fmt(a); const denk=(b===a&&b>0); cb.style.color=denk?'#8fc98f':'#e07b7b'; ca.style.color=cb.style.color; }
      });};
    sar.querySelectorAll('.dkx').forEach(i=>i.addEventListener('input',topla));
    sar.querySelector('.dkKontrol').addEventListener('click',()=>{
      let d=0,t=0,denkHepsi=true;
      sar.querySelectorAll('.dkx').forEach(i=>{ t++; const ok=nrm(i.value)===nrm(i.dataset.d); i.classList.remove('dog','yan'); i.classList.add(ok?'dog':'yan'); if(ok)d++; });
      topla();
      sar.querySelectorAll('.dkB table').forEach(tb=>{ let b=0,a=0; tb.querySelectorAll('tr').forEach(tr=>{ const ins=tr.querySelectorAll('.dkx'); if(ins.length===2){ b+=say(ins[0].value); a+=say(ins[1].value);} }); if(b!==a||b===0) denkHepsi=false; });
      const ms=sar.querySelector('.dkMesaj');
      // 03.09 Cem "3": asil kayitta denk tutturunca dogru defter ayni kutuda belirir (ikizde degil)
      const defterAc=()=>{ if(sar.classList.contains('ikiz')) return; const df=sar.closest('.cozumKutu')?.querySelector('.defterD'); if(df){ df.style.display='block'; } };
      if(d===t&&denkHepsi){ defterAc(); const seri=SERI(+1);
        ms.innerHTML='🏅 <span style="color:#8fc98f">DENK! Kayıt senin.</span> Seri: '+seri+' kayıt'+(seri>=3?' 🔥':''); ms.style.color='#8fc98f'; }
      else { SERI(0);
        ms.textContent=denkHepsi?('Toplamlar denk ama '+(t-d)+' hücre yanlış — tutar doğru tarafta mı? Kırmızılara bak.'):'Denk değil — hangi taraf eksik? TOPLAM satırı söylüyor. (Seri sıfırlandı)'; ms.style.color='#e07b7b'; }
    });
    sar.querySelector('.dkGoster').addEventListener('click',()=>{ sar.querySelectorAll('.dkx').forEach(i=>{ i.value=i.dataset.d; i.classList.remove('yan','dog'); if(i.dataset.d){ i.classList.add('dog'); } }); topla(); if(!sar.classList.contains('ikiz')){ const df=sar.closest('.cozumKutu')?.querySelector('.defterD'); if(df){ df.style.display='block'; } } });
  });
});
</script>
"@)
[void]$sb.Append("</body></html>")
[IO.File]::WriteAllText($HEDEF,$sb.ToString(),[Text.UTF8Encoding]::new($false))
"yazildi: kalip-parti-$Etiket.html | soru: $adet | ikiz: $($ikmap.Count) | kaynak-borcu: $($kaynakBorcu.Count) | aritmetik uyari: $($aritUyari.Count)"
