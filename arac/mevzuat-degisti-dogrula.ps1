#requires -Version 5.1
<#
================================================================================
  MEVZUAT DEĞİŞTİ — ENGEL DOĞRULAMA (yanlış alarmı KANITLA kaldırır)   23.09.2026 · bedel 0

  Cem 23.09 "1.2.3 üçünü de yap" (VUK m.370 yanlış alarmı). 22.09 08:48 UTC nöbetçi (0c628487) 689
  yeni hat sorusunu yayından çekti: 275'i "VUK m.370 SİLİNDİ", 414'ü 12 maddede "değişti". Ölçüldü:
    · m.370 kanunda YÜRÜRLÜKTE (son şerh 7194/25, 2019); ayrıştırıcı "(Mülga: …; Yeniden düzenleme: …)"
      şerhini mülga sanıp atlıyordu (motor/mevzuat-yut.ps1 düzeltildi, MaddeKendisiMulga).
    · "değişti"lerin 7'sinde parçalar ters dizilince eski damga BİREBİR çıkıyor.
  Engel listesi (veri/sinav/mevzuat-degisti-yeni-hat.json) robot çıktısıdır; elle düzenlenmez. Bu araç
  listenin sahibi işlevlerle (arac/mevzuat-degisti.ps1) yalnız KANITI olan kaydı kaldırır.

  KANIT KURALLARI (ikisi de metne bakar, söze değil):
    AYNI-METİN  (tur 'degisti'): bugünkü ambar parçalarının bir alt kümesi, bir dizilişle birleştirilince
                alarmın TABANINDAKİ damgayı birebir veriyor → o madde metni tabandan beri değişmedi.
    DEĞİŞİKLİK-YOK (tur 'SILINDI'): madde bugün ambarda VAR ve metnindeki EN GEÇ tarih (şerh + dipnot, tüm
                gg/aa/yyyy) taban tarihinden ÖNCE → tabandan sonra hiçbir değişiklik şerhi yok.
                (Tam metin eşitliği burada kullanılamaz: m.370 27.08'de elle yutulmuştu, PDF ayrıştırması
                dipnot taşıyor — metinler biçimce farklı, ölçüldü 3.872 / 4.680 kr.)
  Kanıtlanamayan kayıt KALIR ve raporda nedeniyle yazılır.

  ⛔ BİTİRME OTURUMU SGS'YE DOKUNMAZ: -Sinav (varsayılan SMMM) yalnız o sınavın kayıtlarını kaldırır
     (anahtar öneki). Öbür sınavların kanıtlı kayıtları raporda SAYILIR, dokunulmaz.
  🚫 GÖRMEZ: parça anahtarı çıkarımı motor/madde-damga.ps1'in düzenli ifadelerinin AYNASIDIR; ayrışırsa
     bulunan parça sayısı damga dosyasındakiyle tutmaz → o madde "ÖLÇÜLEMEDİ" (kaldırılmaz).
     Tarih kuralı, tarihsiz bir değişiklik şerhini göremez (ölçülmedi; mevzuat.gov.tr şerhleri tarihlidir).

  KULLANIM
    powershell -NoProfile -File arac/mevzuat-degisti-dogrula.ps1                 # kuru: yalnız rapor
    powershell -NoProfile -File arac/mevzuat-degisti-dogrula.ps1 -Yaz            # SMMM kanıtlıları kaldır
