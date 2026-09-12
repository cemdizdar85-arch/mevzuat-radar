# ============================================================================
#  KONU GETIRME KARNESI — "arama bulamadi" mi, "ambarda yok" mu?
#
#  NEDEN VAR (10.09.2026). Bu depoda IKI ayri arama var:
#    · Net Cevap / arama  -> madde_ara SQL fonksiyonu (v2'den v8'e 7 surum,
#                            48 vakalik altin test, cevrimdisi tarti araci)
#    · SORU FABRIKASI     -> kendi ilkel aramasi: konudan kelime cikar, 6 harfe
#                            kirp, dokumanlar.kaynak_ad uzerinde regex ara
#  soru-uret-v2.ps1 ve toplu-uret.ps1 madde_ara'yi HIC cagirmiyor. Olculen
#  bedeli: plan satirlarinin %29,4'u (4.425/15.058) maddesiz kalip ATLANIYOR.
#
#  Bu betik su tek soruyu cevaplar: FABRIKANIN BULAMADIGI konulari madde_ara
#  BULUYOR MU? Cevap "evet"se kusur ambarda degil FABRIKANIN ARAMASINDA'dir ve
#  cozum yeni veri yutmak degil, mevcut motoru fabrikaya baglamaktir.
#
#  NE OLCER, NE OLCMEZ:
#    OLCER   : madde_ara bu konu icin bir madde donduruyor mu, hangisini
#    OLCMEZ  : donen madde DOGRU MU. Dogruluk hakem isidir (parali) ve ayri
#              adimdir. Burada "buldu" demek "isabet etti" demek DEGILDIR.
#  Bu ayrimi bozma: 03.09 dayanak ad koprusu olcumu, "bulundu" ile "dogru"
#  karistirildigi icin dayanaklarin %20,8'inin yanlis oldugunu gec fark etti.
#
#  CANLIYA YAZMAZ. Yalniz okur (rpc/madde_ara + rest/dokumanlar). 0 USD - LLM
#  cagrisi YOKTUR.
#
#  CIKTI: veri/konu-getirme-karnesi.json
#  KOSMA: powershell -NoProfile -File arac/konu-getirme-karnesi.ps1
#         powershell -NoProfile -File arac/konu-getirme-karnesi.ps1 -Kac 40
# ============================================================================
param(
  [int]$Kac = 0,        # yalniz ilk N konu (0 = hepsi). Hizli deneme icin.
  [int]$Aday = 6,       # madde_ara'dan istenen sonuc adedi
  [int]$FrenMs = 1200   # 25.08 olcumu: Supabase ardisik cagri yagmurunu 500 ile keser
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok  = Split-Path -Parent $PSScriptRoot
$SB   = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY  = if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$H    = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
$girdi  = Join-Path $kok 'veri\kaynak-eksik-konular.json'
$hedef  = Join-Path $kok 'veri\konu-getirme-karnesi.json'
. (Join-Path $kok 'arac\rapor-yaz.ps1')

if(-not (Test-Path $girdi)){
  Write-Host 'KOR: veri/kaynak-eksik-konular.json yok. Once motor/kaynak-eksik-konular.ps1 kosulmali.'; exit 3
}
$kaynak = Get-Content $girdi -Raw -Encoding UTF8 | ConvertFrom-Json
$konular = @($kaynak.konular)
if($Kac -gt 0 -and $Kac -lt $konular.Count){ $konular = @($konular | Select-Object -First $Kac) }
Write-Host ("KONU GETIRME KARNESI: {0} konu olculecek (madde_ara v8, salt okuma, 0 USD)" -f $konular.Count)

# --- fren + geri cekilmeli tekrar (sirala-tarti.ps1 ile ayni desen) ---------
$script:sonCagri = [datetime]::MinValue
function Fren { $g = ([datetime]::UtcNow - $script:sonCagri).TotalMilliseconds; if($g -lt $FrenMs){ Start-Sleep -Milliseconds ([int]($FrenMs-$g)) }; $script:sonCagri = [datetime]::UtcNow }
function Cagir([scriptblock]$is,[string]$etiket){
  $son = ''
  foreach($d in 1..3){
    Fren
    try { return (& $is) }
    catch {
      $son = $_.Exception.Message
      # HATA GOVDESI TASINIR: "4 denemede de dustu" deyip sebebi yutmak kor
      # birakir (sirala-tarti.ps1'de ayni ders yazili).
      if($_.Exception.Response){
        try { $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream()); $g=$sr.ReadToEnd(); $sr.Close()
              if($g){ $son += ' || govde: ' + $g.Substring(0,[Math]::Min(200,$g.Length)) } } catch {}
      }
      if($d -eq 3){ return @{ HATA = "$etiket : $son" } }
      Start-Sleep -Seconds (2*$d)
    }
  }
}

