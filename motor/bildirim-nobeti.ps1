# ============================================================================
#  BILDIRIM NOBETI — ogrenci itirazi gelince soruyu yayindan cek (02.08.2026)
#  SINAV-KURALLARI H7 + H5: "Yayina girmis bir soruda sonradan kusur gorulurse
#  ONCE YAYINDAN CEKILIR, sonra tartisilir."
#
#  NEDEN: "Bu soruda hata bildir" dugmesi bildirimi yalnizca e-postaya
#  gonderiyordu. Biz e-postayi okuyana kadar - belki saatler, belki gunler -
#  yanlis olabilecek soru adaylarin onunde duruyordu. Cem'in kurali bunu
#  kaldirmiyor: "site yanlis soru, cevap, yanlis yonlendirme vermeyecek."
#
#  KURAL: ayni soruya BIRBIRINDEN FARKLI 2 oturumdan bildirim gelirse soru
#  kendiliginden yayindan cekilir (yayin=false) ve GM'ye duser. Tek bildirim
#  cekmez - yoksa bir kisi butun bankayi kapatabilir. Iki farkli aday ayni
#  soruya takildiysa orada gercekten bir sey vardir.
#
#  Cekme GERI ALINABILIR: GM soruyu okur, hakliysa duzeltir, haksizsa
#  bildirime kaynak gostererek cevap yazar ve soruyu yeniden acar.
#
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY
#  Cikti: veri/bildirim-nobeti-raporu.json
# ============================================================================
param([int]$esik = 2, [switch]$kuru)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$KOK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$raporYol = Join-Path $kok 'veri/bildirim-nobeti-raporu.json'

function Getir($yol){
  $w = Invoke-WebRequest -Uri "$KOK/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  if([int]$w.StatusCode -ge 400){ throw ("Supabase {0}: {1}" -f $w.StatusCode, $ham) }
  return @($ham | ConvertFrom-Json)
}

# --- bakilmamis bildirimler
try {
  $bildirimler = Getir "soru_bildirim?select=id,soru_id,not_metni,oturum,uye,durum,karantina&durum=eq.yeni&order=id&limit=2000"
} catch {
  Write-Host ("Bildirim tablosu okunamadi: {0}" -f $_.Exception.Message)
  Write-Host "veri/sql-soru-bildirim.sql Supabase'de calistirilmis mi?"
  exit 1
}
Write-Host ("Bakilmamis bildirim: {0}" -f $bildirimler.Count)
if($bildirimler.Count -eq 0){
  $bos = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='IS YOK'; bildirim=0 }
  Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $bos -Depth 4) -Encoding UTF8 -NoNewline
  exit 0
}

# --- soru bazinda FARKLI oturum say (ayni kisinin 5 kez basmasi 1 sayilir)
$soruOturum = @{}
$soruBildirimId = @{}
foreach($b in $bildirimler){
  $sid = "$($b.soru_id)"; if($sid.Length -eq 0){ continue }
  $ot = "$($b.oturum)"; if($ot.Length -eq 0){ $ot = "uye:$($b.uye)" }; if($ot -eq 'uye:'){ $ot = "kayit:$($b.id)" }
  if(-not $soruOturum.ContainsKey($sid)){ $soruOturum[$sid] = New-Object 'System.Collections.Generic.HashSet[string]' }
  [void]$soruOturum[$sid].Add($ot)
  if(-not $soruBildirimId.ContainsKey($sid)){ $soruBildirimId[$sid] = New-Object System.Collections.Generic.List[string] }
  $soruBildirimId[$sid].Add("$($b.id)")
}
$esikGecen = @($soruOturum.GetEnumerator() | Where-Object { $_.Value.Count -ge $esik })
Write-Host ("Esigi ({0} farkli aday) gecen soru: {1}" -f $esik, $esikGecen.Count)

