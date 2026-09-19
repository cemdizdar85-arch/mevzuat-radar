# ============================================================================
#  SIKLIK KUNYESI (SINAV-KURALLARI D9) — 02.08.2026, 0 USD, API YOK
#
#  CEM: "senin onerin vardi onu yapacaktin." Dogru - siklik kunyesi BENIM
#  onerimdi ve BEDAVA. Parali motoru beklemesine gerek yok.
#
#  NE YAPAR: 35 donemlik cikmis kitapcik haritasindan (veri/sgs-analiz.json)
#  her KONUNUN kac donemde ciktigini ve toplam kac soru geldigini sayar.
#  Cikti soru ekraninda kunye olarak gosterilir: "Bu konu son 35 donemin
#  7'sinde cikti, toplam 9 soru."
#
#  D9 FRENI: sayim yoksa kunye YAZILMAZ. "Sik cikar" gibi olcusuz ifade yasak.
#  Cikti: veri/siklik-kunyesi.json
# ============================================================================
# 13.09 SMMM (Cem "staja baslamada ne yaptiysak bunda aynisi"): -Sinav SMMM
#  kaynak veri/smmm-analiz.json, cikti veri/siklik-kunyesi-smmm.json. SGS yolu
#  (varsayilan) BIREBIR ayni kalir. SMMM'de kayit (donem|ders) bazli: her ders
#  bir donemde tek kayit oldugu icin "kac kayitta" = "kac donemde"; donem_sayisi
#  ise TEKIL donem sayisidir (kayit sayisi degil).
# 17.09 KGK (Cem "1.2.3 üçünü de yap"): -Sinav KGK · kaynak veri/kgk-analiz.json,
#  çıktı veri/siklik-kunyesi-kgk.json. SGS/SMMM yolu BİREBİR aynı kalır.
#  KGK'nın tek farkı DERS ADI: çıkmış kitapçık haritası 21 ayrı ders adı taşıyor
#  (2013–2018 "Muhasebe" / "Denetim", sonra "Türkiye Muhasebe Standartları"…,
#  bazı dönemlerde ç+d+e tek modülde "Sermaye Piyasası, Bankacılık, Sigortacılık…").
#  Kasa ve kota ise 9 resmî etiket kullanıyor (veri/kgk-uretim-kotasi.json). Eşleme
#  olmadan künye anahtarı hiç tutmuyordu → KGK'da künye HİÇ görünmüyordu.
#  Birleşik modüller konu kelimesiyle bölünür; kelime tutmazsa ders "BIRLESIK-…"
#  kalır ve künye gösterilmez (D9 freni: uydurma yok, bölünemeyen sayım kullanılmaz).
param(
  [ValidateSet('SGS','SMMM','KGK')][string]$Sinav = 'SGS',
  [int]$DelilEnAz = 3,          # KGK delil gecisi: kelime en az kac kez gecmis olmali
  [double]$DelilOran = 0.8      # ve gecislerinin en az bu orani tek derste olmali
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kaynak = switch($Sinav){ 'SMMM' { Join-Path $kok 'veri/smmm-analiz.json' } 'KGK' { Join-Path $kok 'veri/kgk-analiz.json' } default { Join-Path $kok 'veri/sgs-analiz.json' } }
$cikti  = switch($Sinav){ 'SMMM' { Join-Path $kok 'veri/siklik-kunyesi-smmm.json' } 'KGK' { Join-Path $kok 'veri/siklik-kunyesi-kgk.json' } default { Join-Path $kok 'veri/siklik-kunyesi.json' } }
if(-not (Test-Path $kaynak)){ Write-Host "$kaynak yok - cikildi."; exit 1 }

$a = Get-Content $kaynak -Raw -Encoding UTF8 | ConvertFrom-Json
$donemler = @($a.donemler | Where-Object { $_.konuSayim })
$donemSayisi = if($Sinav -eq 'SGS'){ $donemler.Count } else { @($donemler | ForEach-Object { "$($_.donem)" } | Sort-Object -Unique).Count }
Write-Host ("Donem: {0} (kayit {1})" -f $donemSayisi, $donemler.Count)

# Turkce-toleransli normalize: kasadaki etiketle kitapciktaki etiket birebir
# ayni yazilmiyor; aksan/buyuk-kucuk farkini eritip esitliyoruz.
function Norm([string]$t){
  # 30.08 DUZELTME - TURKCE HARF SIRASI: once KATLA, sonra INVARIANT kucult.
  # Olculdu (tr-TR): "IFLASINA".ToLower() -> "ıflasına" olur, 'iflas' arayan
  # desen ISKALAR. en-US runner'da ise "INKILAP" -> "i̇nkilap" (i + birlesen
  # nokta) olur ve asagidaki -replace 'İ' onu BULAMAZ. ToLower() ONCE
  # kosarsa harf degistirme gec kalir. Dogru sira: KATLA -> ToLowerInvariant.
  $s = "$t".Replace([char]0x0130,'I').Replace([char]0x0131,'i').Replace([char]0x015E,'S').Replace([char]0x015F,'s').Replace([char]0x011E,'G').Replace([char]0x011F,'g').Replace([char]0x00DC,'U').Replace([char]0x00FC,'u').Replace([char]0x00D6,'O').Replace([char]0x00F6,'o').Replace([char]0x00C7,'C').Replace([char]0x00E7,'c').ToLowerInvariant()
  $s = $s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİİ]','i' -replace '[öÖ]','o' -replace '[şŞ]','s' -replace '[üÜ]','u'
  $s = $s -replace '[^a-z0-9| ]',' ' -replace '\s+',' '
  return $s.Trim()
}

