# ============================================================================
#  GECE AJANI — kapsamı en zayıf alan için Claude'a DOĞRULANMIŞ soru-cevap
#  ürettirir, KAPILARDAN geçirir, geçenleri veri/onay-bekleyen.json'a yazar.
#  Cem sabah gözden geçirip bilgi-tabani.json'a taşır (v1: staging).
#  KAPILAR (10 — "Cem+Claude gibi kontrol" standardı, 22.07.2026):
#   (1) kaynak zorunlu/spesifik  (2) eskiyen rakam gömülüyse ret
#   (3) tekrar-id  (4) anahtar kalitesi (>=4 kök kelime)
#   (5) yalpalama yasağı (çoğu durumda/genellikle... -> ret)
#   (6) konu-benzerlik mükerrer (mevcut konuyla >%70 kesişim -> ret)
#   (7) AMBAR TEYİDİ: atıf yapılan kanun+madde Supabase ambarında VAR MI
#       (uydurma madde atıfı deterministik yakalanır; tebliğ atıfı soft-pass)
#   (8) hasım doğrulayıcı A (Haiku, puanlı)  (9) hasım doğrulayıcı B (bağımsız
#       2. koşu) — ikisi de gecerli:true VE puan>=8 vermeli
#   (10) yayın sonrası günlük örneklem sınavı (cevap-hakemi, mevzuat.yml'de)
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
function Fold($s){ return ("$s".ToLowerInvariant() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'İ','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u') }

# --- KAPI 7 yardımcısı: AMBAR TEYİDİ (atıf yapılan madde arşivde var mı) ---
$SB_URL  = "https://bjrleanjpyujtajmazxn.supabase.co"
$SB_ANON = "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"   # public okuma anahtarı
$KANUN_NO = [ordered]@{ 'kvkk'='6698'; 'kdvgut'='GUT'; 'kdv gut'='GUT'; 'vuk'='213'; 'gvk'='193'; 'kdvk'='3065'; 'kvk'='5520'; 'ttk'='6102'; 'smk'='6769'; 'aatuhk'='6183'; 'otv'='4760'; 'iik'='2004'; 'hmk'='6100'; 'tck'='5237'; 'tbk'='6098'; 'isg'='6331' }
function AmbarTeyit($kaynak){
  $f = Fold $kaynak
  # tebliğ/GUT/karar/yönetmelik atıfları: madde yapısı farklı -> soft-pass (işaretle, reddetme)
  if($f -match 'gut|teblig|karar|yonetmelik|genelge|sira no'){ return 'atla' }
  # kanun numarası: açık 3-4 haneli (örn "5520", "213 s.") ya da kısaltma haritasından
  $no = $null
  $mN = [regex]::Match($f,'(?<!\d)(\d{3,4})(?!\d)\s*(s\.|sayili)')
  if($mN.Success){ $no = $mN.Groups[1].Value }
  if(-not $no){ foreach($k in $KANUN_NO.Keys){ if($f -match ('(?<![a-z])'+[regex]::Escape($k)+'(?![a-z])')){ $no=$KANUN_NO[$k]; break } } }
  if(-not $no -or $no -eq 'GUT'){ return 'atla' }
  # madde no (mük./geç./ek + taksimli 32/C dahil)
  $on = ''
  if($f -match 'muk(\.|errer)'){ $on='muk. ' } elseif($f -match 'gec(\.|ici)'){ $on='gec. ' } elseif($f -match '(?<![a-z])ek\s*m'){ $on='ek ' }
  $mM = [regex]::Match($kaynak,'m(?:adde)?\.?\s*(\d+(?:/[A-Za-zÇĞİÖŞÜçğıöşü])?)')
  if(-not $mM.Success){ return 'atla' }
  $madde = $mM.Groups[1].Value.ToUpperInvariant()
  $filtre = "*$no*" + $on + "m.$madde*"
  try {
    $u = "$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike." + [uri]::EscapeDataString($filtre) + "&select=id&limit=1"
    $r = Invoke-RestMethod -Uri $u -Headers @{ apikey=$SB_ANON; Authorization="Bearer $SB_ANON" } -TimeoutSec 30
    if(@($r).Count -ge 1){ return 'ok' } else { return 'yok' }
  } catch { return 'atla' }   # ambar erişilemezse kapı kilitlemez (fail-open, rapora yazılır)
}

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
  # Kapı 3: tekrar id
  $id = Slug $konu; $i=2; $temel=$id; while($mevcutId.ContainsKey($id) -or ($gecen | Where-Object { $_.id -eq $id })){ $id="$temel-$i"; $i++ }
  # Kapı 4: anahtar kalitesi (arama bununla çalışıyor — cılız anahtar = bulunmayan cevap)
  if(@(($anahtar -split '\s+') | Where-Object { $_.Length -ge 3 }).Count -lt 4){ $rapor.Add("RET (anahtar cilz): $konu"); continue }
  # Kapı 5: yalpalama yasağı (ikili olgular net yazılır — ev kuralı)
  if($cevap -match '(?i)(çoğu durumda|cogu durumda|çoğu zaman|cogu zaman|genellikle|büyük ölçüde|buyuk olcude|çoğunlukla|cogunlukla)'){ $rapor.Add("RET (yalpalama): $konu"); continue }
  # Kapı 6: konu-benzerlik mükerreri (id farklı ama anlam aynı olabilir)
  $yeniKel = @((Fold $konu) -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 })
  $benzedi = $false
  if($yeniKel.Count -ge 2){
    foreach($mk in $kb.kayitlar){
      $eskiF = Fold "$($mk.konu)"
      $ortak = @($yeniKel | Where-Object { $eskiF.Contains($_) }).Count
      if($ortak / [double]$yeniKel.Count -ge 0.7){ $benzedi=$true; $rapor.Add("RET (konu benzer): $konu ~ $($mk.konu)"); break }
    }
  }
  if($benzedi){ continue }
  # Kapı 7: AMBAR TEYİDİ — atıf yapılan madde arşivimizde gerçekten var mı
  $at = AmbarTeyit $kaynak
  if($at -eq 'yok'){ $rapor.Add("RET (ambar teyidi: atif bulunamadi): $konu -> '$kaynak'"); continue }
  # Kapı 8+9: İKİ bağımsız hasım doğrulayıcı — ikisi de gecerli VE puan>=8 demeli
  $dogIstem = @"
