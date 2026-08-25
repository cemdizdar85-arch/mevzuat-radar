# ============================================================================
#  SINAV + DERS ENVANTERI (05.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  NEDEN: mevcut motor/etiket-duzelt.ps1 (29.07) kasada bir SINAV alani
#  oldugunu gosterdi (SGS / SMMM). Benim bu geceki iki olcumum bunu
#  FILTRELEMEDI:
#    - konu-dagilim-olcum.ps1 : tum kasayi (SGS+SMMM) yalniz SMMM Yeterlilik
#      planiyla karsilastirdi -> "Yabanci Dil / Turkce / Ekonomi plan disi"
#      dedim; oysa onlar SGS sorulari ve DOGRU etiketli.
#    - bosluk-dogrulama.ps1   : ayni sebeple "yanlis derste" gorunen bazi
#      sorular aslinda baska SINAVIN sorusu olabilir.
#  Yani iki raporumun da SGS/SMMM ayrimi yok. Etikete dokunmadan once
#  DOGRU ENVANTER cikarilmali - yanlis tasima geri alinabilir ama once
#  yapilmamalidir.
#
#  BU BETIK: sinav bazinda ders dagilimini, her sinavin RESMI ders listesine
#  gore "taninan / taninmayan" ayrimini ve SMMM tarafinda plana gore konu
#  eslesmesini cikarir. Yalniz OLCUM.
#
#  CIKTI: veri/sinav-ders-envanteri.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/sinav-ders-envanteri.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
# 24.08: elle calistirmada anahtar bulunamiyordu - yayin-kapisi.ps1'deki
# KULLANICI ORTAMI yedegi burada yoktu.
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
# 24.08: 'User-Agent' EKSIKTI -> 401. sb_secret anahtar robot UA ister; UA'siz
# istek TARAYICI sayilip reddedilir (13.08 dersi, yayin-kapisi.ps1'de vardi,
# burada yoktu). Yani bu betik timeout onarilsa bile yine olurdu.
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
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

# 24.08: OFFSET sayfalamasi kaldirildi (yayin-kapisi.ps1'in 19.08 dersi burada
# uygulanmamisti). offset buyudukce Postgres o kadar satiri atlayarak tarar;
# son sayfalar agirlasip 20.08'de statement timeout (500/57014) uretti ve bu
# betik O GUNDEN BERI OLUYDU - rapor "HATA" yaziyordu, kimse bakmadi.
# Anahtar-takipli sayfalama (id=gt.sonId) her sayfada sabit maliyettir.
$kasa = New-Object System.Collections.Generic.List[object]
$sonId = ''
for($sayfa=0; $sayfa -lt 60; $sayfa++){
  $filtre = if($sonId){ "&id=gt." + [uri]::EscapeDataString($sonId) } else { "" }
  $r = CekListe "$U`?select=id,sinav,ders,konu&order=id&limit=1000$filtre"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  $sonId = "$(@($r)[-1].id)"
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ throw "Kasa kucuk gorundu ($($kasa.Count)) - sayfalama kirilmis olabilir; olculemeyen sey saglam sayilmaz." }

# --- SINAV dagilimi ---
$sinavSay = @{}
foreach($s in $kasa){
  $sv = "$($s.sinav)"; if($sv.Trim() -eq ''){ $sv = '(BOS)' }
  if(-not $sinavSay.ContainsKey($sv)){ $sinavSay[$sv]=0 }; $sinavSay[$sv]++
}

# --- SINAV + DERS dagilimi ---
$sd = @{}
foreach($s in $kasa){
  $sv = "$($s.sinav)"; if($sv.Trim() -eq ''){ $sv='(BOS)' }
  $an = "$sv|$($s.ders)"
  if(-not $sd.ContainsKey($an)){ $sd[$an] = [ordered]@{ sinav=$sv; ders="$($s.ders)"; soru=0 } }
  $sd[$an].soru++
}

# --- RESMI ders listeleri ---
$plan = @((Get-Content (Join-Path $kok 'veri/uretim-kotasi.json') -Raw -Encoding UTF8 | ConvertFrom-Json).plan)
$YET = @{}
foreach($p in $plan){ $YET[(Sade "$($p.ders)")] = "$($p.ders)" }
# konu -> tek ders haritasi (plan)
$konuDers = @{}
foreach($p in $plan){
  $k = Sade "$($p.konu)"; if($k -eq ''){ continue }
  if(-not $konuDers.ContainsKey($k)){ $konuDers[$k] = New-Object System.Collections.Generic.List[string] }
  if(-not $konuDers[$k].Contains("$($p.ders)")){ $konuDers[$k].Add("$($p.ders)") }
}
$tekil = @{}
foreach($k in $konuDers.Keys){ if($konuDers[$k].Count -eq 1){ $tekil[$k] = $konuDers[$k][0] } }