# ---- KGK ders eşlemesi (yalnız -Sinav KGK) -------------------------------
# Sol: çıkmış kitapçık haritasındaki ders adının Norm'u. Sağ: kota/kasa etiketi.
$kgkDersHedef = @{
  'muhasebe'                                  = 'Muhasebe Standartlari'
  'muhasebe standartlari'                     = 'Muhasebe Standartlari'
  'turkiye muhasebe standartlari'             = 'Muhasebe Standartlari'
  'denetim'                                   = 'Denetim Standartlari'
  'turkiye denetim standartlari'              = 'Denetim Standartlari'
  'sermaye piyasasi mevzuati'                 = 'Sermaye Piyasasi Mevzuati'
  'sermaye piyasasi'                          = 'Sermaye Piyasasi Mevzuati'
  'bankacilik mevzuati'                       = 'Bankacilik Mevzuati'
  'bankacilik'                                = 'Bankacilik Mevzuati'
  'sigortacilik ve ozel emeklilik mevzuati'   = 'Sigortacilik ve Ozel Emeklilik Mevzuati'
  'sigortacilik ve ozel emeklilik'            = 'Sigortacilik ve Ozel Emeklilik Mevzuati'
  'genel hukuk mevzuati'                      = 'Genel Hukuk Mevzuati'
}
# Birleşik modüller: tek ders adı altında iki ya da üç resmî ders var. Konu
# adındaki kelimeye göre bölünür; hiçbiri tutmazsa BIRLESIK- olarak bırakılır.
$kgkBirlesik = @{
  'sermaye piyasasi bankacilik sigortacilik ve ozel emeklilik mevzuati' = 'SPK-BANK-SIG'
  'sermaye piyasasi bankacilik sigortacilik'                            = 'SPK-BANK-SIG'
  'kurumsal yonetim ilkeleri ve finansal yonetim'                       = 'KY-FY'
  'kurumsal yonetim ve finansal yonetim'                                = 'KY-FY'
  'kurumsal surdurulebilirlik raporlamasi ve denetimi'                  = 'SURDUR'
}
$kgkKelime = @{
  'SPK-BANK-SIG' = @(
    @{ hedef='Bankacilik Mevzuati';                    desen='banka|bddk|mevduat|kredi|katilim bank|tmsf|sermaye yeterlilig|cekirdek sermaye|likidite karsilama|takipteki|donuk alacak|kaldirac orani|bilgi sistemleri|karsilik yonetmelig' }
    @{ hedef='Sigortacilik ve Ozel Emeklilik Mevzuati'; desen='sigorta|emeklilik|\bbes\b|seddk|aktuer|reasurans|police|teknik karsilik|matematik karsilik|muallak|devam eden riskler|riziko|hasar|\bprim\b|zeyil|tazminat|teknik faiz|hayat brans' }
    @{ hedef='Sermaye Piyasasi Mevzuati';              desen='sermaye piyasasi|\bspk\b|borsa|halka arz|halka acik|izahname|yatirim fonu|yatirim ortakligi|menkul kiymet|portfoy yonetim|kayitli sermaye|pay sahip|pay alim|ihrac|kurul kayd|kurul karari|ortakliktan cikarma|fiyat adimi|fon ictuzug|para piyasasi fon|fon ortaklik|kar payi avans|ara donem rapor|tamamlama cagrisi|genel kurul cagri|sermaye artirim|iceriden ogrenen|tahvil|vadeli islem|kotasyon|aracilik|yatirimci tazmin' }
  )
  # KY kuralı ÖNCE bakar: yönetim kelimeleri daha özel ("risk yonetim komitesi" KY,
  #  "risk getiri" FY). 17.09 ölçümü: eşlenmeyen 525 → aşağıdaki listelerle düştü.
  'KY-FY' = @(
    @{ hedef='Kurumsal Yonetim';  desen='yonetim kurulu|komite|bagimsiz uye|\betik\b|kurumsal yonetim|genel kurul|kamuyu aydinlatma|ucretlendirme|ic kontrol|ic denetim|pay sahip|menfaat sahip|paydas|seffaflik|hesap verebilir|sorumluluk ilkesi|esitlik ilkesi|adillik|kurumsal karne|kademeli kurul|kurul yapisi|bagimsizlik|aday gosterme|\buye\b|oy hakk|azlik hakk|imtiyaz|faaliyet raporu|entegre raporlama|icerden ogrenen|derecelendirme|vekalet|temsil maliyeti|ilkeler|insan kaynaklari|onemli nitelikte islem|yonetim temel fonksiyon|\bkyt\b' }
    @{ hedef='Finansal Yonetim';  desen='faiz|\bnpv\b|\birr\b|nakit|isletme sermayesi|portfoy|risk|sermaye maliyeti|sermaye yapisi|sermaye kazanci|sermaye varliklari|kaldirac|basabas|deger(leme|lemesi)?\b|defter degeri|piyasa degeri|tahvil|bono|hisse|varant|\bwacc\b|\bcapm\b|butce|oran|kar pay|temettu|kar dagitim|buyume|beta|iskonto|anuite|devir hizi|likidite|maliyet|finanslama|finansal planlama|finansal yonetim|finansman|borclanma|turev|forward|futures|opsiyon|\bswap\b|faktoring|forfaiting|leasing|kiralama|getiri|yatirim|\bfon\b|alacak yonetimi|stok yonetimi|stok tahmini|katki|modigliani|gordon|miller|proje degerlendirme|egilim yuzde|karlilik|borc|ozkaynak|spot piyasa|piyasa vade' }
  )
  'SURDUR' = @(
    @{ hedef='Surdurulebilirlik Denetimi';    desen='\bgds\b|guvence|denetci|denetim kanit|denetim ekip|sinirli guvence|makul guvence|dogrulama|surdurulebilirlik denetimi yonetmelig|surdurulebilirlik yonetmelig|etik kurallar|bagimsizlik|izin iptali' }
    @{ hedef='Surdurulebilirlik Raporlamasi'; desen='\btsrs\b|raporlama|surdurulebilirlik rapor|sera gazi|iklim|onemlilik|paydas|\besg\b|kapsam [123]|karbon|\bco2\b|emisyon|enerji tuketim|biyocesitlilik|gecis plani|\bab\b|csrd|csddd|skdm|\bets\b|taksonomi|\bska\b|paris anlasmasi|dongusel ekonomi|sasb|\bsbti\b|yesil|sosyal tahvil|etki yatirimi|\bspk\b|bddk|platform|kamu destek|roma kulubu' }
  )
}
$kgkSayac = @{}   # hangi ders adı hangi hedefe kaç konu taşıdı (rapora yazılır)
function KgkDers([string]$DersAdi, [string]$KonuAdi){
  $dn = Norm $DersAdi
  if($kgkDersHedef.ContainsKey($dn)){ return $kgkDersHedef[$dn] }
  if($kgkBirlesik.ContainsKey($dn)){
    $grup = $kgkBirlesik[$dn]; $kn = Norm $KonuAdi
    foreach($kural in $kgkKelime[$grup]){ if($kn -match $kural.desen){ return $kural.hedef } }
    return "BIRLESIK-$grup"
  }
  return "ESLENMEDI-$DersAdi"
}

