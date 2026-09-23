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
#  ENV: GH_TOKEN (zorunlu, actions:read) · RESEND_KEY + RESEND_FROM (mail icin
#  zorunlu; web3forms yedegi 04.09.2026'da kaldirildi - Cem: "guvensiz yere gonderme").
#  API maliyeti SIFIR (GitHub API, ucretsiz).
#
#  Kullanim: pwsh arac/ci-kirmizi-nobetcisi.ps1
#            pwsh arac/ci-kirmizi-nobetcisi.ps1 -UstUste 3 -Sessiz
# ============================================================================
param(
  [int]$UstUste = 2,        # kac ust uste kirmizi "kalici" sayilir
  # 21.09.2026 - DONUSUMLU ARIZA KORLUGU (olculdu, kaynak.yml):
  # "ust uste" olcusu ilk YESILDE duruyor. kaynak.yml'in son 6 kosusu
  # "failure success failure success failure success" idi: sabah kosusu
  # 4 gun ust uste dustu, aksam kosusu hep yesildi, seri HEP 1'de kaldi
  # ve nobetci arizayi 4 gun boyunca HIC gormedi. Ikinci bir olcu gerekti:
  # "son N kosunun kaci kirmizi". Tek seferlik gecici ariza (10'da 1)
  # alarm uretmez; donusumlu kalici ariza (10'da 5) uretir.
  [int]$OranPencere = 10,   # oran olcusunde bakilacak son kosu sayisi
  [int]$OranEsik = 3,       # o pencerede kac kirmizi "kalici ariza" sayilir
  [int]$HatirlatmaGun = 7,  # suren seri kac gunde bir hatirlatilir
  # 23.09.2026 - KRITIK AKIS: SGS yayini (yayin-bas.yml) 18.09 11:03 -> 23.09 arasi 38 kez dustu,
  # nobetcinin 5 gunluk raporunun yalniz 1'inde gorundu. Kritik akis mail KONUSUNA yazilir
  # (42 kalici kirmizinin arasinda kaybolmasin) ve her gun hatirlatilir.
  [string[]]$Kritik = @('yayin-bas.yml'),
  [int]$HatirlatmaGunKritik = 1,
  [int]$GunPencere = 14,    # oran yalniz bu kadar gunluk kosulara bakar; son kosusu daha eski kirmizi = 'uyuyan'
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
# 21.09.2026 - SAYFALAMA EKLENDI. Tek sayfa 100 kayit veriyordu ama depoda
# 159 workflow var (API total_count 160): ~60 workflow HIC BAKILMIYORDU ve
# rapor bunu "aktif_workflow: 100" diye yaziyordu - yani korlugu tamlik gibi
# gosteriyordu. Simdi tum sayfalar cekilir, alinamayan sayfa KOR sayilir.
$hamWf = @()
$sayfa = 1
$toplamBeklenen = -1
while ($sayfa -le 20) {
  $wf = Api ("actions/workflows?per_page=100&page={0}" -f $sayfa)
  if (-not $wf) { if ($sayfa -eq 1) { Write-Host "CI KIRMIZI NOBETCISI: KOR — workflow listesi alinamadi."; exit 1 } else { break } }
  if ($toplamBeklenen -lt 0) { $toplamBeklenen = [int]$wf.total_count }
  $gelen = @($wf.workflows)
  if ($gelen.Count -eq 0) { break }
  $hamWf += $gelen
  if ($hamWf.Count -ge $toplamBeklenen) { break }
  $sayfa++
}
if ($toplamBeklenen -gt 0 -and $hamWf.Count -lt $toplamBeklenen) {
  Write-Host ("  UYARI: {0} workflow beklenirken {1} alindi - eksik kalan OLCULMEDI sayilir." -f $toplamBeklenen, $hamWf.Count)
}
$aktif = @($hamWf | Where-Object { $_.state -eq "active" })
$tumu  = $aktif.Count
if ($Sinir -gt 0 -and $aktif.Count -gt $Sinir) { $aktif = @($aktif[0..($Sinir - 1)]) }
Write-Host ("CI KIRMIZI NOBETCISI: {0}/{1} aktif workflow, esik {2} ust uste kirmizi." -f $aktif.Count, $tumu, $UstUste)
# Sinir verildiyse geri kalani OLCULMEDI sayilir - "temiz" denmez.
$sinirlandi = $tumu - $aktif.Count

# --- 2) her birinin son kosulari -------------------------------------------
# --- KARAR MANTIGI (oz-sinav bu iki fonksiyonu AST ile cikarip GERCEGINI kosar) ---
# 23.09.2026 - KARAR VERMEYEN KOSU: 'cancelled' ve 'skipped' ne kirmizi ne yesildir.
# Eskiden "kirmizi degil" sayiliyordu: ust uste sayaci her iptalde sifirlaniyor, 10'luk
# pencereyi de atlanan kosular dolduruyordu. OLCULDU: yayin-bas.yml 18.09 11:03'ten 23.09'a
# 38 kez dustu; araya 26 iptal + 26 atlandi girdi; 23.09 09:23 raporunda son 10 kosu 04:04-04:38
# arasi 'skipped' idi -> 0/10, alarm YOK. Rapor 19/20/21/23.09'da akisi hic gostermedi.
# GORMEZ: yalniz iptal edilen ya da hep atlanan akis (hic karar yoksa sessiz kalir).
function KararVerir([string]$c) { return -not ($c -eq 'cancelled' -or $c -eq 'skipped') }
# 23.09.2026 - ZAMAN PENCERESI: seyrek kosan akista "son 10 kosu" AYLARA yayiliyordu. 42 kalici
# kirmizinin 13'u son kosusu YESIL olan akisti (karne, kalite-tarama, rejim...): oran olcusu
# agustostaki dususleri bugunun arizasi sayiyordu. Artik:
#   - oran yalniz son $gunPencere gundeki karar veren kosulara bakar;
#   - son karar veren kosu $gunPencere gunden ESKIYSE akis 'uyuyan'dir: kalici kirmizi SAYILMAZ,
#     mail atilmaz, raporda AYRI listede durur (gizlenmez). 12 olcum araci 12.09'daki tek bir
#     Supabase 500'unde dusup o gunden beri hic kosmamisti.
# $yaslar = her kosunun kac gun once oldugu ($sonuclar ile ayni sira). Verilmezse zaman suzgeci yok.
# GORMEZ: uyuyan akisin gercekten bozuk olup olmadigini (yeniden kosulmadan bilinemez).
function AlarmOlcusu([string[]]$sonuclar, [int]$esikSeri, [int]$pencereBoy, [int]$esikOran, [double[]]$yaslar = @(), [int]$gunPencere = 14) {
  $sira = @(0..([Math]::Max(0, $sonuclar.Count - 1)) | Where-Object { $sonuclar.Count -gt 0 -and (KararVerir $sonuclar[$_]) })
  $kararli = @($sira | ForEach-Object { $sonuclar[$_] })
  $zamanli = ($yaslar.Count -eq $sonuclar.Count -and $yaslar.Count -gt 0)
  # OLCU 1 - bastan itibaren kac karar veren kosu UST USTE basarisiz
  $seriSay = 0
  foreach ($c in $kararli) { if ($c -eq 'failure' -or $c -eq 'timed_out') { $seriSay++ } else { break } }
  # OLCU 2 (21.09) - son N karar veren kosunun kaci kirmizi (donusumlu ariza); 23.09: yalniz pencere gunleri
  $oranSira = if ($zamanli) { @($sira | Where-Object { $yaslar[$_] -le $gunPencere }) } else { $sira }
  $pnc = @($oranSira | Select-Object -First $pencereBoy | ForEach-Object { $sonuclar[$_] })
  $kirmiziSay = @($pnc | Where-Object { $_ -eq 'failure' -or $_ -eq 'timed_out' }).Count
  # Pencere dolmadiysa oran uygulanmaz (yeni workflow yanlis alarm vermesin)
  $oranTutar = ($pnc.Count -ge $pencereBoy) -and ($kirmiziSay -ge $esikOran)
  $uyuyor = $zamanli -and $sira.Count -gt 0 -and ($yaslar[$sira[0]] -gt $gunPencere)
  $sonucTur = if ($seriSay -ge $esikSeri -and $uyuyor) { 'uyuyan' } elseif ($seriSay -ge $esikSeri) { 'ust_uste' } elseif ($oranTutar) { 'oran' } else { 'sessiz' }
  return [pscustomobject]@{ tur = $sonucTur; seri = $seriSay; oran = $kirmiziSay; pencere = $pnc.Count; kararli = $kararli.Count }
}
# --- /KARAR MANTIGI ---

$kirmiziSeriler = @()
$uyuyanlar      = @()
$olculemeyen    = 0
$bakilan        = 0

foreach ($w in $aktif) {
  # yalniz TAMAMLANMIS kosular; devam edenler seriyi bozmasin. Iptal/atlandi elendigi
  # icin pencereden fazlasi cekilir (yayin-bas.yml'de 10 kosunun 10'u atlandi olabiliyor).
  $r = Api ("actions/workflows/{0}/runs?per_page=100&status=completed" -f $w.id)
  if (-not $r) { $olculemeyen++; continue }
  $kosular = @($r.workflow_runs | Where-Object { KararVerir "$($_.conclusion)" })
  if ($kosular.Count -eq 0) { continue }   # karar veren kosu yok - kirmizi degil
  $bakilan++

  $simdiUtc = (Get-Date).ToUniversalTime()
  $yasListe = @($kosular | ForEach-Object { ($simdiUtc - ([datetime]$_.created_at).ToUniversalTime()).TotalDays })
  $olc = AlarmOlcusu @($kosular | ForEach-Object { "$($_.conclusion)" }) $UstUste $OranPencere $OranEsik $yasListe $GunPencere
  $seri        = $olc.seri
  $oranKirmizi = $olc.oran
  $pencere     = @($kosular | Select-Object -First $olc.pencere)
  if ($olc.tur -eq 'sessiz') { continue }
  if ($olc.tur -eq 'uyuyan') {
    # IKINCI BAKIS (23.09 OLCULDU): API ayni istege bir kosuda dogrula.yml icin "59 ust uste, son
    # 08.09" dondurdu, hemen sonraki kosuda dogrusunu (40, son 23.09). Tek kotu yanit canli kirmiziyi
    # 'uyuyan' yapip alarmi SUSTURABILIR. Uyuyan karari ancak durum suzgecsiz ikinci sorgu da ayni
    # seyi soylerse verilir; demezse ikinci sorgunun olcusu kullanilir.
    $r2 = Api ("actions/workflows/{0}/runs?per_page=100" -f $w.id)
    $k2 = @($r2.workflow_runs | Where-Object { "$($_.status)" -eq 'completed' -and (KararVerir "$($_.conclusion)") })
    if ($r2 -and $k2.Count) {
      $yas2 = @($k2 | ForEach-Object { ($simdiUtc - ([datetime]$_.created_at).ToUniversalTime()).TotalDays })
      $olc2 = AlarmOlcusu @($k2 | ForEach-Object { "$($_.conclusion)" }) $UstUste $OranPencere $OranEsik $yas2 $GunPencere
      if ($olc2.tur -ne 'uyuyan') {
        Write-Host ("  IKINCI BAKIS: {0} ilk sorguda uyuyan, ikincide '{1}' - ikincisi kullanildi" -f $w.path, $olc2.tur)
        $kosular = $k2; $olc = $olc2; $seri = $olc.seri; $oranKirmizi = $olc.oran; $pencere = @($kosular | Select-Object -First $olc.pencere)
      }
    }
  }
  if ($olc.tur -eq 'sessiz') { continue }
  if ($olc.tur -eq 'uyuyan') {
    $uyuyanlar += [pscustomobject]@{ dosya = ($w.path -replace '^\.github/workflows/', ''); ust_uste = $seri; son_kosu = "$($kosular[0].created_at)"; son_olay = "$($kosular[0].event)"; url = $kosular[0].html_url }
    continue
  }

  if ($olc.tur -eq 'ust_uste') {
    # serinin EN ESKI kosusu seriyi kimliklendirir (yeni seri = yeni bildirim)
    $tur     = "ust_uste"
    $seriKok = $kosular[$seri - 1].id
  } else {
    # ORAN alarmi: pencere her kosuda kaydigi icin kok olarak kosu id'si
    # KULLANILMAZ - her gun "yeni seri" sanilip spam olurdu. Workflow'a sabit
    # bir anahtar verilir: bir kez bildirilir, surerse haftada bir hatirlatilir.
    $tur     = "oran"
    $seriKok = "oran-" + $w.id
  }
  $kirmiziSeriler += [pscustomobject]@{
    ad            = $w.name
    dosya         = ($w.path -replace '^\.github/workflows/', '')
    seri          = $seri
    tur           = $tur
    oran_kirmizi  = $oranKirmizi
    oran_pencere  = $pencere.Count
    seri_kok      = $seriKok
    son_sonuc     = "$($kosular[0].conclusion)"
    son_sha       = $kosular[0].head_sha.Substring(0, 8)
    son_url       = $kosular[0].html_url
    son_ne        = ($kosular[0].display_title -replace '[\r\n]', ' ')
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
    # kritik akis gunde bir - ama yalniz HALA kirmiziysa; son kosusu yesilse haftalik (duzelmis yayin her gun mail atmasin)
    $hatirlatEsik = if (($Kritik -contains $s.dosya) -and $s.son_sonuc -ne 'success') { $HatirlatmaGunKritik } else { $HatirlatmaGun }
    if ($gecen -lt $hatirlatEsik) { $bildir = $false }
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
  esik_oran        = ("{0}/{1}" -f $OranEsik, $OranPencere)   # 21.09: donusumlu ariza olcusu
  hatirlatma_gun   = $HatirlatmaGun
  workflow_toplam  = $toplamBeklenen     # 21.09: sayfalama sonrasi GERCEK toplam
  workflow_alinan  = $hamWf.Count        # alinamayan kalirsa aradaki fark KOR demektir
  aktif_workflow   = $aktif.Count
  bakilan          = $bakilan
  olculemeyen      = $olculemeyen
  kalici_kirmizi   = $kirmiziSeriler.Count
  gun_pencere      = $GunPencere
  # 23.09: son kosusu $GunPencere gunden eski ve kirmizi akislar - alarm degil, ama GIZLENMEZ
  uyuyan_kirmizi   = $uyuyanlar.Count
  uyuyanlar        = @($uyuyanlar | Sort-Object son_kosu | ForEach-Object { [ordered]@{ dosya = $_.dosya; ust_uste = $_.ust_uste; son_kosu = $_.son_kosu; son_olay = $_.son_olay; url = $_.url } })
  yeni_bildirim    = $bildirim.Count
  seriler          = @($kirmiziSeriler | ForEach-Object {
                        [ordered]@{ ad = $_.ad; dosya = $_.dosya; tur = $_.tur; ust_uste = $_.seri; oran = ("{0}/{1}" -f $_.oran_kirmizi, $_.oran_pencere); son_sha = $_.son_sha; son_ne = $_.son_ne; url = $_.son_url } })
  bildirilen       = $yeniDurum
}
$rapor | ConvertTo-Json -Depth 6 | Set-Content -Path $raporYol -Encoding UTF8

# --- 5) ekrana --------------------------------------------------------------
if ($olculemeyen -gt 0) {
  Write-Host ("  OLCULEMEDI: {0} workflow (kosu listesi alinamadi) - temiz DEGIL, bilinmiyor." -f $olculemeyen)
}
if ($uyuyanlar.Count -gt 0) {
  Write-Host ("  UYUYAN KIRMIZI ({0}): son kosusu {1} gunden eski ve kirmizi - alarm degil, yeniden kosulmadan bozuk mu bilinmez:" -f $uyuyanlar.Count, $GunPencere)
  foreach ($u in ($uyuyanlar | Sort-Object son_kosu)) { Write-Host ("    {0,-34} {1} ust uste  son: {2} ({3})" -f $u.dosya, $u.ust_uste, $u.son_kosu, $u.son_olay) }
}
if ($sinirlandi -gt 0) {
  Write-Host ("  ATLANDI: {0} workflow (-Sinir verildi) - bunlar OLCULMEDI." -f $sinirlandi)
}
if ($kirmiziSeriler.Count -eq 0) {
  Write-Host ("  Temiz - {0} workflow bakildi; ust uste {1} kirmizi de, son {2} kosuda {3}+ kirmizi da yok." -f $bakilan, $UstUste, $OranPencere, $OranEsik)
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
# Kritik akis once gelir ve KONUYA yazilir (23.09: yayin 5 gun durdu, gorulmedi).
$kritikBil = @($bildirim | Where-Object { $Kritik -contains $_.dosya })
if ($kritikBil.Count) {
  $k0 = $kritikBil[0]
  if ($k0.son_sonuc -eq 'success') {
    # oran alarmi, son kosu yesil: yayin su an CALISIYOR ama sik dusuyor - "durdu" denmez
    $konu = "Tetikte alarmi: SGS yayini sik dusuyor ({0}, son {1} kosunun {2}'i kirmizi, son kosu yesil)" -f $k0.dosya, $k0.oran_pencere, $k0.oran_kirmizi
  } else {
    $konu = "Tetikte alarmi: SGS yayini durdu ({0}, {1} kirmizi)" -f $k0.dosya, $(if ($k0.tur -eq 'ust_uste') { "ust uste $($k0.seri) kosudur" } else { "son $($k0.oran_pencere) kosunun $($k0.oran_kirmizi)'i" })
  }
  if ($bildirim.Count -gt $kritikBil.Count) { $konu += " + $($bildirim.Count - $kritikBil.Count) kapi" }
  $bildirim = @($kritikBil) + @($bildirim | Where-Object { $Kritik -notcontains $_.dosya })
}
function OlcuMetni($s) { if ($s.tur -eq 'ust_uste') { "{0} kosudur ust uste kirmizi" -f $s.seri } else { "son {0} kosunun {1}'i kirmizi (son kosu: {2})" -f $s.oran_pencere, $s.oran_kirmizi, $s.son_sonuc } }
$satirlar = $bildirim | ForEach-Object { "{0}{1} — {2} (son: {3})" -f $(if ($Kritik -contains $_.dosya) { 'KRITIK · ' } else { '' }), $_.dosya, (OlcuMetni $_), $_.son_ne }

if ($Sessiz) {
  Write-Host ""
  Write-Host "  -Sessiz verildi, mail ATILMADI. Gidecek olan:"
  $satirlar | ForEach-Object { Write-Host "    $_" }
  exit 1
}

if ($env:RESEND_KEY) {
  $sat  = ($bildirim | ForEach-Object { "<li>$(if ($Kritik -contains $_.dosya) { '<b>KRITIK</b> · ' })<a href=""$($_.son_url)"">$($_.dosya)</a> — $(OlcuMetni $_)<br><small>son: $($_.son_ne)</small></li>" }) -join ""
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
  # 04.09.2026: web3forms yedegi KALDIRILDI (Cem: "guvensiz yere gonderme").
  # RESEND_KEY yoksa mail gitmez; betik zaten 1 ile biter, Actions kirmizi olur.
  Write-Host "`n  !! RESEND_KEY tanimli degil - alarm maili GITMEDI. Gidecek olan:"
  $satirlar | ForEach-Object { Write-Host "    $_" }
}

exit 1
