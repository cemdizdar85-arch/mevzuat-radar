#requires -Version 5.1
<#
================================================================================
  AKTARIM KAPILARI — fabrika → soru_havuzu geçiş denetimi (10.09.2026)

  Cem: "9 kapıyı koştur, net geçen sayıyı raporla."

  VARSAYILAN: ÖLÇÜM KİPİ. Hiçbir şey yazmaz, hiçbir yere POST atmaz.
  Aktarım ayrı bir betiktir ve ancak bu ölçüm okunduktan sonra koşar.

  ÜÇ KOVA — soru çöpe atılmaz, ayrıştırılır:
    GEÇTİ        → 9 kapıdan da geçti, v2 damgasıyla kasaya inebilir
    ONARILABİLİR → mantığı sağlam, kusuru biçimsel (yuvarlak tutar, placeholder
                   unvan, eksik tuzak adı, uzunluk). Rakam/unvan tazelenir,
                   hakem turuna yeniden girer.
                   ⚠️ Tutar değişimi HESABI BOZAR: şıklar da yeniden hesaplanır,
                   soru yayin=false düşer, hakem YENİDEN yargılar (29.07 dersi).
    BEKLESİN     → konu etiketi gövdeyle örtüşmüyor. Yanlış konuya asılı soru,
                   olmayan sorudan zararlıdır (Cem, 10.09). Etiket dayanaktan
                   yeniden türetilene kadar fabrikada bekler.

  DİNAMİK UZUNLUK TAVANI: ders başına p90, `veri/sinav-anatomisi-sgs.json`'dan
  OKUNUR, sabit yazılmaz. Sebep ölçüldü: sınav uzuyor (SGS medyanı 2024/2'de
  153 → 2026/2'de 215, +%40). Sabit "350" tavanı 13 dersin hiçbirine oturmuyor
  (Maliyet 551, Ticaret 136).

  YD / MATEMATİK MUAFİYETİ: konu–gövde örtüşme ölçütü bu iki derste GEÇERSİZ —
  YD gövdesi İngilizce, matematik gövdesi formül/sayı; Türkçe konu adı orada
  geçmez. Ölçüldü: yd partilerinde şüpheli oranı %93'e çıkıyor, soru bozuk
  olduğu için değil ÖLÇÜT çöktüğü için. Katı ölçüt şişirir, gevşek ölçüt
  uydurur (bkz. konu-kaynak-eslestirme-yasagi).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/aktarim-kapilari.ps1
================================================================================
#>
param(
  [string]$Cikti = 'veri\aktarim-kapilari.json'
)

$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' `
        -creplace 'Â','a' -creplace 'â','a').ToLowerInvariant()
}

# Konu adında geçen ama ayırt etmeyen kelimeler: örtüşme ölçütüne girmez.
$GENEL = @('kaydi','kayitlar','kayit','hesabi','hesap','uzerindeki','ile','ilgili','genel',
           'esaslar','konusu','turleri','sartlari','tanimi','unsurlari','islemleri','sistemi',
           'durumu','yontemi','sorunu','beyani','bolumu','olcusu','degeri','orani')

# --- DERS ESLEMESI: parti adi -> sinav anatomisindeki ders adi ---------------
# DEGISKEN ADI DIKKAT: bu tablonun adi '$DERS' OLAMAZ. PowerShell harf ayirmaz;
# asagidaki dongude '$ders = DersBul $parti' satiri ayni degiskene yazar ve
# TABLOYU BIR METINLE EZER. Olculdu (10.09): ilk cagri calisti, sonraki 3.695
# cagri null dondu; ders bulunamadigi icin uzunluk tavani (kapi 7) HIC
# uygulanmadi ve "0 soru tavani asti" diye YANLIS rapor uretildi.
# Bu tuzak depoda yazili: ps-degisken-cakismasi.
$DERS_ESLEME = [ordered]@{
  'fmuh'='Finansal Muhasebe'; 'maliyet'='Maliyet Muhasebesi'; 'mta'='Mali Tablolar Analizi';
  'denetim'='Denetim'; 'ticaret'='Ticaret ve Borclar'; 'borclar'='Ticaret ve Borclar';
  'vergi'='Vergi Hukuku'; 'maliye'='Maliye'; 'ekonomi'='Ekonomi'; 'meslek'='Meslek Hukuku';
  'issgk'='Is ve Sosyal Guvenlik'; 'turkce'='Turkce'; 'mat'='Matematik'; 'inkilap'='Ataturk Ilkeleri'
}
function DersBul([string]$parti){
  $p = Katla $parti
  foreach($k in $DERS_ESLEME.Keys){ if($p -match "(^|-)$k(-|$)"){ return $DERS_ESLEME[$k] } }
  return $null
}

