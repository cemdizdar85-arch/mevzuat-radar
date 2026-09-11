#requires -Version 5.1
<#
================================================================================
  KONU ETIKETI ONARIMI  (11.09.2026, Cem "siralama bunu yap" - 1. is)

  GIRDI : veri/_etiket-secim.json  (arac/konu-etiket-sec.ps1 ciktisi, ~9 TL)
  CIKTI : veri/fabrika/kalip-parti-*.json icindeki `konu` alani
  BEDEL : 0 - model cagrilmaz.

  ⛔ BU BETIK BIR KEZ YENIDEN YAZILDI. ILK SURUMU YANLISTI, SEBEBI:
  Girdisi ikinci gorus turunun SERBEST METIN onerileriydi. Uygulanmadan once
  olculdu: onerilen 68 etiketin 66'si 1.409 konuluk mufredat listesinde YOKTU.
  Uygulansaydi "etiket soruyu anlatiyor" duzelir, ama "etiket bir mufredat
  konusuna denk geliyor" KIRILIRDI - o 66 soru kapsama olcumunden duserdi.
  Artik girdi, modelin MUFREDATTAN SECTIGI etikettir (0 uydurma olculdu).

  NE DEGISTIRIR : yalniz `konu` alani
  NE DEGISTIRMEZ: soru, siklar, dogru, aciklama, adimlar, sade, hakem karari,
                  ve DERS alani (ders hukmu hakemin ders_uyum kapisindadir)

  GERI ALINABILIR: her degisiklik veri/_etiket-onarim-kutugu.json'a
  (eski ad, yeni ad, gerekce) yazilir.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-etiket-onar.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-etiket-onar.ps1 -Yaz
================================================================================
#>
param([switch]$Yaz)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

$secHam = Get-Content (Join-Path $depoKok 'veri\_etiket-secim.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$sat = @($secHam.satirlar)
$degisecek = @($sat | Where-Object { "$($_.durum)" -eq 'SECILDI' -and "$($_.yeni)".Trim() -and "$($_.yeni)" -ne "$($_.eski)" })
$ayni      = @($sat | Where-Object { "$($_.durum)" -eq 'SECILDI' -and "$($_.yeni)" -eq "$($_.eski)" })
$menudeYok = @($sat | Where-Object { "$($_.durum)" -eq 'MENUDE-YOK' })

Write-Host ("SECIM DOSYASI: {0} soru · degisecek {1} · ayni kalan {2} · mufredatta yok {3}" -f
  $sat.Count,$degisecek.Count,$ayni.Count,$menudeYok.Count) -ForegroundColor Cyan
Write-Host "`nDERS BAZLI DEGISIKLIK:"
$degisecek | Group-Object ders | Sort-Object Count -Descending | ForEach-Object { Write-Host ("  {0,-28} {1,3}" -f $_.Name,$_.Count) }

Write-Host "`nDEGISIKLIKLER:"
$degisecek | ForEach-Object {
  Write-Host ("  {0,-22} {1,-7}" -f $_.etiket,$_.id) -NoNewline
  Write-Host (" '{0}'" -f $_.eski) -ForegroundColor DarkYellow -NoNewline
  Write-Host " -> " -NoNewline
  Write-Host ("'{0}'" -f $_.yeni) -ForegroundColor Green
}
if($menudeYok.Count){
  Write-Host "`nMUFREDATTA KARSILIGI YOK (DOKUNULMAYACAK - mufredata konu eklemek AYRI karar):" -ForegroundColor Yellow
  $menudeYok | ForEach-Object { Write-Host ("  {0,-22} {1,-7} '{2}' ~> onerilen yeni konu: '{3}'" -f $_.etiket,$_.id,$_.eski,$_.eksik_konu) }
}

if(-not $Yaz){ Write-Host "`nGOSTERIM - dosyaya dokunulmadi. Uygulamak icin: -Yaz" -ForegroundColor Yellow; return }

$onb=@{}; $kutuk=New-Object System.Collections.Generic.List[object]; $atlanan=0
foreach($a in $degisecek){
  $et="$($a.etiket)"
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
  if(-not (Test-Path $f)){ $atlanan++; continue }
  if(-not $onb.ContainsKey($et)){ $onb[$et]=Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json }
  $v=$onb[$et].($a.id)
  if(-not $v){ $atlanan++; continue }
  # Onbellekteki ad, secim aninda gorulen addan farkliysa DOKUNMA: arada
  # degismis olabilir ve korlemesine yazmak baska bir onarimi ezer.
  if("$($v.konu)" -ne "$($a.eski)"){
    Write-Host ("  ATLANDI {0}/{1}: onbellek '{2}', secim '{3}'" -f $et,$a.id,$v.konu,$a.eski) -ForegroundColor Yellow
    $atlanan++; continue
  }
  $v | Add-Member -NotePropertyName konu -NotePropertyValue "$($a.yeni)" -Force
  $kutuk.Add([pscustomobject]@{ etiket=$et; id=$a.id; ders=$a.ders; eski="$($a.eski)"; yeni="$($a.yeni)"; gerekce="$($a.gerekce)" })
}
foreach($et in $onb.Keys){
  if(-not @($kutuk | Where-Object { $_.etiket -eq $et }).Count){ continue }
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
  [IO.File]::WriteAllText($f,[string](ConvertTo-Json -InputObject $onb[$et] -Depth 12),[Text.UTF8Encoding]::new($false))
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\_etiket-onarim-kutugu.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak='veri/_etiket-secim.json (mufredat menusuyle secim, 0 uydurma)'
  kural='Yalniz `konu` degistirildi. DERS alanina dokunulmadi. Mufredatta karsiligi olmayan 12 soru DISARIDA birakildi.'
  degisen=$kutuk.Count; atlanan=$atlanan; mufredatta_yok=$menudeYok.Count
  satirlar=$kutuk
})
Write-Host ("`nONARILDI: {0} etiket · atlanan {1}" -f $kutuk.Count,$atlanan) -ForegroundColor Green
Write-Host "-> veri/_etiket-onarim-kutugu.json (geri alma kaydi)"
Write-Host "SIRADAKI: arac/sgs-650-bas.ps1 (sayfalar yeni etiketlerle yeniden basilir, bedel 0)"
