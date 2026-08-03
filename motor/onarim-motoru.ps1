# ============================================================================
#  ONARIM MOTORU (02.08.2026) — SINAV-KURALLARI D1/D2/D7/D8 tamamlayicisi
#  Sartname: ONARIM-MOTOR-SARTNAMESI.md (bu gecenin TUM kararlari orada)
#
#  CEM'IN KURALI: "parali islemi bir kez calistirip birakalim" + "tekrar tekrar
#  yapmayalim". Bu yuzden motor bir soruyu ACAR ve EKSIK OLAN NE VARSA HEPSINI
#  AYNI CAGRIDA uretir. Bir soruya BIR KEZ dokunulur.
#
#  UC MOD:
#   (varsayilan) KURU  : 0 USD. Kimin neyi eksik oldugunu sayar, ORNEK ISTEMLERI
#                        dosyaya yazar. Hicbir API cagrisi YOK. Gozle kontrol icin.
#   -uygula -sinir N   : PARALI pilot. N soru islenir, GERCEK FATURA olculur.
#   -uygula            : PARALI tam parti (Cem'in acik "bas"i olmadan kosulmaz).
#
#  KIRMIZI CIZGILER (sartname 3):
#   - Dayanak metni COZULEMEYEN soru ATLANIR, uydurulmaz (D4).
#   - Zaten TAM olan madde uretilmez (hem para hem kalite kaybi).
#   - Yazma PATCH ile (kismi upsert NOT NULL duvarina carpar - 27.07 dersi).
#   - Yazilan her soru GERI OKUNUR; dogrulanmayan "yapildi" sayilmaz.
#   - Her kosu rapor yazar (kor kalma): islenen/yazilan/dogrulanan/atlanan+sebep.
#
#  ENV: SUPABASE_SERVICE_KEY (+ -uygula icin ANTHROPIC_API_KEY)
#  Cikti: veri/onarim-motor-raporu.json · veri/onarim-motor-ornek-istem.txt
# ============================================================================
param(
  [switch]$uygula,
  [int]$sinir = 0,
  [string]$model = 'claude-haiku-4-5-20251001'
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/onarim-motor-raporu.json'
$ornekYol = Join-Path $kok 'veri/onarim-motor-ornek-istem.txt'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$DK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

# Ham JSON ile cek: IRM diziyi bozup tek nesne verebiliyor (bu gece 2 kez yandik)
# ============================================================================
#  RAPOR SIZINTI SIGORTASI — 03.08 sabahi kondu, sebebi acikca sudur:
#
#  $etiketAdi'nin eski adi $PARTI idi; 200 soruluk dizinin adi da $parti.
#  PowerShell degisken adlarinda BUYUK/KUCUK HARF AYIRMAZ - ikisi ayni degisken
#  cikti, dizi adin uzerine yazdi ve raporun "parti" alanina 200 PARALI SORUNUN
#  TAM METNI dokuldu. Rapor public depoya commit edilir; sizinti oradan gitti.
#
#  Ad cakismasi duzeltildi ama bu YETMEZ: baska bir yanlisla ayni sey tekrar
#  olabilir. Bu yuzden rapor artik TEK KAPIDAN yazilir ve o kapi olcer:
#  rapor 20 KB'i asiyorsa icinde olmamasi gereken bir sey vardir - icerik
#  yazilmaz, yerine KIRMIZI uyari yazilir. Kucuk ve sayisal kalmak zorunda.
# ============================================================================
function RaporYaz($nesne){
  $j = ConvertTo-Json -InputObject $nesne -Depth 6
  if($j.Length -gt 20480){
    Write-Host ("!! RAPOR SISMIS ({0} bayt) - icerik sizmis olabilir, YAZILMADI." -f $j.Length)
    $j = ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
      tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI - RAPOR SISMIS'
      boyut_bayt=$j.Length
      sebep='Rapor 20 KB siniri asti. Raporda yalniz SAYI olur; bu buyukluk soru metni sizdigi anlamina gelir.'
      yapilacak='Rapor uretimindeki alan adlarini denetle (PS degisken adlari buyuk/kucuk harf ayirmaz).' })
  }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}

function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye,kaynak&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa beklenenden kucuk - sayfalama kirik olabilir." }

