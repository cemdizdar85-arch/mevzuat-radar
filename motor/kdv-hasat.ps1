# ============================================================================
#  KDV HASAT - 2007/13033 (I) ve (II) sayili liste -> fasil/pozisyon indeksi
#  Kaynak: GİB guncel konsolide metin (kdv-oranlari-gib.txt, 9126 s. CK dahil)
#  ONEMLI (rakam disiplini): KDV listesi 12 haneli koda TEK oran vermez.
#    Fasil / pozisyon / tam kod + ISTISNA ('haric') karisik yazilmistir.
#    Bu yuzden "kesin oran" UYDURULMAZ. Her hukmun METNI birebir saklanir,
#    kodun fasil/pozisyonuna gore ilgili hukumler gosterilir, karar kullaniciya.
#  Cikti: veri\gtip-kdv.json = {
#    "fasil": { "01": { "o1":[{"m":metin,"poz":[...]}], "o10":[...] } , ... },
#    "not": "listede yoksa %20"
#  }
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$src  = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\kdv-oranlari-gib.txt"
$t = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::GetEncoding(1254))
$t = $t -replace '\s+',' '

# --- liste sinirlari ---
$iIdx  = $t.IndexOf("(I) SAYILI L")
$iiIdx = $t.IndexOf("(II) SAYILI L")
$dipIdx = ([regex]::Match($t,"Değişmeden önceki şekli")).Index
if($iIdx -lt 0 -or $iiIdx -lt 0 -or $dipIdx -lt 0){ throw "Liste sinirlari bulunamadi" }
$listeI  = $t.Substring($iIdx, $iiIdx - $iIdx)
$listeII = $t.Substring($iiIdx, $dipIdx - $iiIdx)

# --- bir hukum metninden fasil/pozisyon/tamkod referanslarini cikar ---
function Refler([string]$metin){
  $fasillar = New-Object System.Collections.Generic.HashSet[string]
  $pozlar   = New-Object System.Collections.Generic.HashSet[string]
  $calisma = $metin

  # 1) TAM 12 HANELI KOD: NNNN.NN.NN.NN.NN -> fasil(ilk2) + pozisyon(ilk4). Sonra MASKELE
  #    (icindeki .90.50 gibi ciftler pozisyon sanilmasin)
  foreach($m in [regex]::Matches($calisma, '\b(\d{2})(\d{2})\.\d{2}\.\d{2}\.\d{2}\.\d{2}\b')){
    $f = $m.Groups[1].Value
    if([int]$f -ge 1 -and [int]$f -le 97){ [void]$fasillar.Add($f); [void]$pozlar.Add($f + $m.Groups[2].Value) }
  }
  $calisma = [regex]::Replace($calisma, '\b\d{4}\.\d{2}\.\d{2}\.\d{2}\.\d{2}\b', ' # ')

  # 2) TARIHLERI MASKELE: GG.AA.YYYY / GG/AA/YYYY / AA/YYYY (pozisyon sanilmasin!)
  $calisma = [regex]::Replace($calisma, '\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b', ' # ')
  $calisma = [regex]::Replace($calisma, '\b\d{1,2}/\d{4}\b', ' # ')

  # 3) "N no.lu fasil" / "NN no.lu faslinda" -> fasil
  foreach($m in [regex]::Matches($calisma, '(\d{1,2})\s*no\.?\s*lu\s*fas')){
    $f = [int]$m.Groups[1].Value; if($f -ge 1 -and $f -le 97){ [void]$fasillar.Add($f.ToString("00")) }
  }
  # 4) STANDALONE pozisyon "NN.NN" (kod/tarih maskelendi) -> fasil + pozisyon
  foreach($m in [regex]::Matches($calisma, '\b(\d{2})\.(\d{2})\b')){
    $f = $m.Groups[1].Value
    if([int]$f -ge 1 -and [int]$f -le 97){ [void]$fasillar.Add($f); [void]$pozlar.Add($f + $m.Groups[2].Value) }
  }
  return @{ fasillar = @($fasillar); pozlar = @($pozlar) }
}

# --- liste govdesini HUKUMLERE bol (madde no + '-' ile baslayanlar) ---
# ornek baslangiclar: "1 - ", "2- ", "13- a) ", "23-"
function Hukumler([string]$govde){
  # madde numaralari '<num>- ' seklinde (referans rakamlariyla karismasin diye
  # ONCESINDE bosluk/virgul/parantez + SONRASINDA '- ' araniyor). Pozisyon 'NN.NN'
  # nokta icerdigi icin, tam kodlar noktali oldugu icin bunlara takilmaz.
  $parcalar = [regex]::Split($govde, '(?<=[ ,;)])(?=\d{1,3}\s*-\s)')
  $sonuc = @()
  foreach($p in $parcalar){
    $p = $p.Trim()
    if($p.Length -lt 8){ continue }
    $sonuc += $p
  }
  return $sonuc
}

# --- fasil indeksini kur ---
$fasil = @{}
function Ekle([string]$govde, [string]$oranEtiket){
  $script:sayacHukum = 0
  foreach($h in (Hukumler $govde)){
    $r = Refler $h
    if($r.fasillar.Count -eq 0){ continue }   # hicbir fasla baglanamayan genel hukum -> atla (kod sorgusunda gosterilemez)
    $kisa = $h
    if($kisa.Length -gt 1400){ $kisa = $kisa.Substring(0,1400) + "… (devamı için resmî listeyi açın)" }
    foreach($f in $r.fasillar){
      if(-not $fasil.ContainsKey($f)){ $fasil[$f] = @{ o1=@(); o10=@() } }
      $kayit = @{ m = $kisa; poz = $r.pozlar }
      if($oranEtiket -eq "1"){ $fasil[$f].o1 += $kayit } else { $fasil[$f].o10 += $kayit }
    }
    $script:sayacHukum++
  }
  return $script:sayacHukum
}

$n1  = Ekle $listeI  "1"
$n10 = Ekle $listeII "10"

# --- JSON ---
$out = [ordered]@{
  guncelleme = "GİB güncel konsolide metin (2007/13033, 9126 s. CK dahil)"
  genelOran = 20
  not = "Listede yer almayan mal ve hizmetlerde genel oran %20'dir. Aşağıdaki hükümler kodun faslına/pozisyonuna değiniyor; kesin oran ürünün tanımına ve 'hariç' istisnalarına bağlıdır — hükmü okuyun."
  fasil = [ordered]@{}
}
foreach($f in ($fasil.Keys | Sort-Object)){ $out.fasil[$f] = $fasil[$f] }

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
$hedef = Join-Path $veriDir "gtip-kdv.json"
($out | ConvertTo-Json -Depth 6 -Compress) | Out-File $hedef -Encoding utf8

""
"KDV HASAT BITTI."
"  (I) %1  liste: $n1 hukum"
"  (II) %10 liste: $n10 hukum"
"  Fasil sayisi (indekslenen): $($fasil.Count)"
"veri\gtip-kdv.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
""
"--- DOGRULAMA fasil 87 (otomobil) %10 hukumleri ---"
if($fasil.ContainsKey("87")){ foreach($k in $fasil["87"].o10){ "  [poz: $($k.poz -join ',')] " + $k.m.Substring(0,[Math]::Min(160,$k.m.Length)) } }
"--- fasil 01 (canli hayvan) %1 ---"
if($fasil.ContainsKey("01")){ foreach($k in $fasil["01"].o1){ "  " + $k.m.Substring(0,[Math]::Min(160,$k.m.Length)) } }