================================================================================
#>
#   AYNI-PARÇA-KÜMESİ (tur 'degisti', diziliş aranamayacak kadar çok parça): tabanı üreten ambar içeriği o günkü
#               kanun aynasında (veri/mevzuat/<slug>.json, -AynaCommit) durur. Aynanın birleşik boyu tabanın boyuna
#               eşitse VE aynadaki parça metinleri bugünkü ambar parçalarıyla birebir aynı çok-kümeyse → metin aynı.
#               (22.09 VUK gec. m.1: 22 parça, 22! diziliş denenemez.)
param([string]$TabanCommit = '0c628487^', [string]$AynaCommit = '7e766a01^', [string]$AynaYeniCommit = 'HEAD', [string]$Sinav = 'SMMM', [string]$MaddeOnEk = '', [switch]$Yaz)   # -MaddeOnEk '6102|': yalnız o kanunun kayıtları (taban her alarm için farklıdır)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'mevzuat-degisti.ps1')
# Damga/Sadelestir: GERÇEK motor/madde-damga.ps1'den (replika yok)
$tok = $null; $err = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $kok 'motor\madde-damga.ps1'), [ref]$tok, [ref]$err)
foreach ($fn in $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in 'Sadelestir', 'Damga' }, $true)) { . ([scriptblock]::Create($fn.Extent.Text)) }
if (-not (Get-Command Damga -ErrorAction SilentlyContinue)) { throw 'Damga işlevi madde-damga.ps1''de bulunamadı' }
$SRV = $env:SUPABASE_SERVICE_KEY; if (-not $SRV) { $SRV = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY', 'User') }
if (-not $SRV) { throw 'SUPABASE_SERVICE_KEY yok' }
$Hs = @{ apikey = $SRV; Authorization = "Bearer $SRV"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$onEk = "$($Sinav.ToLowerInvariant())-"

# --- taban (alarmın karşılaştırdığı damga) — bayt korunarak
# ⛔ 23.09 KUSUR (ölçüldü): cmd /c içinde '^' KAÇIŞ karakteridir — 'X^' sessizce 'X' oluyordu, yani alarm ÖNCESİ taban
#   yerine SONRASI okunuyor ve 'AYNI-METİN' kanıtı anlamsız çıkıyordu. Sürüm önce git rev-parse ile tam kimliğe çözülür.
$TabanSha = "$(& git -C $kok rev-parse --verify --quiet "$TabanCommit")".Trim(); if (-not $TabanSha) { throw "taban sürümü çözülemedi: $TabanCommit" }
$AynaSha = "$(& git -C $kok rev-parse --verify --quiet "$AynaCommit")".Trim(); if (-not $AynaSha) { throw "ayna sürümü çözülemedi: $AynaCommit" }
$AynaYeniSha = "$(& git -C $kok rev-parse --verify --quiet "$AynaYeniCommit")".Trim(); if (-not $AynaYeniSha) { throw "yeni ayna sürümü çözülemedi: $AynaYeniCommit" }
$tabanDosya = Join-Path $env:TEMP 'md-taban-dogrula.json'
& cmd /c "git -C `"$kok`" cat-file blob $($TabanSha):veri/mevzuat/_madde-damga-onceki.json > `"$tabanDosya`""
if ($LASTEXITCODE) { throw "taban okunamadı: $TabanCommit" }
$tabanJ = Get-Content $tabanDosya -Raw -Encoding UTF8 | ConvertFrom-Json
$taban = $tabanJ.maddeler
$tabanTarih = [datetime]::ParseExact(("$($tabanJ.tarih)" -split ' ')[0], 'dd.MM.yyyy', $null)
$guncel = (Get-Content (Join-Path $kok 'veri\mevzuat\_madde-damga.json') -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler

# --- madde-damga.ps1 anahtar çıkarımının AYNASI (satır 88-104)
function Anahtar([string]$ad) {
  $kn = [regex]::Match($ad, '(?<![\d/])(\d{3,4})\s*(?:s\.|say[ıi]l[ıi])'); if (-not $kn.Success) { $kn = [regex]::Match($ad, '\((\d{3,4})\)') }
  $mn = [regex]::Match($ad, '[^a-zA-Z0-9]m\.\s*(\d{1,4})(?!\d)')
  if (-not ($kn.Success -and $mn.Success)) { return '' }
  $seri = ''; if ($ad -match '(?i)ge[çc]ici\s*m\.?|gec\.\s*m\.') { $seri = 'gec' } elseif ($ad -match '(?i)ek\s+m\.') { $seri = 'ek' }
  return ("{0}|{1}{2}" -f $kn.Groups[1].Value, $seri, $mn.Groups[1].Value)
}
function Parcalar([string]$anahtar, [string]$kaynak) {
  $on = [regex]::Match($kaynak, '^(.*?\(\d{3,4}[^)]*\))').Groups[1].Value
  $no = ($anahtar -split '\|')[1] -replace '^\D+', ''
  if (-not $on -or -not $no) { return @() }
  $desen = [uri]::EscapeDataString("$on*m.$no*")
  $r = Invoke-WebRequest -UseBasicParsing -Uri "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=like.$desen&order=kaynak_ad.asc&limit=200" -Headers $Hs -TimeoutSec 120
  $j = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))
  return @($j | ForEach-Object { $_ } | Where-Object { (Anahtar "$($_.kaynak_ad)") -eq $anahtar })
}
# kanun aynasının (git) eski sürümündeki parçalar — manifestte adı kaynak önekiyle başlayan kanunun <slug>.json'u
$script:aynaOnbellek = @{}
function AynaParcalari([string]$anahtar, [string]$kaynak, [string]$sha = $AynaSha) {
  $on = [regex]::Match($kaynak, '^(.*?\(\d{3,4}[^)]*\))').Groups[1].Value
  $law = @($manifest.kanunlar | Where-Object { "$($_.ad)" -eq $on }) | Select-Object -First 1
  if (-not $law) { return @() }
  $ok = "$sha|$($law.slug)"
  if (-not $script:aynaOnbellek.ContainsKey($ok)) {
    $f = Join-Path $env:TEMP "md-ayna-$($sha.Substring(0,8))-$($law.slug).json"
    & cmd /c "git -C `"$kok`" cat-file blob $($sha):veri/mevzuat/$($law.slug).json > `"$f`" 2>nul"
    $script:aynaOnbellek[$ok] = $(if ($LASTEXITCODE) { @() } else { @((Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler) })
  }
  return @($script:aynaOnbellek[$ok] | Where-Object { (Anahtar "$($_.kaynak_ad)") -eq $anahtar })
}
# dipnot numarası ayıklama: PDF metninde dipnot işareti kelimeye/noktalamaya bitişik sayıdır ("yetkilidir.116", "(…)118").
# Yalnız NOKTALAMA ya da kapanış parantezinden hemen sonra gelen 1-3 haneli sayı atılır; madde içi tutar/tarih/oran
# (boşlukla ayrılmış ya da "/" ile bağlı) dokunulmaz. Sonra Sadelestir (küçük harf + boşluk).
function DipnotSil([string]$t) { return (Sadelestir ([regex]::Replace("$t", '(?<=[\.\)…:;,])\d{1,3}(?=\s|$)', ''))) }
$manifest = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
# alt küme + diziliş araması: uzunlukla budanır
function DizilisBul($parca, [int]$hedefBoy, [string]$hedefDamga) {
  $n = $parca.Count; if ($n -gt 9) { return $null }
  $kullan = New-Object bool[] $n; $yol = New-Object System.Collections.Generic.List[int]
  $script:bulundu = $null
  function Dal([int]$boy) {
    if ($script:bulundu) { return }
    if ($yol.Count -and $boy -eq $hedefBoy) {
      $m = (@($yol | ForEach-Object { "$($parca[$_].metin)" }) -join ' ')
      if ((Damga $m) -eq $hedefDamga) { $script:bulundu = @($yol | ForEach-Object { "$($parca[$_].kaynak_ad)" }); return }
    }
    for ($i = 0; $i -lt $n; $i++) {
      if ($kullan[$i]) { continue }
      $ek = "$($parca[$i].metin)".Length + $(if ($yol.Count) { 1 } else { 0 })
      if ($boy + $ek -gt $hedefBoy) { continue }
      $kullan[$i] = $true; $yol.Add($i); Dal ($boy + $ek); $yol.RemoveAt($yol.Count - 1); $kullan[$i] = $false
      if ($script:bulundu) { return }
    }
  }
  Dal 0
  return $script:bulundu
}
function EnGecTarih([string]$metin) {
  $en = [datetime]::MinValue
  foreach ($m in [regex]::Matches($metin, '(?<!\d)(\d{1,2})/(\d{1,2})/((?:19|20)\d{2})')) {
    try { $t = New-Object datetime ([int]$m.Groups[3].Value), ([int]$m.Groups[2].Value), ([int]$m.Groups[1].Value); if ($t -gt $en) { $en = $t } } catch {}
  }
  # PDF'te tarih ile kanun no bitişik yazılabiliyor ("15/7/20166728/22") → yıl ilk 4 hane
  foreach ($m in [regex]::Matches($metin, '(?<!\d)(\d{1,2})/(\d{1,2})/((?:19|20)\d{2})\d')) {
    try { $t = New-Object datetime ([int]$m.Groups[3].Value), ([int]$m.Groups[2].Value), ([int]$m.Groups[1].Value); if ($t -gt $en) { $en = $t } } catch {}
  }
  return $en
}

# --- engel kayıtları madde başına
$liste = MdListeOku $kok
$elleKanit = @{}; $ekY = Join-Path $kok 'veri\sinav\mevzuat-degisti-elle-kanit.json'; if (Test-Path $ekY) { foreach ($p in (Get-Content $ekY -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar.PSObject.Properties) { $elleKanit[$p.Name] = $p.Value } }
$maddeler = @($liste.Values | Where-Object { -not $MaddeOnEk -or "$($_.madde)".StartsWith($MaddeOnEk) } | Group-Object { "$($_.madde)|$($_.tur)" })
Write-Host ("engel kaydı {0} · madde×tür {1} · taban {2} ({3:dd.MM.yyyy})" -f $liste.Count, $maddeler.Count, $TabanCommit, $tabanTarih)
$sonuc = New-Object System.Collections.Generic.List[object]
foreach ($g in $maddeler) {
  $ornek = $g.Group[0]; $an = "$($ornek.madde)"; $tur = "$($ornek.tur)"
  $sinavSay = @{}; foreach ($k in $g.Group) { $s = ("$($k.anahtar)" -split '-')[0].ToUpperInvariant(); $sinavSay[$s] = 1 + [int]$sinavSay[$s] }
  $kanit = ''; $neden = ''; $detay = ''
  $ek = $elleKanit["$TabanCommit|$an"]; if ($ek) { $kanit = 'ELLE-OKUNDU'; $detay = "$($ek.gerekce) ($($ek.okuyan))" }
  $tb = $taban.PSObject.Properties[$an]
  $parca = @(Parcalar $an "$($ornek.kaynak)")
  $gc = $guncel.PSObject.Properties[$an]
  if ($kanit) { }
  elseif ($gc -and $parca.Count -ne [int]$gc.Value.parca) { $neden = "ÖLÇÜLEMEDİ: ambarda $($parca.Count) parça bulundu, damga dosyası $($gc.Value.parca) diyor (anahtar aynası ayrışmış olabilir)" }
  elseif ($tur -eq 'SILINDI') {
    if (-not $parca.Count) { $neden = 'madde bugün de ambarda YOK (yeniden yutma bekleniyor)' }
    else {
      $en = EnGecTarih (@($parca | ForEach-Object { "$($_.metin)" }) -join ' ')
      if ($en -lt $tabanTarih) { $kanit = 'DEĞİŞİKLİK-YOK'; $detay = "ambarda $($parca.Count) parça; metindeki en geç tarih $($en.ToString('dd.MM.yyyy')) < taban $($tabanTarih.ToString('dd.MM.yyyy'))" }
      else { $neden = "metinde taban sonrası tarih var: $($en.ToString('dd.MM.yyyy'))" }
    }
  } else {
    if (-not $tb) { $neden = 'tabanda damga yok' }
    elseif (-not $parca.Count) { $neden = 'ambarda parça bulunamadı' }
    else {
      $dz = DizilisBul $parca ([int]$tb.Value.uzunluk) "$($tb.Value.damga)"
      if ($dz) { $kanit = 'AYNI-METİN'; $detay = "$(@($dz).Count)/$($parca.Count) parça, diziliş: " + ((@($dz) | ForEach-Object { ($_ -replace '^.*?(m\.\S+.*)$', '$1') }) -join ' + ') }
      else {
        # 3. yol — AYNI-PARÇA-KÜMESİ: tabanı üreten ambar içeriği, o günkü kanun AYNASINDA (veri/mevzuat/<slug>.json, git) durur.
        # Şart 1: aynadaki parçaların birleşik boyu = tabanın boyu (ayna o günkü ambarı temsil ediyor mu?).
        # Şart 2: aynadaki parça metinleri çok-kümesi = bugünkü ambar parçaları çok-kümesi → metin aynı, yalnız diziliş farklı.
        $ay = @(AynaParcalari $an "$($ornek.kaynak)")
        $ayBoy = $(if ($ay.Count) { ((@($ay | ForEach-Object { "$($_.metin)".Length }) | Measure-Object -Sum).Sum + $ay.Count - 1) } else { 0 })
        if ($ay.Count -and $ayBoy -eq [int]$tb.Value.uzunluk) {
          $k1 = @($ay | ForEach-Object { Damga "$($_.metin)" } | Sort-Object) -join ','; $k2 = @($parca | ForEach-Object { Damga "$($_.metin)" } | Sort-Object) -join ','
          if ($k1 -eq $k2) { $kanit = 'AYNI-PARÇA-KÜMESİ'; $detay = "$($parca.Count) parça; ayna $AynaCommit boyu $ayBoy = taban boyu; parça metinleri birebir (diziliş $($parca.Count)! denenemez)" }
          else {
            $ayYeni = @(AynaParcalari $an "$($ornek.kaynak)" $AynaYeniSha)
            $t1 = DipnotSil (@($ay | Sort-Object kaynak_ad | ForEach-Object { "$($_.metin)" }) -join ' '); $t2 = DipnotSil (@($ayYeni | Sort-Object kaynak_ad | ForEach-Object { "$($_.metin)" }) -join ' ')
            if ($ayYeni.Count -and $t1 -eq $t2) { $kanit = 'KANUN-AYNASI-AYNI'; $detay = "kanun aynası $AynaCommit → ${AynaYeniCommit}: madde metni dipnot numarası dışında birebir ($($t2.Length) kr)" }
            else { $neden = "ayna ($AynaCommit) ile bugünkü parçalar farklı ve kanun aynasında metin değişmiş → metin değişmiş olabilir" }
          }
        } else {
          # 4. yol — KANUN-AYNASI-AYNI (23.09, TTK vakası): anahtar başka kayıtları da topladığı için taban boyu tutmayabilir
          # (m.332 taban 2.172 kr, TTK aynasında 1.090). Kanunun KENDİ aynasında maddenin metni, yutmadan önce (-AynaCommit)
          # ve bugün (-AynaYeniCommit) DİPNOT NUMARALARI ayıklanınca birebir aynıysa kanun metni değişmemiştir.
          $ayYeni = @(AynaParcalari $an "$($ornek.kaynak)" $AynaYeniSha)
          $t1 = DipnotSil (@($ay | Sort-Object kaynak_ad | ForEach-Object { "$($_.metin)" }) -join ' '); $t2 = DipnotSil (@($ayYeni | Sort-Object kaynak_ad | ForEach-Object { "$($_.metin)" }) -join ' ')
          if ($ay.Count -and $ayYeni.Count -and $t1 -eq $t2) { $kanit = 'KANUN-AYNASI-AYNI'; $detay = "kanun aynası $AynaCommit → ${AynaYeniCommit}: madde metni dipnot numarası dışında birebir ($($t2.Length) kr)" }
          else { $neden = "tabandaki damga ($($tb.Value.uzunluk) kr) diziliş aramasıyla çıkmadı ($($parca.Count) parça); kanun aynasında metin farklı → kanıt yok" }
        }
      }
    }
  }
  $sonuc.Add([pscustomobject]@{ madde = $an; ad = "$($ornek.kaynak)"; tur = $tur; soru = $g.Count; sinav = (($sinavSay.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ' · '); kanit = $kanit; neden = $neden; detay = $detay })
  Write-Host ("  {0,-10} {1,-14} {2,4} soru  {3}" -f $an, $(if ($kanit) { $kanit } else { 'KANITSIZ' }), $g.Count, $(if ($kanit) { $detay } else { $neden }))
}

# --- kaldırılacaklar: yalnız -Sinav önekli + kanıtlı madde
$kanitli = @{}; foreach ($s in $sonuc) { if ($s.kanit) { $kanitli["$($s.madde)|$($s.tur)"] = $s.kanit } }
# 23.09: SORU BAZINDA kanıt (TTK geç. m.7: madde gerçekten değişti ama paketinde "mıknatıs" kaynak olarak bulunan sorular iptal edilen
#   hükme hiç değinmiyor). Anahtar "<taban>|soru|<etiket/kp-XX>"; tür KAVRAM-TARAMASI ya da ELLE-OKUNDU, gerekçesiyle.
$soruKanit = @{}; foreach ($kk in $elleKanit.Keys) { if ($kk -like "$TabanCommit|soru|*") { $soruKanit[$kk.Substring("$TabanCommit|soru|".Length)] = $elleKanit[$kk] } }
$kalkacak = @($liste.Values | Where-Object { ($kanitli.ContainsKey("$($_.madde)|$($_.tur)") -or $soruKanit.ContainsKey("$($_.anahtar)")) -and (-not $MaddeOnEk -or "$($_.madde)".StartsWith($MaddeOnEk)) -and "$($_.anahtar)".StartsWith($onEk, [StringComparison]::OrdinalIgnoreCase) })
if ($soruKanit.Count) { Write-Host ("soru bazında kanıt: {0} (bu taban için)" -f $soruKanit.Count) }
$digerKanitli = @($liste.Values | Where-Object { $kanitli.ContainsKey("$($_.madde)|$($_.tur)") -and -not "$($_.anahtar)".StartsWith($onEk, [StringComparison]::OrdinalIgnoreCase) })
$kalan = $liste.Count - $kalkacak.Count
$ozet = "DOĞRULAMA: engel $($liste.Count) · kanıtlı $($kalkacak.Count + $digerKanitli.Count) · $Sinav için kalkan $($kalkacak.Count) · başka sınav kanıtlı (dokunulmadı) $($digerKanitli.Count) · kalan engel $kalan"

$md = New-Object System.Collections.Generic.List[string]
$md.Add('# MEVZUAT DEĞİŞTİ — ENGEL DOĞRULAMASI'); $md.Add('')
$md.Add("> Türetilmiştir (``arac/mevzuat-degisti-dogrula.ps1``), elle düzenlenmez. $(Get-Date -Format 'dd.MM.yyyy HH:mm') · taban ``$TabanCommit`` ($($tabanTarih.ToString('dd.MM.yyyy'))) · bedel 0 · soru metni YOK")
$md.Add(''); $md.Add("**$ozet**$(if (-not $Yaz) { ' — KURU KOŞU, liste değişmedi' })"); $md.Add('')
$md.Add('| madde | kaynak | tür | soru | sınav | sonuç | kanıt / neden |'); $md.Add('|---|---|---|---:|---|---|---|')
foreach ($s in ($sonuc | Sort-Object { -$_.soru })) { $md.Add("| $($s.madde) | $($s.ad) | $($s.tur) | $($s.soru) | $($s.sinav) | $(if ($s.kanit) { $s.kanit } else { 'KANITSIZ — engel kalır' }) | $(if ($s.kanit) { $s.detay } else { $s.neden }) |") }
$md.Add(''); $md.Add('Kanıt kuralları betiğin başında. Başka sınavın kanıtlı kayıtları o sınavın sahibi tarafından `-Sinav <SGS|KGK> -Yaz` ile kaldırılır.')
[IO.File]::WriteAllText((Join-Path $kok ('veri\sinav\MEVZUAT-DEGISTI-DOGRULAMA' + $(if ($MaddeOnEk) { '-' + ($MaddeOnEk -replace '[^0-9a-z]', '') } else { '' }) + '.md')), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))

if ($Yaz -and $kalkacak.Count) {
  foreach ($k in $kalkacak) { [void]$liste.Remove("$($k.anahtar)") }
  $j = Get-Content (MdListeYolu $kok) -Raw -Encoding UTF8 | ConvertFrom-Json
  $nesne = [ordered]@{ aciklama = "$($j.aciklama)"; kayitlar = @($liste.Values | Sort-Object anahtar) }
  [IO.File]::WriteAllText((MdListeYolu $kok), (ConvertTo-Json -InputObject $nesne -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host "liste yazıldı: $($kalkacak.Count) kayıt kaldırıldı"
}
Write-Host $ozet
