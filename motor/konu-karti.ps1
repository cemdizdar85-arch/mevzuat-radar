# ============================================================================
#  KONU KARTI URETICISI — 25.08.2026
#
#  CEM: "TTK anlatacaksın, taciri anlatacaksın, ilk önce onu anlat"
#       "biz burda öğretmiyoruz. adam soruyu çözünce konuyu öğrensin"
#
#  TESHIS (ALTIN-09 okunarak): soru "tacir" diyor ama aday tacirin ne oldugunu,
#  esnaftan farkini, kac yolla tacir olundugunu, tacirligin ne getirdigini HIC
#  ogrenmiyor. Soruyu cozuyor, KONUYU ogrenmiyor. Kart bu bosluktur.
#
#  KARTIN DORT BOLUMU (sabit, pazarliksiz):
#    1) ZEMIN    - konunun dayandigi temel kavram. Tacir icin: ticari isletme.
#    2) KARISIR  - en cok karistirildigi komsu kavram, olcut olcut karsilastirma.
#                  Tacir icin: esnaf. Sinav tuzaklarinin cogu buradan cikar.
#    3) DALLAR   - konunun kac yolu/hali var; her dalin kendi maddesi ve tuzagi.
#    4) SONUCLAR - konu ne ise yarar. Tacir icin m.18 yukumlulukleri.
#
#  ⚠ KART, SORUDAN DAHA TEHLIKELIDIR: yanlissa hata tek soruya degil o konudaki
#  BUTUN sorulara dagilir. Bu yuzden:
#    - Kart TEK madde ile yazilmaz; konunun BUTUN maddeleri okunur
#      (Tacir = TTK m.11 + m.12 + m.15 + m.18). Tek madde konunun bir dilimidir.
#    - Metinde OLMAYAN hukum yazilamaz; fikra numarasi metinde yoksa yazilamaz.
#    - Kart da soru ile ayni kapilardan gecer.
#
#  CIKTI: veri/fabrika/konu-kartlari.json  (her kart URETILIR URETILMEZ yazilir)
# ============================================================================
param(
  [string]$model = 'claude-sonnet-5',
  [switch]$olcum,                 # PARA HARCAMAZ: yalniz kaynaklar cozuluyor mu
  [string]$yalniz = ''            # tek kart uret (baslik parcasi)
)
# --- HAT ON KONTROLU (25.08) -------------------------------------------------
# Buyuk/kucuk harf cakismasi bu hatti 25.08'de BES kez sessizce curuttu.
# Cakisma varsa bu betik HIC BASLAMAZ. Kirli olcum > hic olcmemek DEGILDIR.
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
. (Join-Path $here 'madde-coz.ps1') -kutuphane
Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient; $hc.Timeout = [TimeSpan]::FromSeconds(600)

# Turkce-toleransli sadelestirme (konu kapisi icin). Ad 'Duz2' - kisa ad kullanma
# kurali: $H/$h vakasindan sonra global adlar acik yazilir.
function Duz2([string]$t){
  $s = "$t".ToLowerInvariant()
  $s = $s -replace '[ıİi]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
  $s = $s -replace '[^a-z0-9]',' '
  return ($s -replace '\s+',' ').Trim()
}

