# ============================================================================
#  HAKEM SON OKUMA (03.08.2026)
#
#  CEM: "bunlari elimizdeki sorulara da uygulayacak miyiz, 'not aldim' deme."
#  Haklı. Bugun bulunan kusurlarin bir kismini REGEX yakalayamaz cunku ANLAM
#  isidir. Onlari yakalayacak tek sey, soruyu dayanagiyla birlikte okuyan bir
#  hakemdir. Bu script o hakemdir ve KASADAKI MEVCUT sorulara bakar.
#
#  ALTI KUSUR (hepsi bugun Cem'in bulduklari):
#   H1 tarih-rakam uyumsuzlugu  - "18 Aralik 2024" senaryosunda 28,70 TL/EUR kuru
#   H2 islem yonu celiskisi     - "pesin odemis ... tahsil edilmistir" (Denizli Mermer)
#   H3 parcalar arasi celiski   - Kural "ihtiyaridir" derken Akilda kalsin "girer"
#   H4 hesap kodu yanlisi       - 253 personel avansi (THP listesiyle karsilastirilir)
#   H5 hesap tutmuyor           - dogru sikkin rakami aciklamadaki islemden cikmiyor
#   H6 dayanakta olmayan iddia  - metinde gecmeyen oran/tutar/madde
#
#  CIKTI: kusurlu sorularin ID'si + kusur turu + tek cumlelik gerekce.
#  KASAYA YAZMAZ, YAYINDAN INDIRMEZ - yalniz raporlar. Karar Cem'in.
#  Soru metni ozel kovaya, rapora yalniz SAYI (03.08 sizinti dersi).
#
#  VARSAYILAN KURU (0 USD): ornek istemleri gosterir, cagri YAPMAZ.
#  Parali kosu: veri/tetik/hakem-son-okuma.txt icinde "BAS" gecmesi sart.
#
#  ENV: SUPABASE_SERVICE_KEY (+ parali icin ANTHROPIC_API_KEY)
# ============================================================================
param([switch]$uygula, [int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/hakem-son-okuma-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 5
  if($j.Length -gt 40000){
    Write-Host "!! RAPOR SISMIS - icerik sizmis olabilir, yazilmadi."
    $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length }
  }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$DK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- THP listesi (H4 icin hakemin elinde olacak) ---
# 03.08 - TUM msugt dosyalari (kaynak-butunluk robotu bu dosyayi yakaladi):
# msugt-thp-tam.json tek basina 199 hesap; 100 KASA, 102 BANKALAR, 600, 730
# msugt-thp2.json'da. Hakem eksik listeyle yargilarsa dogru kodu yanlis sanar.
$THP = ''
$gorulen = @{}
$c = New-Object System.Collections.Generic.List[string]
foreach($tf in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $tv = Get-Content $tf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($tv.belgeler)){
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $gorulen.ContainsKey($m.Groups[1].Value)){
        $gorulen[$m.Groups[1].Value] = 1
        $c.Add(($m.Groups[1].Value + ' ' + $m.Groups[2].Value.Trim()))
      }
    }
  } catch {}
}
if($c.Count -ge 50){ $THP = ($c | Sort-Object) -join "`n" }
Write-Host ("Hakem THP listesi: {0} hesap" -f $c.Count)

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu." }

