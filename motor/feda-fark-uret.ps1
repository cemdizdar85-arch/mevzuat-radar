# ============================================================================
#  FEDA + FARK SAYFASI ÜRETİCİ v2 (29.08; Cem: kahraman = EN ÇOK ÇIKAN konu)
#  Parametreli: istenen 90'lık sorusunu kural-25 tonuyla FEDA'ya çevirir ve
#  "1 soru çöz, farkı gör" (fark.html) sayfasını basar. Hesaplı sorularda
#  cozum_tablo desteklenir. FEDA bilerek herkese açıktır, kasaya girmez.
#  DERS (iki kez yaşandı): PS harf ayırmaz — yol=$FEDA_YOL, nesne=$fedaNesne;
#  WriteAllText'e nesne geçerse ToString'i DOSYA ADI olur (sessiz kaçak).
# ============================================================================
param([string]$ID='p90-SGS-01-hesapli',[string]$fedaAd='feda-ornek-1.json')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$repoKok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$SONUC=Join-Path $repoKok 'veri\fabrika\sik90-sonuc.jsonl'
$FEDA_YOL=Join-Path $repoKok ('veri\'+$fedaAd)
$HEDEF=Join-Path $repoKok 'fark.html'

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }

# --- 1) kaynak soru ---
$eski=$null
foreach($sat in (Get-Content $SONUC -Encoding UTF8)){
  $r=$sat|ConvertFrom-Json
  if($r.custom_id -eq $ID){ $eski=Coz ((@($r.result.message.content)|? { $_.type -eq 'text' }|Select-Object -Last 1).text); break }
}
if(-not $eski -or -not $eski.soru){ throw "kaynak soru bulunamadi: $ID" }

# --- 2) feda uret (gecerli dosya varsa yeniden uretme) ---
$veri=$null
if(Test-Path $FEDA_YOL){
  $veri=Get-Content $FEDA_YOL -Raw -Encoding UTF8 | ConvertFrom-Json
  if(-not $veri.soru){ Remove-Item $FEDA_YOL -Force; $veri=$null; Write-Host 'bozuk feda silindi - yeniden uretilecek' }
  else { Write-Host "feda mevcut: $fedaAd" }
}
if(-not $veri){
  $istem=@'
Sen "Nobetci" adli hoca-yazarsin. Asagidaki sinav sorusunun SORU, SIKLAR ve DOGRU cevabi AYNEN kalacak; YALNIZ aciklama takimini KURAL 25 tonuyla yeniden yaz, KONSEPT SEMASI uret ve hesapli soruda COZUM TABLOSUNU koru/iyilestir.
KURAL 25: (a) dogru sikkin "Kural:" parcasi KURAL KOYUCUNUN DERDIYLE acilir (kural neden var), kunye cumle SONUNDA parantezde; (b) bes sikta TOPLAM en fazla 2 kunye; (c) "Dogrusu:" cumleleri kunyesiz saf insan dili; (d) dort parca + tuzak adi + Dogrusu korunur; (e) YENI iddia/rakam EKLEME - tek kaynak mevcut aciklama; (f) kar hep sapkali (kâr).
SEMA (soruya en uygun TEK tur; SORUNUN KENDI VERISIYLE konusur, jenerik YASAK):
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
  $sik=(('A','B','C','D','E') | % { "$_) $($eski.siklar.$_)" }) -join "`n"
  $eskiJson=ConvertTo-Json -InputObject ([ordered]@{aciklama=$eski.aciklama;hap=$eski.hap;sinav_taktigi=$eski.sinav_taktigi;notlandirici=$eski.notlandirici;dayanak=$eski.dayanak;cozum_tablo=$eski.cozum_tablo}) -Depth 6
  $ist=$istem.Replace('{SORU}',"$($eski.soru)").Replace('{SIKLAR}',$sik).Replace('{DOGRU}',"$($eski.dogru)").Replace('{ESKI}',$eskiJson)
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist -MaxTok 20000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $cvp=Coz $y.metin
  if(-not $cvp -or -not $cvp.aciklama){ throw 'yeniden yazim bozuk' }
  $fedaNesne=[ordered]@{
    kaynak_not='FEDA ORNEGI - bilerek herkese acik; kasaya girmez'
    soru=$eski.soru; siklar=$eski.siklar; dogru=$eski.dogru
    aciklama=$cvp.aciklama; hap=$cvp.hap; sinav_taktigi=$cvp.sinav_taktigi
    notlandirici=$cvp.notlandirici; dayanak=$eski.dayanak
    sema=$cvp.sema; cozum_tablo=$cvp.cozum_tablo
  }
  [IO.File]::WriteAllText($FEDA_YOL,(ConvertTo-Json -InputObject $fedaNesne -Depth 7),[Text.UTF8Encoding]::new($false))
  if(-not (Test-Path $FEDA_YOL)){ throw 'FEDA yazilamadi (yol kontrolu!)' }
  Write-Host "feda uretildi: $fedaAd"
  $veri=Get-Content $FEDA_YOL -Raw -Encoding UTF8 | ConvertFrom-Json
}

