# ============================================================================
#  SGS SORU TIPI OLCUMU — 02.08.2026  (0 USD, yalniz indirme + pdftotext)
#  Cem onayi: "once olcelim, sonra kilitleyelim."
#
#  NEDEN: sgs-uretim-kotasi.json kendi notunda soyluyor -> "SGS kitapciklarinda
#  kurgu/uzunluk dagilimi OLCULMEDI". Yani SGS'te soru tipi agirligi (kayit /
#  bilgi / vaka / hesap) TAHMINLE konmus. Yeterlilik tarafinda olculdu
#  (kayit %40 - bilgi %35 - vaka %17 - hesap %8); SGS'te olculmedi. Kotayi
#  "son karar" diye kilitlemeden once bu bosluk kapanmali, yoksa kilitledigimiz
#  yerde olculmemis bir rakam kalir (rakam disiplini).
#
#  NE YAPAR: sinav-arsiv.json'daki SGS kitapciklarini indirir, pdftotext ile
#  metne cevirir, sorulari ayirir ve HER SORUYU ACIK KURALLA siniflandirir.
#  Yapay zeka YOK - kural var, kural raporda yaziyor, herkes denetleyebilir.
#
#  SINIFLANDIRMA SIRASI (ilk tutan kazanir; sira onemli):
#    1) KAYIT : yevmiye/muhasebe kaydi isteniyor
#    2) HESAP : rakam var + "kac TL / ne kadar / hesaplan" soruluyor
#    3) VAKA  : sirket-kisi senaryosu anlatilip hukum soruluyor
#    4) BILGI : geri kalan (tanim, kural, sayma)
#
#  KAPILAR (sessiz kayip yasak):
#    - Bir kitapciktan ayiklanan soru sayisi, arsivdeki toplamin %80'inin
#      altindaysa O KITAPCIK OLCUME ALINMAZ ve raporda "okunamadi" yazar.
#    - Bolum basligi bulunamayan kitapcik ders kirilimina katilmaz (genel
#      dagilima katilir ama isaretlenir).
#
#  Cikti: veri/sgs-tip-olcum.json
#  GEREKSINIM: pdftotext (poppler-utils). PARA HARCAMAZ.
# ============================================================================
param([int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$arsivYol = Join-Path $kok 'veri/sinav-arsiv.json'
$ciktiYol = Join-Path $kok 'veri/sgs-tip-olcum.json'

# KOR KALMA SIGORTASI (02.08): 13:00 kosusu FAILURE dondu ve iz birakmadi.
# Artik her olumcul hata rapora yazilir - "Raporu commit'le" adimi always kosar.
trap {
  [IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}
if(-not (Test-Path $arsivYol)){ Write-Host "sinav-arsiv.json yok - cikildi."; exit 1 }
$pdftotext = (Get-Command pdftotext -ErrorAction SilentlyContinue)
if(-not $pdftotext){ Write-Host "pdftotext yok (poppler-utils kurulmali) - cikildi."; exit 1 }

$arsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($arsiv.donemler | Where-Object { $_.sinav -eq 'SGS' -and $_.durum -eq 'tamam' -and "$($_.url)".Length -gt 10 })
if($sinir -gt 0){ $kayitlar = @($kayitlar | Select-Object -First $sinir) }
Write-Host ("Olculecek SGS kitapcigi: {0}" -f $kayitlar.Count)

$gecici = Join-Path ([IO.Path]::GetTempPath()) ("sgs-tip-" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $gecici -Force | Out-Null

# --- siniflandirma kurallari (raporda da yazilir)
$reKayit = [regex]'(?i)yevmiye|muhasebe kayd|kayd[ıi]n[ıi] yap|kayd[ıi] a[şs]a[ğg][ıi]dakiler|hesab[ıi]na bor[çc]|hesab[ıi]na alacak|d[öo]nem sonu kayd'
$reHesapSoru = [regex]'(?i)ka[çc]\s*(TL|lira)|ne kadar|tutar[ıi] ka[çc]|hesaplan|hesaplay|ka[çc]t[ıi]r|y[üu]zde ka[çc]|kar[ıi]\s*ka[çc]'
$reSayi = [regex]'\d{1,3}(?:\.\d{3})+|\b\d{3,}\b'
$reVakaOzne = [regex]'(?i)A\.[ŞS]\.|Ltd\.\s*[ŞS]ti|i[şs]letmesi|firmas[ıi]|[şs]irketi|m[üu]kellef'
$reVakaFiil = [regex]'(?i)m[ıi][şs]t[ıi]r|mi[şs]tir|mu[şs]tur|m[üu][şs]t[üu]r|etmi[şs]|alm[ıi][şs]|satm[ıi][şs]|d[üu]zenlemi[şs]'
$bolumler = @(
  @{ ad='Muhasebe';    re=[regex]'(?i)^\s*MUHASEBE\s*$' }
  @{ ad='Hukuk';       re=[regex]'(?i)^\s*HUKUK\s*$' }
  @{ ad='Ekonomi';     re=[regex]'(?i)^\s*(EKONOM[İI]|[İI]KT[İI]SAT)\s*$' }
  @{ ad='Maliye';      re=[regex]'(?i)^\s*MAL[İI]YE\s*$' }
  @{ ad='Matematik-Istatistik'; re=[regex]'(?i)^\s*MATEMAT[İI]K' }
  @{ ad='Yabanci Dil'; re=[regex]'(?i)^\s*(YABANCI D[İI]L|[İI]NG[İI]L[İI]ZCE)' }
  @{ ad='Genel Kultur-Genel Yetenek'; re=[regex]'(?i)^\s*GENEL (K[ÜU]LT[ÜU]R|YETENEK)' }
)

function Siniflandir([string]$m){
  if($reKayit.IsMatch($m)){ return 'kayit' }
  if($reHesapSoru.IsMatch($m) -and $reSayi.IsMatch($m)){ return 'hesap' }
  if($reVakaOzne.IsMatch($m) -and $reVakaFiil.IsMatch($m)){ return 'vaka' }
  return 'bilgi'
}

$genel = [ordered]@{ kayit=0; bilgi=0; vaka=0; hesap=0 }
$dersTip = @{}
$kitapRapor = New-Object System.Collections.Generic.List[object]
$okunan = 0; $okunamayan = 0; $toplamSoru = 0; $bolumsuz = 0

foreach($k in $kayitlar){
  $ad = "$($k.donem)"
  $pdf = Join-Path $gecici (($ad -replace '[^0-9]','_') + '.pdf')
  $txt = [IO.Path]::ChangeExtension($pdf, '.txt')
  $hata = ''
  try {
    Invoke-WebRequest -Uri "$($k.url)" -OutFile $pdf -UseBasicParsing -TimeoutSec 180
    & pdftotext -layout -enc UTF-8 $pdf $txt 2>$null | Out-Null
  } catch { $hata = $_.Exception.Message }
  if($hata -or -not (Test-Path $txt)){
    $okunamayan++
    $kitapRapor.Add([ordered]@{ donem=$ad; durum='indirilemedi/cevrilemedi'; not=$hata }); continue
  }
  $metin = Get-Content $txt -Raw -Encoding UTF8
  if([string]::IsNullOrWhiteSpace($metin)){
    $okunamayan++
    $kitapRapor.Add([ordered]@{ donem=$ad; durum='metin bos (taranmis pdf olabilir)' }); continue
  }

  # --- sorulari ayikla: "12." ile baslayan satir, numara ARTARAK gitmeli
  $satirlar = $metin -split "`r?`n"
  $sorular = New-Object System.Collections.Generic.List[object]
  $aktifNo = 0; $aktifBolum = ''; $biriken = New-Object Text.StringBuilder
  $bolumBulundu = $false
  foreach($sat in $satirlar){
    foreach($b in $bolumler){
      if($b.re.IsMatch($sat)){ $aktifBolum = $b.ad; $bolumBulundu = $true; break }
    }
    if($sat -match '^\s*(\d{1,3})[\.\)]\s+(.*)$'){
      $no = [int]$Matches[1]
      if($no -eq $aktifNo + 1){
        if($aktifNo -gt 0){ $sorular.Add([pscustomobject]@{ no=$aktifNo; bolum=$aktifBolum; metin=$biriken.ToString() }) }
        $aktifNo = $no; $biriken = New-Object Text.StringBuilder
        [void]$biriken.AppendLine($Matches[2]); continue
      }
    }
    if($aktifNo -gt 0){ [void]$biriken.AppendLine($sat) }
  }
  if($aktifNo -gt 0){ $sorular.Add([pscustomobject]@{ no=$aktifNo; bolum=$aktifBolum; metin=$biriken.ToString() }) }

  # --- KAPI: kapsama
  $beklenen = if($k.PSObject.Properties['toplamSoru'] -and [int]$k.toplamSoru -gt 0){ [int]$k.toplamSoru } else { 130 }
  $oran = if($beklenen -gt 0){ [math]::Round(100 * $sorular.Count / $beklenen, 1) } else { 0 }
  if($oran -lt 80){
    $okunamayan++
    $kitapRapor.Add([ordered]@{ donem=$ad; durum='kapsama dusuk - OLCUME ALINMADI'; ayiklanan=$sorular.Count; beklenen=$beklenen; kapsama_yuzde=$oran })
    continue
  }
  if(-not $bolumBulundu){ $bolumsuz++ }

  $kitapTip = [ordered]@{ kayit=0; bilgi=0; vaka=0; hesap=0 }
  foreach($s in $sorular){
    $t = Siniflandir "$($s.metin)"
    $genel[$t]++; $kitapTip[$t]++; $toplamSoru++
    $d = if("$($s.bolum)".Length -gt 0){ "$($s.bolum)" } else { '(bolum yok)' }
    if(-not $dersTip.ContainsKey($d)){ $dersTip[$d] = [ordered]@{ kayit=0; bilgi=0; vaka=0; hesap=0 } }
    $dersTip[$d][$t]++
  }
  $okunan++
  $kitapRapor.Add([ordered]@{ donem=$ad; durum='olculdu'; soru=$sorular.Count; beklenen=$beklenen; kapsama_yuzde=$oran; bolum_bulundu=$bolumBulundu; tip=$kitapTip })
  Write-Host ("  {0,-8} {1,4} soru (kapsama %{2})  kayit={3} bilgi={4} vaka={5} hesap={6}" -f $ad, $sorular.Count, $oran, $kitapTip.kayit, $kitapTip.bilgi, $kitapTip.vaka, $kitapTip.hesap)
}
Remove-Item $gecici -Recurse -Force -ErrorAction SilentlyContinue

if($toplamSoru -eq 0){
  # 03.08 KOR KALMA: eskiden burada json YAZILMADAN cikiliyordu - kosucu
  # FAILURE veriyor ama hangi kitapcigin neden dustugu gorulemiyordu.
  # Artik kitapcik-bazli dokum her kosulda dosyaya yazilir.
  $rapor = [ordered]@{
    tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm'); durum = 'HATA - hicbir kitapcik olculemedi'
    # 02.08 dersi: @($liste) burada "Argument types do not match" firlatiyor
    # (List[object] icinde OrderedDictionary); .ToArray() sorunsuz.
    kitapcik_dokumu = $kitapRapor.ToArray()
  }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/sgs-tip-olcum.json'), (ConvertTo-Json -InputObject $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
  Write-Host "Hicbir kitapcik olculemedi - dokum veri/sgs-tip-olcum.json'a yazildi."; exit 1
}
function Yuzde($n){ return [math]::Round(100 * $n / $toplamSoru, 1) }
$dersListe = New-Object System.Collections.Generic.List[object]
foreach($d in ($dersTip.Keys | Sort-Object)){
  $t = $dersTip[$d]
  $top = $t.kayit + $t.bilgi + $t.vaka + $t.hesap
  if($top -eq 0){ continue }
  $dersListe.Add([ordered]@{
    ders = $d; soru = $top
    kayit_yuzde = [math]::Round(100*$t.kayit/$top,1); bilgi_yuzde = [math]::Round(100*$t.bilgi/$top,1)
    vaka_yuzde  = [math]::Round(100*$t.vaka/$top,1);  hesap_yuzde = [math]::Round(100*$t.hesap/$top,1)
  })
}

$paket = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kaynak = "TESMER / arsivdeki SGS kitapciklari (sinav-arsiv.json, durum=tamam)"
  kitapcik_olculdu = $okunan
  kitapcik_olculemedi = $okunamayan
  bolum_basligi_bulunamayan_kitapcik = $bolumsuz
  olculen_soru = $toplamSoru
  genel_dagilim = [ordered]@{
    kayit_yuzde = (Yuzde $genel.kayit); bilgi_yuzde = (Yuzde $genel.bilgi)
    vaka_yuzde  = (Yuzde $genel.vaka);  hesap_yuzde = (Yuzde $genel.hesap)
  }
  ders_dagilimi = $dersListe.ToArray()
  siniflandirma_kurali = @(
    "1) KAYIT: yevmiye / muhasebe kaydi / hesaba borc-alacak ifadesi geciyorsa",
    "2) HESAP: metinde 3+ haneli sayi VAR ve 'kac TL / ne kadar / hesaplayiniz / kactir' soruluyorsa",
    "3) VAKA : sirket-kisi oznesi (A.S., Ltd. Sti., isletmesi, mukellef) VE gecmis zamanli anlatim varsa",
    "4) BILGI: yukaridakilerin hicbiri tutmuyorsa"
  )
  kapilar = @(
    "Ayiklanan soru sayisi beklenenin %80'inin altindaysa o kitapcik OLCUME ALINMADI.",
    "Bolum basligi bulunamayan kitapcik genel dagilima katilir, ders kiriliminda '(bolum yok)' altinda gorunur."
  )
  kitapciklar = $kitapRapor.ToArray()
}
$j = ConvertTo-Json -InputObject $paket -Depth 6
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $ciktiYol -Value ([string]$j) -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host ("OLCULEN: {0} kitapcik / {1} soru  (olculemeyen kitapcik: {2})" -f $okunan, $toplamSoru, $okunamayan)
Write-Host ("GENEL DAGILIM: kayit %{0} - bilgi %{1} - vaka %{2} - hesap %{3}" -f (Yuzde $genel.kayit), (Yuzde $genel.bilgi), (Yuzde $genel.vaka), (Yuzde $genel.hesap))
Write-Host "KARSILASTIRMA (Yeterlilik, olculmus): kayit %40 - bilgi %35 - vaka %17 - hesap %8"
Write-Host ("-> {0}" -f $ciktiYol)
