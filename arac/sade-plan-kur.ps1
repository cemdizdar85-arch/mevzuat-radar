#requires -Version 5.1
<#
================================================================================
  SADE PLAN KURUCU  (11.09.2026, Cem "hasadi baslat")

  NE YAPAR: hasat listesini uretir -> veri/_sade-plan.json
  Liste = fabrikada TUM kapilardan gecmis, havuzda OLMAYAN, `sade`si eksik sorular.

  ⛔ NIYE AYRI BETIK: 11.09'da bu listeyi elle kurdum ve `ders` alanini KOYMADIM.
     sade-tamamla.ps1 de uretici ye '-DersRegex .' geciyordu; KAPI-HG ayni gun
     `hesap_uyum`u zorunlu kilinca hakem yeniden kosar oldu ve KAPI-DR turu
     BASTAN SONA durdurdu (93 partinin 93'u dustu, sade 0/…). Bedel 0 gitti ama
     bir dahaki sefere elle kurulmasin diye plan artik BURADA uretilir ve
     `ders` alani ZORUNLU doldurulur.

  DERS NEREDEN: parti etiketinden cozulur (DERS_ANAHTARI). Cozulemeyen etiket
  plana ALINMAZ ve ekrana yazilir - sessizce '.' ile gecistirilmez.

  BEDEL 0 - yalniz yerel dosya okur.
================================================================================
#>
param(
  [string]$Cikti = 'veri\_sade-plan.json'
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

# --- OLCUM KAPILARI (11.09, Cem "olcum araclarina oz-sinav ekle") -------------
# Bu betik OLCUM yapar; olcum aracinin kendisi bozuksa cikan rakam yanlis KARAR
# urettirir (11.09'da dort kez oldu). Oz-sinav kirmizi donerse HIC olcmez.
. (Join-Path $here 'olcum-kapilari.ps1')
$ok_kusur=Test-OlcumKapilari -Sessiz
if((Dizi $ok_kusur).Count){
  Write-Host '⛔ OLCUM KAPILARI KIRMIZI - bu olcume guvenilmez:' -ForegroundColor Red
  foreach($h in (Dizi $ok_kusur)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'olcum kapilari oz-sinavi dustu'
}


# Ders adlari ders-profili.json'daki RESMI yazimla dondurulur (hakem dersi buradan tanir).
$prof=Get-Content (Join-Path $depoKok 'veri\ders-profili.json') -Raw -Encoding UTF8|ConvertFrom-Json
$resmi=@{}
foreach($p in $prof.sinavlar.'STAJA BAŞLAMA (SGS)'.PSObject.Properties){ $resmi[$p.Name]=$p.Name }
function Resmi([string]$ad){ if($resmi.ContainsKey($ad)){ return $resmi[$ad] }; return $ad }

$DERS_ANAHTARI=[ordered]@{
  'fmuh'='Finansal Muhasebe'; 'denetim'='Denetim'; 'maliyet'='Maliyet Muhasebesi'
  'mta'='Mali Tablolar Analizi'; 'ticaret'='Ticaret Hukuku'; 'borclar'='Borclar Hukuku'
  'vergi'='Vergi Hukuku'; 'meslek'='Meslek Hukuku'; 'issgk'='Is ve Sosyal Guvenlik Hukuku'
  'mat'='Matematik'; 'turkce'='Turkce'; 'yd'='Yabanci Dil'; 'ydil'='Yabanci Dil'
  'yabancidil'='Yabanci Dil'; 'ekonomi'='Ekonomi'; 'maliye'='Maliye'
  'inkilap'='Ataturk Ilkeleri ve Inkilap Tarihi'; 'ataturk'='Ataturk Ilkeleri ve Inkilap Tarihi'
}
function DersCoz([string]$et){
  foreach($k in $DERS_ANAHTARI.Keys){ if($et -match "(^|-)$k(-|$)"){ return (Resmi $DERS_ANAHTARI[$k]) } }
  return ''
}

# ⚠ PS 5.1: `@(Get-Content|ConvertFrom-Json)` diziyi TEK ogeye sarar. Once degiskene.
$secimHam=Get-Content (Join-Path $depoKok 'veri\sinav\kaydir-secim\sgs-650-secim.json') -Raw -Encoding UTF8|ConvertFrom-Json
$hav=@{}; foreach($r in @($secimHam)){ $hav["$($r.etiket)|$($r.id)"]=$true }

$plan=New-Object System.Collections.Generic.List[object]
$top=0; $dersiz=@{}; $hakemTaze=0
foreach($x in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json'|Sort-Object Name)){
  $et=($x.BaseName -replace '^kalip-parti-','')
  $c=$null; try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  $id=New-Object System.Collections.Generic.List[string]; $tazeBu=0
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    if(-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')){ continue }
    if("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ continue }
    if(-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $ok=$true; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $ok=$false } }
    if(-not $ok){ continue }
    if($hav.ContainsKey("$et|$($p.Name)")){ continue }          # zaten yayinda
    if($v.sade -and $v.sade.dogru){ continue }                   # sade zaten var
    $id.Add($p.Name)
    if(-not $v.hakem.PSObject.Properties['hesap_uyum']){ $tazeBu++ }
  }
  if(-not $id.Count){ continue }
  $ders=DersCoz $et
  if(-not $ders){ $dersiz[$et]=$id.Count; continue }             # dersi cozulemeyen plana GIRMEZ
  $plan.Add([ordered]@{ etiket=$et; ders=$ders; adet=$id.Count; idler=($id -join ',') })
  $top+=$id.Count; $hakemTaze+=$tazeBu
}

$hedef=if([IO.Path]::IsPathRooted($Cikti)){ $Cikti } else { Join-Path $depoKok $Cikti }
[IO.File]::WriteAllText($hedef,($plan|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))

# Bedel: hakem tazelemesi gerekenlerde 2 cagri (hakem+sade) 0,019 USD;
# hakemi tam olanlarda yalniz sade 0,009 USD. Ikisi de 11.09 provasindan OLCULU.
$usd = ($hakemTaze*0.019) + (($top-$hakemTaze)*0.009)
Write-Host ("PLAN: {0} parti · {1} soru" -f $plan.Count,$top) -ForegroundColor Cyan
Write-Host ("  hakem tazelenecek (hesap_uyum yok): {0}" -f $hakemTaze) -ForegroundColor Yellow
Write-Host ("  yalniz sade                       : {0}" -f ($top-$hakemTaze))
Write-Host ("  BEDEL: {0:N2} USD ≈ {1:N0} TL" -f $usd,($usd*41)) -ForegroundColor Green
if($dersiz.Count){
  Write-Host "`nDERSI COZULEMEDIGI ICIN PLANA ALINMAYAN:" -ForegroundColor Yellow
  $dersiz.GetEnumerator()|Sort-Object Value -Descending|ForEach-Object{ Write-Host ("  {0,-34} {1,4} soru" -f $_.Key,$_.Value) }
}
Write-Host "`n-> $hedef"
