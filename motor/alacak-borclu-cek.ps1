# ============================================================================
#  ALACAK BORÇLU ÇEK (15.08.2026) - iflas/konkordato ilanının BORÇLU firma adını
#  ve (tek+geçerliyse) VKN'sini ilan.gov.tr detayından çekip alacak-ilan-canli.json'a
#  ekler. Kart "Ek sıra cetveli ilanı" yerine "X A.Ş. — Ek sıra cetveli" gösterir.
#
#  Cem "aman farklı firma batmış gibi göstermeyelim, veri çekince bir kere kontrol":
#  DÖRT KONTROL KAPISI, hiçbiri geçmezse firma/VKN HİÇ yazılmaz (boş=güvenli):
#   1) Ünvan büyük-harf dizisiyle bitmeli (…Limited Şirketi / Anonim Şirketi …)
#   2) Baştaki kalıp çöpü (Yukarıda/Sicil/Sayılı/olan/müflis/Davacılar…) atılır
#   3) Ünvan metinde iflas/tasfiye/konkordato/müflis'e YAKIN olmalı (=müflis mi?)
#   4) VKN yalnız TEK geçerli (checksum) VKN varsa; birden çoksa (sıra cetveli =
#      alacaklı VKN'leri) YAZILMAZ, karışmasın.
#  Detay çekme mekanizması ihale-yurtici-hasat'la aynı (GetAdDetail API).
# ============================================================================
$ErrorActionPreference="Continue"
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$yol=Join-Path $kok "veri\alacak-ilan-canli.json"
if(-not (Test-Path $yol)){ Write-Host "alacak-ilan-canli.json yok"; exit 0 }
$h=@{ "User-Agent"="Mozilla/5.0 (MevzuatRadar-Alacak)"; "Accept"="application/json" }
$sonEk='Limited Şirketi|Anonim Şirketi|Ltd\.?\s*Şti\.?|Kollektif Şirketi|Komandit Şirketi'
$rx="((?:[A-ZÇĞİÖŞÜİ][A-Za-zÇĞİÖŞÜçğıöşüİı0-9]*|ve|ile|için)(?:\s+(?:[A-ZÇĞİÖŞÜİ][A-Za-zÇĞİÖŞÜçğıöşüİı0-9]*|ve|ile|için))*\s+(?:$sonEk))"
$junk='^(Yukarıda|Sicil|Sayılı\w*|Adresindeki|adresindeki|Olan|olan|Müflis|müflis|Yazılı|yazılı|Numaraları|Adres|adres|Nezdinde|Hakkında|Davacılar|Davacı|Davalı|Ve|ve|İle|ile|Sayın|Borçlu|borçlu)\s+'
function VknGecerli($s){ if($s -notmatch '^\d{10}$'){return $false}; $v=$s.ToCharArray()|%{[int]([string]$_)}; $sum=0; for($i=0;$i -lt 9;$i++){ $tmp=($v[$i]+(9-$i))%10; $sum+=$(if($tmp -eq 9){9}else{($tmp*[Math]::Pow(2,9-$i))%9}) }; return $v[9] -eq ((10-($sum%10))%10) }

$obj=Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$ilanlar=@($obj.ilanlar)
$fN=0;$vN=0;$say=0
foreach($x in $ilanlar){
  if($x.tur -ne 'iflas' -and $x.tur -ne 'konkordato'){ continue }
  $id=[regex]::Match("$($x.url)",'/ilan/(\d+)/').Groups[1].Value; if(-not $id){ continue }
  try{ $d=Invoke-RestMethod -Uri "https://www.ilan.gov.tr/api/api/services/app/AdDetail/GetAdDetail?id=$id" -Headers $h -TimeoutSec 30 }catch{ continue }
  $say++
  $c=("$($d.result.content)" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
  # FİRMA
  $firma=''; $m=[regex]::Match($c,$rx)
  if($m.Success){ $firma=$m.Groups[1].Value.Trim(); while($firma -match $junk){ $firma=($firma -replace $junk,'').Trim() } }
  $g1 = $firma -and $firma.Length -ge 6 -and $firma.Length -le 90 -and ($firma -match "(?i)($sonEk)\s*$") -and ($firma -notmatch '(?i)^(sayılı|adres|olan|müflis|yazılı|ve |sicil|davac)')
  $g2=$false
  if($g1){ $pos=$c.IndexOf($firma); if($pos -ge 0){ $son=$c.Substring($pos,[Math]::Min(170,$c.Length-$pos)); $g2 = $son -match '(?i)iflas|tasfiye|konkordato|müflis' } }
  if($g1 -and $g2){ $x | Add-Member -NotePropertyName borclu -NotePropertyValue $firma -Force; $fN++ }
  # VKN (yalnız tek geçerli)
  $vkn=@([regex]::Matches($c,'\b\d{10}\b')|ForEach-Object{$_.Value}|Select-Object -Unique|Where-Object{VknGecerli $_})
  if($vkn.Count -eq 1){ $x | Add-Member -NotePropertyName vkn -NotePropertyValue $vkn[0] -Force; $vN++ }
  Start-Sleep -Milliseconds 250
}
Write-Host ("Taranan iflas/konkordato: {0} · borclu eklendi: {1} · VKN eklendi: {2}" -f $say,$fN,$vN)
($obj | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
# geri oku (yaz->oku->karsilastir)
$geri=Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$bGeri=@($geri.ilanlar | Where-Object { $_.borclu }).Count
Write-Host ("-> yazildi, geri okumada borclu'lu ilan: {0}" -f $bGeri)
