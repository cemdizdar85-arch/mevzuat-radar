# ============================================================================
#  IKI SINAV AYRI AYRI: KONU FAZLA/EKSIK OLCUMU (05.08.2026) — 0 USD
#
#  CEM: "konulara ayri ayri sinavda cikan sorulara bak ve ona gore fazla ya
#  da eksik soru cikarmamizi bul - AYRI AYRI iki sinavi da."
#
#  ONCEKI OLCUMUN KUSURU: konu-dagilim-olcum.ps1 SINAV alanini filtrelemiyordu;
#  SGS ve SMMM sorulari karisti, SGS dersleri "plan disi" gorundu.
#
#  BU BETIK HER SINAVI KENDI PLANIYLA karsilastirir:
#    SMMM (bitirme/yeterlilik) -> veri/uretim-kotasi.json
#       (12 donem TESMER Yeterlilik kitapcigindan olculmus hedef)
#    SGS (staja giris)         -> veri/sgs-uretim-kotasi.json
#       (TESMER Uygulama Yonergesi m.6.2 agirliklari; 'siklik' alani var)
#
#  CIKTI (her sinav icin ayri):
#    ASIRI  : kasada hedefin >=2 kati
#    EKSIK  : kasada hedefin <0,8'i
#    BOS    : planda var, kasada hic yok (once GERCEK anahtar, sonra DERSE
#             BAKMADAN kelime aramasi ile dogrulanir - ad uyusmazligi sahte
#             bosluk uretmesin, bu gecenin dersi)
#
#  CIKTI: veri/iki-sinav-konu-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/iki-sinav-konu-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 7
  if($j.Length -gt 61440){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
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
$HARF = @{ [char]0x0130='I';[char]0x0131='I';[char]'i'='I';[char]'I'='I'; [char]0x015E='S';[char]0x015F='S'
           [char]0x011E='G';[char]0x011F='G'; [char]0x00DC='U';[char]0x00FC='U'; [char]0x00D6='O';[char]0x00F6='O'
           [char]0x00C7='C';[char]0x00E7='C' }
function Sade([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,sinav,ders,konu&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

function SinavAnaliz([string]$sinavAd, [string]$planYolu){
  $plan = @((Get-Content (Join-Path $kok $planYolu) -Raw -Encoding UTF8 | ConvertFrom-Json).plan)
  # hedef: ders|konu -> adet (ve derse-bakmadan konu -> adet)
  $hedef = @{}; $hedefKonu = @{}
  foreach($p in $plan){
    $k = Sade "$($p.ders)|$($p.konu)"
    if(-not $hedef.ContainsKey($k)){ $hedef[$k] = [ordered]@{ ders="$($p.ders)"; konu="$($p.konu)"; katman="$($p.katman)"; adet=0 } }
    $hedef[$k].adet += [int]$p.adet
    $kk = Sade "$($p.konu)"
    if($kk -ne ''){ if(-not $hedefKonu.ContainsKey($kk)){ $hedefKonu[$kk]=0 }; $hedefKonu[$kk] += [int]$p.adet }
  }
  # gercek: yalniz BU SINAVIN sorulari
  $gercek = @{}; $gercekKonuSade = New-Object System.Collections.Generic.List[object]
  $soruSayisi = 0
  foreach($s in $kasa){
    if("$($s.sinav)" -ne $sinavAd){ continue }
    $soruSayisi++
    $k = Sade "$($s.ders)|$($s.konu)"
    if(-not $gercek.ContainsKey($k)){ $gercek[$k] = [ordered]@{ ders="$($s.ders)"; konu="$($s.konu)"; adet=0 } }
    $gercek[$k].adet++
    $gercekKonuSade.Add((Sade "$($s.konu)"))
  }
  $asiri = New-Object System.Collections.Generic.List[object]
  $eksik = New-Object System.Collections.Generic.List[object]
  $uyumlu = 0
  foreach($k in $gercek.Keys){
    if(-not $hedef.ContainsKey($k)){ continue }
    $g = $gercek[$k].adet; $h = $hedef[$k].adet
    if($h -le 0){ continue }
    $kat = [Math]::Round($g / [double]$h, 1)
    if($kat -ge 2){ $asiri.Add([ordered]@{ ders=$gercek[$k].ders; konu=$gercek[$k].konu; hedef=$h; kasada=$g; kat=$kat }) }
    elseif($kat -lt 0.8){ $eksik.Add([ordered]@{ ders=$gercek[$k].ders; konu=$gercek[$k].konu; katman=$hedef[$k].katman; hedef=$h; kasada=$g }) }
    else { $uyumlu++ }
  }
  # BOS: ders|konu ile eslesmedi -> derse bakmadan kelime aramasiyla DOGRULA
  $bos = New-Object System.Collections.Generic.List[object]
  foreach($k in $hedef.Keys){
    if($gercek.ContainsKey($k)){ continue }
    if([int]$hedef[$k].adet -lt 10){ continue }   # yalniz onemli hedefler
    $kel = @((Sade "$($hedef[$k].konu)") -split ' ' | Where-Object { $_.Length -ge 4 })
    if($kel.Count -eq 0){ continue }
    $eslesen = 0
    foreach($gk in $gercekKonuSade){
      $hepsi = $true
      foreach($w in $kel){ if($gk -notlike "*$w*"){ $hepsi = $false; break } }
      if($hepsi){ $eslesen++ }
    }
    $bos.Add([ordered]@{ ders=$hedef[$k].ders; konu=$hedef[$k].konu; katman=$hedef[$k].katman; hedef=$hedef[$k].adet
                         kelime_aramasiyla_bulunan=$eslesen
                         KARAR=$(if($eslesen -eq 0){'GERCEKTEN BOS'}else{'AD FARKLI - VAR'}) })
  }
  $gercekBos = @($bos | Where-Object { $_.KARAR -eq 'GERCEKTEN BOS' })
  # 06.08 Cem: "eksik dersler vardi sanki" - DERS duzeyinde sayim:
  # planda olan her ders icin kasadaki soru sayisi; 0 olan = EKSIK DERS.
  $dersPlan = @{}; foreach($p in $plan){ $d = Sade "$($p.ders)"; if(-not $dersPlan.ContainsKey($d)){ $dersPlan[$d] = [ordered]@{ ders="$($p.ders)"; hedef=0; kasada=0 } }; $dersPlan[$d].hedef += [int]$p.adet }
  foreach($s in $kasa){ if("$($s.sinav)" -ne $sinavAd){ continue }; $d = Sade "$($s.ders)"; if($dersPlan.ContainsKey($d)){ $dersPlan[$d].kasada++ } }
  $dersDurum = @($dersPlan.Values | Sort-Object { $_.kasada })
  # 06.08 Cem: "YD bin kusur soru vardi" - PLANDA OLMAYAN derslerin kasa sayimi
  # (YD/GK/Matematik gibi kotasiz dersler DERS_DURUMU'na girmiyordu, kordu).
  $planDisi = @{}
  foreach($s in $kasa){
    if("$($s.sinav)" -ne $sinavAd){ continue }
    $d = Sade "$($s.ders)"
    if($dersPlan.ContainsKey($d)){ continue }
    $ad2 = "$($s.ders)"
    if(-not $planDisi.ContainsKey($ad2)){ $planDisi[$ad2] = 0 }
    $planDisi[$ad2]++
  }
  return [ordered]@{
    PLAN_DISI_DERSLER=$planDisi
    sinav=$sinavAd; plan=$planYolu
    DERS_DURUMU=$dersDurum
    EKSIK_DERSLER=@($dersDurum | Where-Object { $_.kasada -eq 0 } | ForEach-Object { $_.ders })
    kasada_soru=$soruSayisi
    plan_konu=$hedef.Count
    ASIRI=@($asiri | Sort-Object { -$_.kat } | Select-Object -First 20)
    ASIRI_konu_sayisi=$asiri.Count
    EKSIK=@($eksik | Sort-Object { -$_.hedef } | Select-Object -First 20)
    EKSIK_konu_sayisi=$eksik.Count
    UYUMLU_konu_sayisi=$uyumlu
    GERCEKTEN_BOS=@($gercekBos | Sort-Object { -$_.hedef } | Select-Object -First 20)
    GERCEKTEN_BOS_konu_sayisi=$gercekBos.Count
    GERCEKTEN_BOS_hedef_toplami=(($gercekBos | Measure-Object -Property hedef -Sum).Sum)
    ad_farkli_ama_var=@($bos | Where-Object { $_.KARAR -ne 'GERCEKTEN BOS' }).Count
  }
}

$smmm = SinavAnaliz 'SMMM' 'veri/uretim-kotasi.json'
$sgs  = SinavAnaliz 'SGS'  'veri/sgs-uretim-kotasi.json'
# 05.08 Cem: "her konuda soru urettik mi?" - KGK da ayni olcumden gecer.
# Plani: veri/kgk-uretim-kotasi.json (67 satir/1.870; emir #27 02.08'de basildi).
$kgk  = SinavAnaliz 'KGK'  'veri/kgk-uretim-kotasi.json'

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count
  olcut='Her sinav KENDI planiyla karsilastirildi. ASIRI >=2 kat, EKSIK <0,8. BOS yalniz hedef>=10 konularda ve kelime aramasiyla dogrulanarak (ad uyusmazligi sahte bosluk uretmesin).'
  SMMM_bitirme=$smmm
  SGS_staja_giris=$sgs
  KGK_bagimsiz_denetci=$kgk
  not='Cem: "konulara ayri ayri sinavda cikan sorulara bak, fazla/eksik bul - ayri ayri iki sinavi da." SMMM hedefi 12 donem Yeterlilik kitapcigi; SGS hedefi TESMER Uygulama Yonergesi m.6.2 agirliklari.'
})
Write-Host "`n=== SMMM (bitirme) ==="
Write-Host ("  kasada {0} soru | ASIRI {1} | EKSIK {2} | UYUMLU {3} | GERCEKTEN BOS {4} (hedef toplami {5})" -f $smmm.kasada_soru,$smmm.ASIRI_konu_sayisi,$smmm.EKSIK_konu_sayisi,$smmm.UYUMLU_konu_sayisi,$smmm.GERCEKTEN_BOS_konu_sayisi,$smmm.GERCEKTEN_BOS_hedef_toplami)
Write-Host "=== SGS (staja giris) ==="
Write-Host ("  kasada {0} soru | ASIRI {1} | EKSIK {2} | UYUMLU {3} | GERCEKTEN BOS {4} (hedef toplami {5})" -f $sgs.kasada_soru,$sgs.ASIRI_konu_sayisi,$sgs.EKSIK_konu_sayisi,$sgs.UYUMLU_konu_sayisi,$sgs.GERCEKTEN_BOS_konu_sayisi,$sgs.GERCEKTEN_BOS_hedef_toplami)
Write-Host "=== KGK (bagimsiz denetci) ==="
Write-Host ("  kasada {0} soru | ASIRI {1} | EKSIK {2} | UYUMLU {3} | GERCEKTEN BOS {4} (hedef toplami {5})" -f $kgk.kasada_soru,$kgk.ASIRI_konu_sayisi,$kgk.EKSIK_konu_sayisi,$kgk.UYUMLU_konu_sayisi,$kgk.GERCEKTEN_BOS_konu_sayisi,$kgk.GERCEKTEN_BOS_hedef_toplami)
