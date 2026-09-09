# KONU KAYNAK ÖN ÖLÇÜMÜ (09.09.2026, Cem: "kaynak yüzünden düşen konuyu bir daha basmamak, bunu önceden ölçelim soruyu basmaya geçmeden")
# NE YAPAR: bir etiketin konu dosyasındaki HER konu için ambarda kaynak var mı diye ÖNCEDEN bakar. Model çağrısı YOK, bedeli 0 USD.
#   Üç yerden arar (üreticinin DesenUret sırasıyla aynı): (1) OZEL_DESEN'de konu için elle bağlanmış desen, (2) '~teori <konu kökleri>'
#   ad araması (Türkçe + şapkalı harf toleranslı imatch), (3) dersin kanun listesi (DERS_KANUN) içinde konu köklerinden ad araması.
# ÇIKTI: konu başına VAR (kaç belge) / ZAYIF (yalnız 1 belge) / YOK. Sonda özet + "YOK" listesi.
# NEDEN: Tur 1'de hakem reddinin en büyük kalemi kaynak eksikliğiydi ve para soru BASILDIKTAN sonra gidiyordu. Bu betik o parayı
#   basımdan önce kurtarır: YOK çıkan konu için ya teori notu yazılır (0 USD) ya konu plandan çıkarılır.
# KULLANIM: powershell -NoProfile -File arac/konu-kaynak-on-olcum.ps1 -KonuDosya veri/sinav/konu/sgs-t2b-mta-zor.json -Ders 'Mali Tablolar Analizi'
param([Parameter(Mandatory)][string]$KonuDosya,[string]$Ders='',[switch]$YalnizEksik)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok=Split-Path $buDizin -Parent
$SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $KEY){ $KEY=$env:SUPABASE_SERVICE_KEY }
if(-not $KEY){ 'SUPABASE_SERVICE_KEY yok - olculemedi'; return }
$BASLIK=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
function Katla2([string]$s){ ("$s".ToLowerInvariant() -creplace 'İ','i' -creplace 'I','i').Replace('ı','i').Replace('ğ','g').Replace('ü','u').Replace('ş','s').Replace('ö','o').Replace('ç','c').Replace('â','a').Replace('î','i').Replace('û','u') }
# Üreticideki AmbarCek '~' regexinin aynısı (09.09 şapkalı harf düzeltmesi dahil)
function TurkceRegex([string]$ifade){
  $rxA=''
  foreach($kw in ($ifade -split '\s+')){
    if(-not $kw){ continue }
    $kwRx=''
    foreach($ch in $kw.ToLowerInvariant().ToCharArray()){
      switch -CaseSensitive ("$ch"){
        'a' { $kwRx+='[aâ]' } 'c' { $kwRx+='[cç]' } 'g' { $kwRx+='[gğ]' } 'i' { $kwRx+='[iıİIî]' } 'o' { $kwRx+='[oö]' } 's' { $kwRx+='[sş]' } 'u' { $kwRx+='[uüû]' }
        default { if("$ch" -match '[a-z0-9]'){ $kwRx+="$ch" } else { $kwRx+='.' } }
      }
    }
    if($rxA){ $rxA+='.*' }; $rxA+=$kwRx
  }
  return $rxA
}
function AdAra([string]$ifade,[int]$limit=6){
  if(-not $ifade){ return @() }
  $u="$SB`?select=kaynak_ad&kaynak_ad=imatch."+[uri]::EscapeDataString((TurkceRegex $ifade))+'&limit='+$limit
  try{ return @((Invoke-RestMethod -Uri $u -Headers $BASLIK -TimeoutSec 90) | ForEach-Object { "$($_.kaynak_ad)" }) }catch{ return @() }
}
function OnekAra([string]$onek,[int]$limit=4){
  $u="$SB`?select=kaynak_ad&kaynak_ad=ilike."+[uri]::EscapeDataString("$onek%")+'&limit='+$limit
  try{ return @((Invoke-RestMethod -Uri $u -Headers $BASLIK -TimeoutSec 90) | ForEach-Object { "$($_.kaynak_ad)" }) }catch{ return @() }
}
# 09.09 v2 (Cem "aracı düzelt"): HUKUK derslerinde kaynak ADDA değil kanun MADDE METNİNDE geçer. Üreticinin '@kanun|kelime'
# deseninin aynısı: kaynak_ad o kanunla başlayan belgelerin METNİ içinde konu kelimeleri aranır. Bu eklenmeden İş-SGK ve
# Meslek Hukuku konularının çoğu "kaynak YOK" görünüyordu (ölçüm 22:55, 23 Meslek + 12 İş-SGK konusu).
function MetinAra([string]$kanunOnek,[string]$kelime,[int]$limit=3){
  if(-not $kanunOnek -or -not $kelime){ return @() }
  $rx=''
  foreach($ch in $kelime.ToLowerInvariant().ToCharArray()){
    switch -CaseSensitive ("$ch"){
      'a' { $rx+='[aâ]' } 'c' { $rx+='[cç]' } 'g' { $rx+='[gğ]' } 'i' { $rx+='[iıİIî]' } 'o' { $rx+='[oö]' } 's' { $rx+='[sş]' } 'u' { $rx+='[uüû]' }
      ' ' { $rx+='.{0,80}' }   # iki kök aynı maddede, arada en çok 80 karakter
      default { if("$ch" -match '[a-z0-9]'){ $rx+="$ch" } else { $rx+='.' } }
    }
  }
  $u="$SB`?select=kaynak_ad&kaynak_ad=ilike."+[uri]::EscapeDataString("$kanunOnek%")+'&metin=imatch.'+[uri]::EscapeDataString($rx)+'&limit='+$limit
  try{ return @((Invoke-RestMethod -Uri $u -Headers $BASLIK -TimeoutSec 90) | ForEach-Object { "$($_.kaynak_ad)" }) }catch{ return @() }
}
# konu dosyası (PS 5.1: tek elemanlı dizi sarmalını aç)
$konular=@((ConvertFrom-Json -InputObject (Get-Content $KonuDosya -Raw -Encoding UTF8)) | ForEach-Object { $_ })
if($konular.Count -eq 1 -and $konular[0] -is [array]){ $konular=@($konular[0]) }
# üreticideki OZEL_DESEN sözlüğünü kaynak dosyadan oku (kopya tutmamak icin)
$uretici=Get-Content (Join-Path $kok 'motor\kalip-parti-uret.ps1') -Raw -Encoding UTF8
$ozel=@{}
foreach($m in [regex]::Matches($uretici,"(?m)^\s{2}'([^']{3,60})'\s*=\s*@\((.+?)\)\s*(?:#.*)?$")){
  $ad=$m.Groups[1].Value; $ic=$m.Groups[2].Value
  if($ozel.ContainsKey($ad)){ continue }
  $ozel[$ad]=@([regex]::Matches($ic,"'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
}
# DERS_KANUN: dersin ana kanun önekleri (hukuk derslerinde kaynak ADDA değil MADDE METNİNDE geçer).
# 09.09: ilk sürümde bu blok hiç okunamıyordu ve bütün hukuk dersleri sahte "kaynak YOK" veriyordu (Borçlar 28/29).
# Ders adı üretici dosyasında doğrudan aranır; plan ders adı '|' ile iki yazımı taşıyabilir ('Borclar Hukuku|Ticaret ve Borclar').
$dersKanunlari=@()
foreach($dAd in ("$Ders" -split '\|')){
  $ad2=$dAd.Trim(); if(-not $ad2){ continue }
  # 09.09: [^)]+ kullanılamaz — kanun adının kendisinde parantez var ('TBK (6098 s.K.)'), yakalama erken kesiliyordu.
  # Tırnaklı öğe dizisi olarak yakalanır: @('X','Y')
  $mm=[regex]::Match($uretici,"'"+[regex]::Escape($ad2)+"'\s*=\s*@\((?<ic>(?:'[^']*'\s*,?\s*)+)\)")
  if($mm.Success){ foreach($x in [regex]::Matches($mm.Groups['ic'].Value,"'([^']*)'")){ $dersKanunlari+=$x.Groups[1].Value } }
}
$dersKanunlari=@($dersKanunlari | Where-Object { $_ -and $_ -notmatch '^(TEORI|Teori Notu|THP|TMS)$' } | Select-Object -Unique)
"konu dosyası: $KonuDosya"
"konu sayısı: $($konular.Count) · OZEL_DESEN girdisi: $($ozel.Keys.Count) · ders: $(if($Ders){ $Ders } else { '(verilmedi)' })"
"ders kanunları (metin araması bunlarda yapılır): $(if($dersKanunlari.Count){ $dersKanunlari -join ' · ' } else { 'OKUNAMADI — metin araması yapılamaz' })"
""
$var=0; $zayif=0; $yok=0; $eksikListe=New-Object System.Collections.Generic.List[string]
foreach($konu in $konular){
  $bulunan=New-Object System.Collections.Generic.List[string]
  $kaynakTuru=''
  if($ozel.ContainsKey("$konu")){
    $kaynakTuru='OZEL_DESEN'
    foreach($d in $ozel["$konu"]){
      if($d.StartsWith('~')){ foreach($x in (AdAra $d.Substring(1))){ $bulunan.Add($x) } }
      elseif($d -notmatch '^@'){ foreach($x in (OnekAra ($d -replace '%$',''))){ $bulunan.Add($x) } }
    }
  }
  $kokler=@((Katla2 "$konu") -split '[\s\-/]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(icin|olan|ile|veya|hesaplama|analizi|analiz|yontemi|yontem|orani|oran|sistemi|sistem|kaydi|kayit|tablosu|tablo)$' })
  if(-not $bulunan.Count){
    if(-not $kaynakTuru){ $kaynakTuru='ad araması' }
    if($kokler.Count){
      foreach($x in (AdAra (($kokler | Select-Object -First 3) -join ' '))){ $bulunan.Add($x) }
      if(-not $bulunan.Count -and $kokler.Count -ge 2){ foreach($x in (AdAra (($kokler | Select-Object -First 2) -join ' '))){ $bulunan.Add($x) } }
      # 09.09: TEK kök ile ad araması yapılmaz — "gecici" tek başına "Haksız Rekabet Yön. geçici m.1"i getiriyordu (sahte VAR).
    }
  }
  # 3. yol: dersin KANUN listesi içinde MADDE METNİ araması (hukuk dersleri kaynağı adda değil metinde taşır)
  if(-not $bulunan.Count -and $dersKanunlari.Count -and $kokler.Count){
    $kaynakTuru='kanun metni'
    # 09.09: metin aramasında İKİ kök birlikte aranır (kok1.*kok2); tek kelime alakasız madde getiriyordu
    $ikiKok=$(if($kokler.Count -ge 2){ ($kokler[0]+' '+$kokler[1]) } else { $kokler[0] })
    foreach($kn in $dersKanunlari){
      if($bulunan.Count -ge 2){ break }
      foreach($x in (MetinAra $kn $ikiKok)){ $bulunan.Add($x) }
    }
    if(-not $bulunan.Count -and $kokler.Count -ge 3){
      $ikiKok2=($kokler[0]+' '+$kokler[2])
      foreach($kn in $dersKanunlari){ if($bulunan.Count -ge 2){ break }; foreach($x in (MetinAra $kn $ikiKok2)){ $bulunan.Add($x) } }
    }
  }
  $n=@($bulunan | Select-Object -Unique).Count
  $durum=$(if($n -ge 2){ 'VAR' } elseif($n -eq 1){ 'ZAYIF' } else { 'YOK' })
  if($durum -eq 'VAR'){ $var++ } elseif($durum -eq 'ZAYIF'){ $zayif++ } else { $yok++; $eksikListe.Add("$konu") }
  if($YalnizEksik -and $durum -eq 'VAR'){ continue }
  $ilk=$(if($n){ (@($bulunan | Select-Object -Unique)[0] -replace '^(TEORI|Teori Notu)\s*-\s*','') } else { '' })
  "{0,-8} {1,-42} {2} belge {3}" -f $durum,"$konu",$n,$(if($ilk){ "· $($ilk.Substring(0,[Math]::Min(52,$ilk.Length)))" } else { '· kaynak bulunamadı' })
}
""
"=== ÖZET === VAR $var · ZAYIF $zayif · YOK $yok  (toplam $($konular.Count))"
if($eksikListe.Count){
  ""
  "KAYNAK YOK — basımdan ÖNCE teori notu yazılacak konular:"
  foreach($e in $eksikListe){ "  - $e" }
}
