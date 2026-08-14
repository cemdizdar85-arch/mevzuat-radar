# ============================================================================
#  KAMU IHALE BULTENI - GERIYE DONUK ARSIV DOLDURMA (14.08.2026)
#
#  Cem: "EKAP isini cozersek super olacak, ordaki bilgileri almamiz lazim."
#
#  NEDEN GEREKLI (olculdu, tahmin degil):
#    Bugunun bulteni  = 262 ilan
#    ilan.gov.tr havuzu = 250 acik ihale
#    IKN ile eslesen    = 11        <-- yani %4
#  Sebep bilgi yoklugu DEGIL: 4734 m.13'e gore ihaleler ihale tarihinden 7-40
#  GUN ONCE ilan ediliyor. Yani bugun acik olan ihalelerin ilani GECMIS gunlerin
#  bulteninde. Tek gunluk bulten yapisi geregi eksik kalir.
#
#  NASIL (yeni kapi zorlanmadi):
#    KIK'in bulten indirme sayfasindaki tarih alanina (etBultenTarihi) tarih
#    yazilinca o gunun bulteni geliyor. 11.08.2026 ile sinandi: 11.236.861
#    baytlik gecerli ZIP. EKAP'in korumali uclarina (401 arama API'si, 406 v2)
#    DOKUNULMAZ; bu, KIK'in indirilmek uzere yayimladigi resmi bultenin arsivi.
#
#  KAYNAGA NAZIK: gunler arasi bekleme var, tek koside sinirli gun cekilir,
#  ayni gun ikinci kez cekilmez (havuzda o tarih varsa atlanir).
#
#  Ayristirici havuzu BIRIKIMLI tuttugu icin her gun uzerine eklenir; ayni IKN
#  tekrar gelirse yeni kayit eskisini gunceller.
# ============================================================================
param(
  [int]$Gun = 10,                         # kac IS gunu geriye gidilecek
  [string[]]$Turler = @('Mal','Yapim','Hizmet'),
  [switch]$Yaz,                           # verilmezse hicbir dosya yazilmaz
  [int]$BeklemeSn = 4                     # gunler arasi bekleme (kaynaga nazik)
)
$ErrorActionPreference = "Continue"
if($PSVersionTable.PSVersion.Major -lt 6){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$hasat = Join-Path $here "ihale-bulten-hasat.ps1"
$ayir  = Join-Path $here "ihale-ilan-ayristir.ps1"
foreach($b in @($hasat,$ayir)){ if(-not (Test-Path $b)){ Write-Host "BULUNAMADI: $b"; exit 1 } }

# --- havuzda hangi bulten gunleri zaten var? (ayni gunu iki kez cekme) -------
$havuzYol = Join-Path $kok "veri\ihale-bulten-ilan.json"
$mevcutGunler = @{}
if(Test-Path $havuzYol){
  try {
    foreach($x in @((Get-Content $havuzYol -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar)){
      if($x.ilanTarih){ $mevcutGunler["$($x.ilanTarih)"] = 1 }
    }
  } catch {}
}
Write-Host ("Havuzda zaten olan bulten gunu: {0}" -f $mevcutGunler.Count)
if($mevcutGunler.Count){ Write-Host ("   " + (($mevcutGunler.Keys | Sort-Object) -join ', ')) }

# --- geriye dogru IS gunleri (bulten hafta sonu yayimlanmaz) ----------------
$hedefler = @()
$g = (Get-Date).Date
$sayac = 0
while($hedefler.Count -lt $Gun -and $sayac -lt 60){
  $sayac++
  $g = $g.AddDays(-1)
  if($g.DayOfWeek -in @([DayOfWeek]::Saturday,[DayOfWeek]::Sunday)){ continue }
  $ts = $g.ToString('dd.MM.yyyy')
  if($mevcutGunler.ContainsKey($ts)){ Write-Host ("   atlandi (havuzda var): {0}" -f $ts); continue }
  $hedefler += $ts
}
if(-not $hedefler.Count){ Write-Host "`nCekilecek yeni gun yok."; exit 0 }
Write-Host ("`nCekilecek {0} gun: {1}" -f $hedefler.Count, ($hedefler -join ', '))
if(-not $Yaz){ Write-Host "`n(olcum modu - gercekten cekmek icin -Yaz)"; exit 0 }

$basari = 0; $bos = 0
foreach($t in $hedefler){
  Write-Host ("`n===== {0} =====" -f $t)
  & $hasat -Turler $Turler -Tarih $t -Klasor (Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten") 2>&1 |
    Where-Object { $_ -match 'ilan|BULTEN|alinamadi|hata|dustu' } | ForEach-Object { Write-Host ("   " + $_) }
  # ayristirici scratchpad'deki bulten-*.txt dosyalarini okur; hasat onlari
  # az once o gunun bulteniyle DEGISTIRDI. Havuz birikimli oldugu icin ekler.
  $ck = & $ayir -Yaz 2>&1
  $satir = @($ck | Where-Object { $_ -match 'HAVUZ|ilan ayristirildi|Bulten:' })
  foreach($s in $satir){ Write-Host ("   " + $s) }
  if($ck -match 'Hic ilan cikmadi'){ $bos++ } else { $basari++ }
  Start-Sleep -Seconds $BeklemeSn
}

Write-Host ("`n=== ARSIV DOLDURMA BITTI: {0} gun basarili, {1} gun bos ===" -f $basari, $bos)
# --- son durum: havuz ve eslesme -------------------------------------------
try {
  $h = Get-Content $havuzYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $il = @($h.ilanlar)
  $gunler = @{}; foreach($x in $il){ if($x.ilanTarih){ $gunler["$($x.ilanTarih)"] = 1 + $(if($gunler["$($x.ilanTarih)"]){$gunler["$($x.ilanTarih)"]}else{0}) } }
  Write-Host ("`nHAVUZ: {0} ilan · {1} bulten gunu" -f $il.Count, $gunler.Count)
  $gunler.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host ("   {0} -> {1} ilan" -f $_.Key, $_.Value) }
  # ilan.gov.tr ile eslesme (asil olcu bu)
  $yi = Get-Content (Join-Path $kok "veri\ihale-yurtici.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $set = @{}; foreach($x in $il){ if($x.ikn){ $set["$($x.ikn)".Trim()] = 1 } }
  $iknli = @($yi.ilanlar | Where-Object { $_.detay -and $_.detay.ikn })
  $es = @($iknli | Where-Object { $set["$($_.detay.ikn)".Trim()] })
  Write-Host ("`nESLESME: ilan.gov.tr'de IKN'si olan {0} ilanin {1}'i bultende bulundu (%{2})" -f $iknli.Count, $es.Count, [math]::Round(100.0*$es.Count/[math]::Max(1,$iknli.Count)))
} catch { Write-Host ("son durum okunamadi: " + $_.Exception.Message) }
