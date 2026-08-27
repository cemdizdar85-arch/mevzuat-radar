# ============================================================================
#  KONU ŞEMASI ÜRETİCİ — 25.08.2026
#
#  CEM: "kesinlikle şemayı yapalım · şema ile konuyu daha iyi öğretiriz"
#       "SQL'i bas, 10 şemalık pilot koşalım"
#
#  NE YAPAR: en çok soru içeren konular için KONU ŞEMASI üretir.
#  Şema soruya değil KONUYA bağlıdır — ölçüm (25.08): 2.263 tekil ders+konu
#  var ama en çok soru içeren 300 konu kasanın %55'ini kapsıyor. Tek şema
#  o konudaki bütün soruları besler ("is sozlesmesi feshi" = 1.389 soru).
#
#  MODEL SVG YAZMAZ — YALNIZ YAPI ÜRETİR.
#  Çizimi sema.js deterministik yapar. Sebep: model SVG yazarsa koordinat
#  taşar, kutudan metin çıkar, karanlık temada renk okunmaz ve 300 şemanın
#  300'ü farklı görünür. Yapıyı modele, çizimi koda bırakınca hepsi aynı
#  görünür, tasarım değişikliği tek dosyada yapılır ve çıktı 20 kat küçük
#  olduğu için 20 kat ucuzdur.
#
#  KAYNAK OKUNMADAN ŞEMA ÇİZİLMEZ (kasa kuralının şema karşılığı):
#  maddenin TAM METNİ madde-coz.ps1 ile ambardan getirilir ve modele verilir;
#  metin çözülemezse o konu ATLANIR. Uydurma şema, uydurma sorudan kötüdür —
#  çünkü öğrenci şemaya daha çok güvenir.
#
#  ŞIK YOLU: her örnek soru için "hangi şık şemada hangi düğüme düşüyor"
#  eşlemesi de AYNI çağrıda üretilir (ayrı parti, ayrı para gerekmez).
#  "yok" = şıkkın iddiasının şemada karşılığı YOK; ekranda "bu dal kanunda
#  yok" kutusu çıkar. Bu ayrıca ücretsiz bir kalite ölçüsüdür: beş şıkkın
#  üçü birden "yok" ise soru muhtemelen bozuktur.
#
#  ÇIKTI: veri/fabrika/sema-pilot.json  (gitignore'lu — paralı içerik)
#  -yaz verilirse konu_semasi tablosuna da yazar (tablo yoksa atlar ve söyler).
# ============================================================================
param(
  [int]$adet = 10,                    # kaç konu
  [switch]$yaz,                       # Supabase'e de yaz
  [string]$model = 'claude-sonnet-5',
  [switch]$olcum                      # PARA HARCAMAZ: yalnız hangi konular seçilirdi
)
# --- HAT ON KONTROLU (25.08) -------------------------------------------------
# Buyuk/kucuk harf cakismasi bu hatti 25.08'de BES kez sessizce curuttu.
# Cakisma varsa bu betik HIC BASLAMAZ. Kirli olcum > hic olcmemek DEGILDIR.
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }

$raporYol = Join-Path $kok 'veri/sema-uret-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 8), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# madde-coz.ps1 kütüphane olarak yüklenir (arg vermek ölçüm modunu kapatır)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout = [TimeSpan]::FromSeconds(300)
$hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
$hc.DefaultRequestHeaders.Add('Authorization', "Bearer $($env:SUPABASE_SERVICE_KEY)")
$hc.DefaultRequestHeaders.UserAgent.ParseAdd('mevzuat-radar-robot/1.0')

# --- kasa künyesi. ANAHTAR-TAKİPLİ sayfalama (offset değil): 19.08 dersi,
#     offset büyüdükçe Postgres o kadar satırı atlayarak tarar ve 30k kasada
#     statement timeout üretir. Tavana çarpma SESSİZ KAYIPTIR - bağırılır.
Write-Host 'Kasa künyesi çekiliyor...'
$kasa = New-Object System.Collections.Generic.List[object]
$sonId = ''; $TAVAN = 200
for($s=0; $s -lt $TAVAN; $s++){
  $f = if($sonId){ '&id=gt.' + [uri]::EscapeDataString($sonId) } else { '' }
  $r = @(($hc.GetStringAsync("$U`?select=id,sinav,ders,konu,kaynak,kanun_no,madde_no&order=id&limit=1000$f").GetAwaiter().GetResult() | ConvertFrom-Json) | ForEach-Object { $_ })
  if(-not $r.Count){ break }
  foreach($x in $r){ $kasa.Add($x) }
  $sonId = "$(@($r)[-1].id)"
  if($r.Count -lt 1000){ break }
  if($s -eq $TAVAN-1){ throw "SAYFA TAVANINA CARPILDI - kasa eksik cekilmis olabilir, uretim GECERSIZ." }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ throw "Kasa kucuk gorundu ($($kasa.Count)) - sayfalama kirilmis." }