# --- 3) cizdiriciler ---
function TabloHtml($t){
  if(-not $t -or -not $t.satirlar -or @($t.satirlar).Count -eq 0){ return '' }
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<div style='font-weight:800;font-size:.9em;color:#78b4ff;margin-top:12px'>📊 Çözüm tablosu</div><table class='tcetvel'><tr>")
  foreach($b in @($t.basliklar)){ [void]$sb.Append("<th>$(K $b)</th>") }
  [void]$sb.Append('</tr>')
  $n=@($t.satirlar).Count; $q=0
  foreach($st in @($t.satirlar)){
    $q++
    $stil=''; if($q -eq $n){ $stil=" style='background:rgba(143,201,143,.12);font-weight:800'" }
    [void]$sb.Append("<tr$stil>")
    foreach($hc in @($st)){ [void]$sb.Append("<td>$(K $hc)</td>") }
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
      $bl=@($s.ogeler.borc); $al=@($s.ogeler.alacak); $n=[Math]::Max($bl.Count,$al.Count)
      for($q=0;$q -lt $n;$q++){
        $bh='';$bt='';$ah='';$at=''
        if($q -lt $bl.Count){ $bh=K $bl[$q].hesap; $bt=K $bl[$q].tutar }
        if($q -lt $al.Count){ $ah=K $al[$q].hesap; $at=K $al[$q].tutar }
        [void]$sb.Append("<tr><td>$bh</td><td class='ttutar'>$bt</td><td style='padding-left:26px'>$ah</td><td class='ttutar'>$at</td></tr>")
      }
      [void]$sb.Append("</table>")
    }
    'karar'{
      function DugumMu($n){ return ($n -isnot [string]) -and $n.PSObject -and $n.PSObject.Properties['soru'] }
      function Yap($n){ if(DugumMu $n){ return (Yap $n.evet)+(Yap $n.hayir) }; return 1 }
      function Derin($n){ if(DugumMu $n){ return 1+[Math]::Max((Derin $n.evet),(Derin $n.hayir)) }; return 0 }
      $BW=205.0;$GAP=14.0;$LH=112.0;$BH=62.0
      $kk=$s.kok; if(-not $kk -and $s.ogeler){ $kk=@($s.ogeler)[0] }
      if($kk){
        $W=[Math]::Max(430,[int]((Yap $kk)*($BW+$GAP))); $Hh=[int](20+((Derin $kk)+1)*$LH)
        $sv=[Text.StringBuilder]::new()
        [void]$sv.Append("<svg viewBox='0 0 $W $Hh' style='width:100%;max-width:${W}px;height:auto;display:block;margin:0 auto' xmlns='http://www.w3.org/2000/svg'><defs><marker id='fok' markerWidth='7' markerHeight='7' refX='5' refY='3.5' orient='auto'><path d='M0,0 L7,3.5 L0,7 z' fill='#8ab'/></marker></defs>")
        function Yerles($n,[double]$x0,[int]$sev,[string]$dal){
          $y=10+$sev*$LH
          if(-not (DugumMu $n)){
            $cx=($x0+0.5)*($BW+$GAP); $rk='#8fc98f'; if($dal -eq 'hayir'){ $rk='#e07b7b' }
            [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.6px solid $rk;border-radius:10px;color:$rk;font-size:12px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(0,0,0,.25)'>$(K "$n")</div></foreignObject>")
            return @($cx,1)
          }
          $sol=Yerles $n.evet $x0 ($sev+1) 'evet'
          $sag=Yerles $n.hayir ($x0+$sol[1]) ($sev+1) 'hayir'
          $cx=($sol[0]+$sag[0])/2
          [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.8px solid #e0a458;border-radius:10px;color:#e8e4dc;font-weight:700;font-size:12.5px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(224,164,88,.10)'>$(K "$($n.soru)")</div></foreignObject>")
          $py=$y+$BH; $cy=10+($sev+1)*$LH
          foreach($cf in @(@($sol[0],'EVET','#8fc98f'),@($sag[0],'HAYIR','#e07b7b'))){
            [void]$sv.Append("<path d='M $([int]$cx) $([int]$py) C $([int]$cx) $([int]($py+28)), $([int]$cf[0]) $([int]($cy-28)), $([int]$cf[0]) $([int]$cy)' fill='none' stroke='$($cf[2])' stroke-width='1.6' marker-end='url(#fok)'/>")
            [void]$sv.Append("<text x='$([int](($cx+$cf[0])/2))' y='$([int](($py+$cy)/2))' fill='$($cf[2])' font-size='11' font-weight='800' text-anchor='middle' style='paint-order:stroke;stroke:#161513;stroke-width:4px'>$($cf[1])</text>")
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

# --- 4) fark.html ---
$acSb=[Text.StringBuilder]::new()
foreach($hh in 'A','B','C','D','E'){
  $isr=''; if("$($veri.dogru)" -eq $hh){ $isr=' ✓' }
  [void]$acSb.Append("<p><b>$hh$isr)</b> $(K $veri.aciklama.$hh)</p>")
}
$acBlok=$acSb.ToString()
$tabloBlok=TabloHtml $veri.cozum_tablo
$semaBlok=SemaHtml $veri.sema
$sikSb=[Text.StringBuilder]::new()
foreach($hh in 'A','B','C','D','E'){
  [void]$sikSb.Append("<button class='sik' data-h='$hh'>$hh) $(K $veri.siklar.$hh)</button>")
}
$taktikBlok=''; if($veri.sinav_taktigi){ $taktikBlok="<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $veri.sinav_taktigi)</div>" }
$notBlok=''; if($veri.notlandirici){ $notBlok="<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $veri.notlandirici)</div>" }
$hapBlok=''; if($veri.hap){ $hapBlok="<div class='kutu2'><b>HAP:</b> $(K $veri.hap)</div>" }

$html=@"
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>1 Soru Çöz, Farkı Gör — Tetikte</title>
<style>
:root{--zemin:#161513;--kart:#1f1d1a;--kehribar:#e0a458;--metin:#e8e4dc;--soluk:#a89f90;--yesil:#8fc98f;--kirmizi:#e07b7b}
*{box-sizing:border-box}body{margin:0;font-family:'Segoe UI',system-ui,sans-serif;background:var(--zemin);color:var(--metin);line-height:1.6}
.kap{max-width:860px;margin:0 auto;padding:36px 20px}
h1{font-size:1.9em;margin:.1em 0;letter-spacing:-.5px}
.alt{color:var(--soluk);max-width:620px}
.rozet{display:inline-block;background:rgba(224,164,88,.14);border:1px solid var(--kehribar);color:var(--kehribar);border-radius:999px;padding:4px 12px;font-size:.8em;font-weight:800;margin-top:14px}
.soruk{background:var(--kart);border:1px solid #35322c;border-radius:16px;padding:22px;margin-top:14px}
.soruk p.govde{font-weight:600;font-size:1.02em}
.sik{display:block;width:100%;text-align:left;background:#26231f;border:1px solid #3b372f;border-radius:10px;color:var(--metin);padding:11px 14px;margin:7px 0;font-size:.95em;cursor:pointer;font-family:inherit;line-height:1.5}
.sik:hover{border-color:var(--kehribar)}
.sik.dogru{border-color:var(--yesil);background:rgba(143,201,143,.10)}
.sik.yanlis{border-color:var(--kirmizi);background:rgba(224,123,123,.10)}
.sik:disabled{cursor:default;opacity:.9}
#hukum{font-weight:800;margin:14px 0 4px;font-size:1.05em;display:none}
#acikla{display:none;background:#26262c;border-radius:12px;padding:16px;margin-top:14px;font-size:.93em;line-height:1.6}
#acikla b{color:var(--kehribar)}
.kutu{border-left:3px solid #78b4ff;background:rgba(120,180,255,.07);border-radius:0 8px 8px 0;padding:9px 12px;margin-top:10px;font-size:.9em}
.kutu2{border-left:3px solid var(--kehribar);background:rgba(224,164,88,.08);border-radius:0 8px 8px 0;padding:9px 12px;margin-top:10px;font-size:.9em}
.sema{border:1px dashed var(--yesil);border-radius:10px;padding:12px;margin-top:14px;background:rgba(143,201,143,.05)}
.semabaslik{font-weight:800;color:var(--yesil);margin-bottom:8px;font-size:.94em}
.elemasatir{display:flex;align-items:center;gap:10px;padding:6px 10px;margin:5px 0;border-radius:0 8px 8px 0;background:rgba(224,123,123,.05)}
.elemaaday{font-weight:700;font-size:.88em;min-width:38%}
.akis{display:flex;flex-wrap:wrap;gap:6px;align-items:center}
.akisadim{border:1px solid #78b4ff;border-radius:999px;padding:4px 10px;font-size:.84em}
.akisok{color:#78b4ff;font-weight:900}
.tcetvel{border-collapse:collapse;margin-top:6px;font-size:.88em;width:100%}
.tcetvel th{border-bottom:2px solid var(--yesil);color:var(--yesil);padding:4px 8px;text-align:left}
.tcetvel td{padding:4px 8px;border-bottom:1px dotted #444}
.ttutar{text-align:right;color:var(--kehribar);font-weight:700}
#cta{display:none;margin-top:26px;background:linear-gradient(160deg,rgba(224,164,88,.16),rgba(224,164,88,.05));border:1px solid var(--kehribar);border-radius:16px;padding:22px;text-align:center}
#cta h2{margin:.2em 0;color:var(--kehribar)}
.dgm{display:inline-block;background:var(--kehribar);color:#161513;font-weight:800;border-radius:10px;padding:12px 22px;text-decoration:none;margin-top:10px}
.dip{color:var(--soluk);font-size:.82em;margin-top:26px}
</style>
</head>
<body>
<div class="kap">
  <h1>Yanlışını böyle öğrenirsin.</h1>
  <p class="alt">Aşağıdaki soru gerçek sınav ayarında hazırlandı. Bir şık seç — sonra ekranın ne yaptığına bak. <b>Fark, cevabı verdikten sonra başlıyor.</b></p>
  <div class="rozet">📌 Bu konu, sınavların en çok soru çıkan konusudur</div>

  <div class="soruk">
    <p class="govde">$(K $veri.soru)</p>
    $($sikSb.ToString())
    <div id="hukum"></div>
    <div id="acikla">
      $acBlok
      $tabloBlok
      $semaBlok
      $taktikBlok
      $notBlok
      $hapBlok
    </div>
  </div>

  <div id="cta">
    <h2>Bu ekrandan 30.000'den fazla var.</h2>
    <p>Her soru; tuzağın adı, tek cümlelik doğrusu, konsept şeması ve sınav taktiğiyle birlikte gelir. Kaynağı her gün resmî metinle makine tarafından doğrulanır.</p>
    <a class="dgm" href="canli-deneme.html">Ücretsiz Türkiye Geneli Canlı Denemeye Katıl →</a>
  </div>

  <div class="dip">Bu örnek soru tanıtım amacıyla herkese açıktır · Tetikte soru kasası kilitli ve kaynak-damgalıdır.</div>
</div>
<script>
const DOGRU='$($veri.dogru)';
document.querySelectorAll('.sik').forEach(b=>{
  b.addEventListener('click',()=>{
    document.querySelectorAll('.sik').forEach(x=>{x.disabled=true; if(x.dataset.h===DOGRU)x.classList.add('dogru');});
    const h=document.getElementById('hukum');
    if(b.dataset.h===DOGRU){ h.textContent='✓ Doğru! Yine de açıklamayı oku — tuzakların adını öğren.'; h.style.color='var(--yesil)'; }
    else{ b.classList.add('yanlis'); h.textContent='✗ Yanlış — ve şimdi bu yanlışı bir daha yapmayacaksın:'; h.style.color='var(--kirmizi)'; }
    h.style.display='block';
    document.getElementById('acikla').style.display='block';
    document.getElementById('cta').style.display='block';
    h.scrollIntoView({behavior:'smooth',block:'center'});
  });
});
</script>
</body>
</html>
"@
[IO.File]::WriteAllText($HEDEF,$html,[Text.UTF8Encoding]::new($false))
"fark.html basildi ($([math]::Round((Get-Item $HEDEF).Length/1KB)) KB) | tablo: $([bool]$tabloBlok) | sema: $($veri.sema.tur)"
