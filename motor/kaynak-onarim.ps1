# ============================================================================
#  KAYNAK ONARIMI (02.08.2026 — Cem: "kaynak onarimi yap")
#
#  BULGU: Hakem 1. partisinde 6.549 soruya "destek=yetersiz" dendi. Ornekler
#  okundu: sorular MUHASEBE KAYDI / HESAP PLANI / MALIYET SISTEMI sorulari ama
#  kaynak alanlari VUK maddesine baglanmis. VUK m.262 "maliyet bedeli"ni
#  tanimlar; yevmiye kaydini, hangi hesabin borclanacagini ANLATMAZ. Hakem
#  hakli olarak "bu metin bunu soylemiyor" diyor. Soru yanlis degil, ATFI
#  yanlis yere dusmus. Dogru kaynak MSUGT Tekduzen Hesap Plani - ambarda var.
#
#  NE YAPAR: yetersiz cikan sorulari okur, muhasebe-kaydi sorusu olup olmadigina
#  bakar, metinden 3 haneli hesap kodlarini toplar ve kaynak alanini
#  "MSUGT Tekduzen Hesap Plani - <kodlar>" olarak duzeltir. Boylece bir sonraki
#  hakem turunda madde-coz.ps1'in THP yolu devreye girer ve soru DOGRU metinle
#  yargilanir.
#
#  PARA HARCAMAZ (API cagrisi yok). Varsayilan KURU KOSU: yalniz olcer ve
#  rapor yazar; -uygula ile gercekten yazar. Yazim PATCH ile tek kolon
#  (kismi-upsert 23502 tuzagi - 01.08 dersi). Eski kaynak rapora yazilir.
#  ENV: SUPABASE_SERVICE_KEY.  Rapor: veri/kaynak-onarim-raporu.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$raporYol = 'veri/kaynak-onarim-raporu.json'
function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g); exit 1
}

# --- 1) hakem raporlarindan "yetersiz" kimlikleri (kisa 8 hane olabilir)
$yetersiz = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($f in (Get-ChildItem 'veri' -Filter 'profesor-rapor-*.json' -ErrorAction SilentlyContinue)){
  try { $r = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($r.sonuclar)){ if("$($s.destek)" -eq 'yetersiz'){ [void]$yetersiz.Add("$($s.id)") } }
}
Write-Host ("Hakem 'yetersiz' kimlik: {0}" -f $yetersiz.Count)
if($yetersiz.Count -eq 0){ Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='IS YOK' }); exit 0 }

# --- 2) kasadan sorulari cek (yalniz gerekli kolonlar)
$kasa = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,ders,konu,soru,kaynak&limit=1000&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $liste = @($ham | ConvertFrom-Json)
  if($liste.Count -eq 0){ break }
  foreach($s in $liste){ $kasa.Add($s) }
  if($liste.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- 3) muhasebe-kaydi sorusu mu? (kayit/hesap dili) + hesap kodu var mi?
$reKayit = [regex]'(?i)yevmiye|muhasebe kayd|hangi hesab|hesab[ıi]n[ıi]n? bor[cç]|alacakland[ıi]r|hesap plan[ıi]|tekd[uü]zen|kayd[ıi] yap[ıi]l'
$reKod   = [regex]'(?<![\d.])([1-7]\d{2})(?![\d])'
$reKanunNo = [regex]'(?i)(say[ıi]l[ıi]|s\.\s*K\.|S[ıi]ra\s*No)'

$onarilacak = New-Object System.Collections.Generic.List[object]
$kapsamDisi = 0
foreach($s in $kasa){
  $tam = "$($s.id)"; $kisa = if($tam.Length -ge 8){ $tam.Substring(0,8) } else { $tam }
  if(-not ($yetersiz.Contains($tam) -or $yetersiz.Contains($kisa))){ continue }
  $mevcut = "$($s.kaynak)"
  if($mevcut -match '(?i)MSUGT|tekd[uü]zen|hesap plan|\bTHP\b'){ $kapsamDisi++; continue }  # zaten dogru
  $govde = "$($s.soru) $($s.konu)"
  if(-not $reKayit.IsMatch($govde)){ $kapsamDisi++; continue }                              # kayit sorusu degil
  $kodlar = @()
  foreach($m in $reKod.Matches($govde)){
    $son = $govde.Substring($m.Index + $m.Length)
    if($reKanunNo.IsMatch($son.Substring(0,[Math]::Min(12,$son.Length)))){ continue }        # "213 sayili" gibi kanun no
    if($kodlar -notcontains $m.Groups[1].Value){ $kodlar += $m.Groups[1].Value }
  }
  if($kodlar.Count -eq 0){ $kapsamDisi++; continue }                                        # hesap kodu yoksa dokunma
  if($kodlar.Count -gt 4){ $kodlar = $kodlar[0..3] }
  $onarilacak.Add([pscustomobject]@{
    id = $tam; ders = "$($s.ders)"; konu = "$($s.konu)"
    eski_kaynak = $mevcut
    yeni_kaynak = ("MSUGT Tekduzen Hesap Plani - " + ($kodlar -join ', '))
  })
}
Write-Host ("ONARILACAK: {0}   kapsam disi (dokunulmadi): {1}" -f $onarilacak.Count, $kapsamDisi)

$yazilan = 0; $hata = 0
if($uygula -and $onarilacak.Count){
  foreach($o in $onarilacak){
    $gb = ConvertTo-Json -InputObject @{ kaynak = $o.yeni_kaynak } -Compress
    $yr = Invoke-WebRequest -Method Patch -Uri "${U}?id=eq.$($o.id)" `
      -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) `
      -Body ([Text.Encoding]::UTF8.GetBytes($gb)) -TimeoutSec 60 -UseBasicParsing -SkipHttpErrorCheck
    if([int]$yr.StatusCode -ge 300){ $hata++; if($hata -le 3){ Write-Host ("PATCH {0} -> HTTP {1}" -f $o.id, $yr.StatusCode) } }
    else { $yazilan++ }
    if(($yazilan % 500) -eq 0 -and $yazilan -gt 0){ Write-Host ("  ... {0}/{1} yazildi" -f $yazilan, $onarilacak.Count) }
  }
}

Rapor ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($uygula){ 'UYGULA' } else { 'KURU KOSU (yazma yok)' })
  hakem_yetersiz = $yetersiz.Count
  onarilacak = $onarilacak.Count
  kapsam_disi = $kapsamDisi
  yazilan = $yazilan
  hata = $hata
  ornekler = @($onarilacak | Select-Object -First 25)
  not = "Yalniz 'kaynak' kolonu degistirildi; soru/sik/aciklama/yayin durumuna DOKUNULMADI. Onarilanlar bir sonraki hakem turunda DOGRU metinle (THP) yargilanacak."
})
Write-Host ("-> {0}" -f $raporYol)
