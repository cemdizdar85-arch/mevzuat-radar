# ============================================================================
#  NEYIN NESI DEGISTI SAYFASI (19.08.2026 - Cem: "eski hali / yeni hali,
#  ne degisti hap seklinde")
#
#  NE YAPAR: eski->yeni cifti olan her kart icin ayri bir karsilastirma
#  sayfasi uretir: degisen kalem, eski hali, yeni hali ve KELIME DUZEYINDE
#  fark isareti. Tamamen DETERMINISTIK - model cagrilmaz, uydurma riski yok;
#  gosterilen her kelime kartin kendi eski_yeni verisinden gelir.
#
#  NEDEN TEK SAYFA, IKI SUTUN DEGIL: telefonda iki tam metin yan yana
#  okunmaz. Ustelik eski tam metni AYRI SAYFA yapmak tehlikeli - arama
#  motoru indeksler, biri girip yururlukteki hal sanir. Burada eski hal
#  yalniz DEGISEN kalem icinde ve "ESKI HALI" seridiyle gosterilir.
#
#  Kullanim: .\arac\degisim-sayfasi.ps1            (hepsi)
#            .\arac\degisim-sayfasi.ps1 -Gun 11-07-2026
# ============================================================================
param([string]$Gun)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kartDir = Join-Path $kok 'motor\kartlar'
$cikisDir = Join-Path $kok 'arsiv\degisim'
New-Item -ItemType Directory -Force $cikisDir | Out-Null

function HtmlKac([string]$s){
  if($null -eq $s){ return "" }
  return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;')
}

# --- KELIME DUZEYINDE FARK (LCS) ---------------------------------------
# Iki metni kelimelere bolup ortak en uzun diziyi bulur; ortak olmayan
# kelimeler ESKI tarafta "cikarilan", YENI tarafta "eklenen" olarak isaretlenir.
function KelimeDizi([string]$s){ return @(($s -replace '\s+',' ').Trim() -split ' ' | Where-Object { $_ -ne '' }) }
function OrtakDizi($a, $b){
  # PS 5.1: tek elemanli dizi cozulur -> gelen deger STRING olabilir. Once sar.
  $a = @($a); $b = @($b)
  $n = $a.Count; $m = $b.Count
  $t = New-Object 'int[,]' ($n+1), ($m+1)
  # PS TUZAGI: [Math]::Max($t[$i+1,$j], $t[$i,$j+1]) ifadesi ayristirilamiyor
  # (2 boyutlu indeks + metot argumani). Once gecici degiskene al.
  for($i=$n-1; $i -ge 0; $i--){
    for($j=$m-1; $j -ge 0; $j--){
      $i1 = $i + 1; $j1 = $j + 1
      if($a[$i] -eq $b[$j]){
        $t[$i,$j] = $t[$i1,$j1] + 1
      } else {
        $sag = $t[$i1,$j]
        $alt = $t[$i,$j1]
        if($sag -ge $alt){ $t[$i,$j] = $sag } else { $t[$i,$j] = $alt }
      }
    }
  }
  # geri yurume: her kelime icin ortak mi degil mi
  $aOrtak = New-Object 'bool[]' $n
  $bOrtak = New-Object 'bool[]' $m
  $i = 0; $j = 0
  while($i -lt $n -and $j -lt $m){
    if($a[$i] -eq $b[$j]){ $aOrtak[$i] = $true; $bOrtak[$j] = $true; $i++; $j++; continue }
    $i1 = $i + 1; $j1 = $j + 1
    $sag = $t[$i1,$j]
    $alt = $t[$i,$j1]
    if($sag -ge $alt){ $i++ } else { $j++ }
  }
  return @{ a=$aOrtak; b=$bOrtak }
}
function FarkHtml([string]$metin, $ortak, [string]$sinif){
  $kelimeler = @(KelimeDizi $metin)
  $ortak = @($ortak)
  $sb = New-Object System.Text.StringBuilder
  for($i=0; $i -lt $kelimeler.Count; $i++){
    $k = HtmlKac $kelimeler[$i]
    if($ortak[$i]){ [void]$sb.Append($k) } else { [void]$sb.Append("<mark class='$sinif'>$k</mark>") }
    if($i -lt $kelimeler.Count-1){ [void]$sb.Append(' ') }
  }
  return $sb.ToString()
}

