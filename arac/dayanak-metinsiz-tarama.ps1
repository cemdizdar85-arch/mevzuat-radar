# ============================================================================
#  METİNSİZ DAYANAK TARAMASI (02.09.2026 — Cem: "2 yap")
#
#  Köprüdeki bir dayanağın ambarda KARŞILIĞI yoksa o konu ölçülemez ve soru
#  üretilemez: hakem dayanağı doğrulayamaz, üretici kaynak metnini çekemez.
#  Bunlar ne "çöp" ne "sağlam" — ÖLÇÜLEMEZ. Ayrı ele alınmaları gerekir:
#  ya kaynak yutulur ya da konu kaynak borcuna yazılır.
#  (02.09'da kara liste ölçümünde üç dayanak böyle çıktı: "SPK Kararı",
#   "SPK Tebliğ (Seri: X, No: 22)", madde numarasız düz "TTK (6102 s.K.)".)
#
#  YÖNTEM: ambardaki TÜM kaynak adları sayfalanarak çekilir (tek kolon, hızlı),
#  köprünün tekil dayanaklarıyla karşılaştırılır. Üç eşleşme denenir:
#    1) birebir ad   2) madde öneki (" - açıklama" atılmış hâli)
#    3) önek eşleşmesi (ambar adı dayanakla başlıyor mu)
#  ÇIKTI: veri/dayanak-metinsiz-raporu.json — etkilenen konu sayısına göre sıralı.
#
#  ⚠ PS: döngü değişkenine $h/$d gibi tek harf VERİLMEZ ($H başlıkları ezer).
#  ⚠ PS: hashtable literalinde List'i @() ile sarma — .ToArray() kullan.
# ============================================================================
param(
  [int]$EnAzKonu=1,        # kac konuya bagli dayanaklar raporlansin
  [int]$ListeTavan=60      # ekrana/rapora kac ornek yazilsin
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$BASLIK=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# --- ambardaki tum kaynak adlari (sayfali; order SART - order'siz offset kararsizdir)
$ambarAdlari=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$ofs=0
while($true){
  $u=$AMBAR+"?select=kaynak_ad&order=kaynak_ad.asc&limit=1000&offset=$ofs"
  $cevap=$null
  foreach($deneme in 1..4){
    try{ $cevap=Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 120; break }
    catch{ if($deneme -eq 4){ throw "ambar adlari cekilemedi (offset $ofs): $($_.Exception.Message)" }; Start-Sleep -Seconds (4*$deneme) }
  }
  $ham=ConvertFrom-Json -InputObject $cevap.Content
  $sayfa=@($ham)
  if($sayfa.Count -eq 0){ break }
  foreach($kayit in $sayfa){ if($kayit.kaynak_ad){ [void]$ambarAdlari.Add("$($kayit.kaynak_ad)") } }
  if($sayfa.Count -lt 1000){ break }
  $ofs+=1000
  if($ofs -gt 200000){ break }
}
Write-Host "ambarda tekil kaynak adi: $($ambarAdlari.Count)"

# hizli onek aramasi icin sirali dizi
$sirali=@($ambarAdlari) | Sort-Object
# 02.09 DUZELTME: ilk surum ham ad kiyasi yapiyordu ve "%50 ambarda yok" dedi -
# oysa cogu YAZIM FARKIYDI ("VUK m.275" vs ambardaki "VUK (213 s.K.) m.275 - Imal
# edilen emtia"). Artik deponun kendi DayanakAnahtar normalizasyonu + KANUN/STANDART
# kimlik cikarimi kullaniliyor; boylece "kaynak eksigi" ile "ad farki" ayrisir.
. (Join-Path $depoKok 'arac\dayanak-normalize.ps1')
$ambarAnahtar=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($ad in $sirali){ $ak=DayanakAnahtar $ad; if($ak){ [void]$ambarAnahtar.Add($ak) } }
# kanun kisa adi + madde no / standart + paragraf cikarimi (uretici DesenUret mantigi)
function KimlikCikar([string]$metin){
  $sonuc=New-Object System.Collections.Generic.List[string]
  foreach($m in [regex]::Matches($metin,'(TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS)\s*(\d+)')){ $sonuc.Add("$($m.Groups[1].Value) $($m.Groups[2].Value)") }
  foreach($m in [regex]::Matches($metin,'(\d{3,4})\s*sayılı')){ $sonuc.Add("SK$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'\((\d{3,4})\s*s\.K\.\)')){ $sonuc.Add("SK$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'\b(VUK|TTK|TBK|GVK|KVK|KDV|SPK|İİK|AATUHK|MSUGT|THP)\b')){ $sonuc.Add($m.Groups[1].Value.ToUpperInvariant()) }
  foreach($m in [regex]::Matches($metin,'\bm\.?\s*(\d+)')){ $sonuc.Add("M$($m.Groups[1].Value)") }
  return @($sonuc)
}
# ambardaki her adin kimlik kumesi (bir kez hesaplanir)
$ambarKimlik=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($ad in $sirali){ foreach($kim in (KimlikCikar $ad)){ [void]$ambarKimlik.Add($kim) } }

# 02.09 iki tuzak daha olculdu:
#  (a) PARAGRAF ARALIGI: kopruDE "TMS 40 p.1-4 - Amac ve kapsam" yaziyor, ambarda
#      "TMS 40 p.1 - Amac" olarak TEK TEK duruyor -> aralik acilip ilk paragraf aranir.
#  (b) TURKCE HARF: "MSUGT Tekduzen Hesap Plani" arandi, ambarda "Tekduzen" DEGIL
#      "Tekduzen"in u-umlautlu hali var -> katlanmis ad kumesi eklendi.
$ambarKatli=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
function HarfKatla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
foreach($ad in $sirali){ [void]$ambarKatli.Add((HarfKatla $ad)) }
$katliDizi=@($ambarKatli)
# 02.09 iki eslesme daha (olculdu):
#  "MSUGT Tekduzen Hesap Plani - 120" -> ambarda "THP 120 - Alicilar"
#  "BDS 230 madde 16" / "BDS 500 A31" -> ambarda "BDS 230 p.16" / "BDS 500 p.A31"
function EsAdlar([string]$dayanak){
  $liste=New-Object System.Collections.Generic.List[string]
  $m1=[regex]::Match($dayanak,'(?i)MSUGT.*?(\d{3})\s*$')
  if($m1.Success){ $liste.Add("THP $($m1.Groups[1].Value)") }
  $m2=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS)\s*\d+)[\s,]+(?:madde|md\.?|Ek)?\s*(A?\d+)')
  if($m2.Success){ $liste.Add(("{0} p.{1}" -f $m2.Groups[1].Value,$m2.Groups[2].Value)) }
  return @($liste)
}
function AralikAc([string]$dayanak){
  # "TMS 40 p.1-4 - Amac" -> "TMS 40 p.1" ; "BDS 540 p.1-11 - ..." -> "BDS 540 p.1"
  $m=[regex]::Match($dayanak,'^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS)\s*\d+\s*p\.\s*)(\d+)\s*-\s*\d+')
  if($m.Success){ return ($m.Groups[1].Value+$m.Groups[2].Value) }
  return ''
}
function AmbardaVarMi([string]$dayanak){
  if($ambarAdlari.Contains($dayanak)){ return 'birebir' }
  # paragraf araligi
  $ilkPar=AralikAc $dayanak
  if($ilkPar){
    $ilkKat=HarfKatla $ilkPar
    foreach($ad in $katliDizi){ if($ad.StartsWith($ilkKat,[StringComparison]::OrdinalIgnoreCase)){ return 'paragraf-araligi' } }
  }
  # es-ad eslemesi (MSUGT->THP, "madde N"->"p.N")
  foreach($es in (EsAdlar $dayanak)){
    $esKat=HarfKatla $es
    foreach($ad in $katliDizi){ if($ad.StartsWith($esKat,[StringComparison]::OrdinalIgnoreCase)){ return 'es-ad' } }
  }
  # turkce harf katlamasi ile onek
  $dayKat=HarfKatla (($dayanak -replace ' - .*$','').Trim())
  if($dayKat.Length -ge 6){
    foreach($ad in $katliDizi){ if($ad.StartsWith($dayKat,[StringComparison]::OrdinalIgnoreCase)){ return 'harf-katlamasi' } }
  }
  $cekirdek=($dayanak -replace ' - .*$','').Trim()
  if($cekirdek -ne $dayanak -and $ambarAdlari.Contains($cekirdek)){ return 'cekirdek' }
  $anahtar=DayanakAnahtar $dayanak
  if($anahtar -and $ambarAnahtar.Contains($anahtar)){ return 'normalize-anahtar' }
  foreach($ad in $sirali){ if($ad.StartsWith($dayanak,[StringComparison]::OrdinalIgnoreCase)){ return 'onek' } }
  if($cekirdek -ne $dayanak){
    foreach($ad in $sirali){ if($ad.StartsWith($cekirdek,[StringComparison]::OrdinalIgnoreCase)){ return 'cekirdek-onek' } }
  }
  # kimlik eslesmesi: kanun/standart + madde/paragraf ikilisi ambarda geciyor mu
  $kimlikler=@(KimlikCikar $dayanak)
  if($kimlikler.Count -ge 2){
    $tutan=@($kimlikler | Where-Object { $ambarKimlik.Contains($_) }).Count
    if($tutan -eq $kimlikler.Count){ return 'kimlik' }
  }
  return ''
}

