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
# Şirket son ekleri (hem başlık-harf "Limited Şirketi" hem TÜM-BÜYÜK "LİMİTED ŞİRKETİ")
$sonEk='Limited Şirketi|Anonim Şirketi|Ltd\.?\s*Şti\.?|Kollektif Şirketi|Komandit Şirketi|LİMİTED ŞİRKETİ|ANONİM ŞİRKETİ|KOLLEKTİF ŞİRKETİ|KOMANDİT ŞİRKETİ|Limited Şti|LİMİTED ŞTİ'
# Bir ünvan kelimesi (büyük harfle başlar; ve/ile/için bağlaçları serbest)
$W='(?:[A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşüİı0-9\.]*|ve|Ve|VE|ile|İle|İLE|için)'
$firmaRx="($W(?:\s+$W){0,15}\s+(?:$sonEk))"
$junk='^(Yukarıda|Sicil|Sayılı\w*|Adresindeki|adresindeki|Olan|olan|Müflis|müflis|Yazılı|yazılı|Numaraları|Numarası|Adres|adres|Nezdinde|Hakkında|Davacılar|Davacı|Davalı|Ve|ve|İle|ile|Sayın|Borçlu|borçlu|Borçlusu|borçlusu|Ait|ait|Esas|Karar|İLAN|İLANI|İlan|İlanı|Alacaklılar|alacaklılar|Toplantısına|toplantısına|Toplantı|Davet|davet|Tebligat|tebligat|Konusu|konusu|Talebinde|talebinde|Bulunan|bulunan|Talep|talep)\s+'
# Etiket-öncelikli kalıplar: hepsi borçluyu AÇIKÇA tanımlar (yanlış firma riski düşük)
$firmaEtiket=@(
  "MÜFLİS\s*:?\s*$firmaRx",
  "olan\s+müflis\s+$firmaRx",
  "adresindeki\s+$firmaRx",
  "müflis\s+$firmaRx",
  "MİRAS\s*BIRAKAN\s*:?\s*$firmaRx",
  "kayıtlı\s+.{0,40}?müflis\s+$firmaRx"
)
# Kişi borçlu (yalnız etiketli): davalı X aleyhine / MÜFLİS : X (  — TCKN ASLA saklanmaz
$kisiEtiket=@(
  "[Dd]aval[ıi]\s+([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ]+(?:\s+[A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ]+){1,3})\s+aleyhine",
  "MÜFLİS\s*:?\s*([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ]+(?:\s+[A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ]+){1,3})\s*[\(,]"
)
function VknGecerli($s){ if($s -notmatch '^\d{10}$'){return $false}; $v=$s.ToCharArray()|%{[int]([string]$_)}; $sum=0; for($i=0;$i -lt 9;$i++){ $tmp=($v[$i]+(9-$i))%10; $sum+=$(if($tmp -eq 9){9}else{($tmp*[Math]::Pow(2,9-$i))%9}) }; return $v[9] -eq ((10-($sum%10))%10) }

$obj=Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$ilanlar=@($obj.ilanlar)
$fN=0;$vN=0;$kN=0;$say=0
foreach($x in $ilanlar){
  if($x.tur -ne 'iflas' -and $x.tur -ne 'konkordato'){ continue }
  $id=[regex]::Match("$($x.url)",'/ilan/(\d+)/').Groups[1].Value; if(-not $id){ continue }
  try{ $d=Invoke-RestMethod -Uri "https://www.ilan.gov.tr/api/api/services/app/AdDetail/GetAdDetail?id=$id" -Headers $h -TimeoutSec 30 }catch{ continue }
  $say++
  $c=("$($d.result.content)" -replace "(?s)<style[^>]*>.*?</style>"," " -replace "(?s)<script[^>]*>.*?</script>"," " -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
  # FİRMA — önce etiketli kalıplar (açık müflis beyanı), sonra genel + yakınlık kapısı
  $firma=''; $etiketli=$false
  foreach($lp in $firmaEtiket){ $mm=[regex]::Match($c,$lp); if($mm.Success){ $firma=$mm.Groups[1].Value.Trim(); $etiketli=$true; break } }
  if(-not $firma){
    $m=[regex]::Match($c,$firmaRx)
    if($m.Success){ $cand=$m.Groups[1].Value.Trim(); while($cand -match $junk){ $cand=($cand -replace $junk,'').Trim() }
      $pos=$c.IndexOf($cand); if($pos -ge 0){ $son=$c.Substring($pos,[Math]::Min(180,$c.Length-$pos)); if($son -match '(?i)iflas|tasfiye|konkordato|müflis'){ $firma=$cand } } }
  }
  # etiketli firmayı da çöp önekten arındır + son ek doğrula (yaz kapısı)
  if($firma){ while($firma -match $junk){ $firma=($firma -replace $junk,'').Trim() } }
  # Etiketli (açık müflis beyanı) uzun ünvanlara izin ver (130); belirsiz fallback'te 95.
  $tavan = if($etiketli){130}else{95}
  $g1 = $firma -and $firma.Length -ge 6 -and $firma.Length -le $tavan -and ($firma -match "(?i)(Şirketi|Şti\.?)\s*$") -and ($firma -notmatch '(?i)^(sayılı|adres|olan|müflis|yazılı|ve |sicil|davac|ait)')
  if($g1){ $x | Add-Member -NotePropertyName borclu -NotePropertyValue $firma -Force; $fN++ }
  else {
    # KİŞİ borçlu (firma yoksa): yalnız açık etiketten, TCKN yazılmaz
    $kisi=''
    foreach($kp in $kisiEtiket){ $km=[regex]::Match($c,$kp); if($km.Success){ $kisi=($km.Groups[1].Value -replace '\s+',' ').Trim(); break } }
    if($kisi -and $kisi.Length -ge 5 -and $kisi.Length -le 45 -and ($kisi -notmatch '(?i)şirket|müdürl|mahkeme|daire|icra|ticaret sicil')){
      $x | Add-Member -NotePropertyName borclu -NotePropertyValue $kisi -Force; $kN++
    }
  }
  # VKN (yalnız tek geçerli; TCKN 11 hane olduğundan \b\d{10}\b'e takılmaz)
  $vkn=@([regex]::Matches($c,'\b\d{10}\b')|ForEach-Object{$_.Value}|Select-Object -Unique|Where-Object{VknGecerli $_})
  if($vkn.Count -eq 1){ $x | Add-Member -NotePropertyName vkn -NotePropertyValue $vkn[0] -Force; $vN++ }
  Start-Sleep -Milliseconds 200
}
Write-Host ("Taranan iflas/konkordato: {0} · firma: {1} · kişi: {2} · VKN: {3}" -f $say,$fN,$kN,$vN)
($obj | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
# geri oku (yaz->oku->karsilastir)
$geri=Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$bGeri=@($geri.ilanlar | Where-Object { $_.borclu }).Count
Write-Host ("-> yazildi, geri okumada borclu'lu ilan: {0}" -f $bGeri)
