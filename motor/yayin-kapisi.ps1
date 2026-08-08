# ============================================================================
#  YAYIN KAPISI (03.08.2026) — 0 USD, API YOK
#
#  CEM: "böyle bir hata ile bir daha karşılaşmamak için ne yapacaksan yap."
#
#  EKSIK OLAN YAPISAL PARCA BUYDU: kurallarimiz vardi, sayaclarimiz olmaya
#  basladi, ama KIRMIZI BIR SAYAC VARKEN YAYINI DURDURAN HICBIR SEY YOKTU.
#  Bir kural ancak yayini durdurabiliyorsa kuraldir; durduramiyorsa temennidir.
#
#  KAPSAM: yalniz YAYINDA olan sorular (yayin=true). Yayindan cekilmis soru
#  onarim kuyrugundadir, onu suclamak anlamsiz. Yayindakinde SIFIR TOLERANS.
#
#  DOKUZ KAPI (03.08 aksami Cem in bulgulariyla 6 dan 9 a cikti):
#    K1 D3  - "bu sik yanlis cunku dogru cevap X" (ogretmeyen aciklama)
#    K2 D12 - kanun kopyasi dili (bilumum, muteferri, munasebetiyle...)
#    K3 D12 - yapay zeka doldurma kaliplari
#    K4 D14 - hesap kodu THP'nin resmi adiyla uyusmuyor
#    K5 D2  - yanlis siklarda "Dogrusu:" hic yok
#    K6 D10 - ayni cumle birden fazla sikka yazilmis
#    K7 D24 - "belirli sartlarda" deyip sartlari saymayan muglak ifade
#    K8 D18 - sinir sorusu ama listenin kalani sayilmamis (TTK m.516 vakasi)
#    K9     - eskimis kurum adi (IMKB -> Borsa Istanbul, 2013)
#
#  KARAR: hepsi 0 ise GECER, degilse DURDU. Karar dosyaya yazilir; yayin
#  akisindaki her adim once bu dosyaya bakar.
#
#  ONEMLI: bu script KASAYA DOKUNMAZ. Yalniz olcer ve karar verir. Kirmizi
#  soruyu yayindan indirmek AYRI bir adimdir (-uygula), cunku toplu yayindan
#  indirme Cem'in gorup onaylamasi gereken bir karardir.
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/yayin-kapisi.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/yayin-kapisi.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 5
  if($j.Length -gt 60000){ $j = ConvertTo-Json -Depth 2 -InputObject @{ karar='DURDU'; sebep='rapor sismis - icerik sizmis olabilir'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  # Kapi COKERSE de GECER demez - olculemeyen sey guvenli sayilmaz.
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); karar='DURDU'
    sebep='kapi kosarken hata aldi - olculemeyen sey guvenli sayilmaz'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
# 08.08: diger motorlarda olan KULLANICI ORTAMI yedegi burada yoktu; elle
# calistirildiginda 401 aliniyordu. Ayni desen eklendi.
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- Turkce duyarsiz sadelestirme: KARAKTER KARAKTER (regex degil).
# 03.08 dersi: -replace ile Turkce harf donusturmek "TAŞITLAR"i "TAS TLAR" yapip
# sahte uyusmazlik uretmisti. Acik esleme gizli surpriz birakmaz.
$HARF = @{
  [char]0x0130='I'; [char]0x0131='I'; [char]'i'='I'; [char]'I'='I'
  [char]0x015E='S'; [char]0x015F='S'; [char]0x011E='G'; [char]0x011F='G'
  [char]0x00DC='U'; [char]0x00FC='U'; [char]0x00D6='O'; [char]0x00F6='O'
  [char]0x00C7='C'; [char]0x00E7='C'
}
function Sade([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}

# --- THP resmi kod->ad ---
# 03.08 - TEK DOSYA DEGIL HEPSI: msugt-thp-tam.json 199 hesap tasiyor ve
# 100 KASA / 102 BANKALAR / 600 YURTICI SATISLAR / 730 GENEL URETIM GIDERLERI
# ICERMIYOR. Butun msugt*.json birlesince 230 hesap ve hepsi var.
$RESMI = @{}
foreach($f in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $thp = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($thp.belgeler)){
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $RESMI.ContainsKey($m.Groups[1].Value)){ $RESMI[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() }
    }
  } catch {}
}
if($RESMI.Count -lt 200){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); karar='DURDU'
    sebep="THP resmi listesi okunamadi (okunan: $($RESMI.Count)) - hesap kodu kapisi calisamaz" })
  Write-Host "DURDU: THP listesi okunamadi."; exit 1
}

