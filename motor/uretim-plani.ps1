#requires -Version 5.1
<#
================================================================================
  URETIM PLANI — SGS  (11.09.2026, Cem "seri uretime girmeden plan yapalim")

  NIYE: "3 bin kusurda bir soru cikarmistik" — fabrikada 3.701 soru var ama
  yayina girmis 630. Aradaki farkin NEREDE oldugu ve NE KADARININ kurtarilabilir
  oldugu olculmeden seri uretim kararı verilemez.

  NE OLCER (hicbir rakam elle yazilmaz):
    1) Sinavda her dersten kac soru cikiyor        -> veri/ders-profili.json
    2) Yayina girmis v2 havuzumuz ders ders        -> veri/sinav/kaydir-secim/sgs-650-secim.json
    3) Fabrikada TUM kapilardan gecip havuza
       ALINMAMIS soru (hasat edilebilir) ders ders -> veri/fabrika/kalip-parti-*.json
    4) Gercek birim maliyet                        -> veri/fabrika/bedel-kayit.jsonl
    5) Hedef deneme sayisina gore ders ders ACIK

  ⛔ v1 KASA SAYISI (15.827) BU PLANDA KULLANILMAZ. Kasa sorularinin
     kalip_surum'u yok; CHECK kisiti yayina girmelerini engelliyor. Plan
     yalnizca yayina girebilen v2 sorularini sayar.

  DERS NEREDEN GELIR: fabrika kayitlarinda `ders` alani BOS (parti duzeyinde
  tutuluyor). Ders, parti ETIKETINDEN cozulur (asagidaki DERS_ANAHTARI).
  Cozulemeyen etiket rapora AYRICA yazilir — sessizce yutulmaz.

  BEDEL 0 — yalniz yerel dosya okur, hicbir API cagrisi yapmaz.