$sonuc = New-Object System.Collections.ArrayList
$buldu = 0; $bulamadi = 0; $olculemedi = 0; $i = 0

foreach($k in $konular){
  $i++
  # Sorgu = ders + konu. Sebebi: madde_ara'nin altin testi KULLANICI SORUSU
  # seklinde ("kira artisi en fazla ne kadar"), fabrikanin girdisi ise KONU
  # BASLIGI ("tms 2 stoklar"). Ders adi eklenmesi konuyu cumleye yaklastirir.
  # Ders adinin YARDIM MI ETTIGI de olculur: iki sorgu da denenir.
  $sorgular = @(
    @{ ad='konu';       metin = "$($k.konu)" },
    @{ ad='ders+konu';  metin = "$($k.ders) $($k.konu)" }
  )
  $satir = [ordered]@{ ders=$k.ders; konu=$k.konu; kez=$k.kez }
  $herhangi = $false; $hata = ''

  foreach($s in $sorgular){
    $govde = @{ sorgu = $s.metin; adet = $Aday } | ConvertTo-Json -Compress
    $r = Cagir { Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers $H -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 } "madde_ara($($s.ad))"
    if($r -is [hashtable] -and $r.HATA){ $satir["$($s.ad)_durum"]='OLCULEMEDI'; $satir["$($s.ad)_ilk"]=''; $hata = $r.HATA; continue }
    $liste = @($r)
    if($liste.Count -gt 0){
      $satir["$($s.ad)_durum"] = 'BULDU'
      $satir["$($s.ad)_adet"]  = $liste.Count
      $satir["$($s.ad)_ilk"]   = "$($liste[0].kaynak_ad)"
      $satir["$($s.ad)_ilk3"]  = (@($liste | Select-Object -First 3 | ForEach-Object { "$($_.kaynak_ad)" }) -join ' | ')
      $herhangi = $true
    } else {
      $satir["$($s.ad)_durum"] = 'BOS'
      $satir["$($s.ad)_ilk"]   = ''
    }
  }

  if($hata -ne '' -and -not $herhangi){ $olculemedi++; $satir['hata']=$hata }
  elseif($herhangi){ $buldu++ } else { $bulamadi++ }
  [void]$sonuc.Add([pscustomobject]$satir)
  if($i % 25 -eq 0){ Write-Host ("  {0}/{1} ... buldu={2} bulamadi={3} olculemedi={4}" -f $i,$konular.Count,$buldu,$bulamadi,$olculemedi) }
}

$olculen = $buldu + $bulamadi
$cikti = [ordered]@{
  olcum    = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = 'Fabrikanin MADDESIZ deyip atladigi konulari madde_ara v8 buluyor mu? BULDU = bir madde donduruldu; DOGRU MU oldugu BURADA OLCULMEZ (hakem isi, ayri adim).'
  kaynak   = 'veri/kaynak-eksik-konular.json'
  motor    = 'rpc/madde_ara (canli surum)'
  ozet     = [ordered]@{
    olculen_konu = $olculen
    buldu        = $buldu
    bulamadi     = $bulamadi
    olculemedi   = $olculemedi
    buldu_yuzde  = $(if($olculen -gt 0){ [math]::Round(100*$buldu/$olculen,1) } else { 0 })
  }
  satirlar = @($sonuc)
}
$yazildi = RaporYaz -Hedef $hedef -Nesne $cikti -ZamanAlanlari @('olcum')

Write-Host ''
Write-Host ("KARNE: {0} konu olculdu -> BULDU {1} (%{2}) / BULAMADI {3} / OLCULEMEDI {4}" -f $olculen,$buldu,$cikti.ozet.buldu_yuzde,$bulamadi,$olculemedi)
if($olculemedi -gt 0){ Write-Host "  UYARI: olculemeyen konular var - RPC dustu, 'bulamadi' SAYILMADI (kor birakma kurali)." -ForegroundColor Yellow }
if($yazildi){ Write-Host '  -> veri/konu-getirme-karnesi.json yazildi' } else { Write-Host '  -> icerik ayni, dosyaya dokunulmadi' }