# ---------------------------------------------------------------- KART PLANI
# Her kartin BIRDEN FAZLA kaynagi var - konunun tamami okunmadan kart yazilmaz.
$PLAN = @(
  [ordered]@{ baslik='Tacir'; sinav='SGS'; ders='Ticaret Hukuku'; konu='tacir sifati ve sonuclari'
    kaynaklar=@('TTK (6102 s.K.) m.11','TTK (6102 s.K.) m.12','TTK (6102 s.K.) m.15','TTK (6102 s.K.) m.18')
    odak='Tacir kimdir, esnaftan farki nedir, kac yolla tacir olunur, tacir olmak ne getirir' }

  [ordered]@{ baslik='Haksız rekabet'; sinav='SMMM'; ders='Muh. ve Mali Müş. Meslek Hukuku'; konu='haksiz rekabet halleri'
    kaynaklar=@('TTK (6102 s.K.) m.54','TTK (6102 s.K.) m.55','TTK (6102 s.K.) m.56')
    odak='Haksiz rekabet nedir, amaci ne, kac ana hali var, hangi davalar acilabilir' }

  [ordered]@{ baslik='Belirli süreli iş sözleşmesi'; sinav='SGS'; ders='Hukuk'; konu='belirli sureli is sozlesmesi'
    kaynaklar=@('İş K. (4857 s.K.) m.8','İş K. (4857 s.K.) m.9','İş K. (4857 s.K.) m.11','İş K. (4857 s.K.) m.12')
    odak='Is sozlesmesi turleri, belirli sureli olmanin sarti, zincirleme yasagi, ayrim yasagi' }

  [ordered]@{ baslik='İmal edilen emtiada maliyet bedeli'; sinav='SGS'; ders='Maliyet Muhasebesi'; konu='imal edilen emtia maliyeti'
    kaynaklar=@('VUK (213 s.K.) m.262','VUK (213 s.K.) m.274','VUK (213 s.K.) m.275')
    odak='Maliyet bedeli nedir, emtia nasil degerlenir, imal edilen mamulun maliyetine ne girer, hangisi ihtiyari' }

  [ordered]@{ baslik='İktisadi kıymette maliyet bedeli'; sinav='SGS'; ders='Finansal Muhasebe'; konu='iktisadi kiymette maliyet bedeli'
    kaynaklar=@('VUK (213 s.K.) m.261','VUK (213 s.K.) m.262','VUK (213 s.K.) m.269','VUK (213 s.K.) m.270')
    odak='Degerleme olculeri nelerdir, maliyet bedeline neler girer, gayrimenkullerde hangi giderler ihtiyari' }
)
if($yalniz){ $PLAN = @($PLAN | Where-Object { $_.baslik -like "*$yalniz*" }) }

Write-Host '======== KART PLANI ========'
foreach($p in $PLAN){ Write-Host ("  {0,-36} {1} kaynak" -f $p.baslik, $p.kaynaklar.Count) }

# --- kaynaklari coz
Write-Host ''
Write-Host 'Kaynaklar cozuluyor...'
$metin = @{}
foreach($p in $PLAN){
  foreach($kk in $p.kaynaklar){
    if($metin.ContainsKey($kk)){ continue }
    $c = KaynakCoz $kk $p.konu
    if($c.durum -like 'cozuldu*'){ $metin[$kk] = "$($c.metin)"; Write-Host ("  {0,-30} -> {1,6} karakter" -f $kk, "$($c.metin)".Length) }
    else { Write-Host ("  {0,-30} -> !! {1}" -f $kk, $c.durum) }
  }
}
Write-Host ''
foreach($p in $PLAN){
  $var = @($p.kaynaklar | Where-Object { $metin.ContainsKey($_) })
  $durum = if($var.Count -eq $p.kaynaklar.Count){ 'TAM' } elseif($var.Count -ge 2){ 'KISMI' } else { 'YETERSIZ' }
  Write-Host ("  {0,-36} {1}/{2} kaynak -> {3}" -f $p.baslik,$var.Count,$p.kaynaklar.Count,$durum)
}
if($olcum){ Write-Host ''; Write-Host 'OLCUM MODU - 0 USD.'; exit 0 }
if(-not $env:ANTHROPIC_API_KEY){ Write-Host 'ANTHROPIC_API_KEY yok.'; exit 1 }

