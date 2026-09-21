#requires -Version 5.1
<#
================================================================================
  DAYANAK ALINTISI SAYACI — OZ-SINAV  (21.09.2026)

  NIYE VAR: 20.09'da sayac kuruldu ve "olcuyorum" sandi. 21.09'da olculdu ki
  karsilastirmayi BOS METINLE yapiyordu (`$aday.kaynak_metin_ozet` modelin
  cevabinda YOK) -> w5 kosusunda 277 denemenin 277'si AL-TUTMAZ, AL-TAM sifir.
  Kapi kendi bozuldugunda sessizce yalan soyledi. Bu sinav onu yakalar.

  ⛔ REPLIKA YASAK: sinav kendi kopyasini yazmaz. `motor/kalip-parti-uret.ps1`
     icindeki GERCEK `AlintiDurumu` fonksiyonu AST ile cikarilip kosulur.
     (20.09 dersi: KAPI-C'nin replikasi %99,8 dedi, gercek fonksiyon %0,6.)

  BEDEL 0 — model cagrisi YOK.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$uretici = Join-Path $depoKok 'motor\kalip-parti-uret.ps1'
if (-not (Test-Path $uretici)) { throw "uretici bulunamadi: $uretici" }

# --- GERCEK fonksiyonu AST ile cikar ---
$tok = $null; $hata = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($uretici, [ref]$tok, [ref]$hata)
if ($hata -and $hata.Count) { throw "uretici ayristirilamadi: $($hata[0].Message)" }
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'AlintiDurumu' }, $true)
if (-not $fn -or -not @($fn).Count) { throw 'AlintiDurumu fonksiyonu uretici icinde BULUNAMADI (adi degistiyse sinav da guncellenir)' }
. ([scriptblock]::Create(@($fn)[0].Extent.Text))

# --- Vakalar: yakalamasi gereken + YANLIS ALARM vermemesi gereken ---
$paket = @'
Ertelenen, iadesi gereken, tahsil edilen ve cesitli sekillerde ortaya cikan diger KDV'nin bir yili
asan tutarlarinin kaydedildigi hesaptir. Bu hesap, isletmenin bir yildan uzun surede indirilecek
katma deger vergisini izlemek icin kullanilir. Donem sonunda kalan tutar bilancoda duran varlik
icinde gosterilir.
'@

$vaka = @(
  @{ ad = 'BIREBIR alinti pakette geciyor'; al = 'Bu hesap, isletmenin bir yildan uzun surede indirilecek katma deger vergisini izlemek icin kullanilir.'; pk = $paket; bek = 'AL-TAM' }
  @{ ad = 'Bosluk/satir sonu farkli, metin ayni'; al = "Ertelenen,  iadesi gereken,   tahsil edilen ve cesitli`n sekillerde ortaya cikan diger KDV'nin"; pk = $paket; bek = 'AL-TAM' }
  @{ ad = 'Kivrik tirnak farki (U+2019) yanlis alarm vermemeli'; al = ('Ertelenen, iadesi gereken, tahsil edilen ve cesitli sekillerde ortaya cikan diger KDV' + [char]0x2019 + 'nin'); pk = $paket; bek = 'AL-TAM' }
  # Kismi kabul BILEREK var: model cumlenin sonunu kendi kelimesiyle baglarsa alinti yine mesrudur.
  # ⚠ Bu esneklik yanlis alarmi azaltir ama KACIRMA da uretir: ilk 60 karakteri kopyalayip gerisini
  #   uyduran bir cevap AL-TAM sayilir. Sayac bunu GORMEZ (fonksiyon basindaki korluk notu).
  @{ ad = 'Ilk 60 karakter tutuyor, sonrasi sapiyor (kismi kabul — bilerek)'; al = 'Bu hesap, isletmenin bir yildan uzun surede indirilecek katma deger vergisini ayrica ozel tuketim vergisini de izler.'; pk = $paket; bek = 'AL-TAM' }
  @{ ad = 'UYDURMA alinti — pakette hic gecmiyor'; al = 'Gelir Vergisi Kanunu madde 94 uyarinca yapilan tevkifat oranlari Bakanlar Kurulunca belirlenir.'; pk = $paket; bek = 'AL-TUTMAZ' }
  @{ ad = '40 karakterden kisa'; al = 'Bu hesap KDV izler.'; pk = $paket; bek = 'AL-KISA' }
  @{ ad = 'Alinti hic yok'; al = ''; pk = $paket; bek = 'AL-YOK' }
  @{ ad = 'Alinti bos bosluk'; al = '     '; pk = $paket; bek = 'AL-YOK' }
  # ⭐ 21.09 GERILEME SINAVI: paket bos gelirse "TUTMAZ" DENMEZ. Sayaci bir gun
  #    yalanci yapan tam olarak buydu; bos paket artik OLCULEMEDI'dir.
  @{ ad = 'GERILEME: paket BOS -> TUTMAZ degil, OLCULEMEDI'; al = 'Bu hesap, isletmenin bir yildan uzun surede indirilecek katma deger vergisini izler.'; pk = ''; bek = 'AL-OLCULEMEDI' }
  @{ ad = 'GERILEME: paket null -> OLCULEMEDI'; al = 'Bu hesap, isletmenin bir yildan uzun surede indirilecek katma deger vergisini izler.'; pk = $null; bek = 'AL-OLCULEMEDI' }
)

$gecen = 0; $kalan = New-Object System.Collections.Generic.List[string]
foreach ($v in $vaka) {
  $c = AlintiDurumu $v.al $v.pk
  if ($c -eq $v.bek) { $gecen++; if (-not $Sessiz) { "  OK   [{0,-14}] {1}" -f $c, $v.ad } }
  else { $kalan.Add(("{0} -> beklenen {1}, cikan {2}" -f $v.ad, $v.bek, $c)); if (-not $Sessiz) { "  DUSTU[{0,-14}] {1}  (beklenen {2})" -f $c, $v.ad, $v.bek } }
}
''
"ALINTI SAYACI OZ-SINAVI: {0}/{1} gecti" -f $gecen, $vaka.Count
if ($kalan.Count) {
  foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }
  exit 1
}
Write-Host 'YESIL' -ForegroundColor Green
exit 0
