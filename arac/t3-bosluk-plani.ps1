# T3 BOSLUK PLANI (10.09.2026, Cem onayi: "onay veriyorum kur ve baslat") — 0 USD, model cagrisi yok.
#
# Ne yapar: veri/fabrika/konu-kapsama.csv'den EKSIGI OLAN konulari alir ve ders x seviye konu
# dosyalari + plan satirlari uretir. Kosucu bunlari toplu modda basar.
#
# ALDIGIMIZ KARARLAR BU BETIKTE UYGULANIR:
#   - Hedef konu basina sinavda cikan sorunun 3 kati. Ustune CIKILMAZ (Temmuz-Agustos asiri
#     basimi bir daha olmasin diye). Hedefe ulasmis konu plana GIRMEZ.
#   - Kaynagi olmayan konu BASILMAZ. Bu betik konu dosyasini uretir; kosudan once
#     arac/konu-kaynak-on-olcum.ps1 ayrica kosulur ve YOK cikan konu dosyadan cikarilir.
#   - Cop konu adlari (PDF okuma hatasindan kalanlar) plana alinmaz.
#
# Kullanim:
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/t3-bosluk-plani.ps1 -Ad sgs-t3 -EnAzCikan 2
#
# Cikti: veri/sinav/konu/<ad>-<ders>-<seviye>.json + veri/sinav/plan-<ad>.json

param([string]$Ad='sgs-t3', [int]$EnAzCikan=2, [int]$HedefKat=3)
$ErrorActionPreference='Stop'
$kok = Split-Path $PSScriptRoot -Parent

# ders -> kisa ad · uretici DersRegex · uzunluk tavani (plan-uret.ps1 $SIN tablosuyla ayni)
$SIN = @{
  'Finansal Muhasebe'            = @{ k='fmuh';    r='Finansal Muhasebe';                                   t=746 }
  'Denetim'                      = @{ k='denetim'; r='Denetim';                                             t=746 }
  'Maliyet Muhasebesi'           = @{ k='maliyet'; r='Maliyet Muhasebesi';                                  t=746 }
  'Mali Tablolar Analizi'        = @{ k='mta';     r='Mali Tablolar Analizi';                               t=411 }
  'Vergi Hukuku'                 = @{ k='vergi';   r='Vergi Hukuku';                                        t=300 }
  'Ticaret Hukuku'               = @{ k='ticaret'; r='Ticaret Hukuku|Ticaret ve Borclar';                   t=300 }
  'Borclar Hukuku'               = @{ k='borclar'; r='Borclar Hukuku|Ticaret ve Borclar';                   t=300 }
  'Is ve Sosyal Guvenlik Hukuku' = @{ k='issgk';   r='Is ve Sosyal Guvenlik Hukuku|Is ve Sosyal Guvenlik';  t=300 }
  'Meslek Hukuku'                = @{ k='meslek';  r='Meslek Hukuku';                                       t=300 }
  'Turkce'                       = @{ k='turkce';  r='Turkce';                                              t=300 }
  'Yabanci Dil'                  = @{ k='yd';      r='Yabanci Dil';                                         t=300 }
  'Matematik'                    = @{ k='mat';     r='Matematik';                                           t=300 }
  'Ekonomi'                      = @{ k='ekonomi'; r='Ekonomi';                                             t=300 }
  'Maliye'                       = @{ k='maliye';  r='^Maliye$';                                            t=300 }
  'Ataturk Ilke ve Inkilap Tarihi'= @{ k='inkilap';r='Ataturk Ilke';                                        t=300 }
}
# 10.09 TUZAK: bu desen once $COP adiyla yazilmisti, cop listesi de $cop adiyla. PowerShell harf
# AYIRMAZ, ikisi ayni degiskendir; liste desenin uzerine yazilinca regex bosaldi, bos regex her
# seyle eslesti ve sinavda 9 kez cikan 'cumle tamamlama' konusu cop sayilip plandan dustu.
# CLAUDE.md'deki kural: global sabitlere kisa ad verilmez.
$COP_DESEN = '(?i)okunamad|okunmad|bilinmiyor|belirsiz|\(\d+\s*soru|^\?+$|^\s*$'