# ---------------------------------------------------------------- SOZLESME
function Nesne($g,$o){ @{ type='object'; additionalProperties=$false; required=$g; properties=$o } }
$Str=@{type='string'}
$kartSema = Nesne @('baslik','zemin_baslik','zemin_metin','zemin_maddeler',
                    'karisir_komsu','karisir_olcutler','dallar','sonuclar','akilda_kalsin') ([ordered]@{
  baslik          = $Str
  zemin_baslik    = $Str          # "Ticari işletme nedir?"
  zemin_metin     = $Str          # sifirdan tanim, terimler acikli
  zemin_maddeler  = @{ type='array'; items=$Str }
  karisir_komsu   = $Str          # "Esnaf"  (yoksa "")
  karisir_olcutler= @{ type='array'; items=(Nesne @('olcut','komsu','konu') ([ordered]@{ olcut=$Str; komsu=$Str; konu=$Str })) }
  dallar          = @{ type='array'; items=(Nesne @('ad','madde','metin','tuzak') ([ordered]@{ ad=$Str; madde=$Str; metin=$Str; tuzak=$Str })) }
  sonuclar        = @{ type='array'; items=(Nesne @('metin','madde') ([ordered]@{ metin=$Str; madde=$Str })) }
  akilda_kalsin   = $Str
})

# ⚠ 25.08 KUSUR: burada sablon $ISTEM, kurulan istem ise $istem adiniyordi.
# PowerShell HARF AYIRMAZ -> ikisi AYNI DEGISKEN. Ilk turda sablon Tacir
# istemiyle EZILDI; ikinci turda model [tum Tacir istemi + Tacir maddeleri] +
# [Haksiz rekabet basligi] gordu ve Tacir karti yazdi. Bes kartin dordu bu
# yuzden yanlis konudaydi - istemde ya da kaynakta hicbir sorun yoktu.
# Bugun ucuncu kez ayni tuzak ($H/$h, $ISTEM/$istem). Kurulan istemin adi
# artik $tamIstem. Bkz [[ps-degiskeni-cakismasi]].
$ISTEM = @'
Bir muhasebe meslek sınavı (SGS/SMMM) için KONU KARTI yazacaksın.

KART NEDİR: adayın soruyu görmeden önce okuduğu, konuyu SIFIRDAN öğreten kart.
Hedef kitle: o konuyu HİÇ BİLMEYEN aday. Ürünün vaadi "konu okumadan, soru
çözerek öğrenmek" — kart o vaadin taşıyıcısıdır.

⚠ KART SORUDAN DAHA TEHLİKELİDİR: yanlışsa hata tek soruya değil, o konudaki
BÜTÜN sorulara dağılır.

PAZARLIKSIZ
1. YALNIZ sana verilen madde metinlerine dayan. Metinde olmayan hüküm YAZMA,
   hafızandan tamamlama. Emin değilsen o dalı hiç yazma.
2. FIKRA NUMARASI: yalnız metinde numaralandırma GÖRÜYORSAN yaz ("m.12/2").
   Görmüyorsan sadece "m.12" yaz.
3. TERİM AÇIKLANMADAN KULLANILMAZ. Adayın bilmediği her meslek terimi, kartta
   ilk geçtiğinde tek cümleyle açıklanır. Ölçüt: "bu konuyu hiç bilmeyen biri
   bu kelimeyi duyunca ne anlar?" Anlamıyorsa açıklanır.
   (Buraya terim ÖRNEĞİ bilerek yazılmadı: önceki koşuda örnek olarak verilen
    terimler modeli o konuya çekti ve kart yanlış konuda yazıldı.)
4. Kanun cümlesi kopyalanmaz; hiç bilmeyen birinin anlayacağı sade Türkçe.
5. Yasak kalıplar: "bu bağlamda", "önemli bir husus", "unutulmamalıdır ki",
   "sonuç olarak", "özetle,", "dikkat edilmesi gereken".

