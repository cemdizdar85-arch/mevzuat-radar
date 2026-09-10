# KALIP GECE KOŞUCUSU — GENEL (08.09, B kovası 12; 07.09 kalip-parti-30.ps1'in genelleştirilmiş hâli)
# Plan dosyasından (json dizi) ders ders ardışık koşar; her satır: { "ders":"regex", "etiket":"sgs-fmuh-p31", "adet":6, "tavan":350, "zorluk":"zor|kolay|karisik",
#   "sinav":"SGS", "disla":"regex", "konuDosya":"", "eskiKaynak":"" }  — eskiKaynak doluysa KURTARMA (FAZ U) koşar, yeni soru üretilmez.
# Her ders için: tam hat (soru/uyarlama + adımlar + verilenler + giriş + ikiz + sim Sonnet + hakem + kör çözüm + hakem2), sonra seçim
# (hakem EVET ∧ sim ✓ ∧ kör ✓ ∧ hakem2 EVET — SORU-BASMA-KURALLARI 8.1), Kaydır-Çöz sayfası ve karne. Loglar veri/fabrika/kosucu-log/<plan>/.
# Kullanım: powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-sgs-08-09.json
param([Parameter(Mandatory=$true)][string]$Plan,[string]$Kok='',[switch]$SayfaYok,
  [double]$AylikTavan=2000,      # 08.09 Cem: konsolda aylık tavan 2.000 USD (GM göremez, Cem okudu)
  [double]$EmniyetPayi=300)      # tavana bu kadar kala koşucu durur: parti ortada ölmez, ödenen iş yazılmadan kaybolmaz (ağustos dersi)
$ErrorActionPreference='Continue'
# 08.09: Start-Process ile -File çağrısında param varsayılanındaki $PSScriptRoot BOŞ geldi (Split-Path hatası) → kök gövdede hesaplanır
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
if(-not $Kok){ $Kok=Split-Path $buDizin -Parent }
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
$harcanan=AyHarcama
"BEDEL EMNİYETİ: bu ay defterde ≈$([math]::Round($harcanan,2)) USD (defter 08.09'da başladı, öncesi yok) · tavan $AylikTavan · durma eşiği $($AylikTavan-$EmniyetPayi)"
if($harcanan -ge ($AylikTavan-$EmniyetPayi)){ throw "BEDEL EMNİYETİ: aylık harcama eşiğe ulaştı ($harcanan ≥ $($AylikTavan-$EmniyetPayi)); koşu başlatılmadı. Cem konsolu kontrol etsin." }
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

