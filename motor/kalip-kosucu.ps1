# KALIP GECE KOŞUCUSU — GENEL (08.09, B kovası 12; 07.09 kalip-parti-30.ps1'in genelleştirilmiş hâli)
# Plan dosyasından (json dizi) ders ders ardışık koşar; her satır: { "ders":"regex", "etiket":"sgs-fmuh-p31", "adet":6, "tavan":350, "zorluk":"zor|kolay|karisik",
#   "sinav":"SGS", "disla":"regex", "konuDosya":"", "eskiKaynak":"" }  — eskiKaynak doluysa KURTARMA (FAZ U) koşar, yeni soru üretilmez.
# Her ders için: tam hat (soru/uyarlama + adımlar + verilenler + giriş + ikiz + sim Sonnet + hakem + kör çözüm + hakem2), sonra seçim
# (hakem EVET ∧ sim ✓ ∧ kör ✓ ∧ hakem2 EVET — SORU-BASMA-KURALLARI 8.1), Kaydır-Çöz sayfası ve karne. Loglar veri/fabrika/kosucu-log/<plan>/.
# Kullanım: powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-sgs-08-09.json
param([Parameter(Mandatory=$true)][string]$Plan,[string]$Kok='',[switch]$SayfaYok,
  # 11.09 Cem "paralel kostur": ayni anda kac parti. 1 = eski sirali davranis.
  # 12.09 Cem: "toplu moda bulutta hizlanacakti ondan gectik" - HAKLI, ve tavan
# tam onu engelliyordu. 8 siniri CEM'IN MAKINESI icin konmustu (olculdu: 8
# paralelde 543 MB bos kalmisti). Bulut runner'inda 16 GB var ve uzerinde
# baska is YOK. Dahasi toplu parti CPU'nun %2'sini kullanip kuyrukta BEKLIYOR;
# 24 parti ayni anda beklerse 8 partinin bekledigi surede biter - yani
# paralellik toplu modun yavasligini telafi eder.
# ⛔ Tavan kalkti ama KORLEMESINE degil: asagida BOS RAM olculur ve sigmayan
#    paralellik sessizce degil, SEBEBI SOYLENEREK dusurulur.
  # ⛔⭐ 12.09.2026 TAVAN 40 -> 72 (Cem: "ayni anda fazla parti gondeririz diye
  #    konusmustuk, ondan bilgisayari tasidik RAM yemeyelim diye").
  #    OLCULDU, B kosusunun kutugunden:
  #        PARALELLIK: 32 (bos RAM 13769 MB · 71 surece kadar sigar)
  #    Bulut runner'inda 13,8 GB bos RAM var, 71 surece yer var. Darbogaz RAM
  #    DEGIL, bu satirdaki ELLE KONMUS TAVANDI. Buluta tasinmanin sebebi tam bu
  #    basligi acmakti; tavan onu kapatiyordu.
  #    Tavan 72 = olculen 71'in hemen ustu. GERCEK sinir asagidaki BOS RAM
  #    KAPISI: her kosuda kendi olcumunu yapar, sigmayani SEBEBIYLE dusurur.
  #    Yani tavan artik guvenlik agi, karar mekanizmasi degil.
  [ValidateRange(1,72)][int]$Paralel=4,
  [double]$AylikTavan=2000,      # 08.09 Cem: konsolda aylık tavan 2.000 USD (GM göremez, Cem okudu)
  [double]$EmniyetPayi=300)      # tavana bu kadar kala koşucu durur: parti ortada ölmez, ödenen iş yazılmadan kaybolmaz (ağustos dersi)
$ErrorActionPreference='Continue'
# 08.09: Start-Process ile -File çağrısında param varsayılanındaki $PSScriptRoot BOŞ geldi (Split-Path hatası) → kök gövdede hesaplanır
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
if(-not $Kok){ $Kok=Split-Path $buDizin -Parent }

