# ============================================================================
#  YUT EŞDEĞERLİK PROVASI (31.10.2026, Cem: "önce eşdeğerlik provası: eski ve yeni betiği ambardaki BÜTÜN
#  kaynaklarda çalıştır; değişen her parçayı say; değişenlerin yalnız kesik madde onarımları olduğunu göster")
#
#  NE YAPAR: motor/mevzuat-yut.ps1'in İKİ SÜRÜMÜNÜN (eski / yeni) parçalayıcı işlevlerini AST ile ayrı iki
#  dinamik modüle yükler; manifestteki (veri/mevzuat-kaynaklar.json) HER kaynağın ham metnini
#  (veri/mevzuat-hazir/<slug>.txt, yoksa <TxtDir>/<slug>.txt - bulut ve yerel-ayna ile aynı sıra) iki sürümle
#  ayrı ayrı yutar, AMBARA ve DOSYAYA YAZMAZ, ağ isteği YAPMAZ. Çıktıları parça parça karşılaştırır.
#
#  SINIFLAR (kaynak başına):
#    ayni  - iki sürümün parçaları birebir aynı (ad, başlık, metin)
#    (i)   - "kesik kuyruk geri geldi + sonraki madde adı temizlendi": birleşik metin AYNI, madde dizisi AYNI,
#            fark yalnız madde sınırında: sonraki maddenin başından bir kuyruk (cümle sonuyla biten) ÖNCEKİ
#            maddenin sonuna geri dönmüş, sonraki maddenin adı/başlığı o kuyruk kadar kısalmış.
#    (ii)  - başka her fark (metin farkı, madde dizisi farkı, ileri taşıma, adın başka biçimde değişmesi).
#    girdi-yok / kisa - ham metin yok ya da 300 kr altı (yut betiği de atlar).
#
#  KULLANIM:
#    powershell -NoProfile -File arac/yut-esdegerlik-provasi.ps1 -Eski <eski mevzuat-yut.ps1> [-Yeni motor/mevzuat-yut.ps1]
#               [-TxtDir <_txt klasörü>] [-Sadece kdv,vuk] [-Dilim 1/4] [-Rapor <çıktı.json>]
#    powershell -NoProfile -File arac/yut-esdegerlik-provasi.ps1 -OzSinav
#
#  BU PROVA ŞUNU GÖRMEZ: yut betiğinin ana akışındaki (işlev dışı) değişiklikler - sarmal (ProvaYut) ana akışın
#    31.10 hâlinin kopyasıdır (dipnot belirleme, aralıklı madde, görsel tablo, kılavuz/bölüm yedeği, dipnot çıkarma) ·
#    ambara başka yoldan (elle onarım, standart-yut, kgk-standart-yut, spk-mevzuat-yut) yazılmış kayıtlar ·
#    ham metni olmayan kaynak (girdi-yok sayılır, sınanmamıştır).
#
#  -Ambar (08.11.2026, A-11 GM önerisi 3): eski↔yeni kıyası iki AYRIŞTIRICIYI karşılaştırır, ambarı değil.
#    08.11 yeniden yutmasında prova "metin farkı 0" dediği hâlde ambarda dipnotlar gövdeden çıktı, tcmb1211'e
#    74 kelime geri geldi, satır sayıları değişti: bunlar ambarın eski hâli ile yeni çıktı arasındaki farktı ve
#    prova göremiyordu. -Ambar verilirse YENİ sürümün çıktısı ambardaki bugünkü kanun-madde satırlarıyla da
#    kıyaslanır: parça sayısı, yalnız ambarda / yalnız yenide olan adlar, ortak adda metni farklı parça,
#    kelime çoklu-kümesi farkı (örnek kelimelerle). Yalnız GET (salt okuma); ambara yazmaz. Çıkış koduna
#    ETKİ ETMEZ (yeniden yutulmamış kaynakta fark beklenir); rapora 'ambar' alanı ve özet satırı ekler.
#    Örnek: powershell -NoProfile -File arac/yut-esdegerlik-provasi.ps1 -Ambar -Sadece kdv,vuk -Rapor r.json
# ============================================================================
param(
  [string]$Eski = '',
  [string]$Yeni = '',
  [string]$TxtDir = '',
  [string]$Sadece = '',
  [string]$Dilim = '',
  [string]$Rapor = '',
  [string]$Adlar = '',    # verilirse HER kaynagin yeni cikti adlari buraya yazilir {slug:[kaynak_ad]} (bag kapisi olcumu)
  [string]$Dok = '',      # verilirse degisen kaynaklarin eski/yeni parcalari buraya yazilir (inceleme icin)
  [switch]$Ambar,         # 08.11: YENI ciktiyi ambarin BUGUNKU satirlariyla da kiyasla (salt okuma GET; -Eski olmadan da calisir)
  [switch]$OzSinav
)
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
if(-not $Yeni){ $Yeni = Join-Path $kok 'motor/mevzuat-yut.ps1' }
if(-not $TxtDir){ $TxtDir = Join-Path $kok '_txt' }