# ---- KGK 2. GECIS: kelime kuralinin bolemedigi konuyu VERIDEN gelen delille coz ----
# 19.09 (Cem "2 ve 3 yap"): birlesik modulde kalan 322 konu icin delil, AYRI MODULLU
#  donemlerin kendisi. Cozulmus konularin kelimeleri derslere gore sayilir; bir kelime
#  en az $DelilEnAz kez gecmis ve gecislerinin >=%$($DelilOran*100)'i tek derste ise
#  AYIRT EDICI sayilir. Acik konu yalnizca ayirt edici kelimelerin OY BIRLIGIYLE
#  (celisen oy yoksa) o derse gecer. Celiski ya da delil yoksa BIRLESIK kalir.
#  Olculdu: esik (3, %80) -> 322'nin 53'u cozuldu, celiskili 0. Gevsek esik (2, %80)
#  65 veriyor; muhafazakar olan secildi.
$kgkDelil = @{}   # acik "ders|konu" -> hedef ders
if($Sinav -eq 'KGK'){
  $kgkGrupHedef = @{
    'BIRLESIK-SPK-BANK-SIG' = @('Sermaye Piyasasi Mevzuati','Bankacilik Mevzuati','Sigortacilik ve Ozel Emeklilik Mevzuati')
    'BIRLESIK-KY-FY'        = @('Kurumsal Yonetim','Finansal Yonetim')
    'BIRLESIK-SURDUR'       = @('Surdurulebilirlik Raporlamasi','Surdurulebilirlik Denetimi')
  }
  $durakKelime = @('ve','ile','icin','bir','olan','gore','tanimi','ozellikleri','turleri','hesabi','kavrami','esaslari','sureci','yontemi','yontemleri','orani','suresi')
  function KelimeAyikla([string]$Metin){ @((Norm $Metin) -split '\s+' | Where-Object { $_.Length -ge 4 -and $durakKelime -notcontains $_ }) }
  $kelDers = @{}; $acikKayit = New-Object System.Collections.Generic.List[object]
  foreach($d0 in $donemler){
    foreach($p0 in $d0.konuSayim.PSObject.Properties){
      $parca0 = "$($p0.Name)" -split '\|',2
      if($parca0.Count -ne 2){ continue }
      $hedef0 = KgkDers $parca0[0] $parca0[1]
      $kelime0 = KelimeAyikla $parca0[1]
      if($hedef0 -like 'BIRLESIK-*'){ $acikKayit.Add([pscustomobject]@{ anah="$($parca0[0])|$($parca0[1])"; grup=$hedef0; kelime=$kelime0 }) }
      elseif($hedef0 -notlike 'ESLENMEDI-*'){ foreach($w0 in $kelime0){ if(-not $kelDers.ContainsKey($w0)){ $kelDers[$w0] = @{} }; $kelDers[$w0][$hedef0] = 1 + [int]$kelDers[$w0][$hedef0] } }
    }
  }
  $ayirtEdici = @{}
  foreach($kv in $kelDers.GetEnumerator()){
    $toplamGecis = 0; foreach($v in $kv.Value.Values){ $toplamGecis += [int]$v }
    if($toplamGecis -lt $DelilEnAz){ continue }
    $enAd = $null; $enDeger = 0
    foreach($e in $kv.Value.GetEnumerator()){ if([int]$e.Value -gt $enDeger){ $enDeger = [int]$e.Value; $enAd = [string]$e.Key } }
    if(($enDeger / $toplamGecis) -ge $DelilOran){ $ayirtEdici[$kv.Key] = $enAd }
  }
  $delilCelisen = 0
  foreach($a in $acikKayit){
    $oy = @{}
    foreach($w in ($a.kelime | Select-Object -Unique)){ if($ayirtEdici.ContainsKey($w)){ $hd = $ayirtEdici[$w]; if($kgkGrupHedef[$a.grup] -contains $hd){ $oy[$hd] = 1 + [int]$oy[$hd] } } }
    if($oy.Count -eq 0){ continue }
    if($oy.Count -gt 1){ $delilCelisen++; continue }   # celisen oy -> karar verilmez
    $kgkDelil[$a.anah] = [string]@($oy.Keys)[0]
  }
  Write-Host ("KGK delil gecisi: ayirt edici kelime {0} · delille cozulen konu {1} · celiskili {2} · delilsiz {3}" -f $ayirtEdici.Count, $kgkDelil.Count, $delilCelisen, ($acikKayit.Count - $kgkDelil.Count - $delilCelisen))
}