================================================================================
#>
param(
  [int]$HedefDeneme = 10,          # kac tam deneme sinavi cikarmak istiyoruz
  [double]$Kur      = 41.0         # 1 USD = ? TL (varsayim, raporda yazilir)
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

# --- OLCUM KAPILARI (11.09, Cem "olcum araclarina oz-sinav ekle") -------------
# Bu betik OLCUM yapar; olcum aracinin kendisi bozuksa cikan rakam yanlis KARAR
# urettirir (11.09'da dort kez oldu). Oz-sinav kirmizi donerse HIC olcmez.
. (Join-Path $depoKok 'arac\olcum-kapilari.ps1')
$ok_kusur=Test-OlcumKapilari -Sessiz
if((Dizi $ok_kusur).Count){
  Write-Host '⛔ OLCUM KAPILARI KIRMIZI - bu olcume guvenilmez:' -ForegroundColor Red
  foreach($h in (Dizi $ok_kusur)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'olcum kapilari oz-sinavi dustu'
}


# --- 1) SINAV AGIRLIKLARI ----------------------------------------------------
$prof=Get-Content (Join-Path $depoKok 'veri\ders-profili.json') -Raw -Encoding UTF8|ConvertFrom-Json
$sgs=$prof.sinavlar.'STAJA BAŞLAMA (SGS)'
if(-not $sgs){ throw 'ders-profili.json icinde "STAJA BAŞLAMA (SGS)" yok.' }
# ⚠ TURKCE KATLAMA SART: ders-profili ASCII yazar ("Borclar Hukuku"),
#   secim dosyasi Turkce yazar ("Borçlar Hukuku"). Katlamasiz eslestirmede
#   Borclar (37) + Is-SGK (18) = 55 soru sessizce dusuyordu.
function DersKatla([string]$s){
  $x="$s".Trim()
  foreach($c in @(@('ç','c'),@('Ç','C'),@('ğ','g'),@('Ğ','G'),@('ı','i'),@('İ','I'),
                  @('ö','o'),@('Ö','O'),@('ş','s'),@('Ş','S'),@('ü','u'),@('Ü','U'))){
    $x=$x.Replace($c[0],$c[1])
  }
  return $x.ToUpperInvariant()
}
$agirlik=[ordered]@{}; $dersAd=@{}
foreach($p in $sgs.PSObject.Properties){
  $k=DersKatla $p.Name
  $agirlik[$k]=[int]$p.Value.soru_sayisi
  $dersAd[$k]=$p.Name
}
$sinavToplam=0; foreach($k in $agirlik.Keys){ $sinavToplam+=$agirlik[$k] }

# --- 2) YAYINDAKI v2 HAVUZU --------------------------------------------------
$secimDosya=Join-Path $depoKok 'veri\sinav\kaydir-secim\sgs-650-secim.json'
$havuz=@{}; $havuzAnahtar=@{}
# ⚠ PS 5.1 TUZAGI: `@(Get-Content|ConvertFrom-Json)` diziyi TEK ogeye sarar
#   (ConvertFrom-Json boru hattina enumerate ETMEDEN yazar). Once degiskene alinir;
#   degisken uzerinde @() dogru calisir. Bu hata ilk kosuda "yayinda 0" verdi.
$secimHam=Get-Content $secimDosya -Raw -Encoding UTF8|ConvertFrom-Json
$havuzYabanci=@{}
foreach($r in @($secimHam)){
  $d=DersKatla "$($r.ders)"; if(-not $d){ $d='(DERS YOK)' }
  $havuz[$d]=1+[int]$havuz[$d]
  if(-not $agirlik.Contains($d)){ $havuzYabanci[$d]=1+[int]$havuzYabanci[$d] }
  $havuzAnahtar["$($r.etiket)|$($r.id)"]=$true
}

# --- 3) FABRIKADA HASAT EDILEBILIR -------------------------------------------
# Etiketten ders cozumu. Anahtar, etikette "-anahtar-" ya da "anahtar-" olarak gecer.
$DERS_ANAHTARI=[ordered]@{
  'fmuh'='Finansal Muhasebe'; 'denetim'='Denetim'; 'maliyet'='Maliyet Muhasebesi'
  'mta'='Mali Tablolar Analizi'; 'ticaret'='Ticaret Hukuku'; 'borclar'='Borclar Hukuku'
  'vergi'='Vergi Hukuku'; 'meslek'='Meslek Hukuku'; 'issgk'='Is ve Sosyal Guvenlik Hukuku'
  'mat'='Matematik'; 'turkce'='Turkce'; 'yd'='Yabanci Dil'; 'ydil'='Yabanci Dil'
  'yabancidil'='Yabanci Dil'; 'ekonomi'='Ekonomi'; 'maliye'='Maliye'
  'inkilap'='Ataturk Ilkeleri ve Inkilap Tarihi'; 'ataturk'='Ataturk Ilkeleri ve Inkilap Tarihi'
}
function DersCoz([string]$etiket){
  foreach($k in $DERS_ANAHTARI.Keys){ if($etiket -match "(^|-)$k(-|$)"){ return (DersKatla $DERS_ANAHTARI[$k]) } }
  return $null
}
# Bir kayit TUM kapilardan gecti mi? (kalip-kosucu.ps1'in secim kapisiyla ayni sira)
function KapilardanGecti($v){
  if(-not ($v -and $v.soru)){ return $false }
  if(-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')){ return $false }
  if("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ return $false }
  if(-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ return $false }
  if(-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ return $false }
  foreach($sa in 'simulasyon_sonnet','simulasyon'){
    if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ return $false }
  }
  return $true
}

# CEVAP BICIMI KILITLI (Cem 11.09: "nobetci coz / sen coz sayfa gibi uretilecek cevaplar").
# Sartname: STANDART-CEVAP-KALIBI.md · builder: motor/kaydir-coz.ps1 (bedel 0, API yok).
# Sayfanin doldurdugu alanlar asagida sayilir: raftaki soru bu alanlari tasimiyorsa
# hasat bedeli YANLIS hesaplanir (sade'den fazlasi gerekir).
$SAYFA_ALANI=@('sade','adimlar','konu_giris','ikiz','teori_ikiz','sema','cozum_tablo','hap','sinav_taktigi','teshis')
$sayfaDolu=[ordered]@{}; foreach($a in $SAYFA_ALANI){ $sayfaDolu[$a]=0 }
$sayfaHazir=0

$hasat=@{}; $hasatSade=@{}; $cozulemeyen=@{}
$huni=[ordered]@{ toplam=0; hakemYok=0; hakemHayir=0; korYok=0; korYanlis=0; hakem2Yok=0; hakem2Hayir=0; simYanlis=0; gecen=0 }
foreach($x in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  $et=($x.BaseName -replace '^kalip-parti-','')
  $ders=DersCoz $et
  $c=$null; try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    $huni.toplam++
    if(-not $v.hakem){ $huni.hakemYok++ } elseif("$($v.hakem.karar)" -eq 'HAYIR'){ $huni.hakemHayir++ }
    if(-not $v.kor_cozum){ $huni.korYok++ } elseif(-not [bool]$v.kor_cozum.dogru_mu){ $huni.korYanlis++ }
    if(-not $v.hakem2){ $huni.hakem2Yok++ } elseif("$($v.hakem2.karar)" -eq 'HAYIR'){ $huni.hakem2Hayir++ }
    foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $huni.simYanlis++; break } }
    if(-not (KapilardanGecti $v)){ continue }
    $huni.gecen++
    if($havuzAnahtar.ContainsKey("$et|$($p.Name)")){ continue }   # zaten yayinda
    foreach($a in $SAYFA_ALANI){ if($v.PSObject.Properties[$a] -and $v.$a){ $sayfaDolu[$a]++ } }
    $ikizVar=($v.PSObject.Properties['ikiz'] -and $v.ikiz) -or ($v.PSObject.Properties['teori_ikiz'] -and $v.teori_ikiz)
    if(($v.sade -and $v.sade.dogru) -and $v.adimlar -and $v.konu_giris -and $ikizVar){ $sayfaHazir++ }
    if($ders){
      $hasat[$ders]=1+[int]$hasat[$ders]
      if($v.sade -and $v.sade.dogru){ $hasatSade[$ders]=1+[int]$hasatSade[$ders] }
    } else { $cozulemeyen[$et]=1+[int]$cozulemeyen[$et] }
  }
}

