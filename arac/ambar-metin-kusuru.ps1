#requires -Version 5.1
<#
================================================================================
  AMBAR METİN KUSURU TARAMASI — "kaynak var" ile "kaynak sağlam" ayrı şeydir
  (21.09.2026, Cem "1 ve 2 yap")

  NEDEN: konu-kaynak karnesi yalnız "bu konuda ambarda metin VAR MI" diye bakar.
  Metnin bozuk olması onun gözüne "var" görünür. 19.09'da KGK sorularını yazan
  altı ajan bağımsız olarak aynı dört kusuru gördü ve o paragraflardan soru
  yazamadı; hiçbiri ölçülmüş değildi:
    K1 YAPIŞIK DİPNOT   : "BDS 20010", "açıklığı12", "bildirir3" — dipnot numarası
                          kelimeye/standart numarasına kaynamış. Soruya kopyalanırsa
                          OLMAYAN bir standart numarası üretir.
    K2 KESİK BENT       : "aşağıdakileri/şunları" diye liste açıp TEK bentle biten
                          kayıt (BDS 580 p.11, BDS 210 p.17). "Hangisi zorunludur"
                          sorusu bu kayıttan yazılamaz.
    K3 KOMŞU METİN      : kaydın sonuna bir sonraki paragrafın BAŞLIĞI yapışmış
                          (büyük harfle başlayan, cümle olmayan kuyruk).
    K4 MÜKERRER KAYIT   : aynı kaynak_ad birden çok satırda (BDS 540 p.3 üç kez).

  NE YAPAR: ambardaki metin kayıtlarını sayfa sayfa okur, dört kusuru SAYAR ve
  örnekleriyle raporlar. Yazma yok, model yok, bedel 0.

  BU TARAMA ŞUNU GÖRMEZ: iki sütunlu tablonun iç içe geçmesi (metin akışı bozuk
  ama desen yok), yanlış paragraf ADI (ad dipnottan üretilmiş), OCR harf hatası.
  Bunlar ayrı iş emridir — "temiz" çıkan kayıt bu üç kusurdan muaf DEĞİLDİR.

  KULLANIM
    powershell -NoProfile -File arac/ambar-metin-kusuru.ps1                 # tüm ambar
    powershell -NoProfile -File arac/ambar-metin-kusuru.ps1 -Desen 'BDS %'  # süzgeçli
    powershell -NoProfile -File arac/ambar-metin-kusuru.ps1 -OzSinav        # kapı sınavı
  ÇIKTI: veri/ambar-metin-kusuru.json
