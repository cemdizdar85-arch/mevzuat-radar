# ============================================================================
#  ALACAK KASASI YEDEGI  (04.09.2026, Cem: "1 ve 2 yap")
#
#  NIYE: ilan.gov.tr TAM 365 gun tutuyor; kaynaktan dusen ilani YALNIZ bizim
#  kasamiz (Supabase public.alacak_ilan) tasiyor. Bu tablo bozulursa/silinirse
#  1 yildan eski kayitlar hicbir yerden geri alinamaz (04.09 olcumu: canli API,
#  Wayback, TTSG - hepsi kapali). Supabase'in kendi yedegi 7 gun tutar, kalici
#  degil. Bu betik tabloyu OneDrive DISINA (C:\TETIKTE-YEDEK) tam kopyalar.
#
#  NEREDE KOSAR: Cem'in makinesinde, Windows Gorev Zamanlayici (haftalik, Pazar 09:00).
#    Actions'ta KOSMAZ: depo public, yedek dosyasi TCKN/VKN tasir, disari cikamaz.
#  ANAHTAR: SUPABASE_SERVICE_KEY (User-env). Yoksa "atlandi" der, 0 ile cikar.
#
#  YAZ -> GERI OKU -> KARSILASTIR: kasadaki satir sayisi (alacak_sayi RPC ya da
#  Content-Range) ile dosyadaki satir sayisi esit degilse dosya .HATALI uzantisiyla
#  birakilir ve betik 1 ile cikar - eksik yedek "yedek var" sanilmasin.
#
#  KULLANIM:  powershell -NoProfile -File motor\alacak-kasa-yedek.ps1
#             $env:YEDEK_KOK ile hedef klasor degistirilebilir (test icin).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$SB_URL  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtar) { $anahtar = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtar) {
  Write-Host 'ATLANDI: SUPABASE_SERVICE_KEY yok - kasa yedegi alinmadi. Yerelde: anahtar-kur.cmd'
  exit 0
}

$yedekKok = if ("$($env:YEDEK_KOK)".Trim()) { $env:YEDEK_KOK } else { 'C:\TETIKTE-YEDEK\alacak-kasa' }
if (-not (Test-Path $yedekKok)) { New-Item -ItemType Directory -Force -Path $yedekKok | Out-Null }
$damga = (Get-Date).ToString('yyyyMMdd-HHmm')
$hedef = Join-Path $yedekKok ("alacak-kasa-{0}.json" -f $damga)
$log   = Join-Path $yedekKok 'yedek-log.txt'

$H = @{
  'apikey'        = $anahtar
  'Authorization' = "Bearer $anahtar"
  'Accept'        = 'application/json'
  'User-Agent'    = 'MevzuatRadar-AlacakKasaYedek'
}

# --- 1) KASADAKI SATIR SAYISI (bagimsiz olcum; Content-Range ile) --------------
$sayimIstek = [System.Net.WebRequest]::Create("$SB_URL/rest/v1/alacak_ilan?select=ilan_no&limit=1")
$sayimIstek.Method = 'HEAD'
foreach ($k in $H.Keys) { if ($k -eq 'Accept') { $sayimIstek.Accept = $H[$k] } elseif ($k -eq 'User-Agent') { $sayimIstek.UserAgent = $H[$k] } else { $sayimIstek.Headers[$k] = $H[$k] } }
$sayimIstek.Headers['Prefer'] = 'count=exact'
$sayimYanit = $sayimIstek.GetResponse()
$aralik = "$($sayimYanit.Headers['Content-Range'])"   # ornek: 0-0/6011
$sayimYanit.Close()
$kasaSayi = 0
if ($aralik -match '/(\d+)$') { $kasaSayi = [int]$Matches[1] }
if ($kasaSayi -le 0) { throw "Kasa sayisi okunamadi (Content-Range='$aralik') - yedek alinmadi." }
Write-Host ("KASA: {0} satir" -f $kasaSayi)

