# ============================================================================
#  KASA TAVAN ÖLÇÜMÜ — gerçek kullanım dağılımı (0 USD, yalnız okur)
#
#  NEDEN (Cem 10.10 "3 yap"): kasa tavanları (10 dk 1.500 · 24 sa 4.000 · 7 gün 12.000 farklı soru,
#  radar-app/sql/2026-10-10-kasa-tekil-sayim.sql) ÖLÇÜLMEDEN kondu. Bu betik kasa_cekim kütüğünden
#  üye başına en yoğun 10 dk / gün / 7 gün farklı soru sayısını çıkarır; tavan bu dağılıma göre ayarlanır.
#
#  ÇIKTI: yalnız SAYI (kişi verisi yok: üye kimliği yazılmaz, sıra numarasıyla). Ekrana basar.
#  BU BETİK ŞUNU GÖRMEZ:
#    - Pencereler kayan değil, sabit kova: 10 dk = saat dilimi kovası, gün = TR takvim günü, hafta = son 7 gün toplamı.
#      Kayan pencere tepe değeri bundan biraz yüksek olabilir.
#    - Tavana takılıp vazgeçen üyenin "isteyip alamadığı" miktar (TAVAN satırı adetsiz) — yalnız takılma sayısı.
#    - 10.10 göçünden önceki idler satırları tekil = adet (fazla sayar).
#
#  KULLANIM: powershell -NoProfile -File arac/kasa-tavan-olcum.ps1 [-Gun 14]
#  GEREK: $env:SUPABASE_SERVICE_KEY (yerel). Bulutta koşmaz (kişi verisi Actions'a girmez).
# ============================================================================
[CmdletBinding()]
param([int]$Gun = 14)
$ErrorActionPreference = 'Stop'
$B = 'https://bjrleanjpyujtajmazxn.supabase.co'
$k = $env:SUPABASE_SERVICE_KEY
if (-not $k) { Write-Output 'KÖR: SUPABASE_SERVICE_KEY yok'; exit 1 }
$bas = (Get-Date).ToUniversalTime().AddDays(-$Gun).ToString('yyyy-MM-ddTHH:mm:ss')

# sayfalı oku (PostgREST 1.000 satır sınırı)
$satirlar = New-Object System.Collections.Generic.List[object]
$ofset = 0
while ($true) {
  $u = "$B/rest/v1/kasa_cekim?select=user_id,sayfa,adet,tekil,zaman&zaman=gte.$bas&order=id.asc&limit=1000&offset=$ofset"
  $parca = Invoke-RestMethod -Uri $u -Headers @{ apikey = $k } -UserAgent 'tetikte-motor'
  $parcaDizi = @($parca)
  foreach ($p in $parcaDizi) { $satirlar.Add($p) }
  if ($parcaDizi.Count -lt 1000) { break }
  $ofset += 1000
}
$trSaat = [TimeSpan]::FromHours(3)
$cekim = @($satirlar | Where-Object { $_.sayfa -notlike 'TAVAN:*' })
$tavanSatir = @($satirlar | Where-Object { $_.sayfa -like 'TAVAN:*' })

function Yuzdelik([double[]]$dizi, [double]$p) {
  if ($dizi.Length -eq 0) { return 0 }
  $s = $dizi | Sort-Object
  $i = [Math]::Min($s.Length - 1, [Math]::Ceiling($p * $s.Length) - 1)
  return [int]$s[[Math]::Max(0, $i)]
}

$uyeTepe = foreach ($g in ($cekim | Group-Object user_id)) {
  $kayit = foreach ($r in $g.Group) {
    $z = ([DateTimeOffset]::Parse($r.zaman)).ToUniversalTime() + $trSaat
    $t = if ($null -ne $r.tekil) { [int]$r.tekil } else { [int]$r.adet }
    [pscustomobject]@{ z = $z; t = $t; ham = [int]$r.adet }
  }
  $dk10 = ($kayit | Group-Object { $_.z.ToString('yyyyMMddHH') + [string][Math]::Floor($_.z.Minute / 10) } | ForEach-Object { ($_.Group | Measure-Object t -Sum).Sum } | Measure-Object -Maximum).Maximum
  $gunler = @($kayit | Group-Object { $_.z.ToString('yyyyMMdd') } | ForEach-Object { [int](($_.Group | Measure-Object t -Sum).Sum) })
  $hafta = 0
  foreach ($gg in ($kayit | Group-Object { $_.z.Date })) {
    $son = $gg.Group[0].z.Date   # $gg.Name metin; [DateTime] dönüşümü TR kültüründe bozuluyordu (ilk koşu 0 verdi)
    $top = ($kayit | Where-Object { $_.z.Date -le $son -and $_.z.Date -gt $son.AddDays(-7) } | Measure-Object t -Sum).Sum
    if ($top -gt $hafta) { $hafta = $top }
  }
  [pscustomobject]@{
    dk10 = [int]$dk10; gun = [int](($gunler | Measure-Object -Maximum).Maximum); hafta = [int]$hafta
    aktifGun = $gunler.Count; ham = [int](($kayit | Measure-Object ham -Sum).Sum); tekil = [int](($kayit | Measure-Object t -Sum).Sum)
  }
}
$uyeTepe = @($uyeTepe)

Write-Output ("KASA TAVAN ÖLÇÜMÜ · son {0} gün · {1} çekim satırı · {2} üye · tavana takılma {3} kez ({4} üye)" -f `
  $Gun, $cekim.Count, $uyeTepe.Count, $tavanSatir.Count, @($tavanSatir | Select-Object -ExpandProperty user_id -Unique).Count)
if ($uyeTepe.Count -eq 0) { Write-Output 'VERİ YOK: kütükte çekim yok — tavan ayarı için ölçülecek bir şey yok.'; exit 0 }
$tablo = foreach ($p in @(@{ ad = '10 dk'; a = 'dk10'; tavan = 1500 }, @{ ad = 'gün'; a = 'gun'; tavan = 4000 }, @{ ad = '7 gün'; a = 'hafta'; tavan = 12000 })) {
  $d = [double[]]@($uyeTepe | ForEach-Object { $_.($p.a) })
  [pscustomobject]@{
    pencere = $p.ad; tavan = $p.tavan
    p50 = Yuzdelik $d 0.5; p90 = Yuzdelik $d 0.9; p99 = Yuzdelik $d 0.99; en_yuksek = [int](($d | Measure-Object -Maximum).Maximum)
    tavanin_yarisini_asan_uye = @($d | Where-Object { $_ -gt $p.tavan / 2 }).Count
  }
}
$tablo | Format-Table -AutoSize | Out-String -Width 160 | Write-Output
$hamTop = ($uyeTepe | Measure-Object ham -Sum).Sum; $tekTop = ($uyeTepe | Measure-Object tekil -Sum).Sum
Write-Output ("ham satır / farklı soru oranı: {0} / {1} = {2:N1} (sayfa yeniden açma katsayısı)" -f $hamTop, $tekTop, ($(if ($tekTop) { $hamTop / $tekTop } else { 0 })))
Write-Output ("en çok çeken 5 üye (sıra no; gün tepesi · 7 gün tepesi · aktif gün): " + (($uyeTepe | Sort-Object gun -Descending | Select-Object -First 5 | ForEach-Object { "$($_.gun)·$($_.hafta)·$($_.aktifGun)g" }) -join ' | '))
