# ============================================================================
#  KÖPRÜ DOĞRULUK TARAMASI (02.09.2026)
#
#  NEDEN: 02.09'da 30 soruluk FMuh partisinde hakemler 5 soruyu reddetti ve
#  BEŞİNİN DE kök sebebi aynıydı — konu köprüsü YANLIŞ DAYANAK bağlamıştı:
#    · "ozkaynak hesaplama"  → VUK m.275 İmal edilen emtia
#    · "duran varlik satisi" → VUK m.275 İmal edilen emtia
#    · "yasal yedek akce"    → VUK m.275 İmal edilen emtia   (üçü aynı maddeye!)
#    · "gider tahakkuku"     → VUK m.283 AKTİF geçici hesaplar (doğrusu m.287 PASİF)
#    · "gelir tablosu hesaplari" → TMS 1 sunuluş (doğrusu THP 690/600 kayıt)
#  Örneklemde oran %17. Bu araç aynı hatayı KÖPRÜNÜN TAMAMINDA ölçer.
#
#  ÖLÇÜM (LLM'siz, 0 maliyet — hepsi sayım):
#   A) Dayanak YIĞILMASI  — bir dayanağa kaç FARKLI konu bağlanmış? (yığılma = şüphe)
#   B) Kök EŞLEŞMESİ      — konunun kelime kökleri dayanak künyesinde geçiyor mu?
#   C) Boş dayanak oranı
#   D) Sınav/ders kırılımı ve en çok yığılan dayanaklar
#
#  ÇIKTI: veri/kopru-dogruluk-raporu.json + ekrana özet
#  KURAL: "kök geçmiyor" ≠ "kesin yanlış" — künye kısa olabilir (THP 100 - Kasa).
#         Bu yüzden sonuç ŞÜPHELİ olarak raporlanır, HÜKÜM olarak değil.
#         Kesin hüküm için örneklem hakemden geçirilir (-Ornek ile).
# ============================================================================
param(
  [string]$Sinav='',           # bos = hepsi
  [int]$YiginlanmaEsigi=3,     # bir dayanaga N+ farkli konu baglanmissa yigilma
  [int]$Ornek=0                # >0 ise supheli listeden N ornek ekrana basilir
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
# konu adindan anlamli kokleri cikar (4+ harf, son 2 harf atilir = ek toleransi)
$DURAK=@('icin','gore','ile','veya','olan','olarak','uzere','arasi','hesabi','hesap','kaydi','kayit','yontemi','yontem','islemi','islem','tutari','tutar','orani','oran','sayisi','farki','fark','bedeli','bedel','degeri','deger')
function Kokler([string]$konu){
  $k=Katla $konu
  $parcalar=@($k -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^\d' -and $DURAK -notcontains $_ })
  return @($parcalar | ForEach-Object { if($_.Length -ge 6){ $_.Substring(0,$_.Length-2) } else { $_ } })
}

$tam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar=@($tam)
if($Sinav){ $kayitlar=@($kayitlar | Where-Object { $_.sinav -eq $Sinav }) }
Write-Host "taranan kopru kaydi: $($kayitlar.Count)$(if($Sinav){" ($Sinav)"})"

$bosDayanak=0
$supheli=New-Object System.Collections.Generic.List[object]
$eslesen=0; $olculemeyen=0
$dayanakKonu=New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.HashSet[string]]' ([StringComparer]::Ordinal)

foreach($r in $kayitlar){
  $konu="$($r.konu)"
  $day="$($r.dayanak)"; if(-not $day){ $day="$($r.cikmis_dayanak)" }
  if(-not $day.Trim()){ $bosDayanak++; continue }
  # A) yigilma sayaci
  $dTemiz=($day -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $dayanakKonu.ContainsKey($dTemiz)){ $dayanakKonu[$dTemiz]=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal) }
  [void]$dayanakKonu[$dTemiz].Add($konu)
  # B) kok eslesmesi
  $kk=@(Kokler $konu)
  if($kk.Count -eq 0){ $olculemeyen++; continue }
  $dKat=Katla $dTemiz
  $tut=@($kk | Where-Object { $dKat.Contains($_) }).Count
  if($tut -ge 1){ $eslesen++ }
  else{
    $supheli.Add([pscustomobject]@{ sinav=$r.sinav; ders="$($r.bizim_ders)$($r.arsiv_ders)"; konu=$konu; dayanak=$dTemiz; donem=$r.donem })
  }
}
$olculen=$eslesen+$supheli.Count
$yigilma=@($dayanakKonu.Keys | Where-Object { $dayanakKonu[$_].Count -ge $YiginlanmaEsigi } | Sort-Object { -$dayanakKonu[$_].Count })

