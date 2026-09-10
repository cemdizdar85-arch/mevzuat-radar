#requires -Version 5.1
<#
================================================================================
  PANEL BÜTÜNLÜĞÜ — cevap kalıbı gerçekten dolu mu? (10.09.2026)
  Cem: "her soruya ayrı cevap vs vs kurallarımız var, ona göre yapmayacak mısın"

  NE ÖLÇER: `STANDART-CEVAP-KALIBI.md` bölüm 8'deki VERİ SÖZLEŞMESİ ile
  fabrikadaki gerçeği karşılaştırır. Aktarım kapıları madde 1 çekirdeğini
  (5 şık + açıklama + HAP + tuzak adı) denetliyordu; madde 2-3-4 hiç
  denetlenmiyordu. 1.835 soru "9 kapıdan geçti" diye raporlandı ama kalıbın
  tamamından değil, yalnız çekirdeğinden geçmişti.

  ⚠️ ZORUNLULUK SORU TİPİNE GÖRE DEĞİŞİR (Kalıp Sözleşmesi madde 2):
     HESAPLI soru : cozum_tablo + verilenler + adimlar  ZORUNLU
     SÖZEL  soru : sema ZORUNLU, oynatıcı (adimlar) YOK
  Bu yüzden tek bir "tam panel" ölçütü yanlış olur - sözel soruyu çözüm
  tablosu yokluğundan düşürmek, olmayan bir kusuru raporlamaktır.

  TİP TESPİTİ: soruda hesap isteniyor mu? (tutar/oran deseni + "kaç TL",
  "kaç gün", "hesaplayınız" gibi) VE cozum_tablo/adimlar/verilenler'den biri
  doluysa HESAPLI sayılır. Kararsızsa SÖZEL kabul edilir - katı ölçüt
  şişirir, gevşek ölçüt uydurur; burada gevşek taraf daha az zararlı çünkü
  sözel ölçütü daha az alan istiyor.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/panel-butunluk.ps1
================================================================================
#>
param([string]$Hedef = 'veri\panel-butunluk.json')
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

function Dolu($v){
  if($null -eq $v){ return $false }
  if($v -is [string]){ return $v.Trim().Length -gt 0 }
  if($v -is [array]){ return @($v).Count -gt 0 }
  return (@($v.PSObject.Properties).Count -gt 0)
}

$kapi = Get-Content (Join-Path $depoKok 'veri\aktarim-kapilari.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$gecti = @($kapi.kovalar.gecti | ForEach-Object { $_ })
Write-Host ("Madde 1 cekirdegini gecen soru: {0}" -f $gecti.Count)

$onbellek = @{}
$say = [ordered]@{
  toplam=0; hesapli=0; sozel=0
  tam_panel=0; eksik_panel=0
  e_sade=0; e_kavram=0; e_cozum_tablo=0; e_verilenler=0; e_adimlar=0; e_sema=0; e_ikiz=0
}
$kova = @{ tam=New-Object System.Collections.ArrayList; eksik=New-Object System.Collections.ArrayList }

foreach($s in $gecti){
  if(-not $onbellek.ContainsKey($s.parti)){
    $onbellek[$s.parti] = Get-Content (Join-Path $depoKok ("veri\fabrika\kalip-parti-{0}.json" -f $s.parti)) -Raw -Encoding UTF8 | ConvertFrom-Json
  }
  $v = $onbellek[$s.parti].($s.id)
  if(-not $v){ continue }
  $say.toplam++

  # --- TIP ---
  $metin = "$($v.soru)"
  $hesapIzi = ($metin -match 'ka[çc]\s+(TL|gün|lira|adet)' -or $metin -match 'hesapla' -or $metin -match '\b\d{1,3}(\.\d{3})+\b')
  $veriIzi  = (Dolu $v.cozum_tablo) -or (Dolu $v.adimlar) -or (Dolu $v.verilenler)
  $hesapli  = ($hesapIzi -and $veriIzi)
  if($hesapli){ $say.hesapli++ } else { $say.sozel++ }

  $eksik = New-Object System.Collections.ArrayList
  # --- HER SORUDA ZORUNLU (madde 1 + veri sozlesmesi) ---
  if(-not (Dolu $v.sade)){ [void]$eksik.Add('sade'); $say.e_sade++ }
  $kavramVar = ($v.sade -and $v.sade.PSObject.Properties['kavramlar'] -and (Dolu $v.sade.kavramlar))
  if(-not $kavramVar){ [void]$eksik.Add('kavramlar'); $say.e_kavram++ }

  # --- TIPE GORE (madde 2) ---
  if($hesapli){
    if(-not (Dolu $v.cozum_tablo)){ [void]$eksik.Add('cozum_tablo'); $say.e_cozum_tablo++ }
    if(-not (Dolu $v.verilenler)) { [void]$eksik.Add('verilenler');  $say.e_verilenler++ }
    if(-not (Dolu $v.adimlar))    { [void]$eksik.Add('adimlar');     $say.e_adimlar++ }
  } else {
    if(-not (Dolu $v.sema))       { [void]$eksik.Add('sema');        $say.e_sema++ }
  }

  $kayit = [pscustomobject]@{ parti=$s.parti; id=$s.id; ders=$s.ders; konu=$s.konu; tip=$(if($hesapli){'hesapli'}else{'sozel'}); eksik=($eksik -join ',') }
  if($eksik.Count -eq 0){ $say.tam_panel++; [void]$kova.tam.Add($kayit) }
  else { $say.eksik_panel++; [void]$kova.eksik.Add($kayit) }
}

Write-Host ""
Write-Host ("SORU TIPI     : hesapli {0} · sozel {1}" -f $say.hesapli, $say.sozel)
Write-Host ""
Write-Host ("  TAM PANEL   {0,5}" -f $say.tam_panel) -ForegroundColor Green
Write-Host ("  EKSIK PANEL {0,5}" -f $say.eksik_panel) -ForegroundColor Red
Write-Host ""
Write-Host "EKSIK ALAN KIRILIMI:"
Write-Host ("  sade (Sade Dogrusu)      {0,5}" -f $say.e_sade)
Write-Host ("  kavramlar                {0,5}" -f $say.e_kavram)
Write-Host ("  cozum_tablo (hesaplida)  {0,5}" -f $say.e_cozum_tablo)
Write-Host ("  verilenler  (hesaplida)  {0,5}" -f $say.e_verilenler)
Write-Host ("  adimlar     (hesaplida)  {0,5}" -f $say.e_adimlar)
Write-Host ("  sema        (sozelde)    {0,5}" -f $say.e_sema)

$rapor = [ordered]@{
  olcum  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = 'STANDART-CEVAP-KALIBI.md bolum 8 (veri sozlesmesi) x veri/fabrika/kalip-parti-*.json'
  kural  = 'Zorunluluk soru tipine gore degisir: HESAPLI -> cozum_tablo+verilenler+adimlar · SOZEL -> sema. Her ikisinde sade + kavramlar zorunlu.'
  sayac  = $say
  tam_liste   = @($kova.tam)
  eksik_liste = @($kova.eksik)
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Hedef) -Nesne $rapor
Write-Host ("`n-> {0}" -f $Hedef)