# ============================================================================
#  03.08 - CEM: "bunun digerlerine yapalim, sadece bu degil."
#
#  BU ITIRAZ COK BUYUK BIR KUSUR ORTAYA CIKARDI: kapi yalniz YAYINDA olan
#  sorulari tariyordu (yayin=eq.true). Yayinda SIFIR soru var. Yani on kapinin
#  ONU DA HICBIR SEY OLCMUYORDU - 27.478 sorunun hepsi denetim disindaydi.
#  Kapilari kurup "olculuyor" demek, olctuklerini dogrulamadan, bos guvendi.
#
#  ARTIK TUM KASA taranir. Karar (GECER/DURDU) yine YAYINDAKILERE bakar -
#  cunku ogrenciye giden odur - ama SAYIM tum kasayi kapsar. Boylece Cem
#  27.478 soruya degil TEK RAPORA bakar; hangi kusur kac soruda, gorur.
# ============================================================================
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
$yayindaSayi = @($kasa | Where-Object { $_.yayin -eq $true }).Count
Write-Host ("Kasa: {0} soru (yayinda: {1})" -f $kasa.Count, $yayindaSayi)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu." }

# --- desenler ---
# K1 (D3): "X yanlis CUNKU dogru cevap Y" kalibi - ogretmez, sadece isaret eder
$reD3 = [regex]'(?i)(yanl[ıi][şs]t[ıi]r|yanl[ıi][şs]\s+olup|do[ğg]ru\s+de[ğg]ildir)[^.]{0,60}\b[çc][üu]nk[üu]\b[^.]{0,60}(do[ğg]ru\s+(cevap|se[çc]enek|[şs][ıi]k)|as[ıi]l\s+cevap)'
$reD3b = [regex]'(?i)\bdo[ğg]ru\s+(cevap|se[çc]enek|[şs][ıi]k)\s*[:\(]?\s*[A-E]\b[^.]{0,30}(oldu[ğg]u\s+i[çc]in|olmas[ıi]\s+nedeniyle)'
$reKanun = [regex]'(?i)bil[üu]mum|m[üu]teferri|m[üu]nasebetiyle|i[şs]bu\b|mezk[üu]r|mutazamm[ıi]n|keyfiyet'
$reYZ    = [regex]'(?i)[öo]nemli bir husus|dikkat edilmesi gereken nokta|sonu[çc] olarak|[öo]zetle\s*,|bu ba[ğg]lamda|unutulmamal[ıi]d[ıi]r'
$reDogrusu = [regex]'(?i)do[ğg]rusu\s*:'
# 08.08: olumsuz kok tespiti - bu kaliplarda isaretlenmeyen siklar DOGRU ifadedir.
$reOlumsuzKok = [regex]'(?i)(yanl[ıi][şs]t[ıi]r|hangisi\s+yanl[ıi][şs]|de[ğg]ildir|s[öo]ylenemez|bulunmaz|yer\s+almaz|gerekmez|ba[ğg]da[şs]maz)'
$BIRIM = @('TL','LIRA','USD','EUR','ADET','GUN','AY','YIL','SAAT','KG','TON','M2','MT','PUAN','KURUS','TANE','KISI','TAKSIT')
# 03.08 - Cem: "hesap planina gore kontrol et." Kontrol zaten 199 hesabin
# tamamina bakiyordu; eksik olan DESENDI. Kucuk harfli ad, tireli yazim ve
# "Ad (NNN)" bicimi goruluyordu. Adsiz "620 numarali hesap" disarida.
$reHesap  = [regex]'(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*(?!numaral|no.?lu|say[ıi]l|adet|kalem|tane|hesab|hesap|kodlu|nolu)([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})'
$reHesap2 = [regex]'([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})\s*\(\s*([1-8]\d{2})\s*\)'
# Onek eslesmesi (03.08): Turkce ekler yuzunden birebir kelime esitligi sahte
# alarm uretiyordu ("KARSILIKLAR"~"KARSILIK", "HES"~"HESAPLANAN"). Biri digerinin
# oneki ise (>=3 harf) ayni kok sayilir; "GELIR"/"GELECEK" yine ayrilir.
function AdUyuyorMu([string]$iddia, [string]$resmi){
  $a = @((Sade $iddia) -split ' ' | Where-Object { $_.Length -ge 3 })
  $b = @((Sade $resmi) -split ' ' | Where-Object { $_.Length -ge 3 })
  if($a.Count -eq 0 -or $b.Count -eq 0){ return $true }
  foreach($k in $a){
    foreach($r in $b){
      if($k.StartsWith($r) -or $r.StartsWith($k)){ return $true }
    }
  }
  return $false
}

