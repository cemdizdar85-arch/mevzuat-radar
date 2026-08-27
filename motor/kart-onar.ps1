# ============================================================================
#  KONU KARTI ONARIM DONGUSU — 25.08.2026
#  CEM: "onarım döngüsünü yaz, kartları temizle"
#
#  EKSIK OLAN HALKA BUYDU. Hat bugune kadar soyleydi:
#      URET  ->  OLC  ->  DUR
#  Her kosuda kusur cikiyordu ve elle duzeltmek olceklenmiyordu. Oysa kapi
#  kusuru ADIYLA soyluyor ("K1 EKSIK DAL: m.15'in su cumlesi kartta yok").
#  O adi modele geri vermek dongunun kapanmasi demek:
#      URET  ->  OLC  ->  KUSURU ADIYLA GERI GONDER  ->  ONAR  ->  TEKRAR OLC
#
#  NEDEN AYRI BETIK: kart-kontrol.ps1 calisiyor ve dogrulanmis durumda.
#  Onarimi onun icine gomsem calisan kapiyi bozma riski alirdim (bugun ayni
#  hatayi bir kez yaptim: yeni sigorta eklerken eskisini dusurmek). Bu betik
#  kapiyi ALT SUREC olarak cagirir, ciktisini okur, onarir, tekrar cagirir.
#
#  PAZARLIKSIZ FREN: en fazla -tur tur (varsayilan 3). Uc turda temizlenmeyen
#  kart ATILIR, zorlamayla gecirilmez. Esik gevsetmek kaliteyi olduren seydir.
#
#  Girdi/Cikti: veri/fabrika/konu-kartlari.json (YERINDE onarilir, her turda yazilir)
#  Rapor      : veri/kart-onarim-raporu.json
# ============================================================================
param(
  [int]$tur = 3,
  [string]$model = 'claude-sonnet-5',
  [switch]$kuruProva          # PARA HARCAMAZ: yalniz kapiyi kosar, onarim yapmaz
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }
. (Join-Path $here 'madde-coz.ps1') -kutuphane
Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient; $hc.Timeout=[TimeSpan]::FromSeconds(600)

$kartYol   = Join-Path $kok 'veri/fabrika/konu-kartlari.json'
$fabrika   = Join-Path $kok 'veri/fabrika'
$raporYol  = Join-Path $kok 'veri/kart-onarim-raporu.json'
if(-not (Test-Path $kartYol)){ Write-Host "Kart dosyasi yok: $kartYol"; exit 1 }

# ---------------------------------------------------------------- SOZLESME
# Onarim ciktisi, URETIM ciktisiyla BIREBIR AYNI sekilde olmali - yoksa
# onarilan kart farkli bir seye donusur ve kapi onu tanimaz.
function NesneO($g,$o){ @{ type='object'; additionalProperties=$false; required=$g; properties=$o } }
$Str=@{type='string'}
$onarimSema = NesneO @('baslik','zemin_baslik','zemin_metin','zemin_maddeler',
                       'karisir_komsu','karisir_olcutler','dallar','sonuclar','akilda_kalsin','ne_degistirdim') ([ordered]@{
  baslik          = $Str
  zemin_baslik    = $Str
  zemin_metin     = $Str
  zemin_maddeler  = @{ type='array'; items=$Str }
  karisir_komsu   = $Str
  karisir_olcutler= @{ type='array'; items=(NesneO @('olcut','komsu','konu') ([ordered]@{ olcut=$Str; komsu=$Str; konu=$Str })) }
  dallar          = @{ type='array'; items=(NesneO @('ad','madde','metin','tuzak') ([ordered]@{ ad=$Str; madde=$Str; metin=$Str; tuzak=$Str })) }
  sonuclar        = @{ type='array'; items=(NesneO @('metin','madde') ([ordered]@{ metin=$Str; madde=$Str })) }
  akilda_kalsin   = $Str
  ne_degistirdim  = $Str    # her kusur icin tek satir: neyi nasil duzelttin
})

