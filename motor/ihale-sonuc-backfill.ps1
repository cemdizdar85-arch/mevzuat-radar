# ============================================================================
#  SONUC ILANI BACKFILL - v2 (30.08.2026)
#
#  Cem 30.08: "asama 0'i bitir, bir hafta bekleyemeyiz" + "tam indirdigimizi,
#  is kollarini tam indirdigimizi BILELIM".
#
#  ---------------------------------------------------------------------------
#  v1 NEDEN 36 AYI KALDIRAMAZDI (olculdu, tahmin degil):
#  Eski akista her gun icin  hasat -> ayristir -Yaz  kosuluyordu ve ayristirici
#  BIRIKIMLI: veri/ihale-sonuc.json'i bastan okuyup tamamini yeniden yaziyor.
#  Yani 2.250. gun, 2.250 gunluk dosyayi (yaklasik 900 MB) tekrar seri hale
#  getiriyor. Maliyet O(n^2): 36 aylik kosuda toplam ~1 TB JSON yazimi ve
#  ConvertTo-Json'un 775.000 nesnede saatlere cikmasi. 3 aylik backfill'in
#  yavas olmasinin sebebi de buydu; kimse olcmemisti.
#
#  v2'DE: gunluk havuz her gun SIFIRDAN kurulur, gun biter bitmez KASAYA
#  yuklenir. Biriktiren yer artik Supabase. Maliyet O(n), ve gunler birbirinden
#  BAGIMSIZ hale gelir -> SERIT SERIT PARALEL kosulabilir.
#
#  ---------------------------------------------------------------------------
#  IS LISTESI NEREDEN: kasadaki ihale_eksik_gun(). Yerel dosya degil, cunku
#  yerel kutuk (ihale-backfill-gunlog.json) 4 gun yaziyordu, kasada 62+ gunluk
#  veri vardi - yani yerel kutuk YALAN SOYLUYORDU. Tek dogru kaynak kasadir.
#  ihale_eksik_gun IKI hali birden doner: "hic cekilmedi" ve "eksik indi"
#  (icindekiler ile govdesi tutmayan gun). Ikincisi de yeniden cekilir.
#
#  TAM INDI MI: ayristirici bultenin ICINDEKILER bolumundeki IKN listesiyle
#  govdedeki IKN listesini karsilastirir; kutuge beklenen/bulunan/tam yazilir.
#  Tam degilse o gun kutukte "eksik" kalir ve bir sonraki kosuda geri gelir.
#
#  ISTENEN GUN <> GELEN GUN: KIK arsiv formu yanlis doldurulursa sessizce
#  BUGUNUN bultenini dondurur (14.08'de bir kez oldu). Damga kaynaktan okundugu
#  icin fark goruluyor; o gun "yapildi" sayilmaz, yerel atlanan listesine
#  yazilir ve sonsuz tekrar donmez.
#
#  KULLANIM
#    tek makine, 36 ay      : ./ihale-sonuc-backfill.ps1 -AyGeri 36
#    Actions parcali (6 sa) : ./ihale-sonuc-backfill.ps1 -AyGeri 36 -Gun 400
#    6 paralel serit        : ./ihale-sonuc-backfill.ps1 -AyGeri 36 -Serit 0 -SeritSayisi 6
#                             (her serit AYRI makinede ya da AYRI klasorde:
#                              $env:IHALE_BULTEN_KLASOR ayarlanir)
#    kuru kosu (yazmaz)     : ./ihale-sonuc-backfill.ps1 -AyGeri 36 -Gun 2 -Olc
# ============================================================================
param(
  [int]$AyGeri = 36,
  [int]$Gun = 0,                 # bu kosuda islenecek azami gun (0 = hepsi)
  [double]$BeklemeSn = 2.0,      # gunler arasi bekleme (KIK'e nazik)
  [string[]]$Turler = @('Mal','Yapim','Hizmet','Danismanlik'),
  [int]$Serit = 0,               # bu seridin sirasi (0..SeritSayisi-1)
  [int]$SeritSayisi = 1,         # toplam paralel serit
  [switch]$Olc,                  # olcum modu: indirir, ayristirir, YAZMAZ
  # 30.08 EKLENDI - YENIDEN ISLEME:
  # Kasada 2.097 kayitta yuklenici adi jenerik bir sirket ekiyle BASLIYOR
  # ("Ticaret Limited Sirketi") - firmanin ozel adi kayip. Olculdu: bugunun
  # dort bulteni URETIMDEKI ayristiriciyla yeniden okundu, KESIK AD URETMEDI.
  # Yani ayristirici artik saglam; kusur eski bir turdan kalma. Onarim =
  # ayni gunu bugunun ayristiricisiyla yeniden isle, kasaya upsert et.
  # Ama is listesi ihale_eksik_gun()'den geliyor ve o gunler "cekilmis"
  # sayildigi icin bir daha gelmiyorlardi. Bu parametre listeyi ELLE verir.
  #   ./ihale-sonuc-backfill.ps1 -Gunler '2026-08-27,2026-08-28'
  # AYRI BIR CIKARICI YAZILMADI - bilerek. 30.08'de denendi ve dustu:
  # KISIMLI ihalede bir IKN'nin BIRDEN COK yuklenicisi var (her kisma bir
  # sozlesme). "IKN -> tek ad" modeli 1.295 kaydi yanlis eslestirdi. Dogru
  # anahtar IKN degil, IKN+sozlesme; onu zaten uretimdeki ayristirici
  # cikariyor. Onarim onun uzerinden yurur.
  [string]$Gunler = ""
)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$hasat    = Join-Path $here "ihale-bulten-hasat.ps1"
$ayristir = Join-Path $here "ihale-sonuc-ayristir.ps1"
$yukle    = Join-Path $here "ihale-supabase-yukle.ps1"
$ambar    = Join-Path $kok  "veri\ihale-sonuc.json"
$damgaYol = Join-Path $kok  "veri\ihale-son-kosu-damga.json"
$atlanYol = Join-Path $kok  "veri\ihale-backfill-atlanan.json"