# --- yut betiğinin ana akışının (31.10) parçalayıcı kısmı: iki sürüm için AYNI sarmal ---
$script:SARMAL = @'
function ProvaYut([string]$raw, $law){
  $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  $dipnotSonuc = YutmaHami $raw
  $flat = AralikliMaddeDuzelt $flat
  if($law.PSObject.Properties['gorselTablolar']){
    foreach($gt in @($law.gorselTablolar)){
      $gi = $flat.IndexOf("$($gt.isaret)"); if($gi -lt 0){ continue }
      $flat = $flat.Substring(0,$gi) + "$($gt.metin)" + $flat.Substring($gi + "$($gt.isaret)".Length)
    }
  }
  $url = 'u'
  $docs = if($law.PSObject.Properties['parcalayici'] -and "$($law.parcalayici)" -eq 'kilavuz-bolum'){ ParcalaKilavuz $flat "$($law.ad)" $url } else { Parcala $flat "$($law.ad)" $url (BaslikSatirlari $raw) }
  if($docs.Count -lt 5){   # ana akisla AYNI ifade (tek belgede OrderedDictionary.Count dahil)
    if($flat.Length -lt 300){ return 'KISA' }
    $docs = New-Object System.Collections.Generic.List[object]
    $PARCA_BOYU = 1800; $d = 0; $n = 1
    while($d -lt $flat.Length){
      $boy = [Math]::Min($PARCA_BOYU, $flat.Length - $d)
      $kes = $flat.Substring($d, $boy)
      if($d + $boy -lt $flat.Length){
        $kir = $kes.LastIndexOf('. ')
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }
        if($kir -ge 900){ $kes = $kes.Substring(0, $kir+1); $boy = $kir+1 }
      }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=("$($law.ad) bolum $n"); baslik=""; metin=$kes.Trim(); kaynak_url=$url; belge_tarihi=$bugun })
      $d += $boy; $n++
    }
  }
  if($dipnotSonuc.sayi){ [void](DipnotlariCikar $docs $dipnotSonuc.ayiklanan) }
  return ,@($docs | ForEach-Object { [pscustomobject]@{ kaynak_ad="$($_.kaynak_ad)"; baslik="$($_.baslik)"; metin="$($_.metin)" } })
}
'@

function YutModulu([string]$yol, [string]$ad){
  $tk = $null; $h = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($yol, [ref]$tk, [ref]$h)
  if($h.Count){ throw "$yol ayristirilamadi: $($h[0].Message)" }
  $parca = New-Object System.Collections.Generic.List[string]
  $parca.Add('$bugun = "2000-01-01"')
  # -cmatch: tr-TR'de -match, "DIPNOT_ACILIS"teki I'yi [A-Z] saymiyor -> dipnot desenleri yuklenmiyordu (31.10 olculdu)
  foreach($st in $ast.EndBlock.Statements){
    if($st -is [System.Management.Automation.Language.FunctionDefinitionAst] -or $st.Extent.Text -cmatch '^\$script:[A-Za-z_]+\s*='){ $parca.Add($st.Extent.Text) }
  }
  $parca.Add($script:SARMAL)
  $parca.Add('Export-ModuleMember -Function @()')
  $mod = New-Module -Name $ad -ScriptBlock ([scriptblock]::Create(($parca -join "`n")))
  if(-not (& $mod { $null -ne $script:TR_HARF -and $null -ne $script:DIPNOT_ACILIS -and $null -ne $script:DIPNOT_IMZA })){ throw "$yol : betik duzeyi desenler modulde yok" }
  return $mod
}

$script:AYRAC = [string][char]1
function Bosluk([string]$x){ return (($x -replace '\s+',' ').Trim()) }
$script:AD_RX = [regex]'^(?<k>.*?\s(?:muk\. |ek gec\. |gec\. |ek )?m\.\d+(?:/[A-ZÇĞİÖŞÜ])?)(?<r>(?:\s-\s.*?)?)(?:\s\[\d+/\d+\])?(?:\s\(\d+\))?$'
function MaddeAyir([string]$ad){
  $m = $script:AD_RX.Match($ad)
  if($m.Success){ return @{ k = $m.Groups['k'].Value; t = (Bosluk ($m.Groups['r'].Value -replace '^\s-\s','')) } }
  return @{ k = ($ad -replace '\s\[\d+/\d+\](\s\(\d+\))?$','' -replace '\s\(\d+\)$',''); t = '' }
}
function Maddeler($docs){
  $l = New-Object System.Collections.Generic.List[object]
  foreach($d in $docs){
    $a = MaddeAyir $d.kaynak_ad
    $son = if($l.Count){ $l[$l.Count-1] } else { $null }
    if($son -and $son.k -ceq $a.k -and $son.t -ceq $a.t){ $son.metinler.Add($d.metin); $son.parca++ }
    else { $y = [pscustomobject]@{ k=$a.k; t=$a.t; baslik=(Bosluk $d.baslik); ad=$d.kaynak_ad; metinler=(New-Object System.Collections.Generic.List[string]); parca=1; metin='' }; $y.metinler.Add($d.metin); $l.Add($y) }
  }
  foreach($x in $l){ $x.metin = Bosluk ($x.metinler -join ' ') }
  return ,$l
}
function Kirp([string]$s, [int]$n){ if($s.Length -le $n){ return $s }; return $s.Substring(0,$n) }
function Kuyruk([string]$s, [int]$n){ if($s.Length -le $n){ return $s }; return $s.Substring($s.Length-$n) }

