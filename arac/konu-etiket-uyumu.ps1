#requires -Version 5.1
<#
================================================================================
  KONU ETIKETI UYUM OLCUMU  (11.09.2026, Cem "etiket uyumunu 648 tamaminda olc")

  NIYE: 10 soruluk muhur orneklemini yazarken 3 uyusmazlik gorundu (Cem'in
  3. kurali "Ders ve Konu Eslesmesi - Hata Yok"):
    #3 etiket 'satis dongusu kontrol testi' · soru VUK m.231 fatura nizami
    #6 etiket 'haksiz rekabet davalari'     · soru limited sirket pay devri
    #7 etiket 'bds 706 dikkat cekilen...'   · sorunun cevabi BDS 570
  Etiket mufredat kapsama olcumunu besliyor ("su konuda kac sorumuz var"),
  bozuk etiket kor nokta uretir.

  ⛔ BU OLCUM SOZCUK DUZEYINDEDIR, ANLAM DUZEYINDE DEGIL. BEDEL 0, model
  cagrilmaz. Ne gorur / ne goremez:
    GORUR   : etiket kelimeleri soru metninde HIC gecmiyorsa (ornek #6)
    GOREMEZ : etiket dogru kelimeleri tasiyip yanlis konuyu adlandiriyorsa
    YARI    : etiket kelimesi YALNIZ SIKLARDA geciyorsa - ornek #7'de '706'
              yalnizca celdirici sikta var, soru kokunde yok. Bunu ayri
              kovaya ('YALNIZ-SIKTA') koyuyoruz; guclu suphe isaretidir.
  Yani cikan sayi "bozuk etiket sayisi" DEGIL, "incelenmesi gereken etiket
  sayisi"dir. Kesin hukum ancak hakem turuyla (bedelli) verilir.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-etiket-uyumu.ps1
================================================================================
#>
param([string]$Secim = 'veri\sinav\kaydir-secim\sgs-650-secim.json')
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
# Etikette gecen ama ayirt etmeyen kelimeler. Bunlar sayima girerse her etiket
# "uyumlu" cikar (ornek: 'hesaplama', 'kaydi', 'islemleri' neredeyse her soruda var).
$DOLGU = @('ile','icin','veya','bir','olan','gibi','uzerine','hesabi','hesap','kaydi','kayit',
           'islemi','islemleri','yontemi','yontemleri','tutari','orani','oran','genel','ozel',
           'esaslari','hukumleri','turleri','sekli','sartlari','unsurlari','kavrami','tanimi',
           'hesaplama','hesaplanmasi','belirlenmesi','degerlendirmesi','uygulamasi','analizi',
           'sonrasi','oncesi','arasi','dahil','haric') | ForEach-Object { $_ }

$ham = Get-Content (Join-Path $depoKok $Secim) -Raw -Encoding UTF8 | ConvertFrom-Json
$sec = @($ham)
Write-Host ("OLCULEN: {0} soru" -f $sec.Count) -ForegroundColor Cyan

$onb=@{}
$satirlar = New-Object System.Collections.Generic.List[object]
foreach($r in $sec){
  $et="$($r.etiket)"
  if(-not $onb.ContainsKey($et)){
    $cf=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
    $onb[$et] = if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
  }
  $v=$onb[$et]; if($v){ $v=$v.($r.id) }
  if(-not $v -or -not $v.soru){ continue }

  $kokMetin = Katla "$($v.soru)"                       # yalniz soru koku
  $sikMetin = Katla ((@('A','B','C','D','E') | ForEach-Object { "$($v.siklar.$_)" }) -join ' ')
  $acikMetin = Katla ((@('A','B','C','D','E') | ForEach-Object { "$($v.aciklama.$_)" }) -join ' ')
  $konuMetin = Katla "$($v.konu)"                      # onbellekteki konu (secim dosyasindakiyle ayni olmali)
  $tamMetin = "$kokMetin $sikMetin $acikMetin"

  $kelimeler = @([regex]::Matches((Katla "$($r.konu)"),'[a-z0-9]{3,}') | ForEach-Object { $_.Value } |
                 Where-Object { $DOLGU -notcontains $_ } | Select-Object -Unique)
  if(-not $kelimeler.Count){ continue }

  $kokta=0; $sadeceSik=0; $hic=0; $eksikler=@(); $sikta=@()
  foreach($k in $kelimeler){
    if($kokMetin.Contains($k)){ $kokta++ }
    elseif($tamMetin.Contains($k)){ $sadeceSik++; $sikta+=$k }
    else { $hic++; $eksikler+=$k }
  }
  $n=$kelimeler.Count
  $kova =
    if($kokta -eq $n){ 'TAM' }
    elseif($hic -eq $n){ 'HIC-GECMIYOR' }
    elseif($kokta -eq 0 -and $sadeceSik -gt 0){ 'YALNIZ-SIKTA' }
    elseif(($kokta/$n) -ge 0.5){ 'GUCLU' }
    else { 'ZAYIF' }

  $satirlar.Add([pscustomobject]@{
    ders=$r.ders; etiket=$et; id=$r.id; konu="$($r.konu)"
    kelime=$n; kokta=$kokta; yalnizSik=$sadeceSik; hic=$hic; kova=$kova
    eksik=($eksikler -join ','); sikKelime=($sikta -join ',')
    konuSapmasi=$(if($konuMetin -and $konuMetin -ne (Katla "$($r.konu)")){ "onbellek='$($v.konu)'" } else { '' })
  })
}

Write-Host ("DEGERLENDIRILEN: {0} soru`n" -f $satirlar.Count)
$satirlar | Group-Object kova | Sort-Object @{e={switch($_.Name){'TAM'{1}'GUCLU'{2}'ZAYIF'{3}'YALNIZ-SIKTA'{4}'HIC-GECMIYOR'{5}}}} |
  ForEach-Object { Write-Host ("  {0,-14} {1,4}  (%{2:N1})" -f $_.Name,$_.Count,(100*$_.Count/$satirlar.Count)) }

$supheli = @($satirlar | Where-Object { $_.kova -in @('HIC-GECMIYOR','YALNIZ-SIKTA','ZAYIF') })
Write-Host ("`nINCELENMESI GEREKEN: {0} soru (%{1:N1})" -f $supheli.Count,(100*$supheli.Count/$satirlar.Count)) -ForegroundColor Yellow
Write-Host "`nDERS BAZLI:"
$satirlar | Group-Object ders | Sort-Object Count -Descending | ForEach-Object {
  $s=@($_.Group | Where-Object { $_.kova -in @('HIC-GECMIYOR','YALNIZ-SIKTA','ZAYIF') }).Count
  Write-Host ("  {0,-30} {1,4} soru · supheli {2,3} (%{3:N0})" -f $_.Name,$_.Count,$s,(100*$s/$_.Count))
}
Write-Host "`nEN AGIR 20 (etiket kelimeleri soruda HIC gecmiyor):"
$satirlar | Where-Object { $_.kova -eq 'HIC-GECMIYOR' } | Select-Object -First 20 | ForEach-Object {
  Write-Host ("  {0,-24} {1,-8} [{2}]  eksik: {3}" -f $_.etiket,$_.id,$_.konu,$_.eksik)
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\konu-etiket-uyumu.json') -Nesne ([ordered]@{
  olcum   = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak  = "$Secim + veri/fabrika/kalip-parti-*.json"
  yontem  = 'SOZCUK duzeyi: konu etiketinin ayirt edici kelimeleri (>=3 harf, dolgu listesi disi) soru kokunde / siklarda / aciklamada araniyor. ANLAM duzeyi DEGIL - model cagrilmaz, bedel 0.'
  uyari   = 'Cikan sayi "bozuk etiket" degil, "incelenmesi gereken etiket"tir. Etiket dogru kelimeleri tasiyip yanlis konuyu adlandiriyorsa bu olcum GOREMEZ.'
  dolgu_kelimeler = $DOLGU
  toplam  = $satirlar.Count
  kovalar = (@($satirlar | Group-Object kova | ForEach-Object { @{ kova=$_.Name; adet=$_.Count } }))
  supheli = $supheli.Count
  satirlar = $satirlar
})
Write-Host "`n-> veri/konu-etiket-uyumu.json"
