# TON PROVASI 5 (28.08, Cem onayi): kural 25 tonu + konsept semasi - yan yana kiyas
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$kok='C:\Users\cemdi\OneDrive\Masaüstü\mevzuat işi\mevzuat-radar'
. (Join-Path $kok 'motor\api-hedef.ps1')
$SONUC=Join-Path $kok 'veri\fabrika\sik90-sonuc.jsonl'
$HEDEF=Join-Path $kok 'sql-yerel\ton-provasi-5.html'
$SECIM=@('p90-SGS-14-vaka','p90-SMMM-11-hesapli','p90-KGK-27-vaka-uzun','p90-SGS-25-onculu','p90-KGK-06-hesapli')

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
$eski=@{}
foreach($sat in (Get-Content $SONUC -Encoding UTF8)){
  $r=$sat|ConvertFrom-Json
  if($r.custom_id -in $SECIM){
    $txt=(@($r.result.message.content)|? { $_.type -eq 'text' }|Select-Object -Last 1).text
    $eski["$($r.custom_id)"]=Coz $txt
  }
}
"secilen: $($eski.Count)/5"

$istemSablon=@'
Sen "Nobetci" adli hoca-yazarsin: sinava hazirlanan adaya ders anlatan, sicak ama ciddi bir hoca. Asagida bir sinav sorusu ve MEVCUT aciklama takimi var. SORU, SIKLAR ve DOGRU CEVAP AYNEN KALACAK - senin isin YALNIZ aciklama takimini KURAL 25 tonuyla yeniden yazmak ve bir KONSEPT SEMASI uretmek.

KURAL 25 - MADDE DIYETI + ONCE MANTIK (UWorld/Kaplan dersi: "aciklama not vermez, OGRETIR"):
(a) Dogru sikkin "Kural:" parcasinin ILK cumlesi KANUN KOYUCUNUN/STANDART KOYUCUNUN DERDINI gunluk dille anlatir - bu kural neden var, hangi kacisi/suistimali/riski kapatiyor. Madde kunyesi cumle SONUNDA parantezde.
(b) BES sikkin tamaminda madde/paragraf kunyesi TOPLAM en fazla 2 kez gecer. Kalan atiflar kunyesiz kurulur: "kanun bu kapiyi kapatmis", "standart cizgiyi burada cekiyor" gibi.
(c) "Dogrusu:" cumleleri kunyesiz, saf insan dili.
(d) Dort parca iskeleti korunur (Ne soruluyor / Kural / Bu olayda / Akilda kalsin); yanlis siklarda tuzagin adi + "Dogrusu:" korunur; varsa "Vaka taktigi" satiri korunur.
(e) YENI hukuki iddia, rakam, oran, madde EKLEME - elindeki tek kaynak mevcut aciklamadir; sadece DILI donustur. Mevcut aciklamadaki kunyelerden en onemli 1-2 tanesini tut, gerisini dayanak alanina birak.
(f) Ton: ogrenciyle konusan hoca; kisa cumleler; "kar" hep sapkali (kâr).

KONSEPT SEMASI ("sema" alani) - kavrami TEK BAKISTA ozetleyen basit sema. Su turlerden SORUYA EN UYGUN olanini sec:
- "yevmiye": MUHASEBE KAYDI/yevmiye soran soruda BU TUR ZORUNLUDUR (akis DEGIL - Cem karari: finansallarda T cetveli) -> {"tur":"yevmiye","baslik":"...","ogeler":{"borc":[{"hesap":"322 Borc Senetleri Reeskontu","tutar":"22.000"}],"alacak":[{"hesap":"642 Faiz Gelirleri","tutar":"22.000"}]}} - hesap kodu+adi birebir dogru sikkin kaydiyla ayni olsun; borc toplami = alacak toplami.
- "kiyas": iki kavramin farki -> {"tur":"kiyas","baslik":"...","ogeler":[{"ad":"Kavram A","maddeler":["...","..."]},{"ad":"Kavram B","maddeler":["...","..."]}]}
- "karar": YALNIZ gercekten evet/hayir dallanan kurallarda -> {"tur":"karar","baslik":"...","kok":{"soru":"...?","evet":"KISA sonuc metni VEYA ic dugum {soru,evet,hayir}","hayir":"KISA sonuc metni VEYA ic dugum"}}. EN FAZLA 2 seviye; her dal net bir SONUCLA biter (en fazla 8 kelime); dallanma dogal degilse karar TURUNU SECME, akis sec.
- "akis": surec adimlari -> {"tur":"akis","baslik":"...","ogeler":["adim 1","adim 2","adim 3"]}
- "zaman": tarih/an cizgisi -> {"tur":"zaman","baslik":"...","ogeler":[{"an":"...","olay":"..."}]}
Sema metinleri KISA olsun (kutu basina en fazla 8-10 kelime); mevcut aciklamadaki bilgiden turesin, yeni bilgi tasimaz.

