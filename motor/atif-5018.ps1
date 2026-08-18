# ============================================================================
#  5018 YANLIS ATIF OLCUMU - 19.08.2026 (Cem: "1089 yanlis atif isine basla")
#
#  BULGU (16.08 damga denetimi + ders-kanun kapisi): "cari oran hesaplama"
#  gibi ozel-sektor bilanco analizi sorulari 5018 s. Kamu Mali Yonetimi K.
#  m.3'e (kamu idareleri tanim cetveli) dayanak yapilmis. Kota-v2 #16-#26
#  partilerine yayilmis sistematik kusur. Hakem yanlis metinle yargilar.
#
#  BU BETIK YALNIZ OLCER, HICBIR SEY YAZMAZ. Cikti veri/atif-5018-olcum.json:
#   - 5018'e bagli TUM sorularin metaverisi (id/sinav/ders/konu/kaynak/madde/uretim)
#   - dagilimlar (ders, madde_no, konu, kaynak kaligi, uretim partisi)
#   - SAGLIKLI KIYAS: ayni konudaki 5018-DISI sorular hangi kanun_no kullaniyor?
#     (duzeltmenin hedef degeri tahminle degil bu dagilimla secilecek)
#  Soru METNI cekilmez/yazilmaz (parali icerik public depoya girmez).
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY (Actions).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$raporYol = Join-Path $kok 'veri/atif-5018-olcum.json'

trap {
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - atlandi.'; exit 0 }
$H = @{ apikey=$KEY; Authorization=("Bearer "+$KEY) }

# --- 1) 5018'e bagli tum sorular (sayfali) ---------------------------------
$satirlar = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $r = Invoke-RestMethod -Uri ("$U`?select=id,sinav,ders,konu,kaynak,kanun_no,madde_no,uretim,yayin&kanun_no=eq.5018&order=id&limit=1000&offset=$bas") -Headers $H -TimeoutSec 120
  $sayfa = @($r | Where-Object { $null -ne $_ })
  if($sayfa.Count -eq 0){ break }
  foreach($s in $sayfa){ $satirlar.Add($s) }
  if($sayfa.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("5018'e bagli soru: {0} (16.08 olcumu 1.089 demisti)" -f $satirlar.Count)

function Dagit($liste, [scriptblock]$anahtar){
  $d = @{}
  foreach($x in $liste){ $k = & $anahtar $x; if([string]::IsNullOrWhiteSpace("$k")){ $k='(bos)' }; if($d.ContainsKey("$k")){ $d["$k"]++ } else { $d["$k"]=1 } }
  $sirali = [ordered]@{}
  foreach($p in ($d.GetEnumerator() | Sort-Object -Property Value -Descending)){ $sirali[$p.Key] = $p.Value }
  return $sirali
}

$dersD   = Dagit $satirlar { param($x) $x.ders }
$maddeD  = Dagit $satirlar { param($x) $x.madde_no }
$konuD   = Dagit $satirlar { param($x) $x.konu }
$kaynakD = Dagit $satirlar { param($x) $x.kaynak }
$uretimD = Dagit $satirlar { param($x) $x.uretim }
$sinavD  = Dagit $satirlar { param($x) $x.sinav }
$yayinda = @($satirlar | Where-Object { $_.yayin -eq $true }).Count

function IlkN($sirali, [int]$n){
  $c = [ordered]@{}; $i=0
  foreach($p in $sirali.GetEnumerator()){ if($i -ge $n){ break }; $c[$p.Key]=$p.Value; $i++ }
  return $c
}

# --- 2) SAGLIKLI KIYAS: en sik 12 konunun 5018-DISI kanun_no dagilimi ------
$kiyas = [ordered]@{}
$i = 0
foreach($p in $konuD.GetEnumerator()){
  if($i -ge 12){ break }; $i++
  $konu = "$($p.Key)"; if($konu -eq '(bos)'){ continue }
  $enc = [uri]::EscapeDataString($konu)
  try {
    $r = Invoke-RestMethod -Uri ("$U`?select=kanun_no&konu=eq.$enc&kanun_no=not.eq.5018&limit=1000") -Headers $H -TimeoutSec 120
    $dis = @($r | Where-Object { $null -ne $_ })
    $kiyas[$konu] = [ordered]@{ soru_5018=$p.Value; dis_toplam=$dis.Count; dis_kanun_no=(Dagit $dis { param($x) $x.kanun_no }) }
  } catch { $kiyas[$konu] = [ordered]@{ soru_5018=$p.Value; hata="$($_.Exception.Message)" } }
  Start-Sleep -Milliseconds 200
}

[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'
  toplam_5018=$satirlar.Count; su_an_yayinda=$yayinda
  sinav_dagilimi=$sinavD; ders_dagilimi=$dersD; madde_dagilimi=(IlkN $maddeD 15)
  konu_dagilimi=(IlkN $konuD 40); kaynak_kaliplari=(IlkN $kaynakD 30); uretim_dagilimi=(IlkN $uretimD 30)
  saglikli_kiyas=$kiyas
  idler=@($satirlar | ForEach-Object { "$($_.id)" })
  not='OLCUM - hicbir sey yazilmadi. Duzeltme hedefi saglikli_kiyas dagilimindan secilecek; uygulama ayri karar/betik.'
}) -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("Rapor yazildi: {0} satir, yayinda {1}" -f $satirlar.Count, $yayinda)
