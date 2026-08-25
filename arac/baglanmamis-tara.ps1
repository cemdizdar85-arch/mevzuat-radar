# ============================================================================
#  "KURULMUS AMA BAGLANMAMIS" TARAYICISI  (25.08.2026)
#
#  CEM: "kurulmus ama baglanmamis katmanlari tara."
#
#  NEDEN. 25.08'de bu desenden DORT vaka cikti ve DORDU DE TESADUFEN bulundu:
#   1) RG Nobeti'nin otomatik cekmesi: kosul `event -eq 'push'` idi; robot
#      push'lari (GITHUB_TOKEN) yeni is akisi TETIKLEMEZ -> dal HIC calismadi.
#      Nobet aylardir yalniz rapor yaziyordu, tek soru bile cekmemisti.
#   2) Altin test: adim vardi ama 38 gun `skipped` - ustundeki kapi hep
#      kirmizi dustugu icin sira ona hic gelmedi.
#   3) madde_ara v7'de `when 'standart' then 0.85`: ambarda tur='standart'
#      diye SIFIR kayit var (gercek deger 'standart-madde') -> olu dal.
#   4) v5'in df<=1500 dar havuzu: bir yeniden yazimda dustu; kabul sorgusu
#      SQL dosyasinin dibinde YORUM olarak kaldigi icin 5 hafta gorunmedi.
#
#  ORTAK SINIF: mekanizma YAZILMIS, ama ates alacagi yol yok. Kod incelemesi
#  bunu gostermez cunku kodun kendisi dogrudur; eksik olan BAGLANTIDIR.
#
#  BU TARAYICI MEKANIK OLARAK BULUNABILENLERI ARAR:
#   A) CAGRILMAYAN BETIK  - motor/arac altindaki .ps1/.js hicbir is akisinda
#      ve hicbir baska betikte gecmiyorsa: yazilmis ama kimse cagirmiyor.
#   B) COMMIT EDILMEYEN CIKTI - betik veri/x.json yaziyor ama hicbir is akisi
#      o dosyayi `git add` etmiyorsa: CI'da ne yaptigi GORUNMUYOR (kor kalma).
#   C) ATESLENEMEYEN KOSUL - is akisinda `event_name == 'push'` kosulu var ama
#      push tetigi ROBOT'un yazdigi yollara bagli. Robot push'u is akisi
#      tetiklemedigi icin o dal fiilen olu. (1 numarali vakanin ta kendisi.)
#
#  BULAMADIKLARI (durustce): calisma zamaninda olusan olu dallar (3 numarali
#  vaka gibi - veri degeriyle kiyaslanan sabitler) ve "adim hep skipped"
#  durumu (GitHub API gerektirir, ayri is). Bu tarayici KAPSAMLI DEGIL;
#  mekanik olani yakalar, geri kalani insan okumasi ister.
#
#  KULLANIM: pwsh arac/baglanmamis-tara.ps1
#  CIKIS: 0 temiz · 2 bulgu var (KIRMIZI DEGIL - bunlar is listesidir,
#         kapi degil; kalici kirmizi gurultuye doner)
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

$isAkisiMetin = @{}
foreach ($w in Get-ChildItem '.github/workflows' -Filter *.yml -ErrorAction SilentlyContinue) {
  $isAkisiMetin[$w.Name] = Get-Content $w.FullName -Raw -Encoding UTF8
}
$tumIsAkisi = ($isAkisiMetin.Values -join "`n")

$betikler = @()
foreach ($d in @('motor','arac')) {
  if (Test-Path $d) { $betikler += Get-ChildItem $d -Recurse -Include *.ps1,*.js -File }
}
$betikMetin = @{}
foreach ($b in $betikler) { $betikMetin[$b.FullName] = Get-Content $b.FullName -Raw -Encoding UTF8 }
$tumBetik = ($betikMetin.Values -join "`n")

