# ============================================================================
#  BOSLUK DOGRULAMA (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  NEDEN: konu-dagilim-olcum.ps1 "planda var kasada HIC YOK: 280 konu" dedi ve
#  ben bunu Cem'e "sinavin en cok sordugu Vergi/Denetim konularinda hic
#  sorumuz yok" diye KRITIK BULGU olarak sundum.
#
#  AMA SUPHE VAR: o olcum konulari "ders|konu" anahtariyla eslestirdi. Karne
#  dosyasi gosterdi ki DERS ADLARI TUTMUYOR - ornek: "mesleki muhakeme"
#  karnede ders="Muhasebe", planda ders="Muhasebe Denetimi". Kasada da
#  "Denetim", "Muhasebe Denetimi", "Denetim Standartlari" gibi farkli ders
#  adlari var. Ders adi farkliysa SORU VARKEN YOK GORUNUR.
#
#  Bu gece sekiz kez "gercek hata" sandigim sey olcum hatasi cikti. Cem'e
#  yanlis bir oncelik verdirmemek icin ONCE DOGRULUYORUM: bu betik DERSE
#  BAKMADAN, yalniz konu metnindeki anahtar kelimelerle kasayi tarar.
#
#  SONUC: her bos gorunen omurga konu icin "gercekten 0 mi, yoksa baska
#  ders/ad altinda var mi" sorusu rakamla cevaplanir.
#
#  CIKTI: veri/bosluk-dogrulama-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/bosluk-dogrulama-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g })
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

# --- planda olup kasada (ders+konu ile) bulunamayanlari yeniden hesapla ---
$plan = @((Get-Content (Join-Path $kok 'veri/uretim-kotasi.json') -Raw -Encoding UTF8 | ConvertFrom-Json).plan)
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# kasadaki konu metinlerini sadelestirilmis olarak hazirla (bir kez)
$kasaKonu = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){ $kasaKonu.Add([ordered]@{ ders="$($s.ders)"; sade=(Sade "$($s.konu)") }) }

# ders+konu ile eslesmeyen plan konulari
$kasaAnahtar = @{}
foreach($s in $kasa){ $kasaAnahtar[(Sade "$($s.ders)|$($s.konu)")] = 1 }

$sonuc = New-Object System.Collections.Generic.List[object]
$gercektenBos = 0; $baskaAdAltinda = 0
foreach($p in $plan){
  $tamAnahtar = Sade "$($p.ders)|$($p.konu)"
  if($kasaAnahtar.ContainsKey($tamAnahtar)){ continue }   # zaten eslesti
  if([int]$p.adet -lt 10){ continue }                      # yalniz ONEMLI hedefler (>=10)

  # DERSE BAKMADAN konu adiyla ara: plan konusunun anlamli kelimeleri
  $kel = @((Sade "$($p.konu)") -split ' ' | Where-Object { $_.Length -ge 4 })
  if($kel.Count -eq 0){ continue }
  $eslesen = 0; $ornekDers = @{}
  foreach($kk in $kasaKonu){
    $hepsi = $true
    foreach($w in $kel){ if($kk.sade -notlike "*$w*"){ $hepsi = $false; break } }
    if($hepsi){
      $eslesen++
      if(-not $ornekDers.ContainsKey($kk.ders)){ $ornekDers[$kk.ders]=0 }
      $ornekDers[$kk.ders]++
    }
  }
  if($eslesen -gt 0){ $baskaAdAltinda++ } else { $gercektenBos++ }
  $sonuc.Add([ordered]@{
    plan_ders="$($p.ders)"; konu="$($p.konu)"; katman="$($p.katman)"; hedef=[int]$p.adet
    kasada_derse_bakmadan=$eslesen
    bulundugu_dersler=@($ornekDers.Keys | Sort-Object { -$ornekDers[$_] } | Select-Object -First 3 | ForEach-Object { "$_ ($($ornekDers[$_]))" })
    KARAR=$(if($eslesen -eq 0){'GERCEKTEN BOS'}else{'BASKA DERS/AD ALTINDA VAR'})
  })
}
$sonucS = @($sonuc | Sort-Object { -$_.hedef })
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='DOGRULAMA (0 USD, yazma yok)'
  kasa=$kasa.Count
  incelenen_plan_konusu=$sonucS.Count
  GERCEKTEN_BOS=$gercektenBos
  BASKA_AD_ALTINDA_VAR=$baskaAdAltinda
  olcut='Yalniz hedefi 10 ve ustu olan plan konulari incelendi. Eslesme: plan konusunun 4+ harfli TUM kelimeleri kasadaki konu metninde geciyorsa sayilir.'
  satirlar=$sonucS.ToArray()
  not='Bu betik konu-dagilim-olcum.ps1 in "280 konu hic yok" bulgusunu DOGRULAR. O olcum ders+konu anahtariyla esleme yapiyordu; ders adlari tutmuyorsa soru VARKEN yok gorunur.'
})
Write-Host "`n=== BOSLUK DOGRULAMA ==="
Write-Host ("  Incelenen plan konusu   : {0}" -f $sonucS.Count)
Write-Host ("  GERCEKTEN BOS           : {0}" -f $gercektenBos)
Write-Host ("  BASKA AD ALTINDA VAR    : {0}" -f $baskaAdAltinda)
Write-Host "`n  --- ilk 15 ---"
$sonucS | Select-Object -First 15 | ForEach-Object {
  Write-Host ("    hedef={0,-4} kasada={1,-5} {2,-16} {3}" -f $_.hedef, $_.kasada_derse_bakmadan, $_.KARAR, $_.konu) }
