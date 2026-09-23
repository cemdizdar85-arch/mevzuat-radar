#requires -Version 5.1
<#
================================================================================
  COMMIT İDDİA DENETİMİ — mesaj "şu dosyayı değiştirdim" diyor, dosya commit'te mi?   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): o gün iki kez değişiklik "yapıldı" diye gönderildi ama dosyaya girmemişti
  (cc4b6a6e: mesaj "2) CLAUDE.md KAPI KURMA KURALLARI md.8" diyor, CLAUDE.md düzenlemesi metin eşleşmediği için
  uygulanmamıştı; tek sayfa düzenlemesi 'R' takma adı yüzünden sessizce uygulanmadı).
  İDDİA = mesajda SATIR BAŞINDA (isteğe bağlı "N)" ile) duran depo yolu, ardından ':' '(' ya da boşluk — ama
  boşluk + '-' DEĞİL (o bir komut örneğidir: "arac/x.ps1 -Yaz ile üretildi").
  ÖLÇÜLDÜ (23.09, o günün 59 Claude commit'i, 41 iddia): kural 1 gerçek vakayı (cc4b6a6e) yakaladı; komut örneği ayıklanınca
  yanlış alarm 0 (ayıklamadan önce 2).
  🚫 GÖRMEZ: satır içinde geçen yol; dosya commit'te olup İÇİNDE iddia edilen değişikliğin olmaması (içerik doğrulanmaz);
     robot commit'leri (Co-Authored-By: Claude olmayan) atlanır.
  KULLANIM: commit'ten SONRA, push'tan ÖNCE:  powershell -NoProfile -File arac/commit-iddia-denetimi.ps1 [-Ref HEAD]
            çıkış 1 = mesajda anılan dosya commit'te yok → push etme, düzelt.   -Sinav: öz-sınav.
================================================================================
#>
param([string]$Ref = 'HEAD', [switch]$Sinav)
$ErrorActionPreference = 'Stop'
$script:IDDIA_RX = '^\s*(?:\d+\)\s*)?((?:\.github/workflows|arac|motor|veri|radar-app|kaydir|kutuphane)/[\w./-]+\.\w+|CLAUDE\.md|[\w-]+\.(?:html|js|css|md))(?=\s*[:(]|\s+(?!-))'
function IddiaEksik([string]$mesaj, [string[]]$dosyalar) {
  $eksik = New-Object System.Collections.Generic.List[string]
  foreach ($l in ($mesaj -split "`r?`n")) { $m = [regex]::Match($l, $script:IDDIA_RX); if (-not $m.Success) { continue }
    $p = $m.Groups[1].Value; if ($dosyalar -notcontains $p -and -not $eksik.Contains($p)) { $eksik.Add($p) } }
  return , $eksik.ToArray()
}
if ($Sinav) {
  $gecti = 0; $dustu = @()
  function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++ } else { $script:dustu += $ad } }
  T 'gerçek vaka cc4b6a6e: "2) CLAUDE.md …" ama CLAUDE.md commit''te yok → YAKALANIR' ((IddiaEksik "baslik`n`n2) CLAUDE.md KAPI KURMA KURALLARI md.8: kural" @('motor/gece-paket.ps1')).Count -eq 1)
  T '"arac/x.ps1: …" dosya commit''te → sorun yok' ((IddiaEksik "baslik`narac/had-kapisi.ps1: DAR kapi" @('arac/had-kapisi.ps1')).Count -eq 0)
  T 'komut örneği "arac/x.ps1 -Yaz ile" → iddia sayılmaz (yanlış alarm yok)' ((IddiaEksik "arac/smmm-kaydir-dizin.ps1 -Yaz ile yeniden uretildi" @()).Count -eq 0)
  T 'satır içi yol → iddia sayılmaz' ((IddiaEksik "Kural: arac/smmm-yayin-sarti.ps1 bunu okur" @()).Count -eq 0)
  T '"veri/sinav/x.json (yeni)" parantezli iddia yakalanır' ((IddiaEksik "veri/sinav/had-guncel.json (madde -> tutar)" @('arac/x.ps1')).Count -eq 1)
  T 'aynı dosya iki kez anılırsa bir kez sayılır' ((IddiaEksik "CLAUDE.md: a`nCLAUDE.md: b" @()).Count -eq 1)
  Write-Host "COMMIT İDDİA ÖZ-SINAVI: $gecti/$($gecti + $dustu.Count) geçti"; if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }; exit 0
}
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$mesaj = (git log -1 --format='%B' $Ref) -join "`n"
if ($mesaj -notmatch 'Co-Authored-By: Claude') { Write-Host "COMMIT İDDİA: $Ref robot/insan commit'i — atlandı"; exit 0 }
$dosyalar = @(git show --name-only --format='' $Ref | Where-Object { $_ })
$eksik = IddiaEksik $mesaj $dosyalar
if ($eksik.Count) { Write-Host ("⛔ COMMIT İDDİA: mesaj şu dosyaları değiştirdiğini söylüyor ama commit'te YOK: {0} — düzenleme uygulanmamış olabilir; push etmeden dosyayı oku." -f ($eksik -join ', ')) -ForegroundColor Red; exit 1 }
Write-Host ("COMMIT İDDİA: tamam ({0} dosya)" -f $dosyalar.Count); exit 0
