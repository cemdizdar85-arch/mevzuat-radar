# ============================================================================
#  CI KIRMIZI NOBETCISI — kalici kirmizi kapi kimseye gorunmuyordu.
#
#  NEDEN VAR (25.08.2026)
#  "Dogrulama Kapisi" 19.08'den 25.08'e kadar KIRMIZI kaldi ve kimse fark
#  etmedi. Alti gun. Sebep basitti: GitHub kirmizi kosu icin depo sahibine
#  mail atar ama o mailler gunde onlarca gelince okunmaz olur; ve kirmizi
#  KALICI olunca "zaten hep kirmizi" diye bakilmaz.
#  O alti gunde iki sey oldu:
#    - kapinin ardindaki DORT adim hic kosmadi (skipped),
#    - o adimlarin korudugu seyler denetimsiz yayina gitti.
#
#  NE YAPAR
#  Depodaki AKTIF workflow'larin son kosularina bakar. Bir workflow'un son
#  IKI ya da daha fazla kosusu ust uste basarisizsa "KALICI KIRMIZI" sayar.
#  Tek bir kirmizi kosu alarm degildir (gecici ariza olabilir); UST USTE
#  IKI kirmizi, insanin bakmasi gereken seydir.
#
#  SPAM YAPMAZ
#  Her kirmizi seri (streak) bir kez bildirilir. Seri surerse HAFTADA BIR
#  hatirlatilir. Seri kirilip yeniden baslarsa yeni seri sayilir ve yeniden
#  bildirilir. Durum veri/ci-kirmizi-raporu.json'da tutulur.
#
#  UC DURUM: YESIL / KIRMIZI / KOR (token yoksa "temiz" demez, KOR der).
#
#  ENV: GH_TOKEN (zorunlu, actions:read) · RESEND_KEY + RESEND_FROM (istege
#  bagli; yoksa web3forms yedegi kullanilir - nabiz-nobetcisi ile ayni kanal).
#  API maliyeti SIFIR (GitHub API, ucretsiz).
#
#  Kullanim: pwsh arac/ci-kirmizi-nobetcisi.ps1
#            pwsh arac/ci-kirmizi-nobetcisi.ps1 -UstUste 3 -Sessiz
# ============================================================================
param(
  [int]$UstUste = 2,        # kac ust uste kirmizi "kalici" sayilir
  [int]$HatirlatmaGun = 7,  # suren seri kac gunde bir hatirlatilir
  [int]$Sinir = 0,          # kac workflow taransin (0 = hepsi; yerel deneme icin)
  [switch]$Sessiz           # mail atma, yalniz raporla (yerel deneme icin)
)

$ErrorActionPreference = "Stop"
# Kok, git'ten DEGIL betigin kendi konumundan cozuluyor. Sebep: yol Turkce
# harf iceriyor ("Masaustu", "mevzuat isi") ve "git rev-parse" ciktisi
# kabuklar arasi gecerken bozulabiliyor; PowerShell o yolu bulamiyor.
# $PSScriptRoot her zaman dogru ve kodlamadan etkilenmez.
$kok = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $kok

$REPO     = "cemdizdar85-arch/mevzuat-radar"
$raporYol = Join-Path $kok "veri\ci-kirmizi-raporu.json"

# Depo PUBLIC oldugu icin API kimliksiz de okunur - ama saatte 60 istek.
# 100 workflow icin bu yetmez, o yuzden CI'da token SART. Yerelde -Sinir ile
# kucuk bir ornekle denenebilsin diye kimliksiz kosuya da izin veriliyor;
# hangi kipte kosuldugu ekrana yaziliyor ki kimse yaniltici bir "temiz"
# okumasin.
$BASLIK = @{ "User-Agent" = "tetikte-ci-nobetcisi" }
if ($env:GH_TOKEN) {
  $BASLIK["Authorization"] = "Bearer $env:GH_TOKEN"
} else {
  $ci = ($env:CI -eq "true") -or ($env:GITHUB_ACTIONS -eq "true")
  if ($ci) {
    # CI'da token her zaman vardir; yoksa kurulum hatasidir, sessizce gecilmez.
    Write-Host "CI KIRMIZI NOBETCISI: KOR — CI'da GH_TOKEN yok, olcum YAPILAMADI."
    exit 1
  }
  Write-Host "  UYARI: GH_TOKEN yok, kimliksiz kosuluyor (saatte 60 istek)."
}