# supheli konularin yigilmis dayanaga bagli olani = EN GUCLU sinyal
$cifteSinyal=@($supheli | Where-Object { $dayanakKonu.ContainsKey($_.dayanak) -and $dayanakKonu[$_.dayanak].Count -ge $YiginlanmaEsigi })

$cikti=[ordered]@{
  aciklama="Konu koprusunun dayanak dogrulugu taramasi. 'Supheli' = konunun kelime kokleri dayanak kunyesinde HIC gecmiyor. Bu bir HUKUM DEGIL sinyaldir: kunye kisa olabilir (orn. konu 'kasa sayim farki', dayanak 'THP 100 - Kasa' -> 'sayim' gecmez ama dayanak dogrudur). Kesin hukum icin ornekler hakemden gecirilmelidir. 'Cifte sinyal' = hem kok tutmuyor HEM de ayni dayanaga cok sayida farkli konu baglanmis - en guclu yanlis-eslesme adayi."
  kapsam=$(if($Sinav){$Sinav}else{'tum sinavlar'})
  taranan=$kayitlar.Count
  bos_dayanak=$bosDayanak
  olculen=$olculen
  kok_tutan=$eslesen
  supheli=$supheli.Count
  supheli_yuzde=$(if($olculen){[math]::Round(100*$supheli.Count/$olculen,1)}else{0})
  cifte_sinyal=$cifteSinyal.Count
  yigilan_dayanak_sayisi=$yigilma.Count
  en_cok_yigilan=@($yigilma | Select-Object -First 15 | ForEach-Object { "$_ -> $($dayanakKonu[$_].Count) farkli konu" })
  cifte_sinyal_ornekleri=@($cifteSinyal | Sort-Object { -[int]$_.donem } | Select-Object -First 40 | ForEach-Object { "[$($_.sinav)|$($_.donem)d] $($_.konu)  =>  $($_.dayanak)" })
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\kopru-dogruluk-raporu.json') -Nesne $cikti

Write-Host ""
Write-Host "=== KOPRU DOGRULUK ==="
Write-Host ("  bos dayanak    : {0}" -f $bosDayanak)
Write-Host ("  olculen        : {0}" -f $olculen)
Write-Host ("  kok tutan      : {0}" -f $eslesen)
Write-Host ("  SUPHELI        : {0}  (%{1})" -f $supheli.Count,$cikti.supheli_yuzde)
Write-Host ("  CIFTE SINYAL   : {0}  (kok tutmuyor + dayanak yigilmis)" -f $cifteSinyal.Count)
Write-Host ("  yigilan dayanak: {0} adet ({1}+ konu bagli)" -f $yigilma.Count,$YiginlanmaEsigi)
Write-Host ""
Write-Host "--- EN COK YIGILAN DAYANAKLAR ---"
foreach($d in ($yigilma | Select-Object -First 12)){ Write-Host ("  {0,4} konu <- {1}" -f $dayanakKonu[$d].Count,$d) }
if($Ornek -gt 0){
  Write-Host ""
  Write-Host "--- CIFTE SINYAL ORNEKLERI (en cok cikan konulardan) ---"
  foreach($s in @($cifteSinyal | Sort-Object { -[int]$_.donem } | Select-Object -First $Ornek)){
    Write-Host ("  [{0}|{1}d] {2}" -f $s.sinav,$s.donem,$s.konu)
    Write-Host ("        => {0}" -f $s.dayanak)
  }
}