$sayfa = 0; $blokToplam = 0
$gunler = @(Get-ChildItem $kartDir -Directory | Where-Object { -not $Gun -or $_.Name -eq $Gun } | Sort-Object Name)
foreach($gd in $gunler){
  $jy = Join-Path $gd.FullName 'kartlar.json'
  if(-not (Test-Path $jy)){ continue }
  $kartlar = @((ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($jy, [System.Text.Encoding]::UTF8))))
  foreach($k in $kartlar){
    if($null -eq $k -or -not $k.baslik_sade){ continue }
    $ciftler = @($k.eski_yeni | Where-Object { $_ -and "$($_.eski)".Trim() -and "$($_.yeni)".Trim() })
    if(-not $ciftler.Count){ continue }
    # Sayfa adi KARTIN KENDI dosyasindan turer (20260620-21.htm -> 20260620-21.html):
    # boylece kart basimi, gunu bilmeden bagalantiyi kurabilir.
    $dosyaAd = (("$($k.dosya)" -replace '\.htm$','') + ".html")
    $yol = Join-Path $cikisDir $dosyaAd

    $s = New-Object System.Text.StringBuilder
    [void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
    [void]$s.AppendLine("<title>Neyin nesi değişti - $(HtmlKac $k.baslik_sade) | Tetikte</title>")
    [void]$s.AppendLine('<meta name="robots" content="noindex">')
    [void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="../../favicon.svg"><style>')
    [void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#ffc24b;--red:#ff6b5e;--green:#3ddc97}')
    [void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6}')
    [void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:840px;margin:0 auto;padding:24px 18px 70px}')
    [void]$s.AppendLine('.top{font-size:13px;color:var(--dim);margin-bottom:18px}.top a{color:var(--muted);text-decoration:none;font-weight:600}')
    [void]$s.AppendLine('h1{font-size:clamp(20px,4vw,27px);letter-spacing:-.6px;margin:4px 0 6px;font-weight:800}')
    [void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:18px}')
    [void]$s.AppendLine('.blok{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:16px 18px;margin-bottom:14px}')
    [void]$s.AppendLine('.nerede{font-size:11px;font-weight:800;letter-spacing:.8px;color:var(--accent2);text-transform:uppercase}')
    [void]$s.AppendLine('.hal{border-radius:10px;padding:10px 13px;margin-top:9px;font-size:13.5px;line-height:1.75}')
    [void]$s.AppendLine('.hal .etiket{display:block;font-size:10.5px;font-weight:800;letter-spacing:.8px;margin-bottom:5px}')
    [void]$s.AppendLine('.eski{background:rgba(255,107,94,.07);border:1px solid rgba(255,107,94,.28)}.eski .etiket{color:var(--red)}')
    [void]$s.AppendLine('.yeni{background:rgba(61,220,151,.07);border:1px solid rgba(61,220,151,.28)}.yeni .etiket{color:var(--green)}')
    [void]$s.AppendLine('mark.cik{background:rgba(255,107,94,.22);color:#ffd7d2;border-radius:4px;padding:0 3px;text-decoration:line-through}')
    [void]$s.AppendLine('mark.ekle{background:rgba(61,220,151,.22);color:#c7f7e3;border-radius:4px;padding:0 3px;font-weight:700}')
    [void]$s.AppendLine('.ozet{font-size:12.5px;color:var(--dim);margin-top:8px}')
    [void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 22px}')
    [void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:26px;padding-top:14px;border-top:1px solid var(--line)}')
    [void]$s.AppendLine('</style></head><body><div class="wrap">')
    [void]$s.AppendLine('<div class="top"><a href="../../kartlar.html">← Günün Kartları</a> · <a href="../index.html">Arşiv</a></div>')
    [void]$s.AppendLine("<h1>Neyin nesi değişti?</h1>")
    [void]$s.AppendLine("<div class='alt'>$(HtmlKac $k.baslik_sade)<br><span style='color:var(--dim)'>$($gd.Name -replace '-','.') tarihli Resmî Gazete</span></div>")
    # 21.08.2026 - ESKI HAL TARIHSIZ GOSTERILMEZ. Tebliglerin resmi konsolide metni
    # yok; "eskiden boyleydi" demek, o tarihten bugune baska degisiklik olmadigini
    # iddia etmektir - bunu olcmedik. Bu yuzden iki kaynak ayri etiketlenir:
    #   (1) eski_karsilastirma dolu  -> eski hal o tarihli RG metninden geldi
    #   (2) satirin kaynagi 'metin'  -> tebligin kendi "X ibaresi Y seklinde
    #       degistirilmistir" cumlesinden geldi, ayri bir RG okunmadi
    $eskiRgTarih = "$($k.eski_karsilastirma)".Trim()
    $gunNokta    = ($gd.Name -replace '-','.')
    $rgSatir     = @($ciftler | Where-Object { "$($_.kaynak)" -ne 'metin' }).Count
    $kaynakCumle = if($eskiRgTarih -and $rgSatir -gt 0){
        "Eski hâl için $eskiRgTarih tarihli Resmî Gazete metni okundu; yeni hâl $gunNokta tarihli tebliğden alındı."
      } else {
        "Karşılaştırma, tebliğin kendi metnindeki değişiklik cümlelerinden birebir çıkarıldı."
      }
    [void]$s.AppendLine("<div class=""uyari"">Aşağıda tebliğin <b>yalnızca değişen kalemleri</b> var: solda eski hâli, sağda (telefonda altta) yeni hâli. <b>Kırmızı üstü çizili</b> kelimeler çıkarılanı, <b>yeşil kalın</b> kelimeler eklenen ya da değişeni gösterir. $kaynakCumle Eski hâl, o tarihteki metindir; <b>aradaki dönemde başka bir değişiklik olup olmadığı bu sayfada ölçülmez.</b></div>")

    foreach($c in $ciftler){
      $eski = "$($c.eski)"; $yeni = "$($c.yeni)"
      $ea = @(KelimeDizi $eski); $yb = @(KelimeDizi $yeni)
      $ort = OrtakDizi $ea $yb
      $eskiHtml = FarkHtml $eski $ort.a 'cik'
      $yeniHtml = FarkHtml $yeni $ort.b 'ekle'
      $cikan = @($ort.a | Where-Object { -not $_ }).Count
      $eklenen = @($ort.b | Where-Object { -not $_ }).Count
      [void]$s.AppendLine('<div class="blok">')
      [void]$s.AppendLine("<div class='nerede'>$(HtmlKac $c.konu)</div>")
      # Etiket satir bazinda: bu satirin eski hali nereden geldi?
      $eskiEtiket = "ESKİ HÂLİ · $gunNokta değişikliğinden önce"
      $yeniEtiket = "YENİ HÂLİ · $gunNokta tarihli değişiklikle"
      [void]$s.AppendLine("<div class='hal eski'><span class='etiket'>$eskiEtiket</span>$eskiHtml</div>")
      [void]$s.AppendLine("<div class='hal yeni'><span class='etiket'>$yeniEtiket</span>$yeniHtml</div>")
      [void]$s.AppendLine("<div class='ozet'>$cikan kelime çıktı · $eklenen kelime geldi</div>")
      [void]$s.AppendLine('</div>')
      $blokToplam++
    }

    $degMad = @($k.degisen_maddeler | Where-Object { "$_".Trim() })
    if($degMad.Count){
      [void]$s.AppendLine('<div class="blok"><div class="nerede">Ayrıca bu maddeler</div>')
      foreach($dm in $degMad){ [void]$s.AppendLine("<div class='ozet' style='color:var(--muted);font-size:13px'>• $(HtmlKac $dm)</div>") }
      [void]$s.AppendLine('</div>')
    }
    if("$($k.yururluk)".Trim()){ [void]$s.AppendLine("<div class='ozet' style='font-size:13px'><b style='color:var(--ink)'>Yürürlük:</b> $(HtmlKac $k.yururluk)</div>") }
    [void]$s.AppendLine("<div class='dip'>Kaynak: <a href='$(HtmlKac $k.kaynak)' target='_blank' rel='noopener'>Resmî Gazete metni</a>. Bu sayfa yalnız değişen kalemleri gösterir; tebliğin yürürlükteki tam hâli için kaynak metni açın. Bilgilendirme amaçlıdır.</div>")
    [void]$s.AppendLine('</div></body></html>')

    [System.IO.File]::WriteAllText($yol, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    $sayfa++
  }
}
"Uretilen degisim sayfasi: $sayfa"
"Toplam karsilastirma blogu : $blokToplam"
