#requires -Version 5.1
# ============================================================================
#  ÖZ-SINAV — arac/smmm-ah-yalniz.ps1 + arac/smmm-ah-yalniz.js (31.10.2026)   0 USD, AĞ YOK
#  1) node arac/smmm-ah-yalniz.js --sinav (sahte ambar: TEMIZ yazılır · KUSURLU → incelenecek + kaynak_okundu:false · taslak farklı → atlanır
#     · damga değişti → durur · yalnız hedef alan değişir · madde metni yok → kaynaksız · SGS kimliği atlanır · mutasyon)
#  2) PS uçtan uca, sahte ambar + sahte model (SMMM_AH_SAHTE): istem = çekirdek + RESMÎ MADDE METNİ · bütçe yetmez → BAŞLAMAZ (çıkış 4,
#     0 yazma) · KURU → 0 yazma · paralı yol → TEMIZ + KUSURLU kayda, sonuç dosyası · aynı içerik yeniden → gönderilmez
#  3) söz dizimi (Parser::ParseInput) — PS dosyaları
#  KULLANIM: powershell -NoProfile -File arac/smmm-ah-yalniz-sinavi.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$gecen = 0; $toplam = 0
function Sina([string]$ad, [bool]$ok) { $script:toplam++; if ($ok) { $script:gecen++; Write-Host "  [+] $ad" } else { Write-Host "  [-] $ad" -ForegroundColor Red } }

# 1) node öz-sınavı
$nodeCikti = @(& node (Join-Path $depoKok 'arac/smmm-ah-yalniz.js') --sinav)
$nodeKod = $LASTEXITCODE
$nodeCikti | ForEach-Object { Write-Host $_ }
# konsol kod sayfası Türkçe harfi bozabilir → "(N/N)" eşitliğiyle bakılır
Sina 'node öz-sınavı YEŞİL' ($nodeKod -eq 0 -and ($nodeCikti -join ' ') -match 'SINAVI \S+ \((\d+)/\1\)')

# 3) söz dizimi
foreach ($f in @('arac/smmm-ah-yalniz.ps1', 'arac/smmm-ah-yalniz-sinavi.ps1')) {
  $tk = $null; $hh = $null
  [void][System.Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText((Join-Path $depoKok $f), [Text.Encoding]::UTF8), [ref]$tk, [ref]$hh)
  Sina "söz dizimi temiz: $f" (-not @($hh).Count)
}

