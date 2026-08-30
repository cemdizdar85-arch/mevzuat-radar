# ============================================================================
#  ÜRÜN KÜNYESİ — "sorduğumda net ve gerçekçi cevap ver"
#
#  NEDEN VAR (Cem 30.08): "sana onunla ilgili bir bilgi sorduğumda en net ve
#  gerçekçi cevabı bana veresin." Bugüne kadar bu sorunun cevabı HAFIZADAN
#  veriliyordu - ve hafıza eskiyor. Bu betik her ürünün fotoğrafını ÖLÇER:
#  kaç kayıt, ne zaman güncellendi, hangi robot besliyor, robot ne sıklıkta koşuyor.
#
#  ÇIKTI: veri/URUN-KUNYELERI.json  ->  pano.html bunu gösterir.
#
#  ÖLÇÜM DİSİPLİNİ: ölçülemeyen hücreye "yok" YAZILMAZ, "ölçülmedi" yazılır.
#  Supabase'deki tablolar buradan görünmez - onlar "kasada (ölçülmedi)" olur.
# ============================================================================
$ErrorActionPreference = 'Stop'
$KOK = Split-Path $PSScriptRoot -Parent

# --- ÜRÜN TANIMLARI - elle yazılır, çünkü doğruluk tahmine bırakılmaz --------
$URUNLER = @(
  @{ ad='Alacak Radarı'; yuz='alacak-radari.html'; desen='^alacak'; kasa='alacak_vitrin (Supabase)' },
  @{ ad='Marka Radarı';  yuz='marka-radari.html';  desen='^marka';  kasa='marka_talep · marka_rakip · marka_durum' },
  @{ ad='Destek Radarı'; yuz='destekler.html';     desen='^(destek|cagri|kgf|iskur|eximbank|birlik|tesvik)'; kasa='destek_takip' },
  @{ ad='İhale Radarı';  yuz='ihale-radari.html';  desen='^ihale';  kasa='ihale (gizli kasa)' },
  @{ ad='Sınav / Soru';  yuz='soru-cevap.html';    desen='^(soru|konu|kart|zorluk|parti|vitrin|sik|ders)'; kasa='soru bankası (RLS korumalı)' },
  @{ ad='Mevzuat / RG';  yuz='radar.html';         desen='^(mevzuat|teblig|rg-|duyuru|madde|dayanak)'; kasa='madde_ara' }
)

function KayitSay($yol){
  # JSON'daki EN BÜYÜK diziyi kayıt sayısı sayar. Dizi yoksa 'ölçülmedi'.
  try {
    $o = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $en = 0
    foreach($p in $o.PSObject.Properties){ if($p.Value -is [System.Array] -and $p.Value.Count -gt $en){ $en = $p.Value.Count } }
    if($o -is [System.Array] -and $o.Count -gt $en){ $en = $o.Count }
    return $en
  } catch { return -1 }   # -1 = ölçülemedi
}

# --- ROBOT HARİTASI: hangi workflow hangi ürüne dokunuyor -------------------
$wf = Get-ChildItem (Join-Path $KOK '.github\workflows') -Filter *.yml -ErrorAction SilentlyContinue
$robotlar = @()
foreach($f in $wf){
  $ic = Get-Content $f.FullName -Raw -Encoding UTF8
  $cron = if($ic -match "cron:\s*'([^']+)'"){ $Matches[1] } else { $null }
  if($cron){ $robotlar += [pscustomobject]@{ dosya=$f.Name; cron=$cron; icerik=$ic } }
}

$sonuc = @()
foreach($u in $URUNLER){
  $dosyalar = Get-ChildItem (Join-Path $KOK 'veri') -Filter *.json -File | Where-Object { $_.Name -match $u.desen }
  $toplam = 0; $olculemeyen = 0
  foreach($d in $dosyalar){
    $s = KayitSay $d.FullName
    if($s -lt 0){ $olculemeyen++ } else { $toplam += $s }
  }

  # son güncelleme: git'in bildiği son commit (dosya damgası OneDrive'dan kayabilir)
  $sonCommit = $null
  if($dosyalar){
    $yollar = $dosyalar | ForEach-Object { 'veri/' + $_.Name }
    try { $sonCommit = (git -C $KOK log -1 --format='%ci' -- $yollar 2>$null) } catch {}
  }

  # Bu ürünü besleyen zamanlanmış robotlar.
  #
  # 30.08 DERSİ: ilk sürüm workflow METNİNDE anahtar kelime arıyordu ve YALAN
  # SÖYLÜYORDU - "Mevzuat/RG" 20 robot gösterdi, yani neredeyse hepsini; çünkü
  # "madde", "duyuru" gibi kelimeler her akışın yorumunda geçiyor. Sınav satırında
  # marka-ayna, destek satırında marka-talep çıkıyordu.
  #
  # ÖLÇÜLEBİLİR ÖLÇÜT: bir robot bir ürüne aitse o ürünün veri dosyasına YAZAR.
  # Workflow'un dokunduğu veri/*.json yollarını çıkarıp desene bakıyoruz.
  # Tahmin değil, ölçüm.
  $benim = @()
  foreach($rb in $robotlar){
    $yazdiklari = [regex]::Matches($rb.icerik, 'veri/([A-Za-z0-9\-_/]+\.json)') | ForEach-Object { Split-Path $_.Groups[1].Value -Leaf } | Sort-Object -Unique
    foreach($y in $yazdiklari){
      if($y -match $u.desen){ $benim += "$($rb.dosya) [$($rb.cron)]"; break }
    }
  }

  $sonuc += [pscustomobject]@{
    urun            = $u.ad
    yuz             = $u.yuz
    yuz_var         = (Test-Path (Join-Path $KOK $u.yuz))
    dosya_sayisi    = $dosyalar.Count
    kayit_sayisi    = $toplam
    olculemeyen     = $olculemeyen
    son_guncelleme  = $sonCommit
    kasa            = $u.kasa + ' — kasa içeriği buradan ÖLÇÜLMEDİ'
    robotlar        = ($benim | Sort-Object -Unique)
    robot_sayisi    = @($benim | Sort-Object -Unique).Count
  }
}

$cikti = [pscustomobject]@{
  olcum_zamani = (Get-Date -Format 'o')
  aciklama     = "Yerel veri/*.json dosyalarindan olculdu. Supabase kasasindaki tablolar buradan GORUNMEZ - onlar icin 'olculmedi' gecerlidir."
  toplam_json  = (Get-ChildItem (Join-Path $KOK 'veri') -Filter *.json -File).Count
  zamanli_robot= $robotlar.Count
  urunler      = $sonuc
}

$hedef = Join-Path $KOK 'veri\URUN-KUNYELERI.json'
($cikti | ConvertTo-Json -Depth 6) | Set-Content $hedef -Encoding UTF8
Write-Host "yazildi: veri/URUN-KUNYELERI.json" -ForegroundColor Green
foreach($s in $sonuc){
  $kt = if($s.olculemeyen -gt 0){ "$($s.kayit_sayisi) (+$($s.olculemeyen) olculemedi)" } else { "$($s.kayit_sayisi)" }
  "{0,-15} {1,3} dosya · {2,10} kayit · {3} robot · {4}" -f $s.urun, $s.dosya_sayisi, $kt, $s.robot_sayisi, $(if($s.son_guncelleme){ ([datetime]::Parse($s.son_guncelleme)).ToString('dd.MM HH:mm') } else { 'olculmedi' })
}