# --- sozlesme denetleyicileri (aciklama-sozlesme-olcum.ps1 ile AYNI desenler) ---
$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak=[regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'; $reDogrusu=[regex]'(?i)do[ğg]rusu\s*:'
$reHesapli=[regex]'(?i)ka[çc]\s*TL|ne\s+kadar|hesapla|tutar[ıi]n[ıi]|maliyet bedeli|amortisman|toplam[ıi]'
$reKayit=[regex]'(?i)yevmiye|kay[ıi]t|kaydeder|muhasebele[şs]tir|bor[çc]land|alacakland'
$reKarsi=[regex]'(?i)hangisi\s+do[ğg]rudur|a[şs]a[ğg][ıi]dakilerden\s+hangisi'
function Dolu($v){ if($null -eq $v){ return $false }; $s="$v"; if($s.Trim().Length -lt 5){ return $false }; return ($s -ne '{}' -and $s -ne '[]' -and $s -ne 'null') }

# --- her soru icin EKSIK LISTESI cikar ---
$isler = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $a = $s.aciklama; if($null -eq $a){ continue }
  $dh = "$($s.dogru)".Trim().ToUpper()
  $dm = ""; try { if($a.PSObject.Properties[$dh]){ $dm = "$($a.$dh)" } } catch {}
  $eksik = @()
  $p = 0
  if($reNe.IsMatch($dm)){$p++}; if($reKural.IsMatch($dm)){$p++}
  if($reOlay.IsMatch($dm)){$p++}; if($reAkil.IsMatch($dm)){$p++}
  if($p -lt 4){ $eksik += 'D1_dort_parca' }
  $tz=0; $dg=0
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dh){ continue }
    $m=""; try { if($a.PSObject.Properties[$h]){ $m="$($a.$h)" } } catch {}
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){$tz++}; if($reDogrusu.IsMatch($m)){$dg++}
  }
  if($tz -lt 3){ $eksik += 'D2_tuzak' }
  if($dg -lt 3){ $eksik += 'D2_dogrusu' }
  $gv = "$($s.soru)"
  if($reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D7_tablo' }
  if($reKayit.IsMatch($gv)   -and -not (Dolu $s.yevmiye)){ $eksik += 'D7_yevmiye' }
  if($reKarsi.IsMatch($gv) -and -not $reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D8_karsilastirma' }
  if($eksik.Count -eq 0){ continue }
  $isler.Add([pscustomobject]@{ soru=$s; eksik=$eksik })
}
Write-Host ("Eksigi olan soru: {0}" -f $isler.Count)

# --- DAYANAK KAPISI (D4): kaynak metni ambarda yoksa soru ATLANIR ---
# Uydurma kanun/oran yasak; "Dogrusu" yalniz dayanak metninden turetilir.
#
# 02.08 GECE - IKI KUSUR DUZELTILDI (kuru kosu 8.098 soruyu haksiz atlamisti):
#
# KUSUR 1 - MEVZUAT DISI DERSLER. Kuru kosunun atlananlari arasinda "Prepositions
# of Time (in/on/at)", "Unless sart baglaci", "lend-borrow ayrimi", "TDK cumle
# ogeleri" vardi. Yabanci Dil / Turkce / Matematik sorularinin mevzuat dayanagi
# YOKTUR - olamaz da. Bunlar artik dayanak aranmadan gecer; istem karsiliginda
# "bu bir dil/beceri sorusu, HICBIR kanun/madde/oran atfi yapamazsin" der.
# Boylece uydurma riski kapali kalir ama soru cope gitmez.
#
# KUSUR 2 - ETIKETIN TAMAMIYLA ARAMA. "TMS 1 Finansal Tablolarin Sunulusu, m.38
# (Karsilastirmali Bilgi ilkesi)" etiketi ambarda birebir boyle gecmez, bu yuzden
# ilike bos donuyordu. Artik once tam etiket, olmazsa etiketten cikarilan
# STANDART/KANUN KODU ("TMS 1", "BDS 230", "TTK 474", "6362") aranir.
$reDilDers = [regex]'(?i)yabanc[ıi]\s*dil|ingiliz|t[üu]rk[çc]e|matematik|atat[üu]rk|inkil[âa]p|genel\s*k[üu]lt[üu]r'
$reKod = [regex]'(?i)\b(TMS|TFRS|BDS|KKS|TSRS|SGDS|VUK|TTK|TBK|GVK|KVK|KDVK|AATUHK|SMK|[İI][İI]K|MSUGT|THP)\s*(GT\s*)?(\d{1,4})?'
$reSayiliK = [regex]'(?i)\b(\d{4})\s*say[ıi]l[ıi]'
$atlanan = New-Object System.Collections.Generic.List[object]
$hazir   = New-Object System.Collections.Generic.List[object]
$dilSoru = 0
$dayanakOnbellek = @{}
foreach($i in $isler){
  $kay = "$($i.soru.kaynak)".Trim()
  $ders = "$($i.soru.ders)"

  # --- mevzuat disi ders: dayanak aranmaz, ama kanun atfi da YASAK ---
  if($reDilDers.IsMatch($ders)){
    $i | Add-Member -NotePropertyName dayanak -NotePropertyValue '' -Force
    $i | Add-Member -NotePropertyName mevzuatdisi -NotePropertyValue $true -Force
    $hazir.Add($i); $dilSoru++
    if($sinir -gt 0 -and $hazir.Count -ge $sinir){ break }
    continue
  }

  if($kay.Length -lt 6){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep='kaynak etiketi yok' }); continue }
  if(-not $dayanakOnbellek.ContainsKey($kay)){
    $metin = ''
    # 1) tam etiket
    $arama = [Uri]::EscapeDataString(($kay -replace '\s+',' '))
    try {
      $bul = CekListe "$DK`?select=metin&kaynak_ad=ilike.*$arama*&limit=1"
      if($bul.Count -gt 0){ $metin = "$($bul[0].metin)" }
    } catch {}
    # 2) olmazsa etiketten cikarilan standart/kanun kodu
    if($metin.Length -lt 40){
      $kod = ''
      $m = $reKod.Match($kay)
      if($m.Success){ $kod = (($m.Groups[1].Value + ' ' + $m.Groups[3].Value).Trim()) }
      if($kod -eq ''){ $m2 = $reSayiliK.Match($kay); if($m2.Success){ $kod = $m2.Groups[1].Value } }
      if($kod -ne ''){
        $a2 = [Uri]::EscapeDataString($kod)
        try {
          $b2 = CekListe "$DK`?select=metin&kaynak_ad=ilike.*$a2*&limit=1"
          if($b2.Count -gt 0){ $metin = "$($b2[0].metin)" }
        } catch {}
      }
    }
    $dayanakOnbellek[$kay] = $metin
  }
  $metin = $dayanakOnbellek[$kay]
  if($metin.Length -lt 40){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep="dayanak ambarda cozulemedi: $kay" }); continue }
  $i | Add-Member -NotePropertyName dayanak -NotePropertyValue $metin -Force
  $i | Add-Member -NotePropertyName mevzuatdisi -NotePropertyValue $false -Force
  $hazir.Add($i)
  if($sinir -gt 0 -and $hazir.Count -ge $sinir){ break }
}
Write-Host ("Mevzuat disi ders (dayanak aranmadan gecen): {0}" -f $dilSoru)
Write-Host ("Islenebilir: {0} | Atlanan (dayanaksiz): {1}" -f $hazir.Count, $atlanan.Count)

