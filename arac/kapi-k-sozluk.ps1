# KAPI-K KÖK SÖZLÜĞÜ (10.09.2026, GM Borçlar t2b) — 0 USD, model çağrısı YOK.
# NE YAPAR: üreticinin KAPI-K penceresini (motor/kalip-parti-uret.ps1, PencereKavram + PENCERE_KOK) ambardan BİREBİR yeniden kurar,
#   böylece "bu soru sınav dilinin dışında mı" sorusu BASIMDAN ÖNCE, bedelsiz ölçülebilir.
# NEDEN: 10.09 GM Borçlar t2b koşusunda düşen 6 sorunun 6'sı da bu kapıdan düştü ve ön denetim hepsine 'ok' demişti — çünkü
#   hazir-soru-denetle.ps1 sözlüğü DIŞARIDAN (-Sozluk) istiyordu ve o sözlüğü üreten bir araç yoktu. Kapı koşuda yakalanınca
#   ikinci tur bedeli doğuyor; burada yakalanınca bedel sıfır.
# ÜRETİCİYLE AYNI KALMA: ders aralığı tablosu KOPYALANMAZ, motor/kalip-parti-uret.ps1 içindeki $DERS_ARALIK'tan okunur
#   (konu-kaynak-on-olcum.ps1'in OZEL_DESEN'i üreticiden okuma deseninin aynısı). Üretici tabloyu değiştirirse bu araç da değişir.
# KULLANIM (kütüphane):  . arac/kapi-k-sozluk.ps1  →  $s = KapiKSozlukKur -DersRegex 'Borclar Hukuku|Ticaret ve Borclar'
#                        $eksik = KapiKOlc -Metin $soru -Sozluk $s     # boş = sınav dili; >=2 kelime = üretici DÜŞÜRÜR
# ÖNBELLEK: çıkmış kitapçık gövdeleri veri/fabrika/kapi-k-blok-<sinav>.json'a yazılır; dönem listesi değişmedikçe ambara gidilmez.

