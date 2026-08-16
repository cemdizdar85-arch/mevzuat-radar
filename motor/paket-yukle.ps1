# ============================================================================
#  PAKET HAVUZU TASIYICI — onay dosyasindaki durum='paket-havuzu' sorulari
#  Supabase 'soru_havuzu' tablosuna (kilitli; yalniz uye okur) tasir ve
#  PUBLIC depodan SILER. Parali icerik depoda tutulmaz — sizinti vektoru.
#  Idempotent: upsert (ayni id tekrar yuklenirse gunceller).
#  ENV: SUPABASE_SERVICE_KEY zorunlu. Yoksa zarifce atlar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - tasiyici atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Prefer = "resolution=merge-duplicates,return=minimal" }

$onayYol = Join-Path $kok "veri/soru-bankasi-onay.json"
$onay = if(Test-Path $onayYol){ Get-Content $onayYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

# 23.07: fabrika/el-partisi kanali da tuketilir — veri/fabrika/*.json icindeki
# durum='paket-havuzu' (GM onay damgali) sorular ayni sekilde kasaya tasinir,
# tuketilen soru dosyadan cikarilir, sorusu kalmayan dosya SILINIR.
$fabrikaDir = Join-Path $kok "veri/fabrika"
$fabrikaDosyalari = @(); if(Test-Path $fabrikaDir){ $fabrikaDosyalari = @(Get-ChildItem $fabrikaDir -Filter *.json) }

# 28.07 DUZELTME (Cem onayi): GM okumasi 'gm-onay' damgasi yaziyordu, tasiyici ise
# yalniz 'paket-havuzu' ariyordu -> GM'nin okuyup onayladigi 528 soru yerelde ASILI
# KALIYORDU. Iki damga da kasaya gider.
$TASINABILIR = @('paket-havuzu','gm-onay')

$paket = @()
if($onay){ $paket += @($onay.sorular | Where-Object { $TASINABILIR -contains "$($_.durum)" }) }
$fabrikaIcerik = @{}
foreach($fd in $fabrikaDosyalari){
  try {
    $ic = Get-Content $fd.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $fabrikaIcerik[$fd.FullName] = $ic
    $paket += @($ic.sorular | Where-Object { $TASINABILIR -contains "$($_.durum)" })
  } catch { Write-Host ("UYARI: {0} okunamadi, atlandi" -f $fd.Name) }
}
if($paket.Count -eq 0){ Write-Host "Tasinacak paket sorusu yok."; exit 0 }
Write-Host ("Aday: {0} soru" -f $paket.Count)

# ---- 28.07 KASA MUKERRER KAPISI (Cem: "ayni soru zaten kasada olabilir") -------
# GM yerelde okurken kasayi goremiyor (anon anahtar RLS'e takiliyor). Bu betik
# SERVICE anahtariyla kostugu icin kasayi okuyabilir; mukerrer kontrolu BURADA yapilir.
# Kural: kok metni (bosluk/noktalama/buyuk-kucuk normalize) kasada zaten varsa ve
# id FARKLIYSA soru tasinmaz, yerelde 'kasa-mukerrer' damgasiyla birakilir.
function KokNormal($t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[‘’“”]',"'" -replace '\s+',' '
  $x = $x -replace '[^\p{L}\p{Nd} ]',''
  return $x.Trim()
}
$kasaKok = @{}
$kasaAdet = 0
try {
  $bas = 0
  while($true){
    $sayfa = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,soru&order=id&offset=$bas&limit=1000" `
      -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 120
    $dilimK = @($sayfa)
    if($dilimK.Count -eq 0){ break }
    foreach($k in $dilimK){ $kasaAdet++; $kk = KokNormal $k.soru; if($kk.Length -ge 25 -and -not $kasaKok.ContainsKey($kk)){ $kasaKok[$kk] = "$($k.id)" } }
    if($dilimK.Count -lt 1000){ break }
    $bas += 1000
  }
  Write-Host ("KASA SAYIMI: {0} soru okundu, {1} tekil kok" -f $kasaAdet, $kasaKok.Count)
} catch {
  Write-Host ("KRITIK: kasa okunamadi - mukerrer kapisi calistirilamaz: {0}" -f $_.Exception.Message)
  Write-Host "Tasima DURDURULDU (kor tasima yapilmaz)."
  exit 1
}

$mukerrer = @()
$temiz = @()
foreach($s in $paket){
  $kk = KokNormal $s.soru
  if($kk.Length -ge 25 -and $kasaKok.ContainsKey($kk) -and $kasaKok[$kk] -ne "$($s.id)"){
    $mukerrer += $s
  } else { $temiz += $s }
}
if($mukerrer.Count -gt 0){
  Write-Host ("KASA MUKERRERI: {0} soru zaten kasada var - tasinmayacak, yerelde 'kasa-mukerrer' damgasiyla kalacak." -f $mukerrer.Count)
}
$paket = $temiz
if($paket.Count -eq 0){ Write-Host "Mukerrer eleme sonrasi tasinacak soru kalmadi."; exit 0 }
Write-Host ("Tasinacak: {0} soru" -f $paket.Count)

# 24.07 DAYANIKLILIK (Cem "sistem durmasin, GM sensin"): opsiyonel gorsel kolonlar
# (yevmiye/tablo/yanlis_kayitlar) yoksa TASIMAYI DURDURMA - o alani atla, soruyu yine tasi,
# atlananlari GERI-DOLDURMA listesine yaz (kolon eklenince backfill). Cekirdek soru/cevap/aciklama
# her halukarda gider; gorsel eksigi tum kasayi bosta tutmaktan iyidir. (Eski sert exit 1
# tek hayalet soru yuzunden 1.191 soruyu kasaya sokamiyordu - bulundu ve kaldirildi.)
function KolonVar($ad){ try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=$ad&limit=1" -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 30 | Out-Null; return $true } catch { return $false } }
$yevmiyeKolonu = KolonVar 'yevmiye'
$tabloKolonu   = KolonVar 'tablo'
$hayaletKolonu = KolonVar 'yanlis_kayitlar'
# 28.07: GM okumasinda 76 grupta 357 soru 'benzerGrup' etiketi aldi (ayni kurali olcen
# sorular). Quiz motorunun bir oturumda gruptan TEK soru servis edebilmesi icin bu etiket
# kasaya da tasinmali; kolon yoksa soru yine tasinir, etiket backfill listesine yazilir.
$grupKolonu    = KolonVar 'benzer_grup'
$backfill = @()
foreach($s in $paket){
  $eksik = @()
  if(($s.yevmiye -and @($s.yevmiye).Count -gt 0) -and -not $yevmiyeKolonu){ $eksik += 'yevmiye' }
  if($s.tablo -and -not $tabloKolonu){ $eksik += 'tablo' }
  if($s.yanlisKayitlar -and -not $hayaletKolonu){ $eksik += 'yanlis_kayitlar' }
  if($s.benzerGrup -and -not $grupKolonu){ $eksik += 'benzer_grup' }
  if($eksik.Count){ $backfill += [ordered]@{ id=$s.id; eksik_alanlar=$eksik; benzer_grup="$($s.benzerGrup)" } }
}
if(-not $grupKolonu){ Write-Host "UYARI: 'benzer_grup' kolonu yok - benzerlik etiketi tasinamadi (backfill). Quiz motoru gruptan tek soru servis edemez." }
if(-not $yevmiyeKolonu){ Write-Host "UYARI: 'yevmiye' kolonu yok - o alan atlanarak tasiniyor (backfill)" }
if(-not $tabloKolonu){ Write-Host "UYARI: 'tablo' kolonu yok - o alan atlanarak tasiniyor (backfill)" }
if(-not $hayaletKolonu){ Write-Host "UYARI: 'yanlis_kayitlar' kolonu yok - o alan atlanarak tasiniyor (backfill)" }
if($backfill.Count){
  $bfYol = Join-Path $kok "veri/kasa-backfill-bekleyen.json"
  [IO.File]::WriteAllText($bfYol, ($backfill | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("GERI-DOLDURMA: {0} soru gorsel alani eksik tasindi - kolon eklenince backfill (veri/kasa-backfill-bekleyen.json)" -f $backfill.Count)
}

# 24.07 PARTILI TASIMA: 1.199 soru tek POST'ta (2.76MB govde + 11KB dogrulama URL'i)
# sunucu sinirlarina takiliyordu (#17-#21 kirmizi seri) -> 150'serlik partiler.
# Her parti ayri yuklenir + ayri dogrulanir; TUM partiler dogrulanmadan depo silinmez.
$PARTI = 150
$toplamDogrulanan = 0
for($i=0; $i -lt $paket.Count; $i += $PARTI){
  $dilim = @($paket[$i..([Math]::Min($i+$PARTI-1, $paket.Count-1))])
  $govde = @($dilim | ForEach-Object {
    $satir = [ordered]@{
      id=$_.id; sinav="$($_.sinav)"; ders="$($_.ders)"; konu="$($_.konu)"; soru="$($_.soru)"
      siklar=$_.siklar; dogru="$($_.dogru)"; aciklama=$_.aciklama
      kaynak="$($_.kaynak)"; hap="$($_.hap)"
      onay=$(if("$($_.onay)".Trim()){ "$($_.onay)" } elseif("$($_.gmKarar)".Trim()){ "GM $($_.gmTarih): $($_.gmKarar)" } else { "" })
      uretim="$($_.uretim)"
    }
    if($yevmiyeKolonu){ $satir['yevmiye'] = $_.yevmiye }
    if($tabloKolonu){ $satir['tablo'] = $_.tablo }
    if($hayaletKolonu){ $satir['yanlis_kayitlar'] = $_.yanlisKayitlar }
    if($grupKolonu){ $satir['benzer_grup'] = "$($_.benzerGrup)" }
    $satir
  })
  $json = ConvertTo-Json -InputObject $govde -Depth 6
  $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $H `
      -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 120 | Out-Null
  } catch {
    Write-Host ("HATA parti {0}: POST basarisiz - {1}" -f ([int]($i/$PARTI)+1), $_.Exception.Message)
    $hataGovde = ""
    try { $hataGovde = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    if($hataGovde){ Write-Host ("SUNUCU CEVABI: " + $hataGovde.Substring(0, [Math]::Min(500, $hataGovde.Length))) }
    # 24.07: loglar admin-kilitli - hata DOSYAYA yazilir, workflow always() ile commit'ler (kor kalma yasak)
    $hataKaydi = [ordered]@{
      zaman = (Get-Date -Format "dd.MM.yyyy HH:mm"); parti = ([int]($i/$PARTI)+1)
      ilk_id = "$($dilim[0].id)"; son_id = "$($dilim[-1].id)"; dilim_adet = $dilim.Count
      istisna = "$($_.Exception.Message)"; sunucu_cevabi = $hataGovde
      govde_ilk_600 = $json.Substring(0, [Math]::Min(600, $json.Length))
    }
    [IO.File]::WriteAllText((Join-Path $kok "veri/tasiyici-hata.json"), ($hataKaydi | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
    Write-Host "Depoya DOKUNULMADI - onceki partiler kasada (upsert, tekrar kosmak guvenli)."
    exit 1
  }
  # parti dogrulamasi (150 id ~ 1.4KB URL - guvenli)
  $idListe = ($dilim | ForEach-Object { $_.id }) -join ','
  $kontrol = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($idListe)&select=id" `
    -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 60
  if(@($kontrol).Count -ne $dilim.Count){
    Write-Host ("HATA parti {0}: dogrulama tutmadi ({1}/{2}) - depoya DOKUNULMADI." -f ([int]($i/$PARTI)+1), @($kontrol).Count, $dilim.Count)
    exit 1
  }
  $toplamDogrulanan += $dilim.Count
  Write-Host ("parti {0}: {1} soru yuklendi+dogrulandi (toplam {2}/{3})" -f ([int]($i/$PARTI)+1), $dilim.Count, $toplamDogrulanan, $paket.Count)
}
Write-Host ("Dogrulandi: {0}/{1} kayit tabloda." -f $toplamDogrulanan, $paket.Count)

# ancak dogrulama sonrasi depodan temizle
# 28.07: ARTIK DURUMA GORE DEGIL, GERCEKTEN YUKLENEN ID'YE GORE siliniyor. Eskiden
# 'paket-havuzu' damgali her sey siliniyordu; kasa-mukerrer kapisi eklendigi icin
# tasinmayan sorularin da silinmesi veri kaybi olurdu.
$yuklenenId = @{}
foreach($s in $paket){ $yuklenenId["$($s.id)"] = $true }
$mukerrerId = @{}
foreach($s in $mukerrer){ $mukerrerId["$($s.id)"] = $true }

function DamgaGuncelle($liste){
  foreach($q in @($liste)){
    if($q -and $mukerrerId.ContainsKey("$($q.id)")){
      $q.durum = 'kasa-mukerrer'
      $q | Add-Member -NotePropertyName kasaNot -NotePropertyValue "Aynı kök kasada zaten var; taşınmadı (28.07 mükerrer kapısı)." -Force
    }
  }
}

if($onay){
  DamgaGuncelle $onay.sorular
  $onay.sorular = @($onay.sorular | Where-Object { -not $yuklenenId.ContainsKey("$($_.id)") })
  $onay.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
  [IO.File]::WriteAllText($onayYol, ($onay | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
}
foreach($fdYol in $fabrikaIcerik.Keys){
  $ic = $fabrikaIcerik[$fdYol]
  DamgaGuncelle $ic.sorular
  $kalan = @($ic.sorular | Where-Object { -not $yuklenenId.ContainsKey("$($_.id)") })
  if($kalan.Count -eq 0){
    Remove-Item $fdYol -Force
    Write-Host ("  {0}: tum sorular tasindi, dosya silindi" -f (Split-Path $fdYol -Leaf))
  } else {
    $ic.sorular = $kalan
    [IO.File]::WriteAllText($fdYol, ($ic | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
    Write-Host ("  {0}: {1} soru kaldi (paket olmayanlar)" -f (Split-Path $fdYol -Leaf), $kalan.Count)
  }
}
Write-Host ("TAMAM: {0} soru kilitli havuza tasindi, depodan cikarildi." -f $paket.Count)

# ---- 28.07 KOSU SONRASI MUTABAKAT (Cem dersi: "yesil kosu != tam veri") -----------
$kasaSon = 0
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&limit=1" `
    -Headers @{ apikey=$KEY; Authorization="Bearer $KEY"; Prefer='count=exact' } -TimeoutSec 60
  $kasaSon = [int](($r.Headers['Content-Range'] -split '/')[-1])
} catch { Write-Host "UYARI: kosu sonrasi kasa sayimi alinamadi" }
Write-Host ""
Write-Host "======== TASIMA MUTABAKATI ========"
Write-Host ("  kosu oncesi kasa      : {0}" -f $kasaAdet)
Write-Host ("  aday (paket+gm-onay)  : {0}" -f ($paket.Count + $mukerrer.Count))
Write-Host ("  kasa mukerreri (atlandi): {0}" -f $mukerrer.Count)
Write-Host ("  tasinan + dogrulanan  : {0}" -f $toplamDogrulanan)
Write-Host ("  kosu sonrasi kasa     : {0}" -f $kasaSon)
$beklenen = $kasaAdet + $toplamDogrulanan
if($kasaSon -gt 0 -and $kasaSon -ne $beklenen){
  Write-Host ("  KIRMIZI: beklenen {0}, gerceklesen {1} (fark {2}) - sebep bulunmadan devam edilmez." -f $beklenen, $kasaSon, ($kasaSon-$beklenen))
  exit 1
}
Write-Host "  MUTABAKAT TUTTU."
exit 0
