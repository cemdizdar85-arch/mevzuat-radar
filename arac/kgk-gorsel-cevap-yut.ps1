# ============================================================================
#  KGK GÖRÜNTÜDEN OKUNAN CEVAPLARI AMBARA YUT   16.09.2026 (Cem "1 VE 2 YAP", GM 1)
#
#  NEDEN: arac/kgk-cikmis-tamlik.ps1 iki sınavda cevabı metinden okuyamadı:
#   - 15.05.2016 (kod 6551): kitapçıklar taranmış; ayrı cevap anahtarı YOK — doğru şık kitapçıkta dolu daireyle işaretli.
#   - 14.11.2020 (kod 10248): cevap anahtarı kitapçığın son sayfasında GÖRÜNTÜ; metin katmanında tek sütun var.
#  Cevaplar 16.09'da yerelde, PARASIZ okundu (API yok) ve üç bağımsız yoldan doğrulandı (yöntem her kaydın
#  "dogrulama" alanında). Okumalar veri/kgk-arsiv/gorsel-cevap-anahtari.json'dadır — GIT DIŞI (soru/cevap depoya girmez).
#
#  NE YAPAR (bedel 0, model yok):
#   - O dosyadaki her kitapçık için bir belge yazar:
#       tur='cikmis-soru' · kaynak_ad = "CIKMIS SINAV - KGK CEVAP (<kitapçık kökü>-GORSELANAHTAR)"
#       ("-GORSELANAHTAR" eki: diskte karşılığı olan bir dosya yok → karne bu belgeleri disk/ambar kıyasına katmaz)
#       metin = resmî başlık + modül modül "N. X" listesi + okuma/doğrulama notu + AYRIŞTIRILMIŞ CEVAPLAR satırı
#       kaynak_url = veri/kgk-arsiv/pdf-links.tsv'deki kitapçık adresi
#   - Her modül tam 40 harf (A–E) değilse DURUR. Var olanı ezmez. Yazdıktan sonra birebir geri okur.
#  Varsayılan KURU PROVA. Yazmak için -Yaz.
# ============================================================================
param([switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$arsiv = Join-Path (Join-Path $depoKok 'veri') 'kgk-arsiv'
$okumaYolu = Join-Path $arsiv 'gorsel-cevap-anahtari.json'
if(-not (Test-Path $okumaYolu)){ Write-Host 'KÖR: veri/kgk-arsiv/gorsel-cevap-anahtari.json yok (yalnız yerelde).'; exit 0 }
$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $sbAnahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

$okuma = Get-Content $okumaYolu -Raw -Encoding UTF8 | ConvertFrom-Json
$baglantilar = @(Get-Content (Join-Path $arsiv 'pdf-links.tsv') -Encoding UTF8 | Where-Object { $_.Trim() })
function DiskAdi([string]$kod, [string]$pdfAdresi){
  $yaprak = [uri]::UnescapeDataString(($pdfAdresi -split '/')[-1]) -replace '[^\w\.\-]','_'
  return ($kod + '_' + ($yaprak -replace '(?i)\.pdf$',''))
}
$ambardakiAdlar = New-Object System.Collections.Generic.HashSet[string]
foreach($kayit in (Invoke-RestMethod -Uri ("$ambarUcu`?select=kaynak_ad&tur=eq.cikmis-soru&kaynak_ad=like." + [uri]::EscapeDataString('CIKMIS SINAV - KGK CEVAP*') + '&order=kaynak_ad&limit=1000') -Headers $sbBasliklar -TimeoutSec 120)){ [void]$ambardakiAdlar.Add("$($kayit.kaynak_ad)") }

$yazilacak = New-Object System.Collections.Generic.List[object]
foreach($kitap in $okuma.kayitlar){
  $kaynakAdi = "CIKMIS SINAV - KGK CEVAP ($($kitap.kok)-GORSELANAHTAR)"
  $cevapSayisi = 0
  $liste = New-Object System.Text.StringBuilder
  $ayristirilmis = New-Object System.Text.StringBuilder
  foreach($modul in $kitap.moduller.PSObject.Properties){
    $harfler = "$($modul.Value)"
    if($harfler -cnotmatch '^[A-E]{40}$'){ Write-Host "  !! $($kitap.kok) · $($modul.Name): 40 harflik A–E dizisi değil — DURDU"; exit 1 }
    [void]$liste.AppendLine(''); [void]$liste.AppendLine($modul.Name)
    $ciftler = for($n = 1; $n -le 40; $n++){ "$n-$($harfler[$n-1])" }
    for($n = 1; $n -le 40; $n++){ [void]$liste.AppendLine("$n. $($harfler[$n-1])") }
    [void]$ayristirilmis.AppendLine("$($modul.Name) (40 soru): $($ciftler -join ', ')")
    $cevapSayisi += 40
  }
  $kaynakNotu = if($kitap.bicim -like 'kitapçıkta*'){
    "KAYNAK: KGK'nın yayımladığı soru kitapçığında her sorunun doğru şıkkı dolu daireyle işaretlidir; bu sınav için ayrı cevap anahtarı sayfası yayımlanmamıştır. Aşağıdaki liste kitapçıktaki işaretlerden okunmuştur."
  } else {
    "KAYNAK: KGK'nın yayımladığı kitapçığın son sayfasındaki cevap anahtarı. PDF'te bu sayfa görüntü olduğu için metin görüntüden yazıya geçirilmiştir."
  }
  $metin = ($kitap.resmi_baslik + "`n" + $kaynakNotu + "`n" + $liste.ToString() + "`nOKUMA VE DOĞRULAMA (16.09.2026, arac/kgk-gorsel-cevap-yut.ps1): " + $kitap.dogrulama + "`n`nAYRIŞTIRILMIŞ CEVAPLAR`nSınav tarihi: $($kitap.tarih) · Kitapçık: $($kitap.kitapcik) · Oturum: $($kitap.oturum)`n" + $ayristirilmis.ToString()).Trim()
  $kod = ($kitap.kok -split '_')[0]
  $adres = ''
  foreach($satir in $baglantilar){
    $parcalar = $satir -split "`t"; if($parcalar.Count -lt 3){ continue }
    if($parcalar[0].Trim([char]0xFEFF).Trim() -ne $kod){ continue }
    if((DiskAdi $kod $parcalar[2].Trim()) -eq $kitap.kok){ $adres = $parcalar[2].Trim(); break }
  }
  if($ambardakiAdlar.Contains($kaynakAdi)){ Write-Host "  zaten ambarda: $kaynakAdi"; continue }
  $yazilacak.Add([ordered]@{ tur='cikmis-soru'; kaynak_ad=$kaynakAdi; baslik="KGK cevap anahtarı $($kitap.tarih) $($kitap.kitapcik) $($kitap.oturum) (görüntüden, $cevapSayisi cevap) - 0 soru"; metin=$metin; kaynak_url=$adres })
  Write-Host ("  yazılacak: {0} · {1} cevap · {2:N0} kr · adres {3}" -f $kitap.kok,$cevapSayisi,$metin.Length,$(if($adres){'VAR'}else{'YOK'}))
}
if($yazilacak.Count -eq 0){ Write-Host 'Yazılacak belge yok.'; exit 0 }
if(-not $Yaz){ Write-Host "KURU PROVA — $($yazilacak.Count) belge. Yazmak için -Yaz"; exit 0 }
$govde = ConvertTo-Json -InputObject @($yazilacak.ToArray()) -Depth 4
if($govde.TrimStart()[0] -ne '['){ $govde = "[$govde]" }
$null = Invoke-RestMethod -Method Post -Uri $ambarUcu -Headers ($sbBasliklar + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120
$dogru = 0
foreach($belge in $yazilacak){
  $geri = @(foreach($x in (Invoke-RestMethod -Uri ("$ambarUcu`?select=metin&kaynak_ad=eq." + [uri]::EscapeDataString($belge.kaynak_ad)) -Headers $sbBasliklar -TimeoutSec 120)){ $x })
  if($geri.Count -eq 1 -and "$($geri[0].metin)" -ceq $belge.metin){ $dogru++ } else { Write-Host "  !! GERİ OKUMA TUTMADI: $($belge.kaynak_ad) (kayıt $($geri.Count))" -ForegroundColor Red }
}
Write-Host ("YAZILDI: {0} belge · geri okuma birebir {1}" -f $yazilacak.Count,$dogru)
if($dogru -ne $yazilacak.Count){ exit 1 }