# --- DINAMIK UZUNLUK TAVANI (ders p90) --------------------------------------
$anatomiYol = Join-Path $depoKok 'veri\sinav-anatomisi-sgs.json'
if(-not (Test-Path $anatomiYol)){ throw "Uzunluk tavani OKUNAMADI: $anatomiYol yok. Sabit tavan YAZILMAZ - olcum durduruldu." }
$anatomi = Get-Content $anatomiYol -Raw -Encoding UTF8 | ConvertFrom-Json
$TAVAN = @{}
foreach($p in $anatomi.C_ders_kalibi.PSObject.Properties){ $TAVAN[$p.Name] = [int]$p.Value.uzunluk.p90 }
Write-Host "DINAMIK UZUNLUK TAVANI (ders p90, anatomiden okundu):" -ForegroundColor Cyan
$TAVAN.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("  {0,-24} {1}" -f $_.Key,$_.Value) }

# ============================================================================
#  KAPILAR
# ============================================================================
$f = Get-ChildItem (Join-Path $depoKok 'veri\fabrika\kalip-parti-*.json')
$HARF = @('A','B','C','D','E')

$sayac = [ordered]@{
  toplam=0; hakem_hayir=0; hakem_yok=0; hakem_evet=0
  k2_cekirdek=0; k3_konu=0; k4_placeholder=0; k5_yuvarlak=0; k6_klise=0; k7_uzunluk=0
  gecti=0; onarilabilir=0; beklesin=0
}
$kovalar = @{ gecti=New-Object System.Collections.ArrayList; onarilabilir=New-Object System.Collections.ArrayList; beklesin=New-Object System.Collections.ArrayList }

foreach($x in $f){
  $parti = $x.BaseName -replace '^kalip-parti-',''
  $dersAdi  = DersBul $parti
  $olcutDisi = ($parti -match '(^|-)(yd|mat)(-|$)')   # konu ortusmesi bu derslerde gecersiz
  try{ $j = Get-Content $x.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }

  foreach($p in $j.PSObject.Properties){
    $v = $p.Value
    if(-not $v -or -not $v.soru){ continue }
    $sayac.toplam++

    # KAPI 1 — hakem
    if(-not ($v.hakem -and $v.hakem.karar)){ $sayac.hakem_yok++; continue }
    if("$($v.hakem.karar)" -ne 'EVET'){ $sayac.hakem_hayir++; continue }
    $sayac.hakem_evet++

    $s = "$($v.soru)"
    $kusur = New-Object System.Collections.ArrayList

    # KAPI 2 — madde 1 cekirdek
    $sikTam  = (@($HARF | Where-Object { $v.siklar.PSObject.Properties[$_]   -and "$($v.siklar.$_)".Trim()   }).Count -eq 5)
    $acikTam = (@($HARF | Where-Object { $v.aciklama.PSObject.Properties[$_] -and "$($v.aciklama.$_)".Trim() }).Count -eq 5)
    $hapVar  = ($v.hap -and "$($v.hap)".Trim().Length -ge 10)
    $yanlisH = $HARF | Where-Object { $_ -ne "$($v.dogru)" }
    $tuzakTam= (@($yanlisH | Where-Object { "$($v.aciklama.$_)" -match '^\s*[^:]{3,60}Tuza[gğ][ıi]\s*:' }).Count -eq 4)
    if(-not ($sikTam -and $acikTam -and $hapVar -and $tuzakTam)){ $sayac.k2_cekirdek++; [void]$kusur.Add('cekirdek') }

    # KAPI 3 — konu-govde ortusmesi (yd/mat MUAF)
    $konuSuphe = $false
    if(-not $olcutDisi){
      $kel = @((Katla "$($v.konu)") -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 -and $GENEL -notcontains $_ })
      if($kel.Count -gt 0){
        $govde = Katla ($s + ' ' + (($HARF | ForEach-Object { "$($v.siklar.$_)" }) -join ' ') + " $($v.dayanak) $($v.hap)")
        if(-not (@($kel | Where-Object { $govde -match [regex]::Escape($_.Substring(0,[Math]::Min(6,$_.Length))) })).Count){
          $konuSuphe = $true; $sayac.k3_konu++
        }
      }
    }

    # KAPI 4 — placeholder unvan
    if($s -match '\b(XYZ|ABC|ABD)\b' -or $s -match '\b[A-Z]\s+A\.Ş\.' -or $s -match '\([A-Z]\)\s+A\.Ş\.'){
      $sayac.k4_placeholder++; [void]$kusur.Add('placeholder')
    }

    # KAPI 5 — tum tutarlar yuvarlak
    $tut = [regex]::Matches($s,'\b\d{1,3}(?:\.\d{3})+\b')
    if($tut.Count -ge 2){
      $hepsi=$true
      foreach($t in $tut){ if(($t.Value -replace '\.','') -notmatch '000$'){ $hepsi=$false; break } }
      if($hepsi){ $sayac.k5_yuvarlak++; [void]$kusur.Add('yuvarlak') }
    }

    # KAPI 6 — klise
    if($s -match 'bu bağlamda|önem arz et|sonuç olarak|göz önünde bulundur' -or $s -match '\S\s—\s\S'){
      $sayac.k6_klise++; [void]$kusur.Add('klise')
    }

    # KAPI 7 — dinamik uzunluk tavani (ders p90)
    if($dersAdi -and $TAVAN.ContainsKey($dersAdi) -and $s.Length -gt $TAVAN[$dersAdi]){
      $sayac.k7_uzunluk++; [void]$kusur.Add('uzunluk')
    }

    # --- KOVALAMA: konu suphesi ONCELIKLI (yanlis etiket en zararlisi) -------
    $kayit = [pscustomobject]@{ parti=$parti; id=$p.Name; ders=$dersAdi; konu="$($v.konu)"; uzunluk=$s.Length; kusur=($kusur -join ',') }
    if($konuSuphe){ $sayac.beklesin++; [void]$kovalar.beklesin.Add($kayit) }
    elseif($kusur.Count -gt 0){ $sayac.onarilabilir++; [void]$kovalar.onarilabilir.Add($kayit) }
    else { $sayac.gecti++; [void]$kovalar.gecti.Add($kayit) }
  }
}