Cevap YALNIZ su JSON:
{"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","sinav_taktigi":"...","notlandirici":"...","sema":{...}}

=== SORU (degistirme, referans icin) ===
{SORU}

SIKLAR: {SIKLAR}
DOGRU: {DOGRU}

=== MEVCUT ACIKLAMA TAKIMI (kaynagin bu) ===
{ESKI}
'@

$yeni=@{}
foreach($id in $SECIM){
  $e=$eski[$id]
  $sik=(('A','B','C','D','E') | % { "$_) $($e.siklar.$_)" }) -join "`n"
  $eskiJson=ConvertTo-Json -InputObject ([ordered]@{aciklama=$e.aciklama;hap=$e.hap;sinav_taktigi=$e.sinav_taktigi;notlandirici=$e.notlandirici;dayanak=$e.dayanak}) -Depth 5
  $istem=$istemSablon.Replace('{SORU}',"$($e.soru)").Replace('{SIKLAR}',$sik).Replace('{DOGRU}',"$($e.dogru)").Replace('{ESKI}',$eskiJson)
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istem -MaxTok 20000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $c=Coz $y.metin
  if($c -and $c.aciklama){ $yeni[$id]=$c; Write-Host "  OK $id" } else { Write-Host "  BOZUK $id"; }
}
"yeniden yazilan: $($yeni.Count)/5"

# ---- HTML: yan yana kiyas ----
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }

