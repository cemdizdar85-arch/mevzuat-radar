# ============================================================================
#  DAYANAK HAKEM TURU — "buldu" ne kadarinda "DOGRU"?
#
#  NEDEN VAR (10.09.2026). Konu getirme karnesi sunu olctu: soru fabrikasinin
#  MADDESIZ deyip atladigi 278 konunun 276'sina madde_ara bir cevap veriyor
#  (%99,3). Karne bilerek DOGRULUK OLCMEDI - "buldu" demek "isabet etti"
#  demek degildir ve bu ayrim 03.09'da bir kez kaybedilmisti (dayanak ad
#  koprusu: dayanaklarin %20,8'i yanlisti, cunku "bulundu" ile "dogru"
#  karistirilmisti).
#
#  Ayni karne miknatisi da olctu: 276 cevabin yalniz 114'u tekil belge ve
#  TEK BELGE 110 konuya cevap oluyor (SPK Teblig Seri: X, No: 22 - bolunmemis
#  43.516 karakterlik [giris] parcasi). Bu yuzden orneklem KATMANLI:
#      15 konu: ilk sonucu MIKNATIS belgelerden biri
#      15 konu: ilk sonucu miknatis DISI
#  Tek katman olculseydi sonuc ya kotumser (yalniz miknatis) ya iyimser
#  (yalniz digerleri) cikardi. Iki katman ayri raporlanir ve BIRLESTIRILMEZ.
#
#  HAKEM NE SORAR: "bu konuda soru yazmak icin bu dayanak metin yeterli mi?"
#  Uc cevap: UYGUN / KISMEN / ALAKASIZ. Hakemden GEREKCE de istenir, cunku
#  gerekcesiz karar denetlenemez.
#
#  PARA. Bu betik PARA HARCAR - tek parali adim hakem cagrisidir.
#  Olculen tahmin: 30 konu x (~2.000 jeton giris + ~150 jeton cikis)
#  claude-sonnet-5 ile ~0,17 USD. Cem'e verilen tavan 0,4 USD idi.
#  ONCE UCUZ PROVA: -Kac 2 ile kos (~0,01 USD), ciktiyi gor, sonra tam tur.
#  Model secimi: uretim modeli degil HAKEM modeli - sonnet-5 bu is icin
#  yeterli ve depodaki hakem geleneginde (haiku/sonnet) duruyor.
#
#  CIKTI: veri/dayanak-hakem-turu.json
#  KOSMA: powershell -NoProfile -File arac/dayanak-hakem-turu.ps1 -Kac 2
#         powershell -NoProfile -File arac/dayanak-hakem-turu.ps1
# ============================================================================
param(
  [int]$Kac = 0,                       # 0 = katman basina $KatmanBoy; >0 = toplam bu kadar (ucuz prova)
  [int]$KatmanBoy = 15,
  [string]$Model = 'claude-sonnet-5',
  [int]$FrenMs = 1200
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$SKEY= if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$SH  = @{ apikey = $SKEY; Authorization = "Bearer $SKEY" }
$AKEY= $env:ANTHROPIC_API_KEY
if(-not $AKEY){ Write-Host 'KOR: ANTHROPIC_API_KEY yok - hakem turu kosulamaz (0 USD harcandi).'; exit 3 }
$AH  = @{ 'x-api-key'=$AKEY; 'anthropic-version'='2023-06-01' }
$girdi = Join-Path $kok 'veri\konu-getirme-karnesi.json'
$hedef = Join-Path $kok 'veri\dayanak-hakem-turu.json'
. (Join-Path $kok 'arac\rapor-yaz.ps1')

if(-not (Test-Path $girdi)){ Write-Host 'KOR: veri/konu-getirme-karnesi.json yok.'; exit 3 }
$karne = Get-Content $girdi -Raw -Encoding UTF8 | ConvertFrom-Json
$satirlar = @($karne.satirlar)

# --- miknatis belgeleri karneden TURET (elle liste yazilmaz: ambar degisince
#     liste bayatlar, turetilen esik bayatlamaz) -------------------------------
$ilkler = @($satirlar | ForEach-Object { if($_.'ders+konu_ilk'){ $_.'ders+konu_ilk' } elseif($_.konu_ilk){ $_.konu_ilk } } | Where-Object { $_ })
$miknatis = @($ilkler | Group-Object | Where-Object { $_.Count -ge 5 } | ForEach-Object { $_.Name })
Write-Host ("Miknatis belge (>=5 konuya cevap olan): {0}" -f $miknatis.Count)

function IlkAd($s){ if($s.'ders+konu_ilk'){ $s.'ders+konu_ilk' } elseif($s.konu_ilk){ $s.konu_ilk } else { '' } }
$katA = @($satirlar | Where-Object { (IlkAd $_) -and $miknatis -contains (IlkAd $_) })
$katB = @($satirlar | Where-Object { (IlkAd $_) -and $miknatis -notcontains (IlkAd $_) })
Write-Host ("  katman A (miknatisa cakilan): {0} konu" -f $katA.Count)
Write-Host ("  katman B (miknatis disi)    : {0} konu" -f $katB.Count)

# Orneklem: id yerine SIRALI ADIMLA (her N'inci) - basa yigilmayi onler,
# rastgele tohum kullanmadigimiz icin de tekrar kosulabilir olur.
function Ornekle($liste,[int]$n){
  $liste = @($liste); if($liste.Count -le $n){ return $liste }
  $adim = [math]::Floor($liste.Count / $n); $c=@()
  for($i=0; $i -lt $n; $i++){ $c += $liste[$i*$adim] }
  return $c
}
if($Kac -gt 0){ $boyA = [math]::Ceiling($Kac/2); $boyB = $Kac - $boyA } else { $boyA = $KatmanBoy; $boyB = $KatmanBoy }
$sec = @()
$sec += @(Ornekle $katA $boyA | ForEach-Object { $_ | Add-Member -NotePropertyName katman -NotePropertyValue 'A-miknatis' -PassThru -Force })
$sec += @(Ornekle $katB $boyB | ForEach-Object { $_ | Add-Member -NotePropertyName katman -NotePropertyValue 'B-diger'   -PassThru -Force })
Write-Host ("Hakeme gidecek: {0} konu ({1} + {2})" -f $sec.Count,$boyA,$boyB)

$script:son = [datetime]::MinValue
function Fren { $g=([datetime]::UtcNow-$script:son).TotalMilliseconds; if($g -lt $FrenMs){ Start-Sleep -Milliseconds ([int]($FrenMs-$g)) }; $script:son=[datetime]::UtcNow }

function MaddeGetir([string]$sorgu){
  $b = @{ sorgu=$sorgu; adet=1 } | ConvertTo-Json -Compress
  foreach($d in 1..3){
    Fren
    try {
      $r = Invoke-WebRequest -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers $SH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($b)) -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 60
      $j = @($r.Content | ConvertFrom-Json | ForEach-Object { $_ })
      if($j.Count -eq 0){ return $null }
      return $j[0]
    } catch { if($d -eq 3){ return $null }; Start-Sleep -Seconds (2*$d) }
  }
}