# Sınıflandırıcı: eski (O) ve yeni (N) parça dizileri -> sınıf + sayımlar + örnekler
function Siniflandir($O, $N){
  $O = @($O); $N = @($N)
  $r = [ordered]@{ sinif='ayni'; parca_eski=$O.Count; parca_yeni=$N.Count; degisen_parca_eski=0; degisen_parca_yeni=0; madde_degisen=0; parca_sayisi_degisen=0; tasima=@(); ii=@() }
  $anah = { param($d) "$($d.kaynak_ad)$($script:AYRAC)$($d.baslik)$($script:AYRAC)$($d.metin)" }
  $kN = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($d in $N){ [void]$kN.Add((& $anah $d)) }
  $kO = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($d in $O){ [void]$kO.Add((& $anah $d)) }
  foreach($d in $O){ if(-not $kN.Contains((& $anah $d))){ $r.degisen_parca_eski++ } }
  foreach($d in $N){ if(-not $kO.Contains((& $anah $d))){ $r.degisen_parca_yeni++ } }
  $ayni = ($O.Count -eq $N.Count)
  if($ayni){ for($i=0; $i -lt $O.Count; $i++){ if((& $anah $O[$i]) -cne (& $anah $N[$i])){ $ayni = $false; break } } }
  if($ayni){ return [pscustomobject]$r }
  $ii = New-Object System.Collections.Generic.List[object]; $ts = New-Object System.Collections.Generic.List[object]
  $jO = Bosluk (($O | ForEach-Object { $_.metin }) -join ' '); $jN = Bosluk (($N | ForEach-Object { $_.metin }) -join ' ')
  if($jO -cne $jN){
    $x = 0; $mn = [Math]::Min($jO.Length, $jN.Length); while($x -lt $mn -and $jO[$x] -ceq $jN[$x]){ $x++ }
    $ii.Add([ordered]@{ tur='birlesik metin farki'; konum=$x; eski=(Kirp $jO.Substring([Math]::Max(0,$x-40)) 120); yeni=(Kirp $jN.Substring([Math]::Max(0,$x-40)) 120) })
  }
  $mO = Maddeler $O; $mN = Maddeler $N
  $dizO = ($mO | ForEach-Object { $_.k }) -join $script:AYRAC; $dizN = ($mN | ForEach-Object { $_.k }) -join $script:AYRAC
  if(-not $ii.Count -and $dizO -cne $dizN){
    $x = 0; while($x -lt [Math]::Min($mO.Count,$mN.Count) -and $mO[$x].k -ceq $mN[$x].k){ $x++ }
    $ii.Add([ordered]@{ tur='madde dizisi farki'; sayi_eski=$mO.Count; sayi_yeni=$mN.Count; ilk_fark_eski=$(if($x -lt $mO.Count){ $mO[$x].ad } else { '' }); ilk_fark_yeni=$(if($x -lt $mN.Count){ $mN[$x].ad } else { '' }) })
  }
  if(-not $ii.Count){
    $oS = 0; $nS = 0
    for($j=0; $j -lt $mO.Count; $j++){
      $a = $mO[$j]; $b = $mN[$j]
      if($a.parca -ne $b.parca){ $r.parca_sayisi_degisen++ }
      if($a.metin -cne $b.metin -or $a.t -cne $b.t -or $a.baslik -cne $b.baslik -or $a.parca -ne $b.parca){ $r.madde_degisen++ }
      if($j -gt 0){
        if($nS -gt $oS){
          $T = $jO.Substring($oS, $nS - $oS).Trim()
          $tur = ''
          if($T -notmatch '[.!?…]$'){ $tur = 'kuyruk cumle sonuyla bitmiyor' }
          elseif($a.t -and $b.t -and $a.t -ceq (Bosluk "$T $($b.t)")){ $tur = 'i-ad-temizlendi' }
          elseif(-not $a.t -and $b.t){ $tur = 'i-ad-eklendi' }
          elseif($a.t -and -not $b.t -and $a.t.StartsWith($T)){ $tur = 'i-ad-bosaldi' }
          elseif(-not $a.t -and -not $b.t){ $tur = 'i-ad-yok' }
          else { $tur = 'ad baska bicimde degisti' }
          if($tur -like 'i-*' -and $b.baslik -cne $b.t -and $b.baslik -cne $a.baslik){ $tur = 'baslik alani baska bicimde degisti' }
          $kay = [ordered]@{ tur=$tur; alan=$mN[$j-1].ad; veren_eski=$a.ad; veren_yeni=$b.ad; kuyruk_kr=$T.Length; kuyruk_son=(Kuyruk $T 70); parca_eski=$a.parca; parca_yeni=$b.parca }
          if($tur -like 'i-*'){ $ts.Add($kay) } else { $ii.Add($kay) }
        } elseif($nS -lt $oS){
          $ii.Add([ordered]@{ tur='ileri tasima (onceki maddeden sonrakine metin gecti)'; madde=$b.ad; kr=($oS-$nS) })
        } elseif($a.t -cne $b.t -or $a.baslik -cne $b.baslik){
          $ii.Add([ordered]@{ tur='ad/baslik degisti, sinirda tasima yok'; eski=$a.ad; yeni=$b.ad })
        }
      } elseif($a.t -cne $b.t -or $a.baslik -cne $b.baslik){
        $ii.Add([ordered]@{ tur='ilk maddenin adi degisti'; eski=$a.ad; yeni=$b.ad })
      }
      $oS += $a.metin.Length + 1; $nS += $b.metin.Length + 1
    }
  }
  $r.tasima = $ts.ToArray(); $r.ii = $ii.ToArray()
  $r.sinif = if($ii.Count){ '(ii)' } else { '(i)' }
  return [pscustomobject]$r
}