# --- gercek geometrili karar agaci (SVG): kok yukarida, EVET sol / HAYIR sag,
#     oklar kutulari FIZIKSEL olarak baglar (UWorld dersi: yigilmis hap degil) ---
function KrDugumMu($n){ return ($n -isnot [string]) -and $n.PSObject -and $n.PSObject.Properties['soru'] }
function KrYaprak($n){ if(KrDugumMu $n){ return (KrYaprak $n.evet)+(KrYaprak $n.hayir) }; return 1 }
function KrDerin($n){ if(KrDugumMu $n){ return 1+[Math]::Max((KrDerin $n.evet),(KrDerin $n.hayir)) }; return 0 }
function KrYerlestir($n,[double]$x0,[int]$sev,[string]$dal,$sb,[double]$BW,[double]$GAP,[double]$LH,[double]$BH){
  $y=10+$sev*$LH
  if(-not (KrDugumMu $n)){
    $cx=($x0+0.5)*($BW+$GAP)
    $renk='#7fc98f'; if($dal -eq 'hayir'){ $renk='#e07b7b' }
    [void]$sb.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.6px solid $renk;border-radius:10px;color:$renk;font-size:12px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(0,0,0,.25)'>$(K "$n")</div></foreignObject>")
    return @($cx,1)
  }
  $sol=KrYerlestir $n.evet $x0 ($sev+1) 'evet' $sb $BW $GAP $LH $BH
  $sag=KrYerlestir $n.hayir ($x0+$sol[1]) ($sev+1) 'hayir' $sb $BW $GAP $LH $BH
  $cx=($sol[0]+$sag[0])/2
  [void]$sb.Append("<foreignObject x='$([int]($cx-$BW/2))' y='$([int]$y)' width='$([int]$BW)' height='$([int]$BH)'><div xmlns='http://www.w3.org/1999/xhtml' style='height:100%;display:flex;align-items:center;justify-content:center;text-align:center;border:1.8px solid #78b4ff;border-radius:10px;color:#e8e6e3;font-weight:700;font-size:12.5px;line-height:1.25;padding:4px 8px;box-sizing:border-box;background:rgba(120,180,255,.10)'>$(K "$($n.soru)")</div></foreignObject>")
  $py=$y+$BH; $cyy=10+($sev+1)*$LH
  foreach($cift in @(@($sol[0],'EVET','#7fc98f'),@($sag[0],'HAYIR','#e07b7b'))){
    $tx=$cift[0]; $et=$cift[1]; $rk=$cift[2]
    [void]$sb.Append("<path d='M $([int]$cx) $([int]$py) C $([int]$cx) $([int]($py+28)), $([int]$tx) $([int]($cyy-28)), $([int]$tx) $([int]$cyy)' fill='none' stroke='$rk' stroke-width='1.6' marker-end='url(#kok)'/>")
    $mx=($cx+$tx)/2; $my=($py+$cyy)/2
    [void]$sb.Append("<text x='$([int]$mx)' y='$([int]$my)' fill='$rk' font-size='11' font-weight='800' text-anchor='middle' style='paint-order:stroke;stroke:#1b1b1f;stroke-width:4px'>$et</text>")
  }
  return @($cx,($sol[1]+$sag[1]))
}
function KararSvg($kok){
  $BW=205.0; $GAP=14.0; $LH=112.0; $BH=62.0
  $yp=KrYaprak $kok; $dr=KrDerin $kok
  $W=[Math]::Max(430,[int]($yp*($BW+$GAP)))
  $H=[int](20+($dr+1)*$LH)
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<svg viewBox='0 0 $W $H' style='width:100%;max-width:${W}px;height:auto;display:block;margin:0 auto' xmlns='http://www.w3.org/2000/svg'><defs><marker id='kok' markerWidth='7' markerHeight='7' refX='5' refY='3.5' orient='auto'><path d='M0,0 L7,3.5 L0,7 z' fill='#8ab'/></marker></defs>")
  [void](KrYerlestir $kok 0.0 0 '' $sb $BW $GAP $LH $BH)
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}
function AcBlok($e,$c,[string]$etiket,[string]$renk){
  $sb=[Text.StringBuilder]::new()
  [void]$sb.Append("<div class='kolon' style='border-top:3px solid $renk'><div class='ketiket' style='color:$renk'>$etiket</div>")
  foreach($hh in 'A','B','C','D','E'){
    $isr=''; if("$($e.dogru)" -eq $hh){ $isr=' ✓' }
    [void]$sb.Append("<p><b>$hh$isr)</b> $(K $c.aciklama.$hh)</p>")
  }
  if($c.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $c.sinav_taktigi)</div>") }
  if($c.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $c.notlandirici)</div>") }
  if($c.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $c.hap)</div>") }
  # sema (yalniz yeni tarafta olur)
  if($c.sema -and $c.sema.tur){
    $s=$c.sema
    [void]$sb.Append("<div class='sema'><div class='semabaslik'>🗺️ $(K $s.baslik)</div>")
    switch("$($s.tur)"){
      'kiyas'{
        [void]$sb.Append("<div class='kiyas'>")
        foreach($og in @($s.ogeler)){
          [void]$sb.Append("<div class='kiyaskutu'><div class='kiyasbas'>$(K $og.ad)</div>")
          foreach($m in @($og.maddeler)){ [void]$sb.Append("<div class='kiyasmad'>• $(K $m)</div>") }
          [void]$sb.Append("</div>")
        }
        [void]$sb.Append("</div>")
      }
      'karar'{
        $kok2=$s.kok; if(-not $kok2 -and $s.ogeler){ $kok2=@($s.ogeler)[0] }
        if($kok2){ [void]$sb.Append((KararSvg $kok2)) }
      }
      'akis'{
        [void]$sb.Append("<div class='akis'>" + ((@($s.ogeler) | % { "<span class='akisadim'>$(K $_)</span>" }) -join "<span class='akisok'>→</span>") + "</div>")
      }
      'zaman'{
        foreach($og in @($s.ogeler)){ [void]$sb.Append("<div class='zamansatir'><span class='zamanan'>$(K $og.an)</span> $(K $og.olay)</div>") }
      }
      'yevmiye'{
        [void]$sb.Append("<table class='tcetvel'><tr><th colspan='2'>BORÇ</th><th colspan='2'>ALACAK</th></tr>")
        $bl=@($s.ogeler.borc); $al=@($s.ogeler.alacak)
        $n=[Math]::Max($bl.Count,$al.Count)
        for($q=0;$q -lt $n;$q++){
          $bh='';$bt='';$ah='';$at=''
          if($q -lt $bl.Count){ $bh=K $bl[$q].hesap; $bt=K $bl[$q].tutar }
          if($q -lt $al.Count){ $ah=K $al[$q].hesap; $at=K $al[$q].tutar }
          [void]$sb.Append("<tr><td class='thesap'>$bh</td><td class='ttutar'>$bt</td><td class='thesap talacak'>$ah</td><td class='ttutar'>$at</td></tr>")
        }
        [void]$sb.Append("</table>")
      }
    }
    [void]$sb.Append("</div>")
  }
  [void]$sb.Append("</div>")
  return $sb.ToString()
}