# --- ISTEM KURUCU: yalniz EKSIK olanlari ister ---
function IstemKur($i){
  $s = $i.soru
  $sik = ""
  foreach($h in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$h]){ $sik += "$h) $($s.siklar.$h)`n" } }
  $ist = @()
  if($i.eksik -contains 'D1_dort_parca'){ $ist += 'dort_parca: dogru sikkin aciklamasini SU DORT BASLIKLA yeniden yaz: "Ne soruluyor:", "Kural:", "Bu olayda:", "Akilda kalsin:". 400-700 karakter, gunluk dil, hic muhasebe bilmeyene anlatir gibi.' }
  if($i.eksik -contains 'D2_tuzak'){    $ist += 'tuzak: her YANLIS sik icin tuzagin ADINI koy — "<A> ile <B> karistiriliyor. <A> sudur; <B> ise budur." Her sik icin FARKLI tuzak; ayni cumle iki sikka yazilamaz. Basina "TUZAK:" yazma, oneki sistem koyar.' }
  # 03.08 - CEM YAKALADI: ilk pilotta dort yanlis sikka da AYNI cumle yazilmisti
  # ("Belirli sureli is sozlesmesi esasli neden olmadikca zincirleme yapilamaz").
  # Bu, D3'un kilik degistirmis hali: "bu sik yanlis cunku dogru cevap D" demenin
  # baska yolu. Ogrenciye A'nin NESI yanlis onu soylemiyor. Istem simdi her sikkin
  # KENDI IDDIASIYLA yuzlesmeyi zorunlu kiliyor ve ayni cumleyi yasakliyor.
  if($i.eksik -contains 'D2_dogrusu'){  $ist += @'
dogrusu: HER YANLIS SIK ICIN AYRI bir duzeltme cumlesi. Kurallar:
  (a) O SIKKIN KENDI IDDIASINI ele al. Once iddianin nereden geldigini soyle
      (hangi baska kuralla karistiriliyor), sonra o iddianin DOGRUSUNU yaz.
  (b) DOGRU CEVABI TEKRAR ETMEK YASAK. "Dogrusu: <sorunun genel kurali>" yazma -
      bu "bu sik yanlis cunku dogru cevap X" demenin gizli halidir, ogretmez.
  (c) IKI SIKKA AYNI CUMLEYI YAZAMAZSIN. Her cumle o sikka OZEL olacak; birini
      digerine kopyalarsan is yanlistir.
  (d) Cumlenin basina "Dogrusu:" YAZMA - yalniz cumleyi ver, oneki sistem koyar.
  ORNEK (soru: zincirleme is sozlesmesinin sarti nedir, dogru cevap "esasli neden"):
    A sikki "yazili onay" diyorsa -> "Yazili sekil sarti ile karistiriliyor; yazili
      sekil sozlesmenin kurulusuna iliskindir, zincirlemenin sarti degildir."
    C sikki "bes yil" diyorsa -> "Bes yillik ust sinir baska bir kuralin suresidir;
      kanun zincirleme icin sure degil esasli neden arar."
  Gorulduğu gibi iki cumle birbirinden FARKLI ve her biri kendi sikkini hedefliyor.
'@ }
  if($i.eksik -contains 'D7_tablo'){    $ist += 'tablo: hesap tablosu uret (kolonlar: kalem, tutar; son satir toplam).' }
  if($i.eksik -contains 'D7_yevmiye'){  $ist += 'yevmiye: yevmiye fisi uret (her satir: hesap adi VE KODU, borc, alacak; borc toplami = alacak toplami).' }
  if($i.eksik -contains 'D8_karsilastirma'){ $ist += 'tablo: karsilastirma tablosu uret (ayrimi yapilan kavramlar satir satir; sorunun konusu olan satiri "<-" ile isaretle).' }
  # --- Mevzuat disi ders (Yabanci Dil / Turkce / Matematik): dayanak metni YOK.
  #     Uydurma riski dayanak yerine YASAKLA kapatilir: hicbir kanun atfi yapamaz. ---
  if($i.mevzuatdisi){
    $kaynakKurali = @"
- Bu bir DIL/BECERI sorusudur; mevzuat dayanagi yoktur. Bu yuzden hicbir kanun,
  madde, teblig, oran veya tutar ATFI YAPAMAZSIN. Kurali dilin kendi kuralı olarak
  yaz (ornek: "Unless = if...not; olumsuz yan cumle kurar"). Emin degilsen bos birak.
"@
    $dayanakBlok = "DAYANAK: (yok - dil/beceri sorusu, kanun atfi yasak)"
  } else {
    $kaynakKurali = @"
- Yazdigin her cumle YALNIZCA asagidaki DAYANAK METNINDEN turetilecek. Dayanakta
  olmayan kanun, madde, oran, tutar veya tarih YAZAMAZSIN. Emin degilsen o alani bos birak.
"@
    $dayanakBlok = "DAYANAK METNI:`n" + $i.dayanak.Substring(0, [Math]::Min(2500, $i.dayanak.Length))
  }
@"
Sen bir SMMM sinav sorusu editorusun. ASAGIDAKI SORUYA YALNIZCA ISTENEN ALANLARI uret.

MUTLAK KURALLAR:
$kaynakKurali- "Bu sik yanlis cunku dogru cevap X" gibi cumle YASAK - ogretmez.
- Var olan dogru metni degistirme; yalnizca istenen alanlari uret.
- Ciktiyi SAF JSON ver, baska hicbir sey yazma.

DERS: $($s.ders) | KONU: $($s.konu)
KAYNAK: $($s.kaynak)

$dayanakBlok

SORU:
$($s.soru)

SIKLAR:
$sik
DOGRU SIK: $($s.dogru)

URETILECEK ALANLAR:
$([string]::Join("`n", ($ist | ForEach-Object { "- $_" })))

CIKTI BICIMI (yalniz istenen anahtarlari doldur):
{"dort_parca":"...","tuzak":{"A":"...","B":"..."},"dogrusu":{"A":"...","B":"..."},"tablo":{"baslik":"...","kolonlar":["..."],"satirlar":[["..."]]},"yevmiye":[{"hesap":"100 KASA","borc":0,"alacak":0}]}
"@
}

