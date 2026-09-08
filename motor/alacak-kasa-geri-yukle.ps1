# ============================================================================
#  ALACAK KASASI GERI YUKLEME (08.09.2026, Cem "1 yap")
#
#  Cozulmus yedek dosyasini (alacak-kasa-yedek.ps1 ciktisi: {yedekZamani, kasaSayi,
#  satirlar[]}) yukleyicinin bekledigi {ilanlar[]} bicimine cevirir ve kasaya yazar.
#
#  IKI KIP:
#    deneme (varsayilan): dosyayi okur, cevirir, satir sayisini kasanin bugunku sayisiyla
#                         kiyaslar, HICBIR SEY YAZMAZ. Sifreli yedek zincirinin (artifact ->
#                         RSA zarf -> AES -> JSON) calistigini kanitlar.
#    gercek            : alacak_yaz ile parti parti yazar (400'luk). alacak_yaz UPSERT +
#                         coalesce'dir: silinmis satirlari GERI GETIRIR, bos alanlari DOLDURUR,
#                         ama kasadaki DOLU bir alani yedekteki degerle EZMEZ (bilerek - 07.09
#                         kazasinda coalesce kurtarici oldu). "Yanlis deger" onarimi bu betigin
#                         isi degil; o ayri, olculerek yapilir.
#
#  KULLANIM:
#    ./motor/alacak-kasa-geri-yukle.ps1 -Dosya <cozulmus.json> [-Kip deneme|gercek] [-Onay GERI-YUKLE]
#  gercek kipte -Onay GERI-YUKLE sart. Anahtar: SUPABASE_SERVICE_KEY (env).
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Dosya,
  [ValidateSet('deneme','gercek')][string]$Kip = 'deneme',
  [string]$Onay = ''
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()

function Not($m){ Write-Host $m; Write-Host ("::notice title=geri yukleme::{0}" -f $m) }
function Hata($m){ Write-Host ("::error title=geri yukleme::{0}" -f $m); throw $m }

if (-not (Test-Path $Dosya)) { Hata "yedek dosyasi yok: $Dosya" }
$ham = [IO.File]::ReadAllText($Dosya, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
$y = $ham | ConvertFrom-Json
$satirlar = @($y.satirlar)
if (-not $satirlar.Count) { Hata 'yedekte satir yok (satirlar bos) - dosya cozulmemis ya da bozuk olabilir' }
Not ("yedek okundu: {0} satir - yedek zamani {1} - yedek anindaki kasa {2}" -f $satirlar.Count, $y.yedekZamani, $y.kasaSayi)
if ([int]$y.kasaSayi -ne $satirlar.Count) { Hata ("yedek EKSIK: dosya {0} != yedek anindaki kasa {1}" -f $satirlar.Count, $y.kasaSayi) }

# --- kasa sutunu -> yukleyici alani --------------------------------------------
$ilanlar = New-Object System.Collections.Generic.List[object]
$tarihsiz = 0
foreach ($s in $satirlar) {
  $t = "$($s.tarih_str)"
  if (-not $t -and "$($s.tarih)" -match '^(\d{4})-(\d{2})-(\d{2})') { $t = "$($Matches[3]).$($Matches[2]).$($Matches[1])" }
  if (-not $t) { $tarihsiz++ }
  $ilanlar.Add([ordered]@{
    ilanNo = "$($s.ilan_no)"; baslik = "$($s.baslik)"; kurum = "$($s.kurum)"; il = "$($s.il)"; ilce = "$($s.ilce)"
    tarih = $t; tur = "$($s.tur)"; url = "$($s.url)"
    borclu = "$($s.borclu)"; vkn = "$($s.vkn)"; tckn = "$($s.tckn)"
    metin = "$($s.metin)"; esas_no = "$($s.esas_no)"; sicil_no = "$($s.sicil_no)"; mahkeme = "$($s.mahkeme)"
    muhlet_tip = "$($s.muhlet_tip)"; muhlet_ay = "$($s.muhlet_ay)"
    muhlet_baslangic = "$($s.muhlet_baslangic)"; muhlet_bitis = "$($s.muhlet_bitis)"
    komiser = "$($s.komiser)"; itiraz_gun = "$($s.itiraz_gun)"; karar_durumu = "$($s.karar_durumu)"
    borclular = $(if ($s.borclular) { @($s.borclular | Where-Object { $null -ne $_ }) } else { $null })
    vknler    = $(if ($s.vknler)    { @($s.vknler    | Where-Object { $null -ne $_ }) } else { $null })
    tcknler   = $(if ($s.tcknler)   { @($s.tcknler   | Where-Object { $null -ne $_ }) } else { $null })
  })
}
$borclulu = @($ilanlar | Where-Object { $_.borclu }).Count
$dizili   = @($ilanlar | Where-Object { $_.borclular }).Count
Not ("cevrildi: {0} ilan - tarihsiz {1} - borclu adli {2} - borclular dizili {3}" -f $ilanlar.Count, $tarihsiz, $borclulu, $dizili)

# --- kasanin bugunku hali (kiyas) -------------------------------------------------
if (-not $anahtar) { Not 'SUPABASE_SERVICE_KEY yok - kasa kiyasi ve yazma atlandi (deneme yalniz cozme/cevirme kanitidir)'; exit 0 }
$H = @{ apikey = $anahtar; Authorization = "Bearer $anahtar"; 'Content-Type' = 'application/json'; Accept = 'application/json'; 'User-Agent' = 'MevzuatRadar-GeriYukle' }
$ozet = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/alacak_sayi" -Headers $H -Body '{}' -TimeoutSec 120
Not ("kasa BUGUN: {0} ilan - borclulu {1} - kimlikli {2}" -f $ozet.adet, $ozet.borclulu, $ozet.kimlikli)

if ($Kip -eq 'deneme') { Not 'DENEME KIPI: hicbir sey yazilmadi. Zincir calisiyor (artifact -> zarf -> AES -> JSON -> cevirme -> kasa kiyasi).'; exit 0 }
if ($Onay -ne 'GERI-YUKLE') { Hata 'gercek kip icin -Onay GERI-YUKLE gerekir' }

# --- YAZ (yukleyiciyle ayni parti mantigi) ------------------------------------------
$PARTI = 400; $yazilan = 0
for ($i = 0; $i -lt $ilanlar.Count; $i += $PARTI) {
  $son = [Math]::Min($i + $PARTI - 1, $ilanlar.Count - 1)
  $parca = @($ilanlar.ToArray()[$i..$son])
  $json = (@{ p_kayitlar = $parca } | ConvertTo-Json -Depth 8 -Compress)
  $n = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/alacak_yaz" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 180
  $yazilan += [int]"$n"
  Write-Host ("  parti {0,5}-{1,-5} -> {2} satir" -f ($i+1), ($son+1), $n)
  Start-Sleep -Milliseconds 120
}
$ozet2 = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/alacak_sayi" -Headers $H -Body '{}' -TimeoutSec 120
Not ("GERI YUKLENDI: {0} satir yazildi - kasa simdi {1} ilan - borclulu {2} - kimlikli {3}" -f $yazilan, $ozet2.adet, $ozet2.borclulu, $ozet2.kimlikli)
if ([int]$ozet2.adet -lt $ilanlar.Count) { Hata ("KAYIP: yedekte {0}, kasada {1}" -f $ilanlar.Count, $ozet2.adet) }
