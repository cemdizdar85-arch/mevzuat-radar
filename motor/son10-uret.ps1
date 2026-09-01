# ============================================================================
#  SON-KARAR 10'LUKLAR (29.08, Cem: "her sınav 10 tane en son kararımızla")
#  90'lık partinin her sınavdan ilk 10 sorusunu (sıklık sıralı) kural-25
#  tonu + konsept şeması + çözüm tablosuyla yeniden işler; üç HTML basar.
#  Dönüşümler veri/fabrika/son10-donusum.json'da CACHE'lenir (kaldığı yerden
#  devam eder; tek-sefer-üretim ilkesi).
# ============================================================================
# 01.09 Cem: "her sinavdan 10, toplam 30" hizli okuma seti -> -TekSayfa -SinavBasina 10; DIKKAT: param adi $Adet OLAMAZ - dongudeki $adet sayaciyla cakisti (PS harf ayirmaz), First 10 yerine First 30 calisti (01.09 yasandi)
# uc sinavi TEK dosyada basar (son-karar-10x3.html); uclu 30'luk basim degismez.
param([int]$SinavBasina=10,[switch]$TekSayfa,[string]$Ders='')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$repoKok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$SONUC=Join-Path $repoKok 'veri\fabrika\sik90-sonuc.jsonl'
$CACHE=Join-Path $repoKok 'veri\fabrika\son10-donusum.json'
$SQLY=Join-Path $repoKok 'sql-yerel'

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }

# --- hedef 30 id: her sinavin 01-10'u ---
$hedefler=@()
foreach($sv in 'SGS','SMMM','KGK'){ foreach($n in 1..30){ $hedefler+=('p90-{0}-{1:d2}-' -f $sv,$n) } }

# --- kaynaklar ---
$kayn=@{}
foreach($sat in (Get-Content $SONUC -Encoding UTF8)){
  $r=$sat|ConvertFrom-Json
  foreach($h in $hedefler){ if($r.custom_id.StartsWith($h)){ $kayn[$r.custom_id]=Coz ((@($r.result.message.content)|? { $_.type -eq 'text' }|Select-Object -Last 1).text) } }
}
"kaynak: $($kayn.Count)/90"

# --- cache ---
$don=@{}
if(Test-Path $CACHE){ foreach($p in (Get-Content $CACHE -Raw -Encoding UTF8|ConvertFrom-Json).PSObject.Properties){ $don[$p.Name]=$p.Value } }
"cache: $($don.Count) hazir"

$istem=@'
Sen "Nobetci" adli hoca-yazarsin. Asagidaki sinav sorusunun SORU, SIKLAR ve DOGRU cevabi AYNEN kalacak; YALNIZ aciklama takimini KURAL 25 tonuyla yeniden yaz, KONSEPT SEMASI uret ve hesapli soruda COZUM TABLOSUNU koru/iyilestir.
KURAL 25: (a) dogru sikkin "Kural:" parcasi KURAL KOYUCUNUN DERDIYLE acilir (kural neden var), kunye cumle SONUNDA parantezde; (b) bes sikta TOPLAM en fazla 2 kunye; (c) "Dogrusu:" cumleleri kunyesiz saf insan dili; (d) dort parca + tuzak adi + Dogrusu + varsa Vaka taktigi korunur; (e) YENI iddia/rakam EKLEME - tek kaynak mevcut aciklama; (f) kar hep sapkali (kâr).
SEMA (soruya en uygun TEK tur; SORUNUN KENDI VERISIYLE konusur, jenerik YASAK; kayit/yevmiye soran soruda yevmiye ZORUNLU):
- "eleme": {"tur":"eleme","baslik":"...","ogeler":[{"aday":"...","sebep":"...","kalan":false},...]}
- "karar": {"tur":"karar","baslik":"...","kok":{"soru":"...?","evet":"kisa sonuc VEYA {soru,evet,hayir}","hayir":"..."}}
- "akis": {"tur":"akis","baslik":"...","ogeler":["adim",...]}
- "yevmiye": {"tur":"yevmiye","baslik":"...","ogeler":{"borc":[{"hesap":"...","tutar":"..."}],"alacak":[...]}}
COZUM_TABLO (hesapli soruda ZORUNLU): {"basliklar":[...],"satirlar":[[...],...]} - son satir SONUCTUR.
Cevap YALNIZ JSON: {"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","sinav_taktigi":"...","notlandirici":"...","sema":{...},"cozum_tablo":{...}}
=== SORU === {SORU}
SIKLAR: {SIKLAR}
DOGRU: {DOGRU}
=== MEVCUT ACIKLAMA TAKIMI (kaynagin) === {ESKI}
'@

