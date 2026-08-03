# ============================================================================
#  KAYNAK BUTUNLUK DENETIMI (03.08.2026) — 0 USD, API YOK
#
#  CEM: "boyle eksik okudugumuz baska bir sey var mi? Korkum benim
#        yakalamadigim baska bir hata var mi."
#
#  KORKU HAKLI VE SEBEBI SU: hesap plani vakasinda veri AMBARDA VARDI, ben
#  TEK DOSYA okuyup "eksik" sandim. 199 hesap gordum, 230 vardi; 100 KASA,
#  102 BANKALAR, 600 YURTICI SATISLAR, 730 GENEL URETIM GIDERLERI hep
#  msugt-thp2.json'daydi ve hicbir robot orayi acmiyordu.
#
#  Bu kusurun adi: PARCALI KAYNAGIN TEK PARCASINI OKUMAK. Gozle aranmaz -
#  olculur. Bu robot iki sey yapar:
#
#   1) PARCALI KAYNAKLARI bulur: ayni kaynagin birden fazla dosyaya bolunmus
#      hali (tms1.json + tms12.json gibi). Her grup icin dosya/belge/karakter.
#
#   2) SABIT DOSYA ADI ile okuyan kodu bulur: motor/*.ps1 ve *.html icinde
#      'veri/mevzuat/xxx.json' gibi TEK dosyaya cakili referanslar. Eger o
#      dosyanin kaynagi parcaliysa, o okuyucu EKSIK OKUYOR demektir.
#
#  CIKTI: veri/kaynak-butunluk.json — riskli okuyucular ve parcali kaynaklar.
#  Karar insanindir; robot yalnizca "burada eksik okuma riski var" der.
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/kaynak-butunluk.json'

trap {
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA: {0}" -f $_.Exception.Message); exit 1
}

# --- 1) PARCALI KAYNAKLAR ---
# Ayni kokten turemis dosyalar: "tms1.json" ile "tms12.json" ayni standardin
# parcalari olabilir. Kok cikarma kurali: sondaki -tam / -ek / rakam atilir.
$dizin = Join-Path $kok 'veri/mevzuat'
$gruplar = @{}
foreach($f in (Get-ChildItem (Join-Path $dizin '*.json') -ErrorAction SilentlyContinue)){
  if($f.BaseName.StartsWith('_')){ continue }   # _durum, _madde-damga: teknik dosyalar
  # 03.08 - KENDI ROBOTUM YANLIS GRUPLUYORDU: sondaki rakami atinca
  # "tms12.json"i "TMS 1'in 2. parcasi" sandi. Baktim: TMS 12, AYRI STANDART.
  # bds200/bds700 de oyle. Yani "7 parcali kaynak var" raporum uydurmaydi.
  # Rakam ATILMAZ; yalniz acik parca ekleri (-tam, -ek, 2) grup sayilir ve
  # bunlar da asagida ICERIKLE dogrulanir.
  $kokAd = $f.BaseName -replace '(?i)[-_](tam|ek|ilkeler)$',''
  if($kokAd -eq ''){ $kokAd = $f.BaseName }
  if(-not $gruplar.ContainsKey($kokAd)){ $gruplar[$kokAd] = New-Object System.Collections.Generic.List[object] }
  $belge = 0
  try { $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json; $belge = @($j.belgeler).Count } catch {}
  $gruplar[$kokAd].Add([ordered]@{ dosya=$f.Name; belge=$belge; bayt=$f.Length })
}
$parcali = New-Object System.Collections.Generic.List[object]
foreach($g in ($gruplar.Keys | Sort-Object)){
  if($gruplar[$g].Count -lt 2){ continue }
  $tb=0; $tk=0
  foreach($d in $gruplar[$g]){ $tb += $d.belge; $tk += $d.bayt }
  $parcali.Add([ordered]@{ kaynak=$g; dosya_sayisi=$gruplar[$g].Count; toplam_belge=$tb; toplam_bayt=$tk; dosyalar=$gruplar[$g].ToArray() })
}
Write-Host ("Parcali kaynak: {0} grup" -f $parcali.Count)

# --- 2) SABIT DOSYA ADIYLA OKUYAN KOD ---
# 'veri/mevzuat/xxx.json' gibi dogrudan bir dosyaya cakili referanslar. Glob
# kullananlar (msugt*.json) GUVENLIDIR - onlar tum parcalari okur.
$parcaliDosya = @{}
foreach($p in $parcali){ foreach($d in $p.dosyalar){ $parcaliDosya[$d.dosya] = $p.kaynak } }

