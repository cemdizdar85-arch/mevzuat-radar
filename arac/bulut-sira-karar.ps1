# ============================================================================
#  BULUT SIRASI — KARAR İŞLEVLERİ (29.09.2026, Cem "1.2.3 üçünü de yap" madde 1)
#
#  NEDEN: soru basım planları bulutta açılırken aynı anda açık koşu sınırını her
#  sınav oturumu KENDİ makinesinde arka planda koşan bir bash "sıra betiği" ile
#  koruyordu. O betik Claude oturumuna bağlıydı; oturum kapanınca ölüyordu.
#  Ölçüldü: 27.09'da bitirme sırası çıkış 4 ile HATA YAZMADAN öldü, gm5-8..22 hiç
#  açılmadı, bulut 27.09 15:00 → 29.09 22:00 BOŞ kaldı; KGK oturumu da bu kuyruğu
#  bekliyordu.
#
#  YAPI: sıra depoda (veri/sinav/bulut-sira.json), dağıtıcı bulutta (bulut-sira.yml,
#  cron). Bu dosya YALNIZ saf işlev taşır: gh çağırmaz, dosya yazmaz → öz-sınav
#  (arac/bulut-sira-sinavi.ps1) sahte koşu listesiyle sınar.
#
#  "AÇILDI MI?" SORUSUNUN CEVABI SIRA DOSYASINDA DEĞİL, GITHUB KOŞU GEÇMİŞİNDE.
#    Dosyaya 'acildi' işareti yazmak iki yeni arıza açardı: (1) dispatch başarılı,
#    işaret commit'i düştü → sonraki tur aynı planı YENİDEN açar = ÇİFT ÖDEME;
#    (2) robot commit'i ile oturumun sıraya satır ekleyen commit'i çarpışır.
#    Geçmiş tek kaynaktır: plan için açık koşu varsa ya da sınır tarihinden sonra
#    açılmış koşu varsa plan AÇILDI sayılır.
#
#  PAY: açık koşular PLAN bazında sayılır (aynı planın halka N'si koşarken halka
#  N+1'i kuyrukta bekler → iki koşu ama TEK plan). Halka koşuları paya sayılır.
#
#  🚫 BU KAPI ŞUNU GÖRMEZ (yazılı körlük):
#    · Sıra dışından (elle / yerel betikle) aynı plan, dağıtıcının "yok" dediği an
#      ile dispatch'i arasında açılırsa ikisi de açılır (yarış penceresi ~saniyeler;
#      bulut-uretim concurrency grubu ikinciyi KUYRUĞA sokar ama yine koşar).
#      → Sıraya plan ekleyen oturum o planı ELLE açmaz, yerel sıra betiği DURDURULUR.
#    · Başlığı 'Bulut Uretim | <plan> | halka' kalıbına uymayan açık koşunun hangi
#      sınava ait olduğunu bilemez; yalnız toplama sayar (temkinli yön).
#    · Bütçenin DOĞRULUĞUNU (Cem onayı var mı) bilemez; yalnız biçimini ve
#      25 USD üstü ölçüm koşusu şartını denetler.
# ============================================================================

$script:BS_PLAN_DESEN   = '^veri/sinav/plan-[A-Za-z0-9._-]+\.json$'
$script:BS_BASLIK_DESEN = '^Bulut Uretim \| (\S+) \| halka'
$script:BS_OLCUM_ESIGI  = 25
$script:BS_KULTUR       = [Globalization.CultureInfo]::InvariantCulture

function BsSinavi([string]$PlanYolu) {
  # plan-smmm-gm5-11.json → smmm · plan-sgs-k13-gk-2.json → sgs · plan-c2.json → ''
  $m = [regex]::Match([IO.Path]::GetFileName("$PlanYolu"), '^plan-([A-Za-z0-9]+)-')
  if ($m.Success) { return $m.Groups[1].Value.ToLowerInvariant() }
  return ''
}