# ---- KGK 3. GECIS: KITAPCIK DELILI (19.09, Cem "2 ve 3 yap") -------------------
# Olculdu: birlesik modulde sorular DERS DERS BLOK halinde diziliyor
#   (ornek 29.06.2019 SPK modulu: SSSSSSSSSSSSSS?BBB?BBB?B?BBB?BGGGGGGGGGG).
# Bu yuzden cozulemeyen sorunun dersi, AYNI KITAPCIKTA kendisinden once ve sonra
# gelen cozulmus sorularin dersinden okunur. Kural KATI: iki yan da cozulmus ve
# AYNI dersi gosteriyorsa atanir; kenardaysa yalniz 3 soru mesafesindeki tek yan
# kabul edilir. Yanlar celisiyorsa (blok siniri) konu ACIK kalir.
# Ayni konu iki kitapcikta farkli ders gosterirse o konu da ACIK birakilir.
# ⚠ 19.09: veri/kgk-arsiv GIT DIŞI — bulutta koşan robotta (konu-eslesme.yml) o klasör YOKTUR.
#   Kitapçık delili yalnız yerelde hesaplanabildiği için KARARLAR depoya yazılır
#   (veri/kgk-birlesik-ders-esleme.json: konu → ders, yalnız etiket + ders adı, soru metni yok).
#   Klasör yoksa betik bu dosyadan okur; böylece bulut ile yerel AYNI künyeyi üretir.
#   Olmasaydı: bulut künyeyi kitapçık delilsiz yeniden üretip yereldekini eziyordu (eşlenmeyen 58 → 327).
$kgkKitapcik = @{}
$kgkEslemeYolu = Join-Path $kok 'veri\kgk-birlesik-ders-esleme.json'
if($Sinav -eq 'KGK'){
  $etiketKlasoru = Join-Path $kok 'veri\kgk-arsiv\etiket'
  if(-not (Test-Path $etiketKlasoru) -and (Test-Path $kgkEslemeYolu)){
    $kayitliEsleme = Get-Content $kgkEslemeYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($pe in @($kayitliEsleme.esleme.PSObject.Properties)){ $kgkKitapcik[$pe.Name] = "$($pe.Value)" }
    Write-Host ("KGK kitapcik delili: etiket klasoru yok - depodaki karar dosyasindan {0} konu okundu ({1})" -f $kgkKitapcik.Count, $kayitliEsleme.uretim)
  }
  elseif(Test-Path $etiketKlasoru){
    $konuOy = @{}
    foreach($ed in (Get-ChildItem $etiketKlasoru -Filter '*.json')){
      $kitap = Get-Content $ed.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
      $modulGrup = @{}
      foreach($sr in @($kitap.sorular)){ $mn = Norm "$($sr.modul)"; if($kgkBirlesik.ContainsKey($mn)){ if(-not $modulGrup.ContainsKey($mn)){ $modulGrup[$mn] = New-Object System.Collections.Generic.List[object] }; $modulGrup[$mn].Add($sr) } }
      foreach($mg in $modulGrup.GetEnumerator()){
        $sira = @($mg.Value | Sort-Object { [int]$_.no })
        $ders = @()
        foreach($sr in $sira){
          $hd = KgkDers "$($sr.modul)" "$($sr.konu)"
          if($hd -like 'BIRLESIK-*' -and $kgkDelil.ContainsKey("$($sr.modul)|$($sr.konu)")){ $hd = $kgkDelil["$($sr.modul)|$($sr.konu)"] }
          $ders += $(if($hd -like 'BIRLESIK-*' -or $hd -like 'ESLENMEDI-*'){ $null } else { $hd })
        }
        for($i = 0; $i -lt $sira.Count; $i++){
          if($ders[$i]){ continue }
          $sol = $null; $solUz = 0
          for($a = $i-1; $a -ge 0; $a--){ if($ders[$a]){ $sol = $ders[$a]; $solUz = $i - $a; break } }
          $sag = $null; $sagUz = 0
          for($a = $i+1; $a -lt $sira.Count; $a++){ if($ders[$a]){ $sag = $ders[$a]; $sagUz = $a - $i; break } }
          $karar = $null
          if($sol -and $sag){ if($sol -eq $sag){ $karar = $sol } }
          elseif($sol -and $solUz -le 3){ $karar = $sol }
          elseif($sag -and $sagUz -le 3){ $karar = $sag }
          if(-not $karar){ continue }
          $konuAnah = "$($sira[$i].modul)|$($sira[$i].konu)"
          if(-not $konuOy.ContainsKey($konuAnah)){ $konuOy[$konuAnah] = New-Object System.Collections.Generic.HashSet[string] }
          [void]$konuOy[$konuAnah].Add($karar)
        }
      }
    }
    $kitapCelisen = 0
    foreach($ko in $konuOy.GetEnumerator()){ if($ko.Value.Count -eq 1){ $kgkKitapcik[$ko.Key] = @($ko.Value)[0] } else { $kitapCelisen++ } }
    Write-Host ("KGK kitapcik delili: cozulen konu {0} · kitapciklar arasi celisen {1}" -f $kgkKitapcik.Count, $kitapCelisen)
    # Kararlari depoya yaz: bulut robotu ayni kunyeyi uretebilsin (etiket klasoru orada yok)
    $eslemeTablosu = [ordered]@{}
    foreach($ka in ($kgkKitapcik.GetEnumerator() | Sort-Object Name)){ $eslemeTablosu[$ka.Key] = $ka.Value }
    $eslemeNesnesi = [ordered]@{
      aciklama = 'KGK birlesik modul konularinin ders karari (kitapcik delili). Anahtar = "<kitapciktaki modul adi>|<konu>", deger = kota ders etiketi. Yalniz etiket ve ders adi tasir; soru metni/sik/cevap YOKTUR.'
      kural    = 'Karar motor/siklik-kunyesi.ps1 -Sinav KGK ile YERELDE uretilir (veri/kgk-arsiv/etiket git disi): birlesik modulde sorular ders ders blok halinde dizildigi icin bosluk, iki yanindaki cozulmus sorular AYNI dersi gosteriyorsa kapanir. Bulutta klasor olmadigindan bu dosya okunur.'
      uretim   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
      konu     = $eslemeTablosu.Count
      esleme   = $eslemeTablosu
    }
    [IO.File]::WriteAllText($kgkEslemeYolu, [string](ConvertTo-Json -InputObject $eslemeNesnesi -Depth 4), (New-Object Text.UTF8Encoding($false)))
  } else { Write-Host 'KGK kitapcik delili: ne etiket klasoru ne karar dosyasi var - atlandi' }
}

