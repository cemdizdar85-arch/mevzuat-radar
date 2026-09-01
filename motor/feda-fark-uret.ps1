# ============================================================================
#  FEDA + FARK SAYFASI ÜRETİCİ v2 (29.08; Cem: kahraman = EN ÇOK ÇIKAN konu)
#  Parametreli: istenen 90'lık sorusunu kural-25 tonuyla FEDA'ya çevirir ve
#  "1 soru çöz, farkı gör" (fark.html) sayfasını basar. Hesaplı sorularda
#  cozum_tablo desteklenir. FEDA bilerek herkese açıktır, kasaya girmez.
#  DERS (iki kez yaşandı): PS harf ayırmaz — yol=$FEDA_YOL, nesne=$fedaNesne;
#  WriteAllText'e nesne geçerse ToString'i DOSYA ADI olur (sessiz kaçak).
# ============================================================================
param([string]$ID='p90-SGS-01-hesapli',[string]$fedaAd='feda-ornek-1.json',[switch]$FarkZorla)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$repoKok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$SONUC=Join-Path $repoKok 'veri\fabrika\sik90-sonuc.jsonl'
$PLAN=Join-Path $repoKok 'veri\fabrika\sik90-plan.json'
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

# --- 1b) KUNYE (31.08 Cem: "mühürlü örneklerin hiçbirinde sinav/ders yok") ---
#  Feda dosyası kendi kimliğini TAŞIR; yoksa her kullanımda soru yeniden ölçülür.
#  Alan adları vitrin bankasıyla birebir: sinav · ders · konu.
#  PS 5.1 tuzağı: @($x | ConvertFrom-Json) diziyi AÇMAZ — önce ata, sonra sar.
$kunye=$null
if(Test-Path $PLAN){
  $planHam=Get-Content $PLAN -Raw -Encoding UTF8 | ConvertFrom-Json
  $kunye=@($planHam) | Where-Object { $_.custom_id -eq $ID } | Select-Object -First 1
}
if(-not $kunye -or -not $kunye.sinav -or -not $kunye.ders){ throw "plan kunyesi (sinav/ders) bulunamadi: $ID" }

