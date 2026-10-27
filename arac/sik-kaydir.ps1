#requires -Version 5.1
# ============================================================================
#  ŞIK KAYDIRMA — yayında OLMAYAN geçen sorularda doğru şıkkın yerini dengeye göre değiştirir (17.09.2026)
#  Cem: "dengesiz 3 dersi beklet" + "2 yap" (şıkları dengele, sonra ekle).
#
#  NEDEN: cevap dağılımı (çırçır) kapısı SGS yayınını durduruyordu; Finansal / Maliyet / Yabancı Dil'de yeni
#  soruların doğru harfi dağılımı bozuyordu (ör. Finansal yayında E 131 · C 237). Gerçek sınav neredeyse düzgün.
#
#  KURALLAR:
#   · YALNIZ yayında olmayan (kaydir/sgs/<ders>.html'de kimliği olmayan) ve dört kapıdan GEÇMİŞ sorular.
#     Yayındaki soruya ASLA dokunulmaz (Cem şartı).
#   · Sayısal şıkları küçükten büyüğe dizili soru KAYDIRILMAZ (gerçek sınav düzeni bozulmasın).
#   · Metninde şık harfi anan soru ("C şıkkı", "cevap B", "A)") KAYDIRILMAZ.
#   · Bulutta koşan partiye yazılmaz (arac/bulut-kosan-etiketler.ps1 -Kati).
#   · Değişen: siklar, dogru, A–E anahtarlı her alan (aciklama, teshis, celdirici_yol …), kor_cozum.cevap/dogru.
#     Soru metni, şık METİNLERİ, açıklama METİNLERİ aynı kalır — yalnız yerleri takas edilir.
#   · Her soruya `sik_kaydirma` kaydı düşülür (eski/yeni harf, tarih). Satır yedeği: C:\TETIKTE-YEDEK\sik-kaydir\
#   · Yazdıktan sonra doğrulama: doğru şık metni ve beş şık kümesi değişmedi mi (geri okuma).
#  Kullanım: powershell -NoProfile -File arac/sik-kaydir.ps1 [-Yaz]      (bekletme listesindeki SGS dersleri)
#  BEDEL 0.
# ============================================================================
#  ⭐ 27.10 DÜZELTME (Cem "öncüllerin şık harfine yazılmasını / kapanışa harf verilmesini kökten düzelt"). ÖLÇÜLDÜ 24.10: bu aracın
#   17.09 koşusunda kaydırılan soruların 17'sinde (Yabancı Dil + Finansal) doğru şıkkın ADIM anlatımı eski harfte kaldı → şık karnesi
#   yanlış şıkkı yeşil, doğru şıkkı kırmızı gösterdi (arac/karne-kapisi.js başlığı). Kök: HARF_ANAN_DESEN büyük/küçük harfe DUYARLIYDI;
#   adım formülleri "Şık A: …" (büyük Ş) diye başladığı için "harf anmıyor" sayıldı; adım.sik alanına hiç bakılmıyordu.
#   Şimdi: (1) desen harf duyarsız · (2) `sik` alanı dolu adımı olan soru KAYDIRILMAZ (adımlar taşınmıyor; taşımak isteyen
#   motor/kalip-parti-uret.ps1 SikTasi 3. seviyesini kullanır) · (3) yazmadan önce bellekte karne tutarlılığı (tek yeşil ya da tek
#   kırmızı = anahtar) önceki hâlle karşılaştırılır; tutarlı karne tutarsızlaşırsa parti YAZILMAZ.
#   Öz-sınav: -Sinav (ağ yok; SIKKAYDIR_MUTASYON=duyarli|adim-yok|karne-yok her biri KIRMIZI düşmeli) — dogrula.yml.
#   🚫 GÖRMEZ: anlatımda harfsiz ama şıkka bağlı cümle ("ilk seçenek", "son şık") · iç denetim alanları (hakem, kor metni) eski harfte kalır (bilinen, sik_kaydirma notunda).
param([switch]$Yaz,[switch]$Prova,[switch]$Sinav,[switch]$Mutasyon)   # -Prova: takas yerel önbellekte bellekte denenir, ambara YAZILMAZ
$ErrorActionPreference='Stop'
$SIKKAYDIR_MUT="$env:SIKKAYDIR_MUTASYON"
$HARF_ANAN_DESEN=$(if($SIKKAYDIR_MUT -eq 'duyarli'){ '(?<![A-Za-zÇĞİÖŞÜçğıöşü])[A-E]\s*(şıkk|şık\b|seçene|\))|(şıkk?ı?|seçenek)\s*[A-E]\b|cevap\s*[A-E]\b' } else { '(?i)(?<![A-Za-zÇĞİÖŞÜçğıöşü])[A-E]\s*(şıkk|şık\b|seçene|\))|(şıkk?ı?|seçenek)\s*[A-E]\b|cevap\s*[A-E]\b' })
function AdimSikli($v){ if($SIKKAYDIR_MUT -eq 'adim-yok'){ return $false }; foreach($a in @($v.adimlar)){ if($a -and $a.PSObject.Properties['sik'] -and "$($a.sik)".Trim()){ return $true } }; return $false }
# Karne tutarlı mı (arac/karne-kapisi.js ile aynı kural; ≥4 şık adımı yoksa ölçülmez = $null)
function KarneTutarli($v){
  if($SIKKAYDIR_MUT -eq 'karne-yok'){ return $null }
  $sa=@(@($v.adimlar) | Where-Object { $_ -and $_.PSObject.Properties['sik'] -and "$($_.sik)".Trim() }); if($sa.Count -lt 4){ return $null }
  $yes=@($sa | Where-Object { "$($_.karar)" -notmatch '^(?i)y' } | ForEach-Object { "$($_.sik)".Trim().ToUpperInvariant() } | Select-Object -Unique)
  $kir=@($sa | Where-Object { "$($_.karar)" -match '^(?i)y' } | ForEach-Object { "$($_.sik)".Trim().ToUpperInvariant() } | Select-Object -Unique)
  $an="$($v.dogru)".Trim().ToUpperInvariant()
  return (($yes.Count -eq 1 -and $yes[0] -eq $an -and $kir -notcontains $an) -or ($kir.Count -eq 1 -and $kir[0] -eq $an -and $yes -notcontains $an))
}
if($Sinav -and $Mutasyon){
  # Önce bozulmamış öz-sınav, sonra her mutasyon AYRI süreçte; hepsi KIRMIZI düşmeli. Kabuk: CI'da pwsh, yerelde powershell (aynı ikili).
  $KABUK=(Get-Process -Id $PID).Path
  & $KABUK -NoProfile -File $PSCommandPath -Sinav; if($LASTEXITCODE -ne 0){ Write-Host 'MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'; exit 1 }
  $tutan=0; $ler=@('duyarli','adim-yok','karne-yok')
  foreach($m in $ler){ $env:SIKKAYDIR_MUTASYON=$m; & $KABUK -NoProfile -File $PSCommandPath -Sinav *> $null; $kr=($LASTEXITCODE -ne 0); if($kr){ $tutan++ }; Write-Host ("  mutasyon {0} {1}" -f $m,$(if($kr){'KIRMIZI (doğru)'}else{'YEŞİL (SINAV KÖR!)'})) }
  $env:SIKKAYDIR_MUTASYON=''
  Write-Host "MUTASYON: $tutan/$($ler.Count) mutasyon KIRMIZI"; if($tutan -ne $ler.Count){ exit 1 }; exit 0
}
if($Sinav){
  function SA($h,$k,$f){ [pscustomobject]@{ sik=$h; karar=$k; formul=$f; anlatim='.' } }
  $V=@(
    @('adim formulu "Şık A:" (büyük Ş) harf anan sayilir', { [regex]::IsMatch('Şık A: müdür ne diyor?',$HARF_ANAN_DESEN) }, $true),
    @('"C şıkkı" (küçük) harf anan sayilir', { [regex]::IsMatch('bu yüzden C şıkkı doğrudur',$HARF_ANAN_DESEN) }, $true),
    @('harfsiz metin (yanlis alarm yok)', { [regex]::IsMatch('Alacaklının yerleşim yerinde ifa edilir. Bu dönem kârı artırır.',$HARF_ANAN_DESEN) }, $false),
    @('sik alanli adim -> kaydirilmaz', { AdimSikli ([pscustomobject]@{ adimlar=@((SA 'A' 'doğru' 'x')) }) }, $true),
    @('sik alansiz adim -> engel yok', { AdimSikli ([pscustomobject]@{ adimlar=@([pscustomobject]@{ formul='Verilen: 100'; anlatim='.' }) }) }, $false),
    @('karne: tek yesil = anahtar -> tutarli', { KarneTutarli ([pscustomobject]@{ dogru='B'; adimlar=@((SA 'A' 'yanlış' 'x'),(SA 'B' 'doğru' 'x'),(SA 'C' 'yanlış' 'x'),(SA 'D' 'yanlış' 'x'),(SA 'E' 'yanlış' 'x')) }) }, $true),
    @('karne: takas sonrasi tek yesil eski harfte -> tutarsiz', { KarneTutarli ([pscustomobject]@{ dogru='E'; adimlar=@((SA 'A' 'yanlış' 'x'),(SA 'B' 'doğru' 'x'),(SA 'C' 'yanlış' 'x'),(SA 'D' 'yanlış' 'x'),(SA 'E' 'yanlış' 'x')) }) }, $false)
  )
  $ok=0; foreach($t in $V){ $g=& $t[1]; $tut=($g -eq $t[2]); if($tut){ $ok++ }; Write-Host ("  {0} {1}" -f $(if($tut){'✓'}else{'✗'}),$t[0]) }
  Write-Host ("SIK-KAYDIR ÖZ-SINAVI {0} ({1}/{2}){3}" -f $(if($ok -eq $V.Count){'YEŞİL'}else{'KIRMIZI'}),$ok,$V.Count,$(if($SIKKAYDIR_MUT){" · SIKKAYDIR_MUTASYON=$SIKKAYDIR_MUT"}else{''}))
  if($ok -ne $V.Count){ exit 1 }; exit 0
}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$DEPO_KOK=Split-Path -Parent $PSScriptRoot
$SERVIS_ANAHTARI="$env:SUPABASE_SERVICE_KEY"; if(-not $SERVIS_ANAHTARI){ $SERVIS_ANAHTARI="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
$SERVIS_ANAHTARI=$SERVIS_ANAHTARI.Trim(); if(-not $SERVIS_ANAHTARI){ throw 'SUPABASE_SERVICE_KEY yok' }
$TABLO_UCU='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$ISTEK_BASLIK=@{ apikey=$SERVIS_ANAHTARI; Authorization="Bearer $SERVIS_ANAHTARI"; Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$HARF_LISTESI=@('A','B','C','D','E')
$DERS_ETIKET=@{ 'Finansal Muhasebe'=@{ sayfa='finansal-muhasebe'; desen='(^|-)(fmuh|finansalmuhasebe)(-|$)' }; 'Maliyet Muhasebesi'=@{ sayfa='maliyet-muhasebesi'; desen='(^|-)maliyet(-|$)' }; 'Yabancı Dil'=@{ sayfa='yabanci-dil'; desen='(^|-)(yd|yabancidil)(-|$)' } }
$YEDEK_DIZIN='C:\TETIKTE-YEDEK\sik-kaydir'; New-Item -ItemType Directory -Force $YEDEK_DIZIN | Out-Null

# 17.09 ÖLÇÜLDÜ (ilk -Yaz, sgs-c2-fmuh-zor-r3 kp-07): siklar {"A".."E","F":null} idi; F yüzünden nesne harf-anahtarlı sayılmadı,
#   şıklar takaslanmadı ama dogru değişti -> geri okuma doğrulaması yakaladı, satır yedekten geri yüklendi. Artık A–E dışındaki
#   anahtar DEĞERİ BOŞSA (null/"") yok sayılır; dolu bir yabancı anahtar varsa nesne harf-anahtarlı sayılmaz.
function HarfAnahtarliMi($deger){ if(-not $deger -or $deger -isnot [pscustomobject]){ return $false }; $harfli=0; foreach($ozellik in $deger.PSObject.Properties){ if($HARF_LISTESI -contains $ozellik.Name){ $harfli++ } elseif($null -ne $ozellik.Value -and "$($ozellik.Value)".Trim()){ return $false } }; return ($harfli -ge 3) }
function Takas($nesne,[string]$birinci,[string]$ikinci){
  $v1=$(if($nesne.PSObject.Properties[$birinci]){ $nesne.$birinci } else { $null }); $v2=$(if($nesne.PSObject.Properties[$ikinci]){ $nesne.$ikinci } else { $null })
  if($nesne.PSObject.Properties[$birinci]){ $nesne.PSObject.Properties.Remove($birinci) }; if($nesne.PSObject.Properties[$ikinci]){ $nesne.PSObject.Properties.Remove($ikinci) }
  if($null -ne $v2){ $nesne | Add-Member -NotePropertyName $birinci -NotePropertyValue $v2 }
  if($null -ne $v1){ $nesne | Add-Member -NotePropertyName $ikinci -NotePropertyValue $v1 }
  # anahtar sırası: A..E önce, varsa diğer (boş) anahtarlar sonra — özgün düzen korunur
  $sirali=[ordered]@{}; foreach($h in $HARF_LISTESI){ if($nesne.PSObject.Properties[$h]){ $sirali[$h]=$nesne.$h } }
  foreach($ozellik in @($nesne.PSObject.Properties)){ if($HARF_LISTESI -notcontains $ozellik.Name){ $sirali[$ozellik.Name]=$ozellik.Value } }
  foreach($ad in @($nesne.PSObject.Properties.Name)){ $nesne.PSObject.Properties.Remove($ad) }
  foreach($ad in $sirali.Keys){ $nesne | Add-Member -NotePropertyName $ad -NotePropertyValue $sirali[$ad] }
}
function HarfCevir([string]$h,[string]$x,[string]$y){ if($h -eq $x){ return $y }; if($h -eq $y){ return $x }; return $h }

$BEKLETME=Get-Content (Join-Path $DEPO_KOK 'arac\yayin-bekletme.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$KOSAN_BULUT=@(); if($Yaz){ $KOSAN_BULUT=@(& (Join-Path $DEPO_KOK 'arac\bulut-kosan-etiketler.ps1') -Kati) }
$PLAN=New-Object System.Collections.Generic.List[object]
foreach($DERS_ADI in @($BEKLETME.dersler)){
  $AYAR=$DERS_ETIKET["$DERS_ADI"]; if(-not $AYAR){ Write-Host "tanımsız ders, atlandı: $DERS_ADI" -ForegroundColor Yellow; continue }
  $SAYFA=[IO.File]::ReadAllText((Join-Path $DEPO_KOK "kaydir\sgs\$($AYAR.sayfa).html")); $BAS=$SAYFA.IndexOf('SORULAR=[')
  $YAYINDA=@{}; $SAYAC=@{A=0;B=0;C=0;D=0;E=0}
  if($BAS -ge 0){
    $GOVDE=$SAYFA.Substring($BAS)
    foreach($m in [regex]::Matches($GOVDE,'"id":"([^"]+/kp-[0-9A-Za-z]+)"')){ $YAYINDA[$m.Groups[1].Value]=1 }
    foreach($m in [regex]::Matches($GOVDE,'"dogru":"([A-E])"')){ $SAYAC[$m.Groups[1].Value]++ }
  } elseif($SAYFA.Contains('data-kasa-sayfa=')){
    # 29.09.2026 ADIM 2: kasa modundaki sayfa SORUSUZ kabuk -> yayındaki kimlik + doğru harf kasadan (paket_soru, sayfa bazında).
    $KASA_SAYFA="kaydir/sgs/$($AYAR.sayfa).html"
    for($KASA_KAYMA=0; ; $KASA_KAYMA+=500){
      $KASA_PARCA=Invoke-RestMethod -Headers $ISTEK_BASLIK -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,kasa_dogru:veri->>dogru&sayfa=eq.$([uri]::EscapeDataString($KASA_SAYFA))&order=id.asc&limit=500&offset=$KASA_KAYMA")
      $KASA_SATIR_SAYISI=0
      foreach($KASA_SATIR in $KASA_PARCA){ $KASA_SATIR_SAYISI++; $YAYINDA["$($KASA_SATIR.id)"]=1; if("$($KASA_SATIR.kasa_dogru)" -match '^[A-E]$'){ $SAYAC["$($KASA_SATIR.kasa_dogru)"]++ } }
      if($KASA_SATIR_SAYISI -lt 500){ break }
    }
    if(-not $YAYINDA.Count){ throw "$DERS_ADI kabuk sayfası için kasada satır yok ($KASA_SAYFA); yayındaki dağılım okunamaz" }
  } else { throw "$DERS_ADI sayfası boş; yayındaki dağılım okunamaz" }
  $ADAYLAR=@()
  foreach($f in Get-ChildItem (Join-Path $DEPO_KOK 'veri\fabrika') -Filter 'kalip-parti-sgs-*.json'){
    $ETIKET=$f.BaseName -replace '^kalip-parti-',''; if($ETIKET -notmatch $AYAR.desen -or $ETIKET -match 'pilot'){ continue }
    $ICERIK=Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($p in $ICERIK.PSObject.Properties){
      if($p.Name -notlike 'kp-*'){ continue }; $v=$p.Value; if(-not $v.soru -or "$($v.dogru)" -notmatch '^[A-E]$'){ continue }
      if($YAYINDA.ContainsKey("$ETIKET/$($p.Name)")){ continue }
      $GECTI=("$($v.hakem.karar)" -eq 'EVET') -and ("$($v.hakem2.karar)" -eq 'EVET') -and [bool]$v.kor_cozum.dogru_mu -and -not ($v.simulasyon_sonnet -and $v.simulasyon_sonnet.PSObject.Properties['dogru_mu'] -and -not [bool]$v.simulasyon_sonnet.dogru_mu)
      if(-not $GECTI){ continue }
      $SIK_METIN=@($HARF_LISTESI | ForEach-Object { "$($v.siklar.$_)" })
      $SAYISAL=@($SIK_METIN | Where-Object { $_ -match '^[\s%₺TL\-]*[\d\.\,]+\s*(TL|₺|%)?\s*$' }).Count -eq 5
      $SIRALI=$false
      if($SAYISAL){ $RAKAM=@($SIK_METIN | ForEach-Object { [double](($_ -replace '[^\d,\-]','') -replace ',','.') }); $SIRALI=$true; for($i=1;$i -lt 5;$i++){ if($RAKAM[$i] -lt $RAKAM[$i-1]){ $SIRALI=$false } } }
      # Yalnız ÖĞRENCİNİN GÖRDÜĞÜ metin denetlenir (harf-anahtarlı alanların DEĞERLERİ dahil: "yanlış olan şık D'dir" takastan sonra yanlış olur).
      # 17.09 ÖLÇÜLDÜ: capa_metin (çıkmış sınav örneği) 523/523 soruda kendi şıklarını taşıyor -> her soruyu yanlış eliyordu.
      # İç denetim alanları (hakem, hakem2, kor_cozum metni, simulasyon, capa_*, kaynak_*) eski harfi anabilir; sik_kaydirma kaydında yazılır.
      $OGRENCI_ALANLARI=@('soru','adimlar','hap','sade','sinav_taktigi','notlandirici','konu_giris','cozum_tablo','sema','verilenler','verilen','ikiz','ikiz_sema','ikiz_soru','aciklama','teshis','celdirici_yol')
      $TUM_METIN=(@($OGRENCI_ALANLARI | Where-Object { $v.PSObject.Properties[$_] -and $null -ne $v.$_ } | ForEach-Object { $j=($v.$_ | ConvertTo-Json -Depth 10 -Compress); if($j){ [regex]::Unescape($j) } }) -join ' ')
      $HARF_ANIYOR=[regex]::IsMatch($TUM_METIN,$HARF_ANAN_DESEN) -or (AdimSikli $v)   # 27.10: sik alanlı adım taşınmaz → soru kaydırılmaz
      $ADAYLAR+=[pscustomobject]@{ ders="$DERS_ADI"; etiket=$ETIKET; kp=$p.Name; eski="$($v.dogru)"; kaydirilir=(-not $SIRALI -and -not $HARF_ANIYOR) }
    }
  }
  $DENGE=@{}; foreach($h in $HARF_LISTESI){ $DENGE[$h]=$SAYAC[$h] }
  foreach($a in ($ADAYLAR | Where-Object { -not $_.kaydirilir })){ $DENGE[$a.eski]++ }
  foreach($a in ($ADAYLAR | Where-Object { $_.kaydirilir })){
    $EN_AZ=($HARF_LISTESI | Sort-Object @{e={$DENGE[$_]}}, @{e={ if($_ -eq $a.eski){0}else{1} }} | Select-Object -First 1)
    $DENGE[$EN_AZ]++
    if($EN_AZ -ne $a.eski){ $PLAN.Add([pscustomobject]@{ ders=$a.ders; etiket=$a.etiket; kp=$a.kp; eski=$a.eski; yeni=$EN_AZ }) }
  }
  Write-Host ("{0}: aday {1} · kaydırılabilir {2} · değişecek {3} · hedef dağılım {4}" -f $DERS_ADI,$ADAYLAR.Count,@($ADAYLAR|?{$_.kaydirilir}).Count,@($PLAN|?{$_.ders -eq $DERS_ADI}).Count,(($HARF_LISTESI|%{ "$_ $($DENGE[$_])" }) -join ' '))
}
$PLAN | Export-Csv (Join-Path $YEDEK_DIZIN ("plan-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.csv')) -NoTypeInformation -Encoding UTF8
if(-not $Yaz -and -not $Prova){ Write-Host "KURU KOŞU: ambara yazılmadı (-Yaz)." -ForegroundColor Yellow; return }

$YAZILAN=0; $DOGRULANAN=0
foreach($GRUP in ($PLAN | Group-Object etiket)){
  if($KOSAN_BULUT -contains $GRUP.Name){ Write-Host "ATLANDI (bulutta koşuyor): $($GRUP.Name)" -ForegroundColor Yellow; continue }
  if($Prova){ $SATIR=[pscustomobject]@{ sinav='SGS'; icerik=(Get-Content (Join-Path $DEPO_KOK "veri\fabrika\kalip-parti-$($GRUP.Name).json") -Raw -Encoding UTF8 | ConvertFrom-Json) }; $IC=$SATIR.icerik }
  else{
  $HAM=Invoke-WebRequest -UseBasicParsing -Uri ("$TABLO_UCU" + "?select=sinav,icerik&etiket=eq.$([uri]::EscapeDataString($GRUP.Name))") -Headers $ISTEK_BASLIK -TimeoutSec 180
  $BAYT=$HAM.RawContentStream.ToArray(); [IO.File]::WriteAllBytes((Join-Path $YEDEK_DIZIN ("$($GRUP.Name)-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')),$BAYT)
  $SATIR=(ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($BAYT)))[0]; $IC=$SATIR.icerik }
  $BEKLENEN=@{}
  foreach($d in $GRUP.Group){
    $s=$IC.($d.kp); if(-not $s -or "$($s.dogru)" -ne $d.eski){ Write-Host "  atlandı (ambarda harf değişmiş): $($GRUP.Name) $($d.kp)" -ForegroundColor Yellow; continue }
    $BEKLENEN[$d.kp]=@{ dogruMetin="$($s.siklar.($d.eski))"; kume=((@($HARF_LISTESI|%{ "$($s.siklar.$_)" })|Sort-Object) -join '|'); yeni=$d.yeni }
    $KARNE_ONCE=KarneTutarli $s   # 27.10: tutarlı karne takastan sonra da tutarlı kalmalı
    foreach($alan in @($s.PSObject.Properties)){ if(HarfAnahtarliMi $alan.Value){ Takas $alan.Value $d.eski $d.yeni } }
    if($s.PSObject.Properties['sade'] -and $s.sade -is [pscustomobject]){ foreach($alan in @($s.sade.PSObject.Properties)){ if(HarfAnahtarliMi $alan.Value){ Takas $alan.Value $d.eski $d.yeni } } }
    $s.dogru=$d.yeni
    # YAZMADAN ÖNCE bellekte doğrula: yeni harfteki şık = eski doğru metin, beş şık kümesi aynı. Tutmazsa bütün parti YAZILMAZ.
    $bellekKume=((@($HARF_LISTESI|%{ "$($s.siklar.$_)" })|Sort-Object) -join '|')
    if("$($s.siklar.($d.yeni))" -ne $BEKLENEN[$d.kp].dogruMetin -or $bellekKume -ne $BEKLENEN[$d.kp].kume){ throw "BELLEK DOĞRULAMASI DÜŞTÜ (yazılmadı): $($GRUP.Name) $($d.kp)" }
    if($KARNE_ONCE -eq $true -and (KarneTutarli $s) -ne $true){ throw "KARNE DOĞRULAMASI DÜŞTÜ (yazılmadı): $($GRUP.Name) $($d.kp) — takas şık karnesini anahtarla çelişik bıraktı" }
    if($s.kor_cozum){ foreach($k in 'cevap','dogru'){ if($s.kor_cozum.PSObject.Properties[$k] -and "$($s.kor_cozum.$k)" -match '^[A-E]$'){ $s.kor_cozum.$k=(HarfCevir "$($s.kor_cozum.$k)" $d.eski $d.yeni) } } }
    $s | Add-Member -NotePropertyName sik_kaydirma -NotePropertyValue ([pscustomobject]@{ eski=$d.eski; yeni=$d.yeni; tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); neden='cevap dagilimi dengesi (Cem 17.09)'; not="Ic denetim metinleri (hakem, hakem2, kor_cozum aciklamasi, simulasyon, capa) ESKI harf duzenine goredir: $($d.eski) -> $($d.yeni) takaslandi." }) -Force
  }
  if(-not $BEKLENEN.Count){ continue }
  if($Prova){ $YAZILAN+=$BEKLENEN.Count; $DOGRULANAN+=$BEKLENEN.Count; continue }
  $GOVDE='{"etiket":' + (ConvertTo-Json $GRUP.Name) + ',"sinav":' + (ConvertTo-Json "$($SATIR.sinav)") + ',"yazan":"sik-kaydir","icerik":' + (ConvertTo-Json -InputObject $IC -Depth 40 -Compress) + '}'
  [void](Invoke-RestMethod -Method Post -Uri ($TABLO_UCU + '?on_conflict=etiket') -Headers ($ISTEK_BASLIK + @{ Prefer='resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($GOVDE)) -TimeoutSec 300)
  $YAZILAN+=$BEKLENEN.Count
  # geri okuma doğrulaması
  $GERI=(ConvertFrom-Json ([Text.Encoding]::UTF8.GetString((Invoke-WebRequest -UseBasicParsing -Uri ("$TABLO_UCU" + "?select=icerik&etiket=eq.$([uri]::EscapeDataString($GRUP.Name))") -Headers $ISTEK_BASLIK -TimeoutSec 180).RawContentStream.ToArray())))[0].icerik
  foreach($kp in $BEKLENEN.Keys){
    $g=$GERI.$kp; $b=$BEKLENEN[$kp]
    $kume=((@($HARF_LISTESI|%{ "$($g.siklar.$_)" })|Sort-Object) -join '|')
    if("$($g.dogru)" -ne $b.yeni -or "$($g.siklar.($g.dogru))" -ne $b.dogruMetin -or $kume -ne $b.kume -or ($g.kor_cozum -and "$($g.kor_cozum.dogru)" -match '^[A-E]$' -and "$($g.kor_cozum.dogru)" -ne $b.yeni)){ throw "DOĞRULAMA DÜŞTÜ: $($GRUP.Name) $kp — yedekten geri yükle: $YEDEK_DIZIN" }
    $DOGRULANAN++
  }
}
Write-Host "YAZILDI: $YAZILAN soru · doğrulandı: $DOGRULANAN" -ForegroundColor Green