function BsZaman($Deger) {
  # gh createdAt (PS 5.1'de metin, PS 7'de ConvertFrom-Json DateTime yapar) → UTC DateTime ya da $null
  if ($null -eq $Deger) { return $null }
  if ($Deger -is [datetime]) {
    if ($Deger.Kind -eq [DateTimeKind]::Local) { return $Deger.ToUniversalTime() }
    return [datetime]::SpecifyKind($Deger, [DateTimeKind]::Utc)
  }
  if ($Deger -is [DateTimeOffset]) { return $Deger.UtcDateTime }
  $dto = [DateTimeOffset]::MinValue
  if ([DateTimeOffset]::TryParse("$Deger", $script:BS_KULTUR, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$dto)) { return $dto.UtcDateTime }
  return $null
}

function BsButce($Deger) {
  # Bütçe → "1.68" biçiminde metin (NOKTA, kültürden bağımsız) ya da $null (bozuk).
  # ⛔ PS ondalık virgül tuzağı (25.09): tr-TR'de 1.68.ToString() = "1,68"; gh -f butce_usd=1,68 iş akışında
  #    yine okunur ama "1,58" -split ',' 58 USD olmuştu. Tek biçim: InvariantCulture.
  if ($null -eq $Deger) { return $null }
  if ($Deger -is [double] -or $Deger -is [decimal] -or $Deger -is [int] -or $Deger -is [long]) { $sayi = [double]$Deger }
  else {
    $metin = ("$Deger".Trim()) -replace ',', '.'
    if ($metin -notmatch '^\d+(\.\d+)?$') { return $null }
    $sayi = [double]::Parse($metin, $script:BS_KULTUR)
  }
  if ([double]::IsNaN($sayi) -or [double]::IsInfinity($sayi) -or $sayi -le 0) { return $null }
  return $sayi.ToString('0.####', $script:BS_KULTUR)
}

function BsPayTablosu($Ayar) {
  # pay: { toplam: 6, smmm: 3, sgs: 3, kgk: 2 } → hashtable (küçük harf anahtar). Bozuksa throw (dağıtıcı KIRMIZI).
  if ($null -eq $Ayar -or $null -eq $Ayar.pay) { throw "SIRA DOSYASI BOZUK: 'pay' tablosu yok" }
  $tablo = @{}
  foreach ($p in $Ayar.pay.PSObject.Properties) {
    $n = 0
    if (-not [int]::TryParse("$($p.Value)", [ref]$n) -or $n -lt 0) { throw "SIRA DOSYASI BOZUK: pay.$($p.Name) = '$($p.Value)' (0 ya da pozitif tam sayı olmalı)" }
    $tablo[$p.Name.ToLowerInvariant()] = $n
  }
  if (-not $tablo.ContainsKey('toplam')) { throw "SIRA DOSYASI BOZUK: pay.toplam yok" }
  return $tablo
}

