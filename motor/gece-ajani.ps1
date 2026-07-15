# ============================================================================
#  GECE AJANI — kapsamı en zayıf alan için Claude'a DOĞRULANMIŞ soru-cevap
#  ürettirir, KAPILARDAN geçirir, geçenleri veri/onay-bekleyen.json'a yazar.
#  Cem sabah gözden geçirip bilgi-tabani.json'a taşır (v1: staging).
#  KAPILAR: (1) kaynak zorunlu (madde/tebliğ), (2) eskiyen rakam gömülüyse
#  ret, (3) çapraz-doğrulama (2. Claude turu), (4) JSON+tekrar-id.
#  ENV: ANTHROPIC_API_KEY (zorunlu). Secret yoksa zarifçe atlar (exit 0).
#  GitHub Actions cron (gece) + manuel. GÜVENLİ AÇILIŞ: önce staging, kalite
#  görülünce YAYIN=1 ile canlıya (bilgi-tabani.json'a) yazmaya çevrilir.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$GENMODEL = "claude-sonnet-5"              # ÜRETİM: en iyi akıl (thinking → bol max_tokens ver)
$DOGMODEL = "claude-haiku-4-5-20251001"    # DOĞRULAMA: hızlı, thinking yok, JSON temiz
$ADET  = 6                          # her gece kaç yeni cevap denesin
$YAYIN = ($env:GECE_YAYIN -eq "1")  # 1 ise doğrudan bilgi-tabani'na yazar (kalite kanıtlanınca)

$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok — gece ajani atlandi. (GitHub Secrets)"; exit 0 }

function Claude($istem, $maxtok, $model){
  $body = @{ model=$model; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 240
  $blocks = @($r.content)
  $txt = ($blocks | Where-Object { $_.type -eq 'text' } | ForEach-Object { "$($_.text)" }) -join ""
  if(-not $txt){ $ozet=(($r | ConvertTo-Json -Depth 6 -Compress) -replace '\s+',' '); Write-Host ("HAM API YANIT (ilk 800): " + $ozet.Substring(0,[Math]::Min(800,$ozet.Length))) }
  return $txt
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; $m2=[regex]::Match($t,'(?s)\{.*\}'); if($m2.Success){ return $m2.Value }; return $null }
function Slug($s){ $x=("$s".ToLower() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u'); $x=($x -replace '[^a-z0-9]+','-').Trim('-'); if($x.Length -gt 40){ $x=$x.Substring(0,40).Trim('-') }; return $x }

# --- mevcut kapsam ---
$kbYol = Join-Path $kok "veri\bilgi-tabani.json"
$kb = Get-Content $kbYol -Raw -Encoding UTF8 | ConvertFrom-Json
$mevcutId = @{}; foreach($k in $kb.kayitlar){ $mevcutId["$($k.id)"]=$true }
$sayim = @{}; foreach($k in $kb.kayitlar){ $a="$($k.arac)"; if($a){ $sayim[$a]=1+($sayim[$a]) } }

# --- en zayıf alan (plan) ---
$plan = @(
  @{alan="Gümrük & ithalat/ihracat"; arac="gtip.html"; kanun="4458 Gümrük Kanunu, 474 GTİP, İthalat/İhracat Rejimi, DİR 2006/12"},
  @{alan="Marka & sınai mülkiyet"; arac="marka-radari.html"; kanun="6769 SMK"},
  @{alan="Kurumlar/Gelir vergisi & teşvik"; arac="index.html#app"; kanun="5520 KVK, 193 GVK, 5746 Ar-Ge, Yatırım Teşvik, 7524 asgari kurumlar"},
  @{alan="Şirket & ticaret hukuku"; arac="kurulus.html"; kanun="6102 TTK (kuruluş, genel kurul, sermaye, tasfiye)"},
  @{alan="SGK & bordro"; arac="index.html#app"; kanun="5510 SGK, 4857 İş K., 4447 İşsizlik"},
  @{alan="KDV & tevkifat & iade"; arac="kdv-iade-rehberi.html"; kanun="3065 KDVK, KDV Genel Uygulama Tebliği"}
)
$secili = $plan | Sort-Object { [int]($sayim["$($_.arac)"]) } | Select-Object -First 1
Write-Host ("Bu gece derinlesilecek alan: {0} (mevcut ~{1} kayit)" -f $secili.alan, ([int]$sayim["$($secili.arac)"]))

# --- ÜRETİM ---
$mevcutKonu = ($kb.kayitlar | ForEach-Object { $_.konu }) -join " · "
$uretimIstem = @"
Sen Türkiye mevzuatında uzman, TİTİZ bir soru-cevap içerik üreticisisin. Alan: "$($secili.alan)". Dayanılacak birincil mevzuat: $($secili.kanun).
Bu alanda MÜKELLEFLERİN EN ÇOK SORDUĞU ama listede OLMAYAN $ADET yeni soru-cevap üret.
KURALLAR (ihlal = ret):
1) Her cevap YALNIZ yürürlükteki birincil mevzuata dayansın; "kaynak" alanına SPESİFİK madde/tebliğ yaz (ör. "VUK m.323", "KDVGUT II/C").
2) Eskiyen rakam GÖMME (asgari ücret, prim oranı, tevkifat oranı, had, tavan). Kuralı yaz, güncel sayı için "güncel oranı/tutarı ilgili araçtan teyit et" de.
3) Sade Türkçe, muhasebe bilmeyen anlasın; zorunlu terimi tek parantezle açıkla; 3-6 kısa cümle. Uydurma YOK, emin değilsen o soruyu ATLA.
4) Zaten var olan konuları TEKRAR ETME. Var olanlar: $mevcutKonu
SADECE şu formatta JSON dizisi döndür (başka metin yok):
[{"konu":"...","anahtar":"kök kelimeler boşlukla, çekim değil","cevap":"...","kaynak":"madde/tebliğ"}]
"@
$ham = Claude $uretimIstem 8000 $GENMODEL
Write-Host ("HAM CEVAP uzunluk={0}; ilk 500: {1}" -f ("$ham").Length, (("$ham" -replace '\s+',' ')).Substring(0,[Math]::Min(500,("$ham" -replace '\s+',' ').Length)))
$js = JsonBul $ham
if(-not $js){ Write-Host "Uretim JSON verilemedi, cikiliyor."; exit 0 }
$uretilen = @()
try { $uretilen = $js | ConvertFrom-Json } catch { Write-Host "Uretim JSON parse hatasi."; exit 0 }

