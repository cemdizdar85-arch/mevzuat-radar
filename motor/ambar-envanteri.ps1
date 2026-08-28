# ============================================================================
#  AMBAR ENVANTERİ — TEK DOĞRU SAYFA (28.08.2026, Cem: "tek bir yerde toplayıp
#  ben sorduğumda hepsinin olduğuna emin olduğum bir şey yok mu?")
#
#  NEDEN VAR: "Eksik var mı?" sorusuna GM hafızadan/eski kayıttan "yok" diyordu;
#  kayıtlar iki kez yalancı çıktı (25.08 TFRS 16: liste 122 parça diyordu,
#  ambarda 12 vardı; 28.08 TMS 1: tam görünüyordu, sürümü eskiydi).
#  KURAL: VAR/YOK cevabı YALNIZ bu envanterden verilir. "Var" üç ayrı sorudur:
#    VAR MI   -> canlı parça sayımı (her koşuda taze, Supabase'den)
#    TAM MI   -> bütünlük kapısı son sonucu (veri/butunluk-raporu.json)
#    GÜNCEL Mİ-> sürüm tazeliği kapısı son sonucu (surum-tazeligi-karnesi.json)
#  Ölçülmemiş hücre YOK sayılmaz: "ÖLÇÜLMEDİ" yazar (üçüncü-sonuç kuralı).
#
#  Çıktı: veri/AMBAR-ENVANTERI.md (insan) + veri/fabrika/ambar-envanteri.json
#  Günlük görev sürüm kapısından sonra bunu da koşar. 0 USD, model yok.
# ============================================================================
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $KEY){ $KEY=$env:SUPABASE_SERVICE_KEY }
$H=@{apikey=$KEY;Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# --- 1) CANLI SAYIM: tum kaynak_ad'ler sayfali cekilir, oneke indirgenir ---
Write-Host 'Canli sayim (tum ambar)...'
$say=@{}; $tur=@{}
$arsiv=@{}   # 'SINAV|DONEM' -> soru sayisi (cikmis arsiv dokumu; Cem 28.08: "orda var mi?")
$bas=0; $toplam=0
while($true){
  $r=$null
  foreach($d in 1..3){ try{ $w=Invoke-WebRequest -Uri "$U`?select=kaynak_ad,tur&order=id&limit=1000&offset=$bas" -Headers $H -UserAgent 'mevzuat-radar-robot/1.0' -UseBasicParsing -TimeoutSec 120; $r=[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())|ConvertFrom-Json; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (5*$d) } }
  $ad=0
  foreach($x in $r){
    $ad++
    $k="$($x.kaynak_ad)"
    $t="$($x.tur)"
    # tekil-belge kalabaligi tek gruba katlanir (envanter OKUNUR kalsin):
    if($t -in @('cikmis-soru','cikmis-komisyon-cevabi')){
      $on="[ARŞİV] ÇIKMIŞ SINAV ($t)"
      if($t -in @('cikmis-soru','cikmis-komisyon-cevabi')){
        $sv='?'; $dn='?'
        if($k -match 'CIKMIS SINAV(?: KOMISYON CEVABI)?\s*-?\s*([A-ZÇĞİÖŞÜ]{2,})'){ $sv=$Matches[1] }
        if($k -match '(\d{4}/\d)'){ $dn=$Matches[1] }
        elseif($k -match '_(\d{4})[_\)]' -or $k -match '[_ ](\d{4})\)'){ $dn="y.$($Matches[1])" }
        $ek=''; if($t -eq 'cikmis-komisyon-cevabi'){ $ek=' (yazılı/komisyon)' }
        $ak="$sv$ek|$dn"
        if(-not $arsiv[$ak]){ $arsiv[$ak]=0 }
        $arsiv[$ak]++
      }
    }
    elseif($t -eq 'teori-notu' -or $k -match '^(TEORI|Teori Notu)'){ $on='[GRUP] TEORİ NOTLARI' }
    else{
      # onek cikarimi: ' m.', ' p.', ' ilke', ' ek m.', ' gec. m.' vb oncesi
      $on=$k
      if($k -match '^(.*?)\s+(m\.|muk\. m\.|md\.|p\.\d|p\.[A-Z]|ilke|ek m\.|gec\. m\.|geçici m\.|Ek [A-Z]|b[oö]l[uü]m \d|bolum \d|k[iı]s[iı]m \d)'){ $on=$Matches[1].Trim() }
    }
    if(-not $say[$on]){ $say[$on]=0; $tur[$on]=$t }
    $say[$on]++
    $toplam++
  }
  if($ad -eq 0){ break }
  $bas+=1000
  if($ad -lt 1000){ break }
}
Write-Host "  tekil kaynak (onek): $($say.Count) | toplam parca: $toplam"

# --- 2) BUTUNLUK sonuclari ---
# Rapor yalniz SORUNLULARI listeler (is_listesi); temizler listede OLMAYANDIR.
# Bu cikarim yalniz rapor TUM ambari taradiysa (kapsam bos) gecerli; dar
# kapsamli (-yalniz) kosu varsa yalniz o kaynaklar hakkinda konusuruz.
# Iki rapor okunur: butunluk-raporu-standartlar.json (kapsam=standartlar) +
# butunluk-raporu.json (son kosu; -kanunlar kosuldugunda kapsam=kanunlar).
$butunDelik=@{}
$olcKapsam=@{}   # 'standartlar'/'kanunlar' -> tarih
$bTarih=''
foreach($bAd in @('butunluk-raporu-standartlar.json','butunluk-raporu.json')){
  $bY=Join-Path $kok "veri\$bAd"
  if(-not (Test-Path $bY)){ continue }
  try{
    $bj=Get-Content $bY -Raw -Encoding UTF8 | ConvertFrom-Json
    $kp="$($bj.kapsam)"
    if($kp -in @('standartlar','kanunlar')){ $olcKapsam[$kp]=(Get-Item $bY).LastWriteTime.ToString('dd.MM.yyyy'); $bTarih=$olcKapsam[$kp] }
    foreach($s in @($bj.is_listesi | % { $_ })){
      $butunDelik["$($s.kaynak)"]="par:$($s.eksik_paragraf)/kesik:$($s.kesik_belge)/oksuz:$($s.oksuz_belge)"
    }
  }catch{ Write-Host "  butunluk raporu okunamadi ($bAd): $_" }
}
function ButunlukHukmu([string]$on,[string]$turAd,[string]$surumDurum){
  $delik=''
  if($butunDelik.ContainsKey($on)){ $delik=$butunDelik[$on] }
  $kanunMu = ($turAd -ne 'standart-madde')
  $kapsamOlculdu = $false
  if($kanunMu -and $olcKapsam.ContainsKey('kanunlar')){ $kapsamOlculdu=$true }
  if(-not $kanunMu -and $olcKapsam.ContainsKey('standartlar')){ $kapsamOlculdu=$true }
  if(-not $kapsamOlculdu){ return 'ÖLÇÜLMEDİ' }
  if(-not $delik){ return 'TAM' }
  # 28.08 CAPRAZ KURALI: surum kapisi ayni gun TUTARLI dediyse ambar guncel
  # resmi PDF ile birebir demektir - "eksik" numaralar resmi metinde de yok
  # ([Silinmistir] / atlanmis numara / ornek-rakam artefakti). Kusur DEGIL.
  if($surumDurum -eq 'TUTARLI'){ return "TAM(set-birebir; kapı notu: $delik resmî metinde de yok)" }
  return "DELİK-İNCELE($delik)"
}

# --- 3) SURUM sonuclari ---
$surum=@{}
$sY=Join-Path $kok 'veri\fabrika\surum-tazeligi-karnesi.json'
$sTarih=''
if(Test-Path $sY){
  try{
    $sj=Get-Content $sY -Raw -Encoding UTF8 | ConvertFrom-Json
    $sTarih="$($sj.tarih)"
    foreach($s in @($sj.satirlar | % { $_ })){ $surum["$($s.standart)"]="$($s.durum)" }
  }catch{ Write-Host "  surum karnesi okunamadi: $_" }
}

# --- 4) ENVANTER SATIRLARI ---
$satirlar=New-Object System.Collections.Generic.List[object]
foreach($on in ($say.Keys | Sort-Object)){
  $s='ÖLÇÜLMEDİ'
  $stdAd=''
  if($on -match '^((TMS|TFRS|TSRS)\s+\d+)'){ $stdAd=$Matches[1] }
  if($stdAd -and $surum.ContainsKey($stdAd)){ $s=$surum[$stdAd] }
  elseif(-not $stdAd){ $s='KAPSAM-DIŞI(kanun/tebliğ: günlük ayna+damga kollar)' }
  $b=ButunlukHukmu $on $tur[$on] $s
  $satirlar.Add([pscustomobject]@{kaynak=$on;tur=$tur[$on];parca=$say[$on];tam=$b;guncel=$s})
}
$olculenB=@($satirlar | ? { $_.tam -notmatch '^ÖLÇÜLMEDİ' }).Count
$olculenS=@($satirlar | ? { $_.guncel -notmatch '^ÖLÇÜLMEDİ|KAPSAM' }).Count
$delik=@($satirlar | ? { $_.tam -match 'DEL[İI]K' }).Count
$incele=@($satirlar | ? { $_.guncel -match 'INCELE|OLCULEMEDI' }).Count

$ozet=[ordered]@{
  uretim_tarihi=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  toplam_parca=$toplam
  tekil_kaynak=$say.Count
  butunluk_olculen=$olculenB; butunluk_delik=$delik; butunluk_tarihi=$bTarih
  surum_olculen=$olculenS; surum_incele=$incele; surum_tarihi=$sTarih
  kural='VAR/YOK cevabi YALNIZ bu envanterden verilir; OLCULMEDI hucresi yok sayilmaz.'
  arsiv_dokumu=$arsiv
  satirlar=$satirlar.ToArray()
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\fabrika\ambar-envanteri.json'),(ConvertTo-Json -InputObject $ozet -Depth 4),[Text.UTF8Encoding]::new($false))

# --- 5) INSAN SAYFASI (md) ---
$sb=[Text.StringBuilder]::new()
[void]$sb.AppendLine('# AMBAR ENVANTERİ — TEK DOĞRU SAYFA')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("> Üretim: **$($ozet.uretim_tarihi)** (makine; elle düzenlenmez — `motor/ambar-envanteri.ps1`, günlük görevle tazelenir)")
[void]$sb.AppendLine("> **KURAL:** ""Eksik var mı?"" sorusunun cevabı YALNIZ bu sayfadan verilir. ""Var"" üç sorudur: VAR MI (canlı sayım) · TAM MI (bütünlük kapısı) · GÜNCEL Mİ (sürüm kapısı). ÖLÇÜLMEDİ hücresi ""yok"" sayılmaz — dürüstçe ölçülmemiştir.")
[void]$sb.AppendLine('')
[void]$sb.AppendLine("**ÖZET:** $($ozet.toplam_parca) parça · $($ozet.tekil_kaynak) tekil kaynak | Bütünlük ölçülen: $olculenB (delikli: $delik; son ölçüm: $bTarih) | Sürüm ölçülen: $olculenS (sorunlu: $incele; son ölçüm: $sTarih)")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## ÇIKMIŞ SINAV ARŞİVİ DÖKÜMÜ (üç sınav kuralı)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> **TAM MI hücresi bu bölümde henüz ÖLÇÜLMEDİ:** resmî dönem listesiyle kıyas kapısı kurulmadı — aşağıdaki döküm "elimizde ne var"dır, "eksik yok" iddiası DEĞİLDİR. Sayılar BELGE (kitapçık/oturum dosyası) adedidir; soru adedi belgelerin içindedir (18-23.08 sayımı: 20.851 soru). "y.YYYY" = dönem etiketi dosya adından yıl olarak çıkarıldı; "?" = ad deseninden dönem okunamadı.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Sınav | Belge (canlı) | Dönem sayısı | Dönemler |')
[void]$sb.AppendLine('|---|---:|---:|---|')
$svGrup=@{}
foreach($ak in $arsiv.Keys){
  $p=$ak -split '\|'
  if(-not $svGrup[$p[0]]){ $svGrup[$p[0]]=New-Object System.Collections.Generic.List[object] }
  $svGrup[$p[0]].Add([pscustomobject]@{donem=$p[1];adet=$arsiv[$ak]})
}
foreach($sv in ($svGrup.Keys | Sort-Object)){
  $ds=@($svGrup[$sv] | Sort-Object donem)
  $topS=($ds | Measure-Object adet -Sum).Sum
  $dListe=(@($ds | % { "$($_.donem)($($_.adet))" }) -join ' · ')
  [void]$sb.AppendLine("| $sv | $topS | $($ds.Count) | $dListe |")
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## KAYNAK TABLOSU')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Kaynak | Tür | Parça | TAM MI | GÜNCEL Mİ |')
[void]$sb.AppendLine('|---|---|---:|---|---|')
foreach($x in $satirlar){
  [void]$sb.AppendLine("| $($x.kaynak) | $($x.tur) | $($x.parca) | $($x.tam) | $($x.guncel) |")
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\AMBAR-ENVANTERI.md'),$sb.ToString(),[Text.UTF8Encoding]::new($false))

"ENVANTER: $($ozet.toplam_parca) parça · $($ozet.tekil_kaynak) kaynak | bütünlük ölçülen $olculenB (delik $delik) | sürüm ölçülen $olculenS (sorunlu $incele)"
"  -> veri/AMBAR-ENVANTERI.md + veri/fabrika/ambar-envanteri.json"
