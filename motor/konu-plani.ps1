#requires -Version 5.1
<#
================================================================================
  KONU PLANI — SGS  (11.09.2026)
  Cem: "bizdeki hazır sorular, sınavda çıkmış sorular, kaç soru çıkıyor, bizim
  ürettiğimiz — çalışması yap; eksik konularda soru basalım; ders ders altında
  konu olarak karar verelim ne basacağımıza; fazla fazla soru çıkaralım"

  URETIM PLANI (motor/uretim-plani.ps1) DERS duzeyindeydi: "Meslek Hukuku'nda
  33 soru acik". Bu betik KONU duzeyine iner: "Meslek Hukuku'nun HANGI
  konusunda kac soru basacagiz" sorusunu cevaplar.

  NE OLCER (hicbir rakam elle yazilmaz):
    1) Sinavda hangi konudan kac soru cikmis   -> veri/fabrika/konu-koprusu.json
       (`cikmis` = cikmis arsivde o konudan kac soru; `donem` = kac donemde)
    2) O konudan BIZDE kac saglam soru var     -> veri/fabrika/kalip-parti-*.json
       (tum kapilardan gecmis; yayinda olan + rafta duran ayri sayilir)
    3) Ders agirligi                           -> veri/ders-profili.json
    4) Konu basina HEDEF ve ACIK

  HEDEF KURALI (Cem "fazla fazla"): bir konu cikmis arsivde N kez gorulduyse
  hedef = max($TabanHedef, N x $Kat). Boylece cok cikan konudan cok soru
  basariz; hic cikmamis konuya soru basmayiz.
  ⛔ Cikmis arsivde HIC gorulmemis konu (`cikmis`=0) plana GIRMEZ. 6.573 boyle
  konu var; hepsine soru basmak parayi sinavda cikmayan yere gomer.

  ⚠ KONU ADI ESLESMESI Turkce KATLANARAK yapilir. 05.09 dersi: kopru adlari
  ASCII ("sapmasi"), konu dosyasi Turkce ("sapması") -> eslesmiyor, konu
  sentezleniyor ve donem 1'e dusuyordu.

  BEDEL 0 — yalniz yerel dosya okur.
================================================================================
#>
param(
  [int]$TabanHedef = 2,      # cikmis arsivde gorulen her konudan en az kac soru
  [double]$Kat     = 1.5,    # cikmis sayisinin kac kati hedeflenir
  [int]$KonuTavan  = 12,     # tek konudan en fazla kac soru (para dagilsin)
  [int]$EnAzCikmis = 1       # bu sayidan az cikan konu plana girmez
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

function Katla([string]$s){
  $x="$s".Trim().ToLowerInvariant()
  foreach($c in @(@('ç','c'),@('ğ','g'),@('ı','i'),@('İ','i'),@('ö','o'),@('ş','s'),@('ü','u'),@('â','a'),@('î','i'),@('û','u'))){ $x=$x.Replace($c[0],$c[1]) }
  return ($x -replace '[^a-z0-9]+',' ').Trim()
}

# --- 1) DERS AGIRLIKLARI ------------------------------------------------------
$prof=Get-Content (Join-Path $depoKok 'veri\ders-profili.json') -Raw -Encoding UTF8|ConvertFrom-Json
$agirlik=@{}
foreach($p in $prof.sinavlar.'STAJA BAŞLAMA (SGS)'.PSObject.Properties){ $agirlik[(Katla $p.Name)]=[int]$p.Value.soru_sayisi }

# --- 2) CIKMIS ARSIV: KONU x SIKLIK -------------------------------------------
# ⚠ PS 5.1: once degiskene, sonra @() (ConvertFrom-Json boru hattina enumerate etmez)
$kopruHam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8|ConvertFrom-Json
$konu=@{}   # katlanmis konu adi -> kayit
foreach($r in @($kopruHam)){
  if("$($r.sinav)" -ne 'SGS'){ continue }
  $c=[int]$r.cikmis
  if($c -lt $EnAzCikmis){ continue }            # sinavda hic cikmamis konu plana girmez
  $ka=Katla "$($r.konu)"
  if(-not $ka){ continue }
  # 11.09: yalniz `bizim_ders`e bakinca konularin %63'u "(ders yok)" cikti —
  # kopruce "BOSLUK" damgali kayitlarda bizim_ders BOS, ama `arsiv_ders` dolu
  # (kaba ad: Muhasebe / Hukuk / Genel Kultur...). Kaba ad, hic ders olmamasindan
  # iyidir: plan okunabilir kalir ve ayristirma isi GORUNUR olur.
  $d="$($r.bizim_ders)".Trim()
  if(-not $d){
    $ad="$($r.arsiv_ders)".Trim() -replace '\s*/\s*.*$',''   # "X / Y" ikili adin ilki
    if($ad){ $d="$ad (ayristirilmamis)" }
  }
  if($konu.ContainsKey($ka)){
    if($c -gt [int]$konu[$ka].cikmis){ $konu[$ka].cikmis=$c; $konu[$ka].donem=[int]$r.donem }
    if(-not $konu[$ka].ders -and $d){ $konu[$ka].ders=$d }
    continue
  }
  $konu[$ka]=[pscustomobject]@{ ad="$($r.konu)"; ders=$d; cikmis=$c; donem=[int]$r.donem; bizde=0; yayinda=0; rafta=0 }
}

# --- 3) BIZDEKI SAGLAM SORULAR: KONU x ADET -----------------------------------
$secimHam=Get-Content (Join-Path $depoKok 'veri\sinav\kaydir-secim\sgs-650-secim.json') -Raw -Encoding UTF8|ConvertFrom-Json
$havuz=@{}; foreach($r in @($secimHam)){ $havuz["$($r.etiket)|$($r.id)"]=$true }

function KapilardanGecti($v){
  if(-not ($v -and $v.soru)){ return $false }
  if(-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')){ return $false }
  if("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ return $false }
  if(-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ return $false }
  if(-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ return $false }
  foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ return $false } }
  return $true
}
$eslesmeyen=@{}   # bizde var ama kopruce taninmayan konu (sessizce yutulmaz)
foreach($x in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  $et=($x.BaseName -replace '^kalip-parti-','')
  $c=$null; try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value
    if(-not (KapilardanGecti $v)){ continue }
    $ka=Katla "$($v.konu)"
    if(-not $konu.ContainsKey($ka)){ if($ka){ $eslesmeyen[$ka]=1+[int]$eslesmeyen[$ka] }; continue }
    $konu[$ka].bizde++
    if($havuz.ContainsKey("$et|$($p.Name)")){ $konu[$ka].yayinda++ } else { $konu[$ka].rafta++ }
  }
}