function KapiKDepoKok {
  $bu = $(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
  return (Split-Path $bu -Parent)
}

# Üreticideki Katla2 ile aynı (Türkçe harf katlama)
function KapiKKatla([string]$s){
  ("$s".ToLowerInvariant() -creplace 'İ','i' -creplace 'I','i').Replace('ı','i').Replace('ğ','g').Replace('ü','u').Replace('ş','s').Replace('ö','o').Replace('ç','c').Replace('â','a').Replace('î','i').Replace('û','u')
}

# Ders -> soru aralığı. Tablo ÜRETİCİDEN okunur; sıra önemlidir (üretici ilk eşleşeni alır).
function KapiKDersAralik([string]$DersRegex,[string]$UreticiYol=''){
  if(-not $UreticiYol){ $UreticiYol = Join-Path (KapiKDepoKok) 'motor\kalip-parti-uret.ps1' }
  if(-not (Test-Path $UreticiYol)){ return $null }
  $ham = Get-Content $UreticiYol -Raw -Encoding UTF8
  $m = [regex]::Match($ham,'\$DERS_ARALIK\s*=\s*@\((?<ic>[\s\S]*?)\r?\n\s*\)')
  if(-not $m.Success){ return $null }
  foreach($c in [regex]::Matches($m.Groups['ic'].Value,"@\('(?<ad>[^']*)'\s*,\s*@\((?<b>\d+)\s*,\s*(?<s>\d+)\)\)")){
    if($DersRegex -match $c.Groups['ad'].Value){ return @([int]$c.Groups['b'].Value,[int]$c.Groups['s'].Value) }
  }
  return $null
}

# Son N dönemin çıkmış kitapçığını ambardan çeker, soru gövdelerine böler.
# Gövde temizliği üreticinin satırlarıyla BİREBİR aynıdır (üç -replace).
function KapiKBloklar([string]$Sinav='SGS',[int]$Pencere=7){
  $kok = KapiKDepoKok
  $anYol = Join-Path $kok ("veri\" + $Sinav.ToLowerInvariant() + "-analiz.json")
  if(-not (Test-Path $anYol)){ return $null }
  $anJ = ConvertFrom-Json -InputObject (Get-Content $anYol -Raw -Encoding UTF8)
  $dList = New-Object System.Collections.Generic.List[object]; $anJ.donemler | ForEach-Object { $dList.Add($_) }
  $sonD = @($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $Pencere)
  $donemAd = @($sonD | ForEach-Object { "$($_.donem)" })

  $onbYol = Join-Path $kok ("veri\fabrika\kapi-k-blok-" + $Sinav.ToLowerInvariant() + ".json")
  if(Test-Path $onbYol){
    try{
      $onb = ConvertFrom-Json -InputObject (Get-Content $onbYol -Raw -Encoding UTF8)
      if(((@($onb.donemler) -join ',') -eq ($donemAd -join ',')) -and @($onb.bloklar).Count){
        return [pscustomobject]@{ donemler=$donemAd; bloklar=@($onb.bloklar | ForEach-Object { $_ }); kaynak='onbellek' }
      }
    }catch{}
  }

  $KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $KEY){ $KEY = $env:SUPABASE_SERVICE_KEY }
  if(-not $KEY){ return $null }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $BASLIK = @{ apikey=$KEY; Authorization="Bearer $KEY" }
  $lst = New-Object System.Collections.Generic.List[object]
  foreach($dn in $sonD){
    $u = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=metin&tur=eq.cikmis-soru&kaynak_ad=ilike.' + [uri]::EscapeDataString("CIKMIS SINAV - $Sinav $($dn.donem) (%ingilizce)") + '&order=kaynak_ad.asc&limit=1'   # 05.10: üreticiyle aynı (order'sız limit=1 rastgele belge, K4)
    $rB = $null
    try{
      $r = Invoke-WebRequest -Uri $u -Headers $BASLIK -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 120
      $j = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))
      $j | ForEach-Object { if(-not $rB){ $rB = $_ } }
    }catch{ $rB = $null }
    if(-not $rB){ continue }
    foreach($p in [regex]::Split("$($rB.metin)",'(?=SORU \d+:)')){
      if($p -match '^SORU (\d+):'){
        $no = [int]$Matches[1]; $govde = $p
        $kes = $govde.IndexOf('TÜRMOB'); if($kes -gt 0){ $govde = $govde.Substring(0,$kes) }
        $govde = $govde -replace '\s+',' '
        $govde = $govde -replace '\s+\d+\s+(İzleyen|Diğer) sayfaya geçiniz\.?.*$','' -replace '\s+STAJA GİRİŞ SINAVI.*$','' -replace '\s+\d+\s+(İzleyen|Diğer) sayfaya geçiniz\.?\s*[A-E]?\s*$',''
        $lst.Add([pscustomobject]@{ no=$no; metin=$govde.Trim() })
      }
    }
  }
  if(-not $lst.Count){ return $null }
  # Önbellek: zaman damgası YOK, yalnız dönem listesi + gövdeler. Kitapçık değişmedikçe dosya da değişmez.
  try{ [IO.File]::WriteAllText($onbYol,(ConvertTo-Json -InputObject ([pscustomobject]@{ donemler=$donemAd; bloklar=@($lst.ToArray()) }) -Depth 4),[Text.UTF8Encoding]::new($false)) }catch{}
  return [pscustomobject]@{ donemler=$donemAd; bloklar=@($lst.ToArray()); kaynak='ambar' }
}

