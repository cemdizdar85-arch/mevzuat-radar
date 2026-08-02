# ============================================================================
#  HOMOGLIF ONARIMI — Kiril harf sizintisini deterministik duzeltir (03.08.2026)
#
#  NEDEN: Onarim taramasi 99 soruda Kiril/Yunan karakter buldu ("amortisман"
#  gibi - model cok dilli token kaymasi). Turkce metinde Kiril harfin YERI YOK;
#  amaclanan harf, ayni gorunuslu/sesli Latin harfidir. Bu deterministik bir
#  degisimdir - MODEL GEREKMEZ, 0 USD.
#
#  EMNIYET:
#   - Yalniz esleme tablosundaki harfler cevrilir; tablo disinda Kiril kalan
#     soru YAZILMAZ, "elle" listesine dusulur (yarim onarim yazilmaz).
#   - Yunan harfleri cevrilmez, yalniz raporlanir (matematik sembolu olabilir).
#   - Varsayilan OLCUM (yazmaz). Yazmak icin: -uygula
#   - Yazma sonrasi GERI OKUYUP yeniden sayar (yesil kosu != tam veri).
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/homoglif-onarim.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$cikti = Join-Path $kok "veri/homoglif-onarim.json"

function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
$KEY = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($KEY)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0
}
$BASLIK = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# --- esleme: Kiril -> amaclanan Latin/Turkce harf. Gorunus + ses birlikte
#     degerlendirildi; suphelisi TABLODA YOK (elle listesine duser).
$MAP = @{
  [char]0x0430='a'; [char]0x0410='A'   # а А
  [char]0x0435='e'; [char]0x0415='E'   # е Е
  [char]0x043E='o'; [char]0x041E='O'   # о О
  [char]0x0441='c'; [char]0x0421='C'   # с С (gorunus c)
  [char]0x0440='p'; [char]0x0420='P'   # р Р (gorunus p)
  [char]0x0445='x'; [char]0x0425='X'   # х Х
  [char]0x0443='y'; [char]0x0423='Y'   # у У (gorunus y)
  [char]0x0456='i'; [char]0x0406='I'   # і І (Ukraynaca i)
  [char]0x0455='s'; [char]0x0405='S'   # ѕ Ѕ
  [char]0x0458='j'; [char]0x0408='J'   # ј Ј
  [char]0x043C='m'; [char]0x041C='M'   # м М (amortisман vakasi)
  [char]0x043D='n'; [char]0x041D='H'   # н -> n (ses; амortisман), Н -> H (gorunus)
  [char]0x0442='t'; [char]0x0422='T'   # т Т
  [char]0x043A='k'; [char]0x041A='K'   # к К
  [char]0x0432='v'; [char]0x0412='B'   # в -> v (ses), В -> B (gorunus)
  [char]0x0438='i'; [char]0x0418='I'   # и И (ses i)
  [char]0x043B='l'; [char]0x041B='L'   # л Л
  [char]0x0434='d'; [char]0x0414='D'   # д Д
  [char]0x0437='z'; [char]0x0417='Z'   # з З
  [char]0x0431='b'; [char]0x0411='B'   # б Б
  [char]0x0433='g'; [char]0x0413='G'   # г Г
  [char]0x043F='p'; [char]0x041F='P'   # п П (ses p)
  [char]0x0444='f'; [char]0x0424='F'   # ф Ф
  [char]0x0448='ş'; [char]0x0428='Ş'   # ш Ш
  [char]0x0447='ç'; [char]0x0427='Ç'   # ч Ч
  [char]0x044B='ı'; [char]0x042B='I'   # ы Ы
  [char]0x044D='e'; [char]0x042D='E'   # э Э
  [char]0x0439='y'; [char]0x0419='Y'   # й Й
  [char]0x0446='c'; [char]0x0426='C'   # ц Ц
  [char]0x0436='j'; [char]0x0416='J'   # ж Ж
}
$reKiril = [regex]'[Ѐ-ӿ]'
$reYunan = [regex]'[Ͱ-Ͽ]'

function Onar([string]$s){
  if($null -eq $s){ return $null }
  $sb = New-Object System.Text.StringBuilder
  foreach($ch in $s.ToCharArray()){
    if($MAP.ContainsKey($ch)){ [void]$sb.Append([string]$MAP[$ch]) } else { [void]$sb.Append($ch) }
  }
  return $sb.ToString()
}

