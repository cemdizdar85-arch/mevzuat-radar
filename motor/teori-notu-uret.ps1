# TEORİ NOTU ÜRETİCİ — SGS kaynaksız 6 ders (08.09.2026, Cem "SGS'de dışladığımız 6 dersi kuralım beklerken")
# Türkçe, Matematik, Yabancı Dil, Atatürk İlkeleri ve İnkılap Tarihi, Ekonomi, Maliye: mevzuat metni yok → kaynak = TEORİ NOTU (ders kitabı bilgisi).
# 03.09 emsali: teori-notlari-20260903-sgs-eko-maliye.json (Cem "2 yap"). Ambarda 304 not var; eksik konular için not yazılır.
#   Yazar  : Opus 5 (olgu doğruluğu; tarih/olay/formül) — Türkçe harfli metin (kaynak ASCII olursa model soruyu da ASCII yazar, 02.09 dersi)
#   Denetçi: Sonnet 5 — her cümleyi doğrular; KUŞKULU notlar yüklenmez, inceleme listesine düşer (Cem/GM okur, düzeltilir)
#   Çıktı  : veri/mevzuat/teori-notlari-<tarih>-sgs-genel.json (robot mevzuat-yukle bunu okur; SERT KAPI için repo temsili şart)
#            + ambara anında POST (pilot bugün koşsun) + veri/fabrika/teori-notu-inceleme-<tarih>.md
# Kullanım: powershell -NoProfile -File motor/teori-notu-uret.ps1 -Kontrol           (0 USD: eksik konu listesi)
#           powershell -NoProfile -File motor/teori-notu-uret.ps1 -Ders 'Ekonomi|Maliye' -Adet 5   (pilot)
#           powershell -NoProfile -File motor/teori-notu-uret.ps1                    (hepsi)
param([string]$Plan='veri/sinav/plan-sgs-t1-genel.json',[string]$Ders='',[int]$Adet=0,[switch]$Kontrol,[switch]$YuklemeYok,
  [string]$YazarModel='claude-opus-5',[string]$DenetciModel='claude-sonnet-5',
  [string]$YalnizYukle='')   # 08.09 Cem "bunu sen de yapabilirsin, niye para veriyoruz": notları GM oturumda yazar, bu mod yalnız verilen json'daki belgeleri ambara yükler (0 USD)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path; $kok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$KEY=$env:SUPABASE_SERVICE_KEY; if(-not $KEY){ $KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok' }
