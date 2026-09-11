#requires -Version 5.1
<#
================================================================================
  SADE TAMAMLAMA TURU — üretilmiş soruya FAZ S'i sonradan koşar (11.09.2026)
  Cem: "sade olsun ve 650 soruyu basalım"

  NEDEN: `sade` (Sade Doğrusu + sınav dili + anahtar kavramlar) Kaydır-Çöz
  ekranının 2. ve 5. parçasıdır. Ölçüldü (10.09): 213 partinin yalnız 15'inde
  var, hepsi 04-06.09 arası ELLE koşulan partiler. 07.09'da toplu hatta
  geçilirken `kalip-kosucu.ps1`in argüman listesine `-Sade` KONMAMIŞ; 198 parti
  FAZ S çalışmadan üretti. Üretici bozulmadı — çağrılmayan bir faz vardı.

  BU BETİK YENİDEN ÜRETMEZ. Soru, şık, açıklama, HAP, tuzak, dayanak hepsi
  yerinde; yalnız eksik alan doldurulur. FAZ S zaten `sade`si olanı atlar.

  ⛔ BEDEL EMNİYETİ — üç katman:
    1) -PilotId : model fazları YALNIZ seçili id'lere koşar. Parti dosyasında
       500 soru olsa da yalnız listedekiler işlenir.
    2) -Tavan   : toplam soru tavanı. Aşılırsa DURUR.
    3) Kuru koşu varsayılan: -Yaz demeden HİÇBİR API çağrısı yapılmaz.
  09.09 dersi: `uret.ps1` sınamak için çalıştırıldı, gerçek üretim başladı,
  5,75 USD gitti. O yüzden bu betik varsayılanda hiçbir şey harcamaz.

  ÖLÇÜLEN BEDEL: 0,009 USD/soru (Haiku 4.5, 10.09 provası: 6 soru / 0,054 USD).
  ⚠ 11.09 GÜNCEL: KAPI-HG `hesap_uyum`u zorunlu kıldıktan sonra hakem de yeniden
    koşuyor. Ölçülen (11.09 provası, pilot6-fmuh-cokzor/kp-02): hakem + sade
    birlikte 2 çağrı / 0,019 USD per soru — yani 0,009 DEĞİL, ~0,019 USD.
    1.109 soruluk hasat ≈ 21 USD ≈ 864 TL. Hakem tazelemesi bedava değil ama
    kp-80 sınıfı hatayı (yanlış THP hesabı) yakalayan `hesap_uyum` onunla geliyor.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sade-tamamla.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sade-tamamla.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,                       # olmadan: kuru koşu, bedel 0
  [int]$Tavan = 700,                  # toplam soru tavanı
  # 11.09 Cem "paralel koştur": aynı anda kaç parti koşsun. 1 = eski sıralı
  # davranış. Ölçüldü: sıralı turda parti başına ~6 dk, 89 parti ≈ 9 saat.
  # ⚠ Paralellik BEDELİ DEĞİŞTİRMEZ, yalnız duvar saatini kısaltır.
  # ⚠ Tavanı yükseltmek riskli: her parti ayrı PowerShell süreci + API çağrısı;
  #   çok yüksekte 429 (hız sınırı) başlar ve tekrar denemeler işi YAVAŞLATIR.
  #   4 seçildi çünkü partiler zaten kendi içinde toplu (paralel) gidiyor.
  [ValidateRange(1,8)][int]$Paralel = 4,
  [string]$PlanDosyasi = 'veri\_sade-plan.json'   # ⚠ adi "$Plan" OLMAZ: asagidaki
)                                                 # is listesi $isler'e okunur; PS harf
                                                  # ayirmadigi icin [string] tur kisiti
                                                  # diziyi sessizce string'e cevirirdi.
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$uret    = Join-Path $depoKok 'motor\kalip-parti-uret.ps1'
$logDir  = Join-Path $depoKok 'veri\fabrika\sade-log'
if(-not (Test-Path $logDir)){ New-Item -ItemType Directory -Force $logDir | Out-Null }