$ONARIM_KURALI = @'
Bir muhasebe meslek sınavı bankasının KONU KARTINI ONARACAKSIN.

Aşağıda üç şey var: kaynak metinler, mevcut kart, ve kapıların bu kartta
bulduğu kusurların LİSTESİ. Kusurlar makine ve hakem tarafından adıyla
konmuştur; senin işin onları kapatmak.

PAZARLIKSIZ
1. YALNIZ LİSTELENEN KUSURLARI DÜZELT. Kusur bildirilmeyen bölümü olduğu gibi
   bırak. Baştan yazma — çalışan şeyi bozma riski, kusuru bırakma riskinden
   büyüktür.
2. YALNIZ kaynak metinlerine dayan. Metinde olmayan hüküm YAZMA. Bir kusuru
   kapatmak için hafızandan bilgi eklemek, kusuru büyütmektir.
3. FIKRA NUMARASI: yalnız kaynak metinde numaralandırma GÖRÜYORSAN yaz.
   Görmüyorsan sadece "m.12" yaz.
4. TERİM AÇIKLANMADAN KULLANILMAZ. Adayın bilmediği her meslek terimi ilk
   geçtiğinde tek cümleyle, örnekle açıklanır (parantez, kısa çizgi ya da
   "yani" ile; ayrı paragraf açma).
5. DALLAR AYNI CÜMLE İSKELETİYLE KURULAMAZ. Her dal kendi biçiminde yazılır.
6. TEKRAR YASAK. Aynı cümleyi ya da aynı ifadeyi arka arkaya tekrarlama;
   bir kez söyle ve geç. (Ölçüldü: bir kartta aynı cümle 19 kez tekrarlanmıştı.)
7. Yasak kalıplar: "bu bağlamda", "önemli bir husus", "unutulmamalıdır ki",
   "sonuç olarak", "özetle,", "dikkat edilmesi gereken".

⚠ 8. KAYNAK SUSUYORSA ŞERH DÜŞ — UYDURMA (kural E3-f)
ÖLÇÜLDÜ (25.08, birinci onarım turu): kusur 21'den 14'e düştü AMA **K2 UYDURMA
DAL bir karttan dört karta ÇIKTI.** Sebep tam olarak şu: kapı "şu fıkra kartta
yok" dedi, sen o boşluğu kapatmak zorunda hissettin, kaynak ince olunca
UYDURDUN. Bir kusuru kapatmak için ikinci bir kusur üretmek onarım değildir.

Kaynak metin, kapatman istenen boşluğu doldurmuyorsa ÜÇÜNCÜ YOLU kullan —
boşluğu görünür yaz:
  (1) kaynağın sustuğunu açıkça söyle ("Kanun bunu tanımlamıyor."),
  (2) ölçüt nereden geliyorsa adıyla an (Yargıtay uygulaması / tebliğ / doktrin),
  (3) sınavda bunun nasıl sorulacağını yaz.
Şerh cümlesi madde numarasıyla BİTMEZ — kaynak metinmiş gibi görünmesin.
Şerh düşmek K2'yi TETİKLEMEZ; uydurmak tetikler.

Kapatamıyorsan kapatma. "KAPATILAMADI: kaynak bu noktada susuyor" yazmak,
uydurulmuş bir dal eklemekten İYİDİR.

KUSUR TİPLERİ NE İSTER
- K1 EKSİK DAL      : kaynakta olup kartta olmayan dalı/hükmü EKLE.
                      ⚠ Kaynağı YENİDEN OKU. Aradığın hüküm gerçekten orada
                      değilse EKLEME — 8. kurala göre şerh düş ya da kapatılamadı yaz.
