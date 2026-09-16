#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) YENİ HAT DURUMU — "yeni kalıpla bastığımız sorular hangi kapıda?"   16.09.2026 (bedel 0, model yok)
#
#  NEDEN (Cem 16.09 "kasada ne sorusu var, yeni bastık ... eski şekil basmadık" + "1.2.3"): kasadaki (soru_havuzu) 12.576 bitirme sorusunun
#  hepsi eski kalıp (kota-v2, kalip_surum v1, 27.08'den beri yeni satır yok). Yeni hat (Kaydır-Çöz kalıbı, kör çözüm, iki hakem) ambarın
#  kalip_parti tablosunda durur. Bu araç o partileri okur ve YAYIN ŞARTINI arac/havuz-kur.ps1 ile BİREBİR aynı kurala göre sayar;
#  sorunun hangi kapıda düştüğünü (ilk düşen kapı) yazar. Soru metni YAZILMAZ — yalnız sayı.
#  Pilot partiler (etikette 'pilot') havuz-kur'da yayına GİRMEZ; burada ayrıca gösterilir.
#  Çıktı: veri/sinav/SMMM-YENI-HAT-DURUM.md (RaporYaz değil, düz md; tarih satırı dışında içerik değişmezse git fark göstermez).
# ============================================================================
param([string]$Cikti = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$ANAHTAR_SB = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $ANAHTAR_SB) { $ANAHTAR_SB = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $ANAHTAR_SB) { throw 'SUPABASE_SERVICE_KEY yok' }
$SB_BASLIK = @{ apikey = $ANAHTAR_SB; Authorization = "Bearer $ANAHTAR_SB"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
if (-not $Cikti) { $Cikti = Join-Path $depoKok 'veri\sinav\SMMM-YENI-HAT-DURUM.md' }

$yanit = Invoke-WebRequest -UseBasicParsing -Uri 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,icerik&sinav=eq.SMMM&limit=2000' -Headers $SB_BASLIK -TimeoutSec 300
$satirlar = @((ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($yanit.RawContentStream.ToArray()))) | ForEach-Object { $_ })

# havuz-kur.ps1 satır 119-128 ile aynı sıra: ilk tutmayan kapı yazılır
function IlkDusen($v) {
  if (-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')) { return '1 hakem HAYIR/yok' }
  if ("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS') { return '1b hesap yanlış' }
  if ("$($v.hakem.ders_uyum)" -eq 'DERS-DISI') { return '1c ders dışı' }
  if ("$($v.hakem.konu_uyum)" -eq 'KONU-DISI') { return '1d konu dışı' }
  if ("$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM') { return '1e çift anlam' }
  if (-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)) { return '2 kör çözüm tutmadı/yok' }
  if (-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')) { return '3 hakem2 HAYIR/yok' }
  foreach ($sa in 'simulasyon_sonnet', 'simulasyon') { if ($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu) { return '4 simülasyon tutmadı' } }
  return ''
}
$parti = New-Object System.Collections.Generic.List[object]
$dusus = @{}
foreach ($r in $satirlar) {
  $ic = $r.icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }
  $pilot = ("$($r.etiket)" -match '(^|-)pilot\d*(-|$)')
  $n = 0; $gec = 0
  foreach ($p in $ic.PSObject.Properties) {
    $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $n++; $d = IlkDusen $v
    if (-not $d) { $gec++ } else { $anah = "$(if ($pilot) { 'pilot' } else { 'yayın adayı' })|$d"; $dusus[$anah] = 1 + [int]$dusus[$anah] }
  }
  $parti.Add([pscustomobject]@{ etiket = "$($r.etiket)"; pilot = $pilot; soru = $n; gecen = $gec })
}
$dizi = $parti.ToArray()
$yp = @($dizi | Where-Object { -not $_.pilot }); $pp = @($dizi | Where-Object { $_.pilot })
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('# Bitirme (SMMM) — yeni hat soru durumu')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("> Üretici: ``arac/smmm-yeni-hat-durum.ps1`` · ölçüm $(Get-Date -Format 'dd.MM.yyyy HH:mm') · kaynak: ambar ``kalip_parti`` (sinav=SMMM) · yayın şartı ``arac/havuz-kur.ps1`` ile birebir.")
[void]$sb.AppendLine('> Kasa (``soru_havuzu``) ayrı: 12.576 bitirme sorusu ESKİ kalıp (kota-v2, ``kalip_surum=v1``) — yayına çıkamaz (``ck_soru_havuzu_yayin_yalniz_v2``).')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Küme | Parti | Soru | Dört kapıdan geçen |')
[void]$sb.AppendLine('|---|---:|---:|---:|')
[void]$sb.AppendLine("| Yayın adayı (pilot olmayan) | $($yp.Count) | $(($yp | Measure-Object soru -Sum).Sum) | **$(($yp | Measure-Object gecen -Sum).Sum)** |")
[void]$sb.AppendLine("| Pilot (havuz-kur yayına ALMAZ) | $($pp.Count) | $(($pp | Measure-Object soru -Sum).Sum) | $(($pp | Measure-Object gecen -Sum).Sum) |")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Düşülen ilk kapı')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Küme | Kapı | Soru |')
[void]$sb.AppendLine('|---|---|---:|')
foreach ($k in ($dusus.Keys | Sort-Object)) { $q = $k -split '\|', 2; [void]$sb.AppendLine("| $($q[0]) | $($q[1]) | $($dusus[$k]) |") }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Parti parti')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Parti | Pilot | Soru | Geçen |')
[void]$sb.AppendLine('|---|:-:|---:|---:|')
foreach ($x in ($dizi | Sort-Object pilot, etiket)) { [void]$sb.AppendLine("| $($x.etiket) | $(if ($x.pilot) { 'evet' } else { '' }) | $($x.soru) | $($x.gecen) |") }
[IO.File]::WriteAllText($Cikti, $sb.ToString(), [Text.UTF8Encoding]::new($false))
"YENİ HAT: parti $($dizi.Count) · yayın adayı $($yp.Count) parti / $(($yp | Measure-Object soru -Sum).Sum) soru / geçen $(($yp | Measure-Object gecen -Sum).Sum) · pilot $($pp.Count) parti / $(($pp | Measure-Object soru -Sum).Sum) soru / geçen $(($pp | Measure-Object gecen -Sum).Sum)"
foreach ($k in ($dusus.Keys | Sort-Object)) { "  düşen · $k : $($dusus[$k])" }
"yazıldı: $Cikti"
