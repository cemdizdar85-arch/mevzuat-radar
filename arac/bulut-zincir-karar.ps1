# arac/bulut-zincir-karar.ps1 - bulut-uretim.yml "Toplu kuyruk bitmediyse ayni plani yeniden tetikle" adiminin KARARI.
#
# 21.10.2026 (Cem "2 yap", KGK t6 olcumu): 20.10'da 4 plan (tms-a 39440249326, tds-a 39440214143, fy-a 39440181252,
#   ky-a 39440148280) ACIKLAMA HAKEMI (AH) fazinda 249 dk toplu bekleme doldu -> motor/api-hedef.ps1 "TOPLU ANLIKSIZ" yazip
#   exit 75 verdi. AH koşucunun KENDI surecinde kosar (arac/aciklama-hakemi-uretim.ps1, dot-source) - satir yalniz adim
#   ciktisina dustu, veri/fabrika/kosucu-log altinda HIC dosyaya yazilmadi. Zincir adimi yalniz o klasoru tariyordu:
#   "yarim kalan parti gunlugu: 0" -> "plan tamamlandi - yeniden tetikleme yok". Odenmis AH partisi Anthropic'te kaldi,
#   KGK oturumu planlari elle yeniden siraya koydu (b1288b27). 4/4 kosuda ayni desen.
# Cozum iki BAGIMSIZ sinyal:
#   1) api-hedef zaman asiminda, MEVZUAT_ANLIKSIZ_IZ (koşucu doldurur) dosyasina "TOPLU ANLIKSIZ (zaman asimi)" satiri yazar.
#   2) Uret adimi BASARISIZ bittiyse: BU KOSUDA gonderilmis (zaman >= kosu basi), bu planin etiketine ait ve HASAT EDILMEMIS
#      toplu parti kaydi (veri/bekleyen-partiler.json) = odenmis, bitmemis is -> yarim sayilir (iz yazilamadan surec olduyse).
# Yeniden halka ayni plan + ayni butce + ayni butce_baslangic ile acilir; cift odeme yok cunku api-hedef ayni parmak izli
#   istegi kuyruktaki partiye BAGLAR, bitmisse BEDAVA hasat eder (16-17.09 kurali). Sonsuz dongu yok: halka tavani (10).
# Eski karar sirasi AYNEN korunur: yalniz hasat -> butce doldu -> bakiye bitti -> yarim/hata -> tavan -> yeniden.
#
# GORMEZ: (a) AH butce kapisi yeniden halkada "en kotu durum" hesabini hasat edilecek isler icin de yapar - butce tam
#   sinirdaysa odenmis AH partisi hasat edilmeden "butce yetmedi" ile KIRMIZI durur (elle -Yeniden yolu da ayni).
#   (b) Uret adimi basariliyken api-hedef'in iz yazamadigi zaman asimi (dosya yazma hatasi) - sinyal 1 tek basina.
#   (c) Halka tavanina kadar ayni sebeple tekrar tekrar zaman asimi (her halka ~5 sa); ilerleme olculmez, yalniz sayilir.
#   (d) Bekleyen kaydinin zamani runner yerel saatidir (GitHub'da UTC); kosu basi ayni saatle yazilmali.
# Oz-sinav: arac/bulut-zincir-karar-sinavi.ps1 (dogrula.yml).

function ZincirPlanEtiketleri([string]$planYol) {
  $et = @()
  if (-not $planYol -or -not (Test-Path $planYol)) { return $et }
  $j = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Resolve-Path $planYol).Path))
  foreach ($r in @($j | ForEach-Object { $_ })) { if ($r -and $r.PSObject.Properties['etiket'] -and "$($r.etiket)") { $et += "$($r.etiket)" } }
  return @($et | Sort-Object -Unique)
}

# Bu kosuda gonderilmis, bu planin etiketine ait, hasat edilmemis toplu parti kayitlari
function ZincirAcikPartiler([string]$bekleyenYol, $planEtiketleri, [string]$kosuBasi) {
  $acik = @()
  if (-not $bekleyenYol -or -not (Test-Path $bekleyenYol) -or -not "$kosuBasi") { return $acik }
  $ham = [IO.File]::ReadAllText($bekleyenYol)
  if (-not $ham.Trim()) { return $acik }
  $lst = ConvertFrom-Json -InputObject $ham
  foreach ($x in @($lst | ForEach-Object { $_ })) {
    if (-not $x -or -not "$($x.id)") { continue }
    $et = "$($x.etiket)"; $ait = $false
    foreach ($pe in @($planEtiketleri)) { if ($et -eq $pe -or $et.StartsWith("$pe/")) { $ait = $true; break } }
    if (-not $ait) { continue }
    if ([string]::CompareOrdinal("$($x.zaman)", "$kosuBasi") -lt 0) { continue }
    if ("$($x.durum)" -eq 'hasat edildi') { continue }
    $acik += $x
  }
  return $acik
}