$gG=0; $gC=0
function Hakem([string]$konu,[string]$ders,[string]$ad,[string]$metin){
  # Dayanak metni KIRPILIR: hakem "bu metin bu konuyu kapsiyor mu" sorusuna
  # bakiyor, tam metni okumasi gerekmiyor. 4.000 karakter ~1.300 jeton.
  # Kirpildigi hakeme SOYLENIR - yoksa "eksik" diye ALAKASIZ oyu verebilir.
  $kirp = $false
  if($metin.Length -gt 4000){ $metin = $metin.Substring(0,4000); $kirp = $true }
  $istem = @"
Sen bir Turk mevzuat editorusun. Bir SINAV SORUSU yazilacak; asagida konu ve
o konu icin ARAMA MOTORUNUN getirdigi dayanak metin var. Tek isin, bu dayanak
metnin O KONUDA soru yazmak icin kullanilabilir olup olmadigini soylemek.

DERS: $ders
KONU: $konu

=== DAYANAK METIN ($ad) ===
$metin
=== METIN BITTI ===
$(if($kirp){ "NOT: metin uzun oldugu icin ilk 4.000 karakteri gosterildi. Gordugun kismi degerlendir; gormedigin kisimda konu gecebilir - bu ihtimali KISMEN olarak isaretle, ALAKASIZ deme." })

UC KARARDAN BIRINI VER:
UYGUN    : metin konuyu dogrudan duzenliyor, bu metne dayali soru yazilabilir.
KISMEN   : konuya deginiyor ama soru yazacak kadar hukum icermiyor, ya da konu
           metnin gorulmeyen kisminda olabilir.
ALAKASIZ : metin bu konuyla ilgili degil.

YALNIZCA su JSON'u dondur, baska hicbir sey yazma:
{"karar":"UYGUN|KISMEN|ALAKASIZ","gerekce":"<en fazla 25 kelime, metinden somut dayanakla>"}
"@
  $govde = @{ model=$Model; max_tokens=300; messages=@(@{ role='user'; content=$istem }) } | ConvertTo-Json -Depth 6
  foreach($d in 1..3){
    Fren
    try {
      # TURKCE HARF TUZAGI (10.09 olculdu): PS 5.1'de Invoke-RestMethod, yanit
      # basliginda charset yoksa govdeyi Latin-1 cozuyor -> "aracÄ± kurumlarÄ±n".
      # Kararlar ASCII oldugu icin sayilar dogru cikiyor ama GEREKCELER cop
      # oluyor; gerekcesiz karar da denetlenemez. Bayti kendimiz cozuyoruz.
      $ham = Invoke-WebRequest -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $AH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 120
      $r = [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray()) | ConvertFrom-Json
      $script:gG += [int]$r.usage.input_tokens; $script:gC += [int]$r.usage.output_tokens
      $t = "$($r.content[0].text)".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
      try { return ($t | ConvertFrom-Json) } catch { return [pscustomobject]@{ karar='COZULEMEDI'; gerekce=$t.Substring(0,[Math]::Min(120,$t.Length)) } }
    } catch {
      $g=''; try{ $rp=$_.Exception.Response; if($rp){ $sr=New-Object IO.StreamReader($rp.GetResponseStream()); $g=$sr.ReadToEnd() } }catch{}
      # Bakiye hatasi tekrar denenmez - her deneme ayni duvara carpar.
      if("$g" -match '(?i)credit balance'){ throw "BAKIYE DUSTU: $g" }
      if($d -eq 3){ return [pscustomobject]@{ karar='HATA'; gerekce=$_.Exception.Message } }
      Start-Sleep -Seconds (3*$d)
    }
  }
}

