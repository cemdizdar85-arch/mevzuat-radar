# ============================================================================
#  KASA DUZELTICISI — 28.07.2026
#
#  NEDEN VAR: Bir soru kasaya (soru_havuzu) girdikten sonra DUZELTME YOLU YOKTU.
#  GM yerelde anon anahtarla calisiyor ve RLS yuzunden kasayi ne okuyabiliyor ne
#  yazabiliyor. Bugun 9 KDV sorusundan birinde atif hatasi bulundu (m.12/2 fason
#  hizmeti duzenliyor, hizmet ihracinin sartlarini degil) ama soru kasadaydi ve
#  duzeltilemedi. Kasadaki sorulari denetlemeye devam edecegimize gore bu kanal sart.
#
#  ISLEYIS: veri/kasa-duzeltme.json icindeki durum='bekliyor' satirlari uygulanir.
#  Her satir icin:
#    1) mevcut deger OKUNUR ve 'eski' ile karsilastirilir (yanlis kayda yazmayi onler)
#    2) yeni deger yazilir
#    3) GERI OKUNUP dogrulanir  <- "yesil kosu != tam veri" dersi
#    4) durum='uygulandi' + tarih damgasi dosyaya islenir (iz kalir, silinmez)
#  Tek satir bile dogrulanamazsa is KIRMIZI biter; sessiz basarisizlik yok.
#
#  GUVENLIK: yalniz kaynak/aciklama/hap/siklar/dogru alanlari degistirilebilir.
#  Soru metnini degistirmek YENI SORU demektir; bu kanaldan gecmez.
#  ENV: SUPABASE_SERVICE_KEY zorunlu. Yoksa zarifce cikar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa duzelticisi atlandi."; exit 0 }
$H  = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
$HW = $H + @{ Prefer = "return=minimal" }

# 28.07: 'ders' ve 'konu' eklendi. Gerekce: kasa sayimi ETIKET KAYMASI gosterdi -
# ayni sinavin icinde 'Finansal Muhasebe' (656) ile 'Muhasebe' (93) ayri ders
# gibi duruyor, 'cumle tamamlama' (78) ile 'sentence completion' (73) ayni konu
# iki isimle. Quiz motoru bunlari ayri sanar ve ogrenci havuzun buyuk kismini
# hic gormez. Bu iki alan SINIFLANDIRMADIR, ICERIK DEGILDIR: degistirilmesi
# dogru bir ifadeyi yanlis yapamaz, yalniz sorunun hangi rafta durdugunu duzeltir.
# SORU METNI hala bu kanaldan DEGISTIRILEMEZ - o kural yerinde duruyor.
$IZINLI = @('kaynak','aciklama','hap','siklar','dogru','benzer_grup','ders','konu')

$yol = Join-Path $kok "veri/kasa-duzeltme.json"
if(-not (Test-Path $yol)){ Write-Host "kasa-duzeltme.json yok - yapilacak is yok."; exit 0 }
$j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$hepsi = @($j.duzeltmeler)
$bekleyen = @($hepsi | Where-Object { "$($_.durum)" -eq 'bekliyor' })
if($bekleyen.Count -eq 0){ Write-Host "Bekleyen duzeltme yok."; exit 0 }
Write-Host ("Bekleyen duzeltme: {0}" -f $bekleyen.Count)

$uygulandi = 0; $atlandi = 0; $hata = 0
foreach($d in $bekleyen){
  $id = "$($d.id)"; $alan = "$($d.alan)"
  if($IZINLI -notcontains $alan){
    Write-Host ("  ATLANDI {0}: '{1}' alani bu kanaldan degistirilemez" -f $id, $alan); $atlandi++; continue
  }

  # 1) mevcut degeri oku
  try {
    $mevcut = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$id&select=id,$alan" -Headers $H -TimeoutSec 60
  } catch { Write-Host ("  HATA {0}: okunamadi - {1}" -f $id, $_.Exception.Message); $hata++; continue }
  if(@($mevcut).Count -eq 0){ Write-Host ("  ATLANDI {0}: kasada boyle bir soru yok" -f $id); $atlandi++; continue }
  $simdiki = "$(@($mevcut)[0].$alan)"

  # 2) 'eski' beyani tutuyor mu (yanlis kayda yazmayi onler)
  if("$($d.eski)".Trim().Length -gt 0 -and $simdiki.Trim() -ne "$($d.eski)".Trim()){
    Write-Host ("  ATLANDI {0}: kasadaki deger beklenenden farkli - dokunulmadi" -f $id)
    Write-Host ("     kasada : {0}" -f $simdiki)
    Write-Host ("     beklenen: {0}" -f $d.eski)
    $atlandi++; continue
  }
  if($simdiki.Trim() -eq "$($d.yeni)".Trim()){ Write-Host ("  ZATEN DOGRU {0}" -f $id); $d.durum = 'uygulandi'; $uygulandi++; continue }

  # 3) yaz
  $govde = @{}; $govde[$alan] = $d.yeni
  $json = ($govde | ConvertTo-Json -Depth 6)
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$id" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 60 | Out-Null
  } catch { Write-Host ("  HATA {0}: yazilamadi - {1}" -f $id, $_.Exception.Message); $hata++; continue }

  # 4) GERI OKU ve dogrula (sayaca degil metne bak)
  $teyit = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$id&select=$alan" -Headers $H -TimeoutSec 60
  $sonra = "$(@($teyit)[0].$alan)"
  if($sonra.Trim() -ne "$($d.yeni)".Trim()){
    Write-Host ("  KIRMIZI {0}: yazdi ama GERI OKUMA TUTMADI" -f $id); $hata++; continue
  }
  $d.durum = 'uygulandi'
  $d | Add-Member -NotePropertyName uygulama_tarihi -NotePropertyValue (Get-Date -Format "dd.MM.yyyy HH:mm") -Force
  Write-Host ("  TAMAM {0}: {1} guncellendi ve dogrulandi" -f $id, $alan)
  $uygulandi++
}

# iz birak: dosyayi damgalarla geri yaz
$j.duzeltmeler = $hepsi
[IO.File]::WriteAllText($yol, ($j | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "======== KASA DUZELTME OZETI ========"
Write-Host ("  uygulandi : {0}" -f $uygulandi)
Write-Host ("  atlandi   : {0}" -f $atlandi)
Write-Host ("  hata      : {0}" -f $hata)
if($hata -gt 0){ Write-Host "KIRMIZI: en az bir duzeltme uygulanamadi."; exit 1 }
Write-Host "TEMIZ."
exit 0
