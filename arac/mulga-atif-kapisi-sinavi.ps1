# KAPI-MA ÖZ-SINAVI (29.09.2026) — arac/mulga-atif-kapisi.ps1 MulgaAtifKapisi
# Vakalar UYDURMA kısa cümlelerdir (depo public). Liste de uydurma (SGS KAPI-MM listesiyle aynı biçim: kaynak_ad, iptal).
# Ayrıca: gerçek liste (veri/sinav/ambar-mulga-maddeler.json) VUK m.270'i taşıyor mu · kapı SMMM yayın şartına bağlı mı ·
# MUTASYON: kilit koşullar tek tek bozulur, her bozmada en az bir vaka DÜŞMELİ (CLAUDE.md kapı kuralı 8).
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$kapiMetin = [IO.File]::ReadAllText([IO.Path]::Combine($buDizin, 'mulga-atif-kapisi.ps1'), [Text.Encoding]::UTF8)
$gecici = [IO.Path]::Combine([IO.Path]::GetTempPath(), "ma-sinav-$PID.json")
[IO.File]::WriteAllText($gecici, (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{ maddeler = @(
  [ordered]@{ kaynak_ad = 'VUK (213 s.K.) m.270 - Gayrimaddi haklar'; iptal = 'Mülga: 14/10/2021-7338/29 md.'; kalan = '' },
  [ordered]@{ kaynak_ad = 'Damga V.K. (488 s.K.) m.12 - deneme'; iptal = 'Mülga: 1/1/2000-9999/1 md.'; kalan = '' }
) })), (New-Object Text.UTF8Encoding $false))

function S([string]$hap, $ek = @{}) { $o = [pscustomobject]@{ soru = 'İşletmenin taşıt maliyeti kaç TL''dir?'; siklar = [pscustomobject]@{ A = '1'; B = '2' }; dogru = 'A'; hap = $hap }; foreach ($k in $ek.Keys) { $o | Add-Member -NotePropertyName $k -NotePropertyValue $ek[$k] -Force }; return $o }
$VAKALAR = @(
  @{ ad = 'VUK m.270'; bek = $true; s = (S 'VUK m.270 mantığında nakliye maliyete girer.') }
  @{ ad = 'VUK (213 s.K.) m.270'; bek = $true; s = (S 'Dayanak: VUK (213 s.K.) m.270.') }
  @{ ad = 'VUK 270. madde'; bek = $true; s = (S 'VUK 270. madde uyarınca maliyete eklenir.') }
  @{ ad = 'Vergi Usul Kanunu 270. madde (tam ad)'; bek = $true; s = (S 'Vergi Usul Kanunu 270. madde mantığında taşıma gideri maliyettir.') }
  @{ ad = '213 sayılı … 270 inci madde'; bek = $true; s = (S '213 sayılı Kanunun 270 inci maddesine göre bu gider aktifleştirilir.') }
  @{ ad = 'iç içe teşhis alanında'; bek = $true; s = (S 'Maliyet hesaplanır.' @{ teshis = [pscustomobject]@{ A = [pscustomobject]@{ gercek = 'VUK m.270 bunu söyler.' } } }) }
  @{ ad = 'noktalı kısa ad (Damga V.K. m.12)'; bek = $true; s = (S 'Damga V.K. m.12 gereği vergi alınır.') }
  @{ ad = 'yürürlükteki m.262'; bek = $false; s = (S 'VUK m.262 uyarınca noter ve harç maliyete dahildir.') }
  @{ ad = 'm.2700 / m.27 değil'; bek = $false; s = (S 'VUK m.27 ve VUK m.2700 gibi numaralar atıf değildir.') }
  @{ ad = 'tutar 270 (madde değil)'; bek = $false; s = (S 'VUK kapsamında 270 TL nakliye gideri ödenmiştir.') }
  @{ ad = 'başka kanunun 270. maddesi (TTK)'; bek = $false; s = (S 'TTK 270. madde ile 6102 sayılı Kanunun 270 inci maddesi yürürlüktedir.') }
  @{ ad = 'iç alan: kaynak özeti'; bek = $false; s = (S 'Maliyet bedeli.' @{ kaynak_metin_ozet = 'VUK (213 s.K.) m.270 (Mülga)' }) }
  @{ ad = 'iç alan: atif_genisletme'; bek = $false; s = (S 'Maliyet bedeli.' @{ atif_genisletme = @('VUK (213 s.K.) m.270 - Gayrimaddi haklar') }) }
  @{ ad = 'iç alan: kaynak_adlar'; bek = $false; s = (S 'Maliyet bedeli nakliyeyi kapsar.' @{ kaynak_adlar = @('VUK (213 s.K.) m.270 - Gayrimaddi haklar') }) }
)