- K2 UYDURMA DAL    : kaynakta karşılığı olmayan ifadeyi ÇIKAR (yumuşatma, sil).
- M3 çelişki        : çelişen iki ifadeden kaynağa uyanı bırak, diğerini düzelt.
- M6 sıfırdan öğretmiyor : eksik anlatılan yeri, hiç bilmeyene göre yeniden yaz.
- D13 tanımsız terim: o terimi ilk geçtiği yerde açıkla.
- D12 aynı iskelet  : dalların cümle kuruluşunu çeşitlendir.
- D9 fıkra atfı     : kaynakta yoksa fıkra numarasını KALDIR.
- D14 tekrar döngüsü: tekrarlanan bloğu tek örneğe indir.
- D7 akılda kalsın  : 200 karakteri aşmasın.
- M8 mevzuat eskimiş: kaynak metindeki değişiklik izine göre güncelle.

ÇIKTI: kartın TAMAMINI yeniden ver (değişmeyen bölümler aynen).
"ne_degistirdim" alanına her kusur için tek satır yaz: hangi kusuru nasıl
kapattığın. Kapatamadığın kusur varsa onu da "KAPATILAMADI: ... sebep" diye yaz.
'@

# ---------------------------------------------------------------- YARDIMCI
$AY='https://api.anthropic.com/v1/messages'
$script:jG=0; $script:jC=0
function ModelOnar([string]$govdeIstem){
  $govde = @{ model=$model; max_tokens=20000; messages=@(@{role='user';content=$govdeIstem})
              output_config=@{ effort='medium'; format=@{ type='json_schema'; schema=$script:onarimSema } } } | ConvertTo-Json -Depth 18
  for($d=1;$d -le 3;$d++){
    $ic=New-Object System.Net.Http.StringContent($govde,[Text.Encoding]::UTF8,'application/json')
    $ist=New-Object System.Net.Http.HttpRequestMessage('POST',$AY); $ist.Content=$ic
    $ist.Headers.Add('x-api-key',$env:ANTHROPIC_API_KEY); $ist.Headers.Add('anthropic-version','2023-06-01')
    $ist.Headers.ConnectionClose=$true
    try{
      $yn=$script:hc.SendAsync($ist).GetAwaiter().GetResult()
      $ham=[Text.Encoding]::UTF8.GetString($yn.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
      if(-not $yn.IsSuccessStatusCode){ return @{ hata=$ham.Substring(0,[Math]::Min(300,$ham.Length)) } }
      $cv=$ham|ConvertFrom-Json
      $script:jG+=[int]$cv.usage.input_tokens; $script:jC+=[int]$cv.usage.output_tokens
      $mb=($cv.content|Where-Object{$_.type -eq 'text'}|Select-Object -First 1).text
      if(-not $mb){ return @{ hata="metin blogu yok - stop_reason=$($cv.stop_reason)" } }
      try { return @{ veri=($mb|ConvertFrom-Json) } } catch { return @{ hata='JSON ayristirilamadi' } }
    } catch { if($d -eq 3){ return @{ hata="tasima: $($_.Exception.Message)" } }; Start-Sleep -Seconds (2*$d) }
  }
}
$script:onarimSema=$onarimSema; $script:hc=$hc

function KartYazisi($k){
  $y = "BASLIK: $($k.baslik)`nZEMIN — $($k.zemin.baslik): $($k.zemin.metin)`n"
  if($k.karisir -and "$($k.karisir.komsu)".Trim()){
    $y += "KARISIR — $($k.karisir.komsu):`n"
    foreach($o in @($k.karisir.olcutler)){ $y += "   · $($o.olcut): [komsu] $($o.komsu) | [konu] $($o.konu)`n" }
  }
  $y += "DALLAR:`n"
  foreach($d in @($k.dallar)){ $y += "   · $($d.ad) ($($d.madde)): $($d.metin)`n"; if("$($d.tuzak)".Trim()){ $y += "     TUZAK: $($d.tuzak)`n" } }
  if(@($k.sonuclar).Count){ $y += "SONUCLAR:`n"; foreach($s in @($k.sonuclar)){ $y += "   · $($s.metin) ($($s.madde))`n" } }
  $y += "AKILDA KALSIN: $($k.akilda_kalsin)`n"
  return $y
}
function KartlariYaz($liste){
  $duz=@(); foreach($r in $liste){ $duz += ,([pscustomobject]$r) }
  [IO.File]::WriteAllText($script:kartYol,(ConvertTo-Json -InputObject $duz -Depth 14),(New-Object Text.UTF8Encoding($false)))
}
$script:kartYol=$kartYol

# ---------------------------------------------------------------- DONGU
$gecmis = New-Object System.Collections.Generic.List[object]
for($t=1; $t -le $tur; $t++){
  Write-Host ''
  Write-Host ("################ TUR {0}/{1} ################" -f $t,$tur)

  # 1) KAPIYI KOS (alt surec - calisan kapiya dokunmuyoruz)
  $oncekiler = @(Get-ChildItem $fabrika -Filter 'kart-kontrol-2*.json' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
  & (Join-Path $here 'kart-kontrol.ps1') | Out-Null
  $rapor = Get-ChildItem $fabrika -Filter 'kart-kontrol-2*.json' |
           Where-Object { $oncekiler -notcontains $_.Name } |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if(-not $rapor){
    # yeni dosya olusmadiysa en yenisini al (kapi ayni dakikada iki kez kosmus olabilir)
    $rapor = Get-ChildItem $fabrika -Filter 'kart-kontrol-2*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  }
  if(-not $rapor){ Write-Host 'Kapi ciktisi bulunamadi - dongu durduruldu.'; break }
  $hamRapor = [IO.File]::ReadAllText($rapor.FullName,[Text.Encoding]::UTF8)
  $cozRapor = ConvertFrom-Json -InputObject $hamRapor
  $hukumListesi = @($cozRapor)   # PS 5.1: iki adim SART, tek satirda olmuyor
  $hamKart  = [IO.File]::ReadAllText($kartYol,[Text.Encoding]::UTF8)
  $cozKart  = ConvertFrom-Json -InputObject $hamKart
  $kartlar  = @($cozKart)

  $temiz  = @($hukumListesi | Where-Object { $_.hukum -eq 'uygun' })
  $bozuk  = @($hukumListesi | Where-Object { $_.hukum -ne 'uygun' })
  Write-Host ("KAPI: {0} uygun · {1} kusurlu/olculemedi" -f $temiz.Count,$bozuk.Count)
  # --- KUSUR TIPI SAYIMI (25.08) ---------------------------------------------
  # NEDEN: birinci turda toplam kusur 21'den 14'e dustu ve "onarim calisiyor"
  # dedim. Yaniltiydi: K1 (eksik dal) duserken K2 (UYDURMA dal) BIR karttan
  # DORT karta cikmisti. Onarici, K1'i kapatmak icin uydurmustu. Uydurma dal
  # eksik daldan DAHA TEHLIKELIDIR: eksik dal adayi hazirliksiz birakir,
  # uydurma dal ona YANLIS HUKUK ogretir.
  # KURAL: toplam sayi tek basina ilerleme kaniti DEGILDIR. Herhangi bir kusur
  # TIPI artmissa tur BASARILI SAYILMAZ - toplam dusmus olsa bile.
  $tipSay = @{}
  foreach($hk in $hukumListesi){
    foreach($ks in @(@($hk.deterministik)+@($hk.icerik))){
      $ad = "$ks".Trim(); if($ad.Length -eq 0){ continue }
      # "K1 EKSIK DAL: ..." -> "K1" ;  "D13 tanimsiz-terim: ..." -> "D13"
      $tip = ($ad -split '[\s:]')[0].ToUpperInvariant()
      if($tip -notmatch '^[KMD][0-9]+$'){ continue }
      if(-not $tipSay.ContainsKey($tip)){ $tipSay[$tip]=0 }
      $tipSay[$tip]++
    }
  }
  $onceki = if($gecmis.Count){ $gecmis[$gecmis.Count-1].tipler } else { $null }
  $artan = @()
  if($onceki){
    foreach($tp in $tipSay.Keys){
      $esk = if($onceki.ContainsKey($tp)){ [int]$onceki[$tp] } else { 0 }
      if([int]$tipSay[$tp] -gt $esk){ $artan += ("{0} {1}->{2}" -f $tp,$esk,$tipSay[$tp]) }
    }
    Write-Host ''
    Write-Host '  KUSUR TIPI KARSILASTIRMASI (onceki tur -> bu tur):'
    $tumTip = @(@($onceki.Keys)+@($tipSay.Keys) | Select-Object -Unique | Sort-Object)
    foreach($tp in $tumTip){
      $e = if($onceki.ContainsKey($tp)){ [int]$onceki[$tp] } else { 0 }
      $y = if($tipSay.ContainsKey($tp)){ [int]$tipSay[$tp] } else { 0 }
      $ok = if($y -gt $e){ 'ARTTI  <<<' } elseif($y -lt $e){ 'dustu' } else { 'ayni' }
      Write-Host ("    {0,-6} {1,3} -> {2,3}   {3}" -f $tp,$e,$y,$ok)
    }
    if($artan.Count){
      Write-Host ''
      Write-Host ("  !! TUR BASARISIZ: {0} kusur tipi ARTTI ({1})" -f $artan.Count, ($artan -join ', '))
      Write-Host '     Toplam sayi dusmus olsa bile onarim yeni kusur uretmistir.'
      Write-Host '     Bir kusuru kapatmak icin ikincisini uretmek onarim degildir.'
    }
  }
  $gecmis.Add([ordered]@{ tur=$t; uygun=$temiz.Count; bozuk=$bozuk.Count
    tipler=$tipSay; artan_tip=$artan; tur_basarili=($artan.Count -eq 0)
    ayrinti=@($hukumListesi | ForEach-Object { [ordered]@{ id=$_.id; baslik=$_.baslik; hukum=$_.hukum
      kusur=(@(@($_.deterministik)+@($_.icerik)) | Where-Object { $_ }).Count } }) })

  if(-not $bozuk.Count){ Write-Host 'HEPSI TEMIZ - dongu bitti.'; break }
  if($kuruProva){ Write-Host 'KURU PROVA: onarim yapilmadi, 0 USD.'; break }
  if($t -eq $tur){ Write-Host ("SON TUR - {0} kart temizlenemedi." -f $bozuk.Count); break }
  if(-not $env:ANTHROPIC_API_KEY){ Write-Host 'ANTHROPIC_API_KEY yok - onarim yapilamaz.'; break }

  # 2) ONAR
  foreach($hukum in $bozuk){
    $idx = -1
    for($i=0;$i -lt $kartlar.Count;$i++){ if("$($kartlar[$i].id)" -eq "$($hukum.id)"){ $idx=$i; break } }
    if($idx -lt 0){ continue }
    $k = $kartlar[$idx]
    $kusurlar = @(@($hukum.deterministik) + @($hukum.icerik)) | Where-Object { "$_".Trim() }
    if(-not $kusurlar.Count){ Write-Host ("   {0}: kusur listesi bos (olculemedi) - onarilamaz, atlaniyor" -f $k.id); continue }
    Write-Host ("   ONARILIYOR {0} — {1} kusur" -f $k.id,$kusurlar.Count)

    # kaynak metinleri
    $blok=''
    foreach($kk in @($k.dayanaklar)){
      $c = KaynakCoz $kk $k.konu
      if($c.durum -notlike 'cozuldu*'){ continue }
      $m="$($c.metin)"; if($m.Length -gt 9000){ $m=$m.Substring(0,6000)+"`n[...orta atlandi...]`n"+$m.Substring($m.Length-3000) }
      $blok += "`n=== $kk ===`n$m`n"
    }
    if(-not $blok){ Write-Host '      kaynak cozulemedi - atlandi'; continue }

    $liste=''; $n=0
    foreach($ku in $kusurlar){ $n++; $liste += "  $n) $ku`n" }
    $onarimIstemi = $ONARIM_KURALI +
      "`n`nKONU: $($k.konu)`nDERS: $($k.ders)" +
      "`n`n=== KAYNAK METINLERI ===$blok" +
      "`n`n=== MEVCUT KART ===`n$(KartYazisi $k)" +
      "`n`n=== KAPILARIN BULDUGU KUSURLAR ($($kusurlar.Count) adet) ===`n$liste"

    $c2 = ModelOnar $onarimIstemi
    if($c2.hata){ Write-Host ("      HATA: {0}" -f $c2.hata); continue }
    $v=$c2.veri
    # konu kapisi: onarim kartin konusunu KAYDIRMAMALI
    $istKel = @((($k.konu) -replace '[^a-zA-Z0-9ğüşıöçĞÜŞİÖÇ ]',' ') -split ' ' | Where-Object { $_.Length -ge 4 })
    $gelKel = @((("$($v.baslik)") -replace '[^a-zA-Z0-9ğüşıöçĞÜŞİÖÇ ]',' ') -split ' ' | Where-Object { $_.Length -ge 4 })
    $ortak=0; foreach($g in $gelKel){ foreach($ii in $istKel){ if($g -like "$ii*" -or $ii -like "$g*"){ $ortak++ } } }
    if($istKel.Count -and -not $ortak){
      Write-Host ("      KONU KAYDI: `"{0}`" -> `"{1}`" — onarim REDDEDILDI" -f $k.baslik,$v.baslik); continue
    }

    $kartlar[$idx] = [ordered]@{
      id=$k.id; sinav=$k.sinav; ders=$k.ders; konu=$k.konu; baslik="$($v.baslik)"
      zemin=[ordered]@{ baslik="$($v.zemin_baslik)"; metin="$($v.zemin_metin)"; maddeler=@($v.zemin_maddeler) }
      karisir=$(if("$($v.karisir_komsu)".Trim()){ [ordered]@{ komsu="$($v.karisir_komsu)"; olcutler=@($v.karisir_olcutler) } } else { $null })
      dallar=@($v.dallar); sonuclar=@($v.sonuclar); akilda_kalsin="$($v.akilda_kalsin)"
      dayanaklar=@($k.dayanaklar); son_kontrol=(Get-Date -Format 'dd.MM.yyyy'); uretim="$model (onarim tur $t)"
      onarim_notu="$($v.ne_degistirdim)"
    }
    Write-Host ("      onarildi: {0}" -f (("$($v.ne_degistirdim)" -split "`n")[0]))
  }
  KartlariYaz $kartlar
  Write-Host ("   -> kartlar yazildi ({0} kart)" -f $kartlar.Count)
}

$TAN=[datetime]'2026-08-31'
if((Get-Date) -le $TAN -and $model -like 'claude-sonnet-5*'){ $fg=2.0;$fc=10.0 } else { $fg=3.0;$fc=15.0 }
$usd=($script:jG/1e6*$fg)+($script:jC/1e6*$fc)
Write-Host ''
Write-Host '================ ONARIM OZETI ================'
foreach($g in $gecmis){
  $tipOzet = ''
  if($g.tipler -and @($g.tipler.Keys).Count){
    $tipOzet = '  [' + ((@($g.tipler.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" })) -join ' ') + ']'
  }
  $bayrak = if($g.PSObject.Properties['tur_basarili'] -and -not $g.tur_basarili){ '  << TUR BASARISIZ (kusur tipi artti)' } else { '' }
  Write-Host ("  tur {0}: {1} uygun · {2} kusurlu{3}{4}" -f $g.tur,$g.uygun,$g.bozuk,$tipOzet,$bayrak)
}
Write-Host ("  ONARIM FATURASI: {0:N4} USD  (giris {1:N0} + cikis {2:N0})" -f $usd,$script:jG,$script:jC)
$gecmisD=@(); foreach($g in $gecmis){ $gecmisD += ,([pscustomobject]$g) }
[IO.File]::WriteAllText($raporYol,(ConvertTo-Json -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; tur_sayisi=$tur
  gecmis=$gecmisD; fatura=[ordered]@{ giris=$script:jG; cikis=$script:jC; usd=[math]::Round($usd,4) }
}) -Depth 8),(New-Object Text.UTF8Encoding($false)))
Write-Host '-> veri/kart-onarim-raporu.json'