function BulutZincirKarar {
  param([string]$LogKok, [string]$BekleyenYol, $PlanEtiketleri, [string]$KosuBasi, [string]$UretSonuc,
        [int]$Halka = 0, [string]$YalnizHasat = '0', [string]$ButceUsd = '', [int]$Tavan = 10)
  $s = New-Object System.Collections.Generic.List[string]
  $sonuc = { param($karar, $kirmizi) [pscustomobject]@{ karar = $karar; kirmizi = [bool]$kirmizi; satirlar = @($s) } }
  if ("$YalnizHasat" -eq '1') {
    $s.Add('YALNIZ HASAT turu - zincir yok. Hasat edilen cevaplar bir onceki adimda ambara yazildi.')
    return (& $sonuc 'hasat-bitti' $false)
  }
  $dosyalar = @()
  if ($LogKok -and (Test-Path $LogKok)) { $dosyalar = @(Get-ChildItem $LogKok -Recurse -File -ErrorAction SilentlyContinue) }
  $izSay = { param($ad, $desen) @($dosyalar | Where-Object { $_.Name -eq $ad } | Select-String -Pattern $desen -ErrorAction SilentlyContinue) }
  $bakiye = & $izSay 'bakiye-bitti.log' 'YARIM'
  $hatali = & $izSay 'hata-cikan.log' 'YARIM'
  $butce = & $izSay 'butce-doldu.log' 'YARIM'
  if ($butce.Count) {
    if (@($butce | Where-Object { "$_" -match 'hakemi b' }).Count) { $s.Add('::error::ACIKLAMA HAKEMI BUTCESIZ KALDI - yazilan sorular kararsiz, yayin sartini GECEMEZ. Butce = yazim + AH payi (~0,03 USD/soru). Butceyi artirip ayni plani -Yeniden siraya koy (onceki isler bedava hasat).') }
    $s.Add("::error::PLAN BUTCESI DOLDU ($ButceUsd USD) - plan YARIM kaldi. Zincir durdu. Devam icin sonucu olc, Cem onayiyla butceyi artirip ayni plani elle baslat.")
    return (& $sonuc 'butce-doldu' $true)
  }
  if ($bakiye.Count) {
    $s.Add("::error::ANTHROPIC BAKIYESI BITTI - plan YARIM kaldi ($($bakiye.Count) parti). Zincir yeniden tetiklenmedi (kredisiz halka bos doner). Kredi yuklenince ayni plani -Yeniden siraya koy (butce = planin TOPLAM butcesi, onceki halkalar dahil).")
    return (& $sonuc 'bakiye-bitti' $true)
  }
  $yarim = @($dosyalar | Select-String -Pattern 'TOPLU ANLIKSIZ' -List -ErrorAction SilentlyContinue)
  # 21.10 sinyal 2: Uret dustu + bu kosunun odenmis, hasat edilmemis toplu partisi duruyor
  $acik = @()
  if ("$UretSonuc" -ne 'success') { $acik = @(ZincirAcikPartiler $BekleyenYol $PlanEtiketleri $KosuBasi) }
  $s.Add("yarim kalan parti gunlugu: $($yarim.Count) - hatayla biten parti: $($hatali.Count) - uret: $UretSonuc - hasat edilmemis toplu parti (bu kosu): $($acik.Count)")
  if (-not $yarim.Count -and -not $acik.Count) {
    if ($hatali.Count) { $s.Add("::error::$($hatali.Count) parti hata koduyla bitti - plan TAMAMLANMADI, elle bakilmali (yeniden tetiklenmedi)"); return (& $sonuc 'hata' $true) }
    $s.Add('plan tamamlandi - yeniden tetikleme yok')
    return (& $sonuc 'tamam' $false)
  }
  if ($acik.Count -and -not $yarim.Count) { $s.Add("TOPLU ZAMAN ASIMI izi gunlukte yok ama $($acik.Count) odenmis parti hasat edilmedi ($(@($acik | ForEach-Object { $_.etiket } | Sort-Object -Unique) -join ', ')) - yarim sayildi") }
  if ($Halka -ge $Tavan) { $s.Add("::error::ZINCIR TAVANI ($Tavan) - yeniden tetiklenmedi. Odenmis partiler bekleyen kaydinda; elle bakilmali."); return (& $sonuc 'tavan' $true) }
  $s.Add("yeniden tetiklenecek: halka $($Halka + 1) / tavan $Tavan (ayni plan, ayni butce zinciri)")
  if ($hatali.Count) { $s.Add("::error::$($hatali.Count) parti hata koduyla bitti - zincir surdu ama bu halka KIRMIZI"); return (& $sonuc 'yeniden' $true) }
  return (& $sonuc 'yeniden' $false)
}