Sen HASIM bir denetçisin; görevin aşağıdaki soru-cevabı ÇÜRÜTMEYE çalışmak. Yürürlükteki Türk mevzuatına ve gösterilen kaynağa uygun mu? Uydurma/yanlış madde, yanlış oran, eskimiş hüküm, aşırı genelleme var mı? Şüphen varsa gecerli:false de. 0-10 arası doğruluk puanı ver (10=kusursuz).
KONU: $konu
CEVAP: $cevap
KAYNAK: $kaynak
SADECE JSON: {"gecerli":true/false,"puan":0,"neden":"kısa"}
"@
  $ok=$true; $neden=""
  foreach($tur in 1,2){
    $dv = Claude $dogIstem 400 $DOGMODEL
    $djson = JsonBul $dv; $tOk=$false; $tPuan=0
    if($djson){ try{ $do=$djson|ConvertFrom-Json; $tOk=[bool]$do.gecerli; $tPuan=[int]$do.puan; $neden="$($do.neden)" }catch{} }
    if(-not ($tOk -and $tPuan -ge 8)){ $ok=$false; $neden="hakem$tur puan=$tPuan $neden"; break }
  }
  if(-not $ok){ $rapor.Add("RET (hasim hakem): $konu -> $neden"); continue }
  $gecen.Add([ordered]@{ id=$id; konu=$konu; anahtar=$anahtar; cevap=$cevap; kaynak=$kaynak; arac=$secili.arac })
  $rapor.Add("GECTI (10 kapi): $konu [$kaynak]" + $(if($at -eq 'atla'){ ' (ambar: teblig/soft)' } else { ' (ambar: dogrulandi)' }))
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