# ---------------------- AMBAR TABANI (08.11, salt okuma) ----------------------
# A = ambar satirlari (kaynak_ad, metin), N = yeni surum ciktisi. Sira karsilastirilmaz (ambar id'si uuid).
function KelimeSay([string[]]$metinler){
  $d = New-Object 'System.Collections.Generic.Dictionary[string,int]'
  foreach($m in $metinler){ foreach($w in ((Bosluk $m) -split ' ')){ if(-not $w){ continue }; if($d.ContainsKey($w)){ $d[$w]++ } else { $d[$w] = 1 } } }
  return ,$d
}
function AmbarKiyas($A, $N){
  $A = @($A); $N = @($N)
  $adA = New-Object 'System.Collections.Generic.Dictionary[string,string]'; foreach($x in $A){ $adA["$($x.kaynak_ad)"] = Bosluk "$($x.metin)" }
  $adN = New-Object 'System.Collections.Generic.Dictionary[string,string]'; foreach($x in $N){ $adN["$($x.kaynak_ad)"] = Bosluk "$($x.metin)" }
  $yA = @($adA.Keys | Where-Object { -not $adN.ContainsKey($_) }); $yN = @($adN.Keys | Where-Object { -not $adA.ContainsKey($_) })
  $mf = @($adA.Keys | Where-Object { $adN.ContainsKey($_) -and $adA[$_] -cne $adN[$_] })
  $kA = KelimeSay @($A | ForEach-Object { "$($_.metin)" }); $kN = KelimeSay @($N | ForEach-Object { "$($_.metin)" })
  $fA = @{}; $fN = @{}; $tA = 0; $tN = 0
  foreach($w in $kA.Keys){ $f = $kA[$w] - $(if($kN.ContainsKey($w)){ $kN[$w] } else { 0 }); if($f -gt 0){ $fA[$w] = $f; $tA += $f } }
  foreach($w in $kN.Keys){ $f = $kN[$w] - $(if($kA.ContainsKey($w)){ $kA[$w] } else { 0 }); if($f -gt 0){ $fN[$w] = $f; $tN += $f } }
  $ornek = { param($h) @($h.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 8 | ForEach-Object { "$($_.Key) x$($_.Value)" }) }
  $sinif = if(-not $yA.Count -and -not $yN.Count -and -not $mf.Count -and -not $tA -and -not $tN -and $A.Count -eq $N.Count){ 'ayni' } elseif(-not $tA -and -not $tN){ 'yalniz-bolme' } else { 'metin-farki' }
  return [pscustomobject][ordered]@{ sinif=$sinif; parca_ambar=$A.Count; parca_yeni=$N.Count; ad_yalniz_ambar=$yA.Count; ad_yalniz_yeni=$yN.Count
    ortak_ad_metin_farkli=$mf.Count; kelime_yalniz_ambar=$tA; kelime_yalniz_yeni=$tN
    ornek_ad_yalniz_ambar=@($yA | Select-Object -First 5); ornek_ad_yalniz_yeni=@($yN | Select-Object -First 5)
    ornek_kelime_yalniz_ambar=(& $ornek $fA); ornek_kelime_yalniz_yeni=(& $ornek $fN) }
}
function AmbarSatirlari($law){
  $key = if($env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }  # public anon key
  $H = @{ apikey = $key; Authorization = "Bearer $key"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
  $q = [uri]::EscapeDataString("$($law.ad)*"); $l = New-Object System.Collections.Generic.List[object]
  for($o = 0; ; $o += 1000){
    $r = $null
    foreach($d in 1..4){ try { $r = @(Invoke-RestMethod -Uri "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.kanun-madde&kaynak_ad=like.$q&order=id&limit=1000&offset=$o" -Headers $H | ForEach-Object { $_ }); break } catch { if($d -eq 4){ throw }; Start-Sleep -Milliseconds (700*$d) } }
    # like 'ad*' baska kaynagi da yakalayabilir ("X K." / "X K. Yon."): yalniz tam ad ya da "ad " onekli satir
    foreach($x in $r){ $a = "$($x.kaynak_ad)"; if($a -ceq "$($law.ad)" -or $a.StartsWith("$($law.ad) ")){ $l.Add($x) } }
    if($r.Count -lt 1000){ break }
  }
  # .ToArray() SART: PS 5.1'de @(List[object]) "Bagimsiz degisken turleri eslesmiyor" ile patliyor (08.11 olculdu)
  return ,($l.ToArray())
}

# ------------------------------- ÖZ-SINAV -------------------------------
if($OzSinav){
  $gecti = 0; $kaldi = 0
  function D($ad, $b, $m){ [pscustomobject]@{ kaynak_ad=$ad; baslik=$b; metin=$m } }
  # AMBAR TABANI siniflandiricisi (08.11)
  $aA = @( (D 'K m.1' '' 'Madde 1 – Bir.'), (D 'K m.2' '' 'Madde 2 – Iki (Değişik: 1/1/2020-7000/5 md.)') )
  $amb = @(
    @{ ad='AMBAR: ayni cikti -> ayni'; a=$aA; n=$aA; kontrol={ param($s) $s.sinif -eq 'ayni' -and $s.kelime_yalniz_ambar -eq 0 } }
    @{ ad='AMBAR: dipnot govdeden cikti -> metin-farki, kelime yalniz ambarda, ad farki 0'; a=$aA; n=@( $aA[0], (D 'K m.2' '' 'Madde 2 – Iki') )
       kontrol={ param($s) $s.sinif -eq 'metin-farki' -and $s.kelime_yalniz_ambar -eq 3 -and $s.kelime_yalniz_yeni -eq 0 -and $s.ad_yalniz_ambar -eq 0 -and $s.ortak_ad_metin_farkli -eq 1 } }
    @{ ad='AMBAR: ayni metin, ad degisti -> yalniz-bolme'; a=$aA; n=@( $aA[0], (D 'K m.2 - Baslik' '' $aA[1].metin) )
       kontrol={ param($s) $s.sinif -eq 'yalniz-bolme' -and $s.ad_yalniz_ambar -eq 1 -and $s.ad_yalniz_yeni -eq 1 } }
    @{ ad='MUTASYON AMBAR: yenide kelime fazla -> metin-farki, kelime yalniz yenide'; a=$aA; n=@( $aA[0], (D 'K m.2' '' ($aA[1].metin + ' ek')) )
       kontrol={ param($s) $s.sinif -eq 'metin-farki' -and $s.kelime_yalniz_yeni -eq 1 } }
  )
  foreach($v in $amb){
    $s = AmbarKiyas $v.a $v.n; $ok = $false; try { $ok = [bool](& $v.kontrol $s) } catch {}
    if($ok){ $gecti++; Write-Host ("  OK    {0}" -f $v.ad) } else { $kaldi++; Write-Host ("  KALDI {0} -> {1}" -f $v.ad, ($s | ConvertTo-Json -Depth 4 -Compress)) -ForegroundColor Red }
  }
  $T = "Türkiye'de faydalanılmasını, İfade eder."
  $eskiK = @( (D 'K m.6' '' 'Madde 6 – b) Hizmetin Türkiye''de yapılmasını veya hizmetten'), (D "K m.7 - $T Uluslararası taşıma işleri" "$T Uluslararası taşıma işleri" "$T Uluslararası taşıma işleri: Madde 7 – Türkiye ile yabancı ülkeler arasında taşımacılık."), (D 'K m.8' '' 'Madde 8 – Mükellef sekiz.') )
  $yeniK = @( (D 'K m.6' '' "Madde 6 – b) Hizmetin Türkiye'de yapılmasını veya hizmetten $T"), (D 'K m.7 - Uluslararası taşıma işleri' 'Uluslararası taşıma işleri' 'Uluslararası taşıma işleri: Madde 7 – Türkiye ile yabancı ülkeler arasında taşımacılık.'), (D 'K m.8' '' 'Madde 8 – Mükellef sekiz.') )
  $vakalar = @(
    @{ ad='KDVK m.6/m.7 vakasi -> (i) i-ad-temizlendi, 2 madde, 2 parca'; o=$eskiK; n=$yeniK
       kontrol={ param($s) $s.sinif -eq '(i)' -and $s.madde_degisen -eq 2 -and $s.degisen_parca_eski -eq 2 -and @($s.tasima).Count -eq 1 -and $s.tasima[0].tur -eq 'i-ad-temizlendi' } }
    @{ ad='Ayni cikti -> ayni, 0 parca'; o=$yeniK; n=$yeniK
       kontrol={ param($s) $s.sinif -eq 'ayni' -and $s.degisen_parca_eski -eq 0 } }
    @{ ad='MUTASYON: yeni surum bir kelime dusuruyor -> (ii) birlesik metin farki'; o=$yeniK
       n=@( $yeniK[0], (D 'K m.7 - Uluslararası taşıma işleri' 'Uluslararası taşıma işleri' 'Uluslararası taşıma işleri: Madde 7 – Türkiye ile ülkeler arasında taşımacılık.'), $yeniK[2] )
       kontrol={ param($s) $s.sinif -eq '(ii)' -and $s.ii[0].tur -eq 'birlesik metin farki' } }
    @{ ad='MUTASYON: ters yon (onarilmis -> kesik) -> (ii) ileri tasima'; o=$yeniK; n=$eskiK
       kontrol={ param($s) $s.sinif -eq '(ii)' -and @($s.ii | Where-Object { $_.tur -like 'ileri*' }).Count -ge 1 } }
    @{ ad='MUTASYON: madde dusuyor -> (ii) madde dizisi farki'; o=$yeniK
       n=@( (D 'K m.6' '' ("Madde 6 – b) Hizmetin Türkiye'de yapılmasını veya hizmetten $T Uluslararası taşıma işleri: Madde 7 – Türkiye ile yabancı ülkeler arasında taşımacılık.")), $yeniK[2] )
       kontrol={ param($s) $s.sinif -eq '(ii)' -and $s.ii[0].tur -eq 'madde dizisi farki' } }
    @{ ad='MUTASYON: kuyruk cumle sonuyla bitmiyor -> (ii)'
       o=@( (D 'K m.6' '' 'Madde 6 – b) Hizmet'), (D 'K m.7 - yapılır Başlık' 'yapılır Başlık' 'yapılır Başlık: Madde 7 – Yedi.'), $yeniK[2] )
       n=@( (D 'K m.6' '' 'Madde 6 – b) Hizmet yapılır'), (D 'K m.7 - Başlık' 'Başlık' 'Başlık: Madde 7 – Yedi.'), $yeniK[2] )
       kontrol={ param($s) $s.sinif -eq '(ii)' -and $s.ii[0].tur -eq 'kuyruk cumle sonuyla bitmiyor' } }
    @{ ad='MUTASYON: sinirda tasima yok ama ad degisti -> (ii)'; o=$yeniK
       n=@( $yeniK[0], (D 'K m.7 - Uluslararası taşımalar' 'Uluslararası taşımalar' $yeniK[1].metin), $yeniK[2] )
       kontrol={ param($s) $s.sinif -eq '(ii)' } }
    @{ ad='Parca sayisi degisen (i): uzun madde [1/2]->[1/2] kuyruk geri geldi -> (i)'
       o=@( (D 'K m.6 [1/2]' '' 'Madde 6 – birinci parca.'), (D 'K m.6 [2/2]' '' 'ikinci parca hizmetten'), (D "K m.7 - $T Başlık" "$T Başlık" "$T Başlık: Madde 7 – Yedi.") )
       n=@( (D 'K m.6 [1/2]' '' 'Madde 6 – birinci parca.'), (D 'K m.6 [2/2]' '' "ikinci parca hizmetten $T"), (D 'K m.7 - Başlık' 'Başlık' 'Başlık: Madde 7 – Yedi.') )
       kontrol={ param($s) $s.sinif -eq '(i)' -and $s.madde_degisen -eq 2 } }
  )
  foreach($v in $vakalar){
    $s = Siniflandir $v.o $v.n; $ok = $false; try { $ok = [bool](& $v.kontrol $s) } catch {}
    if($ok){ $gecti++; Write-Host ("  OK    {0}" -f $v.ad) } else { $kaldi++; Write-Host ("  KALDI {0} -> {1}" -f $v.ad, ($s | ConvertTo-Json -Depth 4 -Compress)) -ForegroundColor Red }
  }
  # Gercek yut betigi (bu depodaki) KDVK vakasini (i) yonunde parcaliyor mu? (yut betiginin kendi -OzSinav'i da sinar)
  $mod = YutModulu $Yeni 'prova_yeni_oz'
  $law = [pscustomobject]@{ ad='SINAV'; slug='sinav' }
  $ham = "Madde 6 – a) Mal, teslim anında Türkiye'de bulunuyorsa teslim Türkiye'de yapılmış sayılır ve uzun bir govdesi vardir.`nb) Hizmetin Türkiye'de yapılmasını veya`nhizmetten Türkiye'de faydalanılmasını,`nİfade eder.`nUluslararası taşıma işleri:`nMadde 7 – Türkiye ile yabancı ülkeler arasında yapılan taşımacılık ile transit taşımacılık işlerinde hizmet yapılmış sayılır.`n" + ((1..5 | ForEach-Object { "Madde $(7+$_) – Bu madde dolgu maddesidir ve yeterince uzun bir govdesi vardir, ayri kayit olur." }) -join "`n")
  $c = & $mod { param($r,$l) ProvaYut $r $l } $ham $law
  $m6 = @($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.6' })[0]; $m7 = @($c | Where-Object { $_.kaynak_ad -like 'SINAV m.7*' })[0]
  if($m6 -and $m6.metin.EndsWith('İfade eder.') -and $m7.kaynak_ad -eq 'SINAV m.7 - Uluslararası taşıma işleri'){ $gecti++; Write-Host '  OK    yeni yut betigi (ProvaYut sarmali) KDVK m.6/m.7 vakasini onariyor' }
  else { $kaldi++; Write-Host '  KALDI yeni yut betigi KDVK m.6/m.7 vakasini onarmiyor' -ForegroundColor Red }
  Write-Host ("OZ-SINAV: gecti {0} - kaldi {1}" -f $gecti, $kaldi)
  exit $(if($kaldi){ 1 } else { 0 })
}

# ------------------------------- PROVA -------------------------------
if($Eski -and -not (Test-Path $Eski)){ throw "-Eski bulunamadi: $Eski" }
if(-not $Eski -and -not $Ambar){ throw '-Eski <eski mevzuat-yut.ps1 yolu> ya da -Ambar gerekli' }
$modE = if($Eski){ YutModulu (Resolve-Path $Eski).Path 'prova_eski' } else { $null }
$modY = YutModulu (Resolve-Path $Yeni).Path 'prova_yeni'
$sayA = [ordered]@{ kaynak=0; ayni=0; yalniz_bolme=0; metin_farki=0; ambarda_yok=0; hata=0; kelime_yalniz_ambar=0; kelime_yalniz_yeni=0 }
$kayitA = New-Object System.Collections.Generic.List[object]
$man = Get-Content (Join-Path $kok 'veri/mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$liste = @($man.kanunlar)
if($Sadece){ $sk = @($Sadece -split ',' | ForEach-Object { $_.Trim() }); $liste = @($liste | Where-Object { $sk -contains $_.slug }) }
if($Dilim -match '^(\d+)/(\d+)$'){ $dk = [int]$Matches[1]; $dn = [int]$Matches[2]; $liste = @(for($i=0; $i -lt $liste.Count; $i++){ if(($i % $dn) -eq ($dk-1)){ $liste[$i] } }) }
$say = [ordered]@{ kaynak=$liste.Count; prova=0; ayni=0; sinif_i=0; sinif_ii=0; girdi_yok=0; kisa=0; hata=0; parca_eski=0; parca_yeni=0; degisen_parca_eski=0; degisen_parca_yeni=0; madde_degisen=0; tasima=0; parca_sayisi_degisen=0 }
$kayit = New-Object System.Collections.Generic.List[object]
$bas = Get-Date; $n = 0; $script:CIKTI_AD_DIZINI = [ordered]@{}
foreach($law in $liste){
  $n++
  $hz = Join-Path $kok "veri/mevzuat-hazir/$($law.slug).txt"; $tx = Join-Path $TxtDir "$($law.slug).txt"
  $yol = if(Test-Path $hz){ $hz } elseif(Test-Path $tx){ $tx } else { $null }
  if(-not $yol){ $say.girdi_yok++; $kayit.Add([ordered]@{ slug=$law.slug; ad=$law.ad; sinif='girdi-yok' }); continue }
  $raw = Get-Content $yol -Raw -Encoding UTF8
  try {
    $y = & $modY { param($r,$l) ProvaYut $r $l } $raw $law
    $o = if($modE){ & $modE { param($r,$l) ProvaYut $r $l } $raw $law } else { $null }
  } catch { $say.hata++; $kayit.Add([ordered]@{ slug=$law.slug; ad=$law.ad; sinif='hata'; hata="$_" }); continue }
  if($Ambar -and "$y" -ne 'KISA'){
    $sayA.kaynak++
    try {
      $am = AmbarSatirlari $law
      if(-not $am.Count){ $sayA.ambarda_yok++; $kayitA.Add([ordered]@{ slug=$law.slug; ad=$law.ad; sinif='ambarda-yok' }) }
      else {
        $ak = AmbarKiyas $am $y
        switch($ak.sinif){ 'ayni' { $sayA.ayni++ } 'yalniz-bolme' { $sayA.yalniz_bolme++ } 'metin-farki' { $sayA.metin_farki++ } }
        $sayA.kelime_yalniz_ambar += $ak.kelime_yalniz_ambar; $sayA.kelime_yalniz_yeni += $ak.kelime_yalniz_yeni
        if($ak.sinif -ne 'ayni'){ $kayitA.Add([ordered]@{ slug=$law.slug; ad=$law.ad; kiyas=$ak }) }
        if($Sadece){ Write-Host ("  AMBAR {0,-14} {1,-12} parca ambar {2} / yeni {3} · ad yalniz ambar {4} / yeni {5} · ortak adda metin farkli {6} · kelime yalniz ambar {7} / yeni {8}" -f $law.slug, $ak.sinif, $ak.parca_ambar, $ak.parca_yeni, $ak.ad_yalniz_ambar, $ak.ad_yalniz_yeni, $ak.ortak_ad_metin_farkli, $ak.kelime_yalniz_ambar, $ak.kelime_yalniz_yeni) }
      }
    } catch { $sayA.hata++; $kayitA.Add([ordered]@{ slug=$law.slug; ad=$law.ad; sinif='hata'; hata="$_" }) }
  }
  if(-not $modE){ if($Adlar -and "$y" -ne 'KISA'){ $script:CIKTI_AD_DIZINI[$law.slug] = @($y | ForEach-Object { $_.kaynak_ad }) }; continue }
  if("$o" -eq 'KISA' -or "$y" -eq 'KISA'){ $say.kisa++; $kayit.Add([ordered]@{ slug=$law.slug; ad=$law.ad; sinif='kisa'; ikisi_de=("$o" -eq 'KISA' -and "$y" -eq 'KISA') }); continue }
  $s = Siniflandir $o $y
  $say.prova++; $say.parca_eski += $s.parca_eski; $say.parca_yeni += $s.parca_yeni
  $say.degisen_parca_eski += $s.degisen_parca_eski; $say.degisen_parca_yeni += $s.degisen_parca_yeni; $say.madde_degisen += $s.madde_degisen
  $say.tasima += @($s.tasima).Count; $say.parca_sayisi_degisen += $s.parca_sayisi_degisen
  switch($s.sinif){ 'ayni' { $say.ayni++ } '(i)' { $say.sinif_i++ } '(ii)' { $say.sinif_ii++ } }
  if($Adlar){ $script:CIKTI_AD_DIZINI[$law.slug] = @($y | ForEach-Object { $_.kaynak_ad }) }
  if($s.sinif -ne 'ayni' -and $Dok){   # inceleme icin iki surumun ciktisi (yalniz degisen kaynak; ambara degil, -Dok klasorune)
    if(-not (Test-Path $Dok)){ New-Item -ItemType Directory -Path $Dok -Force | Out-Null }
    [IO.File]::WriteAllText((Join-Path $Dok "$($law.slug).json"), (ConvertTo-Json -InputObject ([ordered]@{ eski=@($o); yeni=@($y) }) -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
  }
  if($s.sinif -ne 'ayni'){ $kayit.Add([ordered]@{ slug=$law.slug; ad=$law.ad; girdi=$(if($yol -eq $hz){ 'hazir' } else { '_txt' }); sinif=$s.sinif; parca_eski=$s.parca_eski; parca_yeni=$s.parca_yeni; degisen_parca_eski=$s.degisen_parca_eski; degisen_parca_yeni=$s.degisen_parca_yeni; madde_degisen=$s.madde_degisen; parca_sayisi_degisen=$s.parca_sayisi_degisen; tasima=$s.tasima; ii=$s.ii }) }
  if(($n % 50) -eq 0){ Write-Host ("  {0}/{1} ({2:n0} sn) ayni {3} (i) {4} (ii) {5}" -f $n, $liste.Count, ((Get-Date)-$bas).TotalSeconds, $say.ayni, $say.sinif_i, $say.sinif_ii) }
}
$cikti = [ordered]@{ olcum=(Get-Date).ToString('s'); eski=$Eski; yeni=$Yeni; dilim=$Dilim; sayim=$say; kaynaklar=$kayit.ToArray() }
if($Ambar){ $cikti.ambar = [ordered]@{ sayim=$sayA; kaynaklar=$kayitA.ToArray() } }
if($Adlar){ [IO.File]::WriteAllText($Adlar, (ConvertTo-Json -InputObject $script:CIKTI_AD_DIZINI -Depth 3 -Compress), (New-Object System.Text.UTF8Encoding($false))) }
if($Rapor){ [IO.File]::WriteAllText($Rapor, ($cikti | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false))) }
if($modE){
  Write-Host ("PROVA: kaynak {0} · prova {1} · ayni {2} · (i) {3} · (ii) {4} · girdi-yok {5} · kisa {6} · hata {7}" -f $say.kaynak,$say.prova,$say.ayni,$say.sinif_i,$say.sinif_ii,$say.girdi_yok,$say.kisa,$say.hata)
  Write-Host ("PARCA: eski {0} · yeni {1} · degisen (eski tarafta) {2} · (yeni tarafta) {3} · madde degisen {4} · sinir tasimasi {5}" -f $say.parca_eski,$say.parca_yeni,$say.degisen_parca_eski,$say.degisen_parca_yeni,$say.madde_degisen,$say.tasima)
}
if($Ambar){
  Write-Host ("AMBAR TABANI (yeni cikti <-> ambarin bugunku hali): kaynak {0} · ayni {1} · yalniz bolme {2} · metin farki {3} · ambarda yok {4} · hata {5} · kelime yalniz ambarda {6} / yalniz yenide {7}" -f $sayA.kaynak,$sayA.ayni,$sayA.yalniz_bolme,$sayA.metin_farki,$sayA.ambarda_yok,$sayA.hata,$sayA.kelime_yalniz_ambar,$sayA.kelime_yalniz_yeni)
  Write-Host "  (bilgi amacli; cikis kodunu degistirmez - yeniden yutulmamis kaynakta fark beklenir)"
}
if(-not $modE){ exit $(if($say.hata){ 2 } else { 0 }) }
exit $(if($say.sinif_ii -or $say.hata){ 2 } else { 0 })
