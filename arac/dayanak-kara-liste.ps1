# ============================================================================
#  DAYANAK KARA LİSTESİ (02.09.2026 — Cem: "çöp dayanakları boşalt")
#
#  Köprüdeki dayanaklar Excel'den geliyor ve bir kısmı ÇÖP: tek maddeye binlerce
#  konu bağlanmış. Ama körlemesine boşaltmak ZARARLI — ölçüldü: İş K. m.11'e
#  bağlı 614 konunun HEPSİ doğru çıktı. Bu yüzden silmek yerine ÖLÇÜP DAMGALIYORUZ.
#
#  YÖNTEM: en çok yığılan dayanaklar tek tek örneklenir; hakeme dayanağın GERÇEK
#  MADDE METNİ ile sorulur (künye yetmez — ölçüldü: künyeyle %67 çıkan VUK m.275
#  metinle %33, künyeyle %17 çıkan TTK m.720 metinle %67; künye hem yukarı hem
#  aşağı yanıltıyor). Yanlış oranı eşiği aşan dayanak KARA LİSTEYE girer.
#
#  ÇIKTI: veri/dayanak-kara-liste.json → üretici bu dayanaklara GÜVENMEZ,
#         konuyu doğrudan ambarda arar. Köprü kaydı SİLİNMEZ (veri kaybı yok).
#
#  ⚠ PS TUZAĞI (bugün 4 kez düşüldü): döngü değişkenine $h DENMEZ — $H başlık
#    hashtable'ını ezer ve ambar sorgusu sessizce "kayıt yok" döner.
# ============================================================================
param(
  [int]$DayanakSayisi=10,     # en cok yigilan kac dayanak olculecek
  [int]$OrnekBasina=10,       # her dayanak icin kac konu orneklenecek
  [int]$KaraListeEsigi=50,    # yanlis orani %N ve uzeriyse kara listeye girer
  # 02.09 gece (Cem "1.2.3 yap" -> 2): tek DERS icin olcum. KGK Kurumsal Yon.+Fin. Yon.
  # partisinde hakem 3 soruyu yanlis dayanaktan reddetti ("yonetim kurulu komiteleri" ->
  # Varlik Yonetim Sirketleri Yonetmeligi). Ders suzgeci verilirse yalniz o dersin
  # kopru kayitlari sayilir; sonuc mevcut kara listeye BIRLESTIRILEREK yazilir (ezmez).
  [string]$Sinav='',
  [string]$DersRegex=''
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$BASLIK=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function Coz2([string]$txt){
  $t=($txt -split "`n" | Where-Object { $_ -notmatch '^\s*```' }) -join "`n"
  $t=$t.Trim()
  try{ return $t|ConvertFrom-Json }catch{}
  $i1=$t.IndexOf('{'); $i2=$t.LastIndexOf('}')
  if($i1 -ge 0 -and $i2 -gt $i1){ try{ return $t.Substring($i1,$i2-$i1+1)|ConvertFrom-Json }catch{} }
  return $null
}
function AmbarMetni([string]$kunye){
  $u=$AMBAR+'?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($kunye)+'&limit=1'
  try{
    $cevap=Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 60
    $ham=ConvertFrom-Json -InputObject $cevap.Content
    $kayit=@($ham)
    if($kayit.Count -and $kayit[0].metin){ return "$($kayit[0].metin)" }
  }catch{}
  return ''
}

$tam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if($Sinav){ $tam=@($tam | Where-Object { $_.sinav -eq $Sinav }) }
if($DersRegex){ $tam=@($tam | Where-Object { ("$($_.bizim_ders)$($_.arsiv_ders)") -match $DersRegex }) }
Write-Host "kopru kaydi (suzgec sonrasi): $(@($tam).Count)"
# dayanak -> tekil konu kumesi
$sayac=@{}
foreach($r in @($tam)){
  $d="$($r.dayanak)"; if(-not $d){ $d="$($r.cikmis_dayanak)" }
  $d=($d -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $d){ continue }
  if(-not $sayac.ContainsKey($d)){ $sayac[$d]=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal) }
  [void]$sayac[$d].Add("$($r.konu)")
}
$enCok=@($sayac.Keys | Sort-Object { -$sayac[$_].Count } | Select-Object -First $DayanakSayisi)
Write-Host "olculecek dayanak: $($enCok.Count) (en cok yigilanlar)"

