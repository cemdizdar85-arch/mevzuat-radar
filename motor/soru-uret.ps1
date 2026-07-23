# ============================================================================
#  SORU FABRIKASI — UWorld modelinin Tetikte uygulamasi (SGS + Yeterlilik).
#  Harita (sgs-analiz.json) agirliklarina gore EN COK SORU GETIREN konulardan
#  OZGUN sorular uretir. Cikmis soru KOPYALANMAZ.
#  Her soru: kok + 5 sik + dogru cevap + HER SIKKIN GEREKCESI + kanun maddesi.
#  KAPILAR (UWorld hakem surecinin robotu):
#   1) Bagimsiz COZUCU-1 soruyu cozer — anahtar ile eslesmezse RET
#   2) Bagimsiz COZUCU-2 ayni — ikisi de bulamayan soru muglaktir, RET
#   3) AMBAR TEYIDI — kaynak maddesi Supabase arsivinde gercekten var mi
#   4) Rakam disiplini — yil-degisen tutar geciyorsa RET (oran/sure sabiti serbest)
#   5) Kok tekrari — ayni konuda benzer kokle baslayan soru varsa RET
#  Cikti: veri/soru-bankasi-onay.json (STAGING — orneklem onayi sonrasi yayin).
#  ENV: ANTHROPIC_API_KEY. Kosum: $KONU_LIMIT konu x $ADET soru.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL_URET = "claude-sonnet-5"
$MODEL_COZ  = "claude-haiku-4-5-20251001"
$KONU_LIMIT = 8    # Cem 23.07 hiz talimati kademe 2 — kosu basi 40 aday (8 konu x 5)
$ADET = 5
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

$analizYol = Join-Path $kok "veri/sgs-analiz.json"
if(-not (Test-Path $analizYol)){ Write-Host "sgs-analiz.json yok - ONCE Sinav Analizi calistir."; exit 0 }
$analiz = Get-Content $analizYol -Raw -Encoding UTF8 | ConvertFrom-Json
if(-not $analiz.donemler -or -not @($analiz.donemler).Count){ Write-Host "Harita bos - once Sinav Analizi."; exit 0 }

$bankaYol = Join-Path $kok "veri/soru-bankasi-onay.json"
$banka = if(Test-Path $bankaYol){ Get-Content $bankaYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; sorular=@() } }
# YAYINLANMIS banka da sayilir: onaydan tasinip yayina giden sorular tekrar
# uretilmesin, konu doygunlugu yayindakileri de gorsun.
$yayinYol = Join-Path $kok "veri/soru-bankasi.json"
$yayinSorular = @(); if(Test-Path $yayinYol){ try { $yayinSorular = @((Get-Content $yayinYol -Raw -Encoding UTF8 | ConvertFrom-Json).sorular) } catch {} }

function Claude($istem,$maxtok,$model){
  $body = @{ model=$model; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; $m2=[regex]::Match($t,'(?s)\{.*\}'); if($m2.Success){ return $m2.Value }; return $null }
function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }

