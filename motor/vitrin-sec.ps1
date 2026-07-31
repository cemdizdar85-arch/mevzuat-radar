# ============================================================================
#  VITRIN SECICI - kayitsiz ziyaretcinin gordugu ORNEK BANKAYI kurar.
#  (31.07 Cem onayi: "150'lik havuz uygun; cok cikan konular + en cok
#  zorlanilan dersler [Maliyet gibi] mukemmel anlatilmis olsun".)
#
#  !!! BILINCLI IFSA: bu betik kasadaki 150 soruyu HERKESE ACIK dosyaya
#  (veri/soru-bankasi.json) yazar - kontrollu reklam stoku, Cem 31.07 onayi.
#  150 disinda ucretli soru public'e YAZILMAZ (tavan asilirsa exit 1).
#
#  Secim kapilari: hakem destek=evet (zorunlu) + koku izi yok + puanlama:
#    +2 senaryolu (unvan/isim)  +2 rakamli  +1 hap dolu  +1 bes aciklama dolu
#  Kota: SGS 75 + Yeterlilik 75; hesap dersleri (Maliyet/Finansal/Mali Tablolar)
#  cift kota (Cem: zorlanilan dersler agirlikli). ENV: SUPABASE_SERVICE_KEY.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

$TAVAN = 150

# hakem: yalniz destek=evet
$hh = Get-Content (Join-Path $kok 'veri/hakem-hasadi.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$evet = @{}
foreach($p in $hh.yargilar.PSObject.Properties){ if("$($p.Value.destek)" -eq 'evet'){ $evet[$p.Name] = $true } }
Write-Host "hakem destek=evet: $($evet.Count)"

# koku izlileri disla
$izli = @{}
$kokuYol = Join-Path $kok 'veri/koku-izli.json'
if(Test-Path $kokuYol){
  try { $kj = Get-Content $kokuYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($k in @($kj.izli)){ $id = if($k -is [string]){ $k } else { "$($k.id)" }; if($id){ $izli[$id] = $true } } } catch {}
}
Write-Host "koku izli (dislanacak): $($izli.Count)"

function DoluMu($v, [int]$enAz){ return ("$v".Length -ge $enAz) }

# yayindaki sorulari sayfali cek
$aday = @()
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak&yayin=eq.true&limit=500&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
  $liste = @($ham | ConvertFrom-Json)
  if(-not $liste.Count){ break }
  foreach($s in $liste){
    $id = "$($s.id)"
    if(-not $evet.ContainsKey($id)){ continue }
    if($izli.ContainsKey($id)){ continue }
    if(-not $s.siklar -or -not $s.aciklama -or -not $s.dogru){ continue }
    $puan = 0
    $metin = "$($s.soru)"
    if($metin -match '(Ltd|A\.Ş|Şti|San\.|Tic\.)' -or $metin -match '\b(Usta|Bey|Hanım|Mehmet|Ayşe|Mustafa|Fatma|Ahmet|Hasan|Emine|Zeynep|Ramazan|Osman|Kemal|Elif|Murat)\b'){ $puan += 2 }
    if($metin -match '\d{1,3}(\.\d{3})+'){ $puan += 2 }
    if(DoluMu $s.hap 60){ $puan += 1 }
    $acikTam = $true
    foreach($h in @('A','B','C','D','E')){ if(-not (DoluMu $s.aciklama.$h 80)){ $acikTam = $false } }
    if($acikTam){ $puan += 1 }
    $aday += [pscustomobject]@{ s = $s; puan = $puan; sinav = "$($s.sinav)"; ders = "$($s.ders)" }
  }
  if($liste.Count -lt 500){ break }
  $ofs += 500
}
Write-Host "kapilari gecen aday: $($aday.Count)"

# kota: sinav basina 75; hesap dersleri cift pay
function HesapDersiMi([string]$d){ return ($d -match 'Maliyet|Finansal Muhasebe|Mali Tablo') }
$secim = @()
foreach($sinavAd in @($aday | Group-Object sinav | ForEach-Object { $_.Name })){
  $grup = @($aday | Where-Object { $_.sinav -eq $sinavAd })
  $dersler = @($grup | Group-Object ders)
  # ders kotalari: hesap dersi 12, digerleri 5 (75'i asarsa skor sirasiyla kirpilir)
  $sinavSecim = @()
  foreach($dg in $dersler){
    $kota = if(HesapDersiMi $dg.Name){ 12 } else { 5 }
    $sinavSecim += @($dg.Group | Sort-Object puan -Descending | Select-Object -First $kota)
  }
  # 75'e tamamla ya da kirp (skor oncelikli, hesap dersi one)
  $sinavSecim = @($sinavSecim | Sort-Object @{e={ HesapDersiMi $_.ders }; Descending=$true}, @{e={ $_.puan }; Descending=$true} | Select-Object -First 75)
  if($sinavSecim.Count -lt 75){
    $icinde = @{}; $sinavSecim | ForEach-Object { $icinde["$($_.s.id)"] = $true }
    $ek = @($grup | Where-Object { -not $icinde.ContainsKey("$($_.s.id)") } | Sort-Object puan -Descending | Select-Object -First (75 - $sinavSecim.Count))
    $sinavSecim += $ek
  }
  $secim += $sinavSecim
  Write-Host ("{0}: {1} soru secildi" -f $sinavAd, $sinavSecim.Count)
}

if($secim.Count -gt $TAVAN){ Write-Host "HATA: tavan asildi ($($secim.Count) > $TAVAN)"; exit 1 }
if($secim.Count -lt 60){ Write-Host "UYARI: yalniz $($secim.Count) aday - dosya GUNCELLENMEDI"; exit 0 }

# cikti: deneme.html'in bekledigi bicim (mevcut 8'lik dosyanin alanlari)
$sorular = @()
foreach($x in $secim){
  $s = $x.s
  $sorular += [ordered]@{
    id = "$($s.id)"; durum = 'yayin'; erisim = 'vitrin'
    sinav = "$($s.sinav)"; ders = "$($s.ders)"; konu = "$($s.konu)"
    soru = $s.soru; siklar = $s.siklar; dogru = $s.dogru
    aciklama = $s.aciklama; hap = $s.hap; kaynak = $s.kaynak
  }
}
$cikti = [ordered]@{
  aciklama = "VITRIN BANKASI - kayitsiz ziyaretci tadimi. Kasadan secilmis $($sorular.Count) soru (hakem onayli, senaryolu, hesap dersleri agirlikli). Bilincli olarak halka acik - Cem onayi 31.07.2026. Tavan: $TAVAN."
  guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
  sorular = $sorular
}
($cikti | ConvertTo-Json -Depth 8) | Out-File (Join-Path $kok 'veri/soru-bankasi.json') -Encoding utf8
Write-Host ("VITRIN: {0} soru -> veri/soru-bankasi.json" -f $sorular.Count)