# ---------------------------------------------------------------------------
#  A) CAGRILMAYAN BETIK
# ---------------------------------------------------------------------------
#  DARALTMA (ilk surumun dersi): "cagrilmayan betik" ham hali 103 sonuc verdi
#  ve cogu MESRU tek seferlik araclardi (geri-yukle-3kanun, emdash-sadelestir
#  gibi elle kosturulan onarim betikleri). O liste is listesi degil GURULTUYDU.
#  Anlamli sinyal su: betik VERI URETIYOR (veri/*.json yaziyor) AMA hicbir is
#  akisi onu cagirmiyor. Yani "veri uretecek ama kendiliginden hic kosmayacak"
#  - kurulmus ama baglanmamisin ta kendisi. Elle calistirilan onarim araclari
#  veri yazmadigi (ya da yazsa bile zaten elle tetiklendigi) icin bu daralttma
#  yanlis pozitifi buyuk olcude kesiyor.
$cagrilmayan = New-Object System.Collections.ArrayList
foreach ($b in $betikler) {
  $ad = $b.Name
  $icerik = $betikMetin[$b.FullName]
  # veri/*.json YAZIYOR mu? (okumak yetmez - yazma kalibi aranir)
  $veriYaziyor = ($icerik -match "(WriteAllText|Set-Content|Out-File|writeFileSync)[^`n]{0,200}veri/[A-Za-z0-9_\-\.]+\.json") -or
                 ($icerik -match "veri/[A-Za-z0-9_\-\.]+\.json[^`n]{0,120}(WriteAllText|Set-Content|Out-File|writeFileSync)")
  if (-not $veriYaziyor) { continue }
  $isAkisindaVar = $tumIsAkisi -match [regex]::Escape($ad)
  $baskaBetikte = $false
  foreach ($k in $betikMetin.Keys) {
    if ($k -eq $b.FullName) { continue }
    if ($betikMetin[$k] -match [regex]::Escape($ad)) { $baskaBetikte = $true; break }
  }
  if (-not $isAkisindaVar -and -not $baskaBetikte) {
    [void]$cagrilmayan.Add(($b.FullName.Replace("$kok\", '') -replace '\\','/'))
  }
}

# ---------------------------------------------------------------------------
#  B) COMMIT EDILMEYEN CIKTI
#  Betikte gecen veri/*.json adlarini topla; is akislarinda `git add` ile
#  eslesiyor mu bak. Not: bazi is akislari toplu ekleme yapiyor
#  ("git ls-files --modified -- 'veri/*.json'"); o kalip varsa o is akisi
#  TUM veri dosyalarini kapsiyor sayilir - yanlis pozitif uretmeyelim.
# ---------------------------------------------------------------------------
$topluEkleyen = $false
foreach ($n in $isAkisiMetin.Keys) {
  if ($isAkisiMetin[$n] -match "ls-files[^`n]*veri/\*\.json" -or $isAkisiMetin[$n] -match "git add -A veri/") { $topluEkleyen = $true; break }
}
$commitsiz = New-Object System.Collections.ArrayList
if (-not $topluEkleyen) {
  $yazilan = @{}
  foreach ($k in $betikMetin.Keys) {
    foreach ($m in [regex]::Matches($betikMetin[$k], "veri/([A-Za-z0-9_\-\.]+\.json)")) {
      $yazilan["veri/" + $m.Groups[1].Value] = ($k.Replace("$kok\", '') -replace '\\','/')
    }
  }
  foreach ($f in $yazilan.Keys) {
    $ad = Split-Path $f -Leaf
    if ($tumIsAkisi -notmatch [regex]::Escape($ad)) {
      [void]$commitsiz.Add([ordered]@{ dosya=$f; ureten=$yazilan[$f] })
    }
  }
}

# ---------------------------------------------------------------------------
#  C) ATESLENEMEYEN 'push' KOSULU
#  Robot push'lari (GITHUB_TOKEN) yeni is akisi TETIKLEMEZ. Bir is akisi
#  `event_name == 'push'` kosuluyla davranis degistiriyorsa ve push tetigi
#  ROBOTUN yazdigi bir yola bagliysa, o dal FIILEN OLUDUR.
# ---------------------------------------------------------------------------
#  IKI DUZELTME (ilk surum ikisinde de YANLIS POZITIF verdi):
#   (1) YORUM SATIRLARI ATLANIR. Ilk surum mevzuat.yml'i isaretledi; eslesen
#       sey satir 328'deki bir YORUMDU ("push'ta event_name='push' oldugundan").
#   (2) YALNIZ '==' aranir, '!=' ARANMAZ. Ilk surum veri-kapisi.yml'i
#       isaretledi; oradaki kosul `github.event_name != 'push'` yani "push
#       DISINDA kos" - dogru kullanim, olu dal degil.
#  Aranan sey: push OLDUGUNDA davranis ACAN kosul.
$oluPushDali = New-Object System.Collections.ArrayList
foreach ($n in $isAkisiMetin.Keys) {
  $t = $isAkisiMetin[$n]
  # yorum satirlarini at (YAML '#' ve pwsh blogu icindeki '#')
  $kodSatirlari = ($t -split "`n" | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
  $t = $kodSatirlari
  $acanKosul = ($t -match "event_name[^`n]{0,10}==\s*'push'") -or ($t -match "event_name[^`n]{0,10}-eq\s*'push'")
  if (-not $acanKosul) { continue }
  # push tetigi veri/ ya da motor/ yollarina mi bagli (robot yazar)
  $robotYolu = ($t -match "paths:\s*(\r?\n\s*-\s*'?[^\r\n]*(veri/|motor/)[^\r\n]*'?)+")
  [void]$oluPushDali.Add([ordered]@{
    is_akisi = $n
    robot_yoluna_bagli = [bool]$robotYolu
    not = "event_name=='push' ile davranis degistiriyor. Robot push'lari (GITHUB_TOKEN) is akisi TETIKLEMEZ; bu dal yalniz INSAN push'unda calisir. Otomatik davranis buna baglanmissa FIILEN OLUDUR."
  })
}

Write-Host "=== KURULMUS AMA BAGLANMAMIS TARAYICISI ==="
Write-Host ("taranan betik: {0} | is akisi: {1}" -f $betikler.Count, $isAkisiMetin.Count)
Write-Host ""
Write-Host ("A) CAGRILMAYAN BETIK        : {0}" -f $cagrilmayan.Count)
foreach ($x in ($cagrilmayan | Select-Object -First 20)) { Write-Host ("     {0}" -f $x) }
if ($cagrilmayan.Count -gt 20) { Write-Host ("     ... ve {0} tane daha" -f ($cagrilmayan.Count - 20)) }
Write-Host ""
Write-Host ("B) COMMIT EDILMEYEN CIKTI   : {0}{1}" -f $commitsiz.Count, $(if($topluEkleyen){' (toplu ekleme kalibi bulundu - bu denetim ATLANDI, yanlis pozitif uretmesin)'}else{''}))
foreach ($x in ($commitsiz | Select-Object -First 15)) { Write-Host ("     {0}  <- {1}" -f $x.dosya, $x.ureten) }
Write-Host ""
Write-Host ("C) ATESLENEMEYEN 'push' DALI: {0}" -f $oluPushDali.Count)
foreach ($x in $oluPushDali) { Write-Host ("     {0}   (robot yoluna bagli: {1})" -f $x.is_akisi, $x.robot_yoluna_bagli) }

$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  taranan_betik = $betikler.Count
  taranan_is_akisi = $isAkisiMetin.Count
  cagrilmayan_betik = @($cagrilmayan)
  commit_edilmeyen_cikti = @($commitsiz)
  toplu_ekleme_kalibi_var = $topluEkleyen
  atesalmayan_push_dali = @($oluPushDali)
  kapsam_notu = "MEKANIK olani arar. Calisma zamaninda olusan olu dallar (veri degeriyle kiyaslanan sabitler) ve 'adim hep skipped' durumu BU TARAYICIDA YOK - ilki insan okumasi, ikincisi GitHub API isi."
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/baglanmamis-raporu.json'), ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "-> veri/baglanmamis-raporu.json"
$toplam = $cagrilmayan.Count + $commitsiz.Count + $oluPushDali.Count
Write-Host ("TOPLAM BULGU: {0}" -f $toplam)
Write-Host "NOT: bunlar IS LISTESIDIR, kapi degil. Kalici kirmizi gurultuye doner."
if ($toplam -gt 0) { exit 2 }
exit 0