$konu = @{}
foreach($d in $donemler){
  $gorulen = @{}
  foreach($p in $d.konuSayim.PSObject.Properties){
    $ham = $p.Name
    if($Sinav -eq 'KGK'){
      $parca = "$ham" -split '\|',2
      if($parca.Count -eq 2){
        $hedefDers = KgkDers $parca[0] $parca[1]
        if($hedefDers -like 'BIRLESIK-*' -and $kgkDelil.ContainsKey("$($parca[0])|$($parca[1])")){ $hedefDers = $kgkDelil["$($parca[0])|$($parca[1])"] + ' (delil)' }
        elseif($hedefDers -like 'BIRLESIK-*' -and $kgkKitapcik.ContainsKey("$($parca[0])|$($parca[1])")){ $hedefDers = $kgkKitapcik["$($parca[0])|$($parca[1])"] + ' (kitapcik)' }
        $izAnah = "$(Norm $parca[0]) -> $hedefDers"
        $kgkSayac[$izAnah] = 1 + [int]$kgkSayac[$izAnah]
        $ham = "$($hedefDers -replace ' \((delil|kitapcik)\)$','')|$($parca[1])"
      }
    }
    $anah = Norm $ham
    if(-not $anah){ continue }
    if(-not $konu.ContainsKey($anah)){ $konu[$anah] = @{ donem = 0; soru = 0; ad = $ham } }
    $konu[$anah].soru += [int]$p.Value
    if(-not $gorulen[$anah]){ $konu[$anah].donem++; $gorulen[$anah] = $true }
  }
}
Write-Host ("Benzersiz konu: {0}" -f $konu.Count)