⚠⚠ EN ÖNEMLİ KURAL: KART, SANA VERİLEN "KONU" BAŞLIĞI HAKKINDA OLACAK.
Aşağıdaki bölüm tarifleri geneldir; içlerindeki hiçbir ifadeyi konu sanma.
Kartın başlığı, sana verilen KONU ile aynı şeyi anlatmalı.
(Ölçüldü: bir önceki koşuda tarifte geçen örnek yüzünden beş kartın dördü
 YANLIŞ KONUDA yazıldı — model konuyu değil örneği izledi.)

DÖRT BÖLÜM
① ZEMİN — konunun dayandığı temel kavram; o kavram anlaşılmadan konu anlaşılmaz.
   Bu kavramın tanımı ve ayırt edici şartları (kaç şart var, hangileri) sade
   dille yazılır. zemin_maddeler: bu bölümün dayandığı madde numaraları.

② KARIŞIR — konunun en çok karıştırıldığı KOMŞU kavram ve ölçüt ölçüt farkı.
   Sınav tuzaklarının çoğu iki kavramın sınırından çıkar. Komşu kavram, sana
   verilen madde metinlerinde GEÇİYORSA yazılır.
   Metinlerde böyle bir komşu kavram yoksa: karisir_komsu = "" ve
   karisir_olcutler = [] bırak. UYDURMA — yanlış komşu, konuyu baştan bozar.

③ DALLAR — konunun kaç yolu/hâli/kategorisi var. Her dal için:
   ad     : kısa ad
   madde  : dayanağı
   metin  : ne olduğu, sade dille
   tuzak  : bu dalda sınavın sorduğu ince ayrım. Yoksa "" bırak.
   ⚠ Kanunun SÖZCÜK SEÇİMİNE dikkat et. "…sayılır" ile "…gibi sorumlu olur",
     "…zorunludur" ile "…-ebilir", "ve" ile "veya" farklı sonuçlar doğurur.
     Metinde böyle bir incelik varsa tuzak alanına MUTLAKA yaz — sınav tam
     oradan sorar.

④ SONUÇLAR — bu konu ne işe yarar, ne getirir, neye yol açar. Konunun asıl
   önemi çoğu zaman burasıdır. Metinlerde yoksa [] bırak.
   ⚠ TAMLIK: sana verilen maddenin BÜTÜN fıkralarını tara. Bir fıkra karta
     girmiyorsa bunun sebebi konuyla ilgisiz olması olmalı — atlanmış olması
     değil. (Ölçüldü: beş kartın DÖRDÜ kaynakta açıkça yazan bir fıkrayı
     atladı: TTK m.18/4, TTK m.56/4, VUK m.274'teki "267'nci maddenin ikinci
     sırasındaki usul hariç" istisnası, VUK m.269'daki "gayrimenkul gibi
     değerlenen kıymetler" listesi. Madde numarasını kaynak gösterip o
     maddenin yarısını yazmak en ağır kart kusurudur.)

AKILDA KALSIN: tek cümle, en çok 200 karakter. Kartın özü.

⚠ KAYNAK SUSUYORSA ŞERH DÜŞ (kural E3-f)
Karta girmesi gereken bir kavramı kaynak metin TANIMLAMIYORSA iki şey yasaktır:
uydurmak ve atlamak. Üçüncü yolu kullan — boşluğu görünür yaz:
  (1) kaynağın sustuğunu açıkça söyle,
  (2) ölçüt nereden geliyorsa adıyla an (Yargıtay uygulaması / tebliğ / doktrin),
  (3) sınavda bunun nasıl sorulacağını yaz.
Şerh cümlesi madde numarasıyla BİTMEZ — kaynak metinmiş gibi görünmemeli.
(Ölçüldü: "esaslı neden" kartında model, m.11'de geçmeyen bir hukuki ayrımı
 madde numarasına bağlayarak yazdı. Kapı bunu UYDURMA DAL olarak kesti.)

