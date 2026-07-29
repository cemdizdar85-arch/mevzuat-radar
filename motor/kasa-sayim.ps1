# ============================================================================
#  KASA SAYIMI — 28.07.2026
#
#  NEDEN VAR: GM yerelde ANON anahtarla calisiyor; soru_havuzu RLS ile kapali
#  oldugu icin kasada kac soru oldugunu OLCEMIYOR (Content-Range: */0 doner).
#  Butun plan bu sayiya bagli: kasa 2.000 ise bir hikaye, 6.000 ise baska.
#  Cem'e "sen SQL calistir" demek yerine, bugun kurulan SERVICE anahtarli kanal
#  ayni isi yapiyor: bu betik Actions'ta koser, sayar ve sonucu depoya yazar.
#
#  PARA HARCAMAZ: hicbir API cagrisi yok, yalniz Supabase okuma.
#  Cikti: veri/kasa-sayim.json  (+ ekrana ozet)
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa sayimi atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

Write-Host "KASA SAYIMI basliyor..."

# --- 1) toplam (count=exact, tek istek)
$toplam = -1
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&limit=1" `
       -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 90
  $toplam = [int](($r.Headers['Content-Range'] -split '/')[-1])
} catch { Write-Host ("KRITIK: toplam sayilamadi - {0}" -f $_.Exception.Message); exit 1 }
Write-Host ("  TOPLAM: {0} soru" -f $toplam)

# --- 2) kirilim icin tum kayitlari sayfali cek (yalniz siniflandirma alanlari)
$kayit = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu,kaynak&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kayit.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
  Write-Host ("  ...{0}" -f $kayit.Count)
}
Write-Host ("  cekilen: {0}" -f $kayit.Count)

function Grupla($alanAdi){
  $g = @{}
  foreach($k in $kayit){ $v = "$($k.$alanAdi)"; if($v.Trim().Length -eq 0){ $v = '(bos)' }
    if($g.ContainsKey($v)){ $g[$v]++ } else { $g[$v] = 1 } }
  return $g
}

$sinav = Grupla 'sinav'
$ders  = Grupla 'ders'

# --- 3) sinav x ders capraz
$capraz = @{}
foreach($k in $kayit){
  $a = "$($k.sinav)"; if($a.Trim().Length -eq 0){ $a='(bos)' }
  $b = "$($k.ders)";  if($b.Trim().Length -eq 0){ $b='(bos)' }
  $key = "$a|$b"; if($capraz.ContainsKey($key)){ $capraz[$key]++ } else { $capraz[$key]=1 }
}

# --- 4) KONU BAZLI YOGUNLUK (kota sisteminin girdisi): hangi konuda kac soru var
$konu = @{}
foreach($k in $kayit){
  $key = "$($k.ders)|$($k.konu)"
  if($konu.ContainsKey($key)){ $konu[$key]++ } else { $konu[$key]=1 }
}

# --- 5) KAYNAK TIPI: kac soru bir KANUN MADDESINE dayaniyor (bag kurulabilir mi)
$mevzuatli = 0; $mevzuatsiz = 0
foreach($k in $kayit){
  $c = "$($k.kaynak)"
  if($c -match '(?i)\d{3,4}\s*say[ıi]l[ıi]|\(\d{3,4}\s*s\.K\.\)|\b(VUK|TTK|TBK|GVK|KDVK|KVK|AATUHK|[İI]YUK|TCK|CMK|SMK|[ÖO]TV|Anayasa)\b|\b(TMS|TFRS|BDS)\s*\d|tebli|y[oö]netmelik'){ $mevzuatli++ } else { $mevzuatsiz++ }
}