# --- konuları soru sayısına göre sırala
$gruplar = $kasa | Group-Object { "$($_.ders)|$($_.konu)" } | Sort-Object Count -Descending
Write-Host ("Tekil ders+konu: {0}" -f $gruplar.Count)

# --- her konu için baskın kaynağı bul ve maddeyi çöz
$adaylar = New-Object System.Collections.Generic.List[object]
$atlanan = New-Object System.Collections.Generic.List[object]
foreach($g in $gruplar){
  if($adaylar.Count -ge $adet){ break }
  $parca = "$($g.Name)" -split '\|'
  $ders = $parca[0]; $konu = $parca[1]
  # BASKIN KAYNAK: konudaki soruların en sık kaynağı. Tek bir soruya bakmak
  # yanıltır - 5018 vakasında konunun bazı soruları yanlış bağlıydı.
  $baskin = $g.Group | Group-Object kaynak | Sort-Object Count -Descending | Select-Object -First 1
  $oran = [math]::Round(100 * $baskin.Count / $g.Count, 1)
  $coz = KaynakCoz "$($baskin.Name)" $konu
  if($coz.durum -notlike 'cozuldu*'){
    $atlanan.Add([ordered]@{ ders=$ders; konu=$konu; soru=$g.Count; kaynak="$($baskin.Name)"; sebep=$coz.durum })
    continue
  }
  # DÜRÜST SINIR: baskın kaynak konunun yarısından azını kapsıyorsa konu
  # ETİKET OLARAK BOZUK demektir (4.482 uyumsuz etiket ölçümü). Şema çizmek
  # yanlış şemayı 1.000 soruya dağıtmak olur - atlanır, GM'ye bırakılır.
  if($oran -lt 50){
    $atlanan.Add([ordered]@{ ders=$ders; konu=$konu; soru=$g.Count; kaynak="$($baskin.Name)"; sebep="baskin-kaynak-zayif-%$oran" })
    continue
  }
  $adaylar.Add([ordered]@{
    ders=$ders; konu=$konu; soru=$g.Count; sinav="$(@($g.Group)[0].sinav)"
    kaynak="$($baskin.Name)"; baskinOran=$oran
    kanun_no="$(@($g.Group | Where-Object { "$($_.kaynak)" -eq "$($baskin.Name)" })[0].kanun_no)"
    madde_no="$(@($g.Group | Where-Object { "$($_.kaynak)" -eq "$($baskin.Name)" })[0].madde_no)"
    metin=$coz.metin; ornekIdler=@($g.Group | Where-Object { "$($_.kaynak)" -eq "$($baskin.Name)" } | Select-Object -First 3 | ForEach-Object { "$($_.id)" })
  })
}

Write-Host ''
Write-Host '======== SECILEN KONULAR ========'
foreach($a in $adaylar){ Write-Host ("  {0,5} soru  {1} / {2}   [{3}  baskin %{4}]" -f $a.soru,$a.ders,$a.konu,$a.kaynak,$a.baskinOran) }
if($atlanan.Count){
  Write-Host ''
  Write-Host ('ATLANAN (ilk 8) — kaynak cozulemedi ya da etiket zayif:')
  foreach($x in ($atlanan | Select-Object -First 8)){ Write-Host ("  {0,5} soru  {1} / {2}   -> {3}" -f $x.soru,$x.ders,$x.konu,$x.sebep) }
}

if($olcum){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; secilen=$adaylar.Count
    atlanan=$atlanan.Count; konular=@($adaylar | ForEach-Object { [ordered]@{ ders=$_.ders; konu=$_.konu; soru=$_.soru; kaynak=$_.kaynak } })
    atlananlar=@($atlanan | Select-Object -First 40) })
  Write-Host ''
  Write-Host 'OLCUM MODU — hicbir istek atilmadi, 0 USD harcandi.'
  Write-Host "-> veri/sema-uret-raporu.json"
  exit 0
}