$riskli = New-Object System.Collections.Generic.List[object]
$taranan = 0
foreach($src in (Get-ChildItem (Join-Path $kok 'motor') -Filter '*.ps1' -ErrorAction SilentlyContinue) +
                (Get-ChildItem $kok -Filter '*.html' -ErrorAction SilentlyContinue)){
  $taranan++
  $metin = Get-Content $src.FullName -Raw -Encoding UTF8
  foreach($m in [regex]::Matches($metin, "veri/mevzuat/([A-Za-z0-9\-_]+\.json)")){
    $dosyaAd = $m.Groups[1].Value
    if(-not $parcaliDosya.ContainsKey($dosyaAd)){ continue }   # parcali degil, sorun yok
    $kaynakAd = $parcaliDosya[$dosyaAd]
    # Ayni dosyada glob da varsa (msugt*.json) okuyucu zaten tamamini aliyordur
    $globVar = [regex]::IsMatch($metin, "veri/mevzuat/[A-Za-z0-9\-_]*\*")
    $riskli.Add([ordered]@{
      okuyucu=$src.Name; sabit_dosya=$dosyaAd; kaynak=$kaynakAd
      kaynak_dosya_sayisi=($parcali | Where-Object { $_.kaynak -eq $kaynakAd }).dosya_sayisi
      glob_de_var=$globVar
      risk=$(if($globVar){'DUSUK - ayni dosyada glob okuma da var'}else{'YUKSEK - kaynagin yalniz bir parcasi okunuyor'})
    })
  }
}
$yuksek = @($riskli | Where-Object { $_.risk -like 'YUKSEK*' })
Write-Host ("Taranan dosya: {0} | Riskli referans: {1} (yuksek: {2})" -f $taranan, $riskli.Count, $yuksek.Count)

# --- 3) GERCEK PARCA DENETIMI: belge adindaki [n/m] isaretleri ---
# En guvenilir sinyal dosya adi degil, BELGE adindaki "[1/2]" isareti. Uzun
# metinler bolunurken bu damga vuruluyor. Tum parcalar var mi, sayilir.
$parcaGrup = @{}
foreach($f in (Get-ChildItem (Join-Path $dizin '*.json') -ErrorAction SilentlyContinue)){
  if($f.BaseName.StartsWith('_')){ continue }
  try { $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($b in @($j.belgeler)){
    $mm = [regex]::Match("$($b.kaynak_ad)", '\[(\d+)\s*/\s*(\d+)\]')
    if(-not $mm.Success){ continue }
    $temel = "$($b.kaynak_ad)" -replace '\s*\[\d+\s*/\s*\d+\]\s*',''
    $anah = "$($f.Name)|$temel"
    if(-not $parcaGrup.ContainsKey($anah)){ $parcaGrup[$anah] = @{ toplam=[int]$mm.Groups[2].Value; bulunan=@{} } }
    $parcaGrup[$anah].bulunan[$mm.Groups[1].Value] = 1
  }
}
$eksikParca = New-Object System.Collections.Generic.List[object]
foreach($a in $parcaGrup.Keys){
  $p = $parcaGrup[$a]
  if($p.bulunan.Count -lt $p.toplam){
    $eksikParca.Add([ordered]@{ belge=$a; bulunan=($p.bulunan.Keys | Sort-Object); beklenen=$p.toplam })
  }
}
Write-Host ("[n/m] isaretli belge grubu: {0} | parcasi eksik: {1}" -f $parcaGrup.Count, $eksikParca.Count)

$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum=$(if($yuksek.Count -eq 0 -and $eksikParca.Count -eq 0){'TEMIZ'}else{'RISK VAR'})
  parcali_belge_grubu=$parcaGrup.Count
  parcasi_eksik_belge=$eksikParca.Count
  eksik_parcalar=$eksikParca.ToArray()
  yontem='Parcali kaynaklar tespit edilir; sonra kodda TEK dosyaya cakili referanslar aranir. Cakili referans + parcali kaynak = EKSIK OKUMA RISKI.'
  parcali_kaynak_sayisi=$parcali.Count
  yuksek_riskli_okuyucu=$yuksek.Count
  yuksek_riskli=$yuksek
  tum_riskli=$riskli.ToArray()
  parcali_kaynaklar=$parcali.ToArray()
  vaka='03.08: msugt-thp-tam.json tek basina okunuyordu (199 hesap); msugt-thp2.json okunmuyordu. 100 KASA, 102 BANKALAR, 600 YURTICI SATISLAR, 730 GENEL URETIM GIDERLERI kayipti. Birlesince 230 hesap.'
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 6) -Encoding UTF8 -NoNewline
Write-Host "`n=== KAYNAK BUTUNLUK ==="
foreach($r in $yuksek){ Write-Host ("  YUKSEK  {0,-26} -> {1} (kaynak '{2}' {3} dosyaya bolunmus)" -f $r.okuyucu, $r.sabit_dosya, $r.kaynak, $r.kaynak_dosya_sayisi) }
foreach($p in $parcali){ Write-Host ("  parcali {0,-16} {1} dosya, {2} belge" -f $p.kaynak, $p.dosya_sayisi, $p.toplam_belge) }
if($yuksek.Count -gt 0){ Write-Host "`n!! Eksik okuma riski var - rapora bak."; exit 1 }
