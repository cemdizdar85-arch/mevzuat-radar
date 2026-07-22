# ============================================================================
#  TAKVIM NOBETCISI — TURMOB sinav takvimi PDF'ini her gun yoklar.
#  Hash DEGISMEDIYSE sessiz cikar. DEGISTIYSE:
#    - yeni PDF'i motor/arsiv-takvim/ altina tarihli kaydeder (kanit)
#    - veri/sinav-takvimi.json'a degisiklik notu duser (sonKontrol alani)
#    - Cem'e mail atar: "takvim degisti, genc.html tarihlerini teyit et"
#  TARIHLERI KENDISI DEGISTIRMEZ — yanlis sinav tarihi basma riski sifir
#  tutulur; guncelleme elle teyitle yapilir (rakam disiplini).
#  ENV: RESEND_KEY + RESEND_FROM (mail icin; yoksa mail atlanir, commit yeter)
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$jsonYol = Join-Path $kok "veri/sinav-takvimi.json"
$j = Get-Content $jsonYol -Raw -Encoding UTF8 | ConvertFrom-Json
$url = $j.kaynakUrl
$bugun = (Get-Date).ToString("dd.MM.yyyy")

# PDF'i indir
$tmp = Join-Path ([IO.Path]::GetTempPath()) "takvim-yeni.pdf"
try {
  Invoke-WebRequest -Uri $url -OutFile $tmp -UserAgent "Mozilla/5.0 (MevzuatRadar-TakvimNobetcisi)" -TimeoutSec 120 -UseBasicParsing
} catch {
  Write-Host "PDF INDIRILEMEDI ($url) — TESMER linki degismis olabilir!"
  # indirilemeyen kaynak da alarm sebebi (URL degisti = takvim yenilendi olabilir)
  $mesaj = "TURMOB sinav takvimi PDF'i INDIRILEMEDI: $url — dosya tasinmis/yenilenmis olabilir. tesmer.org.tr'den yeni takvimi bul, genc.html + sinav-takvimi.json guncelle."
  if($env:RESEND_KEY){
    $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE NOBETCI: sinav takvimi PDF erisim alarmi"; html="<p>$mesaj</p>" } | ConvertTo-Json -Depth 3
    try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "alarm maili gitti" } catch { Write-Host "mail hatasi: $_" }
  }
  exit 0
}

# hash karsilastir
$sha=[Security.Cryptography.SHA256]::Create()
$yeniHash=([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($tmp))) -replace '-','').Substring(0,16).ToLower()
if($yeniHash -eq $j.pdfHash){
  Write-Host "Takvim degismemis (hash: $yeniHash). Son teyit damgasi guncel kaldi."
  exit 0
}

# DEGISMIS — kanit arsivle + json'a not + mail
Write-Host "TAKVIM DEGISTI! eski=$($j.pdfHash) yeni=$yeniHash"
$arsiv = Join-Path $here "arsiv-takvim"
New-Item -ItemType Directory -Force $arsiv | Out-Null
Copy-Item $tmp (Join-Path $arsiv ("takvim-" + (Get-Date).ToString("yyyy-MM-dd") + ".pdf")) -Force
$j | Add-Member -NotePropertyName "degisiklikTespiti" -NotePropertyValue $bugun -Force
$j | Add-Member -NotePropertyName "yeniHashBeklemede" -NotePropertyValue $yeniHash -Force
[IO.File]::WriteAllText($jsonYol, ($j | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))

if($env:RESEND_KEY){
  $html = "<h3>TURMOB sinav takvimi PDF'i DEGISTI</h3><p>Tespit: $bugun · eski hash $($j.pdfHash) → yeni $yeniHash</p><p><b>Yapilacak:</b> <a href='$url'>guncel PDF'i ac</a>, tarihleri oku; genc.html tablolari + geri sayim olaylarini ve sinav-takvimi.json'daki pdfHash/sonTeyit alanlarini guncelle. Robot tarihleri BILEREK kendisi degistirmez.</p><p>Tetikte — takvim nobetcisi</p>"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE NOBETCI: TURMOB sinav takvimi DEGISTI — teyit gerekli"; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "degisiklik maili gitti" } catch { Write-Host "mail hatasi: $_" }
}
exit 0