if(-not $env:ANTHROPIC_API_KEY){ Write-Host 'ANTHROPIC_API_KEY yok - uretim yapilamaz.'; exit 1 }

# --- örnek soruların tam metnini çek
function SoruCek([string[]]$idler){
  if(-not $idler.Count){ return @() }
  $liste = ($idler | ForEach-Object { '"' + $_ + '"' }) -join ','
  $b = $hc.GetStringAsync("$U`?select=id,soru,siklar,dogru&id=in.($liste)").GetAwaiter().GetResult()
  return @(($b | ConvertFrom-Json) | ForEach-Object { $_ })
}

# --- ÇIKTI SÖZLEŞMESİ (yapılandırılmış çıktı). Model bu şemanın dışına
#     çıkamaz; 300'e büyüdüğünde tek bozuk JSON partiyi çöpe atmasın diye.
# 25.08 ÖLÇÜM BULGUSU — KAPI GÜÇLENDİRİLDİ:
#   Ölçüm modu para harcamadan şunu gösterdi: "trend analizi" konusunun 216
#   sorusunun %100'ü VUK m.275'e (imal edilen emtia maliyeti) bağlı; "gug
#   yukleme orani" 182 soru TTK m.516'ya (AŞ yıllık faaliyet raporu) bağlı.
#   İkisinin de konuyla ilgisi YOK. Baskınlık %100 çünkü hepsi TUTARLI BİÇİMDE
#   YANLIŞ. Yani baskınlık kapısı tutarlılığı ölçüyor, doğruluğu değil.
#   ÇÖZÜM: modele önce "bu madde bu konuyu kapsıyor mu?" diye sorulur.
#   Kapsamıyorsa ŞEMA ÜRETİLMEZ - yanlış şema yanlış sorudan kötüdür, çünkü
#   tek şema o konudaki 216 sorunun hepsine dağılır.
#   YAN KAZANÇ: bu hat aynı zamanda kasadaki yanlış kaynak bağlarını da
#   bulur - ayrı bir denetim partisi gerekmez.
#   BİÇİM NOTU (25.08, sunucudan öğrenildi): yapılandırılmış çıktıda HER iç
#   nesnede de additionalProperties=false zorunlu. Bu yüzden serbest anahtarlı
#   nesne (örn. sik_yolu'nun anahtarları soru kimlikleri) KULLANILAMAZ.
#   Çözüm: sözleşme DÜZLEŞTİRİLDİ - her şey tanımlı alan ya da dizi. sema.js'in
#   beklediği biçime çeviriyi BİZ yapıyoruz; çeviri sırasında ikinci bir
#   doğrulama daha kazanılıyor.
function Nesne($gerekli, $ozellik){ return @{ type='object'; additionalProperties=$false; required=$gerekli; properties=$ozellik } }
$Metin = @{ type='string' }
$semaSema = Nesne @('kaynak_konuyu_kapsiyor','gerekce','tip','baslik','dugumler','baglar','formul','zincir','sik_yolu') ([ordered]@{
  kaynak_konuyu_kapsiyor = @{ type='boolean' }
  gerekce  = $Metin
  tip      = @{ type='string'; enum=@('akis','formul','zincir','yok') }
  baslik   = $Metin
  dugumler = @{ type='array'; items=(Nesne @('id','tip','metin','alt') ([ordered]@{
                 id=$Metin; tip=@{ type='string'; enum=@('baslangic','karar','sonuc') }; metin=$Metin; alt=$Metin })) }
  baglar   = @{ type='array'; items=(Nesne @('a','b') ([ordered]@{ a=$Metin; b=$Metin })) }
  formul   = Nesne @('sonuc','pay','payda','ornek_pay','ornek_payda','ornek_sonuc','aciklama') ([ordered]@{
                 sonuc=$Metin; pay=$Metin; payda=$Metin; ornek_pay=$Metin; ornek_payda=$Metin; ornek_sonuc=$Metin; aciklama=$Metin })
  zincir   = @{ type='array'; items=(Nesne @('kod','ad') ([ordered]@{ kod=$Metin; ad=$Metin })) }
  sik_yolu = @{ type='array'; items=(Nesne @('soru_id','A','B','C','D','E') ([ordered]@{
                 soru_id=$Metin; A=$Metin; B=$Metin; C=$Metin; D=$Metin; E=$Metin })) }
})