$cekilen = New-Object System.Collections.Generic.List[object]
$zatenKapali = 0; $hata = 0
foreach($e in $esikGecen){
  $sid = $e.Key
  try {
    $s = Getir ("soru_havuzu?select=id,ders,konu,yayin&id=eq." + [uri]::EscapeDataString($sid))
    if($s.Count -eq 0){ continue }
    if($s[0].yayin -ne $true){ $zatenKapali++; continue }
    if($kuru){
      $cekilen.Add([ordered]@{ id=$sid; ders="$($s[0].ders)"; konu="$($s[0].konu)"; bildirim=$e.Value.Count; islem='KURU KOSU - cekilmedi' })
      continue
    }
    # yayindan cek - PATCH ile yalniz iki kolon (kismi-upsert NOT NULL tuzagi)
    $govde = @{ yayin = $false; yayin_notu = ("Ogrenci bildirimi ile karantinaya alindi ({0} farkli aday) - {1}" -f $e.Value.Count, (Get-Date -Format 'dd.MM.yyyy HH:mm')) } | ConvertTo-Json -Compress
    $w = Invoke-WebRequest -Uri ("$KOK/soru_havuzu?id=eq." + [uri]::EscapeDataString($sid)) -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
    if([int]$w.StatusCode -ge 400){
      $hata++
      $g = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
      Write-Host ("  {0} CEKILEMEDI: {1} {2}" -f $sid, $w.StatusCode, $g); continue
    }
    # bildirimleri karantina=true olarak isaretle (durum 'yeni' kalir - GM bakacak)
    foreach($bid in $soruBildirimId[$sid]){
      $g2 = @{ karantina = $true } | ConvertTo-Json -Compress
      Invoke-WebRequest -Uri "$KOK/soru_bildirim?id=eq.$bid" -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($g2)) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck | Out-Null
    }
    $cekilen.Add([ordered]@{ id=$sid; ders="$($s[0].ders)"; konu="$($s[0].konu)"; bildirim=$e.Value.Count; islem='YAYINDAN CEKILDI' })
    Write-Host ("  CEKILDI: {0} [{1} / {2}] - {3} farkli aday bildirdi" -f $sid, $s[0].ders, $s[0].konu, $e.Value.Count)
  } catch { $hata++; Write-Host ("  {0} hata: {1}" -f $sid, $_.Exception.Message) }
}

# --- GM'nin okuyacagi liste: esigi gecmemis TEK bildirimler de gorunur olsun
$tekBildirim = New-Object System.Collections.Generic.List[object]
foreach($e in $soruOturum.GetEnumerator()){
  if($e.Value.Count -ge $esik){ continue }
  $ilk = @($bildirimler | Where-Object { "$($_.soru_id)" -eq $e.Key } | Select-Object -First 1)
  if($ilk.Count -gt 0){
    $n = "$($ilk[0].not_metni)"; if($n.Length -gt 200){ $n = $n.Substring(0,200) }
    $tekBildirim.Add([ordered]@{ id=$e.Key; bildirim=$e.Value.Count; not=$n })
  }
}

$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($kuru){'KURU KOSU'}else{'CANLI'})
  esik = $esik
  bakilmamis_bildirim = $bildirimler.Count
  bildirilen_soru = $soruOturum.Count
  esigi_gecen = $esikGecen.Count
  yayindan_cekilen = $cekilen.Count
  zaten_yayinda_degil = $zatenKapali
  hata = $hata
  cekilenler = $cekilen.ToArray()
  tek_bildirimli_sorular = $tekBildirim.ToArray()
  not = "Esigi gecen soru kendiliginden yayindan cekildi (H5: once cek, sonra tartis). Bildirimlerin durumu 'yeni' kaldi - GM okuyup hakli/haksiz karari verecek (H7: 48 saat)."
}
$j = ConvertTo-Json -InputObject $ozet -Depth 6
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $raporYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host ("Yayindan cekilen: {0} | tek bildirimli (izlemede): {1} | hata: {2}" -f $cekilen.Count, $tekBildirim.Count, $hata)
Write-Host ("-> {0}" -f $raporYol)
