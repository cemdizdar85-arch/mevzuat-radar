# ============================================================================
#  KARDES KAYNAK CIKARIMI (03.08.2026) — 0 USD, API YOK
#
#  CEM: "bugun dun bulduklarimiza 'onu yapacaksin' deme."
#  Hakli. D23'te kardes kume listesini ELLE yazmistim (5 kume) ve "kasadaki
#  konu dagilimindan turetmek daha dogru, sirasi gelince kurarim" demistim.
#  Erteleme, plan degildir. Bu script o isi simdi yapiyor.
#
#  YONTEM: kasadaki her KONU icin, o konuya bagli sorularin KAYNAK etiketlerinden
#  kanun+madde ciftleri toplanir. Bir konu birden fazla maddeye yayiliyorsa o
#  maddeler BIRBIRININ KARDESIDIR - cunku ayni konuyu aciklarlar.
#
#  Ornek beklenen cikti: "defter tasdiki" konusu -> TTK 64 + VUK 220/221/222.
#  Elle yazdigim liste boylece OLCUMLE degisir; gozden kacan kumeler de cikar.
#
#  ESIK: bir kume icin konuda en az 4 soru ve en az 2 farkli madde olmali.
#  Tek soruluk raslanti kume sayilmaz (rakam disiplini).
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/kardes-kaynak.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/kardes-kaynak.json'
$raporYol = Join-Path $kok 'veri/kardes-kaynak-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g }))
  Write-Host ("HATA: {0}" -f $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,kaynak&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu." }

# Kaynak etiketinden KANUN + MADDE cikar: "VUK (213 s.K.) m.275", "TTK m.64/3",
# "Is K. (4857 s.K.) m.11", "TMS 16 p.61"
# 03.08 - Ilk desenim iki gercek etiketi yanlis cozuyordu (kendi testim yakaladi):
#  - "Is K. (4857 s.K.) m.11"      -> kanun HIC taninmiyordu
#  - "TMS 16 p.61"                 -> "TMS 61" cikiyordu; STANDART NUMARASI (16)
#                                     kayboluyor, paragraf numarasi kod sanildi.
# Yanlis kod = modele YANLIS kardes madde vermek demektir; duzeltildi.
$reStandart = [regex]'(?i)\b(TMS|TFRS|BDS|TSRS|KKS|SGDS)\s*(\d{1,3})\b'   # TMS 16, BDS 230
$reKisaltma = [regex]'(?i)\b(VUK|TTK|TBK|GVK|KVK|KDVK|AATUHK|SMK|MSUGT|THP)\b'
$reSayiliK  = [regex]'(?i)\((\d{4})\s*s\.?\s*K\.?\)'                      # (4857 s.K.)
$reMadde    = [regex]'(?i)\bm(?:adde)?\.?\s*(\d{1,3})'
$reParagraf = [regex]'(?i)\bp\.?\s*(\d{1,3})'
function KaynakCoz([string]$kay){
  # STANDART once: "TMS 16 p.61" -> kod 'TMS 16', birim paragraf 61
  $s = $reStandart.Match($kay)
  if($s.Success){
    $p = $reParagraf.Match($kay); if(-not $p.Success){ $p = $reMadde.Match($kay) }
    if($p.Success){ return @{ kod=($s.Groups[1].Value.ToUpperInvariant()+' '+$s.Groups[2].Value); madde=$p.Groups[1].Value } }
    return $null
  }
  $m = $reMadde.Match($kay); if(-not $m.Success){ return $null }
  $k = $reKisaltma.Match($kay)
  if($k.Success){ return @{ kod=$k.Groups[1].Value.ToUpperInvariant(); madde=$m.Groups[1].Value } }
  # Kisaltma yoksa kanun NUMARASINI kullan: "Is K. (4857 s.K.) m.11" -> 4857
  $n = $reSayiliK.Match($kay)
  if($n.Success){ return @{ kod=$n.Groups[1].Value; madde=$m.Groups[1].Value } }
  return $null
}
function Norm([string]$t){
  if($null -eq $t){ return '' }
  $x = $t.ToLowerInvariant()
  $x = $x -replace '[ıİI]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
  $x = $x -replace '[^a-z0-9 ]',' '
  return ($x -replace '\s+',' ').Trim()
}

$konuHarita = @{}   # konuAnahtari -> @{ ad; ders; sorular; maddeler=@{ 'VUK|275' = adet } }
foreach($s in $kasa){
  $konu = "$($s.konu)".Trim(); if($konu.Length -lt 3){ continue }
  $anah = Norm ("$($s.ders)|$konu")
  if(-not $konuHarita.ContainsKey($anah)){
    $konuHarita[$anah] = @{ ad=$konu; ders="$($s.ders)"; sorular=0; maddeler=@{} }
  }
  $konuHarita[$anah].sorular++
  $coz = KaynakCoz "$($s.kaynak)"
  if($null -eq $coz){ continue }
  $mAnah = "$($coz.kod)|$($coz.madde)"
  $konuHarita[$anah].maddeler[$mAnah] = 1 + $konuHarita[$anah].maddeler[$mAnah]
}

# KUME: konuda >=4 soru VE >=2 farkli madde. Maddeler siklik sirasinda, en fazla 6.
$MIN_SORU = 4; $MIN_MADDE = 2; $MAX_MADDE = 6
$kumeler = New-Object System.Collections.Generic.List[object]
foreach($anah in $konuHarita.Keys){
  $k = $konuHarita[$anah]
  if($k.sorular -lt $MIN_SORU){ continue }
  if($k.maddeler.Count -lt $MIN_MADDE){ continue }
  $sirali = @($k.maddeler.Keys | Sort-Object { -$k.maddeler[$_] } | Select-Object -First $MAX_MADDE)
  $ekler = @()
  foreach($m in $sirali){ $p = $m -split '\|'; $ekler += [ordered]@{ kod=$p[0]; madde=$p[1]; soru=$k.maddeler[$m] } }
  $kumeler.Add([ordered]@{ konu=$k.ad; ders=$k.ders; soru=$k.sorular; madde_sayisi=$k.maddeler.Count; maddeler=$ekler })
}
$sirali = @($kumeler.ToArray() | Sort-Object { -$_.soru })

$paket = [ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  yontem='Kasadaki her konu icin kaynak etiketlerinden kanun+madde ciftleri toplandi; birden fazla maddeye yayilan konularin maddeleri birbirinin kardesi sayildi.'
  esik="konuda >=$MIN_SORU soru ve >=$MIN_MADDE farkli madde"
  kume_sayisi=$sirali.Count
  kumeler=$sirali
}
Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -InputObject $paket -Depth 6) -Encoding UTF8 -NoNewline
Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  kasa=$kasa.Count; konu=$konuHarita.Count; kume=$sirali.Count
  en_buyuk_bes=@($sirali | Select-Object -First 5 | ForEach-Object { [ordered]@{ konu=$_.konu; soru=$_.soru; madde=$_.madde_sayisi } })
  not='Elle yazilan 5 kume yerine OLCUMLE cikarildi. Motor bu dosyayi okur; dosya yoksa elle liste kullanilir.' }))
Write-Host ("Konu: {0} | Kardes kume: {1} -> {2}" -f $konuHarita.Count, $sirali.Count, $ciktiYol)
foreach($x in @($sirali | Select-Object -First 8)){
  Write-Host ("  {0,-38} {1,4} soru  {2} madde" -f $x.konu, $x.soru, $x.madde_sayisi)
}