⚠ AYNI İSKELET YASAĞI (kural E3-g)
Dalların hepsini aynı cümle kalıbıyla yazma. Kusursuz simetri okuyucuya
"bunu makine üretti" der — ve bu bizim en çok savunduğumuz sözü çürütür.
Bir dal iki cümle sürsün, biri tek cümlede bitsin, biri örnekle ya da
karşıtıyla açılsın. Aynı yapı en çok 3 kez tekrar edebilir.
(Ölçüldü: beş kartın dördünde her dal "[Başlık] (m. no): açıklama. TUZAK: uyarı."
 kalıbıyla, her sonuç satırı "X istenebilir. (m. no)" kalıbıyla yazılmıştı.)
Bu yasak bölüm başlıklarını KAPSAMAZ — ZEMİN/KARIŞIR/DALLAR/SONUÇLAR düzeni
zorunludur. Yasak, düzenin içindeki cümlelerin tek kalıba dökülmesidir.

⚠ ŞABLON BOŞ BIRAKILMAZ
Bir bölüm için içerik yoksa alanı [] ya da "" bırak. "SONUÇLAR: · ()" gibi
yarım doldurulmuş başlık kartı çöp yapar. (Ölçüldü: bir kart böyle çıktı.)
'@

$AY='https://api.anthropic.com/v1/messages'
$script:jG=0; $script:jC=0
function Cagir([string]$govdeIstem,$sema){
  $govde = @{ model=$model; max_tokens=20000; messages=@(@{role='user';content=$govdeIstem})
              output_config=@{ effort='medium'; format=@{ type='json_schema'; schema=$sema } } } | ConvertTo-Json -Depth 18
  for($d=1;$d -le 3;$d++){
    $ic=New-Object System.Net.Http.StringContent($govde,[Text.Encoding]::UTF8,'application/json')
    $ist=New-Object System.Net.Http.HttpRequestMessage('POST',$AY); $ist.Content=$ic
    $ist.Headers.Add('x-api-key',$env:ANTHROPIC_API_KEY); $ist.Headers.Add('anthropic-version','2023-06-01')
    $ist.Headers.ConnectionClose=$true
    try {
      $yn=$script:hc.SendAsync($ist).GetAwaiter().GetResult()
      $ham=[Text.Encoding]::UTF8.GetString($yn.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
      if(-not $yn.IsSuccessStatusCode){ return @{ hata=$ham.Substring(0,[Math]::Min(300,$ham.Length)) } }
      $cv=$ham|ConvertFrom-Json
      $script:jG+=[int]$cv.usage.input_tokens; $script:jC+=[int]$cv.usage.output_tokens
      $mb=($cv.content|Where-Object{$_.type -eq 'text'}|Select-Object -First 1).text
      if(-not $mb){ return @{ hata="metin blogu yok - stop_reason=$($cv.stop_reason)" } }
      try { return @{ veri=($mb|ConvertFrom-Json) } } catch { return @{ hata='JSON ayristirilamadi' } }
    } catch {
      if($d -eq 3){ return @{ hata="tasima: $($_.Exception.Message)" } }
      Start-Sleep -Seconds (2*$d)
    }
  }
}

$cikti = Join-Path $kok 'veri/fabrika/konu-kartlari.json'
$null = New-Item -ItemType Directory -Force (Split-Path $cikti)
$kartlar = New-Object System.Collections.Generic.List[object]
function Kaydet(){
  $duz=@(); foreach($r in $script:kartlar){ $duz += ,([pscustomobject]$r) }
  try { [IO.File]::WriteAllText($script:cikti,(ConvertTo-Json -InputObject $duz -Depth 14),(New-Object Text.UTF8Encoding($false))); $true } catch { Write-Host ("  !! kayit: {0}" -f $_.Exception.Message); $false }
}
$script:kartlar=$kartlar; $script:cikti=$cikti

foreach($p in $PLAN){
  $var = @($p.kaynaklar | Where-Object { $metin.ContainsKey($_) })
  if($var.Count -lt 2){ Write-Host ("ATLANDI (kaynak yetersiz): {0}" -f $p.baslik); continue }
  Write-Host ''
  Write-Host ("=== KART: {0}  ({1} kaynak)" -f $p.baslik,$var.Count)
  $blok=''
  foreach($kk in $var){
    $t=$metin[$kk]; if($t.Length -gt 9000){ $t=$t.Substring(0,6000)+"`n[...orta atlandi...]`n"+$t.Substring($t.Length-3000) }
    $blok += "`n=== $kk ===`n$t`n"
  }
  $tamIstem = $ISTEM + "`n`nKONU: $($p.baslik)`nDERS: $($p.ders)`nODAK: $($p.odak)`n`n=== MADDE METINLERI ===$blok"
  $c = Cagir $tamIstem $kartSema
  if($c.hata){ Write-Host ("   HATA: {0}" -f $c.hata); continue }
  $v=$c.veri

  # --- KONU KAPISI (25.08, deterministik): kart ISTENEN konu hakkinda mi?
  # Bir onceki kosuda bes kartin DORDU "Tacir" cikti - cunku istemdeki ornek
  # tacirdi ve model konuyu degil ORNEGI izledi. Kapi, uretilen basligin
  # istenen baslikla en az bir anlamli kelimeyi paylasmasini sart kosar.
  function Kelimeler([string]$t){
    $s = (Duz2 $t) -split ' '
    return @($s | Where-Object { $_.Length -ge 4 })
  }
  $istenen = Kelimeler ($p.baslik + ' ' + $p.konu)
  $gelen   = Kelimeler ("$($v.baslik)")
  $ortak   = @($gelen | Where-Object { $istenen -contains $_ })
  if(-not $ortak.Count){
    Write-Host ("   KONU KAPISI: istenen `"{0}`" ama kart `"{1}`" hakkinda -> ATILDI" -f $p.baslik,$v.baslik)
    continue
  }
  $kartlar.Add([ordered]@{
    id="KART-$($kartlar.Count+1)"; sinav=$p.sinav; ders=$p.ders; konu=$p.konu; baslik="$($v.baslik)"
    zemin=[ordered]@{ baslik="$($v.zemin_baslik)"; metin="$($v.zemin_metin)"; maddeler=@($v.zemin_maddeler) }
    karisir=$(if("$($v.karisir_komsu)".Trim()){ [ordered]@{ komsu="$($v.karisir_komsu)"; olcutler=@($v.karisir_olcutler) } } else { $null })
    dallar=@($v.dallar); sonuclar=@($v.sonuclar); akilda_kalsin="$($v.akilda_kalsin)"
    dayanaklar=$var; son_kontrol=(Get-Date -Format 'dd.MM.yyyy'); uretim=$model
  })
  $k = Kaydet
  Write-Host ("   yazildi: {0} dal · {1} sonuc · komsu={2}{3}" -f @($v.dallar).Count,@($v.sonuclar).Count,$(if("$($v.karisir_komsu)".Trim()){$v.karisir_komsu}else{'yok'}),$(if($k){" · kaydedildi"}else{" · KAYDEDILEMEDI"}))
}

$TAN=[datetime]'2026-08-31'
if((Get-Date) -le $TAN -and $model -like 'claude-sonnet-5*'){ $fg=2.0;$fc=10.0 } else { $fg=3.0;$fc=15.0 }
$usd=($script:jG/1e6*$fg)+($script:jC/1e6*$fc)
Write-Host ''
Write-Host ("URETILEN KART: {0}/{1}   FATURA: {2:N4} USD  (giris {3:N0} + cikis {4:N0})" -f $kartlar.Count,$PLAN.Count,$usd,$script:jG,$script:jC)
if($kartlar.Count){ Write-Host ("  kart basina {0:N4} USD -> 300 kart icin ~{1:N2} USD" -f ($usd/$kartlar.Count),($usd/$kartlar.Count*300)) }
Write-Host ("-> {0}" -f $cikti)