function Api($yol) {
  try { return Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/$yol" -Headers $BASLIK -TimeoutSec 60 }
  catch { return $null }
}

# --- 1) aktif workflow'lar --------------------------------------------------
$wf = Api "actions/workflows?per_page=100"
if (-not $wf) { Write-Host "CI KIRMIZI NOBETCISI: KOR — workflow listesi alinamadi."; exit 1 }
$aktif = @($wf.workflows | Where-Object { $_.state -eq "active" })
$tumu  = $aktif.Count
if ($Sinir -gt 0 -and $aktif.Count -gt $Sinir) { $aktif = @($aktif[0..($Sinir - 1)]) }
Write-Host ("CI KIRMIZI NOBETCISI: {0}/{1} aktif workflow, esik {2} ust uste kirmizi." -f $aktif.Count, $tumu, $UstUste)
# Sinir verildiyse geri kalani OLCULMEDI sayilir - "temiz" denmez.
$sinirlandi = $tumu - $aktif.Count

# --- 2) her birinin son kosulari -------------------------------------------
$kirmiziSeriler = @()
$olculemeyen    = 0
$bakilan        = 0

foreach ($w in $aktif) {
  # yalniz TAMAMLANMIS kosular; devam edenler seriyi bozmasin
  $r = Api ("actions/workflows/{0}/runs?per_page={1}&status=completed" -f $w.id, ($UstUste + 3))
  if (-not $r) { $olculemeyen++; continue }
  $kosular = @($r.workflow_runs)
  if ($kosular.Count -eq 0) { continue }   # hic kosmamis - kirmizi degil
  $bakilan++

  # bastan itibaren kac tanesi ust uste basarisiz
  $seri = 0
  foreach ($k in $kosular) {
    if ($k.conclusion -eq "failure" -or $k.conclusion -eq "timed_out") { $seri++ } else { break }
  }
  if ($seri -lt $UstUste) { continue }

  # serinin EN ESKI kosusu seriyi kimliklendirir (yeni seri = yeni bildirim)
  $seriKok = $kosular[$seri - 1].id
  $kirmiziSeriler += [pscustomobject]@{
    ad       = $w.name
    dosya    = ($w.path -replace '^\.github/workflows/', '')
    seri     = $seri
    seri_kok = $seriKok
    son_sha  = $kosular[0].head_sha.Substring(0, 8)
    son_url  = $kosular[0].html_url
    son_ne   = ($kosular[0].display_title -replace '[\r\n]', ' ')
  }
}

# --- 3) onceki durumu oku ---------------------------------------------------
$onceki = @{}
if (Test-Path -LiteralPath $raporYol) {
  try {
    $j = Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $j.bildirilen.PSObject.Properties) { $onceki[$p.Name] = $p.Value }
  } catch { }
}

$simdi     = Get-Date
$bildirim  = @()
$yeniDurum = [ordered]@{}

foreach ($s in ($kirmiziSeriler | Sort-Object -Property seri -Descending)) {
  $anahtar = $s.dosya
  $kayit   = $onceki[$anahtar]
  $bildir  = $true
  $sebep   = "yeni seri"

  if ($kayit -and [string]$kayit.seri_kok -eq [string]$s.seri_kok) {
    # ayni seri suruyor - haftada bir hatirlat
    $gecen = ($simdi - [datetime]$kayit.son_bildirim).TotalDays
    if ($gecen -lt $HatirlatmaGun) { $bildir = $false }
    else { $sebep = ("{0} gundur suruyor" -f [int]$gecen) }
  }

  if ($bildir) {
    $bildirim += $s
    $yeniDurum[$anahtar] = @{ seri_kok = $s.seri_kok; son_bildirim = $simdi.ToString("o"); seri = $s.seri; sebep = $sebep }
  } else {
    $yeniDurum[$anahtar] = @{ seri_kok = $kayit.seri_kok; son_bildirim = $kayit.son_bildirim; seri = $s.seri; sebep = "bildirildi" }
  }
}

# --- 4) rapor (kor kalma: kirmizi olsa da yazilir) -------------------------
$rapor = [ordered]@{
  olcum_tarihi     = $simdi.ToString("o")
  esik_ust_uste    = $UstUste
  hatirlatma_gun   = $HatirlatmaGun
  aktif_workflow   = $aktif.Count
  bakilan          = $bakilan
  olculemeyen      = $olculemeyen
  kalici_kirmizi   = $kirmiziSeriler.Count
  yeni_bildirim    = $bildirim.Count
  seriler          = @($kirmiziSeriler | ForEach-Object {
                        [ordered]@{ ad = $_.ad; dosya = $_.dosya; ust_uste = $_.seri; son_sha = $_.son_sha; son_ne = $_.son_ne; url = $_.son_url } })
  bildirilen       = $yeniDurum
}
$rapor | ConvertTo-Json -Depth 6 | Set-Content -Path $raporYol -Encoding UTF8