# --- 4) HEDEF ve ACIK ---------------------------------------------------------
$satir=New-Object System.Collections.Generic.List[object]
foreach($ka in $konu.Keys){
  $k=$konu[$ka]
  $hedef=[Math]::Min($KonuTavan,[Math]::Max($TabanHedef,[int][Math]::Ceiling($k.cikmis*$Kat)))
  $satir.Add([pscustomobject]@{
    ders=$(if($k.ders){ $k.ders } else { '(ders yok)' }); konu=$k.ad
    cikmis=$k.cikmis; donem=$k.donem; yayinda=$k.yayinda; rafta=$k.rafta; bizde=$k.bizde
    hedef=$hedef; acik=[Math]::Max(0,$hedef-$k.bizde)
  })
}

# --- 5) RAPOR -----------------------------------------------------------------
$dersler=@($satir | Group-Object ders | Sort-Object { $agirlik[(Katla $_.Name)] } -Descending)
$m=New-Object System.Text.StringBuilder
function Y([string]$s){ [void]$m.AppendLine($s) }
$topKonu=$satir.Count
$topBizde=0; $topAcik=0; $topAcikKonu=0
foreach($s in $satir){ $topBizde+=$s.bizde; $topAcik+=$s.acik; if($s.acik -gt 0){ $topAcikKonu++ } }