# --- 2) SAYFA SAYFA INDIR (1000'lik dilim, ilan_no sirali - 'order'siz sayfalama kararsiz) --
$hepsi = New-Object System.Collections.Generic.List[object]
$dilim = 1000; $bas = 0
while ($true) {
  $u = "$SB_URL/rest/v1/alacak_ilan?select=*&order=ilan_no.asc&offset=$bas&limit=$dilim"
  $p = $null
  for ($deneme = 1; $deneme -le 3 -and $null -eq $p; $deneme++) {
    try { $p = Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 180 }
    catch { Write-Host ("  dilim {0} deneme {1}/3 hata: {2}" -f $bas, $deneme, $_.Exception.Message); if ($deneme -lt 3) { Start-Sleep -Seconds 5 } }
  }
  if ($null -eq $p) { throw "dilim $bas 3 denemede alinamadi - yedek EKSIK, yazilmadi." }
  $p = @($p)
  foreach ($x in $p) { $hepsi.Add($x) }
  Write-Host ("  {0,6} / {1}" -f $hepsi.Count, $kasaSayi)
  if ($p.Count -lt $dilim) { break }
  $bas += $dilim
}

# --- 3) YAZ ---------------------------------------------------------------------
$cikti = [ordered]@{
  yedekZamani = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  kaynak      = 'Supabase public.alacak_ilan (tam tablo, TCKN dahil - DISARI CIKMAZ)'
  kasaSayi    = $kasaSayi
  adet        = $hepsi.Count
  satirlar    = $hepsi
}
[System.IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 6 -Compress), (New-Object System.Text.UTF8Encoding $false))

# --- 4) GERI OKU -> KARSILASTIR ---------------------------------------------------
$geri = Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json
$dosyaSayi = @($geri.satirlar).Count
$tarihler = @($geri.satirlar | ForEach-Object { "$($_.tarih)" } | Where-Object { $_ -match '^\d{4}-\d{2}-\d{2}' } | Sort-Object)
$enEski = if ($tarihler.Count) { $tarihler[0] } else { '?' }
$enYeni = if ($tarihler.Count) { $tarihler[-1] } else { '?' }
$boyutKB = [math]::Round((Get-Item $hedef).Length / 1KB)
$satir = ("{0}  kasa={1}  dosya={2}  tarih={3}..{4}  {5} KB  {6}" -f (Get-Date).ToString('dd.MM.yyyy HH:mm'), $kasaSayi, $dosyaSayi, $enEski, $enYeni, $boyutKB, (Split-Path $hedef -Leaf))
if ($dosyaSayi -ne $kasaSayi) {
  $hatali = $hedef + '.HATALI'
  Move-Item $hedef $hatali -Force
  Add-Content $log ("{0}  !! EKSIK YEDEK (dosya {1} != kasa {2})" -f $satir, $dosyaSayi, $kasaSayi)
  throw ("YEDEK EKSIK: dosya {0} satir, kasa {1} satir. Dosya {2} olarak birakildi." -f $dosyaSayi, $kasaSayi, $hatali)
}
Add-Content $log $satir
Write-Host ("YEDEK TAMAM: {0} satir · {1}..{2} · {3} KB -> {4}" -f $dosyaSayi, $enEski, $enYeni, $boyutKB, $hedef)

# --- 5) ESKI YEDEKLERI SEYRELT: son 8 haftalik + her ayin ilki kalir --------------
$dosyalar = Get-ChildItem $yedekKok -Filter 'alacak-kasa-*.json' | Sort-Object Name -Descending
$tut = @{}
$i = 0
foreach ($d in $dosyalar) {
  $i++
  $ay = $d.Name.Substring(12, 6)   # yyyyMM
  if ($i -le 8) { $tut[$d.FullName] = 1; continue }
  if (-not $tut.ContainsKey("ay:$ay")) { $tut["ay:$ay"] = 1; $tut[$d.FullName] = 1; continue }
  Remove-Item $d.FullName -Force
  Write-Host ("  eski yedek silindi: {0}" -f $d.Name)
}