# --- SINAV bazinda: dersi Yeterlilik listesinde TANINAN / TANINMAYAN ---
$taninan = @{}; $taninmayan = @{}
foreach($s in $kasa){
  $sv = "$($s.sinav)"; if($sv.Trim() -eq ''){ $sv='(BOS)' }
  $ok = $YET.ContainsKey((Sade "$($s.ders)"))
  if($ok){ if(-not $taninan.ContainsKey($sv)){ $taninan[$sv]=0 }; $taninan[$sv]++ }
  else   { if(-not $taninmayan.ContainsKey($sv)){ $taninmayan[$sv]=0 }; $taninmayan[$sv]++ }
}

# --- YANLIS DERS ADAYI: konu planda TEK derse bagli, mevcut ders BASKA bir
#     Yeterlilik dersi. Sinav bazinda ayri sayilir (bu kez dogru sekilde).
$yanlisDers = @{}
foreach($s in $kasa){
  $k = Sade "$($s.konu)"
  if(-not $tekil.ContainsKey($k)){ continue }
  $mevcut = "$($s.ders)"
  if(-not $YET.ContainsKey((Sade $mevcut))){ continue }        # Yeterlilik dersi degilse dokunma
  if((Sade $mevcut) -eq (Sade $tekil[$k])){ continue }         # zaten dogru
  $sv = "$($s.sinav)"; if($sv.Trim() -eq ''){ $sv='(BOS)' }
  $an = "$sv|$mevcut -> $($tekil[$k])"
  if(-not $yanlisDers.ContainsKey($an)){ $yanlisDers[$an] = [ordered]@{ sinav=$sv; gecis="$mevcut -> $($tekil[$k])"; soru=0 } }
  $yanlisDers[$an].soru++
}

function Sirala($tablo, $adet){
  # 05.08 BUG (push oncesi testte yakalandi): burada "Sort-Object { -$tablo[$k].soru }"
  # yaziliydi. Sort-Object blogunun icinde dongu degiskeni $k GECERLI DEGILDIR;
  # oradaki degisken $_'dir. $k null oldugu icin her satirda "array index
  # evaluated to null" hatasi veriyor, siralama sansa kaliyordu.
  $l = New-Object System.Collections.Generic.List[object]
  foreach($k in ($tablo.Keys | Sort-Object { -$tablo[$_].soru } )){ $l.Add($tablo[$k]) }
  return @($l | Select-Object -First $adet)
}
$sinavListe = New-Object System.Collections.Generic.List[object]
foreach($k in ($sinavSay.Keys | Sort-Object { -$sinavSay[$_] })){
  $sinavListe.Add([ordered]@{ sinav=$k; soru=$sinavSay[$k]
    dersi_Yeterlilik_listesinde=$(if($taninan.ContainsKey($k)){$taninan[$k]}else{0})
    dersi_listede_YOK=$(if($taninmayan.ContainsKey($k)){$taninmayan[$k]}else{0}) })
}
$yanlisListe = Sirala $yanlisDers 30
$topYanlis = 0; foreach($k in $yanlisDers.Keys){ $topYanlis += $yanlisDers[$k].soru }

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count
  SINAV_dagilimi=@($sinavListe)
  sinav_ders_dagilimi=@(Sirala $sd 40)
  YANLIS_DERS_ADAYI_toplam=$topYanlis
  yanlis_ders_gecisleri=@($yanlisListe)
  not='Yalniz OLCUM. Bu rapor bu gecenin iki olcumundeki EKSIGI kapatir: konu-dagilim ve bosluk-dogrulama SINAV alanini filtrelemiyordu, bu yuzden SGS sorulari "plan disi"/"yanlis" gorunuyordu. Etiket tasimasi ancak bu envanter okunduktan sonra yapilmalidir.'
})
Write-Host "`n=== SINAV DAGILIMI ==="
$sinavListe | ForEach-Object { Write-Host ("  {0,-10} {1,6} soru   (Yeterlilik dersi {2}, listede olmayan {3})" -f $_.sinav, $_.soru, $_.dersi_Yeterlilik_listesinde, $_.dersi_listede_YOK) }
Write-Host ("`n=== YANLIS DERS ADAYI: {0} soru ===" -f $topYanlis)
$yanlisListe | Select-Object -First 15 | ForEach-Object { Write-Host ("  {0,5}  [{1}] {2}" -f $_.soru, $_.sinav, $_.gecis) }