Y "# KONU PLANI — STAJA BASLAMA (SGS)"
Y ""
Y ("> Uretim: **{0}** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0." -f (Get-Date -Format 'dd.MM.yyyy HH:mm'))
Y "> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json"
Y ("> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max({0}, N x {1}), tavan {2}. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ." -f $TabanHedef,$Kat,$KonuTavan)
Y ""
Y "## 0 · TEK CUMLE"
Y ""
Y ("Cikmis SGS arsivinde gorulen **{0:N0} konu** var. Bunlarin **{1:N0}**'inde elimizde soru YETERSIZ; toplam **{2:N0} soru** basilacak. Su an bu konularda **{3:N0}** saglam sorumuz var." -f $topKonu,$topAcikKonu,$topAcik,$topBizde)
Y ""
Y "## 0b · BEDEL ve ONCELIK"
Y ""
Y "Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti)."
Y "Toplu istekle (Message Batches) bunun **yarisi** hedeflenir."
Y ""
Y "| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |"
Y "|---|---|---:|---:|---:|---:|"
foreach($esik in @(10,5,3,2,1)){
  $alt=@($satir | Where-Object { $_.acik -gt 0 -and $_.cikmis -ge $esik })
  $s2=0; foreach($z in $alt){ $s2+=$z.acik }
  $ad=switch($esik){ 10{'1 · cok kritik'} 5{'2 · kritik'} 3{'3 · onemli'} 2{'4 · orta'} 1{'5 · tamami'} }
  Y ("| {0} | cikmis >= {1} | {2:N0} | {3:N0} | {4:N0} TL | {5:N0} TL |" -f $ad,$esik,$alt.Count,$s2,($s2*13.12),($s2*6.56))
}
Y ""
Y "**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu)."
Y ""
Y "## 1 · DERS OZETI"
Y ""
Y "| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |"
Y "|---|---:|---:|---:|---:|---:|---:|"
foreach($g in $dersler){
  $b=0;$h=0;$a=0;$ak=0
  foreach($s in $g.Group){ $b+=$s.bizde; $h+=$s.hedef; $a+=$s.acik; if($s.acik -gt 0){ $ak++ } }
  $w=$agirlik[(Katla $g.Name)]; if(-not $w){ $w='—' }
  Y ("| {0} | {1} | {2:N0} | {3:N0} | {4:N0} | **{5:N0}** | {6:N0} |" -f $g.Name,$w,$g.Count,$b,$h,$a,$ak)
}
Y ("| **TOPLAM** | **130** | **{0:N0}** | **{1:N0}** | | **{2:N0}** | **{3:N0}** |" -f $topKonu,$topBizde,$topAcik,$topAcikKonu)
Y ""
Y "## 2 · DERS DERS, KONU KONU — ne basacagiz"
Y ""
Y "Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor."
Y "`ACIK` sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez."
Y ""
foreach($g in $dersler){
  $acikSatir=@($g.Group | Where-Object { $_.acik -gt 0 } | Sort-Object @{e='cikmis';d=$true},@{e='acik';d=$true})
  if(-not $acikSatir.Count){ continue }
  $toplamA=0; foreach($s in $acikSatir){ $toplamA+=$s.acik }
  Y ("### {0} — {1} konu, {2} soru basilacak" -f $g.Name,$acikSatir.Count,$toplamA)
  Y ""
  Y "| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |"
  Y "|---|---:|---:|---:|---:|---:|---:|"
  foreach($s in ($acikSatir | Select-Object -First 40)){
    Y ("| {0} | {1} | {2} | {3} | {4} | {5} | **{6}** |" -f $s.konu,$s.cikmis,$s.donem,$s.yayinda,$s.rafta,$s.hedef,$s.acik)
  }
  if($acikSatir.Count -gt 40){ Y ("| _… {0} konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |" -f ($acikSatir.Count-40)) }
  Y ""
}
if($eslesmeyen.Count){
  $eTop=0; foreach($e in $eslesmeyen.GetEnumerator()){ $eTop+=$e.Value }
  Y "## 3 · KOPRUDE KARSILIGI OLMAYAN KONULARIMIZ"
  Y ""
  Y ("Ürettigimiz sorularin **{0:N0}**'i, cikmis arsivde karsiligi olmayan **{1:N0}** konuya ait." -f $eTop,$eslesmeyen.Count)
  Y "Bu konular ya cikmis arsivde hic sorulmadi ya da konu ADI koprudekinden farkli yazildi."
  Y "Ikincisi ise olcum hatasidir — asagidaki ilk 25 ad elle gozden gecirilmeli."
  Y ""
  Y "| Konu (bizde) | Soru |"
  Y "|---|---:|"
  foreach($e in ($eslesmeyen.GetEnumerator()|Sort-Object Value -Descending|Select-Object -First 25)){ Y ("| {0} | {1} |" -f $e.Key,$e.Value) }
  Y ""
}
[IO.File]::WriteAllText((Join-Path $depoKok 'veri\KONU-PLANI-SGS.md'),$m.ToString(),(New-Object Text.UTF8Encoding $true))

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\konu-plani-sgs.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kural="Hedef = max($TabanHedef, cikmis x $Kat), tavan $KonuTavan. Cikmis arsivde gorulmemis konu plana girmez."
  cikmis_konu=$topKonu; bizde_soru=$topBizde; acik_soru=$topAcik; acik_konu=$topAcikKonu
  satirlar=@($satir | Where-Object { $_.acik -gt 0 } | Sort-Object @{e='cikmis';d=$true})
})

Write-Host ("cikmis arsivde gorulen konu : {0:N0}" -f $topKonu) -ForegroundColor Cyan
Write-Host ("bunlarda bizdeki saglam soru: {0:N0}" -f $topBizde)
Write-Host ("ACIK                        : {0:N0} soru · {1:N0} konu" -f $topAcik,$topAcikKonu) -ForegroundColor Yellow
if($eslesmeyen.Count){ $eT=0; foreach($e in $eslesmeyen.GetEnumerator()){ $eT+=$e.Value }; Write-Host ("koprude karsiligi olmayan    : {0:N0} soru / {1:N0} konu" -f $eT,$eslesmeyen.Count) -ForegroundColor DarkYellow }
Write-Host "`n-> veri/KONU-PLANI-SGS.md · veri/konu-plani-sgs.json" -ForegroundColor Green