function IstemKur($s){
  $sik = ''
  foreach($h in 'A','B','C','D','E'){ try { if($s.siklar.PSObject.Properties[$h]){ $sik += "$h) $($s.siklar.$h)`n" } } catch {} }
  $acik = ''
  foreach($h in 'A','B','C','D','E'){ try { if($s.aciklama.PSObject.Properties[$h]){ $acik += "$h) $($s.aciklama.$h)`n" } } catch {} }
  $thpBlok = if($THP -ne ''){ "`n=== TEKDUZEN HESAP PLANI (resmi kod listesi) ===`n$THP`n=== BITTI ===`n" } else { '' }
@"
Sen bir SMMM sinav sorusu HAKEMISIN. Asagidaki soruyu ve aciklamalarini oku,
YALNIZCA su alti kusuru ara. Kusur yoksa temiz de - kusur UYDURMA.

H1 TARIH-RAKAM UYUMSUZLUGU: senaryo tarihi ile verilen yila bagli deger (kur,
   had, asgari ucret, tarife) birbirini tutmuyor mu? Deger soruda "verilmis
   veri" olarak sunulmussa bu TEK BASINA kusur degildir; ama tarihe gore
   ACIKCA aykiriysa isaretle.
H2 ISLEM YONU CELISKISI: odeme/tahsil, borc/alacak, alis/satis, gelir/gider
   ters kullanilmis mi? (Ornek kusur: "pesin ODEMIS ve ayni gun TAHSIL
   edilmistir" - odeme yapan tahsilat yapmis olamaz.)
H3 PARCALAR ARASI CELISKI: aciklamanin bir parcasi otekini yalanliyor mu?
   (Ornek: Kural "katilmasi IHTIYARIDIR" derken Akilda kalsin "maliyete GIRER"
   diye basliyor.)
H4 HESAP KODU YANLISI: metinde gecen hesap kodu-ad eslesmesi yukaridaki resmi
   listeyle tutmuyor mu? (Ornek: "253 Personel Avanslari" - 253 resmi listede
   TESIS, MAKINE VE CIHAZLAR'dir.)
H5 HESAP TUTMUYOR: dogru sikkin rakami, aciklamada anlatilan islemden ADIM
   ADIM cikmiyor mu? Once sen hesapla, sonra karsilastir.
H6 DAYANAKTA OLMAYAN IDDIA: aciklamada gecen oran/tutar/madde numarasi
   asagidaki dayanak metninde YOK mu? Dayanak verilmemisse bu kusuru ARAMA.
H8 TAHDIDI LISTE EKSIK: soru bir SINIR sorusuysa ("hangisi uygulanmaz",
   "hangi bilgi mutlaka yer almalidir") dayanaktaki listenin TAMAMI aciklamada
   sayilmis mi? Yalniz sorulan bendi anlatip otekileri atlamissa isaretle.
   (Ornek kusur: TTK m.516/2 UC bent sayar - sonraki olaylar, Ar-Ge,
   yoneticilere odenen mali menfaatler - aciklama yalniz ucuncusunu anlatmis.)
: "belirli sartlarda", "bazi hallerde", "kanunda ongorulen
   durumlarda" gibi bilgi VAAT EDIP VERMEYEN kalip var mi? Sartlar sayilmamissa
   isaretle. Bu, hic yazmamaktan kotudur: ogrenci bir sey ogrendigini sanir,
   sinavda sart sorulunca bilemez.
$thpBlok
DERS: $($s.ders) | KONU: $($s.konu) | KAYNAK: $($s.kaynak)

SORU:
$($s.soru)

SIKLAR:
$sik
DOGRU SIK: $($s.dogru)

ACIKLAMALAR:
$acik
CIKTI - SAF JSON, baska hicbir sey yazma:
{"temiz":true}
ya da
{"temiz":false,"kusurlar":[{"kod":"H2","gerekce":"<tek cumle>"}]}
"@
}

# --- KURU MOD ---
if(-not $uygula){
  $ornekYol = Join-Path $kok 'veri/hakem-ornek-istem.txt'
  $sb = New-Object Text.StringBuilder
  for($n=0; $n -lt [Math]::Min(5, $kasa.Count); $n++){
    [void]$sb.AppendLine("===== ORNEK $($n+1) =====")
    [void]$sb.AppendLine((IstemKur $kasa[$n])); [void]$sb.AppendLine('')
  }
  Set-Content -LiteralPath $ornekYol -Value $sb.ToString() -Encoding UTF8
  # Maliyet tahmini: istem uzunlugundan token tahmini (~4 karakter = 1 token)
  $ortIstem = 0
  for($n=0; $n -lt [Math]::Min(20, $kasa.Count); $n++){ $ortIstem += (IstemKur $kasa[$n]).Length }
  $ortIstem = [Math]::Round($ortIstem / [Math]::Min(20, $kasa.Count))
  $girisTok = [Math]::Round($ortIstem / 4)
  $maliyet = [Math]::Round(($kasa.Count * $girisTok * 1.0/1000000) + ($kasa.Count * 120 * 5.0/1000000), 2)
  RaporYaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD)'
    kasa=$kasa.Count; thp_kod=$(if($THP -ne ''){199}else{0})
    ortalama_istem_karakter=$ortIstem; tahmini_giris_token_soru=$girisTok
    tahmini_maliyet_usd_tam_kasa=$maliyet
    fiyat_katsayisi='1 USD/M giris + 5 USD/M cikis (Haiku 4.5); cikis ~120 token/soru varsayimi'
    not='Hicbir API cagrisi YAPILMADI. Ornek istemler veri/hakem-ornek-istem.txt (DEPOYA GIRMEZ).'
  })
  Write-Host ("KURU: kasa {0} | ort istem {1} karakter | TAHMINI TAM KASA MALIYETI {2} USD" -f $kasa.Count, $ortIstem, $maliyet)
  exit 0
}