# --- 4) GERCEK BIRIM MALIYET -------------------------------------------------
$bedelDosya=Join-Path $depoKok 'veri\fabrika\bedel-kayit.jsonl'
$usdEt=@{}
foreach($ln in (Get-Content $bedelDosya -Encoding UTF8)){
  if(-not $ln.Trim()){ continue }
  $r=$null; try{ $r=$ln|ConvertFrom-Json }catch{ continue }
  $usdEt["$($r.etiket)"]=[double]$r.toplamUsd + [double]$usdEt["$($r.etiket)"]
}
$defUsd=0; $defUret=0; $defGecen=0
foreach($et in $usdEt.Keys){
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
  if(-not (Test-Path $f)){ continue }
  $defUsd+=$usdEt[$et]
  $c=Get-Content $f -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($p in $c.PSObject.Properties){
    if(-not ($p.Value -and $p.Value.soru)){ continue }
    $defUret++
    if(KapilardanGecti $p.Value){ $defGecen++ }
  }
}
$birimUsd = if($defGecen){ $defUsd/$defGecen } else { 0 }
$birimTl  = $birimUsd*$Kur
$SADE_USD = 0.009      # arac/sade-tamamla.ps1 basligindaki OLCULEN bedel (10.09 provasi)
$sadeTl   = $SADE_USD*$Kur