# K7 (03.08, Cem): "bulduklarimizi tek ornege degil CALISMANIN TUMUNE yay."
# Hakli - "muglak ifade" kuralini yalniz isteme koymustum; mevcut kasada kac
# tane var bilmiyorduk. Artik yayindaki her soruda da olculuyor.
$reMuglak = [regex]'(?i)belirli\s+[şs]artlar|baz[ıi]\s+hallerde|kanunda\s+[öo]ng[öo]r[üu]len\s+durum|gerekli\s+ko[şs]ullar\s+sa[ğg]lan|mevzuatta\s+belirtilen\s+[öo]l[çc][üu]'
# K8 (03.08, Cem: "bunu daha once bulmustuk, digerlerini de duzeltiyoruz deme").
# D18 (tahdidi liste tam yazilir) yine YALNIZ ISTEMDE kalmisti; kasadaki mevcut
# sorularda olculmuyordu. Kaba ama isleyen olcu: soru bir SINIR sorusuysa
# (olumlu ya da olumsuz) aciklamada en az iki SAYIM ogesi bulunmali - yoksa
# ogrenci listenin kalanini goremiyor demektir. (TTK m.516 vakasi: uc bent var,
# aciklama yalniz birini anlatiyordu.)
$reSinirSoru = [regex]'(?i)hangisi(nde)?\s+.{0,80}(uygulanmaz|kapsam\s*d[ıi][şs][ıi]|say[ıi]lmaz|girmez|de[ğg]ildir|dahil\s+de[ğg]il)|hangi(si)?\s+.{0,80}(zorunlu|mutlaka|yer\s+alma|dahildir|say[ıi]l[ıi]r|gerekir|aran[ıi]r)|istisna|kapsam[ıi]\s+d[ıi][şs][ıi]nda'
# K9 (03.08, Cem'in okudugu kartta gorunen): ESKIMIS KURUM ADLARI.
# Kehribar kartta "IMKB sirketlerinde" yaziyordu; IMKB 2013'te BORSA ISTANBUL
# oldu. 2026 adayina 13 yillik eski isim vermek, Cem'in tarih itirazinin
# KURUM ayagidir: banka eskimis gorunur. Mulga adlar burada sayilir.
$reEskiKurum = [regex]'(?i)\b[İI]MKB\b|[İI]stanbul\s+Menkul\s+K[ıi]ymetler\s+Borsas|Sanayi\s+ve\s+Ticaret\s+Bakanl|G[üu]mr[üu]k\s+M[üu]ste[şs]arl|Bay[ıi]nd[ıi]rl[ıi]k\s+ve\s+[İI]sk[âa]n\s+Bakanl|Devlet\s+Planlama\s+Te[şs]kilat'
# K10 (03.08, Cem: "sinava gireceklere eski Turkce ogretmeyelim"): kanunun eski
# lafzi guncel karsiligi ANILMADAN kullanilmis mi? VUK m.275 "genel imal
# giderleri" der; THP'de hesap adi "730 GENEL URETIM GIDERLERI" ve sinav bu
# terimi sorar. Ikisi birlikte gecerse sorun yok - yalniz eskisi gecerse aday
# sinavda terimi tanimaz.
$reEskiTerim = [regex]'(?i)genel\s+imal\s+gider|mubayaa|muhammen\s+bedel'
$reYeniTerim = [regex]'(?i)genel\s+[üu]retim\s+gider|sat[ıi]n\s+alma|tahmini\s+bedel'
$reSayimOge  = [regex]'(?i)(^|\s)[a-ıi]\)\s|(^|\s)\d\s*[\)\.]\s|;\s|·|•|\bbirincisi\b|\bikincisi\b|\bucuncusu\b|\b[üu][çc][üu]nc[üu]s[üu]\b'
$K = [ordered]@{ K1_d3=0; K2_kanun_kopyasi=0; K3_yz_kokusu=0; K4_hesap_kodu=0; K5_dogrusu_yok=0; K6_ayni_cumle=0; K7_muglak_ifade=0; K8_liste_eksik=0; K9_eskimis_kurum=0; K10_eski_terim=0 }
$kirmiziId = @{}
$ornek = New-Object System.Collections.Generic.List[object]
# Iki ayri sayac: TUM KASA (envanter) ve YAYINDAKI (karar). Karar yayindakine
# bakar cunku ogrenciye giden odur; envanter tum kasayi kapsar cunku Cem'in
# gormesi gereken resim odur.
$KY = [ordered]@{}   # yalniz yayinda olanlar
foreach($kk in $K.Keys){ $KY[$kk] = 0 }
$kirmiziYayin = @{}
function Isaretle($kapi, $s, $detay){
  $script:K[$kapi]++
  $script:kirmiziId["$($s.id)"] = 1
  if($s.yayin -eq $true){ $script:KY[$kapi]++; $script:kirmiziYayin["$($s.id)"] = 1 }
  if($script:ornek.Count -lt 40){
    $script:ornek.Add([ordered]@{ kapi=$kapi; soru_id="$($s.id)"; ders="$($s.ders)"; yayinda=$s.yayin; detay=$detay })
  }
}