$n=0
foreach($id in ($kayn.Keys | Sort-Object)){
  $n++
  if($don.ContainsKey($id)){ continue }
  $e=$kayn[$id]
  if(-not $e -or -not $e.soru){ Write-Host "  ATLA (kaynak bozuk): $id"; continue }
  $sik=(('A','B','C','D','E') | % { "$_) $($e.siklar.$_)" }) -join "`n"
  $eskiJson=ConvertTo-Json -InputObject ([ordered]@{aciklama=$e.aciklama;hap=$e.hap;sinav_taktigi=$e.sinav_taktigi;notlandirici=$e.notlandirici;dayanak=$e.dayanak;cozum_tablo=$e.cozum_tablo}) -Depth 6
  $ist=$istem.Replace('{SORU}',"$($e.soru)").Replace('{SIKLAR}',$sik).Replace('{DOGRU}',"$($e.dogru)").Replace('{ESKI}',$eskiJson)
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist -MaxTok 20000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $cvp=Coz $y.metin
  if($cvp -and $cvp.aciklama){
    $don[$id]=$cvp
    # her adimda cache yaz (kesinti guvenligi)
    $dNesne=[ordered]@{}; foreach($kk in ($don.Keys|Sort-Object)){ $dNesne[$kk]=$don[$kk] }
    [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dNesne -Depth 9),[Text.UTF8Encoding]::new($false))
    Write-Host "  OK [$($don.Count)/30] $id"
  } else { Write-Host "  BOZUK: $id" }
}
"donusum tamam: $($don.Count)/90"