# --- KURU MOD: ornek istemleri yaz, para harcama ---
if(-not $uygula){
  $sb = New-Object Text.StringBuilder
  $ornekSayi = [Math]::Min(10, $hazir.Count)
  for($n=0; $n -lt $ornekSayi; $n++){
    [void]$sb.AppendLine("=============== ORNEK $($n+1) / $ornekSayi ===============")
    [void]$sb.AppendLine("SORU ID : $($hazir[$n].soru.id)")
    [void]$sb.AppendLine("EKSIK   : $($hazir[$n].eksik -join ', ')")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((IstemKur $hazir[$n]))
    [void]$sb.AppendLine("")
  }
  Set-Content -LiteralPath $ornekYol -Value $sb.ToString() -Encoding UTF8
  $dagilim = @{}
  foreach($i in $hazir){ foreach($e in $i.eksik){ $dagilim[$e] = 1 + $dagilim[$e] } }
  $rapor = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD)'
    kasa=$kasa.Count; eksigi_olan=$isler.Count; islenebilir=$hazir.Count
    atlanan_dayanaksiz=$atlanan.Count
    mevzuat_disi_gecen=$dilSoru
    eksik_dagilimi=[ordered]@{}
    atlanan_ornek=@($atlanan | Select-Object -First 20)
    not='Hicbir API cagrisi YAPILMADI. veri/onarim-motor-ornek-istem.txt icindeki 10 ornek GOZLE okunacak; Cem onaylayinca -uygula -sinir 200 ile pilot kosulur.'
  }
  foreach($k in ($dagilim.Keys | Sort-Object)){ $rapor.eksik_dagilimi[$k] = $dagilim[$k] }
  RaporYaz $rapor
  Write-Host "`n=== KURU KOSU ==="
  foreach($k in ($dagilim.Keys | Sort-Object)){ Write-Host ("  {0,-20} {1}" -f $k, $dagilim[$k]) }
  Write-Host ("`n-> {0}`n-> {1}" -f $raporYol, $ornekYol)
  Write-Host "PARA HARCANMADI. Ornek istemler gozle kontrol edilecek."
  exit 0
}