foreach($s in $kasa){
  $dh = "$($s.dogru)".Trim().ToUpper()
  $yanlisMetin = ''
  $dogrusuVar = 0; $yanlisSik = 0
  $gorulen = @{}
  foreach($h in 'A','B','C','D','E'){
    $m=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$h]){ $m="$($s.aciklama.$h)" } } catch {}
    if($m.Trim().Length -lt 5){ continue }
    if($h -eq $dh){ continue }
    $yanlisSik++; $yanlisMetin += ' ' + $m
    if($reDogrusu.IsMatch($m)){ $dogrusuVar++ }
    $anah = Sade $m
    if($anah.Length -gt 20){ if($gorulen.ContainsKey($anah)){ Isaretle 'K6_ayni_cumle' $s "iki sikta ayni metin" }; $gorulen[$anah]=1 }
  }
  $tumAciklama = $yanlisMetin
  try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $tumAciklama += ' ' + "$($s.aciklama.$dh)" } } catch {}

  if($reD3.IsMatch($tumAciklama) -or $reD3b.IsMatch($tumAciklama)){ Isaretle 'K1_d3' $s 'ogretmeyen kalip: "yanlis cunku dogru cevap X"' }
  if($reKanun.IsMatch($tumAciklama)){ Isaretle 'K2_kanun_kopyasi' $s 'kanun kopyasi dili' }
  if($reYZ.IsMatch($tumAciklama)){ Isaretle 'K3_yz_kokusu' $s 'yapay zeka doldurma kalibi' }
  if($reMuglak.IsMatch($tumAciklama)){ Isaretle 'K7_muglak_ifade' $s 'bilgi vaat edip vermeyen kalip ("belirli sartlarda" deyip sartlari saymamis)' }
  if($reEskiKurum.IsMatch($tumAciklama)){ Isaretle 'K9_eskimis_kurum' $s 'eskimis kurum adi (IMKB -> Borsa Istanbul gibi)' }
  if($reEskiTerim.IsMatch($tumAciklama) -and -not $reYeniTerim.IsMatch($tumAciklama)){ Isaretle 'K10_eski_terim' $s 'kanun lafzi guncel karsiligi anilmadan kullanilmis (genel imal gideri -> genel uretim gideri)' }
  # K8: sinir sorusu ama aciklamada listenin kalani yok
  if($reSinirSoru.IsMatch("$($s.soru)")){
    $dm2=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $dm2="$($s.aciklama.$dh)" } } catch {}
    if(($reSayimOge.Matches($dm2)).Count -lt 2){
      Isaretle 'K8_liste_eksik' $s 'sinir sorusu ama Kural parcasinda listenin kalani sayilmamis (D18)'
    }
  }
  # 08.08 K5 KOR NOKTASI (kendi el yazimi partimde 39 soru HAKSIZ yere kirmizi
  # dustu): OLUMSUZ KOKLU soruda ("asagidakilerden hangisi YANLISTIR/degildir")
  # isaretlenmeyen siklar TUZAK DEGIL, DOGRU IFADELERDIR - onlarda "Dogrusu:"
  # ARANMAZ, aranmasi da yanlis olur (dogru bir ifadenin "dogrusu" olmaz).
  # Bu kaliplarda yuk DOGRU sikkin aciklamasindadir; kural orada aranir.
  $olumsuzKok = $reOlumsuzKok.IsMatch("$($s.soru)")
  if($olumsuzKok){
    $dm3=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $dm3="$($s.aciklama.$dh)" } } catch {}
    if($dm3.Trim().Length -lt 120){ Isaretle 'K5_dogrusu_yok' $s 'olumsuz kok ama dogru sikkin aciklamasi da yok/kisa' }
  }
  elseif($yanlisSik -ge 3 -and $dogrusuVar -eq 0){ Isaretle 'K5_dogrusu_yok' $s "yanlis sik $yanlisSik, Dogrusu 0" }

  $tum = "$($s.soru) $tumAciklama"
  $ciftler = New-Object System.Collections.Generic.List[object]
  foreach($mm in $reHesap.Matches($tum)){  $ciftler.Add(@{ kod=$mm.Groups[1].Value; ad=$mm.Groups[2].Value.Trim() }) }
  foreach($mm in $reHesap2.Matches($tum)){ $ciftler.Add(@{ kod=$mm.Groups[2].Value; ad=$mm.Groups[1].Value.Trim() }) }
  foreach($cf in $ciftler){
    $kod = $cf.kod; $ad = $cf.ad
    if($ad.Length -lt 4){ continue }
    $ilk = (Sade $ad) -split ' ' | Select-Object -First 1
    if($BIRIM -contains $ilk){ continue }
    if(-not $RESMI.ContainsKey($kod)){ continue }      # THP disi kod: ayri denetimin isi
    if(-not (AdUyuyorMu $ad $RESMI[$kod])){ Isaretle 'K4_hesap_kodu' $s "$kod yazilan '$ad' resmi '$($RESMI[$kod])'" }
  }
}

