# ============================================================================
#  VUK SINAV PROVASI — RAG hattinin ucu uca ilk gercek karnesi
#
#  NE YAPAR: bes VUK konusu icin (1) dayanagi ambardan ARAR, (2) YALNIZ o
#  dayanakla modele soru yazdirir, (3) kapilardan gecirir, (4) Cem'in
#  okuyabilecegi TEMIZ METIN olarak yazar.
#
#  NEDEN BU BETIK, NEDEN DOGRUDAN C# WORKER DEGIL:
#  C# motoru derli ve sema basili, ama canli kosmasi icin bu makinede olmayan
#  IKI kimlik gerekiyor:
#     · GEMINI_API_KEY        (gomme ucu - vektor kanali)
#     · Postgres sifresi      (Npgsql dogrudan baglanti; elimizde PostgREST
#                              anahtari var, veritabani sifresi yok)
#  Bu betik o iki kimligi GEREKTIRMEDEN ayni hatti kosar: istem blogu, JSON
#  semasi ve kapilar SoruUretici.cs ile BIREBIR AYNIDIR. Fark tek: dayanak
#  eski ambardan (madde_ara) gelir, yeni rag semasindan degil.
#  Kimlikler gelince tek fark kalkar.
#
#  PARA: tek parali adim model cagrisidir. Bes konu x ~3 soru, sonnet-5 liste
#  fiyatiyla ~0,10 USD. Fatura GERCEK jetonlardan hesaplanir ve rapora yazilir.
#
#  CIKTI: veri/vuk-sinav-provasi.txt  (okunur metin)  +  .json (ham)
#  KOSMA: powershell -NoProfile -File arac/vuk-sinav-provasi.ps1
# ============================================================================
param(
  [string]$Model = 'claude-sonnet-5',
  [int]$Adet = 3,
  [int]$FrenMs = 1500
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$SKEY= if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$SH  = @{ apikey=$SKEY; Authorization="Bearer $SKEY" }
$AKEY= $env:ANTHROPIC_API_KEY
if(-not $AKEY){ Write-Host 'KOR: ANTHROPIC_API_KEY yok (0 USD harcandi).'; exit 3 }
$AH  = @{ 'x-api-key'=$AKEY; 'anthropic-version'='2023-06-01' }

# --- bes konu: SMMM sinav mufredatindan, VUK'un farkli bolumlerinden --------
$KONULAR = @(
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='degerleme olculeri ve maliyet bedeli'; zorluk='zor'    }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='amortisman ayirma sartlari';           zorluk='zor'    }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='supheli alacak karsiligi';             zorluk='zor'    }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='vergi ziyai cezasi';                   zorluk='kolay'  }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='fatura duzenleme suresi';              zorluk='kolay'  }
)

$script:son=[datetime]::MinValue
function Fren { $g=([datetime]::UtcNow-$script:son).TotalMilliseconds; if($g -lt $FrenMs){ Start-Sleep -Milliseconds ([int]($FrenMs-$g)) }; $script:son=[datetime]::UtcNow }
function Cagir([scriptblock]$is,[int]$deneme=4){
  $son=''
  foreach($d in 1..$deneme){
    Fren
    try{ return (& $is) }
    catch{
      $son=$_.Exception.Message
      if($d -eq $deneme){ throw "$deneme denemede de dustu: $son" }
      Write-Host ("    ... deneme {0}/{1} dustu ({2}), bekleniyor" -f $d,$deneme,$son) -ForegroundColor DarkYellow
      Start-Sleep -Seconds (3*$d)
    }
  }
}

# --- 1) DAYANAK ARA --------------------------------------------------------
# madde_ara genis arar; biz VUK'a daraltiyoruz cunku sinav konusu VUK'tan.
# (Yeni motorda bu is rag.ara'nin p_kaynak_tur suzgecine denk gelir.)
function DayanakBul([string]$sorgu){
  # adet 20 -> 12: madde_ara 57014 statement timeout'una aralikli takiliyor
  # (bugun uc kez olculdu) ve genis adet o riski buyutuyor. 8 deneme + uzun
  # geri cekilme: sunucu hatasi bir CEVAP DEGILDIR, "dayanak yok" sayilmaz.
  $b = @{ sorgu=$sorgu; adet=12 } | ConvertTo-Json -Compress
  $r = Cagir { Invoke-WebRequest -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers $SH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($b)) -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180 } 8
  $j = @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json | ForEach-Object { $_ })
  # VUK KANUN maddesi onceligi; yoksa VUK genel tebligi; o da yoksa bos.
  $vukKanun = @($j | Where-Object { "$($_.kaynak_ad)" -match '^VUK \(213' })
  if($vukKanun.Count -gt 0){ return $vukKanun[0] }
  $vukHer = @($j | Where-Object { "$($_.kaynak_ad)" -match '^VUK' })
  if($vukHer.Count -gt 0){ return $vukHer[0] }
  return $null
}