function VakaKos([string]$kapiKaynak) {
  $sb = [scriptblock]::Create("param(`$vakalar, `$listeYol)`n" + $kapiKaynak + "`n" + @'
$script:MA_LISTE = MaListeOku $listeYol
foreach ($v in $vakalar) { $b = @(MulgaAtifKapisi $v.s).Count -gt 0; [pscustomobject]@{ ad = $v.ad; bek = $v.bek; bulundu = $b; tamam = ($b -eq $v.bek) } }
'@)
  return @(& $sb $VAKALAR $gecici)
}

$kirmizi = 0
try {
  foreach ($r in (VakaKos $kapiMetin)) { if ($r.tamam) { "  YEŞİL  $($r.ad)" } else { $kirmizi++; Write-Host "  KIRMIZI $($r.ad) (beklenen $(if ($r.bek) { 'YAKALA' } else { 'GEÇ' }))" -ForegroundColor Red } }

  $gercek = [IO.Path]::Combine($depoKok, 'veri', 'sinav', 'ambar-mulga-maddeler.json')
  if (-not (Test-Path $gercek)) { $kirmizi++; Write-Host '  KIRMIZI gerçek liste yok (veri/sinav/ambar-mulga-maddeler.json)' -ForegroundColor Red }
  else { $gl = @((Get-Content $gercek -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler); if (@($gl | Where-Object { "$($_.kaynak_ad)" -match '^VUK \(213 s\.K\.\) m\.270\b' }).Count -ne 1) { $kirmizi++; Write-Host '  KIRMIZI gerçek listede VUK m.270 yok' -ForegroundColor Red } else { "  YEŞİL  gerçek liste: $($gl.Count) madde, VUK m.270 içinde" } }

  $y = [IO.Path]::Combine($depoKok, 'arac', 'smmm-yayin-sarti.ps1')
  if (([regex]::Matches([IO.File]::ReadAllText($y, [Text.Encoding]::UTF8), 'MulgaAtifKapisi\s+\$v')).Count -lt 1) { $kirmizi++; Write-Host '  KIRMIZI kapı SMMM yayın şartına bağlı değil' -ForegroundColor Red } else { '  YEŞİL  kapı bağlı: SMMM yayın şartı' }

  $MUTASYONLAR = @(
    @{ ad = 'desenler hiçbir şey tutmaz'; eski = '($desen -join ''|'')'; yeni = '''(?!)''' }
    @{ ad = 'iç alan listesi boş'; eski = '$script:MA_IC_ALAN = @('; yeni = '$script:MA_IC_ALAN = @(''-''); $null = @(' }
    @{ ad = 'madde sonu kontrolü kapalı (m.2700)'; eski = '(?:m\.|md\.|madde)\s*$md(?![\d/])'; yeni = '(?:m\.|md\.|madde)\s*$md' }
    @{ ad = 'tam ad desenleri kapalı'; eski = 'if ($script:MA_TAM_AD.ContainsKey($kisa))'; yeni = 'if ($false)' }
    @{ ad = 'kanun no (213 sayılı) desenleri kapalı'; eski = '"\b$no\s*say[ıi]l[ıi][^.;]{0,80}?\b$md\.?\s*$($script:MA_EK)\s*madde",'; yeni = '"(?!)",' }
  )
  foreach ($m in $MUTASYONLAR) {
    if (-not $kapiMetin.Contains($m.eski)) { $kirmizi++; Write-Host "  KIRMIZI mutasyon kurulamadı (kapı metni değişmiş): $($m.ad)" -ForegroundColor Red; continue }
    $dusen = @((VakaKos ($kapiMetin.Replace($m.eski, $m.yeni))) | Where-Object { -not $_.tamam }).Count
    if ($dusen -lt 1) { $kirmizi++; Write-Host "  KIRMIZI mutasyon sınavı düşürmedi: $($m.ad)" -ForegroundColor Red } else { "  YEŞİL  mutasyon '$($m.ad)' → $dusen vaka düştü" }
  }
} finally { Remove-Item $gecici -Force -ErrorAction SilentlyContinue }

$toplam = $VAKALAR.Count + 2 + 5
if ($kirmizi) { Write-Host "KAPI-MA ÖZ-SINAVI KIRMIZI ($kirmizi / $toplam)" -ForegroundColor Red; exit 1 }
"KAPI-MA ÖZ-SINAVI YEŞİL ($toplam vaka: $($VAKALAR.Count) cümle · 1 gerçek liste · 1 bağlantı · 5 mutasyon)"
