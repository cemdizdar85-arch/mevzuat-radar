#requires -Version 5.1
<#
  SMMM DERS ADI — OZ-SINAV  (22.09.2026)  bedel 0
  Niye: bu esleme bir AD YAZIMI yuzunden 58 odenmis soruyu ambara sokmadi. Sinav hem
  cozmesi gerekeni hem YANLIS COZMEMESI gerekeni olcer; ayrica AMBARDAKI GERCEK
  etiketlerin hepsinin cozuldugunu dogrular (kapsam olcusu - "bakmadigini da soyle").
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'smmm-ders-adi.ps1')

$vaka = @(
  # --- cozmesi gerekenler ---
  @{ e = 'smmm-w6-yvergi-zor'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-w6-fmuh-kolay'; b = 'Finansal Muhasebe' }
  @{ e = 'smmm-w6-yfta-cokzor'; b = 'Finansal Tablolar ve Analizi' }
  @{ e = 'smmm-w6-maliyet-zor'; b = 'Maliyet Muhasebesi' }
  @{ e = 'smmm-w6-ydenetim-kolay'; b = 'Muhasebe Denetimi' }
  @{ e = 'smmm-w6-yspk-zor'; b = 'Sermaye Piyasası Mevzuatı' }
  @{ e = 'smmm-w6-yhukuk-kolay'; b = 'Hukuk' }
  @{ e = 'smmm-w6-ymeslek-zor'; b = 'Meslek Hukuku' }
  # --- 22.09'da 58 soruyu rafta birakan 5 etiket ---
  @{ e = 'smmm-olc2-a-vergi'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-olc2-b-vergi'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-dog1-vergi'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-ab-a-hukuk'; b = 'Hukuk' }
  @{ e = 'smmm-ab-b-hukuk'; b = 'Hukuk' }
  # --- eski adlar ---
  @{ e = 'smmm-bosluk-vergimevzuat-1'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-gm-p2-fta'; b = 'Finansal Tablolar ve Analizi' }
  # --- YANLIS COZMEMESI gerekenler ---
  # 'y' oneki cakismasi: '-yvergi-' icinde '-vergi-' YOKTUR, ikisi ayri kalmali
  @{ e = 'smmm-x-yvergi-kolay'; b = 'Vergi Mevzuatı ve Uygulaması' }
  @{ e = 'smmm-x-yhukuk-kolay'; b = 'Hukuk' }
  @{ e = 'smmm-x-ymeslek-kolay'; b = 'Meslek Hukuku' }
  # ders kisaltmasi HIC yoksa bos doner (uydurmaz)
  @{ e = 'smmm-w9-genel-kolay'; b = '' }
  @{ e = 'sgs-t1-turkce'; b = '' }
  # kisaltma bir kelimenin ICINDE gecerse eslesmemeli (tire siniri)
  @{ e = 'smmm-vergilendirme-kolay'; b = '' }
  @{ e = 'smmm-hukuksal-zor'; b = '' }
)

$gecen = 0; $kalan = New-Object System.Collections.Generic.List[string]
foreach ($v in $vaka) {
  $c = SmmmDersAdi $v.e $null
  if ($c -eq $v.b) { $gecen++; if (-not $Sessiz) { "  OK    {0,-32} -> {1}" -f $v.e, $(if ($c) { $c }else { '(bos)' }) } }
  else { $kalan.Add(("{0} -> beklenen '{1}', cikan '{2}'" -f $v.e, $v.b, $c)); if (-not $Sessiz) { "  DUSTU {0,-32} -> '{1}' (beklenen '{2}')" -f $v.e, $c, $v.b } }
}

# parti icindeki 'ders' alanindan cozme (etiket tanimsizken)
$c2 = SmmmDersAdi 'smmm-bilinmeyen-parti' ([pscustomobject]@{ ders = 'Maliyet Muhasebesi ve Yonetim' })
if ($c2 -eq 'Maliyet Muhasebesi') { $gecen++; if (-not $Sessiz) { '  OK    parti icindeki ders alanindan cozer' } }
else { $kalan.Add("parti ders alanindan cozemedi: '$c2'") }

# slug
if ((SmmmDersSlug 'Vergi Mevzuatı ve Uygulaması') -eq 'vergi') { $gecen++; if (-not $Sessiz) { '  OK    slug dogru' } }
else { $kalan.Add('slug yanlis') }

# --- KAPSAM OLCUSU: ambardaki GERCEK etiketlerin kaci cozulemiyor ---
$depoKok = Split-Path -Parent $buDizin
$fab = Join-Path $depoKok 'veri\fabrika'
$korEtiket = New-Object System.Collections.Generic.List[string]
$bakilan = 0
if (Test-Path $fab) {
  foreach ($f in (Get-ChildItem $fab -Filter 'kalip-parti-smmm-*.json' -ErrorAction SilentlyContinue)) {
    $et = $f.BaseName -replace '^kalip-parti-', ''
    if ($et -match '(^|-)pilot\d*(-|$)') { continue }
    $bakilan++
    if (-not (SmmmDersAdi $et $null)) { $korEtiket.Add($et) }
  }
}
''
if ($bakilan) {
  "KAPSAM: yerel parti etiketi {0} · dersi COZULEMEYEN {1}" -f $bakilan, $korEtiket.Count
  if ($korEtiket.Count) {
    foreach ($k in ($korEtiket | Select-Object -First 8)) { Write-Host "   KOR: $k" -ForegroundColor Yellow }
    $kalan.Add("$($korEtiket.Count) yerel parti etiketinin dersi cozulemiyor - haritaya satir eklenmeli")
  }
}
else { 'KAPSAM: yerel parti dosyasi YOK - kapsam olculmedi (KOR)' }

''
"SMMM DERS ADI OZ-SINAVI: {0}/{1} gecti" -f $gecen, ($vaka.Count + 2)
if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
Write-Host 'YESIL' -ForegroundColor Green
exit 0