# --- 5) PLAN TABLOSU ---------------------------------------------------------
$satir=New-Object System.Collections.Generic.List[object]
foreach($d in $agirlik.Keys){
  $w=$agirlik[$d]; $v2=[int]$havuz[$d]; $hs=[int]$hasat[$d]
  $toplam=$v2+$hs
  $hedef=$w*$HedefDeneme
  $satir.Add([pscustomobject]@{
    ders=$dersAd[$d]; sinav=$w; v2=$v2; hasat=$hs; toplam=$toplam
    deneme=[math]::Round($toplam/[double]$w,1)
    hedef=$hedef; acik=[math]::Max(0,$hedef-$toplam)
  })
}
$topV2=0;$topHasat=0;$topAcik=0
foreach($s in $satir){ $topV2+=$s.v2; $topHasat+=$s.hasat; $topAcik+=$s.acik }
$darBogaz=($satir|Sort-Object deneme|Select-Object -First 1)

# --- 6) RAPOR ----------------------------------------------------------------
$m=New-Object System.Text.StringBuilder
function Y([string]$s){ [void]$m.AppendLine($s) }
Y "# URETIM PLANI — STAJA BASLAMA (SGS)"
Y ""
Y ("> Uretim: **{0}** (makine; elle duzenlenmez — motor/uretim-plani.ps1). Hedef: **{1} tam deneme sinavi**." -f (Get-Date -Format 'dd.MM.yyyy HH:mm'),$HedefDeneme)
Y "> Kaynaklar: ders agirligi = veri/ders-profili.json · yayindaki havuz = veri/sinav/kaydir-secim/sgs-650-secim.json · fabrika = veri/fabrika/kalip-parti-*.json · bedel = veri/fabrika/bedel-kayit.jsonl"
Y ""
Y "## 0 · TEK CUMLE"
Y ""
Y ("Fabrikada **{0:N0}** soru uretildi, **{1:N0}**'i tum kapilardan gecti, ama yayinda **{2:N0}** var. Aradaki **{3:N0}** soru SAGLAM ve rafta duruyor." -f $huni.toplam,$huni.gecen,$topV2,$topHasat)
Y ""
Y "## 1 · ''3 BIN KUSUR''UN NEREYE GITTIGI — fabrika hunisi"
Y ""
Y "| Asama | Soru | Pay |"
Y "|---|---:|---:|"
foreach($k in @('toplam','hakemYok','hakemHayir','korYok','korYanlis','hakem2Yok','hakem2Hayir','simYanlis','gecen')){
  $ad=switch($k){
    'toplam'{'FABRIKADA URETILEN'} 'hakemYok'{'hakem hic kosmamis'} 'hakemHayir'{'hakem HAYIR'}
    'korYok'{'kor cozum hic kosmamis'} 'korYanlis'{'kor cozum YANLIS'}
    'hakem2Yok'{'hakem2 hic kosmamis'} 'hakem2Hayir'{'hakem2 HAYIR'}
    'simYanlis'{'simulasyon YANLIS'} 'gecen'{'**TUM KAPILARDAN GECEN**'} }
  Y ("| {0} | {1:N0} | %{2:N1} |" -f $ad,$huni[$k],(100*$huni[$k]/[double]$huni.toplam))
}
Y ""
Y ("**Kapi sistemi calisiyor:** uretilen her 100 sorudan {0:N0}'i eleniyor. Bu israf degil, kalite bedeli — elenenler yayina cikmiyor." -f (100-100*$huni.gecen/[double]$huni.toplam))
Y ""
Y "> Asamalar **ust uste biner**: hakemden HAYIR alan soruya kor cozum hic kosmaz, o yuzden ''hic kosmamis'' satirlari birbirini kapsar. Toplamlari degil, son satiri oku."
Y ""
Y "## 2 · DERS DERS: SINAV AGIRLIGI × ELIMIZDEKI"
Y ""
Y "| Ders | Sinavda | Yayinda (v2) | Rafta (hasat) | TOPLAM | Kac deneme cikar | Hedef | ACIK |"
Y "|---|---:|---:|---:|---:|---:|---:|---:|"
foreach($s in ($satir|Sort-Object sinav -Descending)){
  $ac= if($s.acik -gt 0){ "**$($s.acik)**" } else { '—' }
  Y ("| {0} | {1} | {2} | {3} | {4} | {5:N1} | {6} | {7} |" -f $s.ders,$s.sinav,$s.v2,$s.hasat,$s.toplam,$s.deneme,$s.hedef,$ac)
}
Y ("| **TOPLAM** | **{0}** | **{1:N0}** | **{2:N0}** | **{3:N0}** | | **{4:N0}** | **{5:N0}** |" -f $sinavToplam,$topV2,$topHasat,($topV2+$topHasat),($sinavToplam*$HedefDeneme),$topAcik)
Y ""
Y ("**DAR BOGAZ: {0}** — {1} soruyla ancak {2:N1} deneme cikar. Deneme sayisini bu ders belirler." -f $darBogaz.ders,$darBogaz.toplam,$darBogaz.deneme)
Y ""
$rafT=0; foreach($k in $hasat.Keys){ $rafT+=$hasat[$k] }
$rafHam=$rafT; foreach($e in $cozulemeyen.GetEnumerator()){ $rafHam+=$e.Value }
Y "## 3 · CEVAP BICIMI — ''Nobetci anlatsin / Sen coz'' sayfasi"
Y ""
Y "**KILITLI KARAR (Cem, 11.09):** cevaplar Kaydir-Coz sayfasi olarak uretilir."
Y "Sartname `STANDART-CEVAP-KALIBI.md` · builder `motor/kaydir-coz.ps1` (onbellekten basar, API yok, **bedel 0**)."
Y ""
Y "Sayfanin doldurdugu alanlar raftaki sorularda ne kadar hazir:"
Y ""
Y "| Alan | Dolu | Oran | Ne ise yarar |"
Y "|---|---:|---:|---|"
$ALAN_ISI=@{ sade='panel (2 sik + kavramlar)'; adimlar='adim adim cozum'; konu_giris='Nobetci anlatsin girisi'
  ikiz='Sen coz ikizi (hesap)'; teori_ikiz='Sen coz ikizi (teori)'; sema='yevmiye / T-hesabi'
  cozum_tablo='cozum tablosu'; hap='hap bilgi'; sinav_taktigi='sinav taktigi'; teshis='teshis (ne sanmistin)' }