$sonuc = New-Object System.Collections.ArrayList
$i=0
foreach($s in $sec){
  $i++
  $sorgu = "$($s.ders) $($s.konu)"
  $d = MaddeGetir $sorgu
  if(-not $d){ [void]$sonuc.Add([pscustomobject]@{ katman=$s.katman; ders=$s.ders; konu=$s.konu; ad=''; karar='GETIRILEMEDI'; gerekce='madde_ara bos/dustu' }); continue }
  $h = Hakem $s.konu $s.ders "$($d.kaynak_ad)" "$($d.metin)"
  [void]$sonuc.Add([pscustomobject]@{ katman=$s.katman; ders=$s.ders; konu=$s.konu; ad="$($d.kaynak_ad)"; uzunluk="$($d.metin)".Length; karar="$($h.karar)"; gerekce="$($h.gerekce)" })
  Write-Host ("  [{0}/{1}] {2,-11} {3,-9} {4}" -f $i,$sec.Count,$s.katman,"$($h.karar)",$s.konu)
}

function Karne($liste){
  $l=@($liste); $t=$l.Count
  if($t -eq 0){ return [ordered]@{ konu=0 } }
  [ordered]@{
    konu     = $t
    UYGUN    = @($l|Where-Object{$_.karar -eq 'UYGUN'}).Count
    KISMEN   = @($l|Where-Object{$_.karar -eq 'KISMEN'}).Count
    ALAKASIZ = @($l|Where-Object{$_.karar -eq 'ALAKASIZ'}).Count
    diger    = @($l|Where-Object{$_.karar -notin @('UYGUN','KISMEN','ALAKASIZ')}).Count
    uygun_yuzde = [math]::Round(100*(@($l|Where-Object{$_.karar -eq 'UYGUN'}).Count)/$t,1)
  }
}
# Sonnet 5 liste fiyati: giris 2 USD/M, cikis 10 USD/M (Batch DEGIL - bu tur
# tek tek cagri). Rakam degisirse BURASI da degisir.
$usd = ($gG/1e6)*2.0 + ($gC/1e6)*10.0

$cikti = [ordered]@{
  olcum   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama= 'madde_ara"nin getirdigi dayanak, o konuda soru yazmaya UYGUN mu? Iki katman AYRI okunur, birlestirilmez.'
  model   = $Model
  fatura  = [ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($usd,4); not='claude-sonnet-5 liste fiyati (giris 2 / cikis 10 USD-M), batch degil' }
  miknatis_belge = $miknatis
  katman_A_miknatis = (Karne @($sonuc|Where-Object{$_.katman -eq 'A-miknatis'}))
  katman_B_diger    = (Karne @($sonuc|Where-Object{$_.katman -eq 'B-diger'}))
  satirlar = @($sonuc)
}
$yazildi = RaporYaz -Hedef $hedef -Nesne $cikti -ZamanAlanlari @('olcum')

Write-Host ''
Write-Host ("KATMAN A (miknatis) : UYGUN {0}/{1} = %{2}" -f $cikti.katman_A_miknatis.UYGUN,$cikti.katman_A_miknatis.konu,$cikti.katman_A_miknatis.uygun_yuzde)
Write-Host ("KATMAN B (diger)    : UYGUN {0}/{1} = %{2}" -f $cikti.katman_B_diger.UYGUN,$cikti.katman_B_diger.konu,$cikti.katman_B_diger.uygun_yuzde)
Write-Host ("GERCEK FATURA: {0:N4} USD  (giris {1:N0} / cikis {2:N0} jeton)" -f $usd,$gG,$gC)
if($yazildi){ Write-Host '  -> veri/dayanak-hakem-turu.json yazildi' } else { Write-Host '  -> icerik ayni, dosyaya dokunulmadi' }