# ============================================================================
#  RAPOR
# ============================================================================
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Cyan
Write-Host "9 KAPI SONUCU" -ForegroundColor Cyan
Write-Host ("=" * 62) -ForegroundColor Cyan
Write-Host ("  fabrikadaki toplam soru        {0,6}" -f $sayac.toplam)
Write-Host ("  KAPI 1  hakem HAYIR            {0,6}" -f $sayac.hakem_hayir)
Write-Host ("  KAPI 1  hakem kosmamis         {0,6}" -f $sayac.hakem_yok)
Write-Host ("  KAPI 1  hakem EVET             {0,6}" -f $sayac.hakem_evet) -ForegroundColor Green
Write-Host ""
Write-Host "  --- hakem EVET icinde kapiya takilanlar (kesisimli) ---"
Write-Host ("  KAPI 2  cekirdek eksik         {0,6}" -f $sayac.k2_cekirdek)
Write-Host ("  KAPI 3  konu ortusmuyor        {0,6}" -f $sayac.k3_konu)
Write-Host ("  KAPI 4  placeholder unvan      {0,6}" -f $sayac.k4_placeholder)
Write-Host ("  KAPI 5  tum tutarlar yuvarlak  {0,6}" -f $sayac.k5_yuvarlak)
Write-Host ("  KAPI 6  klise / em-dash        {0,6}" -f $sayac.k6_klise)
Write-Host ("  KAPI 7  ders p90 tavanini asan {0,6}" -f $sayac.k7_uzunluk)
Write-Host ""
Write-Host ("  ✅ GECTI        {0,6}   (v2 damgasiyla kasaya inebilir)" -f $sayac.gecti) -ForegroundColor Green
Write-Host ("  🔧 ONARILABILIR {0,6}   (rakam/unvan tazele + hakem yeniden)" -f $sayac.onarilabilir) -ForegroundColor Yellow
Write-Host ("  ⏸  BEKLESIN     {0,6}   (konu etiketi bozuk - fabrikada kalir)" -f $sayac.beklesin) -ForegroundColor DarkYellow

Write-Host ""
Write-Host "ONARILABILIR KOVASININ KUSUR KIRILIMI:"
$kovalar.onarilabilir | Group-Object kusur | Sort-Object Count -Descending | Select-Object -First 10 |
  ForEach-Object { Write-Host ("  {0,-34} {1,5}" -f $_.Name, $_.Count) }

# DEGISKEN ADI DIKKAT: PowerShell harf AYIRMAZ. Bu nesneye '$cikti' denince
# parametredeki '$Cikti' (dosya yolu) EZILIYOR ve rapor
# "System.Collections.Specialized.OrderedDictionary" adli dosyaya yazilmaya
# calisiliyordu. Depo dersi: global/parametre adlariyla cakisan kisa ad YASAK.
$raporNesnesi = [ordered]@{
  olcum   = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  yontem  = '9 kapi tek gecişte; konu suphesi oncelikli kovalama; uzunluk tavani ders p90 olarak anatomiden OKUNUR'
  muafiyet= 'yd ve mat partilerinde konu-govde ortusme olcutu GECERSIZ (govde Ingilizce / formul)'
  sayac   = $sayac
  tavan   = $TAVAN
  kovalar = @{
    gecti        = @($kovalar.gecti)
    onarilabilir = @($kovalar.onarilabilir)
    beklesin     = @($kovalar.beklesin)
  }
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Cikti) -Nesne $raporNesnesi
Write-Host ""
Write-Host ("Ayrinti: {0}" -f $Cikti) -ForegroundColor Cyan