$csv = Join-Path $kok 'veri\fabrika\konu-kapsama.csv'
if(-not (Test-Path $csv)){ Write-Host "konu-kapsama.csv yok - once arac/konu-kapsama-tablosu.ps1 kosulmali." -ForegroundColor Red; exit 1 }
$c = Import-Csv $csv -Encoding UTF8

$secilen = @(); $copListe = @(); $dersiYok = @()
foreach($x in $c){
  $ck = [int]$x.sinavda_cikan
  if($ck -lt $EnAzCikan){ continue }
  $hd = $ck * $HedefKat
  $ek = $hd - [int]$x.yayinlanabilir
  if($ek -le 0){ continue }
  if("$($x.konu)" -match $COP_DESEN){ $copListe += "$($x.konu) [$($x.ders)]"; continue }
  if(-not $SIN.ContainsKey("$($x.ders)")){ $dersiYok += "$($x.konu) [$($x.ders)]"; continue }
  $secilen += [pscustomobject]@{ ders="$($x.ders)"; konu="$($x.konu)"; cikan=$ck; hedef=$hd; eksik=$ek }
}
if($copListe.Count){ Write-Host "cop konu adi, plana alinmadi ($($copListe.Count)): $($copListe -join ' · ')" -ForegroundColor DarkYellow }
if($dersiYok.Count){ Write-Host "ders eslesmedi, plana alinmadi ($($dersiYok.Count)): $($dersiYok -join ' · ')" -ForegroundColor DarkYellow }

$konuDir = Join-Path $kok 'veri\sinav\konu'
New-Item -ItemType Directory -Force $konuDir | Out-Null
$plan = @()
foreach($g in ($secilen | Group-Object ders | Sort-Object { -($_.Group | Measure-Object -Property eksik -Sum).Sum })){
  $bilgi = $SIN[$g.Name]
  $liste = @($g.Group | Sort-Object { -$_.cikan } | ForEach-Object { $_.konu })
  foreach($sv in 'kolay','zor','cokzor'){
    $kd = Join-Path $konuDir "$Ad-$($bilgi.k)-$sv.json"
    [IO.File]::WriteAllText($kd,(ConvertTo-Json -InputObject @($liste) -Depth 2),[Text.UTF8Encoding]::new($false))
    $plan += [pscustomobject]@{
      ders=$bilgi.r; dersAd=$g.Name; etiket="$Ad-$($bilgi.k)-$sv"; adet=$liste.Count
      # ⛔ 12.09: GORECE yol (mutlak yerel yol bulutta cozulmez)
      tavan=$bilgi.t; zorluk=$sv; sinav='SGS'; konuDosya=("veri/sinav/konu/$Ad-$($bilgi.k)-$sv.json"); toplu=$true; disla=''; tur=3
      eksikToplam=($g.Group | Measure-Object -Property eksik -Sum).Sum
    }
  }
}
$planYol = Join-Path $kok "veri\sinav\plan-$Ad.json"
[IO.File]::WriteAllText($planYol,(ConvertTo-Json -InputObject @($plan) -Depth 4),[Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host ("PLAN: {0} ders · {1} konu · {2} etiket · eksik toplam {3} yayinlanabilir soru" -f @($secilen | Group-Object ders).Count, $secilen.Count, $plan.Count, ($secilen | Measure-Object -Property eksik -Sum).Sum) -ForegroundColor Green
Write-Host ("plan dosyasi: {0}" -f $planYol)
Write-Host ""
Write-Host ("{0,-32} {1,5} {2,7}" -f 'DERS','konu','eksik')
Write-Host ("-"*48)
foreach($g in ($secilen | Group-Object ders | Sort-Object { -($_.Group | Measure-Object -Property eksik -Sum).Sum })){
  Write-Host ("{0,-32} {1,5} {2,7}" -f $g.Name, $g.Count, ($g.Group | Measure-Object -Property eksik -Sum).Sum)
}