# AMBAR TEYIDI (gece-ajani ile ayni desen)
$SB_URL="https://bjrleanjpyujtajmazxn.supabase.co"; $SB_ANON="sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"
$KANUN_NO=[ordered]@{ 'kvkk'='6698'; 'vuk'='213'; 'gvk'='193'; 'kdvk'='3065'; 'kvk'='5520'; 'ttk'='6102'; 'smk'='6769'; 'aatuhk'='6183'; 'otv'='4760'; 'iik'='2004'; 'tbk'='6098'; 'isg'='6331' }
function AmbarTeyit($kaynak){
  $f=Fold $kaynak
  if($f -match 'gut|teblig|karar|yonetmelik|genelge'){ return 'atla' }
  $no=$null; $mN=[regex]::Match($f,'(?<!\d)(\d{3,4})(?!\d)\s*(s\.|sayili)'); if($mN.Success){ $no=$mN.Groups[1].Value }
  if(-not $no){ foreach($k in $KANUN_NO.Keys){ if($f -match ('(?<![a-z])'+[regex]::Escape($k)+'(?![a-z])')){ $no=$KANUN_NO[$k]; break } } }
  if(-not $no){ return 'atla' }
  $on=''; if($f -match 'muk(\.|errer)'){ $on='muk. ' } elseif($f -match 'gec(\.|ici)'){ $on='gec. ' } elseif($f -match '(?<![a-z])ek\s*m'){ $on='ek ' }
  $mM=[regex]::Match($kaynak,'m(?:adde)?\.?\s*(\d+(?:/[A-Za-zÇĞİÖŞÜçğıöşü])?)'); if(-not $mM.Success){ return 'atla' }
  $filtre="*$no*"+$on+"m."+$mM.Groups[1].Value.ToUpperInvariant()+"*"
  try{ $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString($filtre)+"&select=id&limit=1"
    $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
    if(@($r).Count -ge 1){ return 'ok' } else { return 'yok' } }catch{ return 'atla' }
}

# KILITLI HAVUZ: Supabase'e tasinan paket sorulari da kok-tekrar ve doygunluk
# hesabina girer (yoksa ayni sorular yeniden uretilirdi). Service key yalniz
# Actions ortaminda vardir; yerelde/anahtarsiz zarifce atlanir.
$havuzSorular = @()
if($env:SUPABASE_SERVICE_KEY){
  try {
    $hh = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
    $havuzSorular = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=soru,ders,konu&limit=10000" -Headers $hh -TimeoutSec 60)
    Write-Host ("Kilitli havuzdan {0} soru cekildi (kok/doygunluk)." -f $havuzSorular.Count)
  } catch { Write-Host "Kilitli havuz cekilemedi (tablo henuz kurulmamis olabilir) - devam." }
}

# HARITA: en cok soru getiren konular (mevcut bankada az temsil edilenler oncelikli)
# MESLEK ODAGI: Yabanci Dil ve Genel Kultur uretim hedefi DEGIL — kozumuz
# kaynak-maddeli meslek sorulari (Muhasebe/Hukuk/Ekonomi/Maliye/Mat-Ist).
$HARIC_DERS = @('Yabanci Dil','Genel Kultur-Genel Yetenek')
# konu anahtari: "SINAV|ders|konu" — SGS + SMMM Yeterlilik AYNI fabrikadan beslenir
$konular=@{}
foreach($dn in $analiz.donemler){ foreach($p in $dn.konuSayim.PSObject.Properties){
  $dAd = ($p.Name -split '\|')[0]
  if($HARIC_DERS -contains $dAd){ continue }
  $konular["SGS|"+$p.Name]=[int]$konular["SGS|"+$p.Name]+[int]$p.Value } }
$analizSYol = Join-Path $kok "veri/smmm-analiz.json"
if(Test-Path $analizSYol){
  try {
    $analizS = Get-Content $analizSYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($dn in @($analizS.donemler)){ foreach($p in $dn.konuSayim.PSObject.Properties){
      $konular["SMMM|"+$p.Name]=[int]$konular["SMMM|"+$p.Name]+[int]$p.Value } }
    Write-Host ("Yeterlilik haritasi da hedefte: {0} donem-ders." -f @($analizS.donemler).Count)
  } catch { Write-Host "smmm-analiz okunamadi - yalniz SGS hedeflenecek." }
}
$bankaSay=@{}
foreach($s in (@($banka.sorular)+$yayinSorular+$havuzSorular)){ $kk="$($s.ders)|$($s.konu)"; $bankaSay[$kk]=1+[int]$bankaSay[$kk] }
$hedefler = $konular.GetEnumerator() | Sort-Object { -($_.Value) } | Where-Object { [int]$bankaSay[($_.Key -split '\|',2)[1]] -lt 10 } | Select-Object -First $KONU_LIMIT
if(-not $hedefler){ Write-Host "Tum agir konularda 10+ soru var - banka doygun."; exit 0 }