# En cok cikan 25 konu — bunlar "sinavin belkemigi", pazarlamada da kullanilir
$enCok = $konu.GetEnumerator() | Sort-Object { $_.Value.donem }, { $_.Value.soru } -Descending | Select-Object -First 25

$tablo = [ordered]@{}
foreach($k in ($konu.GetEnumerator() | Sort-Object Name)){
  $tablo[$k.Key] = [ordered]@{ d = $k.Value.donem; s = $k.Value.soru; ad = $k.Value.ad }
}

$rapor = [ordered]@{
  tarih         = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kaynak        = $(switch($Sinav){ 'SMMM' { 'veri/smmm-analiz.json — cikmis SMMM Yeterlilik kitapciklarinin (yazili + test) konu sayimi' } 'KGK' { 'veri/kgk-analiz.json — cikmis KGK kitapciklarinin konu sayimi; ders adi kota etiketine eslendi (bkz. ders_esleme)' } default { 'veri/sgs-analiz.json — cikmis SGS kitapciklarinin konu sayimi' } })
  donem_sayisi  = $donemSayisi
  konu_sayisi   = $konu.Count
  en_cok_cikan  = @($enCok | ForEach-Object { [ordered]@{ konu = $_.Value.ad; donem = $_.Value.donem; soru = $_.Value.soru } })
  konular       = $tablo
  kullanim      = 'Anahtar = Norm("<ders>|<konu>"). Kasadaki soru bu anahtarla aranir; BULUNAMAZSA kunye GOSTERILMEZ (D9 freni: sayim yoksa yazilmaz).'
}
if($Sinav -eq 'KGK'){
  $rapor['ders_esleme'] = [ordered]@{}
  foreach($iz in ($kgkSayac.GetEnumerator() | Sort-Object { $_.Value } -Descending)){ $rapor['ders_esleme'][$iz.Key] = $iz.Value }
  $rapor['eslenmeyen_konu'] = [int](($kgkSayac.GetEnumerator() | Where-Object { $_.Key -match '-> (BIRLESIK|ESLENMEDI)' } | Measure-Object Value -Sum).Sum)
  $rapor['esleme_notu'] = 'Cikmis KGK haritasindaki ders adi kota etiketine (veri/kgk-uretim-kotasi.json) eslendi. Birlesik modul konu kelimesiyle bolundu; kelime tutmazsa ders BIRLESIK- kaldi ve o konunun kunyesi GOSTERILMEZ. Genel Hukuk Mevzuati resmi ders listesinde yok (tarihsel), kotaya girmez.'
}
Set-Content -LiteralPath $cikti -Value (ConvertTo-Json -InputObject $rapor -Depth 6) -Encoding UTF8 -NoNewline
Write-Host "`n=== EN COK CIKAN 10 KONU ==="
$enCok | Select-Object -First 10 | ForEach-Object {
  Write-Host ("  {0,2}/{1} donem · {2,3} soru · {3}" -f $_.Value.donem, $donemSayisi, $_.Value.soru, $_.Value.ad)
}
Write-Host ("`n-> {0}" -f $cikti)
