# ============================================================================
#  SMMM YETERLİLİK 2019–2025: GÖRÜNTÜDEN OKUNAN SORU METNİNİ AMBARA YAZ   16.09.2026
#  Cem "1 VE 2 YAP": arac/smmm-cevap-tamlik.ps1 ölçtü — 2019–2025 kitapçıklarında soru kâğıdı imzalı TARAMA,
#  komisyon cevabı metin. Ambardaki tur='cikmis-komisyon-cevabi' belgelerinde soru metni YOK.
#
#  GİRDİ (git dışı): veri/smmm-arsiv/soru-metni/<kök>.txt — doğrulanmış metin (bkz. arac/smmm-soru-ocr.ps1).
#    Dosyanın ilk satırı "KIP: EKLE" ya da "KIP: DEGISTIR" olmalı:
#      EKLE     → "SORULAR" + metin + kaynak notu, mevcut komisyon cevabının ÖNÜNE eklenir (cevap metne dokunulmaz)
#      DEGISTIR → belge metni tamamen bu metinle değişir (kitapçığın tamamı görüntü ve ambardaki eski OCR hatalıysa)
#  NE YAPAR (bedel 0):
#    - Belge ambarda tek olmalı; zaten "SORULAR" ile başlıyorsa atlar (iki kez eklemez).
#    - Yazmadan önce eski metni veri/smmm-arsiv/soru-yedek/<kök>.json'a yedekler (varsa ezmez).
#    - PATCH ile yazar, birebir geri okur. Varsayılan KURU PROVA; yazmak için -Yaz.
#  -YenidenKur: zaten yazılmış belgeyi yedekteki ilk metinden yeniden kurar (ör. ayraç düzeltmesi).
#  Kullanım: powershell -NoProfile -File arac/smmm-soru-metni-yut.ps1 [-Desen 'smmm_2019_1_*'] [-Yaz] [-YenidenKur]
# ============================================================================
param([string]$Desen = 'smmm_*', [switch]$Yaz, [switch]$YenidenKur)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$arsiv = Join-Path (Join-Path $depoKok 'veri') 'smmm-arsiv'
$metinKlasoru = Join-Path $arsiv 'soru-metni'
$yedekKlasoru = Join-Path $arsiv 'soru-yedek'
if(-not (Test-Path $metinKlasoru)){ Write-Host 'KÖR: veri/smmm-arsiv/soru-metni yok (yalnız yerelde).'; exit 0 }
$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $sbAnahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$kaynakNotu = "KAYNAK NOTU: TESMER/TÜRMOB PDF'inde soru kâğıdı imzalı tarama (görüntü) olarak yayımlanmıştır. Soru metni görüntüden yazıya geçirilmiştir (arac/smmm-soru-metni-yut.ps1). Doğrulama: iki bağımsız OCR (Tesseract, Windows OCR) + görsel okuma; her kelime ve rakam en az iki okumayla eşleştirildi, eşleşmeyenler görüntüden tek tek kontrol edildi. Antet, imzalar ve adres satırı alınmamıştır."
[void](New-Item -ItemType Directory -Force $yedekKlasoru)