$planYol = if([IO.Path]::IsPathRooted($PlanDosyasi)){ $PlanDosyasi } else { Join-Path $depoKok $PlanDosyasi }
$isler = @((Get-Content $planYol -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })
$toplam = ($isler | Measure-Object -Property adet -Sum).Sum
# Birim bedel: hakem tazelemesi gerekiyorsa 2 cagri (hakem+sade) = 0,019 USD/soru,
# hakem kaydi tamsa yalniz sade = 0,009. Ikisi de 11.09 provasindan OLCULU.
# Plan dosyasi hangisinin gecerli oldugunu bilmiyor; kaydi acip sayariz ki
# ekrandaki rakam gercegin ALTINDA kalmasin (11.09'da 409 TL dedim, 855 cikti).
$tazeN=0
foreach($p0 in $isler){
  $f0=Join-Path $depoKok "veri\fabrika\kalip-parti-$($p0.etiket).json"; if(-not (Test-Path $f0)){ continue }
  try{ $c0=Get-Content $f0 -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  foreach($i0 in ("$($p0.idler)" -split ',')){
    $v0=$c0.$i0; if(-not $v0 -or -not $v0.hakem){ continue }
    if(-not $v0.hakem.PSObject.Properties['hesap_uyum']){ $tazeN++ }
  }
}
$usdTah = ($tazeN*0.019) + (($toplam-$tazeN)*0.009)
Write-Host ("PLAN: {0} parti · {1} soru ({2}'inde hakem tazelenecek) · {3:N2} USD ≈ {4:N0} TL" -f $isler.Count,$toplam,$tazeN,$usdTah,($usdTah*41)) -ForegroundColor Cyan
if($toplam -gt $Tavan){ throw "TAVAN ASILDI: $toplam soru > $Tavan. Bilerek asilacaksa -Tavan yukselt." }
if(-not $Yaz){
  Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Gercekten kosmak icin: -Yaz" -ForegroundColor Yellow
  $isler | Sort-Object adet -Descending | ForEach-Object { Write-Host ("  {0,-38} {1,3} soru" -f $_.etiket,$_.adet) }
  return
}

# Bitis damgasi olan partide uretici "ATLANDI" deyip cikar; tamamlama turunda
# damgayi asmak GEREKLI - yeni soru uretmiyoruz, var olani tamamliyoruz.
$env:MEVZUAT_CLAIM = '0'

$sira=0; $basarili=0; $dusen=0
# --- PARALEL HAVUZ (11.09, Cem "paralel kostur") -----------------------------
# PS 5.1'de ForEach-Object -Parallel YOK. Her parti AYRI SUREC olarak baslatilir
# ve havuzda en fazla $Paralel surec tutulur. Guvenli olmasinin sebebi: her
# parti KENDI cache dosyasina yazar (kalip-parti-<etiket>.json), ortak dosyalar
# ise kilitli - bekleyen-partiler.json Mutex'liydi, bedel-kayit.jsonl'a da
# 11.09'da Mutex eklendi (paralel yazim satiri bozabilirdi).
$kuyruk=New-Object System.Collections.Generic.Queue[object]
foreach($p in ($isler | Sort-Object adet -Descending)){ $kuyruk.Enqueue($p) }
$aktif=New-Object System.Collections.Generic.List[object]

function NabizYaz($p){
  try{
    $c = Get-Content (Join-Path $depoKok "veri\fabrika\kalip-parti-$($p.etiket).json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $n=0;$s=0
    foreach($pp in $c.PSObject.Properties){ $v=$pp.Value; if(-not $v.soru){continue}; $n++; if($v.sade -and $v.sade.dogru){$s++} }
    Write-Host ("      NABIZ {0}: sade {1}/{2}" -f $p.etiket,$s,$n)
  }catch{}
}

while($kuyruk.Count -gt 0 -or $aktif.Count -gt 0){
  # bos yer varsa yeni parti baslat
  while($aktif.Count -lt $Paralel -and $kuyruk.Count -gt 0){
    $p=$kuyruk.Dequeue(); $sira++
    $log = Join-Path $logDir ("$($p.etiket).log")
    Write-Host ("[{0}] {1}/{2} BASLADI  {3}  ({4} soru) · aktif {5}" -f (Get-Date -Format HH:mm), $sira, $isler.Count, $p.etiket, $p.adet, ($aktif.Count+1)) -ForegroundColor Cyan
  # -CizmeAtla (11.09): tamamlama turunda parti kendi denetim HTML'ini CIZMEZ.
  # Olculdu: cizim 77 soruluk partide 54 sn; 27 partide ≈24 dk. Tur sonunda
  # 9 yayin sayfasi zaten tek seferde yeniden basiliyor (arac/sgs-650-bas.ps1).
  # Yan etki bilincli: bitis damgasi basilmaz - zaten MEVZUAT_CLAIM=0 ile asiyoruz.
  # ⛔ 11.09: burada '-DersRegex ''.''' vardi ve TUR BASTAN SONA DUSTU.
  #    Sebep: ayni gun KAPI-HG `hesap_uyum`i zorunlu kildi -> hakem YENIDEN kosar oldu;
  #    KAPI-DR de "hakem kosacaksa ders adi gercek olmali" diye dogru sekilde durdurdu.
  #    Hakeme "bu soru '.' dersine mi ait" diye sorulsaydi DERS-DISI damgalanip
  #    sorular yayindan dusecekti. Ders artik plan dosyasindan (etiketten cozulmus) gelir.
  $ders="$($p.ders)".Trim()
  if(-not $ders){ throw "PLAN EKSIK: $($p.etiket) icin ders yok. Plan uretici ders alanini doldurmali (KAPI-DR)." }
  # 11.09 Cem "toplu istege gec": hakem (H) ve sade (S) fazlari artik Message
  # Batches ile gidiyor -> yari fiyat + paralel. Sirali kosuda 1.098 soru x 2
  # cagri = 2.196 istek, olculen hiz 25 sn/soru ≈ 7,6 saat ve tam fiyat.
    # ⛔ 11.09 KAZA: burada tirnak YOKTU ve 86 partinin 86'si 0 saniyede dustu
    #    (bedel 0, kayip yok). Sebep: Start-Process -ArgumentList diziyi BOSLUKLA
    #    birlestirip TEK komut satiri yapar; depo yolu "...\mevzuat işi\..." bosluk
    #    tasidigi icin komut satiri ikiye bolunuyor ve powershell dosyayi bulamiyor.
    #    Bosluk tasiyabilen her arguman TIRNAK icine alinir.
    function Tir([string]$s){ if($s -match '\s'){ return ('"' + $s + '"') }; return $s }
    $arg = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Tir $uret),
             '-Sinav','SGS','-DersRegex',(Tir $ders),'-Etiket',(Tir "$($p.etiket)"),'-Adet',"$([int]$p.adet)",
             '-Sade','-CizmeAtla','-Toplu','-PilotId',(Tir "$($p.idler)"))
    # Cikti dosyaya yonlendirilir; Start-Process ile surec BEKLENMEDEN baslar.
    $ps=Start-Process -FilePath 'powershell' -ArgumentList $arg -PassThru -WindowStyle Hidden `
                      -RedirectStandardOutput $log -RedirectStandardError ("$log.err")
    $aktif.Add([pscustomobject]@{ p=$p; ps=$ps; log=$log; bas=(Get-Date) })
  }
  if(-not $aktif.Count){ break }
  # Ilk aktif surecin bitmesini EN FAZLA 5 sn bekle; bitmezse donguye don ve
  # digerlerini kontrol et. Process nesnesi WaitHandle vermez, bu yuzden
  # WaitAny kullanilamaz; WaitForExit(ms) tek surec icin dogru ve mesgul
  # dongu uretmez (5 sn bloklar).
  [void]$aktif[0].ps.WaitForExit(5000)
  foreach($a in @($aktif.ToArray())){
    if(-not $a.ps.HasExited){ continue }
    $sure=[int]((Get-Date)-$a.bas).TotalSeconds
    # ⚠ Start-Process -PassThru dondurdugu Process'te ExitCode, tam WaitForExit()
    #   cagrilmadan BOS gelebilir (11.09: basarili parti "dustu" sayildi).
    #   Surec zaten bitti, bu cagri aninda doner.
    try{ $a.ps.WaitForExit() }catch{}
    $cikis=$null; try{ $cikis=$a.ps.ExitCode }catch{}
    $bedel = (Select-String -Path $a.log -Pattern 'BEDEL TOPLAM' -ErrorAction SilentlyContinue | Select-Object -Last 1).Line
    # Basari olcutu: cikis 0 YA DA logda bedel satiri var (parti sonuna kadar kostu).
    $ok = ($cikis -eq 0) -or [bool]$bedel
    if($ok){ $basarili++ } else { $dusen++ }
    $renk=if($ok){'Gray'}else{'Yellow'}
    Write-Host ("[{0}] BITTI   {1} · {2} sn · cikis {3}" -f (Get-Date -Format HH:mm),$a.p.etiket,$sure,$(if($null -ne $cikis){$cikis}else{'?'})) -ForegroundColor $renk
    if($bedel){ Write-Host ("      {0}" -f $bedel.Trim()) }
    NabizYaz $a.p
    [void]$aktif.Remove($a)
  }
}
Write-Host ""
Write-Host ("TAMAMLAMA TURU BITTI: {0} parti basarili · {1} dustu (paralel {2})" -f $basarili,$dusen,$Paralel) -ForegroundColor Green
Write-Host "Siradaki: motor/kaydir-coz.ps1 -SecimDosya <yayin-sgs-*.json>"