$istem=@'
Sen bagimsiz bir MEVZUAT HAKEMISIN. Bir SINAV KONUSU ve ona atanmis dayanagin GERCEK METNI verilecek.
Karar: bu metin bu konunun dayanagi olabilir mi? Konunun kurali/tanimi bu metinden cikarilabilir mi?
EVET: metin konuyu kapsiyor ya da konunun dogrudan kaynagi.
HAYIR: metin bambaska bir seyi duzenliyor, konuyla ilgisiz.
Cevap YALNIZ JSON: {"karar":"EVET"} ya da {"karar":"HAYIR"}
=== KONU === {KONU}
=== DAYANAK METNI === {METIN}
'@
$sonuclar=New-Object System.Collections.Generic.List[object]
$karaListe=New-Object System.Collections.Generic.List[string]
foreach($dayanak in $enCok){
  $bagliSayi=$sayac[$dayanak].Count
  $metin=AmbarMetni $dayanak
  if(-not $metin){
    Write-Host ("  {0,-52} AMBARDA METIN YOK -> olculemedi" -f $dayanak.Substring(0,[Math]::Min(52,$dayanak.Length)))
    $sonuclar.Add([pscustomobject][ordered]@{ dayanak=$dayanak; bagli_konu=$bagliSayi; orneklem=0; dogru=0; yanlis=0; olculemedi=0; yanlis_yuzde=-1; durum='olculemedi (ambarda metin yok)'; tahmini_yanlis_kayit=0; yanlis_ornekleri=@() })
    continue
  }
  $mk=$metin; if($mk.Length -gt 1400){ $mk=$mk.Substring(0,1400) }
  $tekil=@(@($tam | Where-Object { (("$($_.dayanak)" -replace '\s*\(\d+\)\s*$','').Trim()) -eq $dayanak }) | Group-Object konu | ForEach-Object { $_.Group[0] })
  $sirali=@($tekil | Sort-Object { -[int]$_.donem })
  $adim=[Math]::Max(1,[math]::Floor($sirali.Count/$OrnekBasina))
  $ornek=New-Object System.Collections.Generic.List[object]
  for($i=0;$i -lt $sirali.Count -and $ornek.Count -lt $OrnekBasina;$i+=$adim){ $ornek.Add($sirali[$i]) }
  $evet=0;$yanlis=0;$olculemedi=0
  $yanlisOrnek=New-Object System.Collections.Generic.List[string]
  foreach($kayit in $ornek){
    $ist=$istem.Replace('{KONU}',"$($kayit.konu)").Replace('{METIN}',$mk)
    $c=$null
    foreach($deneme in 1..4){
      try{ $cvp=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $ist -MaxTok 200; $c=Coz2 "$($cvp.metin)"; if($c -and $c.karar){ break }; $c=$null }catch{}
      Start-Sleep -Seconds (3*$deneme)
    }
    if(-not $c){ $olculemedi++; continue }
    if("$($c.karar)" -eq 'EVET'){ $evet++ } else { $yanlis++; $yanlisOrnek.Add("$($kayit.konu)") }
    Start-Sleep -Milliseconds 800
  }
  $olculen=$evet+$yanlis
  $oran=$(if($olculen -ge 6){ [math]::Round(100*$yanlis/$olculen) } else { $null })
  $durum=$(if($null -eq $oran){ 'orneklem yetersiz' } elseif($oran -ge $KaraListeEsigi){ 'KARA LISTE' } else { 'guvenilir' })
  if($durum -eq 'KARA LISTE'){ $karaListe.Add($dayanak) }
  # [pscustomobject] SART: ic ice [ordered]@{} listesi RaporYaz/ConvertTo-Json
  # tarafinda "Bagimsiz degisken turleri eslesmiyor" ile duser (02.09 yasandi).
  $sonuclar.Add([pscustomobject][ordered]@{
    dayanak=$dayanak; bagli_konu=$bagliSayi; orneklem=$ornek.Count
    dogru=$evet; yanlis=$yanlis; olculemedi=$olculemedi
    yanlis_yuzde=$(if($null -ne $oran){ [int]$oran } else { -1 })
    durum=$durum
    tahmini_yanlis_kayit=$(if($null -ne $oran){ [int][math]::Round($bagliSayi*$oran/100) } else { 0 })
    yanlis_ornekleri=@($yanlisOrnek | Select-Object -First 6)
  })
  Write-Host ("  {0,-52} bagli={1,-5} yanlis=%{2,-4} -> {3}" -f $dayanak.Substring(0,[Math]::Min(52,$dayanak.Length)),$bagliSayi,$(if($null -ne $oran){$oran}else{'?'}),$durum)
}
# BIRLESTIRME: onceki olcumler korunur; ayni dayanak yeniden olculduyse yenisi gecer.
$hedefYol=Join-Path $depoKok 'veri\dayanak-kara-liste.json'
$eskiAyrinti=@{}; $eskiKara=New-Object System.Collections.Generic.List[string]
if(Test-Path $hedefYol){
  try{
    $eski=Get-Content $hedefYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($e in @($eski.ayrinti)){ $eskiAyrinti["$($e.dayanak)"]=$e }
    foreach($k in @($eski.kara_liste)){ $eskiKara.Add("$k") }
  }catch{}
}
# Kapsam anahtari: ders suzgecli olcum, ayni dayanagin GENEL olcumunu EZMEZ (ilk denemede
# VUK m.275'in 2.088 konuluk genel satiri 17 konuluk KGK satiriyla degisti, tahmin 1.951->1.423 dustu).
$kapsam=$(if($Sinav -or $DersRegex){ "$Sinav/$DersRegex" } else { 'genel' })
$eskiAyrinti2=@{}
foreach($e in $eskiAyrinti.Values){ $ek=$(if($e.PSObject.Properties['kapsam'] -and $e.kapsam){ "$($e.kapsam)" } else { 'genel' }); $eskiAyrinti2["$($e.dayanak)|$ek"]=$e }
foreach($s in $sonuclar){ $s | Add-Member -NotePropertyName kapsam -NotePropertyValue $kapsam -Force; $eskiAyrinti2["$($s.dayanak)|$kapsam"]=$s }
$birlesikAyrinti=@($eskiAyrinti2.Values | Sort-Object { -[int]$_.bagli_konu })
$birlesikKara=New-Object System.Collections.Generic.List[string]
foreach($s in $birlesikAyrinti){ if("$($s.durum)" -eq 'KARA LISTE' -and -not $birlesikKara.Contains("$($s.dayanak)")){ $birlesikKara.Add("$($s.dayanak)") } }
$toplamTahmin=0
foreach($s in $birlesikAyrinti){ $toplamTahmin += [int]$s.tahmini_yanlis_kayit }
$cikti=[pscustomobject][ordered]@{
  aciklama="En cok yigilan dayanaklarin GERCEK dogruluk olcumu. Hakeme dayanagin AMBARDAKI MADDE METNI verilir (kunye tek basina yaniltir - olculdu). Yanlis orani esigi asan dayanak KARA LISTEye girer: uretici o dayanaga guvenmez, konuyu dogrudan ambarda arar. Kopru kaydi SILINMEZ. Olcumler birikimlidir (ders suzgecli kosular oncekileri ezmez)."
  esik_yuzde=$KaraListeEsigi
  son_kosu=$(if($Sinav -or $DersRegex){ "suzgec: sinav=$Sinav ders=$DersRegex ($($sonuclar.Count) dayanak)" } else { "genel ($($sonuclar.Count) dayanak)" })
  olculen_dayanak=$birlesikAyrinti.Count
  # .ToArray() SART: hashtable literali icinde List'i '@(...)' ile sarmak PS 5.1'de
  # "Bagimsiz degisken turleri eslesmiyor" ile duser (02.09 olculdu; @() / [ordered]
  # / once-degiskene-al varyantlarinin UCU DE dustu, calisan tek yol ToArray()).
  kara_liste=$birlesikKara.ToArray()
  tahmini_yanlis_kayit_toplami=$toplamTahmin
  ayrinti=$birlesikAyrinti
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\dayanak-kara-liste.json') -Nesne $cikti
Write-Host ""
Write-Host ("KARA LISTE: {0} dayanak | bunlara bagli tahmini yanlis kayit: {1}" -f $karaListe.Count,$toplamTahmin)