$SB_URL='https://bjrleanjpyujtajmazxn.supabase.co'; $H=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
if($YalnizYukle){
  $yol=$(if(Test-Path $YalnizYukle){ $YalnizYukle } else { Join-Path $kok $YalnizYukle }); $pk=ConvertFrom-Json -InputObject (Get-Content $yol -Raw -Encoding UTF8)
  $ok=0; $hata=0
  foreach($b in @($pk.belgeler)){ if(-not $b -or -not $b.kaynak_ad -or -not $b.metin){ continue }
    if("$($b.metin)".Length -lt 600){ Write-Host "  KISA, atlandı: $($b.kaynak_ad) ($("$($b.metin)".Length) kr)" -ForegroundColor Yellow; $hata++; continue }
    if("$($b.metin)" -notmatch '[çğıöşüÇĞİÖŞÜ]'){ Write-Host "  TÜRKÇE HARF YOK, atlandı: $($b.kaynak_ad)" -ForegroundColor Yellow; $hata++; continue }
    try{ $q=[uri]::EscapeDataString("$($b.kaynak_ad)"); Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?kaynak_ad=eq.$q" -Headers $H -TimeoutSec 90 | Out-Null
      $gov=[ordered]@{ tur='teori-notu'; kaynak_ad="$($b.kaynak_ad)"; baslik="$($b.baslik)"; metin="$($b.metin)"; kaynak_url=''; belge_tarihi=$null }
      Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $gov -Depth 4 -Compress))) -TimeoutSec 90 | Out-Null; $ok++ }
    catch{ Write-Host "  HATA $($b.kaynak_ad): $($_.Exception.Message)" -ForegroundColor Red; $hata++ } }
  "yüklendi $ok · atlanan/hata $hata · dosya $yol"; exit 0
}
function Katla([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
function Liste($yol){ $j=ConvertFrom-Json -InputObject (Get-Content $yol -Raw -Encoding UTF8); $a=@($j); if($a.Count -eq 1 -and $j.PSObject.Properties['SyncRoot']){ $a=@($j.SyncRoot) }; return @($a | ForEach-Object { "$_" }) }
# --- mevcut notlar (ambar) ---
# PS 5.1: Invoke-RestMethod JSON dizisini boruya TEK nesne verir → ForEach 1 kez döner (08.09 ölçüldü: "ambarda teori notu: 1"); foreach ile açılır
$rNot=Invoke-RestMethod -Uri "$SB_URL/rest/v1/dokumanlar?select=kaynak_ad&or=(kaynak_ad.ilike.TEORI%25,kaynak_ad.ilike.Teori%20Notu%25)&limit=2000" -Headers $H -TimeoutSec 90
$mevcut=@(foreach($x in @($rNot)){ Katla ("$($x.kaynak_ad)" -replace '^(TEORI|Teori Notu)\s*-\s*','') })
"ambarda teori notu: $($mevcut.Count)"
function NotuVar([string]$konu){ $kok=@((Katla $konu) -split '\s+' | Where-Object { $_.Length -ge 5 } | ForEach-Object { $_.Substring(0,5) }); if(-not $kok.Count){ return $false }
  $gerek=[Math]::Min(2,$kok.Count); foreach($n in $mevcut){ if(@($kok | Where-Object { $n -match [regex]::Escape($_) }).Count -ge $gerek){ return $true } }; return $false }
# --- planın konuları (ders → konu listesi; seviyeler aynı listeyi taşır → kolay satırı yeter) ---
# PS harf ayırmaz: [string]$Plan parametresine nesne atanınca metne dönüyordu (08.09 ölçüldü: liste boş) → ayrı ad
$planYol=$(if(Test-Path $Plan){ $Plan } else { Join-Path $kok $Plan }); $planObj=ConvertFrom-Json -InputObject (Get-Content $planYol -Raw -Encoding UTF8)
$DERS_TARIF=@{ 'Turkce'='Türkçe (dil bilgisi, anlam bilgisi, paragraf, yazım ve noktalama; TDK kuralları)'; 'Matematik'='Matematik (temel matematik, cebir, problemler, fonksiyon, olasılık-istatistik; formül ve çözüm adımları)'; 'Yabanci Dil'='Yabancı Dil — İngilizce (dil bilgisi konusu Türkçe açıklanır, örnek cümleler İngilizce)'; 'Ataturk Ilke ve Inkilap Tarihi'='Atatürk İlkeleri ve İnkılap Tarihi (olay–tarih–sonuç zinciri; standart ders kitabı olguları)'; 'Ekonomi'='Ekonomi (mikro/makro iktisat teorisi; tanım, formül, grafik mantığı)'; 'Maliye'='Maliye (kamu maliyesi teorisi; ilgili kanun varsa adı — 5018 sayılı Kamu Malî Yönetimi ve Kontrol Kanunu gibi — anılır, madde uydurulmaz)' }
$hedefler=New-Object System.Collections.Generic.List[object]
foreach($s in @($planObj | Where-Object { $_.zorluk -eq 'kolay' })){ $dAd="$($s.dersAd)"; if($Ders -and $dAd -notmatch $Ders){ continue }
  foreach($kn in (Liste $s.konuDosya)){ if(-not (NotuVar $kn)){ $hedefler.Add([pscustomobject]@{ ders=$dAd; konu=$kn }) } } }
$ozet=$hedefler | Group-Object ders | ForEach-Object { "$($_.Name)=$($_.Count)" }
"notu olmayan konu: $($hedefler.Count) → $($ozet -join ' · ')"
if($Kontrol){ $hedefler | ForEach-Object { "  [$($_.ders)] $($_.konu)" }; "tahmini bedel: ≈$([math]::Round($hedefler.Count*0.14,1)) USD (Opus yazar ≈0,12 + Sonnet denetçi ≈0,02)"; exit 0 }
if($Adet -gt 0){ $hedefler=@($hedefler | Select-Object -First $Adet) }
$yazarIstem=@'
Sen SGS (Staja Giriş Sınavı, TESMER) hazırlık kitabı yazan bir öğretim üyesisin. Aşağıdaki KONU için bir TEORİ NOTU yaz. Bu not, soru üretecek ve soruyu denetleyecek sistemin TEK KAYNAĞI olacak; bu yüzden:
1. Yalnız standart ders kitaplarında yer alan, yerleşik ve tartışmasız bilgi yaz. Emin olmadığın olgu, tarih, sayı ya da isim varsa YAZMA; yazdığın her tarih/sayı doğru olmalı.
2. Yıla bağlı had, oran, tutar (asgari ücret, bütçe rakamı, enflasyon değeri gibi) YAZMA; kural ve mekanizmayı yaz.
3. Yapı (düz metin, başlıklar BÜYÜK HARF): TANIM VE KURAL · (varsa) FORMÜL VE ÇÖZÜM ADIMLARI · KÜÇÜK ÖRNEK (Matematik/Ekonomi'de sayısal, Türkçe'de cümle, Tarih'te olay-tarih-sonuç zinciri, İngilizce'de örnek cümleler + Türkçe açıklama) · SINAV TUZAĞI (adayın en sık karıştırdığı iki nokta) · SINAVDA NASIL SORULUR (tipik kök kalıbı).
4. 1.200–2.000 karakter. Türkçe harfler TAM (ş, ç, ğ, ı, ö, ü, İ); "yapay zeka" dili yok, resmî rapor dili yok, ders kitabı dili.
5. İlk satır: "TEORİ ({DERS_KISA}; mevzuat maddesi yok)." biçiminde künye. Maliye'de ilgili kanunun ADI anılabilir, madde numarası uydurulmaz.
6. Cevap YALNIZ JSON: {"baslik":"tek satır alt başlık (≤120 kr)","metin":"...not metni..."}
DERS: {DERS}
KONU: {KONU}
'@
$denetciIstem=@'
Sen titiz bir SGS ders kitabı editörüsün. Aşağıdaki TEORİ NOTUnu cümle cümle doğrula: yanlış olgu, yanlış tarih/isim/formül, tartışmalı ya da uydurma ifade, yıla bağlı sayı, Türkçe harf eksiği, konu dışına kayma var mı?
Cevap YALNIZ JSON: {"karar":"TEMIZ|KUSKULU","kusurlar":["..."],"duzeltme":"KUSKULU ise notun düzeltilmiş tam metni, TEMIZ ise boş"}
DERS: {DERS}  ·  KONU: {KONU}
=== NOT ===
{NOT}
'@
$KISA=@{ 'Turkce'='Türkçe'; 'Matematik'='matematik'; 'Yabanci Dil'='yabancı dil'; 'Ataturk Ilke ve Inkilap Tarihi'='inkılap tarihi'; 'Ekonomi'='iktisat'; 'Maliye'='maliye' }
$tarih=Get-Date -Format 'yyyyMMdd'; $ciktiYol=Join-Path $kok "veri\mevzuat\teori-notlari-$tarih-sgs-genel.json"; $incYol=Join-Path $kok "veri\fabrika\teori-notu-inceleme-$tarih.md"
$belgeler=New-Object System.Collections.Generic.List[object]; if(Test-Path $ciktiYol){ $e=ConvertFrom-Json -InputObject (Get-Content $ciktiYol -Raw -Encoding UTF8); foreach($b in @($e.belgeler)){ if($b){ $belgeler.Add($b) } } }
$inceleme=New-Object System.Collections.Generic.List[string]; $temiz=0; $kusku=0
function Coz($m){ $t="$m"; $i=$t.IndexOf('{'); $j=$t.LastIndexOf('}'); if($i -lt 0 -or $j -le $i){ return $null }; try{ return (ConvertFrom-Json -InputObject $t.Substring($i,$j-$i+1)) }catch{ return $null } }
foreach($h in $hedefler){
  $kaynakAd="TEORI - $($h.konu)"
  if(@($belgeler | Where-Object { "$($_.kaynak_ad)" -eq $kaynakAd }).Count){ continue }
  $ist=$yazarIstem.Replace('{DERS}',$DERS_TARIF[$h.ders]).Replace('{DERS_KISA}',$KISA[$h.ders]).Replace('{KONU}',$h.konu)
  $y=Invoke-ClaudeMesaj -Model $YazarModel -Icerik $ist -MaxTok 3000 -Effort medium
  $n=Coz $y.metin; if(-not $n -or -not $n.metin){ Write-Host "  BOZUK yazar çıktısı: $($h.konu)" -ForegroundColor Red; $inceleme.Add("- [$($h.ders)] $($h.konu): yazar çıktısı bozuk"); continue }
  $metin="$($n.metin)".Trim()
  $yd=Invoke-ClaudeMesaj -Model $DenetciModel -Icerik ($denetciIstem.Replace('{DERS}',$h.ders).Replace('{KONU}',$h.konu).Replace('{NOT}',$metin)) -MaxTok 3000 -Effort medium
  $d=Coz $yd.metin; $karar=$(if($d){ "$($d.karar)" } else { 'KUSKULU' })
  if($karar -eq 'TEMIZ'){ $temiz++ }
  else { $kusku++; $inceleme.Add("- [$($h.ders)] $($h.konu): " + ((@($d.kusurlar) | Select-Object -First 3) -join ' · ')); if($d -and "$($d.duzeltme)".Length -gt 600){ $metin="$($d.duzeltme)".Trim(); $inceleme.Add("    → denetçinin düzeltmesiyle yüklendi") } else { Write-Host "  KUŞKULU, yüklenmedi: $($h.konu)" -ForegroundColor Yellow; continue } }
  $belge=[ordered]@{ tur='teori-notu'; kaynak_ad=$kaynakAd; baslik="$($n.baslik)"; metin=$metin; kaynak_url=''; ders=$h.ders; uretim=(Get-Date -Format 'yyyy-MM-dd'); yazar=$YazarModel; denetci=$DenetciModel; denetci_karar=$karar }
  $belgeler.Add([pscustomobject]$belge)
  Write-Host "  NOT $($karar): [$($h.ders)] $($h.konu) ($($metin.Length) kr)" -ForegroundColor $(if($karar -eq 'TEMIZ'){'Green'}else{'Yellow'})
  $paket=[ordered]@{ aciklama="$(Get-Date -Format 'dd.MM.yyyy') — SGS kaynaksız 6 ders (Türkçe, Matematik, Yabancı Dil, İnkılap, Ekonomi, Maliye) teori notu paketi. Yazar $YazarModel, denetçi $DenetciModel; KUŞKULU notlar $incYol'de. Ders kitabı bilgisi; mevzuat maddesi yok. Cem 08.09 'dışladığımız 6 dersi kuralım'."; belgeler=@($belgeler.ToArray()) }
  [IO.File]::WriteAllText($ciktiYol,(ConvertTo-Json -InputObject $paket -Depth 5),[Text.UTF8Encoding]::new($false))
  if(-not $YuklemeYok){ try{ $q=[uri]::EscapeDataString($kaynakAd); Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?kaynak_ad=eq.$q" -Headers $H -TimeoutSec 90 | Out-Null
      $gov=[ordered]@{ tur='teori-notu'; kaynak_ad=$kaynakAd; baslik="$($n.baslik)"; metin=$metin; kaynak_url=''; belge_tarihi=$null }
      Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $gov -Depth 4 -Compress))) -TimeoutSec 90 | Out-Null }catch{ Write-Host "  AMBAR YÜKLEME HATASI ($kaynakAd): $($_.Exception.Message)" -ForegroundColor Red; $inceleme.Add("- [$($h.ders)] $($h.konu): ambara yüklenemedi ($($_.Exception.Message))") } }
}
[IO.File]::WriteAllText($incYol,("# Teori notu inceleme listesi — $(Get-Date -Format 'dd.MM.yyyy HH:mm')`n`nTEMİZ $temiz · KUŞKULU $kusku (denetçi düzeltmesi yeterliyse düzeltilmiş hâli yüklendi, değilse yüklenmedi)`n`n"+($inceleme -join "`n")+"`n"),[Text.UTF8Encoding]::new($false))
"bitti: temiz $temiz · kuşkulu $kusku · dosya $ciktiYol · inceleme $incYol"
$bz=Get-BedelOzet; "BEDEL: ≈$($bz.toplamUsd) USD"