foreach($s in $satirlar){
  $sinav=$(if($s.PSObject.Properties['sinav'] -and $s.sinav){ "$($s.sinav)" } else { 'SGS' })
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
  else { $arg+=@('-DonemPencere','7'); if($s.PSObject.Properties['zorluk'] -and (@('zor','kolay','cokzor') -contains "$($s.zorluk)")){ $arg+=@('-Zorluk',"$($s.zorluk)") }; if($s.PSObject.Properties['disla'] -and "$($s.disla)"){ $arg+=@('-KonuDisla',"$($s.disla)") }; if($s.PSObject.Properties['konuDosya'] -and "$($s.konuDosya)"){ $arg+=@('-KonuDosya',"$($s.konuDosya)") } }
  # 08.09 13:40 ölçümü: Anthropic toplu sırası tıkandı (10:12'den beri 5 parti, 0 işlenen) → MEVZUAT_TOPLU=0 ortam değişkeni planı ezer, fazlar anlık koşar
  # 09.09 Cem "ara ara deneyelim orayı, rakamı düşürmemiz lazım": MEVZUAT_TOPLU='auto' → motor/toplu-sonda.ps1'in yazdığı sağlık dosyasına bakılır;
  # son 40 dk içinde "acik" ölçülmüşse bu etiket TOPLU (yarı fiyat), değilse anlık. Üretici ayrıca faz bazında MEVZUAT_TOPLU_BEKLE_DK sonra anlığa düşer.
  $topluAc=$false
  if($s.PSObject.Properties['toplu'] -and [bool]$s.toplu){
    if("$env:MEVZUAT_TOPLU" -eq 'auto'){
      $sagYol=Join-Path $Kok 'veri\fabrika\toplu-kuyruk-sagligi.json'
      if(Test-Path $sagYol){ try{ $sg=ConvertFrom-Json -InputObject (Get-Content $sagYol -Raw); $yas=((Get-Date)-[datetime]$sg.zaman).TotalMinutes; if("$($sg.durum)" -eq 'acik' -and $yas -le 40){ $topluAc=$true }; "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK: $($sg.durum) ($([int]$yas) dk önce, $($sg.sure_sn) sn) → $(if($topluAc){'TOPLU'}else{'ANLIK'}) · $($s.etiket)" }catch{ "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK okunamadı → anlık" } } else { "[$(Get-Date -Format HH:mm)] TOPLU SAĞLIK dosyası yok → anlık" }
    } elseif("$env:MEVZUAT_TOPLU" -ne '0'){ $topluAc=$true }
  }
  if($topluAc){ $arg+=@('-Toplu') }   # 08.09: fazların ilk denemesi Message Batches ile (yarı fiyat)
  # 08.09 17:10 hız ölçümü: anlık modda 192 konuluk etiket tek hatta ≈16 saat → etiket ikiye bölünür: eski etiket yalnız önbellekteki id'lerle (pilot),
  # kalan konular "<etiket>-b" adlı yeni etikette ayrı hatta koşar. Plan alanı `pilot` = virgüllü id listesi → üreticiye -PilotId
  if($s.PSObject.Properties['pilot'] -and "$($s.pilot)"){ $arg+=@('-PilotId',"$($s.pilot)") }
  # her ders öncesi emniyet: önceki dersler tavana yaklaştırdıysa dur (ödenen iş yazılmış olur, kalan ders sabaha kalır)
  $harcanan=AyHarcama; if($harcanan -ge ($AylikTavan-$EmniyetPayi)){ "[$(Get-Date -Format HH:mm)] BEDEL EMNİYETİ: ≈$([math]::Round($harcanan)) USD, eşik $($AylikTavan-$EmniyetPayi) → kalan dersler DURDU ($($s.etiket) ve sonrası)"; break }
  "[$(Get-Date -Format HH:mm)] BASLIYOR $($s.etiket) · $($s.ders) · adet $($s.adet)$(if($s.PSObject.Properties['eskiKaynak'] -and $s.eskiKaynak){ ' · KURTARMA' }) · ay ≈$([math]::Round($harcanan)) USD"
  & powershell -NoProfile -File $uret @arg *> $log
  $oz=Select-String -Path $log -Pattern 'KONU LİSTESİ|konu tekil|SORU DÜŞTÜ|KURTARMA DÜŞTÜ|UYARLAMA OK|HAKEM (EVET|HAYIR)|HAKEM2 (EVET|HAYIR)|KÖR ÇÖZÜM|SIM (DO|YAN|yetmedi)|KAYNAK BORCU|BEDEL TOPLAM|yazildi' | ForEach-Object { $_.Line }
  # --- 🔴 SADE KAPISI (10.09.2026) ------------------------------------------
  # 198 parti FAZ S calismadan uretti ve KIMSE GORMEDI. Kesilme sessizdi cunku
  # parti "BITTI" diye kapaniyordu; eksik alan hicbir yerde raporlanmiyordu.
  # Kural yazmak isin yarisi, mekanik kapi diger yarisi.
  # Bu kapi PARTIYI DUSURMEZ - uretilen soru odendi, atmak ikinci kayip olur.
  # KIRMIZI damga basar ve kutuge yazar; tamamlama turu bu listeden beslenir.
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
          $kutuk = Join-Path $Kok 'veri\fabrika\sade-eksik-partiler.txt'
          Add-Content -Path $kutuk -Value ("{0}`t{1}`t{2}/{3}`t%{4}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $s.etiket, $sadeli, $n, $oran) -Encoding UTF8
        } else {
          "[$(Get-Date -Format HH:mm)] SADE KAPISI YESIL · $($s.etiket) · sade $sadeli/$n (%$oran)"
        }
      }
    }catch{ "[$(Get-Date -Format HH:mm)] ⚠ SADE KAPISI OLCULEMEDI · $($s.etiket): $($_.Exception.Message)" }
  }

  "[$(Get-Date -Format HH:mm)] BITTI $($s.etiket)"; $oz
  $ozetTum+=[pscustomobject]@{ etiket="$($s.etiket)"; ders="$($s.ders)"; bedel=(($oz | Where-Object { $_ -match 'BEDEL TOPLAM' } | Select-Object -Last 1) -replace '.*≈','' -replace ' USD.*','') }
}
# seçim (8.1 yayın şartı)
$secim=@()
foreach($s in $satirlar){
  $cf=Join-Path $Kok "veri\fabrika\kalip-parti-$($s.etiket).json"; if(-not (Test-Path $cf)){ continue }
  $c=ConvertFrom-Json -InputObject (Get-Content $cf -Raw -Encoding UTF8)
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v.soru){ continue }
    if("$($v.hakem.karar)" -ne 'EVET'){ continue }
    $simOk=$true; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    if(-not ($v.PSObject.Properties['kor_cozum'] -and $v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $secim+=[pscustomobject]@{ etiket="$($s.etiket)"; id=$p.Name; ders="$(if($v.PSObject.Properties['ders'] -and $v.ders){ $v.ders } else { $s.ders })"; konu="$($v.konu)"; donem=[int]$v.donem; kurtarma=[bool]($v.PSObject.Properties['kurtarma'] -and $v.kurtarma) }
  }
}
$secYol=Join-Path $Kok "veri\sinav\kaydir-secim\$planAd-secim.json"
[IO.File]::WriteAllText($secYol,(ConvertTo-Json -InputObject @($secim) -Depth 3),[Text.UTF8Encoding]::new($false))
"SECIM: $($secim.Count) soru (yayın şartı: hakem ∧ sim ∧ kör ∧ hakem2) -> $secYol"
if(-not $SayfaYok -and $secim.Count){
  & powershell -NoProfile -File (Join-Path $buDizin 'kaydir-coz.ps1') -SecimDosya "$planAd-secim.json" -Cikti "KAYDIR-COZ-$planAd.html" *> (Join-Path $logDir 'builder.log')
  Get-Content (Join-Path $logDir 'builder.log') | Select-String -Pattern 'yazildi|ÖZ-SINAV|Exception|Cannot' | ForEach-Object { $_.Line }
}
$etk=($satirlar | ForEach-Object { $_.etiket }) -join ','
& powershell -NoProfile -File (Join-Path $buDizin 'soru-karnesi.ps1') -Etiketler $etk -Cikti "KARNE-$planAd.html" *> (Join-Path $logDir 'karne.log')
Get-Content (Join-Path $logDir 'karne.log') | Select-String -Pattern 'ZORLUK|KARNE:' | ForEach-Object { $_.Line }
"BEDEL (ders ders, ≈USD): $(($ozetTum | ForEach-Object { "$($_.etiket)=$($_.bedel)" }) -join ' · ')"
"[$(Get-Date -Format HH:mm)] TAMAM · sure $([int]((Get-Date)-$t0).TotalMinutes) dk"