# --- KAPILAR ---
$gecen = New-Object System.Collections.Generic.List[object]
$rapor = New-Object System.Collections.Generic.List[string]
foreach($e in @($uretilen)){
  $konu="$($e.konu)"; $cevap="$($e.cevap)"; $kaynak="$($e.kaynak)"; $anahtar="$($e.anahtar)"
  if(-not $konu -or -not $cevap -or -not $anahtar){ $rapor.Add("RET (eksik alan): $konu"); continue }
  # Kapı 1: kaynak spesifik mi
  if($kaynak -notmatch '(?i)(m\.\s*\d|madde|teblig|tebliğ|kanun|bkk|karar|gut|gvk|kvk|vuk|kdvk|smk|ttk|iik|i̇i̇k|4458|5510|6769|4760)'){ $rapor.Add("RET (kaynak zayif): $konu -> '$kaynak'"); continue }
  # Kapı 2: eskiyen rakam gomulu mu (defer yoksa)
  $rakamli = ($cevap -match '%\s*\d' -or $cevap -match '\d[\d\.\,]*\s*(TL|lira)')
  $defer   = ($cevap -match '(?i)(güncel|guncel|teyit|araçtan|aractan|tebliğle|teblig)')
  if($rakamli -and -not $defer){ $rapor.Add("RET (eskiyen rakam gomulu): $konu"); continue }
  # Kapı 4: tekrar id
  $id = Slug $konu; $i=2; $temel=$id; while($mevcutId.ContainsKey($id) -or ($gecen | Where-Object { $_.id -eq $id })){ $id="$temel-$i"; $i++ }
  # Kapı 3: capraz-dogrulama (2. Claude turu, hasim gozle)
  $dogIstem = @"
Aşağıdaki soru-cevap DOĞRU mu? Yürürlükteki Türk mevzuatına ve gösterilen kaynağa uygun mu, uydurma/yanlış madde/yanlış oran var mı? Şüphen varsa gecerli:false de.
KONU: $konu
CEVAP: $cevap
KAYNAK: $kaynak
SADECE JSON: {"gecerli":true/false,"neden":"kısa"}
"@
  $dv = Claude $dogIstem 400 $DOGMODEL
  $djson = JsonBul $dv; $ok=$false; $neden=""
  if($djson){ try{ $do=$djson|ConvertFrom-Json; $ok=[bool]$do.gecerli; $neden="$($do.neden)" }catch{} }
  if(-not $ok){ $rapor.Add("RET (capraz-dogrulama): $konu -> $neden"); continue }
  $gecen.Add([ordered]@{ id=$id; konu=$konu; anahtar=$anahtar; cevap=$cevap; kaynak=$kaynak; arac=$secili.arac })
  $rapor.Add("GECTI: $konu [$kaynak]")
}

Write-Host ("KAPI SONUCU — uretilen={0} gecen={1}" -f @($uretilen).Count, $gecen.Count)
$rapor | ForEach-Object { Write-Host "  $_" }
if($gecen.Count -eq 0){ Write-Host "Bu gece yayina/onaya deger kayit cikmadi."; exit 0 }

# --- ÇIKTI ---
if($YAYIN){
  # kalite kanıtlandıktan sonra: doğrudan canlı bilgi-tabani.json
  $liste = New-Object System.Collections.Generic.List[object]; $liste.AddRange($kb.kayitlar); foreach($g in $gecen){ $liste.Add([pscustomobject]$g) }
  $kb.kayitlar = $liste.ToArray()
  [System.IO.File]::WriteAllText($kbYol, ($kb | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
  Write-Host ("YAYIN: {0} kayit bilgi-tabani.json'a eklendi (canli)." -f $gecen.Count)
} else {
  # v1 GÜVENLİ: onay-bekleyen.json (Cem sabah taşır)
  $sYol = Join-Path $kok "veri\onay-bekleyen.json"
  $s = @{ olusma="gece-ajani"; alan=$secili.alan; kayitlar=@() }
  if(Test-Path $sYol){ try{ $s = Get-Content $sYol -Raw -Encoding UTF8 | ConvertFrom-Json }catch{} }
  $sl = New-Object System.Collections.Generic.List[object]; if($s.kayitlar){ $sl.AddRange(@($s.kayitlar)) }; foreach($g in $gecen){ $sl.Add([pscustomobject]$g) }
  $out = @{ olusma="gece-ajani"; alan=$secili.alan; guncelleme=(Get-Date -Format "yyyy-MM-dd HH:mm"); kayitlar=$sl.ToArray() }
  [System.IO.File]::WriteAllText($sYol, ($out | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
  Write-Host ("STAGING: {0} kayit onay-bekleyen.json'a eklendi (sabah incele)." -f $gecen.Count)
}
exit 0