# ------------------------------------------------------------- kasayi tara
$hepsi = 0
$vurgun = New-Object System.Collections.Generic.List[object]
$offset = 0; $sayfa = 1000
while($true){
  $u = "$U`?select=id,soru,siklar,aciklama,hap&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 180
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $hepsi++
    $tum = "$($s.soru) $($s.hap)"
    if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $tum += ' ' + "$($p.Value)" } }
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }
    if($reKiril.IsMatch($tum) -or $reYunan.IsMatch($tum)){ $vurgun.Add($s) }
  }
  if($parti.Count -lt $sayfa){ break }
  $offset += $sayfa
}
Write-Host ("Taranan: {0} | homoglifli: {1}" -f $hepsi, $vurgun.Count)

$duzelen = 0; $elle = New-Object System.Collections.Generic.List[string]; $yunanli = New-Object System.Collections.Generic.List[string]
$hataYaz = 0; $ilkHata = ''   # kor kalma: ilk sunucu hatasi RAPORA yazilir (Actions logu kilitli)
foreach($s in $vurgun){
  $id = "$($s.id)"
  $yeniSoru = Onar "$($s.soru)"
  $yeniHap  = Onar "$($s.hap)"
  $yeniSik  = $null
  if($s.siklar){ $yeniSik = [ordered]@{}; foreach($p in $s.siklar.PSObject.Properties){ $yeniSik[$p.Name] = Onar "$($p.Value)" } }
  $yeniAck  = $null
  if($s.aciklama){ $yeniAck = [ordered]@{}; foreach($p in $s.aciklama.PSObject.Properties){ $yeniAck[$p.Name] = Onar "$($p.Value)" } }

  $kontrol = "$yeniSoru $yeniHap"
  if($yeniSik){ foreach($k in $yeniSik.Keys){ $kontrol += ' ' + "$($yeniSik[$k])" } }
  if($yeniAck){ foreach($k in $yeniAck.Keys){ $kontrol += ' ' + "$($yeniAck[$k])" } }

  if($reYunan.IsMatch($kontrol)){ $yunanli.Add($id) }          # Yunan: dokunmadik, raporda
  if($reKiril.IsMatch($kontrol)){ $elle.Add($id); continue }   # tablo yetmedi: YAZMA
  if(-not $uygula){ $duzelen++; continue }

  $govde = [ordered]@{ soru = $yeniSoru }
  if($null -ne $s.hap){ $govde['hap'] = $yeniHap }
  if($yeniSik){ $govde['siklar'] = $yeniSik }
  if($yeniAck){ $govde['aciklama'] = $yeniAck }
  try {
    Invoke-RestMethod -Method Patch -Uri "$U`?id=eq.$id" `
      -Headers ($BASLIK + @{ Prefer = "return=minimal" }) -ContentType "application/json" `
      -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 6))) -TimeoutSec 60 | Out-Null
    $duzelen++
  } catch {
    $hataYaz++
    $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
    if(-not $ilkHata){ $ilkHata = ("{0} | sunucu: {1} | id: {2}" -f $_.Exception.Message, $g, $id) }
    Write-Host ("YAZMA HATASI {0}: {1} | {2}" -f $id, $_.Exception.Message, $g)
  }
}

# --- geri okuma sayimi (yalniz -uygula'da anlamli)
$kalan = -1
if($uygula){
  $kalan = 0
  $offset = 0
  while($true){
    $u = "$U`?select=id,soru,siklar,aciklama,hap&order=id&limit=$sayfa&offset=$offset"
    $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 180
    $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
    $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
    if(-not $parti.Count){ break }
    foreach($s in $parti){
      $tum = "$($s.soru) $($s.hap)"
      if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $tum += ' ' + "$($p.Value)" } }
      if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }
      if($reKiril.IsMatch($tum)){ $kalan++ }
    }
    if($parti.Count -lt $sayfa){ break }
    $offset += $sayfa
  }
}

Yaz ([ordered]@{
  tarih   = (Get-Date -Format "dd.MM.yyyy HH:mm")
  durum   = $(if($uygula){ if($hataYaz -gt 0){'KISMI'} else {'TAMAM'} } else { 'OLCUM' })
  mod     = $(if($uygula){ 'uygula' } else { 'olcum' })
  taranan = $hepsi
  homoglifli = $vurgun.Count
  duzelen = $duzelen
  yazma_hatasi = $hataYaz
  ilk_hata = $ilkHata
  elle_kalan = @($elle)
  yunan_raporu = @($yunanli)
  geri_okuma_kiril_kalan = $kalan
})
Write-Host ("Duzelen: {0} | elle kalan: {1} | Yunan raporu: {2} | yazma hatasi: {3} | geri-okuma Kiril kalan: {4}" -f $duzelen, $elle.Count, $yunanli.Count, $hataYaz, $kalan)