function BsSatirDenetle($Satir, $PayTablo, [int]$VarsayilanParalel) {
  # Tek sıra satırını biçimce denetler. Döner: tamam=$false ise neden dolu.
  $sonuc = [pscustomobject]@{ tamam = $false; neden = ''; plan = ''; sinav = ''; butce = $null; paralel = $VarsayilanParalel; olcum = ''; eklenme = $null; yeniden = $false }
  if ($null -eq $Satir) { $sonuc.neden = 'boş satır'; return $sonuc }
  $yol = ("$($Satir.plan)".Trim()) -replace '\\', '/'
  $sonuc.plan = $yol
  if ($yol -notmatch $script:BS_PLAN_DESEN -or $yol.Contains('..')) { $sonuc.neden = "plan yolu geçersiz (beklenen veri/sinav/plan-*.json)"; return $sonuc }
  $snv = BsSinavi $yol
  $sonuc.sinav = $snv
  if (-not $snv -or $snv -eq 'toplam' -or -not $PayTablo.ContainsKey($snv)) { $sonuc.neden = "sınav payı tanımsız ('$snv'; pay tablosuna eklenmeli)"; return $sonuc }
  if ($Satir.PSObject.Properties['sinav'] -and "$($Satir.sinav)".Trim() -and "$($Satir.sinav)".Trim().ToLowerInvariant() -ne $snv) { $sonuc.neden = "sinav alanı ('$($Satir.sinav)') plan adıyla ('$snv') uyuşmuyor"; return $sonuc }
  $btc = BsButce $Satir.butce_usd
  if ($null -eq $btc) { $sonuc.neden = "bütçe bozuk ('$($Satir.butce_usd)'; sayı ve 0'dan büyük olmalı)"; return $sonuc }
  $sonuc.butce = $btc
  $olc = ''
  if ($Satir.PSObject.Properties['olcum_kosusu'] -and $null -ne $Satir.olcum_kosusu) { $olc = "$($Satir.olcum_kosusu)".Trim() }
  if ($olc -and $olc -notmatch '^\d+$') { $sonuc.neden = "olcum_kosusu run id değil ('$olc')"; return $sonuc }
  if ([double]::Parse($btc, $script:BS_KULTUR) -gt $script:BS_OLCUM_ESIGI -and -not $olc) { $sonuc.neden = "bütçe $btc USD > $($script:BS_OLCUM_ESIGI) → olcum_kosusu ZORUNLU (CLAUDE.md para kuralı 2)"; return $sonuc }
  $sonuc.olcum = $olc
  if ($Satir.PSObject.Properties['paralel'] -and $null -ne $Satir.paralel -and "$($Satir.paralel)".Trim()) {
    $par = 0
    if (-not [int]::TryParse("$($Satir.paralel)".Trim(), [ref]$par) -or $par -lt 1 -or $par -gt 40) { $sonuc.neden = "paralel 1-40 arası tam sayı olmalı ('$($Satir.paralel)')"; return $sonuc }
    $sonuc.paralel = $par
  }
  $ekl = BsZaman $Satir.eklenme
  if ($null -eq $ekl) { $sonuc.neden = "eklenme zamanı okunamadı ('$($Satir.eklenme)')"; return $sonuc }
  $sonuc.eklenme = $ekl
  $sonuc.yeniden = ($Satir.PSObject.Properties['yeniden'] -and ("$($Satir.yeniden)" -eq 'True' -or "$($Satir.yeniden)" -eq 'true'))
  $sonuc.tamam = $true
  return $sonuc
}