$mevcutKokler = @(@($banka.sorular)+$yayinSorular+$havuzSorular) | ForEach-Object { (Fold $_.soru).Substring(0, [Math]::Min(60, (Fold $_.soru).Length)) }
$yeniListe = New-Object System.Collections.Generic.List[object]
if($banka.sorular){ $yeniListe.AddRange(@($banka.sorular)) }
$rapor = New-Object System.Collections.Generic.List[string]

foreach($h in $hedefler){
  $parca = $h.Key -split '\|'; $sinavAd=$parca[0]; $ders=$parca[1]; $konu=$parca[2]
  $sinavTanim = if($sinavAd -eq 'SMMM'){ "TURMOB-TESMER SMMM Yeterlilik Sinavi (2026/1'den beri coktan secmeli test)" } else { "TESMER Staja Giris Sinavi (SGS)" }
  Write-Host ("=== [{0}] {1} / {2} (haritada {3} soru getirmis) icin {4} ozgun soru uretiliyor..." -f $sinavAd,$ders,$konu,$h.Value,$ADET)
  $uIstem = @"
Sen $sinavTanim tarzinda OZGUN coktan secmeli soru yazan uzman bir egitimcisin. Ders: $ders · Konu: $konu
$ADET adet ORTA-ZOR seviye, birbirinden farkli soru yaz. CIKMIS SORU KOPYALAMA - tamamen ozgun kurgular.
KURALLAR:
1) 5 sik (A-E), TEK dogru cevap; celdirici siklar tipik ogrenci hatalarindan kurulsun.
2) aciklama alaninda HER sikkin neden dogru/yanlis oldugunu yaz — ama YARGI degil DERS: her yanlis sik belirli bir YANILGIYI temsil etmeli ve aciklamasi o yanilgiyi COZMELI. Ornek: ogrenci 653 yerine 780 sasirdiysa 'yanlistir, 780 olmali' DEME; 653 ile 780 arasindaki KAVRAM FARKINI ogret (biri is yaptirmanin, digeri para bulmanin maliyeti). Sikki seceni 'neyi bildigi, neyi karistirdigi' uzerinden yakala.
3) kaynak alanina dayandigi SPESIFIK kanun maddesini yaz (or. VUK m.323, TTK m.68). Madde uyduramazsin.
4) Yila gore degisen TUTAR sorma (asgari ucret kac TL gibi) - oran, sure, ilke, hesap mantigi sor. Ornek islem tutari (10.000 TL'lik mal gibi) SERBEST.
5) Sade, kitapcik Turkcesiyle.
6) hap alanina konunun 3-4 cumlelik OZ ANLATIMINI yaz: soruyu yanlis yapan kisi bu paragrafi okuyunca konuyu ogrenmis olsun (kural + ipucu/tuzak). Ders kitabi degil, hap: net, ezber degil mantik.
7) Soru bir MUHASEBE KAYDI/hesap isleyisi soruyorsa, dogru kaydin gorselini "yevmiye" alaninda ver: [{"hesap":"102 Bankalar","borc":88000,"alacak":0},...] — borclananlar once, alacaklananlar sonra. Kayit sorusu degilse yevmiye alanini HIC koyma.
SADECE su JSON dizisini dondur:
[{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"kaynak":"...","hap":"...","yevmiye":[...]}]
"@
  # 23.07 dersi: 8000 token 5 soru + hap anlatimlara DAR geldi, JSON yarida kesildi
  # (6 konudan 4'u URETIM/JSON hatasiyla dustu). 16000'e cikarildi + API sigortasi.
  $ham = $null
  try { $ham = Claude $uIstem 16000 $MODEL_URET } catch { $rapor.Add("API HATASI: $konu ($($_.Exception.Message))"); continue }
  $js = JsonBul $ham; if(-not $js){ $rapor.Add("URETIM HATASI (JSON bulunamadi/kesik): $konu"); continue }
  $uretilen = @(); try{ $uretilen = $js | ConvertFrom-Json }catch{ $rapor.Add("JSON HATASI: $konu"); continue }

  foreach($s in @($uretilen)){
    $kokOzet = (Fold $s.soru); $kokOzet = $kokOzet.Substring(0,[Math]::Min(60,$kokOzet.Length))
    # KAPI 5: kok tekrari
    if($mevcutKokler -contains $kokOzet){ $rapor.Add("RET (tekrar): $($s.soru.Substring(0,[Math]::Min(40,$s.soru.Length)))"); continue }
    # KAPI 4: yil-degisen KANUNI tutar (ornek islem tutarlari SERBEST — muhasebe
    # hesap sorusu tutarsiz olmaz; yasak olan "asgari ucret/had/istisna kac TL" tipi,
    # her yil guncellenen mevzuat tutarini ezber soran soru). 22.07 dersi: eski hal
    # TUM TL'li sorulari kesiyordu -> fabrika 0 uretti.
    $tumMetin = "$($s.soru) " + (($s.siklar.PSObject.Properties.Value) -join ' ')
    if($tumMetin -match '(?i)(asgari ucret|asgari ücret|istisna tutar|had{1,2}i|beyan sinir|beyan sınır|tavan tutar|maktu|yeniden degerleme oran|yeniden değerleme oran|fatura duzenleme sinir|fatura düzenleme sınır|defter tutma had)' -and $tumMetin -match '(TL|lira)'){
      $rapor.Add("RET (yil-degisen kanuni tutar): $konu"); continue }
    # KAPI 3: ambar teyidi
    $at = AmbarTeyit $s.kaynak
    if($at -eq 'yok'){ $rapor.Add("RET (ambar: kaynak yok): $($s.kaynak)"); continue }
    # KAPI 1+2: iki bagimsiz cozucu (cevapsiz soruyu cozer)
    $cIstem = "Su coktan secmeli soruyu coz. SADECE JSON: {`"cevap`":`"A-E arasi tek harf`"}`nSORU: $($s.soru)`nA) $($s.siklar.A)`nB) $($s.siklar.B)`nC) $($s.siklar.C)`nD) $($s.siklar.D)`nE) $($s.siklar.E)"
    $ok=$true
    foreach($t in 1,2){
      $cv=$null; try{ $cv=((JsonBul (Claude $cIstem 200 $MODEL_COZ)) | ConvertFrom-Json).cevap }catch{}
      if("$cv".Trim().ToUpper() -ne "$($s.dogru)".Trim().ToUpper()){ $ok=$false; $rapor.Add("RET (cozucu$t '$cv' != '$($s.dogru)'): $($s.soru.Substring(0,[Math]::Min(40,$s.soru.Length)))"); break }
    }
    if(-not $ok){ continue }
    $yeniListe.Add([pscustomobject]@{ id=[guid]::NewGuid().ToString().Substring(0,8); sinav=$sinavAd; ders=$ders; konu=$konu;
      soru=$s.soru; siklar=$s.siklar; dogru=$s.dogru; aciklama=$s.aciklama; kaynak=$s.kaynak; hap="$($s.hap)"; yevmiye=$s.yevmiye; ambar=$at;
      uretim=(Get-Date -Format "dd.MM.yyyy"); durum="onay-bekliyor" })
    $mevcutKokler += $kokOzet
    $rapor.Add("GECTI: [$konu] $($s.soru.Substring(0,[Math]::Min(50,$s.soru.Length)))...")
  }
}

$banka.sorular = $yeniListe.ToArray()
$banka.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
# son kosu raporu dosyaya da yazilir — log okunamayan ortamda 0-uretim teshisi icin
$banka | Add-Member -NotePropertyName sonKosuRaporu -NotePropertyValue @($rapor | Select-Object -Last 40) -Force
[IO.File]::WriteAllText($bankaYol, ($banka | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host "--- RAPOR ---"; $rapor | ForEach-Object { Write-Host "  $_" }
Write-Host ("BANKA: toplam {0} soru (onay bekleyen dahil)." -f @($banka.sorular).Count)
exit 0