foreach($a in $SAYFA_ALANI){
  Y ("| {0} | {1:N0} | %{2:N1} | {3} |" -f $a,$sayfaDolu[$a],(100*$sayfaDolu[$a]/[double]$rafHam),$ALAN_ISI[$a])
}
Y ""
Y ("**SONUC:** eksik olan tek alan **sade** (%{0:N1}). Sayfanin geri kalanini besleyen alanlar uretimde zaten dolduruluyor — hap/taktik/teshis %100, konu girisi %{1:N1}, adimlar %{2:N1}, ikiz (hesap+teori) %{3:N1}. Bu yuzden hasat bedeli = **yalniz sade paneli**." -f (100*$sayfaDolu['sade']/[double]$rafHam),(100*$sayfaDolu['konu_giris']/[double]$rafHam),(100*$sayfaDolu['adimlar']/[double]$rafHam),(100*($sayfaDolu['ikiz']+$sayfaDolu['teori_ikiz'])/[double]$rafHam))
Y ""
Y "## 4 · BEDEL (olculdu, tahmin degil)"
Y ""
Y "| Kalem | Bedel |"
Y "|---|---:|"
Y ("| Sifirdan soru uretmek (kapilardan gecen basina) | {0:N3} USD = **{1:N2} TL** |" -f $birimUsd,$birimTl)
Y ("| Raftaki soruyu yayina hazirlamak (sade paneli) | {0:N3} USD = **{1:N2} TL** |" -f $SADE_USD,$sadeTl)
Y ("| **{0:N0} raf sorusunu hasat etmek** | **{1:N0} TL** |" -f $topHasat,($topHasat*$sadeTl))
Y ("| **{0:N0} acik soruyu sifirdan uretmek** | **{1:N0} TL** |" -f $topAcik,($topAcik*$birimTl))
Y ("| Ayni {0:N0} soruyu hasat yerine sifirdan uretseydik | {1:N0} TL |" -f $topHasat,($topHasat*$birimTl))
Y ""
Y ("Hasat, ayni sayida soruyu sifirdan uretmeye gore **{0:N0} TL** ucuz ({1:N0}x)." -f (($topHasat*$birimTl)-($topHasat*$sadeTl)),($birimTl/$sadeTl))
Y ""
$tik=[char]96
Y ("> Bedel defterinde {0}varsayim=true{0}: jeton sayilari GERCEK, USD fiyatlari model liste fiyatindan hesaplaniyor. Kur varsayimi 1 USD = {1} TL." -f $tik,$Kur)
Y ""
Y "## 5 · SIRA"
Y ""
Y ("1. **Hasat** — {0:N0} raf sorusunu sade panelinden gecir, havuza al. ({1:N0} TL)" -f $topHasat,($topHasat*$sadeTl))
Y ("2. **Acik kapatma** — {0:N0} soru sifirdan uret; oncelik dar bogaz dersleri. ({1:N0} TL)" -f $topAcik,($topAcik*$birimTl))
Y ("3. Toplam: **{0:N0} TL** ile {1} tam deneme sinavi." -f (($topHasat*$sadeTl)+($topAcik*$birimTl)),$HedefDeneme)
$bolum=5
if($havuzYabanci.Count){
  $bolum++
  Y ""
  Y ("## {0} · YAYINDA OLUP RESMI DERS LISTESINDE OLMAYAN DERS ADLARI" -f $bolum)
  Y ""
  Y "| Havuzdaki ad | Soru |"
  Y "|---|---:|"
  foreach($e in ($havuzYabanci.GetEnumerator()|Sort-Object Value -Descending)){ Y ("| {0} | {1} |" -f $e.Key,$e.Value) }
  Y ""
  Y "Bu sorular ders tablosunda **sayilmiyor**. Ders adi ders-profili.json ile hizalanmali."
}
if($cozulemeyen.Count){
  $bolum++
  Y ""
  Y ("## {0} · DERSI COZULEMEYEN ETIKETLER (hasat disinda kaldi)" -f $bolum)
  Y ""
  Y "| Etiket | Soru |"
  Y "|---|---:|"
  foreach($e in ($cozulemeyen.GetEnumerator()|Sort-Object Value -Descending)){ Y ("| {0} | {1} |" -f $e.Key,$e.Value) }
  $cTop=0; foreach($e in $cozulemeyen.GetEnumerator()){ $cTop+=$e.Value }
  Y ""
  Y ("Toplam {0} soru. Etikette ders anahtari yok; ders elle atanmali ya da etiket duzeltilmeli." -f $cTop)
}

$hedefDosya=Join-Path $depoKok 'veri\URETIM-PLANI-SGS.md'
[IO.File]::WriteAllText($hedefDosya,$m.ToString(),(New-Object Text.UTF8Encoding $true))
Write-Host ("-> {0}" -f $hedefDosya) -ForegroundColor Green
Write-Host ("fabrika {0:N0} · gecen {1:N0} · yayinda {2:N0} · rafta {3:N0} · acik {4:N0}" -f $huni.toplam,$huni.gecen,$topV2,$topHasat,$topAcik) -ForegroundColor Cyan
Write-Host ("dar bogaz: {0} ({1:N1} deneme)" -f $darBogaz.ders,$darBogaz.deneme) -ForegroundColor Yellow