# 2) PS uçtan uca (sahte)
$psExe = $(if ($PSVersionTable.PSEdition -eq 'Core') { (Get-Process -Id $PID).Path } else { 'powershell' })
$T = Join-Path ([IO.Path]::GetTempPath()) ("smmm-ah-yalniz-ps-" + $PID)
$utf8 = [Text.UTF8Encoding]::new($false)
function Kur {
  if (Test-Path $T) { Remove-Item $T -Recurse -Force }
  New-Item -ItemType Directory -Force (Join-Path $T 'ambar') | Out-Null
  $parti = '{"icerik":{"kp-01":{"soru":"Sahte kök 1","dogru":"B","siklar":{"A":"10","B":"20"},"aciklama":{"A":"a","B":"b"},"dayanak":"KDVK (3065 s.K.) m.28","hakem":{"karar":"EVET","model":"model-b"}},"kp-02":{"soru":"Sahte kök 2","dogru":"A","siklar":{"A":"x","B":"y"},"aciklama":{"A":"p","B":"q"},"adimlar":[{"anlatim":"tek adım"}]},"kp-03":{"soru":"Dokunulmayan","dogru":"A","siklar":{"A":"m"}}},"guncelleme":"d1","sinav":"SMMM"}'
  [IO.File]::WriteAllText((Join-Path $T 'ambar/smmm-sahte-ps.json'), $parti, $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'dokuman.json'), '[{"kaynak_ad":"KDVK (3065 s.K.) m.28","metin":"Katma değer vergisinin genel oranı yüzde yirmidir. SAHTE-MADDE-IZI"}]', $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'model.json'), '{"ah-smmm-sahte-ps__kp-01":"{\"karar\":\"TEMIZ\",\"kusurlar\":[]}","ah-smmm-sahte-ps__kp-02":"{\"karar\":\"KUSURLU\",\"kusurlar\":[{\"alan\":\"adimlar[0]\",\"neden\":\"sahte gerekçe\"}]}"}', $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'girdi.json'), '{"ad":"ps-sinav","kimlikler":[{"soru_id":"smmm-sahte-ps/kp-01","dayanaklar":[{"kaynak_ad":"KDVK (3065 s.K.) m.28","alinti":"genel oranı yüzde yirmidir"}]},{"soru_id":"smmm-sahte-ps/kp-02"},{"soru_id":"sgs-sahte/kp-01"}]}', $utf8)
}
function Kos([string[]]$ek) {
  $env:SMMM_AH_SAHTE = $T; $eapEski = $ErrorActionPreference; $ErrorActionPreference = 'Continue'   # PS 5.1: 2>&1 yerel süreç stderr'ini hata sayar
  try { $o = @(& $psExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $depoKok 'arac/smmm-ah-yalniz.ps1') -Girdi (Join-Path $T 'girdi.json') -SonucYolu (Join-Path $T 'sonuc.json') @ek 2>&1); $k = $LASTEXITCODE }
  finally { Remove-Item Env:SMMM_AH_SAHTE -ErrorAction SilentlyContinue; $ErrorActionPreference = $eapEski }
  return @{ kod = $k; metin = ($o | ForEach-Object { "$_" }) -join "`n" }
}
function Parti { return (ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $T 'ambar/smmm-sahte-ps.json'), [Text.Encoding]::UTF8))) }
try {
  Kur; $ilk = [IO.File]::ReadAllText((Join-Path $T 'ambar/smmm-sahte-ps.json'))
  $r = Kos @()
  Sina 'KURU (−Calistir yok) → çıkış 0, ambar bayt bayt aynı' ($r.kod -eq 0 -and $r.metin -match 'KURU' -and [IO.File]::ReadAllText((Join-Path $T 'ambar/smmm-sahte-ps.json')) -ceq $ilk)
  $r = Kos @('-ButceUsd', '0.001', '-Calistir')
  Sina 'BÜTÇE YETMEZ (0,001 USD) → BAŞLAMAZ, çıkış 4, ambar bayt bayt aynı, sonuç yok' ($r.kod -eq 4 -and $r.metin -match 'YETMEZ' -and [IO.File]::ReadAllText((Join-Path $T 'ambar/smmm-sahte-ps.json')) -ceq $ilk -and -not (Test-Path (Join-Path $T 'sonuc.json')))
  $r = Kos @('-Calistir')
  Sina 'bütçe parametresi yok → paralı koşu başlamaz (çıkış ≠ 0, 0 yazma)' ($r.kod -ne 0 -and [IO.File]::ReadAllText((Join-Path $T 'ambar/smmm-sahte-ps.json')) -ceq $ilk)
  $r = Kos @('-ButceUsd', '1', '-Calistir')
  $P = Parti; $S = $(if (Test-Path (Join-Path $T 'sonuc.json')) { ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $T 'sonuc.json'), [Text.Encoding]::UTF8)) } else { $null })
  if ($r.kod -ne 0) { Write-Host $r.metin }
  Sina 'PARALI (sahte model) → çıkış 0' ($r.kod -eq 0)
  $ist = [IO.File]::ReadAllText((Join-Path $T 'istem-ah-smmm-sahte-ps__kp-01.txt'), [Text.Encoding]::UTF8)
  Sina 'istem = çekirdek AciklamaHakemIs metni + RESMÎ MADDE METNİ (ambardan) + kural' ($ist -match 'ÇÖZÜM ANLATIMINI denetleyen' -and $ist -match 'RESMÎ MADDE METNİ \(ambardaki' -and $ist -match 'SAHTE-MADDE-IZI' -and $ist -match 'MADDE METNİ KURALI')
  $ist2 = [IO.File]::ReadAllText((Join-Path $T 'istem-ah-smmm-sahte-ps__kp-02.txt'), [Text.Encoding]::UTF8)
  Sina 'dayanaksız + kartsız kayıt → istemde "okunamadı" notu (kaynaksız)' ($ist2 -match 'dayanağı okunamadı')
  Sina 'kp-01 TEMIZ kayda yazıldı (model nötr kod, yol izi)' ("$($P.icerik.'kp-01'.aciklama_hakem.karar)" -eq 'TEMIZ' -and "$($P.icerik.'kp-01'.aciklama_hakem.model)" -eq 'model-c' -and "$($P.icerik.'kp-01'.aciklama_hakem.yol)" -eq 'smmm-ah-yalniz')
  Sina 'kp-02 KUSURLU → kaynak_okundu:false + incelenecek + kaynaksiz' ("$($P.icerik.'kp-02'.aciklama_hakem.karar)" -eq 'KUSURLU' -and $P.icerik.'kp-02'.aciklama_hakem.kaynak_okundu -eq $false -and $P.icerik.'kp-02'.aciklama_hakem.incelenecek -eq $true -and $P.icerik.'kp-02'.aciklama_hakem.kaynaksiz -eq $true)
  Sina 'kp-03 (hedef dışı) dokunulmadı' (-not $P.icerik.'kp-03'.PSObject.Properties['aciklama_hakem'] -and "$($P.icerik.'kp-03'.soru)" -eq 'Dokunulmayan')
  Sina 'sonuç: TEMIZ 1 · KUSURLU 1 · incelenecek=kp-02 · kaynaksız kusurlu=kp-02 · sgs kimliği atlandı' ($S -and $S.sayim.temiz -eq 1 -and $S.sayim.kusurlu -eq 1 -and (@($S.incelenecek) -join ',') -eq 'smmm-sahte-ps/kp-02' -and (@($S.kaynaksiz_kusurlu) -join ',') -eq 'smmm-sahte-ps/kp-02' -and $S.atlanan.PSObject.Properties['sgs-sahte/kp-01'])
  Sina 'sonuç dosyasında soru metni ve gerekçe YOK' ($S -and -not ((ConvertTo-Json -InputObject $S -Depth 12) -match 'Sahte kök|sahte gerekçe'))
  $r = Kos @('-ButceUsd', '1', '-Calistir')
  $S2 = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $T 'sonuc.json'), [Text.Encoding]::UTF8))
  Sina 'aynı içerik yeniden koşuldu → 0 gönderim (önceki 2), çıkış 0' ($r.kod -eq 0 -and $S2.sayim.onceki -eq 2 -and $S2.sayim.gonderilen -eq 0 -and $r.metin -match 'GÖNDERİLECEK: 0')
  # 31.10 thp vakası (Ajan 18): özet ESKİ, ambarda sonradan UYGULAMA NOTU → istemin RESMÎ MADDE METNİ bölümünde not görünür
  [IO.File]::WriteAllText((Join-Path $T 'ambar/smmm-sahte-not.json'), '{"icerik":{"kp-01":{"soru":"Sahte kök not","dogru":"A","siklar":{"A":"657","B":"647"},"aciklama":{"A":"a","B":"b"},"kaynak_metin_ozet":"THP 122 Alıcı senetleri reeskontu hesabı alacak senetlerinin reeskontunu izler.","kaynak_adlar":["THP SAHTE 122"]}},"guncelleme":"n1","sinav":"SMMM"}', $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'dokuman.json'), '[{"kaynak_ad":"THP SAHTE 122","metin":"THP 122 Alıcı senetleri reeskontu hesabı alacak senetlerinin reeskontunu izler. UYGULAMA NOTU: MSUGT Sıra No 2 ile bu işlem artık 657 hesapta izlenir. SAHTE-NOT-IZI"}]', $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'model.json'), '{"ah-smmm-sahte-not__kp-01":"{\"karar\":\"TEMIZ\",\"kusurlar\":[]}"}', $utf8)
  [IO.File]::WriteAllText((Join-Path $T 'girdi.json'), '{"ad":"ps-sinav-not","kimlikler":[{"soru_id":"smmm-sahte-not/kp-01"}]}', $utf8)
  $r = Kos @('-ButceUsd', '1', '-Calistir')
  $ist3 = $(if (Test-Path (Join-Path $T 'istem-ah-smmm-sahte-not__kp-01.txt')) { [IO.File]::ReadAllText((Join-Path $T 'istem-ah-smmm-sahte-not__kp-01.txt'), [Text.Encoding]::UTF8) } else { '' })
  Sina 'özet eski + ambarda UYGULAMA NOTU → istemde RESMÎ MADDE METNİ bölümünde not görünür (özet eskidir etiketiyle)' ($r.kod -eq 0 -and $ist3 -match 'RESMÎ MADDE METNİ' -and $ist3 -match 'UYGULAMA NOTU: MSUGT' -and $ist3 -match 'SAHTE-NOT-IZI' -and $ist3 -match 'özetinde OLMAYAN')
}
finally { if (Test-Path $T) { Remove-Item $T -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Host ("SMMM-AH-YALNIZ PS ÖZ-SINAVI {0} ({1}/{2})" -f $(if ($gecen -eq $toplam) { 'YEŞİL' } else { 'KIRMIZI' }), $gecen, $toplam)
exit $(if ($gecen -eq $toplam) { 0 } else { 1 })