# ============================================================================
#  UYGULA — PARALI KATMAN (Cem'in 02.08 "pilot calistir 200 soru" onayiyla acildi)
#
#  BU KOSU KASAYA YAZMAZ. Sebebi: bu motorun ilk paralı koşusu. Kalitesi
#  gorulmeden 200 soruya dokunursak, kotu cikan parti kasada temizlenecek is
#  birakir. Pilot yalnizca (1) gercek faturayi olcer, (2) ciktilari dosyaya
#  yazar. Kasaya yazma ayri bir anahtarla (-yaz) ve Cem'in ikinci onayiyla olur.
#
#  CIKTI veri/fabrika/ ALTINA yazilir - orasi .gitignore'da. Parali soru icerigi
#  public depoya GIRMEZ (29-30.07 karari).
# ============================================================================
if(-not $env:ANTHROPIC_API_KEY){
  Write-Host "ANTHROPIC_API_KEY yok - parali kosu yapilamaz."
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT - ANAHTAR YOK'; durum='KIRMIZI'
    not='ANTHROPIC_API_KEY sirri tanimli degil; hicbir cagri yapilmadi, para harcanmadi.' }))
  exit 1
}
$MODEL = 'claude-haiku-4-5-20251001'
# Fiyat: 1 USD / M giris token, 5 USD / M cikis token (Haiku 4.5 liste fiyati).
# Token sayilari OLCUMDUR (API'nin usage alani); USD bu iki katsayiyla turetilir.
$FIY_IN = 1.0 / 1000000.0
$FIY_OUT = 5.0 / 1000000.0

# --- CIKTI NEREYE GIDIYOR ---
# 03.08 dersi: ilk pilotta ciktilar veri/fabrika altina yazildi. Orasi .gitignore'da
# (dogru), ama kosucu makine gecici - dosya commit edilmeyince MAKINEYLE BIRLIKTE
# SILINDI. 0,78 USD odendi, maliyet olculdu, 200 cikti kayboldu.
# Artik ciktilar SUPABASE'e (soru_onarim_taslak) yazilir: ozel, kalici, gozle
# okunabilir. Depoya ve artifact'a HICBIR icerik gitmez.
$etiketAdi = "pilot-$(Get-Date -Format 'ddMM-HHmm')"

