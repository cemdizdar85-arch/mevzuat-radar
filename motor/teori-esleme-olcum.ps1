# ============================================================================
#  TEORI ESLEME OLCUMU — BEDAVA PILOT (02.08.2026)
#  Cem: "bundan sonra para harcamadan pilot calisma ayarla, bosa gidecek 1 sent yok"
#
#  NEDEN: Teori kapisinin DOGRU calisip calismadigini anlamak icin hakemi
#  (yani API'yi) calistirmaya GEREK YOK. Kapinin isi tek sey: soruyu DOGRU
#  teori notuyla eslestirmek. Bu eslesmeyi ekrana dokebiliriz - insan gozuyle
#  bakip "bu soru bu nota mi baglanmali?" diye karar veririz. API cagrisi YOK,
#  maliyet SIFIR.
#
#  Ilk pilotta (0,31 USD) sunu ogrendik: kapi calisiyordu ama "pesin odenen
#  vergilerin muhasebe kaydi" sorusunu 'vergi teorisi' notuna bagliyordu.
#  Bu betik ayni hatayi PARA HARCAMADAN gosterir.
#
#  KULLANIM: ./motor/teori-esleme-olcum.ps1 [-adet 200]
#  ENV: SUPABASE_SERVICE_KEY.  Cikti: veri/teori-esleme-raporu.json
# ============================================================================
param([int]$adet = 200)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$raporYol = Join-Path $kok 'veri/teori-esleme-raporu.json'
function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), $enc) }
trap {
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- hakemin "yetersiz" dedigi kimlikler (onarim hedefi bu kume)
$yetersiz = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($f in (Get-ChildItem (Join-Path $kok 'veri') -Filter 'profesor-rapor-*.json' -ErrorAction SilentlyContinue)){
  try { $r = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($r.sonuclar)){ if("$($s.destek)" -eq 'yetersiz'){ [void]$yetersiz.Add("$($s.id)") } }
}
Write-Host ("Hakem 'yetersiz' kimlik: {0}" -f $yetersiz.Count)

$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$kasa = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,ders,konu,soru,kaynak&limit=1000&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){ $kasa.Add($s) }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

$hedef = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $tam = "$($s.id)"; $kisa = if($tam.Length -ge 8){ $tam.Substring(0,8) } else { $tam }
  if($yetersiz.Contains($tam) -or $yetersiz.Contains($kisa)){ $hedef.Add($s) }
  if($hedef.Count -ge $adet){ break }
}
Write-Host ("Olculecek ornek: {0}" -f $hedef.Count)

$eslesen = 0; $eslesmeyen = 0
$ornekler = New-Object System.Collections.Generic.List[object]
foreach($s in $hedef){
  $tn = TeoriNotuMetni "$($s.kaynak)" "$($s.konu)"
  if($tn){
    $eslesen++
    if($ornekler.Count -lt 40){
      $ornekler.Add([ordered]@{
        ders = "$($s.ders)"; konu = "$($s.konu)"
        eski_kaynak = "$($s.kaynak)"
        eslesen_not = "$($tn.ad)"; puan = $tn.puan
        soru = ("$($s.soru)").Substring(0, [Math]::Min(120, "$($s.soru)".Length))
      })
    }
  } else { $eslesmeyen++ }
}

$oran = if($hedef.Count){ [math]::Round(100*$eslesen/$hedef.Count,1) } else { 0 }
Rapor ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  maliyet = "0 USD - API cagrisi yok"
  yetersiz_kimlik = $yetersiz.Count
  olculen = $hedef.Count
  eslesen = $eslesen
  eslesmeyen = $eslesmeyen
  eslesme_orani_yuzde = $oran
  ornekler = @($ornekler)
  not = "Bu rapor eslesmenin DOGRULUGUNU insan gozuyle denetlemek icindir: her ornekte 'konu' ile 'eslesen_not' birbirine ait mi diye bakilir. Alakasiz eslesme varsa puan esigi yukseltilir - PARA HARCANMADAN."
})
Write-Host ("ESLESEN: {0} | ESLESMEYEN: {1} | oran %{2}" -f $eslesen, $eslesmeyen, $oran)
Write-Host ("-> {0}" -f $raporYol)