# GENİŞ = pencerenin bütün kitapçıkları · DAR = yalnız dersin soru aralığı (üreticiyle aynı iki sözlük)
function KapiKSozlukKur([Parameter(Mandatory)][string]$DersRegex,[string]$Sinav='SGS',[int]$Pencere=7){
  $b = KapiKBloklar -Sinav $Sinav -Pencere $Pencere
  if(-not $b){ return $null }
  $aralik = KapiKDersAralik -DersRegex $DersRegex
  $genis = @{}; $dar = $(if($aralik){ @{} } else { $null })
  foreach($bl in $b.bloklar){
    $darMi = ($aralik -and [int]$bl.no -ge $aralik[0] -and [int]$bl.no -le $aralik[1])
    foreach($w in ((KapiKKatla $bl.metin) -replace '[^a-z ]+',' ' -split '\s+')){
      if($w.Length -ge 5){ $on = $w.Substring(0,5); $genis[$on] = 1; if($darMi){ $dar[$on] = 1 } }
    }
  }
  return [pscustomobject]@{ genis=$genis; dar=$dar; aralik=$aralik; blok=@($b.bloklar).Count; donemler=$b.donemler; kaynak=$b.kaynak }
}

# ⭐ 05.10.2026 BİTİRME (SMMM) SÖZLÜĞÜ (Cem "1.2.3", gm6 ölçüm koşusu): üretici SMMM'de sözlüğü SGS penceresinden DEĞİL, SMMM TEST
#   kitapçıklarından kurar (GENİŞ = bütün SMMM test kitapçıkları, DAR = dersin kitapçıkları; motor/kalip-parti-uret.ps1 "13.09 SMMM ÇAPA").
#   Bu araç yalnız SGS yolunu biliyordu → gm6'da 15 hazır sorunun 9'u bulutta KAPI-K ile düştü, ön denetim hepsine 'ok' demişti.
#   KOPYA YOK: SmmmTestBloklari / SmmmDersKodu / Katla2 üreticiden AST ile alınır (üretici değişirse bu da değişir).
#   🚫 GÖRMEZ: bulut koşusu anındaki kitapçık listesi (ambar arada değişirse) · üretici kitapçık çekemezse KAPI-K'yı bulutta KAPATIR (KÖR), burada ise null döner.
function KapiKSmmmSozlukKur([Parameter(Mandatory)][string]$DersRegex){
  $uy = Join-Path (KapiKDepoKok) 'motor\kalip-parti-uret.ps1'; if(-not (Test-Path $uy)){ return $null }
  $tk=$null; $hk=$null; $ast=[System.Management.Automation.Language.Parser]::ParseFile($uy,[ref]$tk,[ref]$hk)
  $gerek=@('Katla2','SmmmDersKodu','SmmmTestBloklari')
  $fn=@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true) | Where-Object { $gerek -contains $_.Name })
  if($fn.Count -lt $gerek.Count){ return $null }
  $KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $KEY){ $KEY = $env:SUPABASE_SERVICE_KEY }; if(-not $KEY){ return $null }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }; $script:SMMM_BLOK=$null
  foreach($f in $fn){ . ([scriptblock]::Create($f.Extent.Text)) }
  $kod = SmmmDersKodu $DersRegex; $tum=@(SmmmTestBloklari)
  if(-not $tum.Count){ return $null }
  $genis=@{}; $dar=$(if(@($tum | Where-Object { $_.kod -eq $kod }).Count){ @{} } else { $null })
  foreach($bl in $tum){ $darMi=($bl.kod -eq $kod); foreach($w in ((Katla2 $bl.metin) -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -ge 5){ $on=$w.Substring(0,5); $genis[$on]=1; if($darMi -and $dar){ $dar[$on]=1 } } } }
  return [pscustomobject]@{ genis=$genis; dar=$dar; aralik=@("smmm-$kod"); blok=$tum.Count; donemler=@('SMMM test'); kaynak='ambar (üretici SmmmTestBloklari)' }
}

