# ============================================================================
#  TABLO FORMAT TARAMASI (03.08.2026 gece) — 0 USD, API YOK
#
#  CEM: "27 bin sorumuz var, onlarda [tabloyu] degistirecegiz demeyecegim -
#  degistirecegiz." Onarim motorunun istemi (D7_tablo) bundan sonraki
#  URETIMLER icin duzeltildi (Hesap|Borc|Alacak), ama KASADA ZATEN duran
#  "Kalem | Tutar (TL) | Isaret" formatli tablolar bundan ETKILENMEZ -
#  onlar ayrica ele alinmali.
#
#  BU ROBOT SADECE SAYAR VE ORNEK GOSTERIR - hicbir seyi degistirmez. Amac
#  Cem'in kendi kuraliyla ("yeni bir olcum kurulunca once ilk on ornegi
#  gozle oku") is buyuklugunu gormesi: kasada kac soruda eski format var,
#  ne kadari DETERMINISTIK donusturulebilir (Isaret sutunu Alacak(+)/Borc(-)
#  disinda bir sey tasimiyorsa 0 USD'ye AI'siz cevrilir), ne kadari
#  belirsiz kalip gozle bakilmasi gerekir.
#
#  CIKTI: veri/tablo-format-taramasi.json (TAM liste, id+kolonlar+ornek) ·
#  veri/tablo-format-taramasi-raporu.json (sayilar, kor kalma raporu)
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/tablo-format-taramasi.json'
$raporYol = Join-Path $kok 'veri/tablo-format-taramasi-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"
    sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber; hat_metni="$($_.InvocationInfo.Line)".Trim() }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- tum kasa cekilir, tablosu olanlar YERELDE ayiklanir (Supabase tarafi
#     filtresi "tablo=not.is.null" dogrulanmamisti - once tum satirlari cek,
#     null/bos olani burada ele, boylece PostgREST sozdizim riski sifirlanir) ---
$tumKasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,tablo&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $tumKasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa (tum): {0} soru" -f $tumKasa.Count)
$kasa = New-Object System.Collections.Generic.List[object]
foreach($x in $tumKasa){ if($null -ne $x.tablo){ $kasa.Add($x) } }
Write-Host ("Tablosu olan soru: {0}" -f $kasa.Count)

$reIsaret = [regex]'(?i)i[şs]aret'
$reBorc   = [regex]'(?i)^bor[çc]$'
$reAlacak = [regex]'(?i)^alacak$'

$eski = New-Object System.Collections.Generic.List[object]      # Isaret sutunlu - donusturme adayi
$temiz = 0                                                       # zaten Hesap|Borc|Alacak
$diger = 0                                                       # ne Isaret ne Borc/Alacak - baska tur tablo (oran vb.)
$isaretDegeri = @{}                                              # Isaret sutununda GERCEKTE ne yaziyor - saf "Alacak (+)/Borc (-)" mi
$satirHatasi = New-Object System.Collections.Generic.List[object] # 1 sorunun bozuk verisi TUM taramayi dusurmesin

foreach($s in $kasa){
  try {
    $t = $s.tablo
    if($null -eq $t){ continue }
    $ham = @($t.kolonlar)
    if($ham.Count -eq 0){ continue }
    $kolonlar = @($ham | ForEach-Object { "$_" })
    $isaretIdx = -1
    for($k=0; $k -lt $kolonlar.Count; $k++){ if($reIsaret.IsMatch($kolonlar[$k])){ $isaretIdx = $k; break } }
    if($isaretIdx -ge 0){
      # bu sorudaki Isaret sutununun TASIDIGI DEGERLERI topla - hepsi Alacak(+)/Borc(-)
      # kalibindaymi yoksa baska bir sey mi yaziyor (deterministik donusum icin sart)
      $tumSafMi = $true
      $satirlar = @($t.satirlar)
      foreach($sat in $satirlar){
        $hucreler = @($sat)
        if($isaretIdx -ge $hucreler.Count){ continue }
        $v = "$($hucreler[$isaretIdx])".Trim()
        if($v -eq ''){ continue }
        if($v -notmatch '(?i)alacak|bor[çc]'){ $tumSafMi = $false }
        if(-not $isaretDegeri.ContainsKey($v)){ $isaretDegeri[$v] = 0 }
        $isaretDegeri[$v]++
      }
      $eski.Add([ordered]@{
        id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)"
        baslik="$($t.baslik)"; kolonlar=$kolonlar
        satir_sayisi=$satirlar.Count
        deterministik_donusturulebilir=$tumSafMi
      })
      continue
    }
    $kucukKolon = @($kolonlar | ForEach-Object { $_.ToLowerInvariant() })
    if(($kucukKolon | Where-Object { $reBorc.IsMatch($_) }) -and ($kucukKolon | Where-Object { $reAlacak.IsMatch($_) })){
      $temiz++
    } else {
      $diger++
    }
  } catch {
    if($satirHatasi.Count -lt 20){ $satirHatasi.Add([ordered]@{ id="$($s.id)"; hata="$($_.Exception.Message)" }) }
  }
}

$detSayisi = @($eski | Where-Object { $_.deterministik_donusturulebilir }).Count
$belirsizSayisi = $eski.Count - $detSayisi

Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -Depth 6 -InputObject ([ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama='Isaret sutunu tasiyan (eski format) sorularin TAM listesi. deterministik_donusturulebilir=true ise Isaret sutunundaki her deger Alacak(+)/Borc(-) kalibinda - AI CAGRISI OLMADAN, 0 USD, kod ile Hesap|Borc|Alacak formatina cevrilebilir. false ise gozle bakilmali.'
  isaret_deger_dagilimi=$isaretDegeri
  sorular=@($eski)
})) -Encoding UTF8 -NoNewline

Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  tablosu_olan_soru=$kasa.Count
  eski_format_isaretli=$eski.Count
  bunun_deterministik_donusturulebilir=$detSayisi
  bunun_gozle_bakilmasi_gereken=$belirsizSayisi
  zaten_yeni_format_borc_alacak=$temiz
  diger_tablo_turu_oran_vb=$diger
  atlanan_hatali_satir=$satirHatasi.Count
  hata_ornek=@($satirHatasi)
  ilk_10_ornek=@($eski | Select-Object -First 10)
  not='Kasaya HICBIR SEY YAZILMADI - bu yalniz olcum. Tam liste veri/tablo-format-taramasi.json icinde.'
}))
Write-Host "`n=== TABLO FORMAT TARAMASI ==="
Write-Host ("  Tablosu olan soru              : {0}" -f $kasa.Count)
Write-Host ("  Eski format (Isaret sutunlu)   : {0}" -f $eski.Count)
Write-Host ("    - deterministik cevrilebilir : {0}" -f $detSayisi)
Write-Host ("    - gozle bakilmali            : {0}" -f $belirsizSayisi)
Write-Host ("  Zaten yeni format (Borc/Alacak): {0}" -f $temiz)
Write-Host ("  Diger tablo turu (oran vb.)    : {0}" -f $diger)
