# ============================================================================
#  FEDA KÜNYE TAMAMLAYICI (31.08.2026 — Cem: "dört dosyada da sınav/ders yok")
#  Mühürlü feda örnekleri kendi kimliğini taşımıyordu: `sinav` ve `ders` alanı
#  yoktu. Ana sayfaya konunca görünür oldu; eksik EKRANDA değil VERİDEDİR.
#  Alansız dosya, her kullanımda soruyu yeniden ölçmeyi zorunlu kılar.
#
#  Bu betik alanı UYDURMAZ: her feda dosyasının SORU metnini
#  `veri/fabrika/sik90-sonuc.jsonl` içindeki üretim çıktısıyla birebir eşler,
#  eşleşen `custom_id`nin künyesini `veri/fabrika/sik90-plan.json`dan alır.
#  Eşleşme yoksa dosyaya DOKUNMAZ — "ölçemediğine kusur deme".
#
#  Alan adları vitrin bankasının (veri/soru-bankasi.json) şemasıyla birebir:
#  sinav · ders · konu. Ek olarak kaynak_id yazılır ki soru bir daha aranmasın.
#
#  DERSLER (bu makinede iki kez yandık):
#   - PS 5.1: @($x | ConvertFrom-Json) diziyi AÇMAZ — önce ata, sonra @() ile sar.
#   - Türkçe içeren .ps1 BOM'lu UTF-8 kaydedilir, yoksa ayrıştırılamaz.
#  Kuru prova varsayılandır; yazmak için -Uygula ver.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$repoKok=Split-Path -Parent $here
$SONUC=Join-Path $repoKok 'veri\fabrika\sik90-sonuc.jsonl'
$PLAN =Join-Path $repoKok 'veri\fabrika\sik90-plan.json'

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null
  try{ $c=$tt|ConvertFrom-Json }catch{
    $son=$tt.LastIndexOf('}')
    if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} }
  }
  return $c
}

# --- 1) kaynak soru metinleri: custom_id -> soru ---
if(-not (Test-Path $SONUC)){ throw "kaynak sonuc dosyasi yok: $SONUC" }
$soruIdx=@{}
foreach($sat in (Get-Content $SONUC -Encoding UTF8)){
  if(-not "$sat".Trim()){ continue }
  $r=$sat|ConvertFrom-Json
  $blok=@($r.result.message.content)|Where-Object { $_.type -eq 'text' }|Select-Object -Last 1
  if(-not $blok){ continue }
  $c=Coz $blok.text
  if($c -and $c.soru){ $soruIdx["$($r.custom_id)"]="$($c.soru)".Trim() }
}
Write-Host "kaynakta cozulen soru: $($soruIdx.Count)"

# --- 2) plan kunyesi: custom_id -> sinav/ders/konu ---
if(-not (Test-Path $PLAN)){ throw "plan dosyasi yok: $PLAN" }
$planHam=Get-Content $PLAN -Raw -Encoding UTF8 | ConvertFrom-Json
$planIdx=@{}
foreach($p in @($planHam)){ $planIdx["$($p.custom_id)"]=$p }
Write-Host "plan kunyesi: $($planIdx.Count)"

# --- 3) feda dosyalari ---
$dosyalar=@(Get-ChildItem (Join-Path $repoKok 'veri') -Filter 'feda-ornek-*.json' | Sort-Object Name)
if($dosyalar.Count -eq 0){ throw 'feda-ornek-*.json bulunamadi' }

$yazilan=0; $atlanan=0; $zatenTam=0
foreach($d in $dosyalar){
  $veri=Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  if(-not $veri.soru){ Write-Host "  ! $($d.Name): soru alani yok - atlandi"; $atlanan++; continue }

  $var=$veri.PSObject.Properties['sinav'] -and $veri.PSObject.Properties['ders']
  if($var){ Write-Host "  = $($d.Name): kunye zaten var (sinav=$($veri.sinav) ders=$($veri.ders))"; $zatenTam++; continue }

  $soru="$($veri.soru)".Trim()
  $kid=$null
  foreach($k in $soruIdx.Keys){ if($soruIdx[$k] -eq $soru){ $kid=$k; break } }
  if(-not $kid){ Write-Host "  ! $($d.Name): kaynak soru ESLESMEDI - dokunulmadi"; $atlanan++; continue }
  $p=$planIdx[$kid]
  if(-not $p -or -not $p.sinav -or -not $p.ders){ Write-Host "  ! $($d.Name): plan kunyesi eksik ($kid) - dokunulmadi"; $atlanan++; continue }

  # eski alanlarin birebir kopyasi (yaz -> geri oku -> karsilastir icin)
  $once=@{}
  foreach($pr in $veri.PSObject.Properties){ $once[$pr.Name]=(ConvertTo-Json -InputObject $pr.Value -Depth 9 -Compress) }

  # kunye kaynak_not'tan HEMEN SONRA, geri kalan alanlar OZGUN SIRASIYLA
  $yeni=[ordered]@{}
  if($veri.PSObject.Properties['kaynak_not']){ $yeni['kaynak_not']=$veri.kaynak_not }
  $yeni['kaynak_id']=$kid
  $yeni['sinav']="$($p.sinav)"
  $yeni['ders']="$($p.ders)"
  $yeni['konu']="$($p.konu)"
  foreach($pr in $veri.PSObject.Properties){
    if($yeni.Contains($pr.Name)){ continue }
    $yeni[$pr.Name]=$pr.Value
  }

  Write-Host "  + $($d.Name): $kid -> sinav=$($p.sinav) | ders=$($p.ders) | konu=$($p.konu)"
  if(-not $Uygula){ continue }

  # feda dosyalari BOM'suz UTF-8 yazilir (ureticiyle ayni)
  [IO.File]::WriteAllText($d.FullName,(ConvertTo-Json -InputObject $yeni -Depth 9),[Text.UTF8Encoding]::new($false))

  # --- geri oku, karsilastir: tek bir eski alan bile degismis olmayacak ---
  $geri=Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($ad in $once.Keys){
    if(-not $geri.PSObject.Properties[$ad]){ throw "GERI OKUMA: $($d.Name) icinde '$ad' KAYBOLDU" }
    $simdi=ConvertTo-Json -InputObject $geri.$ad -Depth 9 -Compress
    if($simdi -ne $once[$ad]){ throw "GERI OKUMA: $($d.Name) icinde '$ad' DEGISTI" }
  }
  if("$($geri.sinav)" -ne "$($p.sinav)" -or "$($geri.ders)" -ne "$($p.ders)"){ throw "GERI OKUMA: $($d.Name) kunyesi yazilamadi" }
  $yazilan++
}

Write-Host ''
if($Uygula){ Write-Host "YAZILDI: $yazilan · zaten tam: $zatenTam · atlanan: $atlanan" }
else{ Write-Host "KURU PROVA (yazilmadi) · yazilacak: $($dosyalar.Count-$zatenTam-$atlanan) · zaten tam: $zatenTam · atlanan: $atlanan"; Write-Host 'Yazmak icin: -Uygula' }