# --- 2) ISTEM: SoruUretici.cs'teki KuralBlogu ile BIREBIR AYNI -------------
$KURAL = @"
Sen Turkiye'deki mali musavirlik sinavlari icin coktan secmeli soru yazan
bir editorsun. Sana bir DERS, bir KONU ve bir DAYANAK METIN verilir.

DEGISMEZ KURALLAR:
1. Soru YALNIZCA dayanak metne dayanir. Metinde YAZMAYAN hicbir rakam,
   oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin
   degilsen sayi verme.
2. Hafizandan yazma. Bildigini sandigin bir hukum metinde yoksa YOKTUR.
3. Bes sik: A, B, C, D, E. Yalniz biri dogru, digerleri savunulabilir
   bicimde yanlis olmali - sacma celdirici yazma.
4. Dogru sikkin metnini soru kokunde TEKRARLAMA (cevap sizintisi).
5. Her sik icin aciklama yaz: dogru olan neden dogru, yanlis olanlar
   neden yanlis. Aciklama da yalniz dayanak metne dayanir.
6. 'dayanak' alanina hangi hukme dayandigini tek cumleyle yaz.
7. Yapay zeka kokusu YASAK: "Bu baglamda", "onemlidir ki", "sonuc olarak"
   gibi dolgu kaliplar kullanma. Gercek bir sinav sorusu gibi yaz.
8. Konu dayanak metinde YOKSA soru uretme - bos liste dondur.
"@

$sikSema = @{ type='object'; additionalProperties=$false; required=@('A','B','C','D','E')
  properties=@{ A=@{type='string'}; B=@{type='string'}; C=@{type='string'}; D=@{type='string'}; E=@{type='string'} } }
$SEMA = @{
  type='object'; additionalProperties=$false; required=@('sorular')
  properties=@{ sorular=@{ type='array'; items=@{
    type='object'; additionalProperties=$false
    required=@('soru','siklar','dogru','aciklama','dayanak')
    properties=@{ soru=@{type='string'}; siklar=$sikSema
      dogru=@{ type='string'; enum=@('A','B','C','D','E') }
      aciklama=$sikSema; dayanak=@{type='string'} } } } }
}