# --- PARALI (yalniz tetikte BAS varsa workflow buraya gelir) ---
if(-not $env:ANTHROPIC_API_KEY){ RaporYaz @{ durum='KIRMIZI'; sebep='ANTHROPIC_API_KEY yok' }; exit 1 }
$MODEL='claude-haiku-4-5-20251001'
$AH=@{ 'x-api-key'=$env:ANTHROPIC_API_KEY; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' }
$KOVA='onarim-taslak'; $STOR="https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$SK=@{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
$etiketAdi = "hakem-$(Get-Date -Format 'ddMM-HHmm')"

$parti = @($kasa | Select-Object -First $(if($sinir -gt 0){$sinir}else{$kasa.Count}))
$tIn=0;$tOut=0;$temizSayi=0;$kusurluSayi=0;$bozuk=0
$kusurDagilim=@{}; $sonuc=New-Object System.Collections.Generic.List[object]
Write-Host ("HAKEM basliyor: {0} soru" -f $parti.Count)
for($n=0; $n -lt $parti.Count; $n++){
  $s = $parti[$n]
  $govde = ConvertTo-Json -Depth 5 -Compress -InputObject @{ model=$MODEL; max_tokens=800; messages=@(@{ role='user'; content=(IstemKur $s) }) }
  try { $c = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $AH -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 }
  catch { $bozuk++; continue }
  $tIn += [int]$c.usage.input_tokens; $tOut += [int]$c.usage.output_tokens
  $metin=''; foreach($p in @($c.content)){ if($p.type -eq 'text'){ $metin += "$($p.text)" } }
  $temiz = ($metin -replace '(?s)^\s*```(?:json)?\s*','' -replace '(?s)\s*```\s*$','').Trim()
  $o=$null; try { $o = $temiz | ConvertFrom-Json } catch { $bozuk++; continue }
  if($o.temiz -eq $true){ $temizSayi++; continue }
  $kusurluSayi++
  foreach($k in @($o.kusurlar)){ $kusurDagilim["$($k.kod)"] = 1 + $kusurDagilim["$($k.kod)"] }
  $sonuc.Add([ordered]@{ soru_id="$($s.id)"; ders="$($s.ders)"; yayinda=$s.yayin; kusurlar=@($o.kusurlar) })
  if((($n+1) % 50) -eq 0){ Write-Host ("  {0}/{1} | kusurlu {2}" -f ($n+1), $parti.Count, $kusurluSayi) }
}
# Kusurlu listesi OZEL kovaya (icerik depoya girmez)
$yazildi=0; $geri=-1
try {
  $govde2 = ConvertTo-Json -Depth 6 -InputObject $sonuc.ToArray()
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/$etiketAdi.json" -Method Post -Headers ($SK + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde2)) -TimeoutSec 180 | Out-Null
  $yazildi = $sonuc.Count
  $h2 = Invoke-WebRequest -Uri "$STOR/object/$KOVA/$etiketAdi.json" -Headers $SK -UseBasicParsing -TimeoutSec 180
  $m2 = if($h2.RawContentStream){ [Text.Encoding]::UTF8.GetString($h2.RawContentStream.ToArray()) } else { "$($h2.Content)" }
  $geri = @($m2 | ConvertFrom-Json | Where-Object { $null -ne $_ }).Count
} catch { $geri = -1 }

$maliyet = [Math]::Round(($tIn*1.0/1000000)+($tOut*5.0/1000000),4)
$dag=[ordered]@{}; foreach($k in ($kusurDagilim.Keys|Sort-Object)){ $dag[$k]=$kusurDagilim[$k] }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='HAKEM (PARALI, kasaya YAZILMADI)'
  model=$MODEL; okunan=$parti.Count
  temiz=$temizSayi; kusurlu=$kusurluSayi; bozuk_cevap=$bozuk
  kusur_dagilimi=$dag
  giris_token=$tIn; cikis_token=$tOut; maliyet_usd=$maliyet
  liste_yeri="Supabase Storage / kova '$KOVA' (OZEL) / $etiketAdi.json"
  yazilan=$yazildi; geri_okuma=$geri
  durum=$(if($geri -eq $sonuc.Count){'TAMAM'}else{'KIRMIZI - liste yazilamadi'})
  not='Kasaya YAZILMADI, yayindan INDIRILMEDI. Karar Cem in.'
})
Write-Host ("HAKEM BITTI: temiz {0} | kusurlu {1} | maliyet {2} USD | geri okuma {3}" -f $temizSayi,$kusurluSayi,$maliyet,$geri)
if($geri -ne $sonuc.Count){ exit 1 }
