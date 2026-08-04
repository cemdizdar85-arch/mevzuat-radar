# ============================================================================
#  KONU DAGILIM OLCUMU (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "biz hep konusurken sinavda cikan sorularda hangi konu fazla
#  soruluyorsa ondan fazla soru sor dedik - hangi konularda yigilma var?"
#
#  CEM HAKLI, BEN YANLIS ETIKETLEMISTIM: acilis olcumunde "imal edilen"
#  1.503 soru cikinca buna "konu yigilmasi" deyip KUSUR gibi sundum. Oysa
#  veri/uretim-kotasi.json 12 donem TESMER kitapcigindan OLCULMUS bir HEDEF
#  dagilim iceriyor - A-omurga 96 konu, hedefin %63'u. Yani yigilma bilerek
#  yapiliyor; asil soru "hedefe uygun mu?"dur.
#
#  BU BETIK ONU OLCER: kasadaki GERCEK konu dagilimi ile plandaki HEDEF
#  yan yana konur. Uc sinif cikar:
#    ASIRI  : hedefin cok ustunde uretilmis (emek bosa gitmis olabilir)
#    UYUMLU : hedefe yakin
#    EKSIK  : hedefin altinda (gercek bosluk - once burasi doldurulmali)
#  Ayrica PLANDA HIC OLMAYAN konular ayri sayilir (plan disi uretim).
#
#  CIKTI: veri/konu-dagilim-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/konu-dagilim-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}
# Turkce-bagimsiz anahtar (bu gecenin dersi: hashtable anahtari kulture bagli)
$HARF = @{ [char]0x0130='I';[char]0x0131='I';[char]'i'='I';[char]'I'='I'; [char]0x015E='S';[char]0x015F='S'
           [char]0x011E='G';[char]0x011F='G'; [char]0x00DC='U';[char]0x00FC='U'; [char]0x00D6='O';[char]0x00F6='O'
           [char]0x00C7='C';[char]0x00E7='C' }
function Anahtar([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}

# --- HEDEF: uretim-kotasi.json plan satirlari ---
$plan = @((Get-Content (Join-Path $kok 'veri/uretim-kotasi.json') -Raw -Encoding UTF8 | ConvertFrom-Json).plan)
$hedef = @{}   # anahtar -> @{ ders; konu; katman; adet }
foreach($p in $plan){
  $k = Anahtar "$($p.ders)|$($p.konu)"
  if(-not $hedef.ContainsKey($k)){ $hedef[$k] = [ordered]@{ ders="$($p.ders)"; konu="$($p.konu)"; katman="$($p.katman)"; adet=0 } }
  $hedef[$k].adet += [int]$p.adet
}
Write-Host ("Plan: {0} satir -> {1} tekil konu, hedef toplam {2}" -f $plan.Count, $hedef.Count, (($hedef.Values | Measure-Object -Property adet -Sum).Sum))

# --- GERCEK: kasadaki konu dagilimi ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
$gercek = @{}
foreach($s in $kasa){
  $k = Anahtar "$($s.ders)|$($s.konu)"
  if(-not $gercek.ContainsKey($k)){ $gercek[$k] = [ordered]@{ ders="$($s.ders)"; konu="$($s.konu)"; adet=0 } }
  $gercek[$k].adet++
}
Write-Host ("Kasada tekil konu: {0}" -f $gercek.Count)

# --- KARSILASTIR ---
$asiri = New-Object System.Collections.Generic.List[object]
$eksik = New-Object System.Collections.Generic.List[object]
$planDisi = New-Object System.Collections.Generic.List[object]
$uyumlu = 0
foreach($k in $gercek.Keys){
  $g = $gercek[$k].adet
  if(-not $hedef.ContainsKey($k)){
    $planDisi.Add([ordered]@{ ders=$gercek[$k].ders; konu=$gercek[$k].konu; kasada=$g })
    continue
  }
  $h = $hedef[$k].adet
  if($h -le 0){ continue }
  $kat = [Math]::Round($g / [double]$h, 1)
  if($kat -ge 2){ $asiri.Add([ordered]@{ ders=$gercek[$k].ders; konu=$gercek[$k].konu; katman=$hedef[$k].katman; hedef=$h; kasada=$g; kat=$kat }) }
  elseif($kat -lt 0.8){ $eksik.Add([ordered]@{ ders=$gercek[$k].ders; konu=$gercek[$k].konu; katman=$hedef[$k].katman; hedef=$h; kasada=$g; oran=$kat }) }
  else { $uyumlu++ }
}
# Planda olup kasada HIC olmayanlar
$hicYok = New-Object System.Collections.Generic.List[object]
foreach($k in $hedef.Keys){
  if(-not $gercek.ContainsKey($k)){ $hicYok.Add([ordered]@{ ders=$hedef[$k].ders; konu=$hedef[$k].konu; katman=$hedef[$k].katman; hedef=$hedef[$k].adet }) }
}
$asiriS = @($asiri | Sort-Object { -$_.kat })
$eksikS = @($eksik | Sort-Object { $_.oran })
$planDisiS = @($planDisi | Sort-Object { -$_.kasada })
$hicYokS = @($hicYok | Sort-Object { -$_.hedef })

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count; kasada_tekil_konu=$gercek.Count
  plan_tekil_konu=$hedef.Count; plan_hedef_toplam=(($hedef.Values | Measure-Object -Property adet -Sum).Sum)
  olcut='kat = kasada/hedef. 2 ve ustu ASIRI, 0,8 alti EKSIK, arasi UYUMLU.'
  ASIRI_konu_sayisi=$asiriS.Count
  EKSIK_konu_sayisi=$eksikS.Count
  UYUMLU_konu_sayisi=$uyumlu
  PLAN_DISI_konu_sayisi=$planDisiS.Count
  planda_var_kasada_HIC_YOK=$hicYokS.Count
  en_asiri_25=@($asiriS | Select-Object -First 25)
  en_eksik_25=@($eksikS | Select-Object -First 25)
  plan_disi_en_cok_25=@($planDisiS | Select-Object -First 25)
  hic_uretilmemis_en_onemli_25=@($hicYokS | Select-Object -First 25)
  not='Yalniz OLCUM. Hedef kaynagi: veri/uretim-kotasi.json (12 donem TESMER Yeterlilik kitapcigindan olculmus). Konu eslemesi ders+konu metnine gore yapilir; yazim farki olan konular PLAN DISI gorunebilir - o liste once gozle okunmali.'
})
Write-Host "`n=== KONU DAGILIMI: GERCEK vs HEDEF ==="
Write-Host ("  ASIRI (>=2 kat) : {0} konu" -f $asiriS.Count)
Write-Host ("  EKSIK (<0,8)    : {0} konu" -f $eksikS.Count)
Write-Host ("  UYUMLU          : {0} konu" -f $uyumlu)
Write-Host ("  PLAN DISI       : {0} konu" -f $planDisiS.Count)
Write-Host ("  HIC URETILMEMIS : {0} konu" -f $hicYokS.Count)
Write-Host "`n  --- EN ASIRI 10 ---"
$asiriS | Select-Object -First 10 | ForEach-Object { Write-Host ("    {0,5}x  hedef={1,4} kasada={2,5}  {3} / {4}" -f $_.kat,$_.hedef,$_.kasada,$_.ders,$_.konu) }
