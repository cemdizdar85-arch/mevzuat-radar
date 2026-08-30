# ============================================================================
#  ZORLUK KIYASI v2 - 26.08.2026 gece (Cem: "eminmiyiz? tekrar tekrar incele")
#
#  v1'in zayif noktalari kapatilir:
#   (1) MUKERRER: cikmis 45.134 cikti, karne 20.851 demisti -> parmak iziyle
#       tekillestir (normalize ilk 90 karakter), gercek set uzerinden say.
#   (2) SIMPSON: genel yuzde aldatir - kasa profili SGS'nin RESMI 130'luk ders
#       dagilimina gore AGIRLIKLANIR, oyle kiyaslanir.
#   (3) TIP EKSENI: zorluk tek boyut degil - bilgi/uygulama/analiz oranlari
#       iki tarafta ayri sayilir (bicim cetvelinden bagimsiz ikinci gosterge).
#  Ayrica 40+40 kor-hakem ornegi uretilir (kaynak gizli, karistirilmis) ->
#  scratchpad'e; hakem ajanlar ayri koşulur.
#  OLCUM - yazmaz. Rapor: veri/zorluk-kiyas-v2.json + kor ornek dosyasi.
# ============================================================================
param([string]$KorCikti = '')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY=$env:SUPABASE_SERVICE_KEY
$H=@{apikey=$KEY; Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

$reHesap=[regex]'(?i)ka[cç]t[iı]r|hesapla|tutar[iı] ne|oran[iı] ka[cç]|ka[cç] TL'
$reRakam=[regex]'\d[\d.,]{2,}'
function Zorluk([string]$soru,[string]$sikJson,[bool]$tabloVar,[bool]$yevmiyeVar){
  $p=0; $metin="$soru $sikJson"
  if($tabloVar){ $p+=2 }
  if($yevmiyeVar){ $p+=2 }
  $rak=$reRakam.Matches($metin).Count
  if($rak -ge 6){ $p+=2 } elseif($rak -ge 2){ $p+=1 }
  if($reHesap.IsMatch($soru)){ $p+=1 }
  if($soru.Length -gt 420){ $p+=1 }
  if($p -ge 4){ return 3 } elseif($p -ge 2){ return 2 } else { return 1 }
}
# TIP: bilgi (tanim/ezber) - uygulama (hesap/kayit) - analiz (yorum/kiyas/vaka)
$reBilgi=[regex]'(?i)a[sş]a[gğ][iı]dakilerden hangisi.{0,40}(tan[iı]m|de[gğ]ildir|yer almaz|say[iı]lmaz|aras[iı]nda|kapsam)|hangisidir\?|ka[cç] g[uü]n|ka[cç] y[iı]l|s[uü]resi ka[cç]'
$reUygulama=[regex]'(?i)ka[cç] TL|ka[cç]t[iı]r|hesapla|yevmiye|kayd[iı] (nas[iı]l|hangisidir)|tutar[iı]|oran[iı] ka[cç]'
function Tip([string]$soru){
  if($reUygulama.IsMatch($soru)){ return 'uygulama' }
  if($reBilgi.IsMatch($soru)){ return 'bilgi' }
  return 'analiz'
}
function Normalize([string]$s){ $t=$s.ToLowerInvariant() -replace '[^a-zçğıöşü0-9]',''; return $t.Substring(0,[Math]::Min(90,$t.Length)) }
# 26.08 Cem isaretleri: (1) onculu/bilesik soru = tek soruda coklu bilgi
# ("I. ... II. ... III. ... hangileri"), (2) sasirtmali kok (olumsuz/tersine).
$reOncul=[regex]'(?m)(^|\s)II\.\s.*?(^|\s)III\.\s|hangileri|ka[cç] tanesi'
$reSasirt=[regex]'(?i)yanl[iı][sş]t[iı]r|de[gğ]ildir|s[oö]ylenemez|yer almaz|say[iı]lmaz|olamaz|bulunamaz|yap[iı]lamaz|m[uü]mk[uü]n de[gğ]il'

# ---------- CIKMIS: diskten bol + TEKILLESTIR ----------
Write-Host 'CIKMIS bolunuyor + tekillesiyor...'
$cikSorular=New-Object System.Collections.Generic.List[string]
$parmak=@{}
$txtler=@(Get-ChildItem (Join-Path $kok 'veri\sgs-arsiv') -Recurse -Include *.txt -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '\.ocr\.' })
foreach($f in $txtler){
  $m=[IO.File]::ReadAllText($f.FullName)
  foreach($p in [regex]::Split($m,'(?m)^(?=\s{0,4}\d{1,3}\.\s)')){
    if($p.Trim().Length -lt 50){ continue }
    if($p -notmatch '^\s*(\d{1,3})\.'){ continue }
    $iz=Normalize $p
    if($iz.Length -lt 30){ continue }
    if($parmak.ContainsKey($iz)){ continue }
    $parmak[$iz]=$true
    $cikSorular.Add($p.Trim())
  }
}
Write-Host "  tekil cikmis: $($cikSorular.Count) (ham 45.134'ten)"
$cikZ=@{z1=0;z2=0;z3=0}; $cikT=@{bilgi=0;uygulama=0;analiz=0}; $cikOncul=0; $cikSasirt=0
foreach($p in $cikSorular){
  $z=Zorluk $p '' $false $false; $cikZ["z$z"]++
  $t=Tip $p; $cikT[$t]++
  if($reOncul.IsMatch($p)){ $cikOncul++ }
  if($reSasirt.IsMatch($p)){ $cikSasirt++ }
}