# 05.10.2026 SÖZLÜK ÖNBELLEĞİ (Cem "1.2.3" GM3): gm9'da 5 GM yazarının ikisi kökü sınamak için KAPI-K'nın node kopyasını kendi kurdu;
#   ön denetim dosya başına ~5 dk sürüyor ve en çok yeniden yazım KAPI-K'dan geldi. Önbellek SÖZLÜĞÜ saklar, ölçüm yine KapiKOlc'dur
#   (mantık kopyası yok). Dosya veri/fabrika/ altında (git dışı). 🚫 GÖRMEZ: önbellek ömrü içinde ambara eklenen kitapçık.
function KapiKSozlukYaz($Sozluk,[string]$Yol){
  $o=[pscustomobject]@{ olcum=(Get-Date).ToString('s'); kaynak="$($Sozluk.kaynak)"; blok=$Sozluk.blok; aralik=@($Sozluk.aralik); genis=@($Sozluk.genis.Keys | Sort-Object); dar=$(if($Sozluk.dar){ @($Sozluk.dar.Keys | Sort-Object) } else { $null }) }
  [IO.File]::WriteAllText($Yol,($o | ConvertTo-Json -Depth 4 -Compress),(New-Object Text.UTF8Encoding $false))
}
function KapiKSozlukOku([string]$Yol){
  $j=Get-Content -Raw -Encoding UTF8 $Yol | ConvertFrom-Json
  $genis=@{}; foreach($k in @($j.genis)){ $genis["$k"]=1 }
  $dar=$null; if($null -ne $j.dar -and "$env:DENETLE_KOKDENE_MUTASYON" -ne 'darsiz'){ $dar=@{}; foreach($k in @($j.dar)){ $dar["$k"]=1 } }
  return [pscustomobject]@{ genis=$genis; dar=$dar; aralik=@($j.aralik); blok=$j.blok; donemler=@('SMMM test'); kaynak="önbellek $($j.olcum) ($($j.kaynak))"; olcum=[datetime]$j.olcum }
}
function KapiKSmmmSozlukOnbellek([Parameter(Mandatory)][string]$DersRegex,[int]$SaatTavan=12,[switch]$Tazele){
  $kat=Join-Path (KapiKDepoKok) 'veri\fabrika'; if(-not (Test-Path $kat)){ New-Item -ItemType Directory -Force $kat | Out-Null }
  $ad=($DersRegex -replace '[^A-Za-z0-9]+','-').Trim('-').ToLowerInvariant(); $yol=Join-Path $kat "kapi-k-smmm-$ad.json"
  if(-not $Tazele -and (Test-Path $yol)){ $s=KapiKSozlukOku $yol; if(((Get-Date)-$s.olcum).TotalHours -lt $SaatTavan){ return $s } }
  $s=KapiKSmmmSozlukKur -DersRegex $DersRegex; if(-not $s){ return $null }
  KapiKSozlukYaz $s $yol; return $s
}