$toplamHepsi = 0; foreach($v in $K.Values){ $toplamHepsi += $v }
$toplamYayin = 0; foreach($v in $KY.Values){ $toplamYayin += $v }
# KARAR yayindakilere bakar (ogrenciye giden odur); ENVANTER tum kasayi kapsar.
# 03.08 - AMA "GECER" YAZISI YANILTICIYDI: yayinda 0 soru varken kapi yesil
# yaziyordu, oysa kasada 27.461 kirmizi soru duruyordu. Bos bir kapidan gecmek
# gecmek degildir. Yayinda soru yoksa karar artik "YAYIN YOK" - yesil degil.
# 08.08 (Cem: "acilisa kadar yetistirmek icin ne yapmali") - TEMIZ SORU ENVANTERI.
# Kapi "kac soru KIRMIZI" diyordu ama "kalan TEMIZ sorular hangi derste" demiyordu.
# Acilis paketi ancak temiz sorular DERSLERE YAYILMISSA kurulabilir; hepsi tek
# derste toplanmissa 130'luk bir deneme cikmaz. Bu doküm o kararı verdirir.
$temizDers = @{}
foreach($s in $kasa){
  if($kirmiziId.ContainsKey("$($s.id)")){ continue }
  $anahtar = "$($s.sinav)|$($s.ders)"
  if(-not $temizDers.ContainsKey($anahtar)){ $temizDers[$anahtar] = 0 }
  $temizDers[$anahtar]++
}
$temizSirali = [ordered]@{}
foreach($k in ($temizDers.Keys | Sort-Object { -$temizDers[$_] })){ $temizSirali[$k] = $temizDers[$k] }
Write-Host "`n--- TEMIZ (hicbir kapiya takilmayan) SORULAR: sinav|ders ---"
foreach($k in $temizSirali.Keys){ Write-Host ("   {0,-46} {1}" -f $k,$temizSirali[$k]) }
Write-Host ("   TEMIZ TOPLAM: {0}" -f ($kasa.Count - $kirmiziId.Count))