# ============================================================================
#  UCUS ONCESI: TASLAK DEPOSU HAZIR MI?  (Cem'e is cikarmayan yol)
#
#  Tablo yaratmak DDL ister; DDL'i yalnizca Cem panelden calistirabilir.
#  Ama ayni ihtiyaci Supabase STORAGE karsiliyor ve kova yaratmak SERVIS
#  ANAHTARIYLA yapilabilir - yani robot kendi kuruyor, Cem'in eli degmiyor.
#
#  KOVA OZEL OLACAK. 17.07 denetiminde "fisler" kovasi public bulunmustu;
#  ayni hata burada tekrarlanmaz: public=false ile yaratilir VE yaratildiktan
#  sonra geri okunup public olmadigi DOGRULANIR. Ozel degilse pilot BASLAMAZ.
# ============================================================================
$KOVA = 'onarim-taslak'
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$SK   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function KovaDurum {
  try {
    $h = Invoke-WebRequest -Uri "$STOR/bucket/$KOVA" -Headers $SK -UseBasicParsing -TimeoutSec 60
    $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
    return ($m | ConvertFrom-Json)
  } catch { return $null }
}
$kv = KovaDurum
if($null -eq $kv){
  Write-Host "Taslak kovasi yok - OZEL olarak yaratiliyor..."
  $kgovde = ConvertTo-Json -Compress -InputObject @{ id=$KOVA; name=$KOVA; public=$false }
  try {
    Invoke-RestMethod -Uri "$STOR/bucket" -Method Post -Headers ($SK + @{ 'Content-Type'='application/json' }) -Body ([Text.Encoding]::UTF8.GetBytes($kgovde)) -TimeoutSec 60 | Out-Null
  } catch {
    $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
    Write-Host "!! KOVA YARATILAMADI - pilot BASLATILMADI, para harcanmadi."
    Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
      tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
      sebep='taslak kovasi yaratilamadi'; sunucu=$g
      not='Hicbir API cagrisi yapilmadi. Ciktinin kaybolacagi kosuya para verilmez.' }))
    exit 1
  }
  $kv = KovaDurum
}
if($null -eq $kv -or $kv.public -eq $true){
  Write-Host "!! KOVA OZEL DEGIL (veya okunamadi) - pilot BASLATILMADI, para harcanmadi."
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
    sebep='taslak kovasi PUBLIC gorundu - parali icerik acik yere yazilamaz (17.07 fisler-bucket dersi)'
    not='Hicbir API cagrisi yapilmadi.' }))
  exit 1
}
Write-Host ("Ucus oncesi: taslak kovasi hazir ve OZEL (public={0})." -f $kv.public)