$ISTEM_BAS = @'
Bir muhasebe meslek sınavı (SGS/SMMM/KGK) soru bankası için KONU ŞEMASI tasarlıyorsun.
Şema, o konudaki BÜTÜN sorularda gösterilecek; öğrenci soruyu yanlış yaptığında kuralın
NEREDE ÇATALLANDIĞINI görecek.

ÖNCE ŞU SORUYA CEVAP VER — hepsinden önemlisi budur:
Aşağıdaki MADDE METNİ, verilen KONU'yu gerçekten kapsıyor mu?
Kasada kaynak bağları bozuk olabilir (ölçüldü: "trend analizi" soruları imal edilen
emtia maliyeti maddesine bağlanmış). Metin konuyu KAPSAMIYORSA:
  kaynak_konuyu_kapsiyor = false, gerekce = tek cümle, tip = "yok", yapi = {}, sik_yolu = {}
ve BAŞKA HİÇBİR ŞEY ÜRETME. Hafızandan doğru kuralı yazıp şema çizme — bu, yanlışı
doğru gibi göstermek olur ve tek şema o konudaki yüzlerce soruya birden dağılır.

KAPSAMA ÖLÇÜTÜ (kesin): madde, konunun YÖNTEMİNİ/TEKNİĞİNİ düzenliyor mu?
Kavramdan söz etmesi YETMEZ. Örnek: VUK m.275 "genel üretim giderleri maliyete
girer" der; ama GÜG YÜKLEME KATSAYISININ nasıl hesaplanacağını düzenlemez —
o bir maliyet muhasebesi tekniğidir. Böyle bir durumda kapsıyor DEME.
Emin değilsen kapsamıyor de; eksik şema, yanlış şemadan iyidir.

PAZARLIKSIZ KURALLAR (yalnız kapsıyorsa)
1. YALNIZ aşağıdaki madde metnine dayan. Metinde olmayan kuralı yazma, hafızandan tamamlama.
2. SVG YAZMA. Yalnız yapıyı (kutular ve bağlar) tarif et; çizimi biz yapıyoruz.
3. Kanun cümlesini kopyalama; hiç bilmeyen birinin anlayacağı sade Türkçe yaz.
4. MADDE ATFI: sonuç kutularında dayanak maddeye atıf yap — AMA FIKRA/BENT NUMARASI
   YAZMA. Sana verilen metin fıkra numarası taşımıyorsa, fıkra numarasını
   HAFIZANDAN yazmış olursun ve bu yasaktır. Yalnız "m.11" yaz, "m.11/2" YAZMA.
   (Ölçüldü: bir önceki koşuda model m.11/3 ve m.11/4 yazdı; doğrusu m.11/2 ve
   m.11/3 idi, üstelik o maddede 4. fıkra hiç yok.)
5. Yasak kalıplar: "bu bağlamda", "önemli bir husus", "unutulmamalıdır ki", "sonuç olarak".
6. Metin sınırı: kutu başlığı en çok 55 karakter, alt satır en çok 65 karakter. Aşarsan kutudan taşar.

TİP SEÇİMİ
- "akis"   : koşul/sonuç zinciri (hukuk, denetim görüşü, tacir sıfatı). 3-6 düğüm.
             "dugumler" ve "baglar" doldurulur. baglar = [{"a":"n1","b":"n2"}, ...]
             Düğüm tipi: baslangic (giriş), karar (koşul), sonuc (hukuki sonuç).
             "alt" alanı boş bırakılabilir ama ALAN YİNE DE YAZILIR ("" olarak).
- "formul" : hesap kuralı (oran analizi, maliyet formülü). "formul" nesnesi doldurulur.
- "zincir" : hesap akışı (THP). "zincir" dizisi doldurulur, örn. {"kod":"150","ad":"İlk Madde ve Malzeme"}.

HER ALAN HER ZAMAN YAZILIR. Kullanmadığın alanları boş bırak:
kullanılmayan dizi = [], kullanılmayan metin = "". Alanı atlamak hata verir.