# ---------- KASA: SGS + ders bazli profil (agirlikli kiyas icin) ----------
Write-Host 'KASA taraniyor (SGS)...'
$dersProfil=@{}
$kasaT=@{bilgi=0;uygulama=0;analiz=0}; $kasaOncul=0; $kasaSasirt=0; $kasaToplamN=0
$kasaOrnekHavuz=New-Object System.Collections.Generic.List[object]
$bas=0
while($true){
  $r=@(Invoke-RestMethod -Uri "$U/soru_havuzu?select=id,sinav,ders,soru,siklar,tablo,yevmiye&sinav=eq.SGS&order=id&limit=500&offset=$bas" -Headers $H -TimeoutSec 300 | % { $_ })
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    $z=Zorluk "$($s.soru)" (($s.siklar | ConvertTo-Json -Compress -Depth 3)) ($null -ne $s.tablo) ($null -ne $s.yevmiye -and @($s.yevmiye).Count -gt 0)
    $d="$($s.ders)"
    if(-not $dersProfil[$d]){ $dersProfil[$d]=@{n=0;z1=0;z2=0;z3=0} }
    $dersProfil[$d].n++; $dersProfil[$d]["z$z"]++
    $kasaT[(Tip "$($s.soru)")]++
    $kasaToplamN++
    if($reOncul.IsMatch("$($s.soru)")){ $kasaOncul++ }
    if($reSasirt.IsMatch("$($s.soru)")){ $kasaSasirt++ }
    if("$($s.soru)".Length -gt 80){ $kasaOrnekHavuz.Add([pscustomobject]@{id=$s.id;soru="$($s.soru)";siklar=$s.siklar}) }
  }
  $bas+=500
  if($bas % 5000 -eq 0){ Write-Host "  ...$bas" }
}

# SGS resmi agirliklari (130 soru)
$AG=@{'Finansal Muhasebe'=26;'Denetim'=16;'Yabanci Dil'=10;'Maliyet Muhasebesi'=8;'Matematik'=8;'Mali Tablolar Analizi'=8;'Turkce'=7;'Borclar Hukuku'=6;'Ekonomi'=6;'Maliye'=6;'Vergi Hukuku'=6;'Ticaret Hukuku'=6;'Is ve Sosyal Guvenlik Hukuku'=6;'Meslek Hukuku'=6;'Ataturk Ilke ve Inkilap Tarihi'=5}
$agz=@{z1=0.0;z2=0.0;z3=0.0}; $agTop=0.0
foreach($d in $AG.Keys){
  $p=$dersProfil[$d]; if(-not $p -or $p.n -eq 0){ continue }
  $w=$AG[$d]; $agTop+=$w
  foreach($zz in 'z1','z2','z3'){ $agz[$zz]+=$w*($p[$zz]/$p.n) }
}