================================================================================
#>
param(
  [string]$Desen = '',
  [int]$Tavan = 0,
  [switch]$OzSinav
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$sinavIstendi = [bool]$OzSinav   # 22.09: dot-source edilen yardimcinin param([switch]$OzSinav)'i bu degiskeni EZIYOR - once sakla
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
. (Join-Path $PSScriptRoot 'dipnot-ayir.ps1')   # $STD_NO: gecerli standart numaralari

# ---- KUSUR ÖLÇERLER (öz-sınav bunları çağırır) ------------------------------
# K1: dipnot numarası kelimeye/standart numarasına kaynamış
#   yakalar : "BDS 20010", "BDS 3202", "açıklığı12", "bildirir3", "BDS 220 (Revize),7"
#   yakalamaz: "BDS 200" (normal), "2023 yılı" (rakam başta), "m.13" (nokta sonrası)
function KusurYapisikDipnot([string]$Metin){
  $bulgu = New-Object System.Collections.Generic.List[string]
  # 22.09 YANLIŞ ALARM ONARIMI: dört haneli GERÇEK numaralar var (GDS 3000/3402, İHS 4400,
  #   SBDS 2400/2410). Eski desen hepsini kusur sayıyordu. Artık ayırıcının numara listesi
  #   (arac/dipnot-ayir.ps1 $STD_NO) esas alınır: liste dışıysa VE kısaltılınca listeye
  #   düşüyorsa kusurdur.
  foreach($es in [regex]::Matches("$Metin",'\b(BDS|GDS|İHS|IHS|KYS|TSRS|SBDS)\s?(\d{2,6})\b')){
    $aile = $es.Groups[1].Value.Replace('İ','I'); $rakam = $es.Groups[2].Value
    if(-not $STD_NO.ContainsKey($aile)){ continue }
    if($STD_NO[$aile] -contains [int]$rakam){ continue }
    for($kes = $rakam.Length-1; $kes -ge 1; $kes--){ if($STD_NO[$aile] -contains [int]$rakam.Substring(0,$kes)){ $bulgu.Add($es.Value); break } }
  }
  foreach($es in [regex]::Matches("$Metin",'\p{L}{3,}\d{1,2}(?=[\s.,;:)])')){
    if($es.Value -match '(?i)^(no|md|m|p|s|sayfa|madde)\d'){ continue }   # "no12" gibi meşru kısaltma
    $bulgu.Add($es.Value)
  }
  return $bulgu
}
# K2: liste açıp tek bentle biten kayıt
#   yakalar : "...şunları sağladığına dair beyan: a) ..." (tek bent)
#   yakalamaz: iki ve daha fazla bendi olan kayıt, liste açmayan kayıt
function KusurKesikBent([string]$Metin){
  $m = "$Metin"
  if($m -notmatch '(?i)(aşağıdaki|şunlar|şu hususlar|aşağıda belirtilen)'){ return $false }
  $bent = ([regex]::Matches($m,'(?m)(?:^|\s)\(?[a-çğıöşüd]\)\s')).Count + ([regex]::Matches($m,'(?m)(?:^|\s)\(?(?:i{1,3}|iv|v)\)\s')).Count
  return ($bent -eq 1)
}
# K3: kaydın sonunda komşu paragrafın başlığı
#   yakalar : "...denetim kanıtı elde eder. Denetçinin Denetim Raporu Tarihinden Sonra" (nokta YOK, büyük harfli tamlama)
#   yakalamaz: normal cümleyle biten kayıt
function KusurKomsuBaslik([string]$Metin){
  $m = ("$Metin").Trim()
  if($m.Length -lt 80){ return $false }
  $son = $m.Substring([Math]::Max(0,$m.Length-90))
  $es = [regex]::Match($son,'(?:\.\s+)((?:\p{Lu}\p{L}+[ ,]+){2,}\p{Lu}\p{L}+)\s*$')
  if(-not $es.Success){ return $false }
  return -not $es.Groups[1].Value.EndsWith('.')
}

if($sinavIstendi){
  # kapı kurma kuralı 2: yakalaması gerekeni YAKALAR, yanlış alarm VERMEZ
  $vakalar = @(
    @{ ad='K1 yapışık standart numarası'; f='KusurYapisikDipnot'; metin='BDS 20010 uyarınca denetçi';             bekle=$true }
    @{ ad='K1 yanlış alarm: normal numara'; f='KusurYapisikDipnot'; metin='BDS 200 uyarınca denetçi';              bekle=$false }
    @{ ad='K1 yanlış alarm: GDS 3000 gerçek';  f='KusurYapisikDipnot'; metin='GDS 3000 güvence denetimi';           bekle=$false }
    @{ ad='K1 yanlış alarm: İHS 4400 gerçek';  f='KusurYapisikDipnot'; metin='İHS 4400 mutabık kalınan';            bekle=$false }
    @{ ad='K1 yapışık kelime dipnotu';    f='KusurYapisikDipnot'; metin='denetçi bunu zamanında bildirir3 ve';     bekle=$true }
    @{ ad='K2 tek bentli liste';          f='KusurKesikBent';     metin='Denetçi aşağıdakileri talep eder: a) tüm kayıtların sunulduğu.'; bekle=$true }
    @{ ad='K2 yanlış alarm: iki bent';    f='KusurKesikBent';     metin='Denetçi aşağıdakileri talep eder: a) kayıtlar b) beyanlar.';    bekle=$false }
    @{ ad='K3 komşu başlık kuyruğu';      f='KusurKomsuBaslik';   metin='Denetçi yeterli ve uygun denetim kanıtı elde etmek zorundadır ve bunu çalışma kâğıtlarında belgelendirir. Denetçi Raporu Tarihinden Sonra Ortaya Çıkan'; bekle=$true }
    @{ ad='K3 yanlış alarm: normal son';  f='KusurKomsuBaslik';   metin='Denetçi yeterli ve uygun denetim kanıtı elde etmek zorundadır ve bunu çalışma kâğıtlarında usulüne uygun biçimde belgelendirir.'; bekle=$false }
  )
  $gecti=0; $kaldi=0
  foreach($v in $vakalar){
    $sonuc = switch($v.f){
      'KusurYapisikDipnot' { @(KusurYapisikDipnot $v.metin).Count -gt 0 }
      'KusurKesikBent'     { [bool](KusurKesikBent $v.metin) }
      'KusurKomsuBaslik'   { [bool](KusurKomsuBaslik $v.metin) }
    }
    if($sonuc -eq $v.bekle){ $gecti++; Write-Host ("  OK    {0}" -f $v.ad) }
    else { $kaldi++; Write-Host ("  KALDI {0} (beklenen {1}, çıkan {2})" -f $v.ad,$v.bekle,$sonuc) -ForegroundColor Red }
  }
  Write-Host ("ÖZ-SINAV: geçti {0} · kaldı {1}" -f $gecti,$kaldi)
  exit $(if($kaldi){ 1 } else { 0 })
}

$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$H = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }

