# ============================================================================
#  CTA CEVIRME - "... acilinca ilk sen haberdar ol" bekleme-listesi cagrisini
#  gercek uyelik cagrisina cevirir. Cem 14.08: "siteyi actigimizda her sey
#  calisacagindan bunu kaldirmak lazim" + "dedigin gibi cevir".
#  Kutu KALIYOR (sayfa sonundaki cagri yeri degerli), SOZU degisiyor.
#
#  CERRAHI YAKLASIM: blogu komple degistirmiyoruz. Olculdu ki asgari-kv.html'in
#  BASLIGI sayfaya ozel ("Asgari vergiye takilmak surpriz olmasin") ve sozu de
#  farkli ("Tetikte acilinca"). Toptan degistirmek o emegi silerdi. Bu yuzden
#  yalniz dort parca degisir: bekleme-listesi cumlesi, form, onay kutusu, script.
#  Yaz -> geri oku -> karsilastir her dosyada uygulanir.
# ============================================================================
param([switch]$Yaz)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$yeniCumle = 'Ücretsiz üye ol</b>, takip listeni kur; günlük tek özet e-posta ücretli aboneliğin parçasıdır.'
$yeniDugme = '<a href="radar-app.html" style="display:inline-block;background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:14px;padding:12px 26px;border-radius:11px;text-decoration:none">Ücretsiz üye ol &rarr;</a>'

$dosyalar = Get-ChildItem $kok -Filter *.html | Where-Object { (Get-Content $_.FullName -Raw -Encoding UTF8) -match 'mrKatil|açılınca ilk sen haberdar' }
Write-Host ("Bekleme-listesi cagrisi iceren dosya: {0}`n" -f $dosyalar.Count)

$degisen = 0; $sorunlu = @(); $silinen = 0
foreach($f in $dosyalar){
  $t = Get-Content $f.FullName -Raw -Encoding UTF8
  $y = $t

  # 14.08 Cem bulgusu (ekran goruntusu): "onu degistirsek sistemde 2 adet olacak".
  # DOGRU - dort sayfada zaten SAYFAYA OZEL bir cagri var ("Rakiplerin gormeden
  # sen gor", "Bu taramanin devami" vb). Genel kutuyu da uyelige cevirirsek ayni
  # ekranda iki uyelik cagrisi olur, ikisi de zayiflar.
  # Kural: sayfanin kendi cagrisi VARSA genel kutu SILINIR, YOKSA cevrilir.
  $ozelVar = $t -match '(?s)<div class="cta">\s*<h3>'
  if($ozelVar){
    $y = [regex]::Replace($y, '(?s)<div[^>]*data-mr-cta[^>]*>.*?</div>\s*</div>\s*', '')
    if($y -eq $t){ $sorunlu += "$($f.Name) (ozel CTA var ama genel blok bulunamadi)"; continue }
    if(-not $Yaz){ Write-Host ("  [olcum] {0}: SILINECEK (sayfanin kendi cagrisi var) {1} -> {2}" -f $f.Name, $t.Length, $y.Length); $degisen++; $silinen++; continue }
    [IO.File]::WriteAllText($f.FullName, $y, (New-Object Text.UTF8Encoding($false)))
    $geri = Get-Content $f.FullName -Raw -Encoding UTF8
    if(($geri -notmatch 'mrKatil') -and ($geri -notmatch 'data-mr-cta') -and ($geri -match '<div class="cta">')){
      Write-Host ("  SILINDI {0}  (sayfanin kendi cagrisi korundu)" -f $f.Name); $degisen++; $silinen++
    } else { Write-Host ("  KIRMIZI {0} - silme sonrasi geri okuma tutmadi" -f $f.Name); $sorunlu += "$($f.Name) (silme)" }
    continue
  }
  # 1) "E-postani birak, <X> acilinca ilk sen haberdar ol." -> uyelik cumlesi
  #    (X = Radar / Tetikte; ikisi de gecıyor)
  $y = [regex]::Replace($y, 'E-postanı bırak, [^<.]{0,30}açılınca ilk sen haberdar ol\.', $yeniCumle)
  #    yukaridaki cumle "<b>" ile bitiyorsa acilis etiketi eklenmeli - kontrol:
  if($y -match 'Ücretsiz üye ol</b>' -and $y -notmatch '<b style="color:#eef2f7">Ücretsiz üye ol</b>'){
    $y = $y.Replace('Ücretsiz üye ol</b>', '<b style="color:#eef2f7">Ücretsiz üye ol</b>')
  }
  # 2) form -> dugme
  $y = [regex]::Replace($y, '(?s)<form onsubmit="return mrKatil\(this\)".*?</form>', $yeniDugme)
  # 3) onay kutusu (artik form yok, gereksiz)
  $y = [regex]::Replace($y, '(?s)<div class="mr-cta-ok".*?</div>\s*', '')
  # 4) mrKatil scripti
  $y = [regex]::Replace($y, '(?s)<script>function mrKatil.*?</script>\s*', '')
  # 5) KVKK alt notu - form kalkti, "katilinca e-posta" sozu artik yanlis
  $y = $y.Replace('Katılınca bilgilendirme e-postası almayı kabul edersin', 'Üyelik ücretsizdir')

  # Degisiklik olmamasi her zaman kusur degil: genc.html'de "mrKatil" yalniz ESKI
  # BIR YORUM satirinda geciyor (31.07'de gercek kutu zaten kaldirilmis). Yanlis
  # alarmi "sorunlu" saymak, gercek sorunu gozden kacirtir.
  if($y -eq $t){
    $gercekVar = $t -match '<form onsubmit="return mrKatil' -or $t -match 'data-mr-cta'
    if($gercekVar){ $sorunlu += "$($f.Name) (gercek CTA var ama degistirilemedi)" }
    else { Write-Host ("  [atlandi] {0}: yalniz yorumda geciyor, gercek CTA yok" -f $f.Name) }
    continue
  }
  if(-not $Yaz){ Write-Host ("  [olcum] {0}: {1} -> {2} karakter" -f $f.Name, $t.Length, $y.Length); $degisen++; continue }

  [IO.File]::WriteAllText($f.FullName, $y, (New-Object Text.UTF8Encoding($false)))
  # GERI OKU -> KARSILASTIR
  $geri = Get-Content $f.FullName -Raw -Encoding UTF8
  $tamam = ($geri -notmatch 'mrKatil') -and ($geri -notmatch 'açılınca ilk sen haberdar') -and
           ($geri -match 'radar-app\.html') -and ($geri.Length -eq $y.Length)
  if($tamam){ Write-Host ("  YAZILDI {0}  ({1} -> {2})" -f $f.Name, $t.Length, $geri.Length); $degisen++ }
  else { Write-Host ("  KIRMIZI {0} - geri okuma tutmadi" -f $f.Name); $sorunlu += "$($f.Name) (geri okuma)" }
}
Write-Host ("`n{0}: {1} dosya ({2} silindi · {3} cevrildi) · sorunlu {4}" -f `
  $(if($Yaz){'DEGISTIRILDI'}else{'OLCUM (yazilmadi)'}), $degisen, $silinen, ($degisen-$silinen), $sorunlu.Count)
if($sorunlu.Count){ $sorunlu | ForEach-Object { Write-Host ("  - " + $_) } }
if(-not $Yaz){ Write-Host "`nYazmak icin: -Yaz" }
