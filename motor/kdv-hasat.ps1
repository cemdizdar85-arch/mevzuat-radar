# ============================================================================
#  KDV HASAT v2 - 2007/13033 (I)%1 ve (II)%10 -> fasil/pozisyon indeksi
#  Kaynak: GİB guncel konsolide metin (kdv-oranlari-gib.txt, 9126 s. CK dahil)
#
#  v1'de yakalanan HATALAR (elle denetim, Cem 12.07.2026) ve DUZELTMELERI:
#   - Liste II sonu DIPNOT/KORELASYON blogu ("GTİP güncellemesi","korelasyonu",
#     "TGTC' de") maddelere yapisip sahte pozisyon bagliyordu -> blok KESILIR.
#   - Mulga/degisiklik metni ("Değişmeden önceki", "N sayılı ... Yürürlük")
#     -> SILINIR. Bare dipnot no "(NN)" -> silinir.
#   - "hariç" istisna pozisyonlari kapsamda sanilyordu (8517 tibbi cihazdan
#     haric ama poz'a giriyordu) -> "( ... hariç)" span'lari SCOPE'tan cikarilir.
#   - Bosluklu tam kod "8428 90.71 00 00" -> "90.71" pozisyon sanilip fasil 90'a
#     baglaniyordu -> bosluklu/noktali TAM KODLAR once maskelenir (ilk4=poz).
#  KURAL: kesin oran UYDURULMAZ; temizlenmis hukum METNI gosterilir.
#  Cikti: veri\gtip-kdv.json = { fasil:{ "NN":{o1:[{m,poz}],o10:[...]} }, ... }
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

# --- HUKUM METNINI TEMIZLE ---
# 1) dipnot/korelasyon blogunu KES (ilk gucu isaretten itibaren at)
$kesIsaretleri = @(
  "GTİP güncellemesi", "korelasyonu", "Korelasyonu", "TGTC'",
  "Değişmeden önceki", "değişmeden önceki", "kaldırılmadan önceki",
  "sayılı listenin ", "uncu sıradaki", "uncu sırada ", "nci sırada ", "sayılı listenin…"
)
function KesBlok([string]$m){
  $enErken = $m.Length
  foreach($isaret in $kesIsaretleri){
    $ix = $m.IndexOf($isaret)
    if($ix -ge 0 -and $ix -lt $enErken){ $enErken = $ix }
  }
  if($enErken -lt $m.Length){ $m = $m.Substring(0, $enErken) }
  return $m
}
# 2) degisiklik atiflari + dipnot no + koseli parantez + tirnak -> sil
function Temizle([string]$m){
  $m = KesBlok $m
  $m = [regex]::Replace($m, '\[[^\]]*\]', ' ')                       # [ ... ] koseli blok
  $m = [regex]::Replace($m, '\([^()]*\bsayılı\b[^()]*\)', ' ')        # (... sayılı Kararname/BKK/CK ...)
  $m = [regex]::Replace($m, '\(\s*Yürürlük[^)]*\)', ' ')             # (Yürürlük: ...)
  $m = [regex]::Replace($m, '\(\s*\d{1,3}\s*\)', ' ')                # bare dipnot no (14)
  $m = [regex]::Replace($m, '\s*"\s*', ' ')                          # stray tirnak
  $m = [regex]::Replace($m, '[AB]\)\s*(GIDA MADDELERİ|DİĞER MAL VE HİZMETLER)', ' ')  # bolum basligi sizintisi
  $m = [regex]::Replace($m, '\s+', ' ').Trim()
  $m = [regex]::Replace($m, '^\s*[,;]\s*', '')
  $m = $m.TrimEnd(' ',',',';')
  return $m
}
# scope metni: "( ... hariç)" istisnalarini da CIKAR (kapsam pozisyonu sanilmasin)
function ScopeMetin([string]$mTemiz){
  return [regex]::Replace($mTemiz, '\([^()]*hariç[^()]*\)', ' ')
}
# "( ... hariç)" span'larindaki KODLARI cikar -> bu hukumden HARIC tutulacaklar.
#  (Sus baligi 0301.10, belli yumurta 0408.x tumF=fasil olsa da %1 DEGIL.) Ayni hukumde
#  ACIKCA listelenen kod (or. sakiz 1704.90.30, madde 13b) haric'i ezer -> eslestirmede kod ONCE bakilir.
function HaricKodlari([string]$metin){
  $set = New-Object System.Collections.Generic.HashSet[string]
  foreach($sp in [regex]::Matches($metin, '\([^()]*hariç[^()]*\)')){
    $span = $sp.Value
    # 8-12 hane tam kod -> yakala, sonra DUZ maskele (yoksa "1704.90.30.00.00" -> "9030","0000" copu)
    foreach($m in [regex]::Matches($span, '\b(\d{2})(\d{2})([\s.]\d{2}[\s.]\d{2}(?:[\s.]\d{2}){0,2})\b')){ [void]$set.Add(($m.Value -replace '[^\d]','')) }
    $span = [regex]::Replace($span, '\b(\d{2})(\d{2})([\s.]\d{2}[\s.]\d{2}(?:[\s.]\d{2}){0,2})\b', ' # ')
    # 6-hane NNNN.NN -> yakala, sonra maskele
    foreach($m in [regex]::Matches($span, '\b(\d{2})(\d{2})\.(\d{2})\b')){ [void]$set.Add($m.Groups[1].Value+$m.Groups[2].Value+$m.Groups[3].Value) }
    $span = [regex]::Replace($span, '\b(\d{2})(\d{2})\.(\d{2})\b', ' # ')
    # standalone NN.NN -> tum pozisyon (or. "84.02 hariç")
    foreach($m in [regex]::Matches($span, '\b(\d{2})\.(\d{2})\b')){ [void]$set.Add($m.Groups[1].Value+$m.Groups[2].Value) }
  }
  # GUVENLIK: bos/kisa (<4 hane) kod ELENIR — yoksa StartsWith('') tum fasli yanlislikla dislar.
  return @($set | Where-Object { $_ -and $_.Length -ge 4 })
}