# --- DENEME YAZMASI: kovaya gercekten yazabiliyor muyuz? ---
# 03.08 dersi: iki kosuda da 200 cagri YAPILDI, para gitti, sonra yazma bozuk
# cikti ve ciktilar kayboldu. Artik yazma yetenegi TEK KURUS harcanmadan
# denenir. Deneme dosyasi yazilip geri okunamiyorsa pilot BASLAMAZ.
try {
  $dGovde = ConvertTo-Json -Compress -InputObject @{ deneme=$true; etiket=$etiketAdi }
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/_deneme.json" -Method Post `
    -Headers ($SK + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) `
    -Body ([Text.Encoding]::UTF8.GetBytes($dGovde)) -TimeoutSec 60 | Out-Null
  $dh = Invoke-WebRequest -Uri "$STOR/object/$KOVA/_deneme.json" -Headers $SK -UseBasicParsing -TimeoutSec 60
  $dm = if($dh.RawContentStream){ [Text.Encoding]::UTF8.GetString($dh.RawContentStream.ToArray()) } else { "$($dh.Content)" }
  if(($dm | ConvertFrom-Json).etiket -ne $etiketAdi){ throw "geri okunan icerik yazilanla ayni degil" }
  Write-Host "Ucus oncesi: kovaya yazma DENENDI ve dogrulandi."
} catch {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Write-Host "!! KOVAYA YAZILAMIYOR - pilot BASLATILMADI, para harcanmadi."
  RaporYaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
    sebep='taslak kovasina deneme yazmasi basarisiz'; hata="$($_.Exception.Message)"; sunucu=$g
    not='Hicbir API cagrisi yapilmadi. Ciktinin kaybolacagi kosuya para verilmez (03.08 dersi: iki kez oldu).' })
  exit 1
}

$AH = @{ 'x-api-key'=$env:ANTHROPIC_API_KEY; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' }
$sonuc = New-Object System.Collections.Generic.List[object]
$tIn=0; $tOut=0; $basarili=0; $bozukJson=0; $hataliCagri=0; $tekrarKusurlu=0
$parti = @($hazir | Select-Object -First $(if($sinir -gt 0){$sinir}else{$hazir.Count}))
Write-Host ("PILOT basliyor: {0} soru | model {1}" -f $parti.Count, $MODEL)

for($n=0; $n -lt $parti.Count; $n++){
  $i = $parti[$n]
  $istem = IstemKur $i
  $govde = ConvertTo-Json -Depth 5 -Compress -InputObject @{
    model=$MODEL; max_tokens=1500
    messages=@(@{ role='user'; content=$istem })
  }
  try {
    $c = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $AH `
         -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120
  } catch {
    $hataliCagri++
    Write-Host ("  [{0}] CAGRI HATASI: {1}" -f ($n+1), $_.Exception.Message)
    continue
  }
  $tIn += [int]$c.usage.input_tokens; $tOut += [int]$c.usage.output_tokens
  $metin = ''
  foreach($p in @($c.content)){ if($p.type -eq 'text'){ $metin += "$($p.text)" } }
  # Model bazen JSON'u ``` icine sarar - soyup dene.
  $temiz = ($metin -replace '(?s)^\s*```(?:json)?\s*','' -replace '(?s)\s*```\s*$','').Trim()
  $obj = $null
  try { $obj = $temiz | ConvertFrom-Json } catch { $bozukJson++ }
  if($null -ne $obj){ $basarili++ }

  # --- TEKRAR KAPISI (03.08, Cem'in bulgusu) ---
  # Istem "her sikka ayri cumle" diyor ama SOYLEMEK olcmek degildir. Model dort
  # yanlis sikka ayni cumleyi yazarsa bu kapida yakalanir ve soru KUSURLU sayilir.
  # Onek de burada temizlenir: model "Dogrusu:" yazip sistem de eklerse cift olur.
  $tekrarVar = $false
  if($null -ne $obj){
    foreach($alan in 'dogrusu','tuzak'){
      $v = $null; try { if($obj.PSObject.Properties[$alan]){ $v = $obj.$alan } } catch {}
      if($null -eq $v){ continue }
      $gorulen = @{}
      foreach($h in 'A','B','C','D','E'){
        $m = ''; try { if($v.PSObject.Properties[$h]){ $m = "$($v.$h)" } } catch {}
        if($m.Trim().Length -lt 5){ continue }
        # model onegi yazdiysa kirp (cift "Dogrusu: Dogrusu:" olmasin)
        $m = ($m -replace '(?i)^\s*(dogrusu|do[ğg]rusu|tuzak)\s*:\s*','').Trim()
        try { $v.$h = $m } catch {}
        $anahtar = ($m.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]','')
        if($gorulen.ContainsKey($anahtar)){ $tekrarVar = $true }
        $gorulen[$anahtar] = 1
      }
    }
  }
  if($tekrarVar){ $tekrarKusurlu++ }
  $sonuc.Add([ordered]@{
    soru_id="$($i.soru.id)"; parti=$etiketAdi; model=$MODEL
    ders="$($i.soru.ders)"; konu="$($i.soru.konu)"; kaynak="$($i.soru.kaynak)"
    mevzuatdisi=[bool]$i.mevzuatdisi; eksik=@($i.eksik)
    cikti=$(if($null -ne $obj){ $obj } else { @{ ham=$temiz } })
    gecerli_json=($null -ne $obj)
    giris_token=[int]$c.usage.input_tokens; cikis_token=[int]$c.usage.output_tokens
  })
  if((($n+1) % 25) -eq 0){ Write-Host ("  {0}/{1} | giris {2} cikis {3} token" -f ($n+1), $parti.Count, $tIn, $tOut) }
}

$maliyet = [Math]::Round(($tIn * $FIY_IN) + ($tOut * $FIY_OUT), 4)
$birim = if($parti.Count -gt 0){ [Math]::Round($maliyet / $parti.Count, 6) } else { 0 }

