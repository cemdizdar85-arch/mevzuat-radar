# ============================================================================
#  K16 - TABLO/YEVMIYE DENETIMI (13.08.2026) — 0 USD, API YOK, YAZMA YOK
#  CEM: "tablo ile anlatacaktik, o tabloyu kontrol etmek lazim."
#  Sozun karsiligi olculur: tablo VAR MI, tablo DOGRU MU?
#   V1) VARLIK: hesapli/muhasebe sorusunda tablo veya yevmiye kaydi var mi?
#   V2) YAPI: kolon sayisi ile satir hucre sayisi uyusuyor mu? bos tablo?
#   V3) DENGE: yevmiye kaydinda BORC = ALACAK mi (dengesiz kayit = KIRMIZI)
#   V4) TUTARLILIK: tablodaki rakamlar soru/aciklama metninde geciyor mu
#       (tabloda 1.847.600 varsa metinde de olmali - uydurma tablo kapisi)
#  Kapsam: yayin adaylari (varsayilan) | -tumKasa
#  Cikti: veri/k16-tablo-denetimi.json
# ============================================================================
param([switch]$tumKasa)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri\k16-tablo-denetimi.json'
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$B = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ADRES = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

$hedefSet = $null
if(-not $tumKasa){
  $liste = (Get-Content (Join-Path $kok 'veri\yayin-kapisi-temiz-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json).idler
  $hedefSet = @{}; foreach($x in $liste){ $hedefSet["$($x.id)"] = $true }
}
$kayitlar = New-Object System.Collections.Generic.List[object]
$SAYFA = 400   # 500 hatasi: tablo/yevmiye kolonlariyla 1000'lik sayfa agir geliyor
for($of=0; $of -lt 40000; $of+=$SAYFA){
  $j = $null
  for($d=1; $d -le 3; $d++){
    try{
      $r = Invoke-WebRequest -UseBasicParsing -Uri "$ADRES/soru_havuzu?select=id,ders,soru,aciklama,tablo,yevmiye&order=id&limit=$SAYFA&offset=$of" -Headers $B -TimeoutSec 180
      $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json); break
    } catch { if($d -eq 3){ Write-Host ("  UYARI: offset {0} cekilemedi ({1}) - atlandi" -f $of, $_.Exception.Message); $j=@() } else { Start-Sleep -Seconds (2*$d) } }
  }
  if(@($j).Count -eq 0){ if($of -gt 30000){ break } else { continue } }
  foreach($s in $j){ if($null -eq $hedefSet -or $hedefSet.ContainsKey("$($s.id)")){ $kayitlar.Add($s) } }
  if(@($j).Count -lt $SAYFA){ break }
}
Write-Host ("Cekilen: {0} soru" -f $kayitlar.Count)

function Duz([object]$o){ if($null -eq $o){ return '' }; if($o -is [string]){ return $o }; $p=New-Object System.Collections.Generic.List[string]; try{ if($o -is [System.Collections.IEnumerable]){ foreach($e in $o){ $p.Add((Duz $e)) } } else { foreach($x in $o.PSObject.Properties){ $p.Add((Duz $x.Value)) } } } catch { $p.Add("$o") }; return ($p -join ' ') }
# 13.08: fonksiyon bazen $null donuyordu (bos HashSet PowerShell'de pipeline'da
# duserek null'a cevriliyor) -> Contains cagrisi patliyordu. Virgul ile SARMALA:
# ,$s tek elemanli dizi olarak dondurur, HashSet bozulmadan gelir.
function Sayilar([string]$m){ $s=New-Object 'System.Collections.Generic.HashSet[string]'; if($m){ foreach($x in [regex]::Matches($m,'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d{4,}')){ [void]$s.Add(($x.Value -replace '[.,]','')) } }; return ,$s }

$reHesapli = [regex]'(?i)\bTL\b|tutar|hesapla|oran[ıi]n[ıi]|kay[ıi]t|yevmiye|maliyet|amortisman'
$v1eksik=@(); $v2bozuk=@(); $v3dengesiz=@(); $v4uydurma=@(); $tabloVar=0; $yevmiyeVar=0
foreach($s in $kayitlar){
  $metin = "$($s.soru) " + (Duz $s.aciklama)
  $tv = ($null -ne $s.tablo -and "$($s.tablo)" -ne ''); $yv = ($null -ne $s.yevmiye -and (Duz $s.yevmiye).Trim() -ne '')
  if($tv){ $tabloVar++ }; if($yv){ $yevmiyeVar++ }

  # V1 varlik
  if($reHesapli.IsMatch($metin) -and -not $tv -and -not $yv){
    $rakam = (Sayilar $s.soru).Count
    if($rakam -ge 3){ $v1eksik += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; rakam=$rakam } }
  }
  # V2 yapi
  if($tv){
    try{
      $kol = @($s.tablo.kolonlar).Count; $sat = @($s.tablo.satirlar)
      if($kol -eq 0 -or $sat.Count -eq 0){ $v2bozuk += [pscustomobject]@{ id="$($s.id)"; sorun='bos tablo' } }
      else { foreach($r2 in $sat){ if(@($r2).Count -ne $kol){ $v2bozuk += [pscustomobject]@{ id="$($s.id)"; sorun="kolon $kol / hucre $(@($r2).Count)" }; break } } }
    } catch { $v2bozuk += [pscustomobject]@{ id="$($s.id)"; sorun='okunamadi' } }
  }
  # V3 denge (yevmiye: borc/alacak sutunlari)
  if($yv){
    $yd = Duz $s.yevmiye
    $borc=0.0; $alacak=0.0; $bulundu=$false
    try{
      foreach($sat2 in @($s.yevmiye)){
        $hucre = @()
        if($sat2 -is [System.Collections.IEnumerable] -and $sat2 -isnot [string]){ $hucre = @($sat2) } else { $hucre = @("$sat2") }
        if($hucre.Count -ge 3){
          $b1 = ("$($hucre[$hucre.Count-2])" -replace '[^\d,]','') -replace ',','.'
          $a1 = ("$($hucre[$hucre.Count-1])" -replace '[^\d,]','') -replace ',','.'
          if($b1 -match '\d'){ $borc += [double]$b1; $bulundu=$true }
          if($a1 -match '\d'){ $alacak += [double]$a1; $bulundu=$true }
        }
      }
      if($bulundu -and $borc -gt 0 -and $alacak -gt 0){
        $fark = [math]::Abs($borc-$alacak)
        if($fark -gt 0.5){ $v3dengesiz += [pscustomobject]@{ id="$($s.id)"; borc=$borc; alacak=$alacak; fark=$fark } }
      }
    } catch {}
  }
  # V4 tutarlilik: tablodaki buyuk sayilar metinde var mi
  if($tv){
    $tabloSayi = Sayilar (Duz $s.tablo); $metinSayi = Sayilar $metin
    $yok = @($tabloSayi | Where-Object { $_.Length -ge 4 -and -not $metinSayi.Contains($_) })
    if($yok.Count -ge 2){ $v4uydurma += [pscustomobject]@{ id="$($s.id)"; metinde_olmayan=@($yok | Select-Object -First 5) } }
  }
}
$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm'); kapsam=$(if($tumKasa){'tum-kasa'}else{'yayin-adaylari'}); soru=$kayitlar.Count
  tablo_olan=$tabloVar; yevmiye_olan=$yevmiyeVar
  V1_gorsel_eksik=[ordered]@{ adet=$v1eksik.Count; not='3+ rakam iceren hesapli soruda tablo/yevmiye YOK - Cem sozu: hesapli soru tabloyla anlatilir'; ornek=@($v1eksik | Select-Object -First 25); idler=@($v1eksik | ForEach-Object { $_.id }) }
  V2_yapi_bozuk=[ordered]@{ adet=$v2bozuk.Count; ornek=@($v2bozuk | Select-Object -First 25); idler=@($v2bozuk | ForEach-Object { $_.id }) }
  V3_dengesiz_yevmiye=[ordered]@{ adet=$v3dengesiz.Count; ornek=@($v3dengesiz | Select-Object -First 25); idler=@($v3dengesiz | ForEach-Object { $_.id }) }
  V4_tabloda_uydurma_rakam=[ordered]@{ adet=$v4uydurma.Count; not='tablodaki 4+ haneli sayi soru/aciklama metninde hic gecmiyor'; ornek=@($v4uydurma | Select-Object -First 25); idler=@($v4uydurma | ForEach-Object { $_.id }) }
  not='K16 OLCER, karar vermez. Her aday okuyucu hattinda elle dogrulanir.'
}
[IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("TABLO/YEVMIYE VAR : tablo {0} · yevmiye {1} (toplam {2} soruda)" -f $tabloVar, $yevmiyeVar, $kayitlar.Count)
Write-Host ("V1 gorsel eksik   : {0}" -f $v1eksik.Count)
Write-Host ("V2 yapi bozuk     : {0}" -f $v2bozuk.Count)
Write-Host ("V3 dengesiz kayit : {0}" -f $v3dengesiz.Count)
Write-Host ("V4 uydurma rakam  : {0}" -f $v4uydurma.Count)
Write-Host ("-> {0}" -f $ciktiYol)
