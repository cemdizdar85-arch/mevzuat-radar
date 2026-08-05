# ============================================================================
#  YONETMELIK AMBAR SAYIMI (05.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "yutma bitince ambar sayimini soyle."
#
#  KURAL (yutma-kapsama): "yuttum" demek yetmez - dosya depoya inmis olabilir
#  ama soru fabrikasinin okudugu yer AMBAR'dir (Supabase dokumanlar). 02.08'de
#  ~25 standart depodaydi, ambarda 0'di; fark ancak SAYIMLA gorulur.
#
#  BU BETIK: 05.08'de yutulan 6 SMMM yonetmeligi icin uc katmani birden sayar:
#    1) DEPO   : veri/mevzuat/<slug>.json var mi, kac belge tasiyor
#    2) AMBAR  : dokumanlar tablosunda kaynak_ad deseniyle kac kayit var
#    3) KARAKTER: depo->ambar metin toplami oransal tutuyor mu (kaba kapsama)
#  Sonuc her yonetmelik icin YESIL/KIRMIZI olarak raporlanir.
#
#  CIKTI: veri/yonetmelik-ambar-sayim.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/yonetmelik-ambar-sayim.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 20480){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$D  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

function AmbarSay([string]$desen){
  # kaynak_ad ilike desen; yalniz sayi (count=exact, limit=1)
  $u = "$D`?select=id&kaynak_ad=ilike.$([uri]::EscapeDataString($desen))&limit=1"
  try {
    $r = Invoke-WebRequest -Uri $u -Headers ($SB + @{ Prefer='count=exact' }) -UseBasicParsing -TimeoutSec 60
    return [int](($r.Headers['Content-Range'] -split '/')[-1])
  } catch { return -1 }
}
function AmbarKarakter([string]$desen){
  # ilk 1000 kaydin metin uzunlugu toplami (kaba kapsama gostergesi)
  $u = "$D`?select=metin&kaynak_ad=ilike.$([uri]::EscapeDataString($desen))&limit=1000"
  try {
    $h = Invoke-WebRequest -Uri $u -Headers $SB -UseBasicParsing -TimeoutSec 120
    $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
    $j = @($m | ConvertFrom-Json)
    $t = 0; foreach($x in $j){ $t += ("$($x.metin)").Length }
    return $t
  } catch { return -1 }
}

# slug -> depo dosyasi + ambar kaynak_ad deseni (manifest 'ad' alanindan)
$HEDEF = @(
  @{ slug='bd-yonetmelik';    desen='%Bagimsiz Denetim Yonetmeligi%';                 ad='Bagimsiz Denetim Yonetmeligi' }
  @{ slug='smmm-disiplin-yon';desen='%Disiplin Yonetmeligi%';                          ad='SMMM ve YMM K. Disiplin Yonetmeligi' }
  @{ slug='smmm-sinav-yon';   desen='%SMMM Sinav Yonetmeligi%';                        ad='YMM ve SMMM Sinav Yonetmeligi' }
  @{ slug='smmm-staj-yon';    desen='%Staj Yonetmeligi%';                              ad='SMMM Staj Yonetmeligi' }
  @{ slug='smmm-calisma-yon'; desen='%Calisma Usul ve Esaslari Hakkinda Yonetmelik%';  ad='SMMM ve YMM Calisma Usul ve Esaslari' }
  @{ slug='smmm-odalar-yon';  desen='%Odalari Yonetmeligi%';                           ad='SMMM Odalari Yonetmeligi' }
)

$satirlar = New-Object System.Collections.Generic.List[object]
$kirmizi = 0
foreach($h in $HEDEF){
  $dosya = Join-Path $kok ("veri/mevzuat/{0}.json" -f $h.slug)
  $depoBelge = 0; $depoKarakter = 0
  if(Test-Path $dosya){
    try {
      $j = Get-Content $dosya -Raw -Encoding UTF8 | ConvertFrom-Json
      $depoBelge = @($j.belgeler).Count
      foreach($b in @($j.belgeler)){ $depoKarakter += ("$($b.metin)").Length }
    } catch { $depoBelge = -1 }
  }
  $ambarBelge = AmbarSay $h.desen
  $ambarKarakter = if($ambarBelge -gt 0){ AmbarKarakter $h.desen } else { 0 }
  $oran = if($depoKarakter -gt 0 -and $ambarKarakter -ge 0){ [Math]::Round(100.0*$ambarKarakter/$depoKarakter,1) } else { 0 }
  # KARAR: depoda var + ambarda var + oran >= 90 -> YESIL (1000-kayit limiti
  # nedeniyle oran buyuk dosyalarda dusuk gorunebilir; belge sayisi da tutuyorsa yesil)
  $karar = if($depoBelge -le 0){ 'KIRMIZI - DEPODA YOK (yutma bitmemis?)' }
           elseif($ambarBelge -le 0){ 'KIRMIZI - AMBARDA YOK (yukleyici inmemis)' }
           elseif($oran -lt 90 -and $ambarBelge -lt $depoBelge){ "SARI - kismi (belge $ambarBelge/$depoBelge, karakter %$oran)" }
           else { 'YESIL' }
  if($karar -like 'KIRMIZI*'){ $kirmizi++ }
  $satirlar.Add([ordered]@{ slug=$h.slug; ad=$h.ad
    depo_belge=$depoBelge; depo_karakter=$depoKarakter
    ambar_belge=$ambarBelge; ambar_karakter_ilk1000=$ambarKarakter
    kapsama_yuzde=$oran; KARAR=$karar })
}
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum=$(if($kirmizi -eq 0){'TAMAM'}else{'KIRMIZI'})
  mod='AMBAR SAYIMI (0 USD, yazma yok)'
  kirmizi_sayisi=$kirmizi
  # 05.08 UTANC NOTU: burada @($satirlar) yaziyordu ve is "Argument types do
  # not match" ile coktu - DUN GECE KENDIM BELGELEDIGIM tuzak (List[object]
  # @() ile sarilmaz, .ToArray() kullanilir). Kendi yazdigim kurala kendim
  # dusmusum. Ders: bu desen artik yapisal-denetci'ye kural olarak eklenmeli.
  yonetmelikler=$satirlar.ToArray()
  not='Yutma-kapsama kurali: dosya depoda olsa bile soru fabrikasi AMBARI okur. KIRMIZI satir varsa uretime GECILMEZ. ambar_karakter ilk 1000 kayitla sinirlidir - buyuk dosyada oran dusuk gorunebilir, belge sayisina da bakilir.'
})
Write-Host "`n=== YONETMELIK AMBAR SAYIMI ==="
foreach($s in $satirlar){ Write-Host ("  {0,-18} depo={1,4}  ambar={2,4}  %{3,-6} {4}" -f $s.slug, $s.depo_belge, $s.ambar_belge, $s.kapsama_yuzde, $s.KARAR) }
if($kirmizi -gt 0){ exit 1 }

# 05.08 tetik notu: bot commitleri workflow tetiklemez (GITHUB_TOKEN kurali) -
# kurtarma bitince sayim kendiliginden kosmadi, bu push ile kosturuluyor.
