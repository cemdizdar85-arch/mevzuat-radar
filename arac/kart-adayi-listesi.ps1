#requires -Version 5.1
<#
================================================================================
  KART ADAYI LİSTESİ — plan dosyalarından ders etiketli tekil konu listesi
  (10.09.2026 · Cem: "Aşama 1'i tüm 1.410 konuda koş")

  NE YAPAR: `veri/sinav/konu/*.json` (759 dosya) içindeki konu adlarını toplar,
  dosya adından dersi türetir, tekilleştirir ve motorun `kartoner` komutunun
  okuduğu biçimde `veri/kart-adaylari.json` üretir.

  ⚠️ DOSYA BİÇİMİ: bu JSON'lar DÜZ METİN DİZİSİDİR (["konu1","konu2"]), nesne
  değil. Ders bilgisi İÇERİDE YOK, yalnız dosya adında var. 10.09'da bu yüzden
  ilk üç okuma denemesi "0 konu" döndürdü — dosyayı açıp bakmadan nesne
  varsaymıştım.

  ⚠️ PS 5.1: ConvertFrom-Json üst düzey diziyi TEK nesne döndürebilir;
  `| ForEach-Object { $_ }` ile açılmadan @() sarması satır kaybettirir.
================================================================================
#>
param(
  [string]$Hedef = 'veri\kart-adaylari.json'
)
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

# Dosya adı parçası -> ders adı. Sıra ÖNEMLİ: uzun anahtar önce denenir ki
# 'fmuh' aranırken 'muh' yakalamasın.
$ESLEME = [ordered]@{
  'fmuh'='Finansal Muhasebe'; 'maliyet'='Maliyet Muhasebesi'; 'mta'='Mali Tablolar Analizi'
  'denetim'='Denetim'; 'ticaret'='Ticaret ve Borclar'; 'borclar'='Ticaret ve Borclar'
  'vergi'='Vergi Hukuku'; 'maliye'='Maliye'; 'ekonomi'='Ekonomi'; 'meslek'='Meslek Hukuku'
  'issgk'='Is ve Sosyal Guvenlik'; 'turkce'='Turkce'; 'inkilap'='Ataturk Ilkeleri'
  'muh'='Finansal Muhasebe'; 'tms'='Turkiye Muhasebe Standartlari'
  'tds'='Turkiye Denetim Standartlari'; 'spk'='Sermaye Piyasasi Mevzuati'
  'banka'='Bankacilik'; 'sigorta'='Sigortacilik'; 'surdur'='Surdurulebilirlik'
  'kyfy'='Kurumsal Yonetim'; 'yd'='Yabanci Dil'; 'mat'='Matematik'
  # 10.09: ilk kosuda eksikti - 'hukuk' etiketli 300+ konu <DERSSIZ> dusuyordu.
  'hukuk'='Hukuk'; 'genel'='Genel Kultur'; 'muhden'='Muhasebe Denetimi'
  'kurumsal'='Kurumsal Yonetim'; 'sermaye'='Sermaye Piyasasi Mevzuati'
}
function DersCoz([string]$dosyaAdi){
  $a = $dosyaAdi.ToLowerInvariant()
  foreach($k in $ESLEME.Keys){ if($a -match "(^|-)$k(-|$|\d)"){ return $ESLEME[$k] } }
  return $null
}

$kayit = @{}          # katlanmis konu -> kayit  (tekillestirme)
$dosyaSay = 0; $dersizDosya = New-Object System.Collections.Generic.HashSet[string]

foreach($f in (Get-ChildItem (Join-Path $depoKok 'veri\sinav\konu\*.json'))){
  try{ $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  $dosyaSay++
  $ders = DersCoz $f.BaseName
  if(-not $ders){ [void]$dersizDosya.Add($f.BaseName) }
  foreach($k in @($j | ForEach-Object { $_ })){
    if($k -isnot [string]){ continue }
    $t = $k.Trim()
    if($t.Length -lt 3){ continue }
    $anahtar = $t.ToLowerInvariant()
    if($kayit.ContainsKey($anahtar)){
      $kayit[$anahtar].kez++
      if(-not $kayit[$anahtar].ders -and $ders){ $kayit[$anahtar].ders = $ders }
    } else {
      $kayit[$anahtar] = [pscustomobject]@{ konu=$t; ders=$ders; kez=1 }
    }
  }
}

$liste = @($kayit.Values | Sort-Object @{e='ders'},@{e='konu'})
$dersli   = @($liste | Where-Object { $_.ders }).Count
$dersiz   = $liste.Count - $dersli

Write-Host ("PLAN DOSYASI : {0}" -f $dosyaSay)
Write-Host ("TEKIL KONU   : {0}   (dersi cozulen {1} · cozulemeyen {2})" -f $liste.Count, $dersli, $dersiz)
Write-Host "`nDERS DAGILIMI:"
$liste | Group-Object ders | Sort-Object Count -Descending | ForEach-Object {
  Write-Host ("  {0,-32} {1,5}" -f $(if($_.Name){$_.Name}else{'<DERSSIZ>'}), $_.Count)
}
if($dersizDosya.Count -gt 0){
  Write-Host "`nDERSI COZULEMEYEN DOSYA ADLARI (ilk 10) - esleme tablosuna eklenmeli:"
  $dersizDosya | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
}

$rapor = [ordered]@{
  olcum  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = 'veri/sinav/konu/*.json'
  uyari  = 'Bu liste KART ADAYIDIR. Konu->madde eslesmesi motorun kartoner komutuyla ONERILIR, hakemle DOGRULANIR, Cem orneklemiyle MUHURLENIR.'
  dosya  = $dosyaSay
  tekil_konu = $liste.Count
  konular = $liste
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Hedef) -Nesne $rapor
Write-Host ("`n-> {0}" -f $Hedef)