# Plan satirindaki konuDosya'yi CALISILABILIR yola cevirir. Gerekcesi kuyruk
# dongusundeki KONU DOSYASI KAPISI yorumunda. Uzun degisken adlari bilerek:
# PS harf ayirmaz, $Kok ile $kok ayni degiskendir (K1 tuzagi).
function KonuYoluCoz($PLAN_SATIRI){
  $KONU_YOLU="$($PLAN_SATIRI.konuDosya)"
  if($KONU_YOLU -notmatch '^[A-Za-z]:\\' -and $KONU_YOLU -notmatch '^\\\\'){
    $KONU_YOLU=Join-Path $Kok ($KONU_YOLU -replace '/','\')
  }
  if(-not (Test-Path $KONU_YOLU)){
    throw ("KONU DOSYASI YOK: parti '$($PLAN_SATIRI.etiket)' -> $KONU_YOLU`n" +
           "  Plan satirindaki konuDosya mutlak yerel yol olabilir (C:\Users\...); bulutta cozulmez.`n" +
           "  Cozum: plani depoya GORECE yolla yaz -> veri/sinav/konu/<etiket>.json")
  }
  return $KONU_YOLU
}

# ⛔⭐ 13.09.2026 — HAZIR SORU (GM elle yazimi) PLAN SATIRINDAN (Cem "1.2.3 ucunu de yap", GM-3).
#   NIYE: uretici -HazirSoru'yu 09.09'dan beri destekliyordu ama BU KOSUCU onu HIC gecirmiyordu.
#   Sonuc olculdu 13.09: GM'in elle yazdigi Meslek sorulari plan satiriyla kosulamadi; t2b-meslek
#   plan satiri kossaydi hazir dosyayi KULLANMAYIP modele YENI soru URETTIRECEKTI.
#   ⛔ DOSYA YOKSA SESSIZ DUSUS YOK: bayrak dusurulup devam edilirse uretici FAZ A ile soru URETIR ->
#     elle yazilmis is dururken para odenir. Bu yuzden dosya yoksa DURULUR.
#   ⚠ BULUT: hazir-*.json .gitignore'dadir (veri/fabrika/*); depoda ve runner'da YOKTUR. Bu alan bugun
#     YALNIZ dosyanin durdugu makinede calisir; bulutta bilerek YUKSEK SESLE durur. Bulutta calismasi icin
#     dosyalarin runner'a indirilmesi gerekir (sifreli yedek anahtarsiz acilmaz - ayri is).
function HazirYoluCoz($PLAN_SATIRI){
  $HAZIR_YOLU="$($PLAN_SATIRI.hazirSoru)"
  if($HAZIR_YOLU -notmatch '^[A-Za-z]:\\' -and $HAZIR_YOLU -notmatch '^\\\\'){
    $HAZIR_YOLU=Join-Path $Kok ($HAZIR_YOLU -replace '/','\')
  }
  if(-not (Test-Path $HAZIR_YOLU)){
    throw ("HAZIR SORU DOSYASI YOK: parti '$($PLAN_SATIRI.etiket)' -> $HAZIR_YOLU`n" +
           "  hazir-*.json .gitignore'dadir: depoda ve BULUTTA yoktur; bu satir yalniz dosyanin durdugu makinede kosar.`n" +
           "  Sessiz devam EDILMEDI: bayrak dusseydi model elle yazilmis soru yerine YENI soru uretecekti.")
  }
  return $HAZIR_YOLU
}

# ---------------------------------------------------------------------------
# CANLI NABIZ  (12.09.2026, Cem "1.2.3 ucunu de yap" - GM onerisi 1)
#
# NIYE: 12.09'da A kosusu 125 dakika kostu ve "kac parti bitti" sorusunun
#   cevabi YOKTU. Olculdu, tahmin degil:
#     gh run view <id> --log              -> bos (kutuk kosu bitince doluyor)
#     gh api .../jobs/<id>/logs           -> BlobNotFound
#     ambar                               -> bos (yazma adimi EN SONDA tek adim)
#   Yani 350 dakikalik odenmis bir kosuyu KOR izliyorduk. Ben o bosluga bakip
#   "0/32 parti bitti" diye bir sayi urettim - bilgi yoklugunu olcum sandim.
#
# NE YAPAR: her parti bitisinde harcama defterini ambara YUKLER. Boylece
#   kosu surerken `bedel_kaydi` tablosundan "kac parti bitti, ne harcandi"
#   okunabilir. Yeni tablo/SQL GEREKMEZ - bedel_kaydi zaten (zaman, etiket,
#   ders, toplam_usd, yazan) tasiyor.
#
# ⛔ NIYE ANA DONGUDE, PARTI SURECINDE DEGIL: bedel-senkron tekillestirmeyi
#   ISTEMCI tarafinda yapiyor (ambardaki satirlari cekip kiyasliyor). 16
#   paralel parti ayni anda cagirsa ayni satir iki kez POST edilebilir ->
#   harcama toplami sisr -> AYLIK TAVAN FRENI yanlis tetiklenir. Ana dongu
#   tek is parcaciklidir, yaris yok.
#
# ⛔ ASLA KOSUYU DUSURMEZ: nabiz bir kolaylik, urun degil. Her sey try/catch
#   icinde; anahtar yoksa sessizce atlanir (yerel kosularda normal).
$NABIZ_BITEN=0
function NabizYaz($ETIKET,$TOPLAM){
  $script:NABIZ_BITEN=$script:NABIZ_BITEN+1
  $NABIZ_ILETI="NABIZ: {0}/{1} parti bitti (son: {2})" -f $script:NABIZ_BITEN,$TOPLAM,$ETIKET
  Write-Host $NABIZ_ILETI -ForegroundColor Cyan
  if(-not "$env:SUPABASE_SERVICE_KEY"){ return }
  try{
    $NABIZ_BETIK=Join-Path $Kok 'arac\bedel-senkron.ps1'
    if(Test-Path $NABIZ_BETIK){ & $NABIZ_BETIK -Yukle -Yaz *> $null }
  }catch{
    Write-Host ("  nabiz yazilamadi (kosu etkilenmedi): " + $_.Exception.Message) -ForegroundColor DarkGray
  }
}
$uret=Join-Path $buDizin 'kalip-parti-uret.ps1'
# --- BEDEL EMNİYETİ: bu ayın harcaması bedel defterinden (veri/fabrika/bedel-kayit.jsonl, 08.09'dan itibaren tam; öncesi eksik → tutucu) ---
function AyHarcama{ $y=Join-Path $Kok 'veri\fabrika\bedel-kayit.jsonl'; $ay=(Get-Date -Format 'yyyy-MM')
  # 08.09 16:11 Cem konsol ekranı: bu ay 351,09 USD — defter yalnız 08.09'dan beri ve yalnız BİTEN etiketleri sayıyordu (47,7), gerçek rakamı 300 USD
  # düşük görüyordu. Çapa: veri/fabrika/bedel-konsol.json {"zaman":"2026-09-08 16:11","harcama":351.09} (konsol Usage okuması, elle güncellenir);
  # emniyet = konsol okuması + o andan SONRA deftere yazılan etiketler. Okuma yoksa eski davranış.
  $t=0.0; $esik=''; $kj=Join-Path $Kok 'veri\fabrika\bedel-konsol.json'
  if(Test-Path $kj){ try{ $ko=ConvertFrom-Json -InputObject (Get-Content $kj -Raw -Encoding UTF8); if("$($ko.zaman)" -like "$ay*"){ $t=[double]$ko.harcama; $esik="$($ko.zaman)" } }catch{} }
  if(-not (Test-Path $y)){ return $t }
  foreach($sat in (Get-Content $y -Encoding UTF8)){ if(-not $sat.Trim()){ continue }; try{ $o=ConvertFrom-Json -InputObject $sat; $z="$($o.zaman)"; if($z -like "$ay*" -and (-not $esik -or $z -gt $esik)){ $t+=[double]$o.toplamUsd } }catch{} }; return $t }
# --- PARALELLIK RAM KAPISI (12.09.2026) --------------------------------------
# Tavan 8'den 40'a cikarildi (bulut runner'i 16 GB, uzerinde baska is yok).
# Ama makine makineye degisir: Cem'in dizustunde 8 paralelde 543 MB kalmisti.
# Istenen paralellik BOS RAM'e gore olculur; sigmiyorsa SESSIZCE degil,
# SEBEBI SOYLENEREK dusurulur. Olculen: surec basina ~180 MB (11.09).
$SUREC_MB=180; $PAY_MB=900
try{
  $bosMB=[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB)
  $sigan=[Math]::Max(1,[int](($bosMB-$PAY_MB)/$SUREC_MB))
  if($Paralel -gt $sigan){
    "PARALELLIK DUSURULDU: $Paralel -> $sigan (bos RAM $bosMB MB · surec ~$SUREC_MB MB · pay $PAY_MB MB)"
    $Paralel=$sigan
  } else { "PARALELLIK: $Paralel (bos RAM $bosMB MB · $sigan surece kadar sigar)" }
}catch{ "PARALELLIK: $Paralel (bos RAM olculemedi)" }
$harcanan=AyHarcama
# ⚠ 11.09.2026 CEM KARARI: "BU İKİ RAKAMI İPTAL ET" — aylık tavan artık KAPI DEĞİL,
#   yalnız RAPOR. Gerekçe (Cem): "bakiye kadar harcayacak ve bizim istediğimiz soru
#   kadar basacağından sıkıntı olmaz." Gerekçe ÖLÇÜLDÜ ve doğrulandı:
#     · motor/kalip-parti-uret.ps1 → KAPI-BAKIYE her parti ÖNCESİ Anthropic
#       bakiyesini yokluyor; yetmezse parti HİÇ BAŞLAMADAN durur (yarım koşu yok).
#       O kapı yerel dosyaya bağlı değil, BULUTTA DA çalışır.
#     · harcama ayrıca plana bağlı: koşucu plandaki parti sayısından fazlasını basmaz.
#   Ayrıca iki rakam ÇELİŞİYORDU (ölçüldü 11.09 22:50): koşucu 933,54 USD,
#   ham defter 630,15 USD, fark 303,39 — çünkü koşucu konsol çapasını ekliyor,
#   defter eklemiyordu. İki ayrı "gerçek" tutan bir fren, fren değildir.
# GERİ ALMAK İÇİN: aşağıdaki satırın başındaki yorumu kaldır.
# if($harcanan -ge ($AylikTavan-$EmniyetPayi)){ throw "BEDEL EMNİYETİ: aylık harcama eşiğe ulaştı ($harcanan ≥ $($AylikTavan-$EmniyetPayi)); koşu başlatılmadı." }
"BEDEL KAYDI (kapı DEĞİL, rapor): bu ay ≈$([math]::Round($harcanan,2)) USD · fren = KAPI-BAKIYE (parti başına bakiye yoklaması)"
$planYol=$(if(Test-Path $Plan){ $Plan } else { Join-Path $Kok $Plan }); if(-not (Test-Path $planYol)){ throw "plan yok: $planYol" }
$planAd=[IO.Path]::GetFileNameWithoutExtension($planYol)
$satirlar=@(ConvertFrom-Json -InputObject (Get-Content $planYol -Raw -Encoding UTF8)); if($satirlar.Count -eq 1 -and $satirlar[0].PSObject.Properties['SyncRoot']){ $satirlar=@($satirlar[0].SyncRoot) }
$logDir=Join-Path $Kok "veri\fabrika\kosucu-log\$planAd"; New-Item -ItemType Directory -Force $logDir | Out-Null
$t0=Get-Date; $ozetTum=@()
# --- DİNAMİK UZUNLUK TAVANI (10.09.2026) -------------------------------------
# Eskiden varsayılan SABİT 350'ydi. Ölçüldü: gerçek sınavda ders başına p90
# 243 (Atatürk) ile 868 (Maliyet) arasında değişiyor; tek rakam 14 dersin
# HİÇBİRİNE oturmuyor. Ayrıca sınav uzuyor (SGS medyanı 2024/2'de 153 →
# 2026/2'de 215, +%40), yani sabit yazılan tavan her dönem daha da yanlışlaşır.
# Tavan artık ölçümden OKUNUR; plan satırında `tavan` varsa o kazanır.
$anatomiYol = Join-Path $Kok 'veri\sinav-anatomisi-sgs.json'
$DERS_TAVAN = @{}
if(Test-Path $anatomiYol){
  try{
    $an = ConvertFrom-Json -InputObject (Get-Content $anatomiYol -Raw -Encoding UTF8)
    foreach($p in $an.C_ders_kalibi.PSObject.Properties){ $DERS_TAVAN[$p.Name] = [int]$p.Value.uzunluk.p90 }
  }catch{ }
}
function DersTavani($satir){
  if($satir.PSObject.Properties['tavan'] -and $satir.tavan){ return [int]$satir.tavan }
  $d = "$($satir.ders)"
  foreach($k in $DERS_TAVAN.Keys){ if($d -match [regex]::Escape($k) -or $k -match [regex]::Escape($d)){ return $DERS_TAVAN[$k] } }
  return 350   # ölçüm bulunamazsa eski varsayılan; sessizce yanlış tavan yerine BİLİNEN tavan
}

# --- PARALEL HAVUZ (11.09.2026, Cem "paralel kostur") ------------------------
# 43 partilik plan sirali kosarsa gece bulur (olculdu: parti basina 6-9 dk).
# Her parti KENDI cache dosyasina yazar; ortak dosyalar kilitli
# (bekleyen-partiler.json ve bedel-kayit.jsonl Mutex'li).
# ⚠ BEDEL EMNIYETI KORUNUR: AyHarcama her BASLATMADAN once bakilir. Tek farki,
#   esige degdiginde en fazla $Paralel parti ucusta olur; EmniyetPayi bunun
#   icin var. Paralellik BEDELI DEGISTIRMEZ, yalniz duvar saatini kisaltir.
# ⚠ 4'te tutuldu: partiler zaten kendi icinde toplu (Message Batches) gidiyor;
#   daha yuksek eszamanlilik 429 uretir ve tekrar denemeler isi YAVASLATIR.
function ProvaTir([string]$x){ if($x -match '\s'){ return ('"'+$x+'"') }; return $x }
function PartiKuyrukBitir($a){
  $s=$a.s; $log=$a.log
  try{ $a.ps.WaitForExit() }catch{}
  $oz=Select-String -Path $log -Pattern 'KONU LİSTESİ|konu tekil|SORU DÜŞTÜ|KURTARMA DÜŞTÜ|UYARLAMA OK|HAKEM (EVET|HAYIR)|HAKEM2 (EVET|HAYIR)|KÖR ÇÖZÜM|SIM (DO|YAN|yetmedi)|KAYNAK BORCU|BEDEL TOPLAM|yazildi' -ErrorAction SilentlyContinue | ForEach-Object { $_.Line }
  $partiYol = Join-Path $Kok ("veri\fabrika\kalip-parti-$($s.etiket).json")
  if(Test-Path $partiYol){
    try{
      $pj = ConvertFrom-Json -InputObject (Get-Content $partiYol -Raw -Encoding UTF8)
      $n=0; $sadeli=0
      foreach($pp in $pj.PSObject.Properties){
        $vv=$pp.Value; if(-not $vv -or -not $vv.soru){ continue }
        $n++
        if($vv.PSObject.Properties['sade'] -and $vv.sade -and @($vv.sade.PSObject.Properties).Count -gt 0){ $sadeli++ }
      }
      if($n -gt 0){
        $oran = [math]::Round(100*$sadeli/$n)
        if($oran -lt 90){
          "[$(Get-Date -Format HH:mm)] 🔴 SADE KAPISI KIRMIZI · $($s.etiket) · sade $sadeli/$n (%$oran) — Kaydir-Coz panelinin 2. ve 5. parcasi BOS iner"
          Add-Content -Path (Join-Path $Kok 'veri\fabrika\sade-eksik-partiler.txt') -Value ("{0}`t{1}`t{2}/{3}`t%{4}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $s.etiket, $sadeli, $n, $oran) -Encoding UTF8
        } else { "[$(Get-Date -Format HH:mm)] SADE KAPISI YESIL · $($s.etiket) · sade $sadeli/$n (%$oran)" }
      }
    }catch{ "[$(Get-Date -Format HH:mm)] ⚠ SADE KAPISI OLCULEMEDI · $($s.etiket): $($_.Exception.Message)" }
  }
  "[$(Get-Date -Format HH:mm)] BITTI $($s.etiket)"; $oz
  return [pscustomobject]@{ etiket="$($s.etiket)"; ders="$($s.ders)"; bedel=(($oz | Where-Object { $_ -match 'BEDEL TOPLAM' } | Select-Object -Last 1) -replace '.*≈','' -replace ' USD.*','') }
}

$kuyruk=New-Object System.Collections.Generic.Queue[object]
foreach($s in $satirlar){ $kuyruk.Enqueue($s) }
$ucan=New-Object System.Collections.Generic.List[object]
$durduruldu=$false

while(($kuyruk.Count -gt 0 -and -not $durduruldu) -or $ucan.Count -gt 0){
 while($ucan.Count -lt $Paralel -and $kuyruk.Count -gt 0 -and -not $durduruldu){
  $s=$kuyruk.Dequeue()
  $sinav=$(if($s.PSObject.Properties['sinav'] -and $s.sinav){ "$($s.sinav)" } else { 'SGS' })
  # ⛔⭐ 12.09.2026 — KONU DOSYASI KAPISI. Plan satirindaki `konuDosya` MUTLAK
  #    YEREL YOL olabiliyor (arac/plan-uret.ps1 ve motor/plandan-parti-kur.ps1
  #    boyle yaziyor: "C:\Users\cemdi\...\veri\sinav\konu\x.json"). Bulut
  #    runner'inda o yol YOKTUR - ve kalip-parti-uret.ps1:1009
  #    `if($KonuDosya -and (Test-Path $KonuDosya))` diyerek SESSIZCE atliyordu.
  #    Sonuc: parti konu listesini hic gormeden, baska bir secimle uretirdi;
  #    yesil kosu + yanlis sorular + odenmis para. Kapi iki is yapar:
  #      1) gorece yolu depo kokune gore cozer (runner CWD'sine guvenmez)
  #      2) yol yoksa DURUR - sessiz dusus yok.
  #    Ayni kapinin ureticideki esi: kalip-parti-uret.ps1 FAZ K.
  $log=Join-Path $logDir ("$($s.etiket).log")
  # 🔴 10.09.2026 — FAZ S (-Sade) BU LİSTEDE YOKTU. Ölçüldü: 213 partinin
  # yalnız 15'inde `sade` alanı var, hepsi 04-06.09 arası ELLE koşulan küçük
  # partiler. 07.09'da toplu hatta geçildi, bu argüman listesi yazıldı ve
  # -Sade listeye ALINMADI; 198 parti FAZ S hiç çalışmadan üretti.
  # Sonuç: 1.835 sorunun 1.811'inde `sade` + `kavramlar` YOK, yani Kaydır-Çöz
  # panelinin 2. ve 5. parçası boş. Tam panel taşıyan soru: 12/1835.
  # Üretici bozulmadı — çağrılmayan bir faz vardı. (bkz. aciklama-standardi:
  # cevap kalıbı 05.09'da KİLİTLENDİ, üretim 07.09'da o kilidi takip etmeyi bıraktı.)
  $arg=@('-Sinav',$sinav,'-DersRegex',"$($s.ders)",'-Adet',"$([int]$s.adet)",'-Etiket',"$($s.etiket)",'-UzunlukTavan',"$(DersTavani $s)",'-Verilenler','-KonuGiris','-Simulasyon','-SimModel','claude-sonnet-5','-Sade')
  if($s.PSObject.Properties['eskiKaynak'] -and "$($s.eskiKaynak)"){ $arg+=@('-EskiKaynak',"$($s.eskiKaynak)",'-DonemPencere','0') }
  else { $arg+=@('-DonemPencere','7'); if($s.PSObject.Properties['zorluk'] -and (@('zor','kolay','cokzor') -contains "$($s.zorluk)")){ $arg+=@('-Zorluk',"$($s.zorluk)") }; if($s.PSObject.Properties['disla'] -and "$($s.disla)"){ $arg+=@('-KonuDisla',"$($s.disla)") }; if($s.PSObject.Properties['konuDosya'] -and "$($s.konuDosya)"){ $arg+=@('-KonuDosya',(KonuYoluCoz $s)) } }
  # 13.09 (bkz. HazirYoluCoz): GM elle yazimi + kor cozum modeli plan satirindan. Uc alan da YOKSA arguman
  #   listesi ESKISIYLE BIREBIR aynidir (olculdu: depodaki hicbir plan bu alanlari tasimiyor).
  #   korModel: yazar GM (Opus) ise kor cozum FARKLI model olmali (SORU-BASMA-KURALLARI 3.5).
  if($s.PSObject.Properties['hazirSoru'] -and "$($s.hazirSoru)"){ $arg+=@('-HazirSoru',(HazirYoluCoz $s)) }
  if($s.PSObject.Properties['korModel'] -and "$($s.korModel)"){ $arg+=@('-KorModel',"$($s.korModel)") }
  if($s.PSObject.Properties['korKaynak'] -and [bool]$s.korKaynak){ $arg+=@('-KorKaynak') }
  # 08.09 13:40 ölçümü: Anthropic toplu sırası tıkandı (10:12'den beri 5 parti, 0 işlenen) → MEVZUAT_TOPLU=0 ortam değişkeni planı ezer, fazlar anlık koşar
  # 09.09 Cem "ara ara deneyelim orayı, rakamı düşürmemiz lazım": MEVZUAT_TOPLU='auto' → motor/toplu-sonda.ps1'in yazdığı sağlık dosyasına bakılır;
  # son 40 dk içinde "acik" ölçülmüşse bu etiket TOPLU (yarı fiyat), değilse anlık. Üretici ayrıca faz bazında MEVZUAT_TOPLU_BEKLE_DK sonra anlığa düşer.
  # ⛔⭐ 12.09.2026 CEM KURALI: "sorulari TOPLU MODDA basiyoruz, bu kural olsun;
  #     diger yerde basmayalim, bosuna para harciyoruz."
  #     TOPLU ARTIK VARSAYILAN. Onceden plan satirinda `toplu:true` YOKSA anlik
  #     kosuyordu - yani planı yazan unutursa TAM FIYAT odeniyordu. Olculen fark:
  #     toplu YARI FIYAT (688 soruluk plan: ~330 USD anlik / ~165 USD toplu).
  #     Yavasligi paralellikle telafi edilir (tavan 8 -> 40, bkz. yukarisi):
  #     toplu parti CPU'nun %2'sini kullanip kuyrukta bekler, 24 parti ayni anda
  #     beklerse 8 partinin bekledigi surede biter.
  #  ⚠ ANLIK ISTISNADIR, kural degil: plan satirinda ACIKCA `toplu:false` yazan
  #    ya da MEVZUAT_TOPLU=0 verilen kosular anlik gider. Ikisi de BILEREK
  #    yazilmis olmali; unutulunca artik pahaliya degil UCUZA kacar.
  $topluAc=$true
  if($s.PSObject.Properties['toplu'] -and -not [bool]$s.toplu){
    $topluAc=$false
    "[$(Get-Date -Format HH:mm)] ANLIK (plan acikca toplu:false demis) · $($s.etiket)"
  }
  # ⛔ ORTAM DEGISKENI EZER. Varsayilan TOPLU oldugu icin bu blok artik yalnizca
  #    "toplu'yu KAPAT" yonunde calisir; acma yonu zaten varsayilan.
  #    (Ilk yazdigimda bunu atlamistim: $topluAc=$true baslayinca MEVZUAT_TOPLU=0
  #     ezemiyordu ve saglıksız kuyrukta da toplu kaliyordu.)
  if($topluAc){
    if("$env:MEVZUAT_TOPLU" -eq '0'){
      $topluAc=$false
      "[$(Get-Date -Format HH:mm)] ANLIK (MEVZUAT_TOPLU=0 ezdi) · $($s.etiket)"
    }
    elseif("$env:MEVZUAT_TOPLU" -eq 'auto'){
      # 09.09 Cem "ara ara deneyelim orayi": kuyruk sagligi son 40 dk icinde
      # 'acik' olculmusse toplu, degilse anlik. Saglik bilinmiyorsa TOPLU kalir
      # (Cem 12.09: toplu KURAL; suphede ucuz olan secilir, pahali olan degil).
      $sagYol=Join-Path $Kok 'veri\fabrika\toplu-kuyruk-sagligi.json'
      if(Test-Path $sagYol){
        try{
          $sg=ConvertFrom-Json -InputObject (Get-Content $sagYol -Raw)
          $yas=((Get-Date)-[datetime]$sg.zaman).TotalMinutes
          if("$($sg.durum)" -ne 'acik' -and $yas -le 40){ $topluAc=$false }
          "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK: $($sg.durum) ($([int]$yas) dk önce) → $(if($topluAc){'TOPLU'}else{'ANLIK'}) · $($s.etiket)"
        }catch{ "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK okunamadı → TOPLU (varsayilan)" }
      } else { "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK dosyası yok → TOPLU (varsayilan)" }
    }
  }
  if($topluAc){ $arg+=@('-Toplu') }   # 08.09: fazların ilk denemesi Message Batches ile (yarı fiyat)
  # 08.09 17:10 hız ölçümü: anlık modda 192 konuluk etiket tek hatta ≈16 saat → etiket ikiye bölünür: eski etiket yalnız önbellekteki id'lerle (pilot),
  # kalan konular "<etiket>-b" adlı yeni etikette ayrı hatta koşar. Plan alanı `pilot` = virgüllü id listesi → üreticiye -PilotId
  if($s.PSObject.Properties['pilot'] -and "$($s.pilot)"){ $arg+=@('-PilotId',"$($s.pilot)") }
  # ⚠ 11.09 Cem "BU İKİ RAKAMI İPTAL ET" — ders arası aylık tavan kapısı da KALDIRILDI.
  #   Fren KAPI-BAKIYE'dir: kalip-parti-uret.ps1 her parti öncesi Anthropic bakiyesini
  #   yoklar, yetmezse parti HİÇ BAŞLAMAZ. Yerel dosyaya bağlı değil → bulutta da çalışır.
  #   GERİ ALMAK İÇİN: aşağıdaki dört satırın yorumunu kaldır.
  $harcanan=AyHarcama
  # if($harcanan -ge ($AylikTavan-$EmniyetPayi)){
  #   "[$(Get-Date -Format HH:mm)] BEDEL EMNİYETİ: ≈$([math]::Round($harcanan)) USD → kalan dersler DURDU"
  #   $durduruldu=$true; break
  # }
  "[$(Get-Date -Format HH:mm)] BASLIYOR $($s.etiket) · $($s.ders) · adet $($s.adet)$(if($s.PSObject.Properties['eskiKaynak'] -and $s.eskiKaynak){ ' · KURTARMA' }) · ay ≈$([math]::Round($harcanan)) USD · ucan $($ucan.Count+1)"
  # ⛔ Start-Process -ArgumentList diziyi BOSLUKLA birlestirir; depo yolu
  #    "...\mevzuat işi\..." bosluk tasiyor. Bosluklu her arguman TIRNAKLANIR.
  #    (11.09'da sade-tamamla'da bu yuzden 86 parti 0 sn'de dusmustu.)
  $argP=@('-NoProfile','-File',(ProvaTir $uret)) + @($arg | ForEach-Object { ProvaTir "$_" })
  $ps=Start-Process -FilePath 'powershell' -ArgumentList $argP -PassThru -WindowStyle Hidden `
                    -RedirectStandardOutput $log -RedirectStandardError ("$log.err")
  $ucan.Add([pscustomobject]@{ s=$s; ps=$ps; log=$log })
 }
 if(-not $ucan.Count){ break }
 [void]$ucan[0].ps.WaitForExit(5000)
 foreach($a in $ucan.ToArray()){
   if(-not $a.ps.HasExited){ continue }
   $ozetTum+=(PartiKuyrukBitir $a)
   [void]$ucan.Remove($a)
   NabizYaz "$($a.s.etiket)" $satirlar.Count   # canli nabiz - bkz. NabizYaz
 }
}
# seçim (8.1 yayın şartı)
$secim=@()
foreach($s in $satirlar){
  $cf=Join-Path $Kok "veri\fabrika\kalip-parti-$($s.etiket).json"; if(-not (Test-Path $cf)){ continue }
  $c=ConvertFrom-Json -InputObject (Get-Content $cf -Raw -Encoding UTF8)
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v.soru){ continue }
    if("$($v.hakem.karar)" -ne 'EVET'){ continue }
    # 11.09.2026 — Cem: "hakem olmadan soru basmiyorduk niye bastik".
    # Hakem DORT hukum verir (karar · ders_uyum · konu_uyum · tek_anlam) ama bu
    # kapi yalnizca `karar`i okuyordu. Hakemin KENDI agziyla KONU-DISI dedigi,
    # hatta gerekcesini yazdigi sorular yayina gitti.
    # OLCULDU (11.09, 648 basilan soru): 12 soruda konu_uyum=KONU-DISI.
    #   ornek sgs-t1-fmuh-kolay/kp-72, etiket 'satis dongusu kontrol testi':
    #   hakem: "Soru satis dongusu kontrol testi konusunu degil, Vergi Usul
    #   Kanunu fatura nizami kurallarini olcmektedir ve bu konu Vergi Hukuku
    #   dersinin icerigidir." -> yine de basildi, muhur orneklemine bile dustu.
    # Uretici bu damgayi zaten RED sayiyordu (satir ~2514 $hakemRed) ve
    # kaydir-coz.ps1'in OTOMATIK aday yolu da eliyordu (satir 14); eksik olan
    # yalniz SECIM yoluydu. Uc yol artik ayni sarti uyguluyor.
    if("$($v.hakem.ders_uyum)" -eq 'DERS-DISI'){ continue }
    if("$($v.hakem.konu_uyum)" -eq 'KONU-DISI'){ continue }
    if("$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM'){ continue }
    $simOk=$true; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    if(-not ($v.PSObject.Properties['kor_cozum'] -and $v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $secim+=[pscustomobject]@{ etiket="$($s.etiket)"; id=$p.Name; ders="$(if($v.PSObject.Properties['ders'] -and $v.ders){ $v.ders } else { $s.ders })"; konu="$($v.konu)"; donem=[int]$v.donem; kurtarma=[bool]($v.PSObject.Properties['kurtarma'] -and $v.kurtarma) }
  }
}
$secYol=Join-Path $Kok "veri\sinav\kaydir-secim\$planAd-secim.json"
[IO.File]::WriteAllText($secYol,(ConvertTo-Json -InputObject @($secim) -Depth 3),[Text.UTF8Encoding]::new($false))
"SECIM: $($secim.Count) soru (yayın şartı: hakem[karar+ders+konu+tek anlam] ∧ sim ∧ kör ∧ hakem2) -> $secYol"
if(-not $SayfaYok -and $secim.Count){
  & powershell -NoProfile -File (Join-Path $buDizin 'kaydir-coz.ps1') -SecimDosya "$planAd-secim.json" -Cikti "KAYDIR-COZ-$planAd.html" *> (Join-Path $logDir 'builder.log')
  Get-Content (Join-Path $logDir 'builder.log') | Select-String -Pattern 'yazildi|ÖZ-SINAV|Exception|Cannot' | ForEach-Object { $_.Line }
}
$etk=($satirlar | ForEach-Object { $_.etiket }) -join ','
& powershell -NoProfile -File (Join-Path $buDizin 'soru-karnesi.ps1') -Etiketler $etk -Cikti "KARNE-$planAd.html" *> (Join-Path $logDir 'karne.log')
Get-Content (Join-Path $logDir 'karne.log') | Select-String -Pattern 'ZORLUK|KARNE:' | ForEach-Object { $_.Line }
"BEDEL (ders ders, ≈USD): $(($ozetTum | ForEach-Object { "$($_.etiket)=$($_.bedel)" }) -join ' · ')"
"[$(Get-Date -Format HH:mm)] TAMAM · sure $([int]((Get-Date)-$t0).TotalMinutes) dk"