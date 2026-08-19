# ============================================================================
#  EXIMBANK ORAN HASAT - Turk Eximbank guncel faiz/kar payi oranlarini ceker.
#  (19.08 Cem: "eximbank kredilerini ekleyebilir miyiz" - krediler KURAL tabanli,
#  katalog kartlarinda durur; RADAR gibi isleyen tek parcasi GUNCEL ORANLAR.)
#  Cikti: veri/eximbank-oran.json - destekler.html "Eximbank oranlari" grubu okur.
#
#  Kaynak kesfi 19.08 OLCULDU:
#   - Sayfa (faiz-ve-kar-payi-oranlari) oranlari JS ile cizer; arka uc JSON:
#     /data/faiz-ve-kar-payi-oranlari (120 kayit, TRY/USD/EUR, 15 program;
#     FaizOrani_Kobi + FaizOrani_Kobi_Disi ayri alanlar - matris tahmini YOK).
#   - "Tum verileri pdf indir" DOSYASI ESKI KALABILIYOR (25.03 damgaliydi,
#     API canliydi) -> PDF degil API kullanilir.
#  Rakam disiplini: oranlar oldugu gibi tasinir (SOFR 6 AY + 4,50 dahil),
#  yorumlanmaz; birim/taban ifadesi kaynaktaki metindir.
#  Kor kalma: kayit < 40 ya da TRY/USD eksikse dosyaya DOKUNULMAZ, exit 1.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\eximbank-oran.json"
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }

$hamDosya = Join-Path ([IO.Path]::GetTempPath()) "exim-oran-api.json"
& $curlKomut -sSL -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $hamDosya "https://www.eximbank.gov.tr/data/faiz-ve-kar-payi-oranlari"
if(-not (Test-Path $hamDosya)){ Write-Host "HATA: API cekilemedi"; exit 1 }
$ham = Get-Content $hamDosya -Raw -Encoding UTF8 | ConvertFrom-Json

$oranlar = @()
foreach($kayit in @($ham.Data)){
  $program = "$($kayit.Program.ProgramAdi)".Trim()
  $doviz = "$($kayit.DovizKodu.DovizKodu)".Trim()
  $vade = "$($kayit.VadeKodu.VadeAciklama)".Trim()
  if(-not $program -or -not $doviz){ continue }
  $oranlar += [ordered]@{
    program = $program
    doviz = $doviz
    vade = $vade
    kobi = "$($kayit.FaizOrani_Kobi)".Trim()
    kobiDisi = "$($kayit.FaizOrani_Kobi_Disi)".Trim()
  }
}

# kor kalma: sayim + iki ana doviz varligi (imkansiz-veri sigortasi)
$dovizler = @($oranlar | ForEach-Object { $_.doviz } | Sort-Object -Unique)
if(@($oranlar).Count -lt 40 -or ($dovizler -notcontains 'TRY') -or ($dovizler -notcontains 'USD')){
  Write-Host ("HATA: beklenmedik veri ({0} kayit, dovizler: {1}) - dosyaya DOKUNULMADI" -f @($oranlar).Count, ($dovizler -join ','))
  exit 1
}

$cikti = [ordered]@{
  guncelleme = "Kaynak: Turk Eximbank faiz ve kar payi oranlari (bankanin kendi veri ucundan robotla). Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = "https://www.eximbank.gov.tr/tr/faiz-ve-kar-payi-oranlari"
  not = "Oranlar Eximbank yayinidir ve degisebilir; kullandirim kosullari, limit ve teminat icin bankayla gorusulur. SOFR/EURIBOR/TLREF tabanli ifadeler kaynaktaki bicimiyle tasinir."
  oranlar = $oranlar
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("EXIMBANK ORAN: {0} kayit ({1}) -> veri/eximbank-oran.json [geri okuma: {2}]" -f @($oranlar).Count, ($dovizler -join '+'), @($geriOkuma.oranlar).Count)
if(@($geriOkuma.oranlar).Count -ne @($oranlar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