ŞIK YOLU
Her örnek soru için ayrı bir kayıt: {"soru_id":"...","A":"n5","B":"yok","C":"n4","D":"n4","E":"n5"}
Değer, şıkkın şemada düştüğü DÜĞÜM KİMLİĞİdir.
Şıkkın iddiasının şemada karşılığı YOKSA (kanun öyle bir sonuç öngörmüyorsa) "yok" yaz.
tip "formul" veya "zincir" ise düğüm yoktur; o zaman şık yolu için "dogru" / "yanlis" yaz.
'@

$sonuc = New-Object System.Collections.Generic.List[object]
$topGiris = 0; $topCikis = 0; $basarisiz = 0
$AH = @{ 'x-api-key'=$env:ANTHROPIC_API_KEY; 'anthropic-version'='2023-06-01' }

foreach($a in $adaylar){
  Write-Host ''
  Write-Host ("URETILIYOR: {0} / {1}  ({2} soru)" -f $a.ders,$a.konu,$a.soru)
  $ornekler = SoruCek $a.ornekIdler
  $ornekMetin = ''
  foreach($o in $ornekler){
    $ornekMetin += "`n--- SORU id=$($o.id)`n$($o.soru)`n"
    foreach($hx in 'A','B','C','D','E'){ $ornekMetin += "  $hx) $($o.siklar.$hx)`n" }
    $ornekMetin += "  DOGRU: $($o.dogru)`n"
  }
  # Madde metni uzunsa BAŞTAN kırpma - 19.08 dersi: mevzuatta geçiş/yürürlük
  # hükümleri HEP SONDADIR. Aşarsa baş %65 + son %35 gönderilir.
  $mtn = "$($a.metin)"
  if($mtn.Length -gt 24000){
    $bas = [int]($mtn.Length*0.0); $mtn = $mtn.Substring(0,15600) + "`n[...orta atlandi...]`n" + $mtn.Substring($mtn.Length-8400)
  }
  $istem = $ISTEM_BAS + "`n`nDERS: $($a.ders)`nKONU: $($a.konu)`nDAYANAK: $($a.kaynak)`n`n=== MADDE METNI ===`n$mtn`n`n=== BU KONUDAN ORNEK SORULAR ===$ornekMetin"

  $govde = @{
    model = $model
    max_tokens = 4000
    messages = @(@{ role='user'; content=$istem })
    output_config = @{ format = @{ type='json_schema'; schema=$semaSema } }
  } | ConvertTo-Json -Depth 12

  # 25.08 KUSUR VE DUZELTMESI: burada Invoke-RestMethod vardi ve PS 5.1'in IRM'i
  # Anthropic cevabini LATIN-1 sanip cozuyordu -> "iş sözleşmesi" yerine
  # "iÅ sÃ¶zleÅmesi". Bu YALNIZ EKRAN kusuru DEGILDI: bozuk metin dosyaya ve
  # oradan kasaya yazilacakti. Sema, sorudan daha gorunur bir icerik oldugu icin
  # bozuk Turkce en cok orada batardi. Cozum: HttpClient ile AÇIKÇA UTF-8 oku.
  # Bkz [[turkce-harf-bozulmasi]] - kasada 288 soruda ayni sinif kusur var.
  $j = $null; $deneme = 0
  while($deneme -lt 2 -and $null -eq $j){
    $deneme++
    try {
      $ic = New-Object System.Net.Http.StringContent($govde, [Text.Encoding]::UTF8, 'application/json')
      $ist = New-Object System.Net.Http.HttpRequestMessage('POST','https://api.anthropic.com/v1/messages')
      $ist.Content = $ic
      $ist.Headers.Add('x-api-key', $env:ANTHROPIC_API_KEY)
      $ist.Headers.Add('anthropic-version','2023-06-01')
      $yanit = $hc.SendAsync($ist).GetAwaiter().GetResult()
      $bayt  = $yanit.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
      $ham   = [Text.Encoding]::UTF8.GetString($bayt)
      if(-not $yanit.IsSuccessStatusCode){
        Write-Host ("  HATA {0}: {1}" -f [int]$yanit.StatusCode, $ham.Substring(0,[Math]::Min(300,$ham.Length)))
        break
      }
      $cv = $ham | ConvertFrom-Json
      $topGiris += [int]$cv.usage.input_tokens
      $topCikis += [int]$cv.usage.output_tokens
      $metin = ($cv.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1).text
      try { $j = $metin | ConvertFrom-Json }
      catch {
        # Yapilandirilmis cikti JSON garantiler ama uc kesilmesi (max_tokens)
        # yine de bozabilir. Tek tekrar hakki - ikisi de duserse bilerek atlanir.
        Write-Host ("  JSON ayristirilamadi (deneme {0}/2) - stop_reason={1}" -f $deneme, $cv.stop_reason)
      }
    } catch {
      Write-Host ("  HATA: {0}" -f $_.Exception.Message)
      break
    }
  }
  if($null -eq $j){ $basarisiz++; continue }

  # --- KAYNAK-KONU KAPISI (asıl kapı): metin konuyu kapsamıyorsa şema YOK.
  #     Bu bir kayıp değil BULGU - kasadaki yanlış kaynak bağını yakalar.
  if(-not $j.kaynak_konuyu_kapsiyor){
    Write-Host ("  KAYNAK-KONU UYUMSUZ -> sema uretilmedi. Gerekce: {0}" -f $j.gerekce)
    $sonuc.Add([ordered]@{
      ders=$a.ders; konu=$a.konu; sinav=$a.sinav; soruSayisi=$a.soru
      durum='kaynak-konu-uyumsuz'; gerekce="$($j.gerekce)"
      dayanak=$a.kaynak; kanun_no=$a.kanun_no; madde_no=$a.madde_no
      etkilenen_soru=$a.soru })
    continue
  }

  # --- DÜZ SÖZLEŞMEYİ sema.js BİÇİMİNE ÇEVİR (çeviri = ikinci doğrulama)
  $kusur = @()
  $yapi = $null
  if($j.tip -eq 'akis'){
    $yapi = [ordered]@{ tip='akis'
      dugumler = @($j.dugumler | ForEach-Object { $d=[ordered]@{ id="$($_.id)"; tip="$($_.tip)"; metin="$($_.metin)" }
                                                  if("$($_.alt)".Trim()){ $d['alt']="$($_.alt)" }; $d })
      baglar   = @($j.baglar   | ForEach-Object { ,@("$($_.a)","$($_.b)") }) }
  } elseif($j.tip -eq 'formul'){
    $yapi = [ordered]@{ tip='formul'; sonuc="$($j.formul.sonuc)"; pay="$($j.formul.pay)"; payda="$($j.formul.payda)" }
    if("$($j.formul.ornek_sonuc)".Trim()){ $yapi['ornek']=[ordered]@{ pay="$($j.formul.ornek_pay)"; payda="$($j.formul.ornek_payda)"; sonuc="$($j.formul.ornek_sonuc)" } }
    if("$($j.formul.aciklama)".Trim()){ $yapi['not']="$($j.formul.aciklama)" }
  } elseif($j.tip -eq 'zincir'){
    $yapi = [ordered]@{ tip='zincir'; adimlar=@($j.zincir | ForEach-Object { [ordered]@{ kod="$($_.kod)"; ad="$($_.ad)" } }) }
  } else { $kusur += "tip-gecersiz:$($j.tip)" }

  # --- DETERMINISTIK KAPI: model ne derse desin, yapı tutarlı değilse kabul edilmez
  if($j.tip -eq 'akis'){
    $ids = @($yapi.dugumler | ForEach-Object { $_.id })
    if($ids.Count -lt 2){ $kusur += 'dugum-az' }
    if($ids.Count -gt 8){ $kusur += "dugum-cok:$($ids.Count)" }
    if(($ids | Select-Object -Unique).Count -ne $ids.Count){ $kusur += 'dugum-id-mukerrer' }
    foreach($b in @($yapi.baglar)){
      if($ids -notcontains $b[0] -or $ids -notcontains $b[1]){ $kusur += "bag-bosluga:$($b[0])->$($b[1])" }
    }
    if(-not @($yapi.dugumler | Where-Object { $_.tip -eq 'sonuc' }).Count){ $kusur += 'sonuc-dugumu-yok' }
    foreach($d in @($yapi.dugumler)){
      if("$($d.metin)".Length -gt 55){ $kusur += "baslik-uzun($($d.id)):$("$($d.metin)".Length)" }
      if("$($d.alt)".Length -gt 65){ $kusur += "alt-uzun($($d.id)):$("$($d.alt)".Length)" }
    }
  } elseif($j.tip -eq 'zincir'){
    if(@($yapi.adimlar).Count -lt 2){ $kusur += 'zincir-adim-az' }
  } elseif($j.tip -eq 'formul'){
    if(-not "$($yapi.pay)".Trim() -or -not "$($yapi.payda)".Trim()){ $kusur += 'formul-eksik' }
  }

  # --- FIKRA ATFI KAPISI (25.08, pilot bulgusu — deterministik)
  #     Model İş K. m.11 için "m.11/3" ve "m.11/4" yazdı; ambardaki metin fıkra
  #     numarası TAŞIMIYOR (tek paragraf), doğrusu m.11/2 ve m.11/3 ve o maddede
  #     4. fıkra hiç yok. Yani numaralar HAFIZADAN geldi.
  #     Kural: kaynak metninde fıkra numaralandırması yoksa, çıktıda "m.X/Y"
  #     biçiminde atıf OLAMAZ. Bu kapı modelin iyi niyetine bakmaz, metne bakar.
  $fikraliMi = ("$($a.metin)" -match '(?m)^\s*\(\d{1,2}\)' ) -or ("$($a.metin)" -match '(?m)^\s*\d{1,2}\)\s')
  if(-not $fikraliMi){
    $tumMetin = @()
    if($yapi.dugumler){ foreach($d in $yapi.dugumler){ $tumMetin += "$($d.metin) $($d.alt)" } }
    if($yapi.not){ $tumMetin += "$($yapi.not)" }
    $tumMetin += "$($j.baslik)"
    foreach($t in $tumMetin){
      foreach($m in [regex]::Matches("$t",'(?i)\bm(?:adde)?\.?\s*\d{1,4}\s*/\s*\d{1,2}')){
        $kusur += "fikra-atfi-uydurma: $($m.Value)  (kaynak metninde fikra numarasi YOK)"
      }
    }
  }

  # --- şık yolu: dizi -> {soru_id:{A..E}} ve geçerlilik denetimi
  $gecerli = @($yapi.dugumler | ForEach-Object { $_.id }) + @('yok','dogru','yanlis')
  $sikYolu = [ordered]@{}
  foreach($sy in @($j.sik_yolu)){
    $hx = [ordered]@{}
    foreach($harf in 'A','B','C','D','E'){
      $v = "$($sy.$harf)"
      if($gecerli -notcontains $v){ $kusur += "sik-yolu-gecersiz $($sy.soru_id).$harf=$v" }
      $hx[$harf] = $v
    }
    # ÜCRETSİZ KALİTE ÖLÇÜSÜ: beş şıkkın üçü birden "yok" ise soru şüphelidir.
    $yokSay = @($hx.Values | Where-Object { $_ -eq 'yok' }).Count
    if($yokSay -ge 3){ $kusur += "soru-supheli($($sy.soru_id)): $yokSay sik semada YOK" }
    $sikYolu["$($sy.soru_id)"] = $hx
  }
  if($kusur.Count){ Write-Host ("  KAPI KUSURU: {0}" -f ($kusur -join ' | ')) }
  else { Write-Host '  kapi temiz' }

  $sonuc.Add([ordered]@{
    ders=$a.ders; konu=$a.konu; sinav=$a.sinav; soruSayisi=$a.soru
    durum='uretildi'
    tip="$($j.tip)"; baslik="$($j.baslik)"; yapi=$yapi; sik_yolu=$sikYolu
    dayanak=$a.kaynak; kanun_no=$a.kanun_no; madde_no=$a.madde_no
    son_kontrol=(Get-Date -Format 'dd.MM.yyyy'); uretim=$model
    kapi_kusuru=$kusur; ornek_idler=$a.ornekIdler
  })
}