$karar = if($yayindaSayi -eq 0){ 'YAYIN YOK - olculecek soru bulunamadi' }
         elseif($toplamYayin -eq 0){ 'GECER' } else { 'DURDU' }
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  karar=$karar
  kasa_toplam=$kasa.Count
  yayinda_soru=$yayindaSayi
  kirmizi_soru_tum_kasa=$kirmiziId.Count
  kirmizi_soru_yayinda=$kirmiziYayin.Count
  temiz_soru_toplam=($kasa.Count - $kirmiziId.Count)
  temiz_ders_dagilimi=$temizSirali
  kapilar_tum_kasa=$K
  kapilar_yayinda=$KY
  toplam_ihlal_tum_kasa=$toplamHepsi
  toplam_ihlal_yayinda=$toplamYayin
  ornekler=$ornek.ToArray()
  kural='KARAR yayindaki sorulara bakar (ogrenciye giden odur). ENVANTER tum kasayi kapsar - Cem 27.478 soruya degil bu rapora bakar.'
  not='Bu kapi kasaya DOKUNMAZ, yalniz olcer. Kirmizi sorulari yayindan indirmek ayri ve Cem onayli bir adimdir.'
}
RaporYaz $rapor
Write-Host "`n=== YAYIN KAPISI: $karar ==="
Write-Host ("  {0,-22} {1,8}   {2,8}" -f 'KAPI', 'TUM KASA', 'YAYINDA')
foreach($k in $K.Keys){ Write-Host ("  {0,-22} {1,8}   {2,8}" -f $k, $K[$k], $KY[$k]) }
Write-Host ("  {0,-22} {1,8}   {2,8}" -f 'KIRMIZI SORU', $kirmiziId.Count, $kirmiziYayin.Count)
Write-Host ("  Kasa {0} soru, yayinda {1}" -f $kasa.Count, $yayindaSayi)
if($karar -eq 'DURDU'){ exit 1 }