function BsKarar {
  # Ayar      : sıra dosyasının nesnesi (pay, sira, varsayilan_paralel, geriye_bakis_gun, durdur)
  # Kosular   : gh run list -w bulut-uretim.yml --json databaseId,displayTitle,status,createdAt
  # PlanDenetle: { param($yol) ... } → $null (tamam) ya da neden metni (dosya yok, JSON bozuk)
  # PencereBasi / PencereTam: getirilen geçmişin en eski koşusu ve geçmişin tamamı gelip gelmediği
  # Döner: özet + her sıra satırı için karar: AC · ACILDI · BEKLE · ATLA · KOR · DURDU
  param($Ayar, $Kosular, [scriptblock]$PlanDenetle, $PencereBasi, [bool]$PencereTam)
  $payTablo = BsPayTablosu $Ayar
  $toplamPay = $payTablo['toplam']
  $varsayilanPar = 5
  if ($Ayar.PSObject.Properties['varsayilan_paralel'] -and "$($Ayar.varsayilan_paralel)" -match '^\d+$') { $varsayilanPar = [int]"$($Ayar.varsayilan_paralel)" }
  $geriGun = 30
  if ($Ayar.PSObject.Properties['geriye_bakis_gun'] -and "$($Ayar.geriye_bakis_gun)" -match '^\d+$') { $geriGun = [int]"$($Ayar.geriye_bakis_gun)" }
  $durdurulmus = ($Ayar.PSObject.Properties['durdur'] -and "$($Ayar.durdur)" -match '^(?i:true)$')
  $pencereUtc = BsZaman $PencereBasi

  # --- açık koşular: PLAN bazında (halka N koşarken N+1 kuyrukta = tek plan)
  $acikListe = New-Object System.Collections.ArrayList
  $cozulmeyenAcik = 0
  $gecmis = @{}
  foreach ($k in @($Kosular)) {
    if ($null -eq $k) { continue }
    $acik = ("$($k.status)" -ne 'completed')
    $m = [regex]::Match("$($k.displayTitle)", $script:BS_BASLIK_DESEN)
    if (-not $m.Success) { if ($acik) { $cozulmeyenAcik++ }; continue }
    $kPlan = $m.Groups[1].Value
    if ($acik) { [void]$acikListe.Add($kPlan) }
    if (-not $gecmis.ContainsKey($kPlan)) { $gecmis[$kPlan] = New-Object System.Collections.ArrayList }
    $kZaman = BsZaman $k.createdAt
    if ($null -ne $kZaman) { [void]$gecmis[$kPlan].Add($kZaman) }
  }
  $acikPlanlar = @($acikListe | Sort-Object -Unique)
  $sayac = @{}
  foreach ($ad in @($payTablo.Keys)) { $sayac[$ad] = 0 }
  foreach ($ap in $acikPlanlar) { $s = BsSinavi $ap; if ($s -and $s -ne 'toplam' -and $sayac.ContainsKey($s)) { $sayac[$s]++ } }
  $toplamAcik = $acikPlanlar.Count + $cozulmeyenAcik
  $acilisToplam = $toplamAcik
  $acilisSayac = @{}; foreach ($ad in @($sayac.Keys)) { $acilisSayac[$ad] = $sayac[$ad] }

  $gorulen = New-Object 'System.Collections.Generic.HashSet[string]'
  $kararlar = New-Object System.Collections.ArrayList
  foreach ($satir in @($Ayar.sira)) {
    if ($null -eq $satir) { continue }
    $d = BsSatirDenetle $satir $payTablo $varsayilanPar
    $kr = [pscustomobject]@{ plan = $d.plan; sinav = $d.sinav; butce = $d.butce; paralel = $d.paralel; olcum = $d.olcum; karar = ''; neden = '' }
    [void]$kararlar.Add($kr)
    if (-not $d.tamam) { $kr.karar = 'ATLA'; $kr.neden = $d.neden; continue }
    if (-not $gorulen.Add($d.plan.ToLowerInvariant())) { $kr.karar = 'ATLA'; $kr.neden = 'aynı plan sırada ikinci kez (ilk satır geçerli)'; continue }
    if ($acikPlanlar -contains $d.plan) { $kr.karar = 'ACILDI'; $kr.neden = 'koşuyor (açık koşu var)'; continue }
    $sinir = $d.eklenme.AddDays(-$geriGun)
    if ($d.yeniden) { $sinir = $d.eklenme }
    $sonrakiler = @()
    if ($gecmis.ContainsKey($d.plan)) { $sonrakiler = @($gecmis[$d.plan] | Where-Object { $_ -ge $sinir }) }
    if ($sonrakiler.Count -gt 0) { $kr.karar = 'ACILDI'; $kr.neden = ('açılmış, bitmiş (son koşu {0:yyyy-MM-dd HH:mm} UTC)' -f ($sonrakiler | Sort-Object | Select-Object -Last 1)); continue }
    if (-not $PencereTam -and ($null -eq $pencereUtc -or $pencereUtc -gt $sinir)) { $kr.karar = 'KOR'; $kr.neden = ('koşu geçmişi {0:yyyy-MM-dd HH:mm} UTC''ye kadar inmiyor; plan açılmış olabilir, AÇILMADI' -f $sinir); continue }
    if ($PlanDenetle) { $pn = & $PlanDenetle $d.plan; if ($pn) { $kr.karar = 'ATLA'; $kr.neden = "$pn"; continue } }
    if ($durdurulmus) { $kr.karar = 'DURDU'; $kr.neden = 'sıra dosyasında durdur=true (acil fren)'; continue }
    if ($toplamAcik -ge $toplamPay) { $kr.karar = 'BEKLE'; $kr.neden = "toplam pay dolu ($toplamAcik/$toplamPay)"; continue }
    if ($sayac[$d.sinav] -ge $payTablo[$d.sinav]) { $kr.karar = 'BEKLE'; $kr.neden = "$($d.sinav) payı dolu ($($sayac[$d.sinav])/$($payTablo[$d.sinav]))"; continue }
    $kr.karar = 'AC'; $kr.neden = 'pay boş'
    $toplamAcik++
    $sayac[$d.sinav]++
  }
  return [pscustomobject]@{
    toplam_acik = $acilisToplam; toplam_pay = $toplamPay; sinav_acik = $acilisSayac; pay = $payTablo
    cozulmeyen_acik = $cozulmeyenAcik; durdur = $durdurulmus; kararlar = @($kararlar)
  }
}
