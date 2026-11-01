#requires -Version 5.1
<#
================================================================================
  D7 YILI HAD LİSTESİ — veri/sinav/had-d7.json   01.11.2026 · bedel 0 (yalnız ambar okuma, model yok)

  NEDEN (Ajan 38 ölçümü, BITIRME-SORU-STANDARDI.md D7 — Cem 30.10 "2026 sınavı 2025 tutarını sorar"): KAPI-HAD bitirme yayın
  şartında "güncel had"i kanun maddesinin konsolide şerhinden (had-guncel.json = 2026 tutarı) alıyordu; 2025 tutarını DOĞRU
  yazan soru düşüyordu (smmm-w4-yvergi-kolay/kp-03 GT 577 EK m.153/A 990.000 · smmm-4k-a-yvergi-kolay-r10/kp-06 m.370 700.000).
  Bu betik D7 yılının RESMÎ listesini ambardan okur:
    · VUK: "VUK GT <no> EK (1.1.<Yıl> had ve tutarlari listesi) m.N" kayıtları (2025 = GT 577). Kayıt metni "MADDE N - … : tutar"
      bölümlerine ayrılır; bir kayıtta birden çok madde olabilir (m.177 kaydında MADDE 232 ve 252 de var) → her biri kendi maddesine.
    · GVK: yeniden değerleme tebliğinin m.3'ü (2025 = Seri No 329; metin "<Yıl> takvim yılında uygula…" demeli, demezse DURUR).
      Bentler "a) 9 uncu maddesinin … 1.580.000 TL" → 193|9; tarife (103) ve mükerrer 121 fıkraları da.
  Biçim had-guncel.json ile aynı (maddeler: anahtar → [{tutar, baglam}]); okuyan arac/had-kapisi.ps1 HadD7HaritaOku (YALNIZ
  'smmm-' anahtarlı yayın şartı yolu). had-guncel.json'a DOKUNMAZ (KGK yolu onu okur).
  2027 sınavına geçişte: -Yil 2026 -GvkTeblig '<2026 tebliği> m.3' (sınav yılı − 1; D7 son maddesi).
  🚫 GÖRMEZ: listede olmayan tebliğ tutarları (KDV GUT, Harçlar, Damga, SGK, asgari ücret, kıdem tavanı) · yazıyla tutar.
  KULLANIM: powershell -NoProfile -File arac/had-d7-kur.ps1 [-Yil 2025] [-GvkTeblig '…'] [-Kuru]
================================================================================
#>
param([int]$Yil = 2025, [string]$GvkTeblig = 'GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO: 329) m.3', [switch]$Kuru)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'had-kapisi.ps1')   # HadKokler
$anahtarS = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarS) { $anahtarS = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY', 'User'))".Trim() }
if (-not $anahtarS) { throw 'SUPABASE_SERVICE_KEY yok — ambar okunamaz' }
$basliklar = @{ apikey = $anahtarS; Authorization = "Bearer $anahtarS"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
function AmbarOku([string]$desen) {
  $u = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id,kaynak_ad,metin&kaynak_ad=like.$([uri]::EscapeDataString($desen))&order=kaynak_ad&limit=500"
  $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $basliklar -TimeoutSec 120
  return @((ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))) | ForEach-Object { $_ })
}
# parçalı kayıtlar ("… m.353 [1/2]", "[2/2]") sırayla birleşir
function Birlestir($kayitlar) {
  $g = [ordered]@{}
  foreach ($k in @($kayitlar | Sort-Object @{ e = { "$($_.kaynak_ad)" -replace '\s*\[\d+/\d+\]\s*$', '' } }, @{ e = { $m = [regex]::Match("$($_.kaynak_ad)", '\[(\d+)/\d+\]\s*$'); if ($m.Success) { [int]$m.Groups[1].Value } else { 0 } } })) {
    $ad = "$($k.kaynak_ad)" -replace '\s*\[\d+/\d+\]\s*$', ''
    if (-not $g.Contains($ad)) { $g[$ad] = [pscustomobject]@{ ad = $ad; metin = ''; id = @() } }
    $g[$ad].metin = ("$($g[$ad].metin) $($k.metin)").Trim(); $g[$ad].id += "$($k.id)"
  }
  return @($g.Values)
}
$BOS_EK = @{}; foreach ($w in 'madde muker inci ncu uncu uncu ikinc birin fikra bendi bentl numar yer alan maddes'.Split(' ')) { $BOS_EK[$w] = 1 }
function Baglam([string]$birim, [int]$konum) { $b = [Math]::Max(0, $konum - 120); return @(HadKokler $birim.Substring($b, $konum - $b) | Where-Object { -not $BOS_EK.ContainsKey($_) } | Sort-Object -Unique) }
$had = @{}
function Ekle([string]$anahtar, [double]$tutar, [string[]]$baglam) {
  if ($tutar -lt 1000) { return }
  if (-not $had.ContainsKey($anahtar)) { $had[$anahtar] = [ordered]@{} }
  $k = "$tutar"; if (-not $had[$anahtar].Contains($k)) { $had[$anahtar][$k] = @{} }
  foreach ($x in $baglam) { $had[$anahtar][$k][$x] = 1 }
}
function Sayi([string]$s) { return [double](($s -replace '\.', '') -replace ',', '.') }
$kaynaklar = New-Object System.Collections.Generic.List[object]

