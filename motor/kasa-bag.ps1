# ============================================================================
#  KASA BAGI — KATMAN 1 (BAG) + KATMAN 5 (KANIT IZI)   28.07.2026
#
#  NE YAPAR: kasadaki her sorunun serbest metin 'kaynak' alanini cozup
#  (kanun_no, madde_no) ciftine baglar ve o maddenin O ANDAKI metninin
#  PARMAK IZINI soruya yazar.
#
#  NIYE SART: bugun kasada bir sorunun hangi maddeye dayandigi YAZILI DEGIL.
#  Yalniz "TBK m.72/1" gibi serbest metin var. Bu yuzden "su madde degisti, ona
#  dayanan sorulari yayindan cek" komutu CALISTIRILAMIYOR. Katman 3 degisikligi
#  goruyor ama kime haber verecegini bilmiyor. Bag, o iki katmani birbirine
#  baglayan tel.
#
#  KANIT IZI: her soru artik "hangi maddeye dayaniyorum, o madde ben yazildigim
#  anda NEYDI, en son ne zaman dogrulandim" sorularina cevap verir. Bir soru
#  itiraz gelirse tartisma degil KAYIT konusur.
#
#  PARA HARCAMAZ: yalniz Supabase okur/yazar.
#
#  KOLON SARTI: yayin/kanun_no/madde_no/madde_damga/son_kontrol kolonlari
#  gerekir (veri/sql-yayin-kapisi.sql). Kolon yoksa betik YAZMAZ, yalniz olcum
#  raporu cikarir ve 3 ile doner - sessizce hicbir sey yapmis gibi durmaz.
# ============================================================================
param(
  [switch]$yaz     # kolonlar varsa kasaya gercekten yaz
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa bagi atlandi."; exit 0 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# Damga hesabi madde-damga.ps1 ile AYNI olmali; farkli olursa her karsilastirma
# yanlis alarm uretir ve alarm sistemi guvenilirligini yitirir.
function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '\s+', ' '
  return $x.Trim()
}
function Damga([string]$t){
  $sha = [Security.Cryptography.SHA256]::Create()
  $b = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((Sadelestir $t)))
  return ([BitConverter]::ToString($b) -replace '-','').Substring(0,16).ToLowerInvariant()
}

# --- kolonlar var mi
function KolonVar($ad){
  try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=$ad&limit=1" -Headers $H -TimeoutSec 30 | Out-Null; return $true } catch { return $false }
}
$kolonlar = @('yayin','kanun_no','madde_no','madde_damga','son_kontrol')
$eksik = @($kolonlar | Where-Object { -not (KolonVar $_) })

Write-Host "KASA BAGI - kasa okunuyor..."
$kayit = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,kaynak,ders,sinav&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kayit.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("  soru: {0}" -f $kayit.Count)

$ist = [ordered]@{ toplam=0; bagli=0; mevzuatDisi=0; cozulemedi=0; yazildi=0; yazmaHatasi=0 }
$baglar = New-Object System.Collections.Generic.List[object]
$i = 0
foreach($k in $kayit){
  $ist.toplam++
  $i++
  if($i % 500 -eq 0){ Write-Host ("  ...{0}" -f $i) }
  $kay = "$($k.kaynak)"
  if(MevzuatDisiMi $kay){ $ist.mevzuatDisi++; continue }
  $c = KaynakCoz $kay
  if("$($c.durum)" -ne 'cozuldu' -or -not $c.kanun -or -not $c.madde){ $ist.cozulemedi++; continue }
  $ist.bagli++
  $baglar.Add([pscustomobject]@{
    id="$($k.id)"; kanun_no="$($c.kanun)"; madde_no="$($c.madde)"
    madde_damga=(Damga "$($c.metin)"); kaynak=$kay
  })
}

Write-Host ""
Write-Host "======== KASA BAGI ========"
foreach($a in $ist.Keys){ Write-Host ("  {0,-14} {1}" -f $a, $ist[$a]) }
if($ist.toplam -gt 0){
  $oran = [math]::Round(100.0*$ist.bagli/[math]::Max(1,($ist.toplam - $ist.mevzuatDisi)),1)
  Write-Host ("  mevzuata dayanan sorularin %{0}'i maddeye BAGLANDI" -f $oran)
}

$rap = Join-Path $kok 'veri/kasa-bag.json'
[IO.File]::WriteAllText($rap, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ozet=$ist; eksik_kolon=$eksik; adet=$baglar.Count
} | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/kasa-bag.json"

if($eksik.Count -gt 0){
  Write-Host ""
  Write-Host ("KOLON EKSIK: {0}" -f ($eksik -join ', '))
  Write-Host "Bag KURULAMADI - kasaya yazilmadi. veri/sql-yayin-kapisi.sql calistirilmali."
  Write-Host "(Olcum yapildi: yukaridaki rakamlar kolonlar gelince ne olacagini gosteriyor.)"
  exit 3
}
if(-not $yaz){ Write-Host ""; Write-Host "OLCUM MODU - kasaya yazilmadi. Yazmak icin -yaz."; exit 0 }

# --- yaz (partili)
$zaman = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
foreach($b in $baglar){
  $govde = @{ kanun_no=$b.kanun_no; madde_no=$b.madde_no; madde_damga=$b.madde_damga; son_kontrol=$zaman } | ConvertTo-Json -Compress
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($b.id)" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $ist.yazildi++
  } catch { $ist.yazmaHatasi++ }
  if($ist.yazildi % 500 -eq 0 -and $ist.yazildi -gt 0){ Write-Host ("  yazildi ...{0}" -f $ist.yazildi) }
}
Write-Host ("  YAZILDI: {0}   hata: {1}" -f $ist.yazildi, $ist.yazmaHatasi)

# --- YAZMA SONRASI SAYIM. Depoda daha once yasanan ders: yesil kosu tam veri
# demek DEGIL. Yazdigimizi iddia ettigimiz sey gercekten orada mi, SAYARAK bak.
$dogru = 0
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&kanun_no=not.is.null&limit=1" `
       -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 90
  $dogru = [int](($r.Headers['Content-Range'] -split '/')[-1])
} catch {}
Write-Host ("  MUTABAKAT: kasada kanun_no dolu {0} soru var (beklenen {1})" -f $dogru, $ist.yazildi)
if($dogru -lt $ist.yazildi){ Write-Host "KIRMIZI: yazildigi iddia edilenden AZ kayit var."; exit 1 }
exit 0