$yazildi = 0; $atlandi = 0; $hata = 0
foreach($dosya in (Get-ChildItem $metinKlasoru -Filter "$Desen.txt" | Sort-Object Name)){
  $kok = $dosya.BaseName
  $icerik = [IO.File]::ReadAllText($dosya.FullName,[Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
  $ilkSatir = ($icerik -split "`n",2)[0].Trim()
  $govdeMetni = (($icerik -split "`n",2)[1]).Trim()
  if($ilkSatir -notmatch '^KIP:\s*(EKLE|DEGISTIR)$'){ Write-Host "  !! $kok ilk satır KIP: EKLE/DEGISTIR değil — atlandı"; $hata++; continue }
  $kip = $Matches[1]
  if($govdeMetni -match '\[OKUNAMADI\]'){ Write-Host "  !! $kok [OKUNAMADI] içeriyor — yazılmaz"; $hata++; continue }
  $kayitlar = @(foreach($x in (Invoke-RestMethod -Uri ("$ambarUcu`?select=id,kaynak_ad,metin&tur=eq.cikmis-komisyon-cevabi&kaynak_ad=like." + [uri]::EscapeDataString("*($kok)")) -Headers $sbBasliklar -TimeoutSec 120)){ $x })
  if($kayitlar.Count -ne 1){ Write-Host "  !! $kok ambarda $($kayitlar.Count) kayıt — atlandı"; $hata++; continue }
  $eski = "$($kayitlar[0].metin)"
  $yedekYolu = Join-Path $yedekKlasoru "$kok.json"
  if($eski.StartsWith('SORULAR')){
    # -YenidenKur: yazılmış belge YEDEKTEN (ilk yazımdan önceki metin) yeniden kurulur; yedek yoksa dokunulmaz
    if(-not $YenidenKur){ Write-Host "  zaten yazılmış: $kok"; $atlandi++; continue }
    if(-not (Test-Path $yedekYolu)){ Write-Host "  !! $kok yeniden kurulamaz: yedek yok"; $hata++; continue }
    $eski = "$((Get-Content $yedekYolu -Raw -Encoding UTF8 | ConvertFrom-Json).metin)"
  }
  # 70 (16.09): motor/kapi-cikmis-gun.ps1 soru kısmını ilk "CEVAPLAR/CEVAP 1/YANITLAR" eşleşmesinde keser.
  #   DEGISTIR metninde soru ile cevap arasına tek başına "CEVAPLAR" satırı konur (ayraç — resmî metin değil).
  #   Resmî soru metni değiştirilmez; içinde bu kelimeler geçerse kırpılan kısım raporlanır.
  $kesimDeseni = '\bCEVAPLAR\b|\bCEVAP\s*1\b|\bCevap\s*1\b|\bYANITLAR\b'
  if($kip -eq 'DEGISTIR' -and $govdeMetni -notmatch "(?m)^CEVAPLAR\r?$"){ Write-Host "  !! $kok DEGISTIR metninde tek başına 'CEVAPLAR' ayraç satırı yok"; $hata++; continue }
  $soruKismi = if($kip -eq 'EKLE'){ $govdeMetni } else { [regex]::Split($govdeMetni,"(?m)^CEVAPLAR\r?$")[0] }
  $kesim = [regex]::Match($soruKismi, $kesimDeseni)
  if($kesim.Success){ Write-Host ("  ⚠ {0}: soru metninde '{1}' geçiyor — KAPI-CB soru kısmının son {2} karakterini keser (resmî metin korunur)" -f $kok,$kesim.Value,($soruKismi.Length - $kesim.Index)) }
  $yeni = if($kip -eq 'EKLE'){ "SORULAR`n$govdeMetni`n`n$kaynakNotu`n`n$($eski.Trim())" } else { $govdeMetni }
  Write-Host ("  {0} {1}: {2:N0} → {3:N0} kr" -f $kip,$kok,$eski.Length,$yeni.Length)
  if(-not $Yaz){ continue }
  if(-not (Test-Path $yedekYolu)){ [IO.File]::WriteAllText($yedekYolu,(ConvertTo-Json -InputObject ([ordered]@{ id=$kayitlar[0].id; kaynak_ad=$kayitlar[0].kaynak_ad; metin=$eski; yedeklendi=(Get-Date -Format 'dd.MM.yyyy HH:mm') }) -Depth 3),(New-Object Text.UTF8Encoding($false))) }
  $govde = ConvertTo-Json -InputObject ([ordered]@{ metin=$yeni }) -Compress
  $null = Invoke-RestMethod -Method Patch -Uri ("$ambarUcu`?id=eq." + $kayitlar[0].id) -Headers ($sbBasliklar + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120
  $geri = @(foreach($x in (Invoke-RestMethod -Uri ("$ambarUcu`?select=metin&id=eq." + $kayitlar[0].id) -Headers $sbBasliklar -TimeoutSec 120)){ $x })
  if($geri.Count -eq 1 -and "$($geri[0].metin)" -ceq $yeni){ $yazildi++ } else { Write-Host "  !! GERİ OKUMA TUTMADI: $kok" -ForegroundColor Red; $hata++ }
}
Write-Host ("{0}: yazılan {1} · zaten yazılmış {2} · hata {3}" -f $(if($Yaz){'YAZILDI'}else{'KURU PROVA'}),$yazildi,$atlandi,$hata)
if($hata){ exit 1 }