# --- VUK: 1.1.<Yıl> had ve tutarlar listesi
$vuk = @(AmbarOku "VUK GT * EK (1.1.$Yil had ve tutarlari listesi)*")
if ($vuk.Count -lt 10) { throw "VUK 1.1.$Yil had listesi ambarda eksik ($($vuk.Count) kayıt) — dosya YAZILMADI" }
foreach ($b in (Birlestir $vuk)) {
  $kaynaklar.Add([ordered]@{ ad = $b.ad; parca = $b.id.Count })
  # bölüm başları soldan sağa eşlenir ("EK MADDE 1 -" tek baş; Split'in ileri bakışı "EK " önekini ayrı parçaya düşürürdü)
  $baslar = @([regex]::Matches($b.metin, '(?:MÜKERRER\s+|EK\s+)?MADDE\s+\d+(?:/[A-Z])?\s*-'))
  for ($i = 0; $i -lt $baslar.Count; $i++) {
    $son = $(if ($i + 1 -lt $baslar.Count) { $baslar[$i + 1].Index } else { $b.metin.Length }); $bol = $b.metin.Substring($baslar[$i].Index, $son - $baslar[$i].Index)
    $bm = [regex]::Match($bol, '^(MÜKERRER\s+|EK\s+)?MADDE\s+(\d+)'); if (-not $bm.Success) { continue }
    $anahtar = "213|$(if ($bm.Groups[1].Value -match '^EK') { 'ek' })$([int]$bm.Groups[2].Value)"
    foreach ($m in [regex]::Matches($bol, '(?<![\d.,])(\d{1,3}(?:\.\d{3})+)(?![\d,])')) { Ekle $anahtar (Sayi $m.Groups[1].Value) (Baglam $bol $m.Index) }
  }
}
# --- GVK: yeniden değerleme tebliği m.3
$gvk = @(AmbarOku "$GvkTeblig*")
$gb = @(Birlestir $gvk | Where-Object { $_.ad -eq $GvkTeblig })
if ($gb.Count -ne 1) { throw "GVK tebliği '$GvkTeblig' ambarda bulunamadı ($($gb.Count)) — dosya YAZILMADI" }
if ($gb[0].metin -notmatch "$Yil\s+takvim\s+y[ıi]l[ıi]nda\s+uygula") { throw "GVK tebliği '$GvkTeblig' $Yil takvim yılı tutarlarını belirtmiyor — yanlış tebliğ, dosya YAZILMADI" }
$kaynaklar.Add([ordered]@{ ad = $gb[0].ad; parca = $gb[0].id.Count })
$ordinal = '(?:inci|ıncı|nci|ncı|uncu|üncü|ncü|ncu)'
foreach ($birim in [regex]::Split($gb[0].metin, "\s(?=[a-zçğıöşü]\)\s+(?:Mükerrer\s+)?\d+\s*$ordinal\s+maddes)|\s(?=\(\d\)\s+(?:193|\d{4})\s)")) {
  $mm = [regex]::Match($birim, "(?i)(\d+)\s*$ordinal\s+maddes"); if (-not $mm.Success) { continue }
  $anahtar = "193|$([int]$mm.Groups[1].Value)"
  foreach ($m in [regex]::Matches($birim, '(?<![\d.,])(\d{1,3}(?:\.\d{3})+)\s*TL')) { Ekle $anahtar (Sayi $m.Groups[1].Value) (Baglam $birim $m.Index) }
}
if (-not $had.ContainsKey('213|370') -or -not $had.ContainsKey('193|103')) { throw 'D7 listesi eksik ayrıştı (213|370 ya da 193|103 yok) — dosya YAZILMADI' }
$md = [ordered]@{}
foreach ($a in ($had.Keys | Sort-Object)) { $md[$a] = @($had[$a].Keys | Sort-Object { [double]$_ } | ForEach-Object { [ordered]@{ tutar = [double]$_; baglam = @($had[$a][$_].Keys | Sort-Object) } }) }
$cikti = [ordered]@{
  aciklama = "D7 yılı ($Yil) resmî had ve tutarları: ambardaki VUK 1.1.$Yil had listesi + GVK yeniden değerleme tebliği m.3. Üreten arac/had-d7-kur.ps1; okuyan arac/had-kapisi.ps1 HadD7HaritaOku (yalnız SMMM yayın şartı yolu, KAPI-HAD)."
  yil = $Yil; olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynaklar = $kaynaklar.ToArray(); maddeler = $md }
$top = (@($md.Values | ForEach-Object { @($_).Count }) | Measure-Object -Sum).Sum
"D7 $Yil had listesi: $($md.Count) madde · $top tutar · $($kaynaklar.Count) kaynak"
if ($Kuru) { 'KURU — dosya yazılmadı'; return }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\had-d7.json'), (ConvertTo-Json -InputObject $cikti -Depth 5), (New-Object Text.UTF8Encoding $false))
'yazıldı: veri/sinav/had-d7.json'