# --- 5) ekrana --------------------------------------------------------------
if ($olculemeyen -gt 0) {
  Write-Host ("  OLCULEMEDI: {0} workflow (kosu listesi alinamadi) - temiz DEGIL, bilinmiyor." -f $olculemeyen)
}
if ($sinirlandi -gt 0) {
  Write-Host ("  ATLANDI: {0} workflow (-Sinir verildi) - bunlar OLCULMEDI." -f $sinirlandi)
}
if ($kirmiziSeriler.Count -eq 0) {
  Write-Host ("  Temiz - {0} workflow bakildi, ust uste {1} kirmizi olan yok." -f $bakilan, $UstUste)
  if ($olculemeyen -gt 0) { exit 1 }
  exit 0
}

Write-Host ""
Write-Host ("  KALICI KIRMIZI ({0}):" -f $kirmiziSeriler.Count)
foreach ($s in ($kirmiziSeriler | Sort-Object -Property seri -Descending)) {
  Write-Host ("    {0,-34} {1} ust uste   son: {2}  {3}" -f $s.dosya, $s.seri, $s.son_sha, $s.son_ne.Substring(0, [Math]::Min(34, $s.son_ne.Length)))
}

if ($bildirim.Count -eq 0) {
  Write-Host ""
  Write-Host ("  Yeni bildirim yok - hepsi zaten bildirilmis (hatirlatma {0} gunde bir)." -f $HatirlatmaGun)
  exit 1
}

# --- 6) mail (nabiz-nobetcisi ile AYNI kanal) ------------------------------
# 19.08 onemsiz-kutu dersi: TUM-BUYUK konu + HTML-tek govde spam puani
# yukseltir; konu cumle duzeni, her maile duz-metin (text) alternatifi eklenir.
$konu = "Tetikte CI alarmi: $($bildirim.Count) kapi kalici kirmizi"
$satirlar = $bildirim | ForEach-Object { "{0} — {1} kosudur ust uste kirmizi (son: {2})" -f $_.dosya, $_.seri, $_.son_ne }

if ($Sessiz) {
  Write-Host ""
  Write-Host "  -Sessiz verildi, mail ATILMADI. Gidecek olan:"
  $satirlar | ForEach-Object { Write-Host "    $_" }
  exit 1
}

if ($env:RESEND_KEY) {
  $sat  = ($bildirim | ForEach-Object { "<li><a href=""$($_.son_url)"">$($_.dosya)</a> — $($_.seri) kosudur ust uste kirmizi<br><small>son: $($_.son_ne)</small></li>" }) -join ""
  $html = "<h3>CI kapisi kalici kirmizi</h3><p>Asagidaki kapilar ust uste basarisiz oluyor. Kalici kirmizi kapi kapi degildir — arkasindaki adimlar da kosmuyor olabilir.</p><ul>$sat</ul><p>Actions sekmesinden loga bak.</p>"
  $duz  = "CI kapisi kalici kirmizi`n`n" + ($satirlar -join "`n") + "`n`nActions sekmesinden loga bak."
  $mb   = @{ from = $env:RESEND_FROM; to = @("cemdizdar85@hotmail.com"); subject = $konu; html = $html; text = $duz } | ConvertTo-Json -Depth 3
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" `
      -Headers @{ Authorization = ("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7e]', '')) } `
      -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" -TimeoutSec 60 | Out-Null
    Write-Host "`n  Alarm maili gonderildi (Resend)."
  } catch { Write-Host "`n  Mail GONDERILEMEDI (Resend): $($_.Exception.Message)" }
} else {
  $mb = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = $konu
    from_name  = "Tetikte CI Nobetcisi"
    "Kapilar"  = ($satirlar -join "`n")
    "Not"      = "Kalici kirmizi kapi kapi degildir - ardindaki adimlar da kosmuyor olabilir. Actions sekmesinden loga bak."
  } | ConvertTo-Json -Depth 3
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" `
      -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" -TimeoutSec 60 | Out-Null
    Write-Host "`n  Alarm maili gonderildi (web3forms)."
  } catch { Write-Host "`n  Mail GONDERILEMEDI (web3forms): $($_.Exception.Message)" }
}

exit 1