Write-Host ""
Write-Host "================ KASA SAYIMI ================"
Write-Host ("  TOPLAM SORU : {0}" -f $toplam)
Write-Host ""
Write-Host "  --- sinav bazinda"
$sinav.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("     {0,-10} {1}" -f $_.Key, $_.Value) }
Write-Host ""
Write-Host "  --- ders bazinda"
$ders.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("     {0,-34} {1}" -f $_.Key, $_.Value) }
Write-Host ""
Write-Host "  --- kaynak tipi (bag kurulabilirlik)"
Write-Host ("     mevzuata dayanan (madde bagi kurulabilir) : {0}" -f $mevzuatli)
Write-Host ("     mevzuat disi (dil/matematik/teori)        : {0}" -f $mevzuatsiz)
Write-Host ""
Write-Host "  --- EN YOGUN 20 KONU (kota sisteminin girdisi)"
$konu.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object { Write-Host ("     {0,4}x  {1}" -f $_.Value, $_.Key) }
Write-Host ""
Write-Host ("  --- tekil konu sayisi: {0}" -f $konu.Count)

# --- ORNEK DOKUMU: GM yerelde ANON anahtarla kasayi OKUYAMIYOR. Aciklamalari
# yeniledik ama GM ciktinin metnini goremedi - "elle okuyacagim" sozu boslukta
# kaldi. Rapor rakami verir, METNI vermez. Bu blok birkac sorunun yeni
# aciklamasini depoya dokuyor ki GM gercekten OKUSUN.
try {
  $o = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,hap,yevmiye,tablo&ders=eq.Finansal%20Muhasebe&order=id&limit=4" -Headers $H -TimeoutSec 90)
  [IO.File]::WriteAllText((Join-Path $kok "veri/kasa-ornek.json"), (@($o) | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/kasa-ornek.json  ({0} ornek soru, tam metin)" -f @($o).Count)
} catch { Write-Host ("ornek dokumu alinamadi: {0}" -f $_.Exception.Message) }

# --- YENI URETIM DOKUMU: uretilen sorularin HEPSI yayin=false. Bu, GM okumadan
# ogrenciye gitmesinler diye konmus bir kilit - ama ayni kilit GM'nin de onlari
# ANON anahtarla gormesini engelliyor. Kilidin, denetimi imkansiz kilmasi olmaz:
# denetlenemeyen bir parti, denetimden gecmis sayilamaz.
# Ders BASINA 3 soru dokuluyor: tek dersten 20 ornek, sekiz kapinin yedisini
# hic gormeden "parti iyi" dedirtir.
try {
  $dersler = @('Hukuk','Finansal Muhasebe','Maliyet Muhasebesi','Vergi Mevzuati ve Uygulamasi',
               'Finansal Tablolar ve Analizi','Muhasebe Denetimi','Meslek Hukuku','Ekonomi')
  $y = New-Object System.Collections.Generic.List[object]
  foreach($d in $dersler){
    $q = [uri]::EscapeDataString($d)
    try {
      $b = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,yevmiye,tablo&yayin=is.false&ders=eq.$q&order=id.desc&limit=3" -Headers $H -TimeoutSec 90)
      foreach($s in $b){ $y.Add($s) }
    } catch { }
  }
  [IO.File]::WriteAllText((Join-Path $kok "veri/yeni-uretim-ornek.json"), (@($y) | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/yeni-uretim-ornek.json  ({0} yeni soru, GM okumasi icin)" -f @($y).Count)
} catch { Write-Host ("yeni uretim dokumu alinamadi: {0}" -f $_.Exception.Message) }

$rapor = [ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm")
  toplam = $toplam
  cekilen = $kayit.Count
  sinav = $sinav
  ders = $ders
  sinav_ders = $capraz
  kaynak_tipi = [ordered]@{ mevzuata_dayanan = $mevzuatli; mevzuat_disi = $mevzuatsiz }
  tekil_konu = $konu.Count
  konu_yogunluk = $konu
}
$yol = Join-Path $kok "veri/kasa-sayim.json"
[IO.File]::WriteAllText($yol, ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "-> veri/kasa-sayim.json"

if($toplam -ne $kayit.Count){
  Write-Host ("UYARI: sayfali cekimde {0} kayit geldi ama toplam {1}. Fark incelenmeli." -f $kayit.Count, $toplam)
}
exit 0