# --- TASLAK KOVASINA YAZ + GERI OKU ---
# Yazdiktan sonra GERI OKUYUP SAYMAK sart: "yesil kosu = tam veri" degil
# (yukleyici 3.162 kaydi sessizce kaybetmisti). Geri okunan sayi istenene esit
# degilse kosu KIRMIZI biter - cunku para harcanip cikti yine kaybolmus olur.
$hepsi = $sonuc.ToArray()
$dosyaAd = "$etiketAdi.json"
$govde2 = ConvertTo-Json -Depth 8 -InputObject $hepsi
$yazilan = 0; $yazmaHatasi = ''
try {
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/$dosyaAd" -Method Post `
    -Headers ($SK + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) `
    -Body ([Text.Encoding]::UTF8.GetBytes($govde2)) -TimeoutSec 180 | Out-Null
  $yazilan = $hepsi.Count
} catch {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  $yazmaHatasi = "$($_.Exception.Message) | $g"
  Write-Host ("  KOVAYA YAZMA HATASI: {0}" -f $yazmaHatasi)
}
$geriOkuma = -1
try {
  $ho = Invoke-WebRequest -Uri "$STOR/object/$KOVA/$dosyaAd" -Headers $SK -UseBasicParsing -TimeoutSec 180
  $mo = if($ho.RawContentStream){ [Text.Encoding]::UTF8.GetString($ho.RawContentStream.ToArray()) } else { "$($ho.Content)" }
  $geriOkuma = @($mo | ConvertFrom-Json | Where-Object { $null -ne $_ }).Count
} catch { $geriOkuma = -1 }
Write-Host ("  Kovaya yazilan: {0} | GERI OKUMA: {1} satir" -f $yazilan, $geriOkuma)

# --- RAPOR: yalniz SAYILAR depoya gider, soru icerigi GITMEZ ---
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT (PARALI, kasaya YAZILMADI)'
  model=$MODEL; istenen=$parti.Count
  basarili_json=$basarili; bozuk_json=$bozukJson; cagri_hatasi=$hataliCagri
  tekrar_kusurlu=$tekrarKusurlu   # ayni cumleyi birden fazla sikka yazan soru sayisi
  giris_token=$tIn; cikis_token=$tOut
  maliyet_usd=$maliyet; birim_usd_soru=$birim
  fiyat_katsayisi='1 USD/M giris + 5 USD/M cikis (Haiku 4.5 liste fiyati)'
  tahmin_tam_kasa_usd=[Math]::Round($birim * $kasa.Count, 2)
  parti=$etiketAdi
  taslaga_yazilan=$yazilan
  geri_okuma=$geriOkuma
  taslak_yeri="Supabase Storage / kova '$KOVA' (OZEL) / dosya $etiketAdi.json"
  taslak_durum=$(if($geriOkuma -eq $parti.Count){'TAMAM'}elseif($geriOkuma -lt 0){'OKUNAMADI'}else{'KIRMIZI - eksik yazildi'})
  yazma_hatasi=$yazmaHatasi
  not='Ciktilar soru_onarim_taslak tablosunda (ozel). KASAYA YAZILMADI - taslak kasa degildir, site degismedi.'
}
RaporYaz $rapor
Write-Host "`n=== PILOT BITTI ==="
Write-Host ("  Soru: {0} | Gecerli JSON: {1} | Bozuk: {2} | Cagri hatasi: {3}" -f $parti.Count, $basarili, $bozukJson, $hataliCagri)
Write-Host ("  Token: giris {0} / cikis {1}" -f $tIn, $tOut)
Write-Host ("  MALIYET: {0} USD | soru basina {1} USD" -f $maliyet, $birim)
Write-Host ("  Tam kasa tahmini ({0} soru): {1} USD" -f $kasa.Count, $rapor.tahmin_tam_kasa_usd)
Write-Host ("  Taslak partisi: {0} | yazilan {1} | geri okuma {2} | {3}" -f $etiketAdi, $yazilan, $geriOkuma, $rapor.taslak_durum)
Write-Host "  KASAYA YAZILMADI - taslak kasa degildir, site degismedi."
# Taslaga yazamadiysak parayi harcayip ciktiyi yine kaybetmisiz demektir: KIRMIZI.
if($geriOkuma -ne $parti.Count){ Write-Host "!! TASLAK EKSIK - kor kalma riski, rapora bak."; exit 1 }
exit 0