# ⭐ 07.10.2026 KGK SÖZLÜĞÜ (KGK oturumu, Cem "eksik kuralları yapalım" K3): KGK'nın KAPI-K sözlüğü yoktu — üretici KGK'da pencere
#   sözlüğü KURMUYOR (PENCERE_KOK yalnız SGS/SMMM dalında dolar), ön denetim de etiket kgk- iken hiçbir sözlük kurmuyordu → KGK sorusunun
#   kökü "sınav dili" ölçüsünden hiç geçmedi. Sözlük ambardaki BÜTÜN KGK çıkmış kitapçıklarından (tur=cikmis-soru, 'CIKMIS SINAV - KGK%',
#   CEVAP belgeleri hariç; 2016–2026, 7 modül karışık) kurulur. KGK kitapçığı modül modül bölünmediği için DAR sözlük yok (yalnız GENİŞ).
#   🚫 GÖRMEZ: bulutta aynı ölçü YOK (üretici KGK'da KAPI-K koşmaz) → bu yalnız ÖN DENETİM kapısıdır; görüntüden okunan 2 sınav (metin yok).
function KapiKKgkSozlukKur(){
  $KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $KEY){ $KEY = $env:SUPABASE_SERVICE_KEY }; if(-not $KEY){ return $null }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $SB=@{ apikey=$KEY.Trim(); Authorization="Bearer $($KEY.Trim())"; 'User-Agent'='mevzuat-radar-robot/1.0' }
  $genis=@{}; $blok=0; $ofs=0
  while($true){
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&kaynak_ad=ilike.' + [uri]::EscapeDataString('CIKMIS SINAV - KGK%') + "&order=kaynak_ad.asc&limit=50&offset=$ofs"
    $sayfa=$null; foreach($d in 1..3){ try{ $r=Invoke-WebRequest -Uri $u -Headers $SB -UseBasicParsing -TimeoutSec 120; $sayfa=ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())); break }catch{ Start-Sleep -Seconds 3 } }
    if($null -eq $sayfa){ return $null }   # yarım sözlük kurulmaz (sessiz eksik = sahte "sınav dili dışı")
    $liste=@($sayfa | ForEach-Object { $_ }); if(-not $liste.Count){ break }
    foreach($x in $liste){ if("$($x.kaynak_ad)" -match '(?i)CEVAP'){ continue }; $blok++
      foreach($w in ((KapiKKatla "$($x.metin)") -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -ge 5){ $genis[$w.Substring(0,5)]=1 } } }
    if($liste.Count -lt 50){ break }; $ofs+=50
  }
  if($blok -lt 50){ return $null }   # 07.10 ölçüldü: 120 belgenin ~100'ü kitapçık; 50 altı = çekim eksik
  return [pscustomobject]@{ genis=$genis; dar=$null; aralik=@('kgk-tum'); blok=$blok; donemler=@('KGK tüm kitapçıklar'); kaynak='ambar (KGK çıkmış kitapçıkları)' }
}
function KapiKKgkSozlukOnbellek([int]$SaatTavan=12,[switch]$Tazele){
  $kat=Join-Path (KapiKDepoKok) 'veri\fabrika'; if(-not (Test-Path $kat)){ New-Item -ItemType Directory -Force $kat | Out-Null }
  $yol=Join-Path $kat 'kapi-k-kgk-tum.json'
  if(-not $Tazele -and (Test-Path $yol)){ $s=KapiKSozlukOku $yol; if(((Get-Date)-$s.olcum).TotalHours -lt $SaatTavan){ return $s } }
  $s=KapiKKgkSozlukKur; if(-not $s){ return $null }
  KapiKSozlukYaz $s $yol; return $s
}

# Üreticideki PencereKavram'ın birebir aynısı: kelime -> sebep sözlüğü döner.
#   GENİŞ'te yok            -> kusur (kaç kez geçtiğine bakılmaz)
#   GENİŞ'te var, DAR'da yok -> yalnız gövdede >=2 kez geçiyorsa kusur
# Üretici, dönen kelime sayısı >=2 ise soruyu DÜŞÜRÜR; 1 ise yalnız rapora not düşer.
function KapiKOlc([string]$Metin,$Sozluk){
  $bos = @{}
  if(-not $Sozluk -or -not $Sozluk.genis -or -not $Sozluk.genis.Keys.Count){ return $bos }
  $sayim = @{}; $kelime = @{}
  $duz = ("$Metin" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant()
  foreach($w in ($duz -replace '[^a-z ]+',' ' -split '\s+')){
    if($w.Length -lt 6){ continue }
    $on = $w.Substring(0,5)
    if(-not $sayim.ContainsKey($on)){ $sayim[$on] = 0; $kelime[$on] = $w }
    $sayim[$on]++
  }
  $eksik = @{}
  foreach($on in $sayim.Keys){
    if(-not $Sozluk.genis.ContainsKey($on)){ $eksik[$kelime[$on]] = 'genis disi'; continue }
    if($Sozluk.dar -and -not $Sozluk.dar.ContainsKey($on) -and $sayim[$on] -ge 2){ $eksik[$kelime[$on]] = "dar disi x$($sayim[$on])" }
  }
  return $eksik
}