$css=@'
body{font-family:Segoe UI,sans-serif;max-width:1180px;margin:20px auto;padding:0 16px;background:#1b1b1f;color:#e8e6e3}
.soru{border:1px solid #444;border-radius:12px;padding:16px;margin:22px 0}
.dogru{color:#7fc98f;font-weight:600}.sik{margin:3px 0;font-size:.95em}
.cift{display:flex;gap:14px;margin-top:12px;align-items:flex-start;flex-wrap:wrap}
.kolon{flex:1;min-width:340px;background:#26262c;border-radius:8px;padding:12px;font-size:.9em;line-height:1.55}
.kolon b{color:#c9a227}.ketiket{font-weight:900;font-size:.82em;letter-spacing:.6px;margin-bottom:8px}
.kutu{border-left:3px solid #78b4ff;background:rgba(120,180,255,.07);border-radius:0 8px 8px 0;padding:8px 11px;margin-top:8px;font-size:.9em}
.kutu2{border-left:3px solid #c9a227;background:rgba(201,162,39,.07);border-radius:0 8px 8px 0;padding:8px 11px;margin-top:8px;font-size:.9em}
.sema{border:1px dashed #7fc98f;border-radius:10px;padding:10px;margin-top:12px;background:rgba(127,201,143,.05)}
.semabaslik{font-weight:800;color:#7fc98f;margin-bottom:8px;font-size:.92em}
.kiyas{display:flex;gap:10px;flex-wrap:wrap}
.kiyaskutu{flex:1;min-width:140px;border:1px solid #555;border-radius:8px;padding:8px}
.kiyasbas{font-weight:800;color:#78b4ff;border-bottom:1px solid #444;padding-bottom:4px;margin-bottom:6px}
.kiyasmad{font-size:.86em;margin:3px 0}
.karar{text-align:center}.kararsoru{display:inline-block;border:1px solid #78b4ff;border-radius:8px;padding:6px 12px;font-weight:700;margin-bottom:8px}
.kararsatir{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}
.kararevet{border:1px solid #7fc98f;color:#7fc98f;border-radius:8px;padding:6px 10px;font-size:.86em}
.kararhayir{border:1px solid #e07b7b;color:#e07b7b;border-radius:8px;padding:6px 10px;font-size:.86em}
.akis{display:flex;flex-wrap:wrap;gap:6px;align-items:center}
.akisadim{border:1px solid #78b4ff;border-radius:999px;padding:4px 10px;font-size:.84em}
.akisok{color:#78b4ff;font-weight:900}
.zamansatir{margin:4px 0;font-size:.88em}.zamanan{display:inline-block;min-width:110px;color:#78b4ff;font-weight:700}
.tcetvel{border-collapse:collapse;margin-top:6px;font-size:.88em;width:100%}
.tcetvel th{border-bottom:2px solid #7fc98f;color:#7fc98f;padding:4px 8px;text-align:center}
.tcetvel td{padding:4px 8px;border-bottom:1px dotted #444}
.thesap{text-align:left}.talacak{padding-left:26px !important;color:#e8e6e3}
.ttutar{text-align:right;font-variant-numeric:tabular-nums;color:#c9a227;font-weight:700}
h1{font-size:1.3em}.tip{display:inline-block;font-size:11.5px;font-weight:900;border-radius:999px;padding:4px 12px;margin-bottom:10px;border:1px solid rgba(120,180,255,.5);background:rgba(120,180,255,.08)}
'@
$sb=[Text.StringBuilder]::new()
[void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><title>Ton Provası — Kural 25 + Konsept Şeması (5 soru)</title><style>$css</style></head><body>")
[void]$sb.Append("<h1>Ton provası: aynı 5 soru — solda mevcut açıklama, sağda kural 25 (hoca tonu) + konsept şeması</h1><p style='color:#aaa;font-size:13.5px'>28.08.2026 · Soru ve şıklar birebir aynı; yalnız açıklama takımı dönüştürüldü. Sağdaki yeşil çerçeveli kutu = yeni konsept şeması denemesi.</p>")
foreach($id in $SECIM){
  $e=$eski[$id]; $c=$yeni[$id]
  if(-not $e){ continue }
  [void]$sb.Append("<div class='soru'><span class='tip'>$id</span><p><b>$(K $e.soru)</b></p>")
  foreach($hh in 'A','B','C','D','E'){
    $cls='sik'; if("$($e.dogru)" -eq $hh){ $cls='sik dogru' }
    [void]$sb.Append("<div class='$cls'>$hh) $(K $e.siklar.$hh)</div>")
  }
  [void]$sb.Append("<div class='cift'>")
  [void]$sb.Append((AcBlok $e $e 'ESKİ — mevcut açıklama' '#e07b7b'))
  if($c){ [void]$sb.Append((AcBlok $e $c 'YENİ — kural 25: önce mantık + madde diyeti + şema' '#7fc98f')) }
  else{ [void]$sb.Append("<div class='kolon'>yeniden yazım üretilemedi</div>") }
  [void]$sb.Append("</div></div>")
}
[void]$sb.Append("</body></html>")
[IO.File]::WriteAllText($HEDEF,$sb.ToString(),[Text.UTF8Encoding]::new($false))
"yazildi: $HEDEF"