# --- referans cikar: fasil(tum bolum) + poz(tum 4-hane) + kod(spesifik) AYRI ---
#  KRITIK (8480 bulgusu): "84.02" = tum 8402 pozisyonu; "8480.71.00.00.00" = SADECE o kod.
#  Ikisini karistirmak yanlisa yol acar (8480.71 %1 ama 8480.90 %20). O yuzden ayirt edilir.
function Refler([string]$metin){
  $fasillar    = New-Object System.Collections.Generic.HashSet[string]
  $tumFasillar = New-Object System.Collections.Generic.HashSet[string]   # "N no.lu fasil" = tum bolum
  $pozlar      = New-Object System.Collections.Generic.HashSet[string]   # "NN.NN" = tum 4-hane pozisyon
  $kodlar      = New-Object System.Collections.Generic.HashSet[string]   # spesifik tam kod (6-12 hane)
  $calisma = $metin
  # 1) TAM/ALT KOD (8-12 hane, nokta/bosluk ayracli) -> fasil + SPESIFIK kod (ilk4 poz'a DEGIL). Maskele.
  $kodRx = '\b(\d{2})(\d{2})([\s.]\d{2}[\s.]\d{2}(?:[\s.]\d{2}){0,2})\b'
  foreach($m in [regex]::Matches($calisma, $kodRx)){
    $f=$m.Groups[1].Value
    if([int]$f -ge 1 -and [int]$f -le 97){
      [void]$fasillar.Add($f)
      $full = ($m.Value -replace '[^\d]','')   # spesifik kodun tam hanesi
      [void]$kodlar.Add($full)
    }
  }
  $calisma = [regex]::Replace($calisma, $kodRx, ' # ')
  # 2) 6-hane alt-baslik "NNNN.NN" ( or 8432.30) -> spesifik kod
  foreach($m in [regex]::Matches($calisma, '\b(\d{2})(\d{2})\.(\d{2})\b')){
    $f=$m.Groups[1].Value
    if([int]$f -ge 1 -and [int]$f -le 97){ [void]$fasillar.Add($f); [void]$kodlar.Add($m.Groups[1].Value+$m.Groups[2].Value+$m.Groups[3].Value) }
  }
  $calisma = [regex]::Replace($calisma, '\b\d{4}\.\d{2}\b', ' # ')
  # 3) tarih maskele
  $calisma = [regex]::Replace($calisma, '\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b', ' # ')
  # 4) "N no.lu fasil" -> TUM bolum. AMA "yalnız" (secmeli) VEYA "faslin [kod] POZISYONUNDA"
  #    (spesifik) ise tum fasil DEGIL — kodlar zaten ayri yakalandi. (F22 icecek/alkol, F12
  #    yagli tohum, F5/23/25 = cimento vb. tuzagi). Ozellik-tabanli fasillar (F15 yag, F6 cicek)
  #    "mallar/pozisyon" icermez -> mevcut haliyle tumF kalir, yanlis-negatif olmaz.
  foreach($m in [regex]::Matches($calisma, '(\d{1,2})\s*no\.?\s*lu\s*fas')){
    $f=[int]$m.Groups[1].Value
    if($f -ge 1 -and $f -le 97){
      [void]$fasillar.Add($f.ToString("00"))
      $ctx = $calisma.Substring($m.Index, [Math]::Min(70, $calisma.Length - $m.Index))
      $secmeli = $false
      if($ctx -match 'yalnız'){ $secmeli = $true }
      else {
        $pm = $ctx.IndexOf('mallar'); $pp = $ctx.IndexOf('pozisyon')
        if($pp -ge 0 -and ($pm -lt 0 -or $pp -lt $pm)){ $secmeli = $true }   # "mallar"dan ONCE "pozisyon" = spesifik
      }
      if(-not $secmeli){ [void]$tumFasillar.Add($f.ToString("00")) }
    }
  }
  # 5) standalone "NN.NN" pozisyon -> TUM 4-hane pozisyon
  foreach($m in [regex]::Matches($calisma, '\b(\d{2})\.(\d{2})\b')){
    $f=$m.Groups[1].Value; if([int]$f -ge 1 -and [int]$f -le 97){ [void]$fasillar.Add($f); [void]$pozlar.Add($f+$m.Groups[2].Value) }
  }
  return @{ fasillar=@($fasillar); tumFasillar=@($tumFasillar); pozlar=@($pozlar); kodlar=@($kodlar) }
}