$SB_URL  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()

# --- is listesi: kasadan ----------------------------------------------------
function EksikGunler([int]$ayGeri, [string[]]$turler){
  if(-not $anahtar){ return $null }
  $bugun = Get-Date
  $govde = @{
    p_bas    = $bugun.AddMonths(-$ayGeri).ToString('yyyy-MM-dd')
    p_bit    = $bugun.AddDays(-1).ToString('yyyy-MM-dd')
    p_turler = @($turler)
  } | ConvertTo-Json -Compress
  $bas = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'Content-Type'='application/json'
            Accept='application/json'; 'User-Agent'='MevzuatRadar-Backfill' }
  # 🔴 SAYFALAMA SART (30.08 olcumu): PostgREST sayfa basina 1.000 satirda
  # kesiyor. 36 aylik aralik 3.124 (gun,is kolu) satiri donuyor; sayfalamasiz
  # istenirse yalnizca en yeni 1.000'i gorulur ve is listesi SESSIZCE kirpilir.
  # Content-Range basligi gercek toplami veriyor ("0-999/3124") - okunur ve
  # kirpilma olup olmadigi ekrana YAZILIR.
  # Ayrica -UseBasicParsing sart (PS 5.1 etkilesimsiz kabukta IE motorunu arar)
  # ve bos JSON dizisi ([]) Invoke-RestMethod'da tek ogeye sariliyor; bu yuzden
  # govde METIN alinip kendimiz ayristiriyoruz.
  $hepsi = New-Object Collections.ArrayList
  $off = 0; $toplam = $null
  try{
    while($true){
      $c = Invoke-WebRequest -UseBasicParsing -Method Post `
             -Uri "$SB_URL/rest/v1/rpc/ihale_eksik_gun?limit=1000&offset=$off" `
             -Headers ($bas + @{ Prefer='count=exact' }) `
             -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
      if($null -eq $toplam -and "$($c.Headers['Content-Range'])" -match '/(\d+)$'){ $toplam = [int]$Matches[1] }
      # ConvertFrom-Json boru hattinda diziyi ACMAZ (PS 5.1) - once degiskene
      # al, sonra @() ile ac. Yoksa 1.000 satir "1" gorunur ve dongu hemen biter.
      $parca = @()
      if("$($c.Content)".Trim()){
        $coz = ConvertFrom-Json -InputObject $c.Content
        if($null -ne $coz){ $parca = @($coz) }
      }
      if(-not $parca.Count){ break }
      foreach($p in $parca){ [void]$hepsi.Add($p) }
      $off += $parca.Count
      if($null -ne $toplam -and $off -ge $toplam){ break }
    }
  }catch{
    Write-Host ("!! is listesi kasadan alinamadi: {0}" -f $_.Exception.Message)
    Write-Host "   (goc basili mi? radar-app/sql/2026-08-30-ihale-bulten-kutugu.sql)"
    return $null
  }
  if($null -ne $toplam -and $hepsi.Count -lt $toplam){
    Write-Host ("!! is listesi EKSIK alindi: {0}/{1} satir - kirpilmis liste ile kosulmaz" -f $hepsi.Count, $toplam)
    return $null
  }
  return @($hepsi)
}

# atlanan gunler (arsivin vermedigi) - sonsuz tekrari onler
$atlanan = @{}
if(Test-Path $atlanYol){
  try{ foreach($p in (Get-Content $atlanYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties){ $atlanan[$p.Name] = $p.Value } }catch{}
}

Write-Host ("BACKFILL v2 · {0} ay · is kolu: {1} · serit {2}/{3}" -f $AyGeri, ($Turler -join ','), $Serit, $SeritSayisi)
if(-not $anahtar){
  Write-Host '!! DURDURULDU: SUPABASE_SERVICE_KEY yok.'
  Write-Host '   v2 gunluk kayitlari dogrudan kasaya yazar; anahtarsiz kosmak'
  Write-Host '   yerelde 900 MB dosya sisirmekten baska ise yaramaz.'
  Write-Host '   Yerelde: anahtar-kur.cmd  |  Actions: Secrets -> SUPABASE_SERVICE_KEY'
  exit 1
}

if($Gunler.Trim()){
  # YENIDEN ISLEME: is listesi kasadan degil, disaridan geliyor. Bu gunler
  # "eksik" DEGIL - zaten cekilmis. Bilerek yeniden cekiliyorlar (bkz. param).
  $gunler = @($Gunler -split '[,; ]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Descending)
  $bozuk = @($gunler | Where-Object { $_ -notmatch '^\d{4}-\d{2}-\d{2}$' })
  if($bozuk.Count){ Write-Host ("Gun bicimi yyyy-MM-dd olmali. Bozuk: {0}" -f ($bozuk -join ', ')) -ForegroundColor Red; exit 1 }
  Write-Host ("YENIDEN ISLEME: {0} gun elle verildi (kasadaki eksik listesi kullanilmadi)" -f $gunler.Count) -ForegroundColor Yellow
} else {
  $eksik = EksikGunler $AyGeri $Turler
  if($null -eq $eksik){ exit 1 }

  # (gun,tur) satirlarini GUNE indirge: bir gunun bulteni tek indirmede tum
  # turleri getiriyor (zip icinde). Gun bazli calisip turleri birlikte isliyoruz.
  $gunler = @($eksik | ForEach-Object { "$($_.gun)" } | Select-Object -Unique | Sort-Object -Descending)
  Write-Host ("EKSIK: {0} (gun,tur) satiri -> {1} tekil gun" -f @($eksik).Count, $gunler.Count)
  if(-not $gunler.Count){ Write-Host 'Eksik gun yok - havuz tam.'; exit 0 }
}

# serit payi: siradaki her SeritSayisi'nci gun bu seride duser
if($SeritSayisi -gt 1){
  $pay = New-Object Collections.ArrayList
  for($i=0; $i -lt $gunler.Count; $i++){ if(($i % $SeritSayisi) -eq $Serit){ [void]$pay.Add($gunler[$i]) } }
  $gunler = @($pay)
  Write-Host ("   bu seride: {0} gun" -f $gunler.Count)
}

$islenen=0; $tamam=0; $eksikKaldi=0; $arsivYok=0; $hata=0
foreach($g in $gunler){
  if($Gun -gt 0 -and $islenen -ge $Gun){ break }
  $d = [datetime]::ParseExact("$g".Substring(0,10), 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
  $ts = $d.ToString('dd.MM.yyyy')
  if($atlanan.ContainsKey($ts)){ continue }

  # HER GUN SIFIRDAN: birikimli havuz O(n^2) idi. Biriktiren yer kasa.
  if(Test-Path $ambar){ Remove-Item $ambar -Force -ErrorAction SilentlyContinue }
  if(Test-Path $damgaYol){ Remove-Item $damgaYol -Force -ErrorAction SilentlyContinue }

  # 🔴 BAYAT DOSYA TUZAGI (30.08 provasinda olculdu, sessizdi):
  # hasat indirdigi bulteni $Klasor'e yaziyor; bir turun indirmesi DUSERSE eski
  # gunun sonuc-<tur>.txt'si orada KALIYOR ve ayristirici onu yeniden ayristiriyor.
  # Provada tam bu oldu: 27.08 kosusunda Mal, 28.08'in metniydi. Damga kaynaktan
  # okundugu icin kutuk yalan soylemedi (satir 2026-08-28 yazildi) ama gun "TAM"
  # sayildi ve 27.08 Mal sessizce atlandi.
  # Cozum: gun baslamadan turlerin metin/pdf/zip dosyalari SILINIR. Indirme
  # duserse "sonuc metni yok" denir, gun TAM sayilmaz ve listeye geri gelir.
  $kls = if("$($env:IHALE_BULTEN_KLASOR)".Trim()){ $env:IHALE_BULTEN_KLASOR }
         else { Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten" }
  if(Test-Path $kls){
    foreach($t in $Turler){
      $tl = $t.ToLower()
      foreach($uzanti in @('txt','pdf','zip','ham')){
        foreach($on in @('sonuc','bulten')){
          $yol = Join-Path $kls ("{0}-{1}.{2}" -f $on, $tl, $uzanti)
          if(Test-Path $yol){ Remove-Item $yol -Force -ErrorAction SilentlyContinue }
        }
      }
    }
  }

  try{
    & $hasat -Turler $Turler -Tarih $ts *> $null
    & $ayristir -Yaz *> $null
  }catch{
    Write-Host ("  {0} · HATA: {1}" -f $ts, $_.Exception.Message); $hata++
    $islenen++; Start-Sleep -Seconds $BeklemeSn; continue
  }

  if(-not (Test-Path $damgaYol)){
    Write-Host ("  {0} · damga uretilmedi (bulten inmedi?)" -f $ts); $hata++
    $islenen++; Start-Sleep -Seconds $BeklemeSn; continue
  }
  # ConvertFrom-Json boru hattinda diziyi ACMAZ (PS 5.1): @(... | ConvertFrom-Json)
  # ic ice dizi verir, $_.tarih bulunamaz, kayit toplami [int]'e cevrilemez.
  # Once degiskene al, sonra @() ile ac.
  $dmgHam = ConvertFrom-Json -InputObject (Get-Content $damgaYol -Raw -Encoding UTF8)
  $dmg = @($dmgHam)

  # ISTENEN GUN = GELEN GUN MU? Arsiv formu tutmazsa KIK bugunun bultenini
  # doner; damga kaynaktan okundugu icin bu fark GORUNUR. Yanlis bulteni o
  # gunun verisi diye yazmak, havuza sessiz kirlilik sokar.
  $gelen = @($dmg | Where-Object { $_.tarih } | Select-Object -ExpandProperty tarih -Unique)
  $bekle = $d.ToString('yyyy-MM-dd')
  if($gelen.Count -and ($gelen -notcontains $bekle)){
    Write-Host ("  {0} · ARSIV VERMEDI (istenen {1}, gelen {2}) - atlaniyor" -f $ts, $bekle, ($gelen -join ','))
    $atlanan[$ts] = ("istenen {0}, gelen {1}" -f $bekle, ($gelen -join ','))
    ($atlanan | ConvertTo-Json) | Out-File $atlanYol -Encoding utf8
    $arsivYok++; $islenen++; Start-Sleep -Seconds $BeklemeSn; continue
  }

  # IKINCI AG: tur tur damga kontrolu. Yukaridaki kontrol "turlerden BIRI bile
  # dogru gunse gec" diyor; karisik gun (bir tur bugun, bir tur dun) oradan
  # siziyordu. Burada BASKA gune damgali her tur ayri ayri yakalanir.
  $yanlisGun = @($dmg | Where-Object { $_.tarih -and $_.tarih -ne $bekle })
  foreach($y in $yanlisGun){
    Write-Host ("  {0} · !! {1} bulteni {2} damgali - bu gune SAYILMIYOR" -f $ts, $y.tur, $y.tarih)
  }

  $toplam = (@($dmg | ForEach-Object { [int]$_.kayit }) | Measure-Object -Sum).Sum
  # TAM olcutu: her is kolu hem dogru gune damgali OLACAK hem icindekiler=govde
  # tutacak. Biri bile saglanmazsa gun TAM degildir ve listeye geri gelir.
  $tamMi = ($yanlisGun.Count -eq 0) -and
           (-not @($dmg | Where-Object { -not $_.tam -and $_.beklenen }).Count) -and
           (-not @($dmg | Where-Object { $_.sebep -eq 'indirilemedi' }).Count)

  if($Olc){
    Write-Host ("  {0} · {1,5} kayit · {2}  (OLCUM - yazilmadi)" -f $ts, $toplam, $(if($tamMi){'TAM'}else{'EKSIK'}))
  } else {
    # yukleyici hem kayitlari hem KUTUGU yazar (damga dosyasindan)
    # CIKTI YUTULMAZ: dusen kapinin NEDEN dustugu goruluyor olmali. Ilk surumde
    # "*> $null" yaziyordu ve "YUKLEME DUSTU (kod 1)" disinda hicbir sey
    # gorunmuyordu - sebebi bulmak icin betigi elle kosmak gerekti.
    $yukCikti = & $yukle 2>&1
    if($LASTEXITCODE -ne 0){
      Write-Host ("  {0} · YUKLEME DUSTU (kod {1}) - kutuge centik atilmadi" -f $ts, $LASTEXITCODE)
      foreach($sat in @($yukCikti | Select-Object -Last 6)){ Write-Host ("       | {0}" -f $sat) }
      $hata++; $islenen++; Start-Sleep -Seconds $BeklemeSn; continue
    }
    Write-Host ("  {0} · {1,5} kayit · {2}" -f $ts, $toplam, $(if($tamMi){'TAM'}else{'EKSIK -> tekrar cekilecek'}))
  }
  if($tamMi){ $tamam++ } else { $eksikKaldi++ }
  $islenen++
  Start-Sleep -Seconds $BeklemeSn
}

Write-Host ""
Write-Host ("BITTI · islenen gun: {0} · tam: {1} · eksik kaldi: {2} · arsiv vermedi: {3} · hata: {4}" -f `
            $islenen, $tamam, $eksikKaldi, $arsivYok, $hata)
if($eksikKaldi -or $hata){
  Write-Host "   Eksik/hatali gunler kutukte 'tam=false' kaldi; betigi tekrar kosunca yalniz onlar cekilir."
}
if($arsivYok){
  Write-Host ("   Arsivin vermedigi {0} gun veri/ihale-backfill-atlanan.json'da sebebiyle yazili." -f $arsivYok)
}
Write-Host "   Kapsama raporu: ./motor/ihale-kapsama-raporu.ps1"