$suzgec = if($Desen){ '&kaynak_ad=like.' + [uri]::EscapeDataString($Desen) } else { '' }
$adim = 500; $ofs = 0
$toplam = 0; $k1 = 0; $k2 = 0; $k3 = 0
$adSayaci = @{}
$ornek = @{ K1=New-Object System.Collections.Generic.List[string]; K2=New-Object System.Collections.Generic.List[string]; K3=New-Object System.Collections.Generic.List[string]; K4=New-Object System.Collections.Generic.List[string] }
while($true){
  $sayfa = @(); foreach($x in (Invoke-RestMethod -Uri "$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&order=id&limit=$adim&offset=$ofs$suzgec" -Headers $H -TimeoutSec 180)){ $sayfa += $x }
  if(-not $sayfa.Count){ break }
  foreach($r in $sayfa){
    $toplam++
    $ad = "$($r.kaynak_ad)"; $mt = "$($r.metin)"
    $adSayaci[$ad] = 1 + [int]$adSayaci[$ad]
    $b1 = KusurYapisikDipnot $mt
    if($b1.Count){ $k1++; if($ornek.K1.Count -lt 15){ $ornek.K1.Add("$ad -> $(($b1 | Select-Object -First 3) -join ', ')") } }
    if(KusurKesikBent $mt){ $k2++; if($ornek.K2.Count -lt 15){ $ornek.K2.Add($ad) } }
    if(KusurKomsuBaslik $mt){ $k3++; if($ornek.K3.Count -lt 15){ $ornek.K3.Add($ad) } }
  }
  $ofs += $adim
  Write-Host ("  okunan {0}" -f $toplam)
  if($Tavan -gt 0 -and $toplam -ge $Tavan){ break }
  if($sayfa.Count -lt $adim){ break }
}
$mukerrer = @($adSayaci.GetEnumerator() | Where-Object { $_.Value -gt 1 })
foreach($m in ($mukerrer | Sort-Object { -$_.Value } | Select-Object -First 15)){ $ornek.K4.Add("$($m.Key) x$($m.Value)") }

$rapor = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'K1 yapışık dipnot · K2 kesik bent (liste açıp tek bent) · K3 komşu paragrafın başlığı kaydın sonunda · K4 mükerrer kaynak_ad. Ölçüm yalnız DESEN tabanlıdır; iki sütunlu tablo karışması, yanlış paragraf adı ve OCR harf hatası GÖRÜLMEZ.'
  suzgec = $(if($Desen){ $Desen } else { '(tüm ambar)' })
  okunan_kayit = $toplam
  K1_yapisik_dipnot = $k1
  K2_kesik_bent = $k2
  K3_komsu_baslik = $k3
  K4_mukerrer_ad = $mukerrer.Count
  ornekler = [ordered]@{ K1=@($ornek.K1); K2=@($ornek.K2); K3=@($ornek.K3); K4=@($ornek.K4) }
}
$null = RaporYaz -Hedef (Join-Path $depoKok 'veri\ambar-metin-kusuru.json') -Nesne $rapor -Derinlik 5
Write-Host ("`nOKUNAN {0} kayıt · K1 yapışık dipnot {1} · K2 kesik bent {2} · K3 komşu başlık {3} · K4 mükerrer ad {4}" -f $toplam,$k1,$k2,$k3,$mukerrer.Count)