function Hukumler([string]$govde){
  $parcalar = [regex]::Split($govde, '(?<=[ ,;)])(?=\d{1,3}\s*-\s)')
  $sonuc=@(); foreach($p in $parcalar){ $p=$p.Trim(); if($p.Length -ge 8){ $sonuc+=$p } }; return $sonuc
}

$fasil = @{}
function Ekle([string]$govde, [string]$oranEtiket){
  $script:sayac=0
  foreach($ham in (Hukumler $govde)){
    $mTemiz = Temizle $ham
    if($mTemiz.Length -lt 10){ continue }
    $r = Refler (ScopeMetin $mTemiz)     # kapsam: haric cikarilmis metinden
    if($r.fasillar.Count -eq 0){ continue }   # koda baglanamayan (hizmet vb.) -> atla
    $goster = $mTemiz
    if($goster.Length -gt 700){ $goster = $goster.Substring(0,700) + "… (devamı resmî listede)" }
    $anahtar = ($goster.Substring(0,[Math]::Min(50,$goster.Length)))   # tekrar ayiklama anahtari
    $haricKod = HaricKodlari $mTemiz    # "(... hariç)" kodlari — bu hukumden cikarilir (kod acikca varsa ezilir)
    foreach($f in $r.fasillar){
      if(-not $fasil.ContainsKey($f)){ $fasil[$f]=@{ o1=@(); o10=@() } }
      $hedefListe = if($oranEtiket -eq "1"){ $fasil[$f].o1 } else { $fasil[$f].o10 }
      $varMi = $false
      foreach($mevcut in $hedefListe){ if($mevcut.m.Substring(0,[Math]::Min(50,$mevcut.m.Length)) -eq $anahtar){ $varMi=$true; break } }
      if($varMi){ continue }
      # tumF: bu hukum, bu FASLI tumuyle mi kapsiyor ("N no.lu fasil")? poz/kod: spesifik eslesme
      # kosul: uygulanabilirligi KODDAN anlasilmayan bir sarta bagli mi (or. "yalniz KULLANILMIS
      #  tasitlar" = gumruk statusu, urun degil). Boyle hukumler pozisyonu topluca indirimli YAPMAZ;
      #  ayri "kosula bagli" gosterilir (8703 dersi: yeni binek oto %20, yalniz kullanilmis %1).
      # NOT: kosul yalnizca hukmun KONU CUMLESINDE (bas ~130 karakter) aranir. Uzun bir %1
      #  makine listesinin (item 17) derinlerinde gecen "kullanilmis" ifadesi tum hukmu kosullu
      #  yapmasin — yoksa 8480.71 plastik kalip %1 yanlislikla genel olur.
      $bas = if($mTemiz.Length -gt 130){ $mTemiz.Substring(0,130) } else { $mTemiz }
      $kosul = [bool]([regex]::IsMatch($bas,'yalnız\s+kullanılmış') -or $bas.Contains('kullanılmış olanlar'))
      $kayit=@{ m=$goster; poz=$r.pozlar; kod=$r.kodlar; tumF=([bool](@($r.tumFasillar) -contains $f)); kosul=$kosul; haric=$haricKod }
      if($oranEtiket -eq "1"){ $fasil[$f].o1+=$kayit } else { $fasil[$f].o10+=$kayit }
    }
    $script:sayac++
  }
  return $script:sayac
}

$n1  = Ekle $listeI  "1"
$n10 = Ekle $listeII "10"

$out = [ordered]@{
  guncelleme = "GİB güncel konsolide metin (2007/13033, 9126 s. CK dahil)"
  genelOran = 20
  not = "Listede yer almayan mal ve hizmetlerde genel oran %20'dir. Aşağıdaki hükümler kodun faslına/pozisyonuna değiniyor; kesin oran ürünün tanımına ve 'hariç' istisnalarına bağlıdır — hükmü okuyun. Değişiklik/mülga metinler ve dipnotlar ayıklanmıştır; tam metin için GİB'e bakın."
  fasil = [ordered]@{}
}
foreach($f in ($fasil.Keys | Sort-Object)){ $out.fasil[$f] = $fasil[$f] }
$veriDir = Join-Path $kok "veri"
$hedef = Join-Path $veriDir "gtip-kdv.json"
($out | ConvertTo-Json -Depth 6 -Compress) | Out-File $hedef -Encoding utf8

""
"KDV HASAT v2 BITTI."
"  (I)%1: $n1 hukum | (II)%10: $n10 hukum | fasil: $($fasil.Count)"
"veri\gtip-kdv.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
