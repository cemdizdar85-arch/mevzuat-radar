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
$KONU_LIMIT = 3
$ADET = 5
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

$analizYol = Join-Path $kok "veri/sgs-analiz.json"
if(-not (Test-Path $analizYol)){ Write-Host "sgs-analiz.json yok - ONCE Sinav Analizi calistir."; exit 0 }
$analiz = Get-Content $analizYol -Raw -Encoding UTF8 | ConvertFrom-Json
if(-not $analiz.donemler -or -not @($analiz.donemler).Count){ Write-Host "Harita bos - once Sinav Analizi."; exit 0 }

$bankaYol = Join-Path $kok "veri/soru-bankasi-onay.json"
$banka = if(Test-Path $bankaYol){ Get-Content $bankaYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; sorular=@() } }

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

# HARITA: en cok soru getiren konular (mevcut bankada az temsil edilenler oncelikli)
$konular=@{}
foreach($dn in $analiz.donemler){ foreach($p in $dn.konuSayim.PSObject.Properties){ $konular[$p.Name]=[int]$konular[$p.Name]+[int]$p.Value } }
$bankaSay=@{}
foreach($s in @($banka.sorular)){ $kk="$($s.ders)|$($s.konu)"; $bankaSay[$kk]=1+[int]$bankaSay[$kk] }
$hedefler = $konular.GetEnumerator() | Sort-Object { -($_.Value) } | Where-Object { [int]$bankaSay[$_.Key] -lt 10 } | Select-Object -First $KONU_LIMIT
if(-not $hedefler){ Write-Host "Tum agir konularda 10+ soru var - banka doygun."; exit 0 }

$mevcutKokler = @($banka.sorular) | ForEach-Object { (Fold $_.soru).Substring(0, [Math]::Min(60, (Fold $_.soru).Length)) }
$yeniListe = New-Object System.Collections.Generic.List[object]
if($banka.sorular){ $yeniListe.AddRange(@($banka.sorular)) }
$rapor = New-Object System.Collections.Generic.List[string]

foreach($h in $hedefler){
  $parca = $h.Key -split '\|'; $ders=$parca[0]; $konu=$parca[1]
  Write-Host ("=== {0} / {1} (haritada {2} soru getirmis) icin {3} ozgun soru uretiliyor..." -f $ders,$konu,$h.Value,$ADET)
  $uIstem = @"
Sen TESMER Staja Giris Sinavi (SGS) tarzinda OZGUN coktan secmeli soru yazan uzman bir egitimcisin. Ders: $ders · Konu: $konu
$ADET adet ORTA-ZOR seviye, birbirinden farkli soru yaz. CIKMIS SORU KOPYALAMA - tamamen ozgun kurgular.
KURALLAR:
1) 5 sik (A-E), TEK dogru cevap; celdirici siklar tipik ogrenci hatalarindan kurulsun.
2) aciklama alaninda HER sikkin neden dogru/yanlis oldugunu 1-2 cumleyle yaz (UWorld tarzi mini ders).
3) kaynak alanina dayandigi SPESIFIK kanun maddesini yaz (or. VUK m.323, TTK m.68). Madde uyduramazsin.
4) Yila gore degisen TUTAR sorma (asgari ucret kac TL gibi) - oran, sure, ilke, hesap mantigi sor.
5) Sade, kitapcik Turkcesiyle.
SADECE su JSON dizisini dondur:
[{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"kaynak":"..."}]
"@
  $ham = Claude $uIstem 8000 $MODEL_URET
  $js = JsonBul $ham; if(-not $js){ $rapor.Add("URETIM HATASI: $konu"); continue }
  $uretilen = @(); try{ $uretilen = $js | ConvertFrom-Json }catch{ $rapor.Add("JSON HATASI: $konu"); continue }

  foreach($s in @($uretilen)){
    $kokOzet = (Fold $s.soru); $kokOzet = $kokOzet.Substring(0,[Math]::Min(60,$kokOzet.Length))
    # KAPI 5: kok tekrari
    if($mevcutKokler -contains $kokOzet){ $rapor.Add("RET (tekrar): $($s.soru.Substring(0,[Math]::Min(40,$s.soru.Length)))"); continue }
    # KAPI 4: yil-degisen tutar
    if($s.soru -match '\d[\d\.\,]*\s*(TL|lira)' -or ($s.siklar.PSObject.Properties.Value -join ' ') -match 'TL'){
      if($s.soru -notmatch '(?i)(varsayalim|kabul edin|X isletmesi|ornekte)'){ $rapor.Add("RET (TL tutari): $konu"); continue } }
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
    $yeniListe.Add([pscustomobject]@{ id=[guid]::NewGuid().ToString().Substring(0,8); sinav="SGS"; ders=$ders; konu=$konu;
      soru=$s.soru; siklar=$s.siklar; dogru=$s.dogru; aciklama=$s.aciklama; kaynak=$s.kaynak; ambar=$at;
      uretim=(Get-Date -Format "dd.MM.yyyy"); durum="onay-bekliyor" })
    $mevcutKokler += $kokOzet
    $rapor.Add("GECTI: [$konu] $($s.soru.Substring(0,[Math]::Min(50,$s.soru.Length)))...")
  }
}

$banka.sorular = $yeniListe.ToArray()
$banka.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
[IO.File]::WriteAllText($bankaYol, ($banka | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host "--- RAPOR ---"; $rapor | ForEach-Object { Write-Host "  $_" }
Write-Host ("BANKA: toplam {0} soru (onay bekleyen dahil)." -f @($banka.sorular).Count)
exit 0