# --- 2) feda uret (gecerli dosya varsa yeniden uretme) ---
$veri=$null
if(Test-Path $FEDA_YOL){
  $veri=Get-Content $FEDA_YOL -Raw -Encoding UTF8 | ConvertFrom-Json
  if(-not $veri.soru){ Remove-Item $FEDA_YOL -Force; $veri=$null; Write-Host 'bozuk feda silindi - yeniden uretilecek' }
  else {
    Write-Host "feda mevcut: $fedaAd"
    # eski (kunyesiz) dosyalar sessizce gecmesin - tamamlayiciya yonlendir
    if(-not $veri.PSObject.Properties['sinav'] -or -not $veri.PSObject.Properties['ders']){
      Write-Warning "$fedaAd KUNYESIZ (sinav/ders yok) - kos: powershell -NoProfile -File motor/feda-kunye-tamamla.ps1 -Uygula"
    }
  }
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
    kaynak_id=$ID; sinav="$($kunye.sinav)"; ders="$($kunye.ders)"; konu="$($kunye.konu)"
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
function TabloHtml($t,$ver){
  if(-not $t -or -not $t.satirlar -or @($t.satirlar).Count -eq 0){ return '' }
  $verSet=@{}
  foreach($vv in @($ver)){ if($vv -and @($vv).Count -ge 2){ $verSet["$(@($vv)[0]),$(@($vv)[1])"]=1 } }
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<div style='font-weight:800;font-size:.9em;color:var(--mavi);margin-top:12px'>📊 Çözüm tablosu</div>")
  if($verSet.Count -gt 0){ [void]$sb.Append("<div style='font-size:.78em;color:var(--mavi);margin-top:3px'>🔷 mavi kenarlı hücreler <b>soruda VERİLENLERDİR</b> — biz bulmadık, soru verdi; kalanları biz hesapladık</div>") }
  [void]$sb.Append("<table class='tcetvel'><tr>")
  foreach($b in @($t.basliklar)){ [void]$sb.Append("<th>$(K $b)</th>") }
  [void]$sb.Append('</tr>')
  $n=@($t.satirlar).Count; $q=0
  foreach($st in @($t.satirlar)){
    $q++
    $stil=''; if($q -eq $n){ $stil=" style='background:color-mix(in srgb,var(--yesil) 12%,transparent);font-weight:800'" }
    [void]$sb.Append("<tr$stil>")
    $kc=0
    foreach($hc in @($st)){
      # 29.08 Cem: KALEM kolonu (c=0) ISKELETTIR - oynatici gizleyemez, 'gelir tablosu gibi' hep okunur
      if($kc -eq 0){ [void]$sb.Append("<td class='hbaslik' style='font-weight:600'>$(K $hc)</td>") }
      else{
        $vcls=''; if($verSet.ContainsKey("$($q-1),$kc")){ $vcls=' verilen' }
        [void]$sb.Append("<td class='hcell$vcls' data-r='$($q-1)' data-c='$kc'>$(K $hc)</td>")
        # (ikiz tablosu ayri 'verilen' class kullanir - oynatici .hcell kapsamina girmez)
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
        $isr='✗'; $rk='var(--kirmizi)'; $st='opacity:.85'
        if($og.kalan){ $isr='✓'; $rk='var(--yesil)'; $st='background:color-mix(in srgb,var(--yesil) 10%,transparent)' }
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
        [void]$sv.Append("<svg viewBox='0 0 $W $Hh' style='width:100%;max-width:${W}px;height:auto;display:block;margin:0 auto' xmlns='http://www.w3.org/2000/svg'><defs><marker id='fok' markerWidth='7' markerHeight='7' refX='5' refY='3.5' orient='auto'><path d='M0,0 L7,3.5 L0,7 z' style='fill:var(--soluk)'/></marker></defs>")
        function Yerles($n,[double]$x0,[int]$sev,[string]$dal){
          $y=10+$sev*$LH
          if(-not (DugumMu $n)){
            $cx=($x0+0.5)*($BW+$GAP); $rk='var(--yesil)'; if($dal -eq 'hayir'){ $rk='var(--kirmizi)' }
            [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.6px solid $rk;border-radius:10px;color:$rk;font-size:12px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:color-mix(in srgb,$rk 6%,transparent)'>$(K "$n")</div></foreignObject>")
            return @($cx,1)
          }
          $sol=Yerles $n.evet $x0 ($sev+1) 'evet'
          $sag=Yerles $n.hayir ($x0+$sol[1]) ($sev+1) 'hayir'
          $cx=($sol[0]+$sag[0])/2
          [void]$sv.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.8px solid var(--mavi);border-radius:10px;color:var(--metin);font-weight:700;font-size:12.5px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:color-mix(in srgb,var(--mavi) 8%,transparent)'>$(K "$($n.soru)")</div></foreignObject>")
          $py=$y+$BH; $cy=10+($sev+1)*$LH
          foreach($cf in @(@($sol[0],'EVET','var(--yesil)'),@($sag[0],'HAYIR','var(--kirmizi)'))){
            [void]$sv.Append("<path d='M $([int]$cx) $([int]$py) C $([int]$cx) $([int]($py+28)), $([int]$cf[0]) $([int]($cy-28)), $([int]$cf[0]) $([int]$cy)' fill='none' style='stroke:$($cf[2])' stroke-width='1.6' marker-end='url(#fok)'/>")
            [void]$sv.Append("<text x='$([int](($cx+$cf[0])/2))' y='$([int](($py+$cy)/2))' font-size='11' font-weight='800' text-anchor='middle' style='fill:$($cf[2]);paint-order:stroke;stroke:var(--zemin);stroke-width:4px'>$($cf[1])</text>")
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
$verList=$null; if($veri.PSObject.Properties['verilen']){ $verList=$veri.verilen }
$tabloBlok=TabloHtml $veri.cozum_tablo $verList
$semaBlok=SemaHtml $veri.sema
$sikSb=[Text.StringBuilder]::new()
foreach($hh in 'A','B','C','D','E'){
  [void]$sikSb.Append("<button class='sik' data-h='$hh'>$hh) $(K $veri.siklar.$hh)</button>")
}
$adimJson='null'; if($veri.adimlar){ $adimJson=ConvertTo-Json -InputObject @($veri.adimlar) -Depth 6 -Compress }

# --- 01.09 Cem "UCUNU KUR": tuzak sozlugu + ipucu merdiveni + verilenler tablosu ---
# Uc veri de once feda json'undan (elle yazilmis, en zengin), yoksa OTOMATIK turetilir.
# 1) TUZAK: yanlis sikka basildigi an tuzagin ADI soylenir (cevap/hesap SIZDIRILMAZ).
$tuzakSoz=[ordered]@{}
if($veri.PSObject.Properties['tuzaklar'] -and $veri.tuzaklar){
  foreach($p in $veri.tuzaklar.PSObject.Properties){ $tuzakSoz[$p.Name]=$p.Value }
} else {
  foreach($hh in 'A','B','C','D','E'){
    if("$($veri.dogru)" -eq $hh){ continue }
    $mt=[regex]::Match("$($veri.aciklama.$hh)",'([A-ZÇĞİÖŞÜ][\w çğıöşüÇĞİÖŞÜ\-]{2,60}?Tuza[ğg]ı)')
    if($mt.Success){ $tuzakSoz[$hh]=$mt.Groups[1].Value.Trim() }
  }
}
$tuzakJson=ConvertTo-Json -InputObject $tuzakSoz -Depth 2 -Compress
# 2) IPUCU MERDIVENI (yalniz ikiz varsa anlamli): 1=formul zinciri, 2=verilenlere bak, 3=ilk hucreyi beraber doldur.
#    Kural (01.09): her ipucu en fazla 2 cumle yardim + 1 cumle neden; ders anlatimina DONUSMEZ.
$ipucuJson='null'
if($veri.PSObject.Properties['ikiz'] -and $veri.ikiz -and $veri.ikiz.tablo){
  if($veri.PSObject.Properties['ipuclari'] -and $veri.ipuclari){
    $ipucuJson=ConvertTo-Json -InputObject @($veri.ipuclari) -Depth 4 -Compress
  } elseif($veri.adimlar){
    $genel=New-Object System.Collections.Generic.List[string]
    foreach($aa in @($veri.adimlar)){
      $ilkSatir=@("$($aa.formul)" -split "`n")[0].Trim()
      if($ilkSatir -and $ilkSatir -notmatch '^Verilenler' -and $ilkSatir -match '=' ){
        # sayili uygulanisi at, genel formul kalsin (ilk '=' oncesi + ilk esitlik govdesi sayisizsa)
        $gnl=($ilkSatir -split '=')[0].Trim()+' = '+(($ilkSatir -split '=')[1]).Trim()
        if($gnl -notmatch '\d{2}' -and -not $genel.Contains($gnl)){ [void]$genel.Add($gnl) }
      }
    }
    $ilkBos=$null
    foreach($vv in @($veri.ikiz.bosluk)){ $ilkBos=$vv; break }
    $ilkDeger=''; if($ilkBos){ $ilkDeger="$(@(@($veri.ikiz.tablo.satirlar)[$ilkBos[0]])[$ilkBos[1]])" }
    $ipListe=@(
      @{ b='💡 İPUCU 1/3 — Hangi formül zinciri?'; m='Cevabı söylemiyorum — yolu gösteriyorum. Bu soru tipi şu formül zinciriyle çözülür:'; f=(($genel | ForEach-Object -Begin{$q=0} -Process{ $q++; "$q) $_" }) -join "`n") },
      @{ b='💡 İPUCU 2/3 — Soru sana ne verdi?'; m='Mavi kenarlı hücrelere bak — bunlar sorunun verdikleri. Önce bunları formül zincirine yerleştir; ilk işin verilenlerden ilk ara değeri hesaplamak.' },
      @{ b='💡 İPUCU 3/3 — İlk adımı beraber yapalım'; m=('İlk boş hücreyi senin için doldurdum: {0}. Aynı yöntemi kalan hücrelere SEN uygula — zincirin kalanı gelir.' -f $ilkDeger); doldur=$ilkDeger }
    )
    $ipucuJson=ConvertTo-Json -InputObject $ipListe -Depth 4 -Compress
  }
}
# 3) VERILENLER TABLOSU (adim-1 formul kutusu yerine): adimlar[0].vtablo elle varsa o;
#    yoksa 'verilen' koordinatlarindan Kalem|Alan|Deger tablosu turetilir.
$vtabloHtml=''
if($veri.adimlar -and @($veri.adimlar)[0].PSObject.Properties['vtablo']){ $vtabloHtml="$(@($veri.adimlar)[0].vtablo)" }
elseif($veri.adimlar -and $verList -and $veri.cozum_tablo){
  $vb=[Text.StringBuilder]::new()
  [void]$vb.Append("<div style='font-weight:800;font-size:.82em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
  foreach($vv in @($verList)){
    $r=@($vv)[0]; $c=@($vv)[1]
    $sat=@(@($veri.cozum_tablo.satirlar)[$r])
    [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($veri.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
  }
  [void]$vb.Append('</table>')
  $vtabloHtml=$vb.ToString()
}
$vtabloJson=ConvertTo-Json -InputObject $vtabloHtml -Compress
$playerBlok=''
if($veri.adimlar){
  $playerBlok=@"
<div id='player' style='margin-top:14px'>
  <button id='padim' class='dgm' style='padding:9px 16px;font-size:.9em'>🎬 Bu çözümü adım adım yaşa</button>
  <div id='panlat' style='display:none;border:1px solid var(--kehribar);border-radius:12px;padding:12px 14px;margin-top:10px;background:color-mix(in srgb,var(--kehribar) 7%,transparent)'>
    <div style='font-size:.78em;color:var(--kehribar);font-weight:800' id='psayac'></div>
    <div id='pformul' style='margin-top:7px;font-family:Consolas,monospace;font-size:.98em;color:var(--mavi-acik);background:color-mix(in srgb,var(--mavi) 10%,transparent);border:1px solid color-mix(in srgb,var(--mavi) 35%,transparent);border-radius:8px;padding:8px 12px'></div>
    <div id='pmetin' style='margin-top:7px;font-size:.95em'></div>
    <button id='pileri' class='dgm' style='padding:7px 14px;font-size:.85em;margin-top:10px'>İleri →</button>
  </div>
</div>
"@
}
# --- 29.08 "SIMDI SEN DENE" (Cem: 'BU SUPER OLUR'): rakamlari degismis ikiz, ogrenci doldurur ---
$ikizBlok=''
if($veri.PSObject.Properties['ikiz'] -and $veri.ikiz -and $veri.ikiz.tablo){
  $ik=$veri.ikiz
  $ikVer=@{}; foreach($vv in @($ik.verilen)){ if(@($vv).Count -ge 2){ $ikVer["$(@($vv)[0]),$(@($vv)[1])"]=1 } }
  $ikBos=@{}; foreach($vv in @($ik.bosluk)){ if(@($vv).Count -ge 2){ $ikBos["$(@($vv)[0]),$(@($vv)[1])"]=1 } }
  $tb=[Text.StringBuilder]::new()
  [void]$tb.Append("<table class='tcetvel'><tr>")
  foreach($b in @($ik.tablo.basliklar)){ [void]$tb.Append("<th>$(K $b)</th>") }
  [void]$tb.Append('</tr>')
  $ns=@($ik.tablo.satirlar).Count; $rq=0
  foreach($st in @($ik.tablo.satirlar)){
    $rq++
    $stil=''; if($rq -eq $ns){ $stil=" style='background:color-mix(in srgb,var(--yesil) 12%,transparent);font-weight:800'" }
    [void]$tb.Append("<tr$stil>")
    $cq=0
    foreach($hc in @($st)){
      $kkey="$($rq-1),$cq"
      if($cq -eq 0){ [void]$tb.Append("<td style='font-weight:600'>$(K $hc)</td>") }
      elseif($ikBos.ContainsKey($kkey)){ [void]$tb.Append("<td><input class='ikx' data-dogru='$(K $hc)' placeholder='?'></td>") }
      elseif($ikVer.ContainsKey($kkey)){ [void]$tb.Append("<td class='verilen'>$(K $hc)</td>") }
      else{ [void]$tb.Append("<td>$(K $hc)</td>") }
      $cq++
    }
    [void]$tb.Append('</tr>')
  }
  [void]$tb.Append('</table>')
  $ikizBlok=@"
<div style='margin-top:16px'>
  <button id='ikizAc' class='dgm' style='padding:9px 16px;font-size:.9em;background:var(--yesil)'>✍️ Şimdi sen dene — aynı yöntemi yeni rakamlarla uygula</button>
  <div id='ikiz' style='display:none;border:1px dashed var(--yesil);border-radius:12px;padding:14px;margin-top:10px'>
    <p style='font-weight:600'>$(K $ik.soru)</p>
    <p style='color:var(--yesil);font-size:.9em'>🎯 $(K $ik.hedef_cumle) — 🔷 maviler soruda verildi; boş hücreleri SEN doldur.</p>
    $($tb.ToString())
    <button id='ikizKontrol' class='dgm' style='padding:8px 15px;font-size:.88em;margin-top:10px'>Kontrol et</button>
    <button id='ipucuAl' class='dgm' style='padding:8px 15px;font-size:.88em;margin-top:10px;background:var(--mavi)'>💡 Takıldım — ipucu ver (1/3)</button>
    <button id='ikizGoster' class='dgm' style='padding:8px 15px;font-size:.88em;margin-top:10px;background:var(--kenar);color:var(--metin)'>Doğruları göster</button>
    <span id='ikizSkor' style='margin-left:10px;font-weight:800'></span>
    <div id='ipucuPanel'><span class='ipb' id='ipucuBaslik'></span><div id='ipucuMetin' style='margin-top:5px'></div><div class='ipf' id='ipucuFormul' style='display:none'></div></div>
  </div>
</div>
"@
}
$taktikBlok=''; if($veri.sinav_taktigi){ $taktikBlok="<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $veri.sinav_taktigi)</div>" }
$notBlok=''; if($veri.notlandirici){ $notBlok="<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $veri.notlandirici)</div>" }
$hapBlok=''; if($veri.hap){ $hapBlok="<div class='kutu2'><b>HAP:</b> $(K $veri.hap)</div>" }

$html=@"
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
<link rel="manifest" href="manifest.webmanifest">
<meta name="theme-color" content="#1b1a18">
<!-- 30.08: BU SAYFA PAZARLAMANIN YUZU ama paylasim etiketi HIC YOKTU -
     favicon bile bagli degildi. Link atildiginda ciplak adres goruluyordu.
     Kendi karti var (og-kahraman.png): kilitli cumle + dort perde.
     Genel kapak (og-kapak.png) DEGIL - kahraman sayfasi kendi vaadini gostermeli. -->
<meta property="og:type" content="article">
<meta property="og:locale" content="tr_TR">
<meta property="og:site_name" content="Tetikte">
<meta property="og:url" content="https://tetikte.com/fark.html">
<meta property="og:title" content="Yanlışını böyle öğrenirsin.">
<meta property="og:description" content="Bir soru çöz. Cevabı vermekle bitmiyor — tuzağın adı, doğrusu, adım adım çözüm ve kendi denemen ondan sonra başlıyor.">
<meta property="og:image" content="https://tetikte.com/og-kahraman.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="Tetikte — Yanlışını böyle öğrenirsin.">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Yanlışını böyle öğrenirsin.">
<meta name="twitter:description" content="Bir soru çöz. Fark, cevabı verdikten sonra başlıyor.">
<meta name="twitter:image" content="https://tetikte.com/og-kahraman.png">
<title>1 Soru Çöz, Farkı Gör — Tetikte</title>
<style>
:root{
  /* ---- ACIK TEMA (30.08; sablona 01.09'da esitlendi) --------------------
     Degerler stil-acik.css'ten AYNEN alindi, uydurulmadi. --------------- */
  --zemin:#fbfaf8;       /* stil-acik --bg     : sicak kagit */
  --kart:#ffffff;        /* stil-acik --panel  : kagit katmani */
  --kehribar:#a04a08;    /* stil-acik --accent : METIN baglaminda koyu kehribar */
  --metin:#16191d;       /* stil-acik --ink    : saf siyah degil, goz yormaz */
  --soluk:#4b5563;       /* stil-acik --muted  */
  --yesil:#146f35;       /* stil-acik --green  : acik zeminde okunacak koyulukta */
  --kirmizi:#b91c1c;     /* stil-acik --red    */
  --mavi:#1d4ed8;        /* stil-acik --link   : ALTIN AYRIM "soruda verilen" */
  --mavi-acik:#1e40af;   /* ogretmen tahtasi formul metni - bir ton koyu */
  --kenar:#d5d0c6;       /* stil-acik --line2  */
  --kart2:#f7f5f1;       /* stil-acik --panel2 */
  --kart3:#d5d0c6;       /* stil-acik --line2  : .soruk siniri (kontrast kapisi dersi) */
  --kart4:#e6e2da;       /* stil-acik --line   */
  --gri:#f4f2ee;
  --soluk-kenar:#d5d0c6;}
*{box-sizing:border-box}body{margin:0;font-family:'Segoe UI',system-ui,sans-serif;background:var(--zemin);color:var(--metin);line-height:1.6}
.kap{max-width:860px;margin:0 auto;padding:36px 20px}
h1{font-size:1.9em;margin:.1em 0;letter-spacing:-.5px}
.alt{color:var(--soluk);max-width:620px}
.rozet{display:inline-block;background:color-mix(in srgb,var(--kehribar) 14%,transparent);border:1px solid var(--kehribar);color:var(--kehribar);border-radius:999px;padding:4px 12px;font-size:.8em;font-weight:800;margin-top:14px}
.soruk{background:var(--kart);border:1px solid var(--kart3);border-radius:16px;padding:22px;margin-top:14px}
.soruk p.govde{font-weight:600;font-size:1.02em}
.sik{display:block;width:100%;text-align:left;background:var(--kart2);border:1px solid var(--kart4);border-radius:10px;color:var(--metin);padding:11px 14px;margin:7px 0;font-size:.95em;cursor:pointer;font-family:inherit;line-height:1.5}
.sik:hover{border-color:var(--kehribar)}
.sik.dogru{border-color:var(--yesil);background:color-mix(in srgb,var(--yesil) 10%,transparent)}
.sik.yanlis{border-color:var(--kirmizi);background:color-mix(in srgb,var(--kirmizi) 10%,transparent)}
.sik:disabled{cursor:default;opacity:.9}
#hukum{font-weight:800;margin:14px 0 4px;font-size:1.05em;display:none}
#acikla{display:none;background:var(--gri);border-radius:12px;padding:16px;margin-top:14px;font-size:.93em;line-height:1.6}
#acikla b{color:var(--kehribar)}
.kutu{border-left:3px solid var(--mavi);background:color-mix(in srgb,var(--mavi) 7%,transparent);border-radius:0 8px 8px 0;padding:9px 12px;margin-top:10px;font-size:.9em}
.kutu2{border-left:3px solid var(--kehribar);background:color-mix(in srgb,var(--kehribar) 8%,transparent);border-radius:0 8px 8px 0;padding:9px 12px;margin-top:10px;font-size:.9em}
.sema{border:1px dashed var(--yesil);border-radius:10px;padding:12px;margin-top:14px;background:color-mix(in srgb,var(--yesil) 5%,transparent)}
.semabaslik{font-weight:800;color:var(--yesil);margin-bottom:8px;font-size:.94em}
.elemasatir{display:flex;align-items:center;gap:10px;padding:6px 10px;margin:5px 0;border-radius:0 8px 8px 0;background:color-mix(in srgb,var(--kirmizi) 5%,transparent)}
.elemaaday{font-weight:700;font-size:.88em;min-width:38%}
.akis{display:flex;flex-wrap:wrap;gap:6px;align-items:center}
.akisadim{border:1px solid var(--mavi);border-radius:999px;padding:4px 10px;font-size:.84em}
.akisok{color:var(--mavi);font-weight:900}
.tcetvel{border-collapse:collapse;margin-top:6px;font-size:.88em;width:100%}
.tcetvel th{border-bottom:2px solid var(--yesil);color:var(--yesil);padding:4px 8px;text-align:left}
.tcetvel td{padding:4px 8px;border-bottom:1px dotted var(--soluk-kenar)}
.ttutar{text-align:right;color:var(--kehribar);font-weight:700}
.hcell.gizli{color:transparent;text-shadow:none}
.verilen{box-shadow:inset 3px 0 0 var(--mavi)}
.ikx{width:110px;background:var(--zemin);border:1px solid var(--kenar);border-radius:6px;color:var(--metin);padding:5px 8px;font-family:inherit;font-size:.92em}
.ikx.dog{border-color:var(--yesil);background:color-mix(in srgb,var(--yesil) 12%,transparent)}
.ikx.yan{border-color:var(--kirmizi);background:color-mix(in srgb,var(--kirmizi) 12%,transparent)}
.hcell.parla{animation:parla .9s ease}
@keyframes parla{0%{background:color-mix(in srgb,var(--kehribar) 55%,transparent)}100%{background:transparent}}
/* 01.09 ipucu merdiveni: takilan ogrenci cevabi gormeden kademeli yardim alir */
td.verilen.parla{animation:parla 1.4s ease}
#ipucuPanel{display:none;border:1px solid var(--mavi);border-radius:10px;padding:10px 13px;margin-top:10px;background:color-mix(in srgb,var(--mavi) 6%,transparent);font-size:.92em}
#ipucuPanel .ipb{font-weight:800;color:var(--mavi);font-size:.82em}
#ipucuPanel .ipf{font-family:Consolas,monospace;font-size:.93em;color:var(--mavi-acik);background:color-mix(in srgb,var(--mavi) 10%,transparent);border-radius:8px;padding:7px 10px;margin-top:6px;white-space:pre-line}
#tuzakKutu{display:none;border-left:3px solid var(--kirmizi);background:color-mix(in srgb,var(--kirmizi) 7%,transparent);border-radius:0 8px 8px 0;padding:9px 12px;margin:10px 0 0;font-size:.92em}
/* 01.09 Cem "TUZAK KARNESI KUR": dunyada elle tutulan error-log'un otomatigi -
   yanlislar tuzak ADIYLA birikir, karne tarayicida saklanir (uyelikte tasinacak) */
#karne{display:none;margin-top:26px;border:1px solid var(--kirmizi);border-radius:16px;padding:18px 20px;background:color-mix(in srgb,var(--kirmizi) 4%,transparent)}
#karne h2{margin:.1em 0 .4em;color:var(--kirmizi);font-size:1.15em}
.karneSatir{display:flex;align-items:center;gap:10px;padding:7px 4px;border-bottom:1px dotted var(--soluk-kenar);font-size:.93em}
.karneSatir:last-of-type{border-bottom:0}
.karneSayi{min-width:52px;text-align:center;font-weight:900;color:var(--kirmizi);background:color-mix(in srgb,var(--kirmizi) 10%,transparent);border-radius:8px;padding:3px 8px}
.karneAd{font-weight:700;flex:1}
.karneSon{color:var(--soluk);font-size:.85em}
#karneNot{color:var(--soluk);font-size:.83em;margin-top:10px}
/* 01.09 Cem: adim-1 verilenleri duz metin yerine TABLO halinde (okunurluk) */
.vtab{border-collapse:collapse;width:100%;font-size:.95em;font-family:inherit}
.vtab th{color:var(--mavi-acik);border-bottom:2px solid color-mix(in srgb,var(--mavi) 45%,transparent);text-align:left;padding:4px 9px;font-size:.88em}
.vtab td{padding:4px 9px;border-bottom:1px dotted color-mix(in srgb,var(--mavi) 30%,transparent)}
.vtab tr:last-child td{border-bottom:0;font-weight:800}
#cta{display:none;margin-top:26px;background:linear-gradient(160deg,color-mix(in srgb,var(--kehribar) 16%,transparent),color-mix(in srgb,var(--kehribar) 5%,transparent));border:1px solid var(--kehribar);border-radius:16px;padding:22px;text-align:center}
#cta h2{margin:.2em 0;color:var(--kehribar)}
.dgm{display:inline-block;background:var(--kehribar);color:var(--zemin);font-weight:800;border-radius:10px;padding:12px 22px;text-decoration:none;margin-top:10px}
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
    <div id="tuzakKutu"></div>
    <div id="acikla">
      $acBlok
      <div id="cozumBolge">
      $playerBlok
      $tabloBlok
      $semaBlok
      </div>
      <button id="cozumToggle" class="dgm" style="display:none;padding:7px 14px;font-size:.85em;background:var(--kenar);margin-top:10px">🙈 Çözüm gizlendi — kopyasız dene! (tekrar göster)</button>
      $ikizBlok
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

  <div id="karne">
    <h2>🗂️ Tuzak Karnem</h2>
    <div style="color:var(--soluk);font-size:.88em;margin-bottom:6px">En sık düştüğün tuzaklar — yanlışın adı belli olunca, bir daha düşmemek mümkün olur.</div>
    <div id="karneListe"></div>
    <div id="karneNot">Karnen şimdilik bu tarayıcıda saklanır · üyelik açıldığında karnen seninle taşınacak, hangi tuzağın ikizleri gerekiyorsa onları önereceğiz.</div>
  </div>

  <div class="dip">Bu örnek soru tanıtım amacıyla herkese açıktır · Tetikte soru kasası kilitli ve kaynak-damgalıdır.</div>
</div>
<script>
const DOGRU='$($veri.dogru)';
const TUZAK=$tuzakJson;
const SORU_ID='$ID';
// 01.09 TUZAK KARNESI (Cem: "KUR"): yanlislar tuzak ADIYLA localStorage'da birikir.
// Ortak sema - buyuk basimin her soru sayfasi ayni anahtara yazar:
//   tetikte_tuzak_karnesi = { "<tuzak adi>": {sayi,son,ornek:[soruId...]} }
// localStorage her ortamda yok (gizli pencere vs.) -> her erisim try/catch.
function karneOku(){ try{ return JSON.parse(localStorage.getItem('tetikte_tuzak_karnesi')||'{}'); }catch(e){ return null; } }
function karneKaydet(tuzakTam){
  const ad=String(tuzakTam).split('—')[0].trim();
  const k=karneOku(); if(k===null) return 0;
  const kk=k[ad]||{sayi:0,son:'',ornek:[]};
  kk.sayi++; kk.son=new Date().toLocaleDateString('tr-TR');
  if(SORU_ID && kk.ornek.indexOf(SORU_ID)<0) kk.ornek.push(SORU_ID);
  k[ad]=kk;
  try{ localStorage.setItem('tetikte_tuzak_karnesi', JSON.stringify(k)); }catch(e){}
  return kk.sayi;
}
function karneCiz(){
  const k=karneOku(); if(!k) return;
  const kayitlar=Object.entries(k).sort((a,b)=>b[1].sayi-a[1].sayi);
  if(!kayitlar.length) return;
  const liste=document.getElementById('karneListe');
  liste.innerHTML=kayitlar.map(([ad,v])=>
    "<div class='karneSatir'><span class='karneSayi'>"+v.sayi+"×</span><span class='karneAd'>🪤 "+ad+"</span><span class='karneSon'>son: "+v.son+"</span></div>"
  ).join('');
  document.getElementById('karne').style.display='block';
}
karneCiz();
document.querySelectorAll('.sik').forEach(b=>{
  b.addEventListener('click',()=>{
    document.querySelectorAll('.sik').forEach(x=>{x.disabled=true; if(x.dataset.h===DOGRU)x.classList.add('dogru');});
    const h=document.getElementById('hukum');
    if(b.dataset.h===DOGRU){ h.textContent='✓ Doğru! Yine de açıklamayı oku — tuzakların adını öğren.'; h.style.color='var(--yesil)'; }
    else{ b.classList.add('yanlis'); h.textContent='✗ Yanlış — ve şimdi bu yanlışı bir daha yapmayacaksın:'; h.style.color='var(--kirmizi)';
      const tk=document.getElementById('tuzakKutu');
      if(tk&&TUZAK&&TUZAK[b.dataset.h]){
        const kacinci=karneKaydet(TUZAK[b.dataset.h]);
        const kacTxt=(kacinci>1)?(' <b style="color:var(--kirmizi)">Bu tuzağa '+kacinci+'. düşüşün.</b>'):'';
        tk.innerHTML='🪤 <b>Düştüğün tuzağın adı:</b> '+TUZAK[b.dataset.h]+kacTxt+' <span style="color:var(--soluk)">Aşağıda bu tuzağın nasıl çalıştığını adım adım göreceksin.</span>'; tk.style.display='block';
        karneCiz();
      } }
    h.style.display='block';
    document.getElementById('acikla').style.display='block';
    document.getElementById('cta').style.display='block';
    h.scrollIntoView({behavior:'smooth',block:'center'});
  });
});
const ikizAc=document.getElementById('ikizAc');
if(ikizAc){
  const norm=t=>String(t||'').toLowerCase().replace(/tl|kg|%/g,'').replace(/[.\s]/g,'').replace(',','.').trim();
  const cb=document.getElementById('cozumBolge'), ct=document.getElementById('cozumToggle');
  ikizAc.addEventListener('click',()=>{
    ikizAc.style.display='none'; document.getElementById('ikiz').style.display='block';
    if(cb){ cb.style.display='none'; ct.style.display='inline-block'; }
  });
  if(ct){ ct.addEventListener('click',()=>{ const acik=cb.style.display!=='none'; cb.style.display=acik?'none':'block'; ct.textContent=acik?'🙈 Çözüm gizlendi — kopyasız dene! (tekrar göster)':'🙈 Çözümü tekrar gizle'; }); }
  document.getElementById('ikizKontrol').addEventListener('click',()=>{
    let d=0,t=0;
    document.querySelectorAll('.ikx').forEach(i=>{ t++; const ok=norm(i.value)===norm(i.dataset.dogru); i.classList.remove('dog','yan'); i.classList.add(ok?'dog':'yan'); if(ok)d++; });
    const sk=document.getElementById('ikizSkor');
    sk.textContent=d+' / '+t+(d===t?' — HEPSİ DOĞRU! 🎉 Yöntem artık senin.':' doğru');
    sk.style.color=(d===t)?'var(--yesil)':'var(--kehribar)';
    if(d===t){ const cb2=document.getElementById('cozumBolge'); if(cb2){ cb2.style.display='block'; document.getElementById('cozumToggle').style.display='none'; } }
  });
  document.getElementById('ikizGoster').addEventListener('click',()=>{
    document.querySelectorAll('.ikx').forEach(i=>{ i.value=i.dataset.dogru; i.classList.remove('yan'); i.classList.add('dog'); });
  });
  // 01.09 IPUCU MERDIVENI: cevabi vermeden kademeli yardim - 1 formul, 2 verilenler, 3 ilk hucre.
  const IPUCU=$ipucuJson;
  const ipBtn=document.getElementById('ipucuAl');
  if(IPUCU&&ipBtn){
    let ipN=0;
    ipBtn.addEventListener('click',()=>{
      if(ipN>=IPUCU.length) return;
      const ip=IPUCU[ipN];
      document.getElementById('ipucuBaslik').textContent=ip.b;
      document.getElementById('ipucuMetin').textContent=ip.m;
      const f=document.getElementById('ipucuFormul'); f.textContent=ip.f||''; f.style.display=ip.f?'block':'none';
      if(ipN===1){ document.querySelectorAll('#ikiz td.verilen').forEach(td=>{ td.classList.remove('parla'); void td.offsetWidth; td.classList.add('parla'); }); }
      if(ip.doldur){ const ilk=document.querySelector('#ikiz .ikx'); if(ilk&&!ilk.value){ ilk.value=ip.doldur; ilk.classList.add('dog'); } }
      document.getElementById('ipucuPanel').style.display='block';
      ipN++;
      ipBtn.textContent=(ipN>=IPUCU.length)?'💡 İpucu bitti — kalanı sende!':'💡 Takıldım — ipucu ver ('+(ipN+1)+'/3)';
      if(ipN>=IPUCU.length){ ipBtn.style.opacity='.55'; ipBtn.style.cursor='default'; }
    });
  } else if(ipBtn){ ipBtn.style.display='none'; }
}
const ADIMLAR=$adimJson;
const VTABLO=$vtabloJson;
if(ADIMLAR){
  let ad=-1;
  const hc=(r,c)=>document.querySelector(".hcell[data-r='"+r+"'][data-c='"+c+"']");
  const tum=()=>document.querySelectorAll('.hcell');
  const goster=()=>{
    const s=ADIMLAR[ad];
    document.getElementById('psayac').textContent='ADIM '+(ad+1)+' / '+ADIMLAR.length;
    document.getElementById('pmetin').textContent=s.anlatim;
    // 01.09 Cem: adim-1 verilenleri duz metin yerine TABLO halinde (vtablo uretici tarafinda kurulur)
    const pf=document.getElementById('pformul');
    if(ad===0&&VTABLO){ pf.innerHTML=VTABLO; pf.style.display='block'; }
    else { pf.textContent=s.formul||''; pf.style.display=s.formul?'block':'none'; }
    (s.doldur||[]).forEach(k=>{const el=hc(k[0],k[1]); if(el){el.classList.remove('gizli'); el.classList.add('parla'); setTimeout(()=>el.classList.remove('parla'),950);}});
    if(ad===ADIMLAR.length-1){ tum().forEach(el=>el.classList.remove('gizli')); } // son adimda acik hucre kalmaz (muhur-turu guvencesi)
    document.getElementById('pileri').textContent=(ad===ADIMLAR.length-1)?'🔄 Baştan':'İleri →';
  };
  document.getElementById('padim').addEventListener('click',()=>{
    tum().forEach(el=>el.classList.add('gizli'));
    document.getElementById('padim').style.display='none';
    document.getElementById('panlat').style.display='block';
    ad=0; goster();
    document.getElementById('panlat').scrollIntoView({behavior:'smooth',block:'center'});
  });
  document.getElementById('pileri').addEventListener('click',()=>{
    if(ad===ADIMLAR.length-1){ tum().forEach(el=>el.classList.add('gizli')); ad=0; goster(); return; }
    ad++; goster();
  });
}
</script>
</body>
</html>
"@
# --- 5) GERI GIDIS FRENI (31.08 — bir kez basıldı, geri alındı) -------------
#  Canlı fark.html, ŞABLONUN ÖNÜNDE: 30.08'de sayfaya açık tema (renk jetonu +
#  color-mix), OG/Twitter paylaşım kartı ve favicon/manifest ELLE eklendi; bu
#  betiğin içindeki şablon hâlâ koyu tema + SABİT renk üretiyor. Betik körü
#  körüne bassaydı o iş sessizce silinir, üstelik renk-sabiti kapısı düşerdi.
#  Fren: canlı sayfada VAR olup yeni çıktıda OLMAYAN bir imza görülürse yazma.
#  Şablon güncellendiğinde imzalar kendiliğinden eşleşir, fren açılır.
$imzalar=@('og:image','color-mix(','manifest.webmanifest')
$kayip=@()
if(Test-Path $HEDEF){
  $canli=Get-Content $HEDEF -Raw -Encoding UTF8
  foreach($im in $imzalar){ if($canli.Contains($im) -and -not $html.Contains($im)){ $kayip+=$im } }
}
if($kayip.Count -gt 0 -and -not $FarkZorla){
  Write-Warning ("fark.html YAZILMADI - sablon canlinin GERISINDE. Canlida var, yeni ciktida yok: " + ($kayip -join ' · '))
  Write-Warning "Once sablonu (bu betikteki `$html) canliyla hizala. Yine de basmak icin: -FarkZorla"
  "fark.html KORUNDU | feda: $fedaAd | tablo: $([bool]$tabloBlok) | sema: $($veri.sema.tur)"
  return
}
[IO.File]::WriteAllText($HEDEF,$html,[Text.UTF8Encoding]::new($false))
"fark.html basildi ($([math]::Round((Get-Item $HEDEF).Length/1KB)) KB) | tablo: $([bool]$tabloBlok) | sema: $($veri.sema.tur)"