$tam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$sayac=@{}
foreach($kayit in @($tam)){
  $day="$($kayit.dayanak)"; if(-not $day){ $day="$($kayit.cikmis_dayanak)" }
  $day=($day -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $day){ continue }
  if(-not $sayac.ContainsKey($day)){ $sayac[$day]=0 }
  $sayac[$day]++
}
Write-Host "koprude tekil dayanak: $($sayac.Keys.Count)"

$metinsiz=New-Object System.Collections.Generic.List[object]
$varSayi=0; $yokKayit=0
$adaylar=@($sayac.Keys | Where-Object { $sayac[$_] -ge $EnAzKonu })
$ilerleme=0
foreach($dayanak in $adaylar){
  $ilerleme++
  if($ilerleme % 500 -eq 0){ Write-Host "  ...$ilerleme / $($adaylar.Count)" }
  $durum=AmbardaVarMi $dayanak
  if($durum){ $varSayi++; continue }
  $yokKayit += $sayac[$dayanak]
  $metinsiz.Add([pscustomobject][ordered]@{ dayanak=$dayanak; etkilenen_kayit=$sayac[$dayanak] })
}
$sirali2=@($metinsiz | Sort-Object { -[int]$_.etkilenen_kayit })

$cikti=[pscustomobject][ordered]@{
  aciklama="Koprudeki dayanaklarin ambarda KARSILIGI var mi taramasi. Karsiligi olmayan dayanak = OLCULEMEZ konu: hakem dogrulayamaz, uretici kaynak metnini cekemez, soru uretilemez. Bunlar cop DEGILDIR - kaynak eksigidir. Eslesme uc yolla denenir: birebir ad, ' - aciklama' atilmis cekirdek, onek eslesmesi."
  ambar_tekil_ad=$ambarAdlari.Count
  kopru_tekil_dayanak=$sayac.Keys.Count
  ambarda_bulunan=$varSayi
  ambarda_BULUNMAYAN=$metinsiz.Count
  bulunmayan_yuzde=$(if($adaylar.Count){[math]::Round(100*$metinsiz.Count/$adaylar.Count,1)}else{0})
  etkilenen_kopru_kaydi=$yokKayit
  en_cok_etkileyenler=@($sirali2 | Select-Object -First $ListeTavan | ForEach-Object { "$($_.dayanak) -> $($_.etkilenen_kayit) kayit" })
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\dayanak-metinsiz-raporu.json') -Nesne $cikti

Write-Host ""
Write-Host "=== METINSIZ DAYANAK ==="
Write-Host ("  ambarda bulunan   : {0}" -f $varSayi)
Write-Host ("  BULUNMAYAN        : {0}  (%{1})" -f $metinsiz.Count,$cikti.bulunmayan_yuzde)
Write-Host ("  etkilenen kayit   : {0} / {1}" -f $yokKayit,@($tam).Count)
Write-Host ""
Write-Host "--- EN COK KAYIT ETKILEYEN METINSIZ DAYANAKLAR ---"
foreach($ornek in @($sirali2 | Select-Object -First 25)){
  Write-Host ("  {0,5} kayit <- {1}" -f $ornek.etkilenen_kayit,$ornek.dayanak)
}