$script:gG=0; $script:gC=0
function ModeliCagir($istek,$dayanak){
  $kirp=$false; $metin="$($dayanak.metin)"
  if($metin.Length -gt 6000){ $metin=$metin.Substring(0,6000); $kirp=$true }
  $kullanici = @"
DERS   : $($istek.ders)
KONU   : $($istek.konu)
ZORLUK : $($istek.zorluk)
ADET   : $Adet

=== DAYANAK METIN ($($dayanak.kaynak_ad)) ===
$metin
=== METIN BITTI ===
$(if($kirp){ "NOT: metin uzun oldugu icin ilk 6.000 karakteri gosterildi. GORMEDIGIN kisma dayali soru YAZMA." })
"@
  $govde = @{
    model=$Model; max_tokens=8000
    system=@(@{ type='text'; text=$KURAL; cache_control=@{ type='ephemeral' } })
    messages=@(@{ role='user'; content=$kullanici })
    output_config=@{ format=@{ type='json_schema'; schema=$SEMA } }
  } | ConvertTo-Json -Depth 20

  $ham = Cagir { Invoke-WebRequest -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $AH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 240 } 3
  # PS 5.1 charset tuzagi: bayti kendimiz cozuyoruz, yoksa Turkce bozulur.
  $y = [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray()) | ConvertFrom-Json
  $script:gG += [int]$y.usage.input_tokens; $script:gC += [int]$y.usage.output_tokens
  $t = ($y.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ''
  return ($t | ConvertFrom-Json)
}

# --- 3) KAPILAR: SoruUretici.Gecerli() ile BIREBIR AYNI --------------------
function Gecerli($s){
  if([string]::IsNullOrWhiteSpace("$($s.soru)")){ return 'bos soru' }
  $d="$($s.dogru)"
  if($d.Length -ne 1 -or 'ABCDE'.IndexOf($d) -lt 0){ return "gecersiz dogru sik: '$d'" }
  $siklar=@("$($s.siklar.A)","$($s.siklar.B)","$($s.siklar.C)","$($s.siklar.D)","$($s.siklar.E)")
  if(@($siklar|Where-Object{[string]::IsNullOrWhiteSpace($_)}).Count -gt 0){ return 'bos sik' }
  if(@($siklar|ForEach-Object{$_.ToLower()}|Select-Object -Unique).Count -ne 5){ return 'ikiz sik' }
  if([string]::IsNullOrWhiteSpace("$($s.dayanak)")){ return 'dayanak yazilmamis' }
  $dogruMetin = switch($d){ 'A'{$siklar[0]} 'B'{$siklar[1]} 'C'{$siklar[2]} 'D'{$siklar[3]} default{$siklar[4]} }
  if($dogruMetin.Length -gt 12 -and "$($s.soru)".ToLower().Contains($dogruMetin.ToLower())){ return 'cevap sizintisi' }
  return $null
}

# --- kos -------------------------------------------------------------------
$sonuc = New-Object System.Collections.ArrayList
foreach($k in $KONULAR){
  Write-Host ("KONU: {0}" -f $k.konu)
  $day = DayanakBul ("$($k.ders) $($k.konu)")
  if(-not $day){ Write-Host '  KAYNAKSIZ - soru URETILMEDI' -ForegroundColor Yellow
    [void]$sonuc.Add([pscustomobject]@{ konu=$k.konu; zorluk=$k.zorluk; dayanak_ad=''; sorular=@(); red=@('dayanak yok') }); continue }
  Write-Host ("  dayanak: {0}  ({1:N0} krk)" -f $day.kaynak_ad, "$($day.metin)".Length)

  $paket = ModeliCagir $k $day
  $saglam=@(); $red=@()
  foreach($s in @($paket.sorular)){
    $sebep = Gecerli $s
    if($sebep){ $red += $sebep } else { $saglam += $s }
  }
  Write-Host ("  uretilen {0} · kapida red {1}" -f $saglam.Count, $red.Count)
  [void]$sonuc.Add([pscustomobject]@{ konu=$k.konu; zorluk=$k.zorluk; dayanak_ad="$($day.kaynak_ad)"; sorular=$saglam; red=$red })
}

$usd = ($script:gG/1e6)*2.0 + ($script:gC/1e6)*10.0

# --- 4) OKUNUR METIN -------------------------------------------------------
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('  TETIKTE RAG MOTORU - VUK SINAV PROVASI')
[void]$sb.AppendLine(('  ' + (Get-Date -Format 'dd.MM.yyyy HH:mm') + '   model: ' + $Model))
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('')
$sn=0
foreach($b in $sonuc){
  [void]$sb.AppendLine('----------------------------------------------------------------')
  [void]$sb.AppendLine(('KONU    : ' + $b.konu + '   (' + $b.zorluk + ')'))
  [void]$sb.AppendLine(('DAYANAK : ' + $b.dayanak_ad))
  if($b.red.Count -gt 0){ [void]$sb.AppendLine(('KAPIDA RED: ' + ($b.red -join ', '))) }
  [void]$sb.AppendLine('----------------------------------------------------------------')
  foreach($s in @($b.sorular)){
    $sn++
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(("SORU $sn"))
    [void]$sb.AppendLine("$($s.soru)")
    [void]$sb.AppendLine('')
    foreach($h in 'A','B','C','D','E'){ [void]$sb.AppendLine(("   $h) " + $s.siklar.$h)) }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(("   DOGRU CEVAP: " + $s.dogru))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('   COZUM:')
    foreach($h in 'A','B','C','D','E'){
      $im = if($h -eq "$($s.dogru)"){ '+' } else { '-' }
      [void]$sb.AppendLine(("   $im $h) " + $s.aciklama.$h))
    }
    [void]$sb.AppendLine(('   DAYANAK: ' + $s.dayanak))
  }
  [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine(("TOPLAM SORU: $sn"))
[void]$sb.AppendLine(("FATURA     : {0:N4} USD  (giris {1:N0} / cikis {2:N0} jeton)" -f $usd,$script:gG,$script:gC))
[void]$sb.AppendLine('================================================================')

$metinYol = Join-Path $kok 'veri\vuk-sinav-provasi.txt'
[IO.File]::WriteAllText($metinYol, $sb.ToString(), [Text.UTF8Encoding]::new($true))
$jsonYol = Join-Path $kok 'veri\vuk-sinav-provasi.json'
[IO.File]::WriteAllText($jsonYol, (@{ olcum=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$Model; fatura=@{ giris=$script:gG; cikis=$script:gC; usd=[math]::Round($usd,4) }; bloklar=$sonuc } | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($true))

Write-Host ''
Write-Host ("BITTI: {0} soru · {1:N4} USD" -f $sn,$usd)
Write-Host ("  -> veri/vuk-sinav-provasi.txt")
