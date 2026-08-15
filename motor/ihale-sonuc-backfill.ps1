# ============================================================================
#  SONUC ILANI BACKFILL (15.08.2026) - Cem "backfili 24 aylik yapsak daha iyi".
#
#  NEDEN: "bu is gercekte kaca yapiliyor" istatistigi az ornekten (n) besleniyor;
#  gecmis SONUC ilanlarini biriktirince gruplar n>=10'u gecip guvenilir olur.
#  Kirim bir ORAN (%) oldugu icin enflasyondan bagimsiz - 24 ay eskimeeden ise yarar.
#
#  NASIL: her IS GUNU icin bulteni ARSIVDEN indir (-Tarih), SONUC ayristir -Yaz
#  (ambara IKN+sozlesme anahtariyla mukerrersiz birlesir). RESUMABLE: yapilan
#  gunler veri/ihale-backfill-gunlog.json'da; tekrar kosulunca kaldigi yerden.
#  THROTTLE: iki gun arasi bekleme (KIK sunucusuna nazik). Hafta sonu atlanir.
#
#  KULLANIM:
#    ./ihale-sonuc-backfill.ps1 -Gun 5            # en yeni 5 (yapilmamis) is gunu - dogrulama
#    ./ihale-sonuc-backfill.ps1 -AyGeri 24        # 24 ay tamami (uzun surer)
#    ./ihale-sonuc-backfill.ps1 -AyGeri 24 -Gun 20  # bu kosuda en fazla 20 gun (Actions parcali)
# ============================================================================
param(
  [int]$AyGeri = 24,
  [int]$Gun = 0,               # bu kosuda islenecek azami is gunu (0 = aralik boyunca hepsi)
  [double]$BeklemeSn = 2.0,    # iki gun arasi bekleme (KIK'e nazik)
  [string[]]$Turler = @('Mal','Yapim','Hizmet')
)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$hasat  = Join-Path $here "ihale-bulten-hasat.ps1"
$ayristir = Join-Path $here "ihale-sonuc-ayristir.ps1"
$ambar  = Join-Path $kok "veri\ihale-sonuc.json"
$logYol = Join-Path $kok "veri\ihale-backfill-gunlog.json"

function AmbarSay(){ if(-not (Test-Path $ambar)){ return 0 }; try{ return @((Get-Content $ambar -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar).Count }catch{ return 0 } }

# yapilan gunler (resumable)
$yapildi = @{}
if(Test-Path $logYol){ try{ (Get-Content $logYol -Raw -Encoding UTF8 | ConvertFrom-Json).gunler | ForEach-Object { $yapildi["$_"] = $true } }catch{} }

# Date.Now yok - gunu ambar guncelleme damgasindan degil, sistemden alamayiz;
# param disi calismasin diye bugunu -RefTarih ile de verebilelim (Actions'ta UTC).
$bugun = Get-Date
$sinir = $bugun.AddMonths(-$AyGeri)
$baslangicSayi = AmbarSay
Write-Host ("BACKFILL basliyor · ambar simdi: {0} kayit · aralik: {1:dd.MM.yyyy} <- {2:dd.MM.yyyy} · bu kosu azami {3} gun" -f $baslangicSayi, $sinir, $bugun, $(if($Gun){$Gun}else{'hepsi'}))

$d = $bugun.AddDays(-1)
$islenen = 0; $bulunan = 0; $bos = 0
while($d -ge $sinir){
  if($Gun -gt 0 -and $islenen -ge $Gun){ break }
  $wd = $d.DayOfWeek
  if($wd -eq 'Saturday' -or $wd -eq 'Sunday'){ $d = $d.AddDays(-1); continue }
  $ts = $d.ToString('dd.MM.yyyy')
  if($yapildi[$ts]){ $d = $d.AddDays(-1); continue }

  $oncekiSay = AmbarSay
  try{
    & $hasat -Turler $Turler -Tarih $ts *> $null
    & $ayristir -Yaz *> $null
  }catch{ Write-Host ("   ! {0} hata: {1}" -f $ts, $_.Exception.Message) }
  $sonrakiSay = AmbarSay
  $delta = $sonrakiSay - $oncekiSay
  if($delta -gt 0){ $bulunan += $delta } else { $bos++ }
  Write-Host ("  {0} · +{1} kayit (ambar {2})" -f $ts, $delta, $sonrakiSay)

  $yapildi[$ts] = $true
  @{ guncelleme = ("Son islenen: {0}" -f $ts); gunler = @($yapildi.Keys) } | ConvertTo-Json | Out-File $logYol -Encoding utf8
  $islenen++
  $d = $d.AddDays(-1)
  Start-Sleep -Seconds $BeklemeSn
}
$bitisSayi = AmbarSay
Write-Host ("`nBITTI · islenen gun: {0} · yeni kayit: {1} · bos/tekrar gun: {2}" -f $islenen, ($bitisSayi-$baslangicSayi), $bos)
Write-Host ("ambar: {0} -> {1} kayit" -f $baslangicSayi, $bitisSayi)