$uretilen  = @($sonuc | Where-Object { $_.durum -eq 'uretildi' })
$uyumsuzlar = @($sonuc | Where-Object { $_.durum -eq 'kaynak-konu-uyumsuz' })

# --- GERÇEK FATURA (tahmin değil, sunucunun bildirdiği jeton)
# Sonnet 5 tanıtım fiyatı 31.08.2026'ya kadar 2/10 USD-M; sonra 3/15.
$TANITIM_SON = [datetime]'2026-08-31'
if((Get-Date) -le $TANITIM_SON -and $model -like 'claude-sonnet-5*'){ $fg=2.0; $fc=10.0; $fnot='tanitim' } else { $fg=3.0; $fc=15.0; $fnot='liste' }
$usd = ($topGiris/1e6*$fg) + ($topCikis/1e6*$fc)

$ciktiYol = Join-Path $kok 'veri/fabrika/sema-pilot.json'
$null = New-Item -ItemType Directory -Force (Split-Path $ciktiYol)
[IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject $sonuc -Depth 12), (New-Object Text.UTF8Encoding($false)))

Write-Host ''
Write-Host '======== SONUC ========'
Write-Host ("  URETILEN SEMA        : {0} / {1}   (basarisiz {2})" -f $uretilen.Count,$adaylar.Count,$basarisiz)
Write-Host ("  KAYNAK-KONU UYUMSUZ  : {0}   <- BULGU, kayip degil" -f $uyumsuzlar.Count)
if($uyumsuzlar.Count){
  # OrderedDictionary uzerinde Measure-Object -Property calismaz (PS 5.1) - elle topla
  $etki = 0; foreach($x in $uyumsuzlar){ $etki += [int]$x.etkilenen_soru }
  Write-Host ("  bunlarin etkiledigi soru: {0}" -f $etki)
  foreach($x in $uyumsuzlar){ Write-Host ("    {0,5} soru  {1} / {2}`n           {3}`n           -> {4}" -f $x.etkilenen_soru,$x.ders,$x.konu,$x.dayanak,$x.gerekce) }
}
Write-Host ''
Write-Host '======== FATURA (gercek, sunucudan) ========'
Write-Host ("  giris token   : {0:N0}" -f $topGiris)
Write-Host ("  cikis token   : {0:N0}" -f $topCikis)
Write-Host ("  fiyat         : {0}/{1} USD-M ({2})" -f $fg,$fc,$fnot)
Write-Host ("  TUTAR         : {0:N4} USD   (konu basina {1:N4})" -f $usd, $(if($sonuc.Count){$usd/$sonuc.Count}else{0}))
Write-Host ("  300 konu icin tahmin: ~{0:N2} USD" -f $(if($sonuc.Count){ $usd/$sonuc.Count*300 }else{0}))
Write-Host ''
Write-Host "-> veri/fabrika/sema-pilot.json"

RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='URETILDI'; model=$model
  uretilen=$uretilen.Count; kaynak_konu_uyumsuz=$uyumsuzlar.Count; basarisiz=$basarisiz; atlanan=$atlanan.Count
  fatura=[ordered]@{ giris=$topGiris; cikis=$topCikis; usd=[math]::Round($usd,4); fiyat="$fg/$fc ($fnot)"; konu_basina=[math]::Round($(if($sonuc.Count){$usd/$sonuc.Count}else{0}),4) }
  uyumsuzlar=@($uyumsuzlar | ForEach-Object { [ordered]@{ ders=$_.ders; konu=$_.konu; dayanak=$_.dayanak; etkilenen_soru=$_.etkilenen_soru; gerekce=$_.gerekce } })
  kapi_kusurlu=@($uretilen | Where-Object { $_.kapi_kusuru.Count } | ForEach-Object { [ordered]@{ konu=$_.konu; kusur=$_.kapi_kusuru } }) })

if($yaz){
  Write-Host ''
  Write-Host 'Supabase yazimi deneniyor...'
  $t = $hc.GetAsync('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/konu_semasi?select=id&limit=1').GetAwaiter().GetResult()
  if([int]$t.StatusCode -eq 404){
    Write-Host '  konu_semasi TABLOSU YOK. radar-app/sql/2026-08-25-konu-semasi.sql Supabase SQL editorunde calistirilmali.'
    Write-Host '  Semalar yerel dosyada duruyor - kayip yok, tablo acilinca -yaz ile yuklenir.'
  } else {
    $kayitlar = @($uretilen | ForEach-Object { [ordered]@{
      sinav=$_.sinav; ders=$_.ders; konu=$_.konu; tip=$_.tip; baslik=$_.baslik; yapi=$_.yapi
      dayanak=$_.dayanak; kanun_no=$_.kanun_no; madde_no=$_.madde_no; uretim=$_.uretim; yayin=$false } })
    $g = ConvertTo-Json -InputObject $kayitlar -Depth 12
    $c = New-Object System.Net.Http.StringContent($g,[Text.Encoding]::UTF8,'application/json')
    $c.Headers.Add('Prefer','resolution=merge-duplicates')
    $w = $hc.PostAsync('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/konu_semasi',$c).GetAwaiter().GetResult()
    Write-Host ("  yazim: {0}" -f [int]$w.StatusCode)
  }
}