# --- FAZ 2 (29.08 Cem: "adim adim yasatalim"): cozum_tablosu olan her soruya adim senaryosu ---
$adimIstem=@'
Sen "Nobetci" adli hocasin. Asagidaki SORU METNI, cozum tablosu ve aciklamadan ADIM ADIM COZUM SENARYOSU uret - ogrenci her tikta bir adim yasayacak, tablo hucre hucre dolacak. BU ANLATIM ISI HIC BILMEYENE YAPILIR.
ALTIN AYRIM (Cem kurali, 29.08): SORUDA VERILEN ile BIZIM HESAPLADIGIMIZ asla karismaz - "biz bunu bulmadik, soru verdi" hep belli olacak.
KURALLAR:
1. Once SORU METNINI oku ve cozum_tablo hucrelerinden hangileri SORUDA VERILI tespit et (fiili miktarlar, katsayilar, TOPLAM ORTAK MALIYET gibi buyuk tutarlar dahil - tabloda gecen ama soruda verilmis HER hucre) -> "verilen":[[satir,kolon],...] listesine yaz.
2. ADIM 1 = VERILENLER ADIMI: anlatimi "Soru bize sunlari vermis: ..." diliyle kur ve doldur listesinde TUM verilen hucreleri ac (240.000 gibi toplamlar dahil - sonradan "bulalim" DENMEZ, cunku soru verdi). ANLATIMDA BUYUK HARF VURGUSU YASAK - ayrim kelimeyle yapilir, bagirarak degil.
3. Sonraki adimlar HESAP adimlaridir: anlatim "simdi biz hesapliyoruz" dilinde (buyuk harf vurgusu YOK); her adim {"anlatim":"1-2 cumle, ne yapiyoruz ve NEDEN","formul":"OGRETMEN TAHTASI kurali: once GENEL formul, sonra sayili uygulanisi tek zincirde - ornek: 'Birim Esdeger Maliyet = Toplam Ortak Maliyet / Toplam Esdeger Miktar = 240.000 (soruda verilen) / 6.000 (onceki adimda bulduk) = 40 TL' - formuldeki HER sayinin kimligi parantezle belli olur: (soruda verilen) ya da (N. adimda bulduk); formul tek basina konuyu anlatir (yoksa bos)","doldur":[[r,c],...]} (0-indexli; kumulatif DEGIL). Son adim: SONUC satiri.
4. 5-8 adim. Rakamlar TABLODAKIYLE BIREBIR; yeni rakam uretme.
Cevap YALNIZ JSON: {"verilen":[[r,c],...],"adimlar":[...]}
SORU METNI: {SORUM}
COZUM_TABLO: {TABLO}
ACIKLAMA (dogru sik): {ACIK}
'@
$af=0
foreach($id in ($don.Keys | Sort-Object)){
  $cvp=$don[$id]
  if(-not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar -or @($cvp.cozum_tablo.satirlar).Count -eq 0){ continue }
  # 'verilen' alani yoksa ESKI senaryodur -> Cem'in verilen/hesaplanan ayrimi kuraliyla YENIDEN uret
  if($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar -and $cvp.PSObject.Properties['verilen']){ continue }
  $ist2=$adimIstem.Replace('{SORUM}',"$($kayn[$id].soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress)).Replace('{ACIK}',"$($cvp.aciklama.$($kayn[$id].dogru))")
  $y2=$null
  foreach($d in 1..3){ try{ $y2=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist2 -MaxTok 8000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $t2="$($y2.metin)".Trim() -replace '^```json\s*','' -replace '\s*```$',''
  $a2=$null; try{ $a2=$t2|ConvertFrom-Json }catch{}
  if($a2 -and $a2.adimlar){
    $cvp | Add-Member -NotePropertyName adimlar -NotePropertyValue $a2.adimlar -Force
    $cvp | Add-Member -NotePropertyName verilen -NotePropertyValue @($a2.verilen) -Force
    $af++
    $dNesne=[ordered]@{}; foreach($kk in ($don.Keys|Sort-Object)){ $dNesne[$kk]=$don[$kk] }
    [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dNesne -Depth 10),[Text.UTF8Encoding]::new($false))
    Write-Host "  ADIM OK [$af] $id ($(@($a2.adimlar).Count) adim)"
  } else { Write-Host "  ADIM BOZUK: $id" }
}
"adim senaryolari: $af yeni"

# --- cizdiriciler ---
function TabloHtml($t,$ver){
  if(-not $t -or -not $t.satirlar -or @($t.satirlar).Count -eq 0){ return '' }
  $verSet=@{}
  foreach($vv in @($ver)){ if($vv -and @($vv).Count -ge 2){ $verSet["$(@($vv)[0]),$(@($vv)[1])"]=1 } }
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<div style='font-weight:800;font-size:.9em;color:#78b4ff;margin-top:12px'>📊 Çözüm tablosu</div>")
  if($verSet.Count -gt 0){ [void]$sb.Append("<div style='font-size:.78em;color:#78b4ff;margin-top:3px'>🔷 mavi kenarlı hücreler <b>soruda VERİLENLERDİR</b> — biz bulmadık, soru verdi; kalanları biz hesapladık</div>") }
  [void]$sb.Append("<table class='tcetvel'><tr>")
  foreach($b in @($t.basliklar)){ [void]$sb.Append("<th>$(K $b)</th>") }
  [void]$sb.Append('</tr>')
  $ns=@($t.satirlar).Count; $q=0
  foreach($st in @($t.satirlar)){
    $q++
    $stil=''; if($q -eq $ns){ $stil=" style='background:rgba(143,201,143,.12);font-weight:800'" }
    [void]$sb.Append("<tr$stil>")
    $kc=0
    foreach($hc in @($st)){
      # 29.08 Cem: KALEM kolonu (c=0) ISKELETTIR - oynatici gizleyemez, 'gelir tablosu gibi' hep okunur
      if($kc -eq 0){ [void]$sb.Append("<td class='hbaslik' style='font-weight:600'>$(K $hc)</td>") }
      else{
        $vcls=''; if($verSet.ContainsKey("$($q-1),$kc")){ $vcls=' verilen' }
        [void]$sb.Append("<td class='hcell$vcls' data-r='$($q-1)' data-c='$kc'>$(K $hc)</td>")
      }
      $kc++
    }
    [void]$sb.Append('</tr>')
  }
  [void]$sb.Append('</table>')
  return $sb.ToString()
}
function SemaHtml($s){
  if(-not $s -or -not $s.tur){ return '' }
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<div class='sema'><div class='semabaslik'>🗺️ $(K $s.baslik)</div>")
  switch("$($s.tur)"){
    'eleme'{
      foreach($og in @($s.ogeler)){
        $isr='✗'; $rk='#e07b7b'; $st='opacity:.85'
        if($og.kalan){ $isr='✓'; $rk='#8fc98f'; $st='background:rgba(143,201,143,.10)' }
        [void]$sb.Append("<div class='elemasatir' style='border-left:3px solid $rk;$st'><span style='color:$rk;font-weight:900;min-width:16px'>$isr</span><span class='elemaaday'>$(K $og.aday)</span><span style='color:$rk;font-size:.84em;flex:1'>$(K $og.sebep)</span></div>")
      }
    }
    'akis'{ [void]$sb.Append("<div class='akis'>" + ((@($s.ogeler) | % { "<span class='akisadim'>$(K $_)</span>" }) -join "<span class='akisok'>→</span>") + "</div>") }
    'yevmiye'{
      [void]$sb.Append("<table class='tcetvel'><tr><th colspan='2'>BORÇ</th><th colspan='2'>ALACAK</th></tr>")
      $bl=@($s.ogeler.borc); $al=@($s.ogeler.alacak); $ns=[Math]::Max($bl.Count,$al.Count)
      for($q=0;$q -lt $ns;$q++){
        $bh='';$bt='';$ah='';$at=''
        if($q -lt $bl.Count){ $bh=K $bl[$q].hesap; $bt=K $bl[$q].tutar }
        if($q -lt $al.Count){ $ah=K $al[$q].hesap; $at=K $al[$q].tutar }
        [void]$sb.Append("<tr><td>$bh</td><td class='ttutar'>$bt</td><td style='padding-left:26px'>$ah</td><td class='ttutar'>$at</td></tr>")
      }
      [void]$sb.Append("</table>")
    }
    'karar'{
      function DugumMu($nn){ return ($nn -isnot [string]) -and $nn.PSObject -and $nn.PSObject.Properties['soru'] }
      function Yap($nn){ if(DugumMu $nn){ return (Yap $nn.evet)+(Yap $nn.hayir) }; return 1 }
      function Derin($nn){ if(DugumMu $nn){ return 1+[Math]::Max((Derin $nn.evet),(Derin $nn.hayir)) }; return 0 }
      $BW=205.0;$GAP=14.0;$LH=112.0;$BH=62.0
      $kk=$s.kok; if(-not $kk -and $s.ogeler){ $kk=@($s.ogeler)[0] }
      if($kk){
        $W=[Math]::Max(430,[int]((Yap $kk)*($BW+$GAP))); $Hh=[int](20+((Derin $kk)+1)*$LH)
        $sv=[Text.StringBuilder]::new()
        [void]$sv.Append("<svg viewBox='0 0 $W $Hh' style='width:100%;max-width:${W}px;height:auto;display:block;margin:0 auto' xmlns='http://www.w3.org/2000/svg'><defs><marker id='sok' markerWidth='7' markerHeight='7' refX='5' refY='3.5' orient='auto'><path d='M0,0 L7,3.5 L0,7 z' fill='#8ab'/></marker></defs>")
        function Yerles($nn,[double]$x0,[int]$sev,[string]$dal){
          $y=10+$sev*$LH
          if(-not (DugumMu $nn)){
            $cx=($x0+0.5)*($BW+$GAP); $rk='#8fc98f'; if($dal -eq 'hayir'){ $rk='#e07b7b' }
            [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.6px solid $rk;border-radius:10px;color:$rk;font-size:12px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(0,0,0,.25)'>$(K "$nn")</div></foreignObject>")
            return @($cx,1)
          }
          $sol=Yerles $nn.evet $x0 ($sev+1) 'evet'
          $sag=Yerles $nn.hayir ($x0+$sol[1]) ($sev+1) 'hayir'
          $cx=($sol[0]+$sag[0])/2
          [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.8px solid #78b4ff;border-radius:10px;color:#e8e6e3;font-weight:700;font-size:12.5px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(120,180,255,.10)'>$(K "$($nn.soru)")</div></foreignObject>")
          $py=$y+$BH; $cy=10+($sev+1)*$LH
          foreach($cf in @(@($sol[0],'EVET','#8fc98f'),@($sag[0],'HAYIR','#e07b7b'))){
            [void]$sv.Append("<path d='M $([int]$cx) $([int]$py) C $([int]$cx) $([int]($py+28)), $([int]$cf[0]) $([int]($cy-28)), $([int]$cf[0]) $([int]$cy)' fill='none' stroke='$($cf[2])' stroke-width='1.6' marker-end='url(#sok)'/>")
            [void]$sv.Append("<text x='$([int](($cx+$cf[0])/2))' y='$([int](($py+$cy)/2))' fill='$($cf[2])' font-size='11' font-weight='800' text-anchor='middle' style='paint-order:stroke;stroke:#1b1b1f;stroke-width:4px'>$($cf[1])</text>")
          }
          return @($cx,($sol[1]+$sag[1]))
        }
        [void](Yerles $kk 0.0 0 '')
        [void]$sv.Append("</svg>")
        [void]$sb.Append($sv.ToString())
      }
    }
  }
  [void]$sb.Append("</div>")
  return $sb.ToString()
}

# --- plan etiketi (ders/konu/tip) ---
$plan=@{}
foreach($x in @((Get-Content (Join-Path $repoKok 'veri\fabrika\sik90-plan.json') -Raw -Encoding UTF8|ConvertFrom-Json)|%{$_})){ $plan["$($x.custom_id)"]=$x }

$css=@'
body{font-family:Segoe UI,sans-serif;max-width:920px;margin:20px auto;padding:0 16px;background:#1b1b1f;color:#e8e6e3}
.soru{border:1px solid #444;border-radius:12px;padding:16px;margin:18px 0}
.tip{display:inline-block;font-size:11.5px;font-weight:900;border-radius:999px;padding:4px 12px;margin-bottom:10px;border:1px solid rgba(120,180,255,.5);background:rgba(120,180,255,.08)}
.konu{display:inline-block;font-size:11px;color:#aaa;margin-left:8px}
.dogru{color:#7fc98f;font-weight:600}.sik{margin:3px 0;font-size:.95em}
.ac{background:#26262c;border-radius:8px;padding:12px;margin-top:12px;font-size:.92em;line-height:1.55}
.ac b{color:#c9a227}
.kutu{border-left:3px solid #78b4ff;background:rgba(120,180,255,.07);border-radius:0 8px 8px 0;padding:8px 11px;margin-top:8px;font-size:.88em}
.kutu2{border-left:3px solid #c9a227;background:rgba(201,162,39,.07);border-radius:0 8px 8px 0;padding:8px 11px;margin-top:8px;font-size:.88em}
.sema{border:1px dashed #7fc98f;border-radius:10px;padding:10px;margin-top:12px;background:rgba(127,201,143,.05)}
.semabaslik{font-weight:800;color:#7fc98f;margin-bottom:8px;font-size:.92em}
.elemasatir{display:flex;align-items:center;gap:10px;padding:6px 10px;margin:5px 0;border-radius:0 8px 8px 0;background:rgba(224,123,123,.05)}
.elemaaday{font-weight:700;font-size:.88em;min-width:38%}
.akis{display:flex;flex-wrap:wrap;gap:6px;align-items:center}
.akisadim{border:1px solid #78b4ff;border-radius:999px;padding:4px 10px;font-size:.84em}
.akisok{color:#78b4ff;font-weight:900}
table.tcetvel{border-collapse:collapse;margin-top:6px;font-size:.88em;width:100%}
.tcetvel th{border-bottom:2px solid #7fc98f;color:#7fc98f;padding:4px 8px;text-align:left}
.tcetvel td{padding:4px 8px;border-bottom:1px dotted #444}
.ttutar{text-align:right;color:#c9a227;font-weight:700}
h1{font-size:1.3em}
.hcell.gizli{color:transparent;text-shadow:none}
.hcell.verilen{box-shadow:inset 3px 0 0 #78b4ff}
.hcell.parla{animation:parla .9s ease}
@keyframes parla{0%{background:rgba(224,164,88,.55)}100%{background:transparent}}
.padim{background:#c9a227;color:#1b1b1f;font-weight:800;border:none;border-radius:8px;padding:8px 14px;cursor:pointer;font-family:inherit;margin-top:10px}
.panlat{display:none;border:1px solid #c9a227;border-radius:10px;padding:10px 12px;margin-top:8px;background:rgba(201,162,39,.07)}
.psayac{font-size:.76em;color:#c9a227;font-weight:800}
.pformul{margin-top:6px;font-family:Consolas,monospace;font-size:.98em;color:#8fd0ff;background:rgba(120,180,255,.10);border:1px solid rgba(120,180,255,.35);border-radius:8px;padding:8px 12px}
.pformul:empty{display:none}
/* 01.09 Cem "UCUNU KUR": adim-1 verilenleri tablo halinde */
.vtab{border-collapse:collapse;width:100%;font-size:.95em;font-family:inherit}
.vtab th{color:#8fd0ff;border-bottom:2px solid rgba(120,180,255,.45);text-align:left;padding:4px 9px;font-size:.85em}
.vtab td{padding:4px 9px;border-bottom:1px dotted rgba(120,180,255,.30)}
'@
$sinavAd=@{ 'SGS'='Staja Giriş (SGS)'; 'SMMM'='SMMM Yeterlilik'; 'KGK'='KGK Bağımsız Denetçilik' }
foreach($sv in 'SGS','SMMM','KGK'){
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><title>$($sinavAd[$sv]) — Son Kararla 30 Soru</title><style>$css</style></head><body>")
  [void]$sb.Append("<h1>$($sinavAd[$sv]) — en çok çıkan 30 konu, SON KARAR standardıyla — SON OKUMA PARTİSİ</h1><p style='color:#aaa;font-size:13.5px'>29.08.2026 · Kural 25 (önce mantık + madde diyeti) + konsept şeması + çözüm tablosu. KASAYA YAZILMADI.</p>")
  $adet=0
  foreach($id in ($don.Keys | ? { $_ -match "^p90-$sv-" } | Sort-Object)){
    $e=$kayn[$id]; $cvp=$don[$id]; $pp=$plan[$id]
    if(-not $e -or -not $cvp){ continue }
    $adet++
    $adVar=($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar)
    [void]$sb.Append("<div class='soru' data-sid='$id'><span class='tip'>$($pp.tip)</span><span class='konu'>#$adet · $($pp.ders) · $(K $pp.konu)</span>")
    [void]$sb.Append("<p><b>$(K $e.soru)</b></p>")
    foreach($hh in 'A','B','C','D','E'){
      $cls='sik'; if("$($e.dogru)" -eq $hh){ $cls='sik dogru' }
      [void]$sb.Append("<div class='$cls'>$hh) $(K $e.siklar.$hh)</div>")
    }
    [void]$sb.Append("<div class='ac'>")
    foreach($hh in 'A','B','C','D','E'){
      $isr=''; if("$($e.dogru)" -eq $hh){ $isr=' ✓' }
      [void]$sb.Append("<p><b>$hh$isr)</b> $(K $cvp.aciklama.$hh)</p>")
    }
    if($adVar){ [void]$sb.Append("<div><button class='padim'>🎬 Bu çözümü adım adım yaşa</button><div class='panlat'><div class='psayac'></div><div class='pformul'></div><div class='pmetin' style='margin-top:6px;font-size:.93em'></div><button class='padim pileri' style='margin-top:8px;padding:6px 12px;font-size:.85em'>İleri →</button></div></div>") }
    $verList=$null; if($cvp.PSObject.Properties['verilen']){ $verList=$cvp.verilen }
    [void]$sb.Append((TabloHtml $cvp.cozum_tablo $verList))
    [void]$sb.Append((SemaHtml $cvp.sema))
    if($cvp.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $cvp.sinav_taktigi)</div>") }
    if($cvp.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $cvp.notlandirici)</div>") }
    if($cvp.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $cvp.hap)</div>") }
    [void]$sb.Append("</div></div>")
  }
  # adim haritasi (yalniz bu sinavin sorulari)
  $amap=[ordered]@{}
  foreach($id2 in ($don.Keys | ? { $_ -match "^p90-$sv-" })){ $c2=$don[$id2]; if($c2.PSObject.Properties['adimlar'] -and $c2.adimlar){ $amap[$id2]=@($c2.adimlar) } }
  $amapJson='{}'
  if($amap.Count -gt 0){ $amapJson=ConvertTo-Json -InputObject $amap -Depth 7 -Compress }
  # 01.09 Cem "UCUNU KUR": adim-1 icin VERILENLER TABLOSU - LLM'siz, verilen koordinatlarindan turetilir
  $vmap=[ordered]@{}
  foreach($id2 in $amap.Keys){
    $c2=$don[$id2]
    if(-not ($c2.PSObject.Properties['verilen'] -and $c2.verilen -and $c2.cozum_tablo)){ continue }
    $vb=[Text.StringBuilder]::new()
    [void]$vb.Append("<div style='font-weight:800;font-size:.8em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
    $ok=$true
    foreach($vv in @($c2.verilen)){
      $r=@($vv)[0]; $c=@($vv)[1]
      $sat=@(@($c2.cozum_tablo.satirlar)[$r])
      if($null -eq $sat -or $c -ge @($sat).Count){ $ok=$false; break }
      [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($c2.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
    }
    [void]$vb.Append('</table>')
    if($ok){ $vmap[$id2]=$vb.ToString() }
  }
  $vmapJson='{}'
  if($vmap.Count -gt 0){ $vmapJson=ConvertTo-Json -InputObject $vmap -Depth 3 -Compress }
  [void]$sb.Append(@"
<script>
const ADIMMAP=$amapJson;
const VTMAP=$vmapJson;
document.querySelectorAll('.soru').forEach(soru=>{
  const sid=soru.dataset.sid, adimlar=ADIMMAP[sid];
  const btn=soru.querySelector('.padim:not(.pileri)');
  if(!adimlar||!btn) return;
  const pan=soru.querySelector('.panlat'), say=soru.querySelector('.psayac'),
        met=soru.querySelector('.pmetin'), frm=soru.querySelector('.pformul'),
        ile=soru.querySelector('.pileri');
  const hcs=()=>soru.querySelectorAll('.hcell');
  const hc=(r,c)=>soru.querySelector(".hcell[data-r='"+r+"'][data-c='"+c+"']");
  let ad=-1;
  const g=()=>{
    const s=adimlar[ad];
    say.textContent='ADIM '+(ad+1)+' / '+adimlar.length;
    met.textContent=s.anlatim;
    if(ad===0&&VTMAP[sid]){ frm.innerHTML=VTMAP[sid]; }
    else { frm.textContent=s.formul||''; }
    (s.doldur||[]).forEach(k=>{const el=hc(k[0],k[1]); if(el){el.classList.remove('gizli'); el.classList.add('parla'); setTimeout(()=>el.classList.remove('parla'),950);}});
    if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.remove('gizli')); } // son adimda acik hucre kalmaz
    ile.textContent=(ad===adimlar.length-1)?'🔄 Baştan':'İleri →';
  };
  btn.addEventListener('click',()=>{ hcs().forEach(el=>el.classList.add('gizli')); btn.style.display='none'; pan.style.display='block'; ad=0; g(); });
  ile.addEventListener('click',()=>{ if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.add('gizli')); ad=0; g(); return; } ad++; g(); });
});
</script>
"@)
  [void]$sb.Append("</body></html>")
  $hedef=Join-Path $SQLY ("son-karar-30-{0}.html" -f $sv)
  [IO.File]::WriteAllText($hedef,$sb.ToString(),[Text.UTF8Encoding]::new($false))
  "yazildi: son-karar-30-$sv.html ($adet soru)"
}

# === 01.09 TEK SAYFA MODU (Cem: "her sinavdan 10 toplam 30 - Finansal Muhasebe
# olsun, tablo gorelim") ==================================================
# -TekSayfa: uc sinavi TEK dosyada basar. -Ders 'Muhasebe': ders adi eslesen VE
# COZUM TABLOLU sorular (Cem tabloyu gormek istiyor - tablosuz girmez).
# Render kodu yukaridaki donguyle AYNI tutulur (degisiklik ikisine birden islenir).
if($TekSayfa){
  $sb=[Text.StringBuilder]::new()
  $etiket=$(if($Ders){"$Ders (tablolu)"}else{'karma'})
  [void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><title>Her Sınavdan $SinavBasina — $etiket</title><style>$css</style></head><body>")
  [void]$sb.Append("<h1>Her sınavdan $SinavBasina soru — $etiket — HIZLI OKUMA SETİ</h1><p style='color:#aaa;font-size:13.5px'>01.09.2026 · en güncel kalıp (verilenler tablosu dahil). KASAYA YAZILMADI.</p>")
  $secilenTum=@()
  foreach($sv in 'SGS','SMMM','KGK'){
    $idler=@($don.Keys | ? { $_ -match "^p90-$sv-" } | Sort-Object | ? {
      $c2=$don[$_]
      $dOk=(-not $Ders) -or ("$($plan[$_].ders)" -match $Ders)
      $tOk=(-not $Ders) -or ($c2.cozum_tablo -and @($c2.cozum_tablo.satirlar).Count -gt 0)
      $dOk -and $tOk
    } | Select-Object -First $SinavBasina)
    $secilenTum+=$idler
    [void]$sb.Append("<h1 style='margin-top:34px;border-top:2px solid #444;padding-top:18px'>$($sinavAd[$sv]) — $(@($idler).Count) soru</h1>")
    $adet=0
    foreach($id in $idler){
      $e=$kayn[$id]; $cvp=$don[$id]; $pp=$plan[$id]
      if(-not $e -or -not $cvp){ continue }
      $adet++
      $adVar=($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar)
      [void]$sb.Append("<div class='soru' data-sid='$id'><span class='tip'>$($pp.tip)</span><span class='konu'>#$adet · $($pp.ders) · $(K $pp.konu)</span>")
      [void]$sb.Append("<p><b>$(K $e.soru)</b></p>")
      foreach($hh in 'A','B','C','D','E'){
        $cls='sik'; if("$($e.dogru)" -eq $hh){ $cls='sik dogru' }
        [void]$sb.Append("<div class='$cls'>$hh) $(K $e.siklar.$hh)</div>")
      }
      [void]$sb.Append("<div class='ac'>")
      foreach($hh in 'A','B','C','D','E'){
        $isr=''; if("$($e.dogru)" -eq $hh){ $isr=' ✓' }
        [void]$sb.Append("<p><b>$hh$isr)</b> $(K $cvp.aciklama.$hh)</p>")
      }
      if($adVar){ [void]$sb.Append("<div><button class='padim'>🎬 Bu çözümü adım adım yaşa</button><div class='panlat'><div class='psayac'></div><div class='pformul'></div><div class='pmetin' style='margin-top:6px;font-size:.93em'></div><button class='padim pileri' style='margin-top:8px;padding:6px 12px;font-size:.85em'>İleri →</button></div></div>") }
      $verList=$null; if($cvp.PSObject.Properties['verilen']){ $verList=$cvp.verilen }
      [void]$sb.Append((TabloHtml $cvp.cozum_tablo $verList))
      [void]$sb.Append((SemaHtml $cvp.sema))
      if($cvp.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $cvp.sinav_taktigi)</div>") }
      if($cvp.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $cvp.notlandirici)</div>") }
      if($cvp.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $cvp.hap)</div>") }
      [void]$sb.Append("</div></div>")
    }
  }
  # birlesik adim + verilenler haritalari (yalniz secilen sorular)
  $amap=[ordered]@{}; $vmap=[ordered]@{}
  foreach($id2 in $secilenTum){
    $c2=$don[$id2]
    if($c2.PSObject.Properties['adimlar'] -and $c2.adimlar){ $amap[$id2]=@($c2.adimlar) }
    if($c2.PSObject.Properties['verilen'] -and $c2.verilen -and $c2.cozum_tablo){
      $vb=[Text.StringBuilder]::new()
      [void]$vb.Append("<div style='font-weight:800;font-size:.8em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
      $ok=$true
      foreach($vv in @($c2.verilen)){
        $r=@($vv)[0]; $c=@($vv)[1]
        $sat=@(@($c2.cozum_tablo.satirlar)[$r])
        if($null -eq $sat -or $c -ge @($sat).Count){ $ok=$false; break }
        [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($c2.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
      }
      [void]$vb.Append('</table>')
      if($ok){ $vmap[$id2]=$vb.ToString() }
    }
  }
  $amapJson='{}'; if($amap.Count -gt 0){ $amapJson=ConvertTo-Json -InputObject $amap -Depth 7 -Compress }
  $vmapJson='{}'; if($vmap.Count -gt 0){ $vmapJson=ConvertTo-Json -InputObject $vmap -Depth 3 -Compress }
  [void]$sb.Append(@"
<script>
const ADIMMAP=$amapJson;
const VTMAP=$vmapJson;
document.querySelectorAll('.soru').forEach(soru=>{
  const sid=soru.dataset.sid, adimlar=ADIMMAP[sid];
  const btn=soru.querySelector('.padim:not(.pileri)');
  if(!adimlar||!btn) return;
  const pan=soru.querySelector('.panlat'), say=soru.querySelector('.psayac'),
        met=soru.querySelector('.pmetin'), frm=soru.querySelector('.pformul'),
        ile=soru.querySelector('.pileri');
  const hcs=()=>soru.querySelectorAll('.hcell');
  const hc=(r,c)=>soru.querySelector(".hcell[data-r='"+r+"'][data-c='"+c+"']");
  let ad=-1;
  const g=()=>{
    const s=adimlar[ad];
    say.textContent='ADIM '+(ad+1)+' / '+adimlar.length;
    met.textContent=s.anlatim;
    if(ad===0&&VTMAP[sid]){ frm.innerHTML=VTMAP[sid]; }
    else { frm.textContent=s.formul||''; }
    (s.doldur||[]).forEach(k=>{const el=hc(k[0],k[1]); if(el){el.classList.remove('gizli'); el.classList.add('parla'); setTimeout(()=>el.classList.remove('parla'),950);}});
    if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.remove('gizli')); }
    ile.textContent=(ad===adimlar.length-1)?'🔄 Baştan':'İleri →';
  };
  btn.addEventListener('click',()=>{ hcs().forEach(el=>el.classList.add('gizli')); btn.style.display='none'; pan.style.display='block'; ad=0; g(); });
  ile.addEventListener('click',()=>{ if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.add('gizli')); ad=0; g(); return; } ad++; g(); });
});
</script>
"@)
  [void]$sb.Append("</body></html>")
  $tekAd='son-karar-10x3.html'
  if($Ders){ $kisa=($Ders.ToLower() -replace '[^a-z]',''); if($kisa.Length -gt 12){ $kisa=$kisa.Substring(0,12) }; $tekAd="son-karar-$kisa-10x3.html" }
  $hedefT=Join-Path $SQLY $tekAd
  [IO.File]::WriteAllText($hedefT,$sb.ToString(),[Text.UTF8Encoding]::new($false))
  "yazildi (TEK SAYFA): $tekAd ($(@($secilenTum).Count) soru)"
}