# ---------- KOR HAKEM ORNEGI: 40 cikmis + 40 kasa, karistirilmis ----------
$rnd=New-Object System.Random(20260827)
$korListe=New-Object System.Collections.Generic.List[object]
$cikSec=$cikSorular | Sort-Object { $rnd.Next() } | Select-Object -First 40
foreach($p in $cikSec){ $korListe.Add([pscustomobject]@{kaynak='cikmis'; metin=$p}) }
$kasaSec=$kasaOrnekHavuz | Sort-Object { $rnd.Next() } | Select-Object -First 40
foreach($s in $kasaSec){
  $sik=@(); foreach($k in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$k] -and $s.siklar.$k){ $sik+="$k) $($s.siklar.$k)" } }
  $korListe.Add([pscustomobject]@{kaynak='kasa'; metin=("$($s.soru)`n"+($sik -join "`n"))})
}
$karisik=$korListe | Sort-Object { $rnd.Next() }
$n=0; $kor=@(); $harita=@()
foreach($x in $karisik){ $n++; $kor+=[pscustomobject]@{no=$n; metin=$x.metin}; $harita+=[pscustomobject]@{no=$n; kaynak=$x.kaynak} }
if($KorCikti){
  $kor | ConvertTo-Json -Depth 3 | Out-File (Join-Path $KorCikti 'kor-zorluk-sorular.json') -Encoding utf8
  $harita | ConvertTo-Json -Depth 3 | Out-File (Join-Path $KorCikti 'kor-zorluk-harita-GIZLI.json') -Encoding utf8
  Write-Host "kor ornek yazildi: $KorCikti (80 soru)"
}

# ---------- RAPOR ----------
function Yzd($h,$n){ if($n -eq 0){ return '0/0/0' }; return "%$([math]::Round(100*$h.z1/$n))/%$([math]::Round(100*$h.z2/$n))/%$([math]::Round(100*$h.z3/$n))" }
$cikN=$cikSorular.Count
''
'======== v2 SONUC ========'
"1) TEKIL cikmis SGS : $cikN soru | Z1/Z2/Z3 = $(Yzd $cikZ $cikN)"
"   Tip (cikmis)     : bilgi %$([math]::Round(100*$cikT.bilgi/$cikN)) | uygulama %$([math]::Round(100*$cikT.uygulama/$cikN)) | analiz %$([math]::Round(100*$cikT.analiz/$cikN))"
$kasaN=($kasaT.bilgi+$kasaT.uygulama+$kasaT.analiz)
"2) KASA SGS (ham)   : $kasaN soru | Tip: bilgi %$([math]::Round(100*$kasaT.bilgi/$kasaN)) | uygulama %$([math]::Round(100*$kasaT.uygulama/$kasaN)) | analiz %$([math]::Round(100*$kasaT.analiz/$kasaN))"
"3) KASA AGIRLIKLI (130 dagilimina gore) : Z1 %$([math]::Round(100*$agz.z1/$agTop)) | Z2 %$([math]::Round(100*$agz.z2/$agTop)) | Z3 %$([math]::Round(100*$agz.z3/$agTop))"
''
'4) CEM ISARETLERI (tek soruda coklu bilgi + sasirtmali kok):'
"   ONCULLU (I-II-III/hangileri): cikmis %$([math]::Round(100*$cikOncul/$cikN,1))  |  kasa %$([math]::Round(100*$kasaOncul/[math]::Max(1,$kasaToplamN),1))"
"   SASIRTMALI KOK (yanlistir/degildir...): cikmis %$([math]::Round(100*$cikSasirt/$cikN,1))  |  kasa %$([math]::Round(100*$kasaSasirt/[math]::Max(1,$kasaToplamN),1))"
''
'Ders bazli kasa Z3 oranlari:'
foreach($d in ($dersProfil.Keys | Sort-Object)){ $p=$dersProfil[$d]; if($p.n -ge 20){ "  {0,-32} n={1,5}  Z3 %{2}" -f $d,$p.n,[math]::Round(100*$p.z3/$p.n) } }
$rapor=[ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); tekilCikmis=$cikN; cikZ=$cikZ; cikTip=$cikT; kasaTip=$kasaT; kasaAgirlikli=@{z1=[math]::Round(100*$agz.z1/$agTop);z2=[math]::Round(100*$agz.z2/$agTop);z3=[math]::Round(100*$agz.z3/$agTop)}; dersProfil=$dersProfil }
$rapor | ConvertTo-Json -Depth 5 | Out-File (Join-Path $kok 'veri\zorluk-kiyas-v2.json') -Encoding utf8
'-> veri/zorluk-kiyas-v2.json'
